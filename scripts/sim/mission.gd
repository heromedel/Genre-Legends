class_name Mission
extends RefCounted
## One mission, start to finish. Reads top to bottom as the flow of a mission:
## set up the world from the planet's info, run the current stage, pause for level-ups and crates,
## and finish with a result. Stages can hand off mid-mission (GDD 6G proposal): the run, the frame and
## its upgrades carry over, and the frame transforms to the new stage's form.
##
## Everything here is simulation. MissionView draws it; tests and bots drive it headless.

const DT := World.DT
const INTRO_SECONDS := 1.5
## A mission that opens with a radio line holds the enemies back this much longer, so it can be read.
const RADIO_HOLD_SECONDS := 2.5
const END_SECONDS := 2.8

var node: Dictionary
var seed_value := 0
var world: World
var run: RunState
var player: PlayerFrame
var weapons: WeaponSystem
var enemy_system: EnemySystem
var offers: UpgradeOffers
var lesson_hazards: LessonHazards
var stage: Stage

## Blood Pact: seconds without a kill before armor starts bleeding, and how fast it bleeds per second.
const BLOOD_PACT_GRACE := 2.0
const BLOOD_PACT_BLEED := 2.0
## A repair pickup: a hit and a half (GDD 13G).
const REPAIR_ARMOR := 15.0

var state := "intro"            # intro, play, offer, crate, won, lost
var state_timer := 0.0
var tick := 0
var pending_level_ups := 0
var pending_crates := 0
var pending_pedestals := 0
var offer_cards: Array = []
var offer_source := ""          # level_up or pedestal
var offer_serial := 0           # changes whenever a new set of cards is shown (new offer or reroll)
var crate_cards: Array = []
var crate_faces: Array = []     # the reel faces behind the last crate, for the reel screen
var stages_played: Array = []
var time_brake_active := false
var log_lines: Array = []       # notable moments, for the play log


func _init(map_node: Dictionary, mission_seed: int, frame_id: String, loadout: Array, mk_lookup: Callable, frame_tiers: Array = []) -> void:
	node = map_node
	seed_value = mission_seed
	world = World.new()
	world.rng.seed = mission_seed
	run = RunState.new()
	run.setup(frame_id, loadout, mk_lookup, frame_tiers)
	world.run = run
	player = PlayerFrame.new()
	world.player = player
	player.setup(frame_id, MissionData.TYPES[node["type"]]["form"], run.frame_stats)
	world.refresh_plate_armor()
	_apply_difficulty()
	weapons = WeaponSystem.new(world)
	enemy_system = EnemySystem.new(world)
	offers = UpgradeOffers.new(world)
	lesson_hazards = LessonHazards.new(world, node.get("lesson", ""))
	world.on_collect = _on_collect
	world.on_player_hurt = _on_player_hurt
	var opening := StageFactory.make(node["type"], self)
	opening.chain_to = node.get("chain", "")
	start_stage(opening)
	if node.get("radio", "") != "":
		state_timer += RADIO_HOLD_SECONDS
	_apply_route_event(node.get("event", {}))


## What happened on the way here (RouteEvents): a scored hull, a crate waiting, more elites, faster
## enemy bullets, tougher bosses, or a field upgrade from a loose Mawjig core.
var route_banners: Array = []    # what the route event changed, announced on the mission's first tick


