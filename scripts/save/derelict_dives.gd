class_name DerelictDives
## Runs a Derelict Dive (DepotData): a scan turns up three wrecks, you pick one, and the drone's haul is rolled
## and paid into Save. The scan is saved, so leaving the Depot never loses a dive you paid for. Dives are
## outside the mission simulation, so any randomness is fine here.
##   Common: 2 blueprints, or 1 Frame Blueprint from a carrier.
##   Rare: 5 blueprints, or 3 Frame Blueprints from a carrier.
##   Prototype: a tech you haven't unlocked yet, at Mk 1 (from the wreck's kind of slots when it can be).

static var rng := RandomNumberGenerator.new()


## Pays for a scan (or uses a free dive) and returns the three wrecks found, or [] if you can't afford one.
static func scan() -> Array:
	if not Save.data["dive_wrecks"].is_empty():
		return Save.data["dive_wrecks"]
	if Save.data["free_dives"] > 0:
		Save.data["free_dives"] -= 1
	elif Save.data["crystals"] >= DepotData.DIVE_COST:
		Save.data["crystals"] -= DepotData.DIVE_COST
	else:
		return []
	rng.randomize()
	var kinds := DepotData.WRECKS.keys()
	var wrecks := []
	while wrecks.size() < 3:
		var kind: String = kinds[rng.randi() % kinds.size()]
		if not wrecks.has(kind):
			wrecks.append(kind)
	Save.data["dive_wrecks"] = wrecks
	PlayLog.note("depot", "Derelict scan: %s" % ", ".join(wrecks))
	Save.write()
	return wrecks


## Boards one of the scanned wrecks and returns {rarity, title, text, icon}.
static func board(kind: String) -> Dictionary:
	if not Save.data["dive_wrecks"].has(kind):
		return {}
	Save.data["dive_wrecks"] = []
	rng.randomize()
	var wreck: Dictionary = DepotData.WRECKS[kind]
	var rarity := _roll_rarity(float(wreck["prototype"]))
	Save.data["dives_since_rare"] = 0 if rarity != "common" else int(Save.data["dives_since_rare"]) + 1
	var result := _haul(rarity, wreck)
	result["wreck"] = wreck["name"]
	PlayLog.note("depot", "Boarded the %s: %s %s" % [wreck["name"], rarity, result["title"]])
	Save.write()
	return result


static func _roll_rarity(prototype_odds: float) -> String:
	if int(Save.data["dives_since_rare"]) >= DepotData.PITY - 1:
		return "rare"
	var weights: Dictionary = DepotData.RARITY_WEIGHTS.duplicate()
	weights["legendary"] *= prototype_odds
	var total := 0.0
	for weight in weights.values():
		total += weight
	var roll := rng.randf() * total
	for rarity in weights:
		roll -= weights[rarity]
		if roll <= 0.0:
			return rarity
	return "common"


static func _haul(rarity: String, wreck: Dictionary) -> Dictionary:
	var slots: Array = wreck["slots"]
	if rarity == "legendary":
		var locked := TechData.findable_ids().filter(func(t): return Save.tech_mk(t) == 0)
		var fitting := locked.filter(func(t): return slots.has(TechData.TECH[t]["slot"]))
		var pool: Array = fitting if not fitting.is_empty() else locked
		if not pool.is_empty():
			var tech_id: String = pool[rng.randi() % pool.size()]
			Save.unlock_tech(tech_id)
			return _result(rarity, TechData.TECH[tech_id]["name"], "Prototype unlocked at Mk 1. It's in the Hangar.", tech_id)
		rarity = "rare"
	if slots.is_empty():
		var frame_blueprints := 3 if rarity == "rare" else 1
		Save.data["frame_blueprints"] += frame_blueprints
		return _result(rarity, "Frame Blueprints x%d" % frame_blueprints, "For frame tiers in the Hangar.", "frame_blueprint")
	return _blueprints(rarity, 5 if rarity == "rare" else 2, slots)


## Blueprints of one tech from the wreck's slots: half the time something you have equipped.
static func _blueprints(rarity: String, amount: int, slots: Array) -> Dictionary:
	var fits := func(t): return slots.has(TechData.TECH[t]["slot"])
	var owned: Array = TechData.findable_ids() + Save.data["tech_mk"].keys()
	var equipped: Array = Save.data["loadout"].filter(func(t): return t != "" and fits.call(t) and Save.tech_mk(t) < TechData.MAX_MK)
	var findable: Array = owned.filter(func(t): return fits.call(t) and Save.tech_mk(t) < TechData.MAX_MK)
	if findable.is_empty() and equipped.is_empty():
		Save.data["frame_blueprints"] += 1
		return _result(rarity, "Frame Blueprints x1", "Everything aboard was already maxed, so the drone took its frame plans.", "frame_blueprint")
	var pool: Array = equipped if not equipped.is_empty() and rng.randf() < 0.5 else findable
	var tech_id: String = pool[rng.randi() % pool.size()]
	Save.add_blueprints(tech_id, amount)
	var mk := Save.tech_mk(tech_id)
	var need := TechData.blueprints_for_next_mk(mk)
	var have := Save.blueprints(tech_id)
	var progress := ("%d / %d toward unlocking it" % [have, need]) if mk == 0 else ("%d / %d toward Mk %d" % [have, need, mk + 1])
	if have >= need:
		progress = "Ready to unlock in R&D!" if mk == 0 else "Ready for Mk %d in R&D!" % (mk + 1)
	return _result(rarity, "%s x%d" % [TechData.TECH[tech_id]["name"], amount], progress, tech_id)


static func _result(rarity: String, title: String, text: String, icon: String) -> Dictionary:
	return {"rarity": rarity, "title": title, "text": text, "icon": icon}
