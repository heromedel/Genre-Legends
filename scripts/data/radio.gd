class_name Radio
## The operations officer on the radio (GDD 9E): short lines only. At most one line at a mission's start,
## and only when there's something worth knowing; lessons and new arrivals are announced back at the
## command center. Never a character who can die and lose you the mission.

const OFFICER := "Lt. Arden, Operations"


## The one line (or none) shown as a mission starts.
static func mission_start_line(node: Dictionary, missions_flown: int) -> String:
	match node.get("lesson", ""):
		"needles":
			return "Needle swarms out there. Our shields can't stop them, so keep moving."
		"mirror":
			return "That hull is mirrored. Shoot it head-on and it shoots you back."
	if node.get("hazard", false):
		return "Hazard route. Bring your best build, Commander."
	if node.get("is_gate", false):
		return "Break the gate and the next region opens up."
	if missions_flown == 0:
		return "Frame's warm, Commander. Weapons fire on their own. Just fly."
	return ""


## What the officer says after a lesson planet hands over its tech (win or lose).
static func lesson_line(tech_id: String, won: bool) -> String:
	match tech_id:
		"mirror_aegis":
			if won:
				return "You beat the swarm the hard way. Engineering salvaged a Mirror Aegis from the debris. It's waiting in the Hangar."
			return "Commander, we can't deal with those needles unless your frame has proper shields. We salvaged a Mirror Aegis. Equip it in the Hangar."
		"swarm_pods":
			if won:
				return "Gate's down. We pulled Swarm Pods from the wreck: homing missiles that curve around anything. They're in the Hangar."
			return "We can't punch through those mirrors head-on. Engineering pulled Swarm Pods from the wreck: homing missiles that curve around the plates. Equip them in the Hangar."
	return "New tech recovered: %s. It's in the Hangar." % TechData.TECH[tech_id]["name"]
