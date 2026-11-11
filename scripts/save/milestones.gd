class_name Milestones
## Checks milestones after every mission, won or lost (GDD 9D), pays their rewards into Save, and queues
## the radio announcement when one brings a new enemy into the galaxy. Returns what was earned so the
## results screen can show it.


static func record_mission(result: Dictionary) -> Array:
	var data: Dictionary = Save.data
	var counters: Dictionary = data["counters"]
	_add(counters, "losses", 0 if result["won"] else 1)
	_add(counters, "forks", result["forks"].size())
	_add(counters, "crates", result["crates"])
	for kind in result.get("kills_by_kind", {}):
		_add(counters, "kill_" + kind, int(result["kills_by_kind"][kind]))
	for boss_look in result.get("bosses_defeated", []):
		_add(counters, "boss_" + boss_look, 1)
	var earned := []
	for milestone in MilestoneData.MILESTONES:
		var milestone_id: String = milestone["id"]
		if data["milestones"].has(milestone_id):
			continue
		if _met(milestone, result, counters):
			data["milestones"][milestone_id] = true
			earned.append(milestone)
			_pay(milestone)
			PlayLog.note("milestone", "%s earned (%s)" % [milestone["name"], milestone["reward"]])
	return earned


static func _add(counters: Dictionary, key: String, amount: int) -> void:
	counters[key] = int(counters.get(key, 0)) + amount


static func _met(milestone: Dictionary, result: Dictionary, counters: Dictionary) -> bool:
	if milestone.has("counter"):
		return int(counters.get(milestone["counter"], 0)) >= int(milestone["goal"])
	var won: bool = result["won"]
	match milestone["id"]:
		"first_sortie": return won
		"resonant": return int(result.get("max_resonance", 0)) >= 2
		"resonance_master": return int(result.get("max_resonance", 0)) >= 3
		"fused": return not result["fusions"].is_empty()
		"gatebreaker": return won and result.get("is_gate", false)
		"comeback": return won and float(result.get("armor_left", 1.0)) < 0.15
		"untouchable": return result.get("boss_untouched", false)
		"purist": return won and result.get("only_main", false)
		"glass_cannon": return won and result.get("field", {}).has("glass_reactor")
		"veteran_ace": return won and result.get("threat", "") == "veteran" and float(result.get("min_armor", 0.0)) >= 0.5
		"explorer": return won and result.get("secret_found", false)
	return false


static func _pay(milestone: Dictionary) -> void:
	Save.add_crystals(DepotData.MILESTONE_CRYSTALS, "milestone %s" % milestone["name"])
	var parts: PackedStringArray = milestone["reward"].split(":")
	match parts[0]:
		"blueprints":
			Save.add_blueprints(parts[1], int(parts[2]))
		"random_blueprints":
			var ids := TechData.findable_ids()
			for i in int(parts[1]):
				Save.add_blueprints(ids[randi() % ids.size()], 1)
		"tech":
			if Save.tech_mk(parts[1]) == 0:
				Save.unlock_tech(parts[1])
				Save.queue_radio("Milestone \"%s\": %s unlocked. It's in the Hangar." % [milestone["name"], TechData.TECH[parts[1]]["name"]])
			else:
				Save.add_blueprints(parts[1], 4)
		"enemy":
			if not Save.data["enemies_unlocked"].has(parts[1]):
				Save.data["enemies_unlocked"].append(parts[1])
				Save.queue_radio(MilestoneData.ENEMY_ANNOUNCEMENTS.get(parts[1], "Something new is out there."))


static func reward_text(milestone: Dictionary) -> String:
	return "%s, +%d Mawjig Crystals" % [_reward_text(milestone), DepotData.MILESTONE_CRYSTALS]


static func _reward_text(milestone: Dictionary) -> String:
	var parts: PackedStringArray = milestone["reward"].split(":")
	match parts[0]:
		"blueprints": return "%s %s blueprints" % [parts[2], TechData.TECH[parts[1]]["name"]]
		"random_blueprints": return "%s random blueprints" % parts[1]
		"tech": return "Unlocks %s" % TechData.TECH[parts[1]]["name"]
		"enemy": return "A new enemy enters the galaxy"
	return ""
