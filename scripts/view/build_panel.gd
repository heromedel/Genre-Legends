class_name BuildPanel
## The Build screen (GDD 9H): everything about your current build in one place, so you can pause and plan.
## Each tech's level, fork and next step; Resonance progress and what each tier does; fusion progress;
## field upgrades taken; rerolls left. Shown from the pause menu and from the level-up screen.


static func build(run: RunState) -> Control:
	var panel := UiKit.panel(Color(0.03, 0.05, 0.09, 0.97), Color(0.3, 0.5, 0.7))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(560, 520)
	panel.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 6)
	scroll.add_child(column)
	column.add_child(UiKit.label("YOUR BUILD", 22, Color(0.6, 0.9, 1.0), "title"))
	column.add_child(UiKit.label("Mission level %d   •   Rerolls left: %d" % [run.level, run.rerolls], 15, Color(0.7, 0.8, 0.92)))
	_tech_section(column, run)
	_resonance_section(column, run)
	_fusion_section(column, run)
	_field_section(column, run)
	return panel


static func _tech_section(column: VBoxContainer, run: RunState) -> void:
	column.add_child(UiKit.label("TECH", 15, Art.GOLD, "bold"))
	for tech_id in run.loadout:
		if tech_id == "":
			continue
		var tech: Dictionary = TechData.TECH[tech_id]
		var level := run.level_of(tech_id)
		var cap: int = run.tech_cap.get(tech_id, 3)
		var fork := run.fork_of(tech_id)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var color: Color = TechData.ELEMENT_COLORS.get(tech["element"], Color.WHITE)
		row.add_child(IconView.make(tech_id, 30, color if level > 0 else Color(0.4, 0.45, 0.55)))
		var text := VBoxContainer.new()
		text.add_theme_constant_override("separation", 0)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var title: String = tech["name"] if fork == "" else "%s: %s" % [tech["name"], TechData.fork_name(tech_id, fork)]
		text.add_child(UiKit.label("%s   Lv %d/%d" % [title, level, cap], 15, Color(1, 1, 1) if level > 0 else Color(0.6, 0.65, 0.75), "bold"))
		var next := ""
		if level == 0:
			next = "Offline. A level-up or crate brings it online."
		elif level >= cap:
			next = "Capped by Mk %d (raise it in R&D)" % int(run.tech_mk.get(tech_id, 1)) if cap < TechData.MAX_LEVEL else "Maxed"
		elif level + 1 == TechData.FORK_LEVEL and fork == "":
			next = "Next: choose a path, %s or %s." % [tech["forks"]["a"]["name"], tech["forks"]["b"]["name"]]
		else:
			next = "Next: %s" % TechData.level_text(tech_id, level + 1)
		text.add_child(UiKit.wrapped(next, 14, Color(0.7, 0.8, 0.9)))
		row.add_child(text)
		column.add_child(row)


static func _resonance_section(column: VBoxContainer, run: RunState) -> void:
	column.add_child(UiKit.label("RESONANCE (levels of one element add up)", 15, Art.GOLD, "bold"))
	for element in UpgradeData.ELEMENTS:
		var info: Dictionary = UpgradeData.RESONANCE[element]
		var points := run.resonance_points(element)
		var tier := run.resonance_tier(element)
		var color: Color = TechData.ELEMENT_COLORS[element]
		var thresholds: Array = UpgradeData.RESONANCE_THRESHOLDS
		if points <= 0:
			continue
		var progress := "all tiers unlocked" if tier >= thresholds.size() else "%d/%d to tier %s" % [points, thresholds[tier], UpgradeOffers.ROMAN[tier + 1]]
		column.add_child(UiKit.label("%s   %s" % [info["name"], progress], 16, color, "bold"))
		# Only what's active now, and the very next thing to aim for.
		for i in tier:
			var entry: Array = info["tiers"][i]
			column.add_child(UiKit.wrapped("Active: %s, %s" % [entry[0], entry[1].to_lower()], 14, color))
		if tier < thresholds.size():
			var upcoming: Array = info["tiers"][tier]
			column.add_child(UiKit.wrapped("Next: %s, %s" % [upcoming[0], upcoming[1].to_lower()], 14, Color(0.62, 0.68, 0.78)))


static func _fusion_section(column: VBoxContainer, run: RunState) -> void:
	# Only fusions this mission can reach (or has made); the rest are goals for R&D, not for now.
	var lines := []
	for fusion_id in UpgradeData.FUSIONS:
		var fusion: Dictionary = UpgradeData.FUSIONS[fusion_id]
		if run.has_fusion(fusion_id):
			lines.append(["%s: fused!" % fusion["name"], Art.GOLD])
		elif run.can_fuse(fusion_id):
			var parts := []
			for needed in fusion["needs"]:
				parts.append("%s %d/%d" % [TechData.TECH[needed]["name"], run.level_of(needed), TechData.MAX_LEVEL])
			lines.append(["%s: %s" % [fusion["name"], " + ".join(parts)], Color(0.8, 0.65, 1.0)])
	if lines.is_empty():
		return
	column.add_child(UiKit.label("FUSIONS (both tech at level 5)", 15, Art.GOLD, "bold"))
	for line in lines:
		column.add_child(UiKit.wrapped(line[0], 13, line[1]))


static func _field_section(column: VBoxContainer, run: RunState) -> void:
	if run.field.is_empty():
		return
	column.add_child(UiKit.label("FIELD UPGRADES", 15, Art.GOLD, "bold"))
	for upgrade_id in run.field:
		var upgrade := UpgradeData.field_upgrade(upgrade_id)
		var risky := UpgradeData.RISKY_FIELD.has(upgrade_id)
		var count := int(run.field[upgrade_id])
		column.add_child(UiKit.wrapped("%s%s: %s" % [upgrade["name"], (" x%d" % count) if count > 1 else "", upgrade["text"]], 13,
			Color(1, 0.5, 0.45) if risky else Color(0.6, 1.0, 0.7)))
