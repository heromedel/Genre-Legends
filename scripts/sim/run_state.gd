class_name RunState
extends RefCounted
## Everything about the player's power inside one mission: which tech is online and at what level,
## forks and fusions chosen, field upgrades, XP, and the tally shown on the results screen.
## It survives a hand-off from one stage to another inside the same mission (GDD 6G proposal).

var frame_id := "vanguard"
var loadout: Array = []         # tech ids by slot, "" for empty
var tech_level := {}            # tech id -> in-mission level, 0 = equipped but offline
var tech_cap := {}              # tech id -> highest level allowed by its R&D Mk
var tech_mk := {}               # tech id -> R&D Mk, for the damage bonus
var forks := {}                 # tech id -> "a" or "b"
var fusions: Array = []
var field := {}                 # field upgrade id -> times taken
var tech_timer := {}            # tech id -> seconds until it fires again

var level := 1
var xp := 0.0
var xp_to_next := 10.0
var rerolls := UpgradeData.REROLLS
var hit_counter := 0            # Energy resonance counts hits to know when to arc

# Tally
var kills := 0
var damage_dealt := 0.0
var damage_taken := 0.0
var blueprints := {}            # tech id -> blueprints picked up this mission
var crates_opened := 0
var shards_missed := 0
var kills_by_kind := {}         # for milestones (GDD 9D)
var bosses_defeated: Array = []  # boss look ids, for the Guide to Guardians
var boss_hits := 0              # hits taken while a boss is on the field
var min_armor_fraction := 1.0
var max_resonance := 0
var hits_taken := 0


func setup(frame: String, equipped: Array, mk_lookup: Callable) -> void:
	frame_id = frame
	loadout = equipped.duplicate()
	for slot_index in loadout.size():
		var tech_id: String = loadout[slot_index]
		if tech_id == "":
			continue
		var mk: int = maxi(1, mk_lookup.call(tech_id))
		tech_mk[tech_id] = mk
		tech_cap[tech_id] = TechData.MK_LEVEL_CAP[mk]
		# GDD 7D: only the main weapon starts online.
		tech_level[tech_id] = 1 if slot_index == 0 else 0
		tech_timer[tech_id] = 0.0


func main_weapon() -> String:
	return loadout[0]


func special_tech() -> String:
	return loadout[4] if loadout.size() > 4 else ""


func level_of(tech_id: String) -> int:
	return int(tech_level.get(tech_id, 0))


func is_online(tech_id: String) -> bool:
	return level_of(tech_id) > 0


func fork_of(tech_id: String) -> String:
	return forks.get(tech_id, "")


func has_fusion(fusion_id: String) -> bool:
	return fusions.has(fusion_id)


func field_count(upgrade_id: String) -> int:
	return int(field.get(upgrade_id, 0))


func online_tech() -> Array:
	var result := []
	for tech_id in loadout:
		if tech_id != "" and is_online(tech_id):
			result.append(tech_id)
	return result


## Damage multiplier for a tech: its R&D Mk bonus plus anything mission-wide.
func damage_multiplier(tech_id: String, armor_fraction: float) -> float:
	var mult := 1.0 + TechData.MK_DAMAGE_BONUS * (int(tech_mk.get(tech_id, 1)) - 1)
	if field_count("last_stand") > 0 and armor_fraction < 0.34:
		mult *= 1.6
	if field_count("glass_reactor") > 0:
		mult *= 1.5
	return mult


## Resonance points for an element: levels of its online tech, plus 2 per field upgrade of it.
func resonance_points(element: String) -> int:
	var points := 0
	for tech_id in loadout:
		if tech_id != "" and TechData.TECH[tech_id]["element"] == element:
			points += level_of(tech_id)
	for upgrade_id in field:
		if UpgradeData.field_upgrade(upgrade_id).get("element", "") == element:
			points += UpgradeData.FIELD_RESONANCE_POINTS * int(field[upgrade_id])
	return points


func resonance_tier(element: String) -> int:
	var points := resonance_points(element)
	var tier := 0
	for threshold in UpgradeData.RESONANCE_THRESHOLDS:
		if points >= threshold:
			tier += 1
	return tier


func resonance_tiers() -> Dictionary:
	var tiers := {}
	for element in UpgradeData.ELEMENTS:
		tiers[element] = resonance_tier(element)
	return tiers


## Adds XP and returns how many levels were gained.
func add_xp(amount: float) -> int:
	xp += amount
	var gained := 0
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		gained += 1
		# Fewer, bigger level-ups: each one should be a decision, not a reflex.
		xp_to_next = 8.0 + level * 6.0 + pow(level, 1.8)
	return gained
