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
const END_SECONDS := 2.8

var node: Dictionary
var seed_value := 0
var world: World
var run: RunState
var player: PlayerFrame
var weapons: WeaponSystem
var enemy_system: EnemySystem
var offers: UpgradeOffers
var stage: Stage

var state := "intro"            # intro, play, offer, crate, won, lost
var state_timer := 0.0
var tick := 0
var pending_level_ups := 0
var pending_crates := 0
var pending_pedestals := 0
var offer_cards: Array = []
var offer_source := ""          # level_up or pedestal
var crate_cards: Array = []
var stages_played: Array = []
var time_brake_active := false
var log_lines: Array = []       # notable moments, for the play log


func _init(map_node: Dictionary, mission_seed: int, frame_id: String, loadout: Array, mk_lookup: Callable) -> void:
	node = map_node
	seed_value = mission_seed
	world = World.new()
	world.rng.seed = mission_seed
	run = RunState.new()
	run.setup(frame_id, loadout, mk_lookup)
	world.run = run
	player = PlayerFrame.new()
	world.player = player
	player.setup(frame_id, MissionData.TYPES[node["type"]]["form"])
	_apply_difficulty()
	weapons = WeaponSystem.new(world)
	enemy_system = EnemySystem.new(world)
	offers = UpgradeOffers.new(world)
	world.on_collect = _on_collect
	world.on_player_hurt = _on_player_hurt
	start_stage(StageFactory.make(node["type"], self))


## Difficulty from the planet's danger, and its special condition (GDD 5C proposal).
func _apply_difficulty() -> void:
	var difficulty: float = node.get("difficulty", 1.0)
	var modifier: Dictionary = MissionData.MODIFIERS.get(node.get("modifier", ""), {})
	world.enemy_hp_scale = (1.0 + 0.55 * (difficulty - 1.0)) * modifier.get("enemy_hp", 1.0)
	world.enemy_damage_scale = 0.8 + 0.22 * (difficulty - 1.0)
	world.bullet_speed_scale = (0.92 + 0.08 * (difficulty - 1.0)) * modifier.get("bullet_speed", 1.0)
	world.spawn_scale = modifier.get("spawn", 1.0)
	world.xp_scale = modifier.get("xp", 1.0)
	world.crate_chance = 0.35 * modifier.get("crates", 1.0)
	world.dark = modifier.get("dark", false)
	world.gentle = int(node.get("region", 0)) == 0 and difficulty < 1.15
	if modifier.get("elite_blueprints", false):
		world.elite_blueprint_tech = node.get("reward_tech", "")


## Starts a stage. Also used for mid-mission hand-offs: the frame transforms to the new stage's form.
func start_stage(new_stage: Stage) -> void:
	stage = new_stage
	enemy_system.stage = stage
	world.walls = []
	world.enemy_shots.clear()
	world.zones.clear()
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
			return
		"intro":
			state_timer -= DT
			world.time += DT
			player.move(input, DT, 1.0)
			_keep_player_in_bounds()
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
	if player_active and player.alive:
		player.move(input, DT, 1.0 + 0.15 * run.field_count("overclocked_servos"))
		_keep_player_in_bounds()
		var shield_regen := 1.6 if FrameData.get_frame(run.frame_id)["trait"] == "fortress_field" else 1.0
		player.tick_timers(DT, shield_regen)
		weapons.update(input, DT)
		_track_time_brake()
	stage.step(DT)
	enemy_system.update(DT)
	world.update_player_shots(DT)
	world.update_blades(DT)
	world.update_enemy_shots(DT)
	world.update_zones(DT)
	world.update_pickups(DT)
	world.cleanup()


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
	elif stage.is_cleared():
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


## Level-ups and crates queue up; they open one at a time once play resumes.
func _open_pending() -> void:
	if pending_crates > 0:
		pending_crates -= 1
		crate_cards = offers.open_crate()
		state = "crate"
		world.emit("crate_opened", {"cards": crate_cards})
		var titles := []
		for card in crate_cards:
			titles.append(card["title"])
		note("Salvage Crate landed on %d: %s" % [crate_cards.size(), ", ".join(titles)])
	elif pending_pedestals > 0:
		pending_pedestals -= 1
		open_offer("pedestal", 3)
	elif pending_level_ups > 0:
		pending_level_ups -= 1
		open_offer("level_up", 3)


func open_offer(source: String, count: int) -> void:
	offer_cards = offers.build_cards(count)
	offer_source = source
	state = "offer"
	world.emit("offer_opened", {"source": source})


func _resolve_offer(choice: int) -> void:
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
			if gained > 0:
				pending_level_ups += gained
				world.emit("level_up", {"level": run.level})
				world.emit("sound", {"name": "level_up"})
			else:
				world.emit("sound", {"name": "pickup"})
		"crate":
			pending_crates += 1
			world.emit("sound", {"name": "crate"})
		"blueprint":
			run.blueprints[tech] = int(run.blueprints.get(tech, 0)) + 1
			world.emit("floating_text", {"pos": player.pos, "text": "+1 %s blueprint" % TechData.TECH[tech]["name"], "color": Color(0.5, 0.9, 1.0)})
			world.emit("sound", {"name": "blueprint"})
		"repair":
			player.repair(25.0)
			world.emit("floating_text", {"pos": player.pos, "text": "+25 armor", "color": Color(0.5, 1.0, 0.6)})
			world.emit("sound", {"name": "repair"})
		"pedestal":
			pending_pedestals += 1
			world.emit("sound", {"name": "pedestal"})
		"key":
			stage.on_key_collected()
			world.emit("sound", {"name": "key"})
		"graze":
			weapons.on_graze()


func _on_player_hurt(amount: float, source: String) -> void:
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
	if won:
		var reward: String = node.get("reward_tech", "")
		var amount := 2 + (2 if first_clear else 0)
		var modifier: Dictionary = MissionData.MODIFIERS.get(node.get("modifier", ""), {})
		amount = int(amount * modifier.get("blueprints", 1.0))
		if reward != "":
			blueprints[reward] = int(blueprints.get(reward, 0)) + amount
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
		"prize": node.get("prize", "") if won else "",
		"prize_text": node.get("prize_text", "") if won else "",
		"stages": stages_played,
		"forks": run.forks.duplicate(),
		"fusions": run.fusions.duplicate(),
	}


func drain_events() -> Array:
	var drained := world.events
	world.events = []
	return drained
