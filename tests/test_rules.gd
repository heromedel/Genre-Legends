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
