class_name Radio
## The operations officer on the radio (GDD 9E): short lines only. At most one line at a mission's start,
## and only when there's something worth knowing; lessons and new arrivals are announced back at the
## command center. Never a character who can die and lose you the mission.

const OFFICER := "Lt. Arden, Operations"


## The one line (or none) shown as a mission starts.
static func mission_start_line(node: Dictionary, missions_flown: int) -> String:
	match node.get("lesson", ""):
		"needles":
			return "Needle swarms out there. A plain shield won't stop them, so keep moving."
		"mirror":
			return "That hull is mirrored. Shoot it head-on and it shoots you back."
	if node.get("hazard", false):
		return "Hazard route, Commander. Everything down there hits harder."
	match node.get("chain", ""):
		"corridor":
			return "Scans show tunnels under that hive. When the ground opens, dive in."
		"planet":
			return "That dungeon has a shaft to the surface. Find the key and break out."
	if node.get("is_gate", false):
		return "Break the gate and the next region opens up."
	if missions_flown == 0:
		return _first_line(node)
	# A special condition is worth a heads-up; a plain planet gets silence.
	return CONDITION_LINES.get(node.get("modifier", ""), "")


## The very first mission's line: what the controls do, in the frame's form and with your auto-fire setting.
static func _first_line(node: Dictionary) -> String:
	var mech: bool = node.get("type", "") in ["planet", "dungeon"]
	if node.get("autofire", true):
		return "Frame's warm, Commander. Weapons fire on their own. %s" % ("Just move." if mech else "Just fly.")
	return "Frame's warm, Commander. %s" % ("Hold the aim stick and your guns answer." if mech else "Steer and your guns answer.")


const CONDITION_LINES := {
	"ion_storm": "Ion storm overhead. Their shots will come in fast, but the shards are rich.",
	"swarm_season": "Swarm season. Twice the bodies, half the armor. Keep your guns busy.",
	"derelict_field": "Derelict field. Plenty of salvage, and whatever's out there is armored up.",
	"bounty_hunters": "Bounty hunters on your trail. Bring one down and its blueprints are yours.",
	"blackout": "We've lost the lights down there. Trust your lamp, Commander.",
}


## What the officer says when you reach a lesson planet already owning its tech.
static func came_prepared_line(tech_id: String) -> String:
	return "You came prepared, Commander. We pulled extra %s blueprints from the wreck; they're in R&D." % TechData.TECH[tech_id]["name"]


## What the officer says after a lesson planet hands over its tech (win or lose).
static func lesson_line(tech_id: String, won: bool) -> String:
	match tech_id:
		"shield_generator":
			if won:
				return "You beat the swarm the hard way. We salvaged a Shield Generator from the debris; it's in the Hangar."
			return "Those needles needed a shield. We salvaged a Shield Generator from the debris; it's in the Hangar."
		"swarm_pods":
			if won:
				return "Gate's down. We pulled homing Swarm Pods from the wreck; they're in the Hangar."
			return "Mirrors won't break head-on. We pulled homing Swarm Pods from the wreck; they're in the Hangar."
	return "New tech recovered: %s. It's in the Hangar." % TechData.TECH[tech_id]["name"]
