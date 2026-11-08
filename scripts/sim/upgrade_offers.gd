class_name UpgradeOffers
extends RefCounted
## Builds the cards offered at level-ups and treasure pedestals, applies the one picked, and spins
## Salvage Crate reels (GDD 7C: tech is powered up inside the mission, with an occasional slot machine).
## A card is a Dictionary: {kind, tech, fork, fusion, field, title, text, rarity}.
## Kinds: online (bring equipped tech online), upgrade, fork (one of two paths), fusion, field, repair.

var world: World
var run: RunState


func _init(target_world: World) -> void:
	world = target_world
	run = world.run


func build_cards(count: int) -> Array:
	var pool := _card_pool(true)
	var cards := []
	while cards.size() < count and not pool.is_empty():
		var picked: Dictionary = _pick_weighted(pool)
		pool.erase(picked)
		cards.append(picked)
		# Forks come as a pair: if one fork is offered, its sibling is offered next to it.
		if picked["kind"] == "fork":
			for other in pool.duplicate():
				if other["kind"] == "fork" and other["tech"] == picked["tech"]:
					pool.erase(other)
					if cards.size() < count + 1:
						cards.append(other)
	if cards.is_empty():
		cards.append(_repair_card())
	return cards


func _card_pool(include_forks: bool) -> Array:
	var pool := []
	var online_count := run.online_tech().size()
	for tech_id in run.loadout:
		if tech_id == "":
			continue
		var level := run.level_of(tech_id)
		var cap: int = run.tech_cap.get(tech_id, 3)
		var tech: Dictionary = TechData.TECH[tech_id]
		if level == 0:
			pool.append(_card("online", tech_id, tech["name"], tech["text"], "rare", 3.2 if online_count < 3 else 2.0))
		elif level < cap:
			var next := level + 1
			if next == TechData.FORK_LEVEL and run.fork_of(tech_id) == "":
				if include_forks:
					for fork in ["a", "b"]:
						var card := _card("fork", tech_id, "%s: %s" % [tech["name"], tech["forks"][fork]["name"]],
							tech["forks"][fork]["text"], "epic", 1.6)
						card["fork"] = fork
						pool.append(card)
			else:
				var fork_name := TechData.fork_name(tech_id, run.fork_of(tech_id))
				var title := "%s  Lv %d" % [tech["name"] if fork_name == "" else fork_name, next]
				pool.append(_card("upgrade", tech_id, title, TechData.level_text(tech_id, next), "common", 1.6))
	for fusion_id in UpgradeData.FUSIONS:
		var fusion: Dictionary = UpgradeData.FUSIONS[fusion_id]
		if run.has_fusion(fusion_id):
			continue
		var ready := true
		for needed in fusion["needs"]:
			if run.level_of(needed) < TechData.MAX_LEVEL:
				ready = false
		if ready:
			var card := _card("fusion", "", "FUSION: %s" % fusion["name"], fusion["text"], "legendary", 6.0)
			card["fusion"] = fusion_id
			pool.append(card)
	for upgrade_id in UpgradeData.FIELD:
		var upgrade: Dictionary = UpgradeData.FIELD[upgrade_id]
		if run.field_count(upgrade_id) >= upgrade["limit"]:
			continue
		var weight := 0.7
		if upgrade_id == "field_repair":
			weight = 2.2 if world.player.armor_fraction() < 0.6 else 0.25
		var card := _card("field", "", upgrade["name"], upgrade["text"], "field", weight)
		card["field"] = upgrade_id
		pool.append(card)
	return pool


func _card(kind: String, tech_id: String, title: String, text: String, rarity: String, weight: float) -> Dictionary:
	return {"kind": kind, "tech": tech_id, "fork": "", "fusion": "", "field": "",
		"title": title, "text": text, "rarity": rarity, "weight": weight}


func _repair_card() -> Dictionary:
	return _card("repair", "", "Patch Job", "Everything's maxed. Repair 30 armor.", "common", 1.0)


func _pick_weighted(pool: Array) -> Dictionary:
	var total := 0.0
	for card in pool:
		total += card["weight"]
	var roll := world.rng.randf() * total
	for card in pool:
		roll -= card["weight"]
		if roll <= 0.0:
			return card
	return pool[pool.size() - 1]


func apply(card: Dictionary) -> void:
	var player := world.player
	match card["kind"]:
		"online":
			run.tech_level[card["tech"]] = 1
			run.tech_timer[card["tech"]] = 0.0
			if TechData.TECH[card["tech"]]["slot"] == "special":
				player.special_charges = 1
				player.special_cooldown = 0.0
			world.emit("banner", {"text": "%s ONLINE" % TechData.TECH[card["tech"]]["name"].to_upper(), "style": "cyan"})
		"upgrade":
			run.tech_level[card["tech"]] = run.level_of(card["tech"]) + 1
		"fork":
			run.forks[card["tech"]] = card["fork"]
			run.tech_level[card["tech"]] = TechData.FORK_LEVEL
			world.emit("banner", {"text": TechData.fork_name(card["tech"], card["fork"]).to_upper(), "style": "violet"})
		"fusion":
			run.fusions.append(card["fusion"])
			world.emit("banner", {"text": "FUSION: %s" % UpgradeData.FUSIONS[card["fusion"]]["name"].to_upper(), "style": "gold"})
			world.emit("flash", {"color": Color(1, 0.85, 0.4), "amount": 0.5})
		"field":
			run.field[card["field"]] = run.field_count(card["field"]) + 1
			if card["field"] == "field_repair":
				player.repair(player.max_armor * 0.4)
		"repair":
			player.repair(30.0)
	world.emit("sound", {"name": "upgrade"})


## Spins a Salvage Crate: lands on 1, 3 or 5 upgrades and applies them. Returns the cards it landed on.
func open_crate() -> Array:
	var count := _roll_reel()
	if run.field_count("lucky_salvage") > 0:
		count = maxi(count, 3)
	var results := []
	for i in count:
		var pool := _card_pool(false).filter(func(c): return c["field"] != "field_repair" and c["kind"] != "fusion")
		if pool.is_empty():
			var card := _repair_card()
			apply(card)
			results.append(card)
			continue
		var card: Dictionary = _pick_weighted(pool)
		apply(card)
		results.append(card)
	run.crates_opened += 1
	return results


func _roll_reel() -> int:
	var total := 0
	for entry in UpgradeData.CRATE_REEL:
		total += entry[1]
	var roll := world.rng.randi() % total
	for entry in UpgradeData.CRATE_REEL:
		roll -= entry[1]
		if roll < 0:
			return entry[0]
	return 1