func _apply_route_event(effects: Dictionary) -> void:
	if effects.is_empty():
		return
	player.armor = player.max_armor * float(effects.get("start_armor", 1.0))
	pending_crates += int(effects.get("start_crates", 0))
	run.rerolls += int(effects.get("rerolls", 0))
	world.elite_chance *= float(effects.get("elites", 1.0))
	world.bullet_speed_scale *= float(effects.get("bullet_speed", 1.0))
	world.enemy_hp_scale *= float(effects.get("enemy_hp", 1.0))
	world.boss_health_scale *= float(effects.get("boss_health", 1.0))
	player.heat = float(effects.get("start_heat", player.heat))
	var fitted := []
	if effects.get("start_field", "") == "random":
		var choices := UpgradeData.FIELD.keys().filter(func(id): return id != "field_repair")
		var field_id: String = choices[world.rng.randi() % choices.size()]
		offers.apply(offers.field_card(field_id))
		fitted.append(UpgradeData.FIELD[field_id]["name"])
	if effects.get("start_risky", "") == "random":
		var risky := UpgradeData.RISKY_FIELD.keys()
		var risky_id: String = risky[world.rng.randi() % risky.size()]
		var card := offers.field_card(risky_id)
		offers.apply(card)
		fitted.append("risky: " + UpgradeData.RISKY_FIELD[risky_id]["name"])
	if effects.has("title"):
		# Said out loud as the mission starts, so you see what the trip changed (heromedel never could).
		var lines: Array = fitted + RouteEvents.mission_summary(effects)
		note("En route: %s (%s)" % [effects["title"], ", ".join(lines)])
		if not lines.is_empty():
			# The event's name, then what it changed, a few short items per banner so each fits the screen.
			route_banners.append(str(effects["title"]).to_upper())
			var chunk := []
			for line in lines:
				if not chunk.is_empty() and ", ".join(chunk + [line]).length() > 40:
					route_banners.append(", ".join(chunk).to_upper())
					chunk = []
				chunk.append(line)
			route_banners.append(", ".join(chunk).to_upper())


## Difficulty from the planet's danger, and its special condition (GDD 5C proposal).
func _apply_difficulty() -> void:
	var difficulty: float = node.get("difficulty", 1.0)
	var modifier: Dictionary = MissionData.MODIFIERS.get(node.get("modifier", ""), {})
	var threat: Dictionary = MissionData.THREAT.get(node.get("threat", "standard"), MissionData.THREAT["standard"])
	# The first region is hand-set (GDD 9A). Past it, enemies grow tougher and busier from the gate's level, and
	# hits grow in region steps (GDD 13D): within a region they climb from 0.75 at its first planet to about 1.0
	# at its last, branches and Hazards push them a little further, and the region's step multiplies it all.
	var region: int = node.get("region", 0)
	var within_region := difficulty - (1.0 + 0.3 * region)
	# Fire carries on from the gate's level rather than jumping to full density: with a hit budget, how much is
	# thrown at you matters as much as how hard each hit lands.
	var base := {"enemy_hp": 1.0 + 0.55 * (difficulty - 1.0), "damage": region_hits(region) * (0.75 + 0.8 * within_region),
		"fire": 0.5 + 0.1 * region + 0.3 * within_region, "bullet_speed": 0.95 + 0.08 * (difficulty - 1.0)}
	var column: int = node.get("baseline", -1)
	if column >= 0:
		base = MissionData.FIRST_REGION_BASELINE[mini(column, MissionData.FIRST_REGION_BASELINE.size() - 1)].duplicate()
	if node.get("hazard", false):
		for key in base:
			base[key] *= MissionData.HAZARD[key]
	var genre: Dictionary = MissionData.TYPE_DIFFICULTY.get(node["type"], {})
	base["damage"] *= genre.get("damage", 1.0)
	base["fire"] *= genre.get("fire", 1.0)
	world.enemy_hp_scale = base["enemy_hp"] * modifier.get("enemy_hp", 1.0) * threat["enemy_hp"]
	world.enemy_damage_scale = base["damage"] * threat["damage"]
	# Armor reads as hits (GDD 13A): this planet's plain bullet is one cell of the Armor bar, and a big hit is
	# anything worth two cells or more (longer immunity, Spaced Armor).
	world.plain_hit = MissionData.HIT_SMALL * world.enemy_damage_scale
	player.heavy_hit = world.plain_hit * 2.0
	world.bullet_speed_scale = base["bullet_speed"] * modifier.get("bullet_speed", 1.0) * threat["bullet_speed"]
	world.enemy_fire_scale = base["fire"] * threat["fire"]
	world.spawn_scale = modifier.get("spawn", 1.0)
	world.xp_scale = modifier.get("xp", 1.0)
	world.crate_chance = 0.2 * modifier.get("crates", 1.0)
	world.dark = modifier.get("dark", false)
	# Only the very first planet eases you in.
	world.gentle = node.get("id", "") == "r0c0n0"
	if modifier.get("elite_blueprints", false):
		world.elite_blueprint_tech = node.get("reward_tech", "")
	# Elites with a twist: none on the first planet, a few more each region, doubled by Bounty Hunters.
	world.elite_chance = 0.0 if world.gentle else (0.025 + 0.01 * region) * modifier.get("elites", 1.0)
	world.elite_mods = ["shielded", "splitting"] + (["mirrored"] if region >= 1 else [])
	world.reward_tech = node.get("reward_tech", "")
	# Missions launched from the game carry the player's setting; tests and old logs keep auto-aim.
	world.auto_aim = node.get("auto_aim", true)
	world.autofire = node.get("autofire", true)


