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
	print("%d checks, %d failed" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _tech_data() -> void:
	for tech_id in TechData.TECH:
		var tech: Dictionary = TechData.TECH[tech_id]
		check(TechData.SLOTS.has(tech["slot"]), "%s has a real slot" % tech_id)
		check(tech["forks"].has("a") and tech["forks"].has("b"), "%s has two forks" % tech_id)
		check(tech["levels"].size() == TechData.MAX_LEVEL, "%s describes every level" % tech_id)
		check(not tech["blueprint_from"].is_empty(), "%s drops from some mission type" % tech_id)
	for slot_index in TechData.STARTING_LOADOUT.size():
		var tech_id: String = TechData.STARTING_LOADOUT[slot_index]
		if tech_id != "":
			check(TechData.TECH[tech_id]["slot"] == TechData.SLOTS[slot_index], "starting %s fits slot %d" % [tech_id, slot_index])
	check(not TechData.STARTING_UNLOCKS.has("mirror_aegis") and not TechData.STARTING_UNLOCKS.has("swarm_pods"), "lesson tech is held back (GDD 9C)")
	for element in UpgradeData.ELEMENTS:
		check(UpgradeData.RESONANCE[element]["tiers"].size() == UpgradeData.RESONANCE_THRESHOLDS.size(), "%s resonance describes every tier" % element)
	for tech_id in TechData.TECH:
		check(UpgradeData.ELEMENTS.has(TechData.TECH[tech_id]["element"]), "%s has a resonance element" % tech_id)
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
	# Ricochet shots fly out of view, glance off something out there and come back in, weaker.
	var shot := world.player_shot(Vector2(world.bounds.end.x - 2.0, 300.0), Vector2(900, 0), 5.0, "pulse_driver", "bolt", Color.WHITE)
	shot.bounces = 2
	var went_out := false
	var came_back := false
	for i in 40:
		world.update_player_shots(World.DT)
		went_out = went_out or not world.bounds.has_point(shot.pos)
		came_back = came_back or (went_out and shot.bounces == 1 and world.bounds.has_point(shot.pos))
	check(went_out and came_back and not shot.dead and shot.vel.x < 0.0 and shot.damage < 5.0,
		"ricochet leaves the screen and glances back in, weaker")
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
	world.player.shield = 5.0
	world.damage_player(20.0, "test")
	check(near.hp < near_hp, "Capacitor Discharge strikes when the shield breaks")


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
	player.shield = 0.0
	player.shield_delay = 0.0
	mission._update_world(InputFrame.new(), true)
	check(player.shield > 0.0, "Blood Pact leaves the shield recharging")


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
