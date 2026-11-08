class_name UpgradeOffers
extends RefCounted
## Builds the cards offered at level-ups and treasure pedestals, applies the one picked, rerolls,
## and spins Salvage Crate reels (GDD 7C, 9H).
## Every card says what it builds toward (GDD 9H): the Resonance points it adds and whether it unlocks a
## tier, and whether it moves you toward a fusion. Risky cards trade a real cost for big power.
## A card is a Dictionary: {kind, tech, fork, fusion, field, title, text, rarity, weight, element, points,
## synergy, fusion_hint}. Kinds: online, upgrade, fork, fusion, field, cache.

const REROLL_CHOICE := 9
const ROMAN := ["", "I", "II", "III"]

var world: World
var run: RunState


func _init(target_world: World) -> void:
	world = target_world
	run = world.run


func build_cards(count: int) -> Array:
	var pool := _card_pool(true, true)
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
		cards.append(_cache_card())
	for card in cards:
		_describe_build_effect(card)
	return cards


func _card_pool(include_forks: bool, include_risky: bool) -> Array:
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
		card["element"] = upgrade.get("element", "")
		pool.append(card)
	if include_risky:
		for upgrade_id in UpgradeData.RISKY_FIELD:
			if run.field_count(upgrade_id) > 0:
				continue
			var upgrade: Dictionary = UpgradeData.RISKY_FIELD[upgrade_id]
			var card := _card("field", "", upgrade["name"], upgrade["text"], "risky", 0.45)
			card["field"] = upgrade_id
			card["element"] = upgrade["element"]
			pool.append(card)
	return pool


func _card(kind: String, tech_id: String, title: String, text: String, rarity: String, weight: float) -> Dictionary:
	return {"kind": kind, "tech": tech_id, "fork": "", "fusion": "", "field": "",
		"title": title, "text": text, "rarity": rarity, "weight": weight,
		"element": TechData.TECH[tech_id]["element"] if tech_id != "" else "", "points": 0, "synergy": "", "fusion_hint": ""}


## When everything is maxed out: something still worth having.
func _cache_card() -> Dictionary:
	return _card("cache", "", "Salvage Cache", "Gain a reroll and repair 15 armor.", "common", 1.0)


## Fills in the card's build lines: Resonance progress or a tier unlock, and fusion progress.
func _describe_build_effect(card: Dictionary) -> void:
	var element: String = card["element"]
	var points := 0
	match card["kind"]:
		"online", "upgrade", "fork":
			points = 1
		"field":
			points = UpgradeData.FIELD_RESONANCE_POINTS
	card["points"] = points
	if element != "" and points > 0 and UpgradeData.RESONANCE.has(element):
		var before := run.resonance_points(element)
		var after := before + points
		var tier_before := run.resonance_tier(element)
		var tier_after := 0
		for threshold in UpgradeData.RESONANCE_THRESHOLDS:
			if after >= threshold:
				tier_after += 1
		var name: String = UpgradeData.RESONANCE[element]["name"]
		if tier_after > tier_before:
			var tier: Array = UpgradeData.RESONANCE[element]["tiers"][tier_after - 1]
			card["synergy"] = "Unlocks %s Resonance %s: %s" % [name, ROMAN[tier_after], tier[0]]
		elif tier_after < UpgradeData.RESONANCE_THRESHOLDS.size():
			card["synergy"] = "+%d %s  (%d/%d)" % [points, name, after, UpgradeData.RESONANCE_THRESHOLDS[tier_after]]
		else:
			card["synergy"] = "+%d %s (maxed)" % [points, name]
	if card["tech"] != "":
		for fusion_id in UpgradeData.FUSIONS:
			var needs: Array = UpgradeData.FUSIONS[fusion_id]["needs"]
			if needs.has(card["tech"]) and not run.has_fusion(fusion_id):
				var partner: String = needs[0] if needs[1] == card["tech"] else needs[1]
				if run.loadout.has(partner):
					card["fusion_hint"] = "Toward fusion: %s" % UpgradeData.FUSIONS[fusion_id]["name"]


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
	var tiers_before := run.resonance_tiers()
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
			_apply_field_now(card["field"])
		"cache":
			run.rerolls += 1
			player.repair(15.0)
	world.emit("sound", {"name": "upgrade"})
	_announce_resonance(tiers_before)


## Field upgrades that change something the moment they're taken.
func _apply_field_now(upgrade_id: String) -> void:
	var player := world.player
	match upgrade_id:
		"field_repair":
			player.repair(player.max_armor * 0.4)
		"glass_reactor":
			player.max_shield = 0.0
			player.shield = 0.0
		"adrenaline_junkie":
			world.bullet_speed_scale *= 1.15


func _announce_resonance(tiers_before: Dictionary) -> void:
	for element in UpgradeData.ELEMENTS:
		var tier := run.resonance_tier(element)
		if tier > int(tiers_before.get(element, 0)):
			var info: Dictionary = UpgradeData.RESONANCE[element]
			world.emit("banner", {"text": "%s RESONANCE %s" % [info["name"].to_upper(), ROMAN[tier]], "style": element})
			world.emit("resonance", {"element": element, "tier": tier})
			world.emit("sound", {"name": "overdrive"})


## Rerolls the current offer. Returns the new cards, or an empty array when no rerolls are left.
func reroll(count: int) -> Array:
	if run.rerolls <= 0:
		return []
	run.rerolls -= 1
	return build_cards(count)


## Spins a Salvage Crate: lands on 1, 3 or 5 upgrades and applies them. Returns the cards it landed on.
## Crates never pick forks, fusions or risky cards for you; those are always your choice.
func open_crate() -> Array:
	var count := _roll_reel()
	if run.field_count("lucky_salvage") > 0:
		count = maxi(count, 3)
	var results := []
	for i in count:
		var pool := _card_pool(false, false).filter(func(c): return c["field"] != "field_repair" and c["kind"] != "fusion")
		var card: Dictionary = _cache_card() if pool.is_empty() else _pick_weighted(pool)
		_describe_build_effect(card)
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