## How much bigger hits are in a region than in the first (GDD 13D).
static func region_hits(region: int) -> float:
	var steps: Array = MissionData.REGION_HITS
	if region < steps.size():
		return steps[region]
	return steps[-1] + MissionData.REGION_HITS_STEP * (region - steps.size() + 1)


## Starts a stage. Also used for mid-mission hand-offs: the frame transforms to the new stage's form.
func start_stage(new_stage: Stage) -> void:
	stage = new_stage
	enemy_system.stage = stage
	lesson_hazards.stage = stage
	world.walls = []
	world.enemy_shots.clear()
	world.zones.clear()
	world.siphoned_this_stage = 0.0
	world.blades.clear()
	stage.setup()
	player.set_form(stage.form)
	stages_played.append(stage.stage_name())
	state = "intro"
	state_timer = INTRO_SECONDS
	world.emit("stage_start", {"form": stage.form, "name": stage.stage_name()})
	world.emit("sound", {"name": "transform"})
	note("Stage started: %s (%s form)" % [stage.stage_name(), stage.form])


func step(input: InputFrame) -> void:
	tick += 1
	world.tick = tick
	# The route event's banners wait for the first tick of the mission itself, after the launch transition.
	for text in route_banners:
		world.emit("banner", {"text": text, "style": "gold"})
	route_banners.clear()
	match state:
		"offer":
			_resolve_offer(input.choice)
			return
		"crate":
			if input.choice >= 0:
				state = "play"
				_open_pending()
			return
		"won", "lost":
			state_timer -= DT
			world.time += DT
			_update_world(InputFrame.new(), false)
			if state == "lost" and _boss_down():
				_trade_kill()
			return
		"intro":
			state_timer -= DT
			world.time += DT
			player.move(input, DT, 1.0)
			_keep_player_in_bounds()
			# While the radio line is up, the enemies hold off so it can be read (GDD 9E).
			if state_timer > INTRO_SECONDS:
				return
			stage.step(DT)
			if state_timer <= 0.0:
				state = "play"
			return
	world.time += DT
	_update_world(input, true)
	_check_end()
	if state == "play":
		_open_pending()


## One tick of play: move, fire, run the stage and enemies, then shots, blades, zones and pickups.
func _update_world(input: InputFrame, player_active: bool) -> void:
	world.refresh_resonance()
	for element in world.resonance:
		run.max_resonance = maxi(run.max_resonance, int(world.resonance[element]))
	if player_active and player.alive:
		player.move(input, DT, 1.0 + 0.15 * run.field_count("juggernaut_servos") + run.plate_speed())
		_keep_player_in_bounds()
		player.tick_timers(DT)
		if run.field_count("blood_pact") > 0:
			_blood_pact_bleed()
		weapons.update(input, DT)
		_track_time_brake()
	stage.tick_pending_boss(DT)
	stage.step(DT)
	if player_active:
		lesson_hazards.update(DT)
	enemy_system.update(DT)
	world.update_player_shots(DT)
	world.update_blades(DT)
	world.update_enemy_shots(DT)
	world.update_zones(DT)
	world.update_chain_blasts(DT)
	world.update_pickups(DT)
	world.update_allies(DT)
	world.cleanup()


