class_name RunState
extends RefCounted
## Everything about the player's power inside one mission: which tech is online and at what level,
## forks and fusions chosen, field upgrades, XP, and the tally shown on the results screen.
## It survives a hand-off from one stage to another inside the same mission (GDD 6G proposal).

var frame_id := "vanguard"
var frame_tiers: Array = []     # the frame's tier picks, kept so a replay can rebuild it
var frame_stats := {}           # FrameData.stats(): armor, speed, load, output, heat_rate with its tier picks
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
var banked_levels := 0           # levels and crates after the last boss fell, paid as blueprints
var bosses_defeated: Array = []  # boss look ids, for the Guide to Guardians
var boss_hits := 0              # hits taken while a boss is on the field
var min_armor_fraction := 1.0
var max_resonance := 0
var hits_taken := 0


func setup(frame: String, equipped: Array, mk_lookup: Callable, tier_picks: Array = []) -> void:
	frame_id = frame
	frame_tiers = tier_picks.duplicate()
	frame_stats = FrameData.stats(frame, tier_picks)
	loadout = equipped.duplicate()
	for slot_index in loadout.size():
		var tech_id: String = loadout[slot_index]
		if tech_id == "":
			continue
		var mk: int = maxi(1, mk_lookup.call(tech_id))
		tech_mk[tech_id] = mk
		tech_cap[tech_id] = TechData.MK_LEVEL_CAP[mk]
		# GDD 7D: only the main weapon starts online, and the parts that are the frame itself: the plating is worn,
		# and the power parts run it (GDD 21A).
		tech_level[tech_id] = 1 if slot_index == 0 or TechData.TECH[tech_id].get("starts_online", false) else 0
		tech_timer[tech_id] = 0.0


func main_weapon() -> String:
	return loadout[0]


func special_tech() -> String:
	return loadout[4] if loadout.size() > 4 else ""


func plating() -> String:
	return loadout[6] if loadout.size() > 6 else ""


## The Armor the plating adds right now: its base, plus what its levels add (GDD 13L, 21H). The DSP-1's fork
## level counts as one of its +10s.
func plate_armor() -> float:
	var plate := TechData.get_tech(plating())
	if plate.is_empty():
		return 0.0
	return float(plate.get("plate_armor", 0.0)) + float(plate.get("armor_per_level", 0.0)) * maxi(level_of(plating()) - 1, 0)


## How much faster (or slower) the plating makes the frame: +0.1 is 10% faster.
func plate_speed() -> float:
	var plate := TechData.get_tech(plating())
	return float(plate.get("plate_speed", 0.0)) + float(plate.get("speed_per_level", 0.0)) * maxi(level_of(plating()) - 1, 0)


## Is this plate worn, and at what level (0 if it isn't).
func plate_level(plate_id: String) -> int:
	return level_of(plate_id) if plating() == plate_id else 0


# ---------------------------------------------------------------- Load, Output and heat (GDD 21A–21D)

## Mawjig Output right now: the frame's, plus the Auxiliary Generator's, which grows as it levels.
func mawjig_output() -> int:
	var output: int = frame_stats.get("output", 9)
	output += [0, 3, 4, 4, 5, 6][level_of("aux_generator")]
	return output


## What the online parts draw. Offline parts draw nothing, so a mission starts cool and heat only begins as an
## overclocked build comes online.
func online_draw() -> int:
	var total := 0
	for tech_id in online_tech():
		total += TechData.draw_of(tech_id)
	return total


## Pips of draw past Output, less what the Coolant Loop takes off (it can't cool below zero).
func overclock_pips() -> float:
	var over := float(online_draw() - mawjig_output())
	if over <= 0.0:
		return over
	return maxf(over - coolant_pips(), 0.0)


func coolant_pips() -> float:
	match level_of("coolant_loop"):
		0: return 0.0
		1, 2, 3: return 1.0
		4: return 1.5
		_: return 2.0


func level_of(tech_id: String) -> int:
	return int(tech_level.get(tech_id, 0))


func is_online(tech_id: String) -> bool:
	return level_of(tech_id) > 0


func fork_of(tech_id: String) -> String:
	return forks.get(tech_id, "")


func has_fusion(fusion_id: String) -> bool:
	return fusions.has(fusion_id)


## True if this mission can still reach the fusion: both tech equipped, and both able to reach level 5
## with their R&D Mk. Fusions that can't happen aren't mentioned in the mission (heromedel).
func can_fuse(fusion_id: String) -> bool:
	if has_fusion(fusion_id):
		return false
	for tech_id in UpgradeData.FUSIONS[fusion_id]["needs"]:
		if not loadout.has(tech_id) or int(tech_cap.get(tech_id, 3)) < TechData.MAX_LEVEL:
			return false
	return true


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
	# Surge Cell: Output you aren't using feeds the guns.
	if fork_of("aux_generator") == "a":
		mult *= 1.0 + 0.03 * maxi(mawjig_output() - online_draw(), 0)
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
