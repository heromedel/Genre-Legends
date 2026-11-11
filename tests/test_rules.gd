extends SceneTree
## Test harness (GDD 4A): checks the rules that everything else leans on.
## Run:  godot --headless -s tests/test_rules.gd

var failures := 0
var checks := 0


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		print("  FAIL: ", message)


func _init() -> void:
	print("Rules tests")
	_tech_data()
	_star_map()
	_input_round_trip()
	_replay_determinism()
	_offers()
	_build_022()
	_build_03()
	_resonance_tiers()
	_blood_pact()
	_fusions()
	_resume()
	_dungeon_needles()
	_aim_hold()
	_hits_that_matter()
	_building_a_frame()
	print("%d checks, %d failed" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _tech_data() -> void:
	for tech_id in TechData.TECH:
		var tech: Dictionary = TechData.TECH[tech_id]
		check(TechData.SLOTS.has(tech["slot"]), "%s has a real slot" % tech_id)
		# Plates level in their own way with no forks (GDD 13M); everything else forks.
		check((tech["forks"].has("a") and tech["forks"].has("b")) or (tech["slot"] == "plating" and tech["forks"].is_empty()), "%s has two forks, or is a plate with none" % tech_id)
		check(tech["levels"].size() == TechData.MAX_LEVEL, "%s describes every level" % tech_id)
		var from_boss: String = tech.get("from_boss", "")
		check(not tech["blueprint_from"].is_empty() or GuideData.BOSSES.has(from_boss) or tech.has("source"), "%s comes from somewhere" % tech_id)
		check(tech.has("weight") and tech.has("draw"), "%s has a weight and a draw (GDD 21C)" % tech_id)
	# Every frame can launch the starting kit (GDD 21C: 6 Load, 3 Output).
	for frame_id in FrameData.FRAMES:
		var stats := FrameData.stats(frame_id, [])
		check(TechData.loadout_weight(TechData.STARTING_LOADOUT) <= stats["load"], "%s carries the starting kit" % frame_id)
		check(TechData.loadout_draw(TechData.STARTING_LOADOUT) <= stats["output"], "%s powers the starting kit without heat" % frame_id)
	# Branch prizes name real frames and tech.
	for branch in MissionData.THEMED_BRANCHES:
		for part in branch["prize"].split("+"):
			var bits: PackedStringArray = part.split(":")
			check((bits[0] == "frame" and FrameData.FRAMES.has(bits[1])) or (bits[0] == "tech" and TechData.TECH.has(bits[1])), "%s prize %s is real" % [branch["id"], part])
	for slot_index in TechData.STARTING_LOADOUT.size():
		var tech_id: String = TechData.STARTING_LOADOUT[slot_index]
		if tech_id != "":
			check(TechData.TECH[tech_id]["slot"] == TechData.SLOTS[slot_index], "starting %s fits slot %d" % [tech_id, slot_index])
	check(not TechData.STARTING_UNLOCKS.has("shield_generator") and not TechData.STARTING_UNLOCKS.has("swarm_pods"), "lesson tech is held back (GDD 9C)")
	for element in UpgradeData.ELEMENTS:
		check(UpgradeData.RESONANCE[element]["tiers"].size() == UpgradeData.RESONANCE_THRESHOLDS.size(), "%s resonance describes every tier" % element)
	for tech_id in TechData.TECH:
		# Plating and the power parts are the frame itself, outside the elements (they never feed Resonance).
		var frame_part: bool = TechData.TECH[tech_id]["slot"] == "plating" or TechData.TECH[tech_id].get("starts_online", false)
		check(UpgradeData.ELEMENTS.has(TechData.TECH[tech_id]["element"]) != frame_part, "%s has a resonance element, unless it's part of the frame" % tech_id)
	# Fusions pair parts that can be fitted together: never two parts for the same slot (GDD 13O).
	for fusion_id in UpgradeData.FUSIONS:
		var needs: Array = UpgradeData.FUSIONS[fusion_id]["needs"]
		var slots: Array = needs.map(func(t): return TechData.TECH[t]["slot"])
		check(slots[0] != slots[1] or slots[0] == "weapon", "%s fuses parts from slots that can both be fitted" % fusion_id)
	for fusion_id in UpgradeData.FUSIONS:
		for needed in UpgradeData.FUSIONS[fusion_id]["needs"]:
			check(TechData.TECH.has(needed), "fusion %s needs real tech %s" % [fusion_id, needed])
	check(TechData.blueprints_for_next_mk(0) == 3, "unlocking takes 3 blueprints (GDD 7A)")
	check(TechData.blueprints_for_next_mk(3) == 0, "Mk 3 is the top")


func _star_map() -> void:
	var cleared := {}
	var is_cleared := func(id): return cleared.has(id)
	var map_a := StarMap.new(1234)
	map_a.ensure_generated(is_cleared)
	var map_b := StarMap.new(1234)
	map_b.ensure_generated(is_cleared)
	check(map_a.all_node_ids().size() == map_b.all_node_ids().size(), "same seed, same map")
	check(map_a.get_node("r0c0n0")["type"] == "star_cluster", "the first planet is a Star Cluster")
	check(map_a.is_available("r0c0n0", is_cleared), "the first planet is open from the start")
	# Every planet must be reachable from the start.
	for node_id in map_a.all_node_ids():
		if node_id == "r0c0n0":
			continue
		check(not map_a.get_node(node_id)["incoming"].is_empty(), "%s has a way in" % node_id)
	# Clear the main route through region 0 and make sure region 2 appears.
	for column in StarMap.COLUMNS_PER_REGION + 1:
		for node_id in map_a.columns[column]:
			cleared[node_id] = true
	map_a.ensure_generated(is_cleared)
	check(map_a.region_count() >= 3, "clearing a region's gate reveals the region after the next")
	var branch_prizes := 0
	for node_id in map_a.all_node_ids():
		if map_a.get_node(node_id)["prize"] != "":
			branch_prizes += 1
	check(branch_prizes >= 2, "themed branch and gate prizes exist (GDD 5D)")
	# Forks: some planet should link to two planets.
	var forks := 0
	for node_id in map_a.all_node_ids():
		if map_a.get_node(node_id)["links"].size() >= 2:
			forks += 1
	check(forks >= 3, "the map has real forks, not a single line")
	for node_id in map_a.columns[2]:
		check(map_a.get_node(node_id)["lesson"] == "needles", "every planet 3 is the needle lesson")
	var gate: Dictionary = map_a.get_node(map_a.columns[5][0])
	check(gate["lesson"] == "mirror" and gate["type"] == "star_cluster", "the first gate is the mirror lesson")


func _input_round_trip() -> void:
	var frame := InputFrame.new()
	frame.move = Vector2(0.53, -0.21)
	frame.drag = Vector2(12.3, -4.1)
	frame.aim = Vector2(-1, 0)
	frame.special = true
	frame.choice = 2
	var q := frame.quantized()
	check(InputFrame.decode(q.encode()).equals(q), "input frames survive encode/decode")
	check(InputFrame.decode("0,0,0,0,0,0,0,-1").fire, "old 8-field logs replay with the trigger held")
	frame.fire = false
	check(not InputFrame.decode(frame.quantized().encode()).fire, "the fire button survives encode/decode")
	var runs := "1,2,3,4,5,6,0,-1*3;0,0,0,0,0,0,1,-1"
	check(InputFrame.decode_runs(runs).size() == 4, "run-length input decoding")


## Two runs with the same seed and the same inputs must end identically: the basis of replays.
func _replay_determinism() -> void:
	for mission_type in MissionData.PLAYABLE_TYPES:
		var results := []
		for attempt in 2:
			var node := {"id": "t", "name": "T", "region": 1, "column": 1, "row": 0.0, "type": mission_type, "need": "x",
				"difficulty": 1.3, "danger": 2, "modifier": "", "reward_tech": "arc_blade", "prize": "", "prize_text": ""}
			var mission := Mission.new(node, 4242, "vanguard", TechData.STARTING_LOADOUT, func(t): return 2)
			var bot := BotPilot.new(mission, 9)
			for i in 60 * 40:
				mission.step(bot.next_input())
				mission.drain_events()
				if mission.is_finished():
					break
			results.append("%s|%d|%.3f|%.3f|%d|%d" % [mission.state, mission.tick, mission.player.pos.x, mission.player.armor, mission.run.kills, mission.run.level])
		check(results[0] == results[1], "%s replays identically (%s vs %s)" % [mission_type, results[0], results[1]])


func _offers() -> void:
	var node := {"id": "t", "name": "T", "region": 0, "column": 1, "row": 0.0, "type": "star_cluster", "need": "x",
		"difficulty": 1.0, "danger": 1, "modifier": "", "reward_tech": "arc_blade", "prize": "", "prize_text": ""}
	var mission := Mission.new(node, 1, "vanguard", TechData.STARTING_LOADOUT, func(t): return 3)
	var cards := mission.offers.build_cards(3)
	check(cards.size() >= 3, "a level-up offers at least three cards")
	var kinds := cards.map(func(c): return c["kind"])
	check(kinds.has("online"), "early level-ups offer bringing tech online")
	# Push one tech to the fork level: both fork cards must appear together.
	mission.run.tech_level["pulse_driver"] = 2
	var saw_pair := false
	for i in 40:
		var offered := mission.offers.build_cards(3)
		var forks := offered.filter(func(c): return c["kind"] == "fork")
		if forks.size() == 2:
			saw_pair = true
		check(forks.size() != 1, "forks are never offered alone")
	check(saw_pair, "fork pairs show up")
	# Rerolls and resonance hints.
	mission.state = "offer"
	mission.offer_cards = mission.offers.build_cards(3)
	var before_rerolls := mission.run.rerolls
	var choice := InputFrame.new()
	choice.choice = UpgradeOffers.REROLL_CHOICE
	mission.step(choice)
	check(mission.run.rerolls == before_rerolls - 1 and mission.state == "offer", "a reroll spends one and keeps the offer open")
	var hinted := mission.offers.build_cards(3).filter(func(c): return c["synergy"] != "")
	check(not hinted.is_empty(), "cards say what they build toward")


func _test_mission(mission_type: String) -> Mission:
	var node := {"id": "t", "name": "T", "region": 0, "column": 1, "row": 0.0, "type": mission_type, "need": "x",
		"difficulty": 1.0, "danger": 1, "modifier": "", "reward_tech": "arc_blade", "prize": "", "prize_text": ""}
	return Mission.new(node, 7, "vanguard", TechData.STARTING_LOADOUT, func(t): return 3)


## Build 0.2.2: crate reels, once-per-pass lasers, ricochet edges, tractor reach, branches, the guide.
func _build_022() -> void:
	# Crate reels: every result from 1 to 6 is possible, and the odds match what the data promises.
	var mission := _test_mission("star_cluster")
	var lowest := 99
	var highest := 0
	var total := 0
	for i in 6000:
		var sum: int = mission.offers.spin_reels().reduce(func(a, b): return a + b, 0)
		lowest = mini(lowest, sum)
		highest = maxi(highest, sum)
		total += sum
	check(lowest == 1, "a crate always gives at least 1 upgrade")
	check(highest >= 5, "crates can land on 5 or more")
	check(absf(total / 6000.0 - 2.2) < 0.1, "crates average about 2.2 upgrades (got %.2f)" % (total / 6000.0))
	mission.run.field["lucky_salvage"] = 1
	var lucky_low := 99
	var lucky_total := 0
	for i in 6000:
		var sum: int = mission.offers.spin_reels().reduce(func(a, b): return a + b, 0)
		lucky_low = mini(lucky_low, sum)
		lucky_total += sum
	check(lucky_low == 2, "Lucky Salvage: every crate gives at least 2")
	check(absf(lucky_total / 6000.0 - 2.8) < 0.1, "Lucky Salvage averages about 2.8 (got %.2f)" % (lucky_total / 6000.0))
	# A laser beam hits once per pass, however long you sit in it.
	mission = _test_mission("star_cluster")
	var world := mission.world
	world.add_zone("laser", world.player.pos + Vector2(-300, 0), 0.0, 2.0, 10.0, true, {"angle": 0.0, "length": 600.0, "width": 30.0})
	for i in 90:
		world.update_zones(World.DT)
		world.player.grace = maxf(world.player.grace - World.DT, 0.0)
	check(mission.run.hits_taken == 1, "a laser hits once per pass (took %d)" % mission.run.hits_taken)
	# Chain Bolts: a bolt that kills arcs on to the next enemy, and stops when a jump doesn't kill.
	world.enemies.clear()
	var first := world.spawn_enemy("dart", Vector2(600, 300))
	var second := world.spawn_enemy("dart", Vector2(700, 300))
	var third := world.spawn_enemy("dart", Vector2(800, 300))
	first.hp = 1.0
	second.hp = 1.0
	third.hp = 9999.0
	var shot := world.player_shot(Vector2(590, 300), Vector2(600, 0), 20.0, "pulse_driver", "bolt", Color.WHITE)
	shot.chains = 3
	world.update_player_shots(World.DT)
	check(first.dead and second.dead and third.hp < 9999.0, "Chain Bolts arc from kill to kill")
	# Tractor Beam pulls from three times as far, not across the whole field.
	var base_reach := world.pickup_reach()
	mission.run.field["tractor_beam"] = 1
	check(world.pickup_reach() > base_reach and world.pickup_reach() < base_reach + 200.0, "Tractor Beam reaches a bit further, not across the screen")
	# Themed branches play harder than the main route beside them, and the prize planet is a Hazard.
	var map := StarMap.new(777)
	map.ensure_generated(func(_id): return false)
	for node_id in map.all_node_ids():
		var node: Dictionary = map.get_node(node_id)
		if node.get("branch", "") != "" and node["region"] == 0:
			check(node["baseline"] > node["column"] - 1 or node["baseline"] == MissionData.FIRST_REGION_BASELINE.size() - 1,
				"%s plays above its column" % node_id)
			if node.get("prize", "") != "":
				check(node.get("hazard", false), "%s, the branch's prize planet, is a Hazard" % node_id)
	# Twin Aces show their health bar once they've flown in.
	mission = _test_mission("star_cluster")
	mission.stage.debug_skip_to_miniboss()
	var bot := BotPilot.new(mission, 1)
	for i in 60 * 12:
		mission.step(bot.next_input())
		mission.drain_events()
	check(mission.stage.miniboss != null and not mission.stage.miniboss.entering, "the Twin Aces finish their entrance")
	# The guide only describes real enemies.
	for kind in GuideData.ENEMIES:
		check(EnemyData.ENEMIES.has(kind), "guide entry %s is a real enemy" % kind)


## Build 0.3: every boss the roster names exists and matches its guide entry; route events add up;
## elites only promote ordinary enemies; the new tech are wired into the data.
func _build_03() -> void:
	var mission := _test_mission("star_cluster")
	for mission_type in BossRoster.POOLS:
		for kind in ["boss", "miniboss"]:
			for boss_id in BossRoster.POOLS[mission_type][kind]:
				var boss := BossRoster.make(boss_id, mission.world)
				boss.setup_room(Rect2(200, 140, 800, 520))
				boss.spawn()
				check(boss.look == boss_id, "%s builds a boss with the same look" % boss_id)
				check(GuideData.BOSSES.has(boss_id), "%s has a guide entry" % boss_id)
				check(BossRoster.make(boss_id, mission.world).boss_name not in ["", "Boss"], "%s is named before it spawns, for its warning" % boss_id)
				check(not boss.parts.is_empty(), "%s has parts" % boss_id)
	check(BossRoster.pick("star_cluster", "boss", "r0c0n0", 5) == "hive_carrier", "the first planet keeps the classic boss")
	# Auto-fire off: weapons hold fire until the player steers, aims or presses fire (Settings).
	for autofire in [true, false]:
		var held := _test_mission("star_cluster")
		held.world.autofire = autofire
		var idle := InputFrame.new()
		idle.fire = false
		for i in 60:
			held.weapons.update(idle, World.DT)
		check((held.world.player_shots.size() > 0) == autofire, "auto-fire %s: idle frame %s" % ["on" if autofire else "off", "fires" if autofire else "holds fire"])
	# Trading with the last boss: if it falls while your wreck burns, the mission counts as won.
	var trade := _test_mission("star_cluster")
	trade.stage.boss = BossRoster.make("hive_carrier", trade.world)
	trade.stage.boss.spawn()
	trade.state = "lost"
	trade.state_timer = 2.0
	trade.stage.boss.defeated = true
	trade.step(InputFrame.new())
	check(trade.state == "won" and trade.results(false)["won"], "the last boss falling during your wreck is a win")
	for event_id in RouteEvents.EVENTS:
		for choice: Dictionary in RouteEvents.EVENTS[event_id]["choices"]:
			var total := 0.0
			for outcome: Array in choice["outcomes"]:
				total += float(outcome[0])
			check(is_equal_approx(total, 1.0), "%s / %s outcomes add up to 1" % [event_id, choice["label"]])
	var world := mission.world
	world.elite_chance = 1.0
	world.elite_mods = ["shielded"]
	var tough := world.spawn_enemy("splitter", Vector2(100, 100))
	check(tough.elite and tough.shield_hp > 0.0, "a tough enemy can be promoted to a shielded elite")
	var shard := world.spawn_enemy("drone_shard", Vector2(100, 100))
	check(not shard.elite, "tiny enemies are never promoted")
	world.hurt_enemy(tough, tough.shield_hp * 0.5)
	check(tough.hp == tough.max_hp, "a shielded elite's barrier soaks damage first")
	# The clone is a surprise: about one Star Cluster planet in four, and the first planet never.
	var clones := 0
	for i in 400:
		if BossRoster.pick("star_cluster", "miniboss", "r1c%dn%d" % [i % 7, i], 11) == "clone_projector":
			clones += 1
	check(clones > 60 and clones < 140, "the Clone Projector shows up on about a quarter of Star Cluster planets (%d / 400)" % clones)
	# The last boss drops the prize; levels after it are banked as blueprints.
	var fight := _test_mission("star_cluster")
	fight.stage.debug_skip_to_boss()
	var bot := BotPilot.new(fight, 2)
	for i in 60 * 240:
		fight.step(bot.next_input())
		fight.drain_events()
		fight.player.armor = fight.player.max_armor
		if fight.stage.boss != null and fight.stage.boss.defeated:
			break
	check(fight.world.prize_waiting, "the last boss leaves its prize on the field")
	check(fight.state == "play", "the mission waits for the prize")
	for i in 60 * 10:
		fight.step(bot.next_input())
		fight.drain_events()
		if fight.is_finished() or fight.state == "won":
			break
	check(not fight.world.prize_waiting and fight.state == "won", "the prize drifts to you and the mission ends")
	# Chained missions: the map chains some planets and dungeons, never lessons or gates, and a chained
	# planet's boss comes from the mission type it ends in.
	var chain_map := StarMap.new(4242)
	chain_map.ensure_generated(func(id): return id.begins_with("r0") or id.begins_with("br_"))
	var chained := 0
	for node_id in chain_map.all_node_ids():
		var node: Dictionary = chain_map.get_node(node_id)
		if node.get("chain", "") != "":
			chained += 1
			check(node["lesson"] == "" and not node["is_gate"], "%s: lessons and gates never chain" % node_id)
			check(BossRoster.POOLS[node["chain"]]["boss"].has(node["boss"]), "%s: its boss belongs to %s" % [node_id, node["chain"]])
	check(chained > 0, "the map has chained missions (%d)" % chained)
	var dive := _test_mission("planet")
	dive.stage.chain_to = "corridor"
	var next := dive.stage.next_stage()
	check(next is CorridorStage and next.short_stage, "a planet dives into a short Corridor Run")
	for tech_id in ["option_pods", "soul_lantern", "ion_cannon", "thruster_explosion"]:
		check(TechData.TECH.has(tech_id), "%s exists" % tech_id)


## Build 0.4.1: the reworked Resonance tiers do what their cards say.
func _resonance_tiers() -> void:
	# Chain Reaction (Explosive II): what a blast kills goes off a beat later and catches the next in line.
	var world := _test_mission("star_cluster").world
	world.enemies.clear()
	world.resonance["explosive"] = 2
	var first := world.spawn_enemy("dart", Vector2(400, 300))
	var second := world.spawn_enemy("dart", Vector2(460, 300))
	world.explode(Vector2(370, 300), 40.0, 999.0, "test", Color.WHITE)
	check(first.dead and not second.dead and world.chain_blasts.size() == 1, "Chain Reaction queues a blast where the kill was")
	world.update_chain_blasts(0.2)
	check(second.dead, "Chain Reaction's blast catches the next enemy")
	# Splinter Rounds (Kinetic II): a shot that has flown a while bursts into two fragments on its first hit.
	world = _test_mission("star_cluster").world
	world.enemies.clear()
	world.resonance["kinetic"] = 2
	var target := world.spawn_enemy("splitter", Vector2(600, 300))
	target.hp = 9999.0
	var shot := world.player_shot(Vector2(590, 300), Vector2(600, 0), 5.0, "pulse_driver", "bolt", Color.WHITE)
	shot.age = 0.5
	var before := world.player_shots.size()
	world.update_player_shots(World.DT)
	check(world.player_shots.size() == before + 2, "Splinter Rounds burst into two fragments")
	# Capacitor Discharge (Energy II): a breaking shield strikes nearby enemies.
	world = _test_mission("star_cluster").world
	world.enemies.clear()
	world.resonance["energy"] = 2
	var near := world.spawn_enemy("splitter", world.player.pos + Vector2(120, 0))
	var near_hp := near.hp
	world.damage_player(20.0, "test")
	check(near.hp < near_hp, "Capacitor Discharge strikes whenever you're hit")


## Blood Pact: no kills for a while bleeds armor, but never below a third; it no longer touches the shield.
func _blood_pact() -> void:
	var mission := _test_mission("planet")
	mission.run.field["blood_pact"] = 1
	var player := mission.player
	for i in 60 * 120:
		mission._blood_pact_bleed()
	check(is_equal_approx(player.armor, player.max_armor / 3.0), "Blood Pact bleeds armor down to a third and no further (%.1f)" % player.armor)
	player.since_kill = 0.0
	var armor_before := player.armor
	mission._blood_pact_bleed()
	check(player.armor == armor_before, "Blood Pact doesn't bleed right after a kill")


## The reworked fusions do what their cards say.
func _fusions() -> void:
	# Storm Halo: a bullet crossing the fence between two saws is erased.
	var mission := _test_mission("planet")
	var world := mission.world
	mission.run.tech_level["orbital_halo"] = 5
	mission.run.fusions.append("storm_halo")
	world.enemies.clear()
	mission.weapons._orbital_halo(0.0)
	var saws: Array = world.events.filter(func(e): return e["type"] == "halo")[-1]["saws"]
	var bullet := world.enemy_shot((saws[0] + saws[1]) * 0.5, 0.0, 0.0)
	mission.weapons._orbital_halo(0.0)
	check(bullet.dead, "Storm Halo's fence erases a bullet between two saws")
	# Event Horizon: a hex orb drags a small enemy toward it, then collapses in a burst.
	mission = _test_mission("planet")
	world = mission.world
	world.enemies.clear()
	var drifter := world.spawn_enemy("dart", Vector2(700, 400))
	drifter.hp = 9999.0
	var orb := world.player_shot(Vector2(620, 400), Vector2.ZERO, 10.0, "hex_repeater", "hex", Color.WHITE)
	orb.devours = true
	orb.life = 1.0
	var before := drifter.pos.distance_to(orb.pos)
	for i in 30:
		world.update_player_shots(World.DT)
	check(drifter.pos.distance_to(orb.pos) < before, "Event Horizon drags enemies toward the orb")
	for i in 60:
		world.update_player_shots(World.DT)
	check(orb.dead and drifter.hex_marked, "Event Horizon collapses in a burst that hexes what's around it")
	# A formation dart that dives off the top of the screen comes back to its slot (heromedel's 0.5 log:
	# one climbed away forever and the wave never ended).
	mission = _test_mission("star_cluster")
	world = mission.world
	world.enemies.clear()
	var diver := world.spawn_enemy("dart", Vector2(600, 20))
	diver.brain = "formation"
	diver.memory = {"slot": Vector2(600, 170)}
	diver.state = 2
	diver.timer = 2.0
	diver.facing = -PI * 0.5
	for i in 120:
		mission.enemy_system.update(World.DT)
	check(diver.state != 2 and diver.pos.y > -100.0, "a dart diving off the top of the screen returns to the formation")
	# Wraith Drive: dashing through an enemy hurts it and lets loose a spirit.
	mission = _test_mission("planet")
	world = mission.world
	world.enemies.clear()
	mission.run.fusions.append("wraith_drive")
	var target := world.spawn_enemy("splitter", mission.player.pos + Vector2(20, 0))
	target.hp = 9999.0
	mission.weapons._thruster_explosion()
	var shots_before := world.player_shots.size()
	var hp_before := target.hp
	mission.weapons._update_dash(World.DT)
	check(target.hp < hp_before and world.player_shots.size() > shots_before, "Wraith Drive tears through an enemy and releases a spirit")


## A mission saved mid-play (its launch through the save file's format, plus its inputs) and replayed lands in
## exactly the state it was left in: what resuming after the browser closes relies on.
func _resume() -> void:
	var node := {"id": "t", "name": "T", "region": 0, "column": 1, "row": 0.0, "type": "planet", "need": "x",
		"difficulty": 1.0, "danger": 2, "modifier": "", "reward_tech": "arc_blade", "prize": "", "prize_text": ""}
	var launch := {"node": node, "seed": 4242, "frame": "vanguard", "loadout": ["pulse_driver", "arc_blade", "", "", "nova_bomb"], "mk": {"pulse_driver": 2}}
	var first := Mission.new(launch["node"], launch["seed"], launch["frame"], launch["loadout"], func(t): return int(launch["mk"].get(t, 1)))
	var recording := InputRecording.new()
	for i in 1500:
		var frame := InputFrame.new()
		frame.move = Vector2.from_angle(i * 0.01) * 0.8
		frame.choice = 0 if first.state in ["offer", "crate"] else -1
		frame = frame.quantized()
		recording.add(frame)
		first.step(frame)
	var saved: Dictionary = str_to_var(var_to_str({"launch": launch, "inputs": recording.encode()}))
	var again_launch: Dictionary = saved["launch"]
	var again := Mission.new(again_launch["node"], again_launch["seed"], again_launch["frame"], again_launch["loadout"], func(t): return int(again_launch["mk"].get(t, 1)))
	for frame in InputFrame.decode_runs(saved["inputs"]):
		again.step(frame)
	check(again.tick == first.tick and again.player.pos.is_equal_approx(first.player.pos) and again.run.kills == first.run.kills
		and is_equal_approx(again.player.armor, first.player.armor), "a saved mission replays to exactly where it was left")


## In a dungeon, needle swarms come out of the room's walls (warning first), and never in a cleared room.
func _dungeon_needles() -> void:
	var mission := _test_mission("dungeon")
	mission.lesson_hazards.lesson = "needles"
	var hazards := mission.lesson_hazards
	var stage := mission.stage as DungeonStage
	stage.room_enemies = []
	for i in 600:
		hazards.update(World.DT)
	check(mission.world.enemy_shots.filter(func(s): return s.look == "needle").is_empty(), "no needles in a cleared dungeon room")
	var guard := mission.world.spawn_enemy("skullbot", stage.room_rect(stage.current).get_center())
	stage.room_enemies = [guard.id]
	mission.world.events.clear()
	for i in 420:
		hazards.update(World.DT)
	var warned := mission.world.events.any(func(e): return e["type"] == "needle_warning")
	var room := stage.room_rect(stage.current).grow(20.0)
	var needles := mission.world.enemy_shots.filter(func(s): return s.look == "needle")
	check(warned and not needles.is_empty() and needles.all(func(s): return room.has_point(s.pos)), "a dungeon room's needles come from its own walls, after a warning")


## Let go of the aim stick and the mech keeps its aim for a moment, so a special still fires where you aimed.
func _aim_hold() -> void:
	var mission := _test_mission("planet")
	var weapons := mission.weapons
	var aim := InputFrame.new()
	aim.aim = Vector2.RIGHT
	weapons._update_facing(aim)
	var walking := InputFrame.new()
	walking.move = Vector2.UP
	for i in 30:
		weapons._update_facing(walking)
	check(is_equal_approx(mission.player.facing, 0.0), "the mech keeps its aim just after the aim stick is let go")
	for i in 40:
		weapons._update_facing(walking)
	check(is_equal_approx(mission.player.facing, -PI * 0.5), "then it turns back to where it's walking")


## Build 0.6, hits that matter (GDD 13A-13W): one Armor pool read as hits, a Shield Generator that takes a
## whole hit, plating that grows, and the rules that keep defence a choice.
func _hits_that_matter() -> void:
	var mission := _test_mission("star_cluster")
	var world := mission.world
	var player := mission.player
	check(is_equal_approx(player.max_armor, 80.0), "the Vanguard has 60 Armor plus 20 built in (%.0f)" % player.max_armor)
	check(player.radius <= 8.0, "the ship's hitbox is smaller than its art")
	world.damage_player(10.0, "test")
	check(is_equal_approx(player.grace, FrameData.HIT_GRACE), "a hit buys a second of immunity")
	player.grace = 0.0
	world.damage_player(25.0, "test")
	check(is_equal_approx(player.grace, FrameData.HEAVY_HIT_GRACE), "a big hit buys a little longer")
	check(is_equal_approx(player.armor, 45.0), "hits come straight off Armor (%.0f)" % player.armor)
	# Shield Generator: blocks one hit of any size, then recharges.
	mission = _test_mission("star_cluster")
	world = mission.world
	player = mission.player
	mission.run.loadout[5] = "shield_generator"
	mission.run.tech_level["shield_generator"] = 1
	mission.weapons._shield_generator(World.DT)
	check(player.shield_charges == 1, "a Shield Generator comes online charged")
	var armor_before := player.armor
	world.damage_player(25.0, "test")
	check(player.armor == armor_before and player.shield_charges == 0, "the shield takes a whole heavy hit")
	for i in int(8.5 / World.DT):
		mission.weapons._shield_generator(World.DT)
	check(player.shield_charges == 1, "the shield comes back 8 s after it breaks")
	# DSP-1 Drop Plate: each level adds Armor at once.
	var max_before := player.max_armor
	mission.offers.apply({"kind": "upgrade", "tech": "dsp1_plate", "fork": "", "fusion": "", "field": ""})
	check(is_equal_approx(player.max_armor, max_before + 10.0), "a plating level adds 10 Armor")
	# Field Repair is a fixed three hits, and only once.
	check(UpgradeData.FIELD["field_repair"]["limit"] == 1, "Field Repair can only be taken once")
	# Orbital Halo: a saw breaks after eating three bullets.
	mission.run.loadout[1] = "orbital_halo"
	mission.run.tech_level["orbital_halo"] = 1
	world.enemy_shots.clear()
	mission.weapons._orbital_halo(0.0)
	var saw: Vector2 = player.pos + Vector2.from_angle(mission.weapons.halo_angle) * 88.0
	for i in 3:
		world.enemy_shot(saw, 0.0, 0.0)
		mission.weapons._orbital_halo(0.0)
	check(mission.weapons.halo_broken_until.size() == 1, "an Orbital Halo saw breaks after eating three bullets")
	# Harder means bigger hits past the first region; boss parts have less health than before.
	check(Mission.region_hits(1) > 1.0 and Mission.region_hits(3) > Mission.region_hits(2), "hits grow region by region")
	check(MissionData.BOSS_HEALTH < 1.0, "bosses are shorter fights now that hits matter")


## Build 0.6.1: Load and Output, heat and vents, frame tiers, the plates (GDD 21A–21H).
func _mission_with(loadout: Array, frame_id: String = "vanguard", tiers: Array = []) -> Mission:
	var node := {"id": "t", "name": "T", "region": 0, "column": 1, "row": 0.0, "type": "star_cluster", "need": "x",
		"difficulty": 1.0, "danger": 1, "modifier": "", "reward_tech": "arc_blade", "prize": "", "prize_text": ""}
	return Mission.new(node, 7, frame_id, loadout, func(t): return 3, tiers)


func _building_a_frame() -> void:
	# Frame tiers change the frame's numbers, and the mission uses them.
	var stats := FrameData.stats("vanguard", ["load", "output", "armor"])
	check(stats["load"] == 13 and stats["output"] == 10 and is_equal_approx(stats["armor"], 90.0), "tier picks add Load, Output and Armor")
	var tiered := _mission_with(TechData.STARTING_LOADOUT, "vanguard", ["armor", "cooling"])
	check(is_equal_approx(tiered.player.max_armor, 90.0) and is_equal_approx(tiered.run.frame_stats["heat_rate"], 0.75), "a mission flies the frame's tiers")
	# The starter runs cool; offline parts draw nothing.
	var mission := _mission_with(TechData.STARTING_LOADOUT)
	check(mission.run.online_draw() == 1 and mission.run.overclock_pips() < 0.0, "a mission starts within its Output")
	# An overclocked build heats up, vents and trips its powered parts.
	var hot := ["thunder_lance", "", "starfall", "", "ion_cannon", "shield_generator", "dsp1_plate"]
	check(TechData.loadout_weight(hot) <= 12 and TechData.loadout_draw(hot) == 12, "the hot test build fits and draws 12")
	mission = _mission_with(hot)
	for tech_id in ["starfall", "ion_cannon", "shield_generator"]:
		mission.run.tech_level[tech_id] = 1
	check(is_equal_approx(mission.run.overclock_pips(), 3.0), "three pips past the Vanguard's Output")
	var vented := false
	for i in int(16.0 / World.DT):
		mission.weapons._update_heat(World.DT)
		if mission.player.vent_trip > 0.0:
			vented = true
			break
	check(vented and is_equal_approx(mission.player.heat, WeaponSystem.VENT_HEAT_LEFT), "at full heat the frame vents and drops to 40%")
	check(mission.weapons.is_tripped("thunder_lance") and not mission.weapons.is_tripped("dsp1_plate"), "a vent trips powered parts, not unpowered ones")
	mission.player.shield_charges = 1
	var armor_before := mission.player.armor
	mission.world.damage_player(10.0, "test")
	check(mission.player.armor < armor_before, "a tripped Shield Generator can't block")
	# The Coolant Loop takes a pip off; the Auxiliary Generator adds Output.
	var cooled := hot.duplicate()
	cooled[3] = "coolant_loop"
	mission = _mission_with(cooled)
	for tech_id in ["starfall", "ion_cannon", "shield_generator"]:
		mission.run.tech_level[tech_id] = 1
	check(mission.run.is_online("coolant_loop") and is_equal_approx(mission.run.overclock_pips(), 2.0), "a Coolant Loop runs from the start and cools a pip")
	var powered := hot.duplicate()
	powered[3] = "aux_generator"
	mission = _mission_with(powered)
	check(mission.run.mawjig_output() == 12, "an Auxiliary Generator adds 3 Output")
	# An Overheat Core's vent on a build within its Output is clean.
	var cored := TechData.STARTING_LOADOUT.duplicate()
	cored[3] = "overheat_core"
	mission = _mission_with(cored)
	mission.run.tech_level["overheat_core"] = 1
	mission.weapons._add_heat(100.0)
	check(mission.player.vent_trip <= 0.0 and is_equal_approx(mission.player.heat, WeaponSystem.VENT_HEAT_LEFT), "a core vent within Output never trips parts")
	# The Hangar's power summary and the launch rule.
	var summary_loadout := ["pulse_driver", "swarm_pods", "orbital_halo", "option_pods", "nova_bomb", "shield_generator", "lunarium_plate"]
	check(TechData.loadout_weight(summary_loadout) > 12, "a greedy build overflows the Vanguard's Load")
	# Plates.
	var plated := TechData.STARTING_LOADOUT.duplicate()
	plated[6] = "qrf_shell"
	mission = _mission_with(plated)
	check(is_equal_approx(mission.player.max_armor, 70.0) and is_equal_approx(mission.run.plate_speed(), 0.1), "QRF Shell: 10 less Armor, 10% faster")
	plated[6] = "jig_weave_plate"
	mission = _mission_with(plated)
	armor_before = mission.player.armor
	mission.world.damage_player(10.0, "bullet")
	check(mission.player.armor == armor_before, "Jig-Weave shrugs off a light hit")
	mission.player.grace = 0.0
	mission.world.damage_player(10.0, "bullet")
	check(mission.player.armor < armor_before, "and needs a while before it can again")
	plated[6] = "jig_phase_plate"
	mission = _mission_with(plated)
	mission.world.damage_player(20.0, "bullet")
	check(is_equal_approx(mission.player.armor, 70.0) and is_equal_approx(mission.player.phase_held, 10.0), "Jig Phase holds half a hit off")
	for i in int(3.2 / World.DT):
		mission.player.tick_timers(World.DT)
	check(mission.player.phase_held == 0.0 and is_equal_approx(mission.player.armor, 70.0), "and it fades if nothing else lands")
	plated[6] = "lunarium_plate"
	mission = _mission_with(plated)
	var max_before := mission.player.max_armor
	mission.world.damage_player(10.0, "bullet")
	check(is_equal_approx(mission.player.max_armor, max_before + 1.0), "Lunarium work-hardens with each hit")
	plated[6] = "mirrorwork_plate"
	mission = _mission_with(plated)
	armor_before = mission.player.armor
	mission.world.damage_player(20.0, "laser")
	check(is_equal_approx(armor_before - mission.player.armor, 10.0), "Mirrorwork halves a beam")
	# A boss-named plate pays only when its boss falls; prizes can carry several rewards at a higher Mk.
	var boss_node := {"id": "t", "name": "T", "region": 0, "column": 1, "row": 0.0, "type": "star_cluster", "need": "x",
		"difficulty": 1.0, "danger": 1, "modifier": "", "reward_tech": "mirrorwork_plate", "prize": "", "prize_text": "", "frame_blueprints": 2}
	mission = Mission.new(boss_node, 7, "vanguard", TechData.STARTING_LOADOUT, func(t): return 1)
	var lost := mission.results(false)
	check(not lost["blueprints"].has("mirrorwork_plate"), "a boss plate isn't paid for a loss")
	mission.state = "won"
	var won := mission.results(false)
	check(int(won["blueprints"].get("mirrorwork_plate", 0)) > 0 and won["frame_blueprints"] == 2, "a win pays the boss plate and the Frame Blueprints")
	check(TechData.has_forks("pulse_driver") and not TechData.has_forks("qrf_shell"), "plates level without forks")