## Blood Pact's price: without a kill for a couple of seconds, armor bleeds away, but never below a third,
## so it pushes you to keep killing without being what wrecks you. Its own penalty, so it doesn't overlap
## Glass Reactor's lost shield (heromedel).
func _blood_pact_bleed() -> void:
	player.since_kill += DT
	if player.since_kill > BLOOD_PACT_GRACE and player.armor > player.max_armor / 3.0:
		player.armor = maxf(player.armor - BLOOD_PACT_BLEED * DT, player.max_armor / 3.0)


func _keep_player_in_bounds() -> void:
	var margin := player.radius
	player.pos = player.pos.clamp(world.bounds.position + Vector2(margin, margin), world.bounds.end - Vector2(margin, margin))
	if not world.walls.is_empty():
		player.pos = world.push_out_of_walls(player.pos, player.radius)
		player.pos = player.pos.clamp(world.bounds.position + Vector2(margin, margin), world.bounds.end - Vector2(margin, margin))
	stage.after_player_moved()


func _track_time_brake() -> void:
	if player.time_brake > 0.0:
		time_brake_active = true
	elif time_brake_active:
		time_brake_active = false
		weapons.on_time_brake_ended()


func _check_end() -> void:
	if not player.alive:
		state = "lost"
		state_timer = END_SECONDS
		world.emit("player_down", {"pos": player.pos})
		world.emit("explosion", {"pos": player.pos, "size": 80.0, "color": Color(1, 0.7, 0.4)})
		world.emit("sound", {"name": "explode_big"})
		note("Frame wrecked")
	elif stage.is_cleared() and not world.prize_waiting:
		if stage.has_next_stage():
			start_stage(stage.next_stage())
		else:
			state = "won"
			state_timer = END_SECONDS
			player.grace = 999.0
			world.clear_bullets(player.pos, 4000.0)
			world.emit("banner", {"text": "MISSION COMPLETE", "style": "gold"})
			world.emit("sound", {"name": "victory"})
			note("Mission complete")


## The last boss fell to your shots still in flight after your frame went down: you traded with it.
## Not in the docs yet: a trade counts as a win and the prize is yours, since the boss was beaten.
func _trade_kill() -> void:
	state = "won"
	state_timer = END_SECONDS
	world.prize_waiting = false
	world.pickups = world.pickups.filter(func(pickup): return pickup.kind != "prize")
	world.emit("banner", {"text": "TAKEN DOWN TOGETHER", "style": "gold"})
	world.emit("sound", {"name": "victory"})
	note("Boss fell after the frame was wrecked: counted as a win")


## Level-ups and crates queue up; they open one at a time once play resumes.
func _open_pending() -> void:
	if pending_crates > 0:
		pending_crates -= 1
		crate_cards = offers.open_crate()
		crate_faces = offers.last_reel_faces
		state = "crate"
		world.emit("crate_opened", {"cards": crate_cards})
		var titles := []
		for card in crate_cards:
			titles.append(card["title"])
		note("Salvage Crate reels %s landed on %d: %s" % [" + ".join(crate_faces.map(func(f): return str(f))), crate_cards.size(), ", ".join(titles)])
	elif pending_pedestals > 0:
		pending_pedestals -= 1
		open_offer("pedestal", 3)
	elif pending_level_ups > 0:
		pending_level_ups -= 1
		open_offer("level_up", 3)


func open_offer(source: String, count: int) -> void:
	offer_cards = offers.build_cards(count)
	offer_serial += 1
	offer_source = source
	state = "offer"
	world.emit("offer_opened", {"source": source})


func _resolve_offer(choice: int) -> void:
	if choice == UpgradeOffers.REROLL_CHOICE:
		var fresh := offers.reroll(3)
		if not fresh.is_empty():
			offer_cards = fresh
			offer_serial += 1
			note("Rerolled the offer (%d rerolls left)" % run.rerolls)
			world.emit("offer_rerolled", {})
			world.emit("sound", {"name": "reel"})
		return
	if choice < 0 or choice >= offer_cards.size():
		return
	var card: Dictionary = offer_cards[choice]
	offers.apply(card)
	note("Picked %s (%s) from %d cards" % [card["title"], card["kind"], offer_cards.size()])
	offer_cards = []
	state = "play"
	_open_pending()


func _on_collect(kind: String, value: float, tech: String) -> void:
	match kind:
		"shard":
			var gained := run.add_xp(value)
			if gained > 0 and _boss_down():
				# The fight is over: a level now would offer upgrades you can't use, so it's banked as a blueprint.
				run.banked_levels += gained
				world.emit("floating_text", {"pos": player.pos, "text": "+%d banked" % gained, "color": Color(1, 0.85, 0.4)})
			elif gained > 0:
				pending_level_ups += gained
				world.emit("level_up", {"level": run.level})
				world.emit("sound", {"name": "level_up"})
			else:
				world.emit("sound", {"name": "pickup"})
		"crate":
			if _boss_down():
				run.banked_levels += 1
			else:
				pending_crates += 1
			world.emit("sound", {"name": "crate"})
		"prize":
			world.prize_waiting = false
			world.emit("power_moment", {"color": Color(1.0, 0.82, 0.35), "size": 2.0})
			world.emit("banner", {"text": "SALVAGE SECURED", "style": "gold"})
			note("Boss prize collected")
		"blueprint":
			run.blueprints[tech] = int(run.blueprints.get(tech, 0)) + 1
			world.emit("floating_text", {"pos": player.pos, "text": "+1 %s blueprint" % TechData.TECH[tech]["name"], "color": Color(0.5, 0.9, 1.0)})
			world.emit("sound", {"name": "blueprint"})
		"repair":
			# A repair is a hit and a half (GDD 13G); DSP-1's Field Patches make it count for more.
			var amount := REPAIR_ARMOR + (5.0 if run.plating() == "dsp1_plate" and run.fork_of("dsp1_plate") == "b" else 0.0)
			player.repair(amount)
			world.emit("floating_text", {"pos": player.pos, "text": "+%d Armor" % amount, "color": Color(0.5, 1.0, 0.6)})
			world.emit("sound", {"name": "repair"})
		"pedestal":
			pending_pedestals += 1
			world.emit("sound", {"name": "pedestal"})
		"key":
			stage.on_key_collected()
			world.emit("sound", {"name": "key"})
		"projector":
			# A boss's dropped device (GDD 11E): whichever fight dropped it decides what it does.
			for fight: BossBase in [stage.miniboss, stage.boss]:
				if fight != null and not fight.finished:
					fight.pickup_taken(kind)
			world.emit("sound", {"name": "pedestal"})
		"graze":
			if run.is_online("graze_engine"):
				weapons.on_graze()
			if run.field_count("adrenaline_junkie") > 0:
				_on_collect("shard", 0.35, "")


## True once the mission's last boss is down: from then on, levels and crates are banked as blueprints.
func _boss_down() -> bool:
	return stage.boss != null and stage.boss.defeated and not stage.has_next_stage()


func _on_player_hurt(amount: float, source: String) -> void:
	run.min_armor_fraction = minf(run.min_armor_fraction, player.armor_fraction())
	if stage.active_boss() != null:
		run.boss_hits += 1
	if player.armor_fraction() < 0.25:
		world.emit("low_armor", {})


## Debug: bring all equipped tech online at its cap, taking fork "a" or "b".
func debug_power_up(fork: String) -> void:
	for tech_id in run.loadout:
		if tech_id == "":
			continue
		run.tech_level[tech_id] = run.tech_cap.get(tech_id, 3)
		if run.tech_level[tech_id] >= TechData.FORK_LEVEL:
			run.forks[tech_id] = fork
	player.special_charges = 1
	world.refresh_plate_armor()
	note("Debug: powered up with forks %s" % fork)


func is_finished() -> bool:
	return (state == "won" or state == "lost") and state_timer <= 0.0


func note(text: String) -> void:
	log_lines.append("%s %s" % [_clock(), text])


func _clock() -> String:
	var seconds := int(world.time)
	return "%02d:%02d" % [seconds / 60, seconds % 60]


## Rewards: blueprints for the planet's reward tech, anything picked up, and the planet's prize.
## Losing keeps half of what was picked up (failure by attrition, not total loss).
func results(first_clear: bool) -> Dictionary:
	var won := state == "won"
	var blueprints := {}
	for tech_id in run.blueprints:
		blueprints[tech_id] = run.blueprints[tech_id] if won else int(run.blueprints[tech_id] / 2)
	# The planet's reward: all of it for a win, and a share by how far you got for a loss (GDD 9D).
	var progress := 1.0 if won else stage.progress_fraction()
	var reward: String = node.get("reward_tech", "")
	var amount := 2 + (2 if first_clear else 0)
	var modifier: Dictionary = MissionData.MODIFIERS.get(node.get("modifier", ""), {})
	var threat: Dictionary = MissionData.THREAT.get(node.get("threat", "standard"), MissionData.THREAT["standard"])
	amount = int(round(amount * progress * modifier.get("blueprints", 1.0) * threat["blueprints"] * float(node.get("reward_scale", 1.0))))
	# Levels and crates picked up after the last boss fell come home as extra blueprints of the planet's tech.
	if won:
		amount += run.banked_levels
	# A route event's wager (the Rival Hunter) pays only for a win.
	var event: Dictionary = node.get("event", {})
	if won:
		amount += int(event.get("wager_blueprints", 0))
	# A plate named after a boss is that boss's prize: only beating it pays (GDD 21G).
	if reward != "" and TechData.get_tech(reward).has("from_boss") and not won:
		amount = 0
	if reward != "" and amount > 0:
		blueprints[reward] = int(blueprints.get(reward, 0)) + amount
	# Frame Blueprints (GDD 21F) pay like the planet's reward: all for a win, a share by progress for a loss.
	var frame_blueprints := int(round(int(node.get("frame_blueprints", 0)) * progress * threat["blueprints"] * float(node.get("reward_scale", 1.0))))
	return {
		"won": won,
		"seconds": world.time,
		"kills": run.kills,
		"level": run.level,
		"damage_dealt": run.damage_dealt,
		"damage_taken": run.damage_taken,
		"hits_taken": run.hits_taken,
		"crates": run.crates_opened,
		"shards_missed": run.shards_missed,
		"blueprints": blueprints,
		"frame_blueprints": frame_blueprints,
		"wager_crystals": int(event.get("wager_crystals", 0)) if won else 0,
		"prize": node.get("prize", "") if won else "",
		"prize_text": node.get("prize_text", "") if won else "",
		"stages": stages_played,
		"forks": run.forks.duplicate(),
		"fusions": run.fusions.duplicate(),
		"progress": progress,
		"kills_by_kind": run.kills_by_kind.duplicate(),
		"bosses_defeated": run.bosses_defeated.duplicate(),
		"banked_levels": run.banked_levels,
		"reward_tech": node.get("reward_tech", "pulse_driver"),
		"max_resonance": run.max_resonance,
		"is_gate": node.get("is_gate", false),
		"armor_left": player.armor_fraction(),
		"min_armor": run.min_armor_fraction,
		"boss_untouched": stage.boss != null and stage.boss.defeated and run.boss_hits == 0,
		"only_main": run.online_tech().size() <= 1,
		"field": run.field.duplicate(),
		"threat": node.get("threat", "standard"),
		"secret_found": stage.get("secret_visited") == true,
	}


func drain_events() -> Array:
	var drained := world.events
	world.events = []
	return drained
