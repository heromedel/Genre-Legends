class_name RouteEvents
## Things that happen on the way to a planet: derelicts, distress calls, traders, ambushes and beacons.
## Each one is a choice with a risk. Some outcomes pay out at once (blueprints); others change the
## mission you're launching into, carried in the planet's "event" entry for Mission to apply.
## Rolls come from the map seed, the planet and how many missions you've flown, so they're repeatable.

## How often a launch meets an event, once you've flown a couple of missions.
const CHANCE := 0.35
const FIRST_AFTER_MISSIONS := 2

## Outcome effects: blueprints_random / blueprints_planet / spend_blueprints (paid at once), and
## start_armor, start_crates, rerolls, start_field, elites, bullet_speed (applied to the mission).
const EVENTS := {
	"derelict": {"title": "Derelict Freighter", "text": "A gutted freighter drifts across your route. Its hold might still be sealed.",
		"choices": [
			{"label": "Board it", "hint": "Salvage, or a trap.", "outcomes": [
				[0.65, "The hold was full. +3 blueprints.", {"blueprints_random": 3}],
				[0.35, "It was rigged. You tear free with your armor scored: you'll start at 70%.", {"start_armor": 0.7}]]},
			{"label": "Scan it from a distance", "hint": "Safe, and a little something.", "outcomes": [
				[1.0, "Your scanners pull a schematic from its memory. +1 blueprint.", {"blueprints_random": 1}]]},
			{"label": "Fly on", "hint": "", "outcomes": [[1.0, "You leave it to drift.", {}]]}]},
	"distress": {"title": "Distress Call", "text": "A survey drone is pinned down by raiders on the planet below.",
		"choices": [
			{"label": "Answer it", "hint": "More elites down there, and the drone's salvage.", "outcomes": [
				[1.0, "You'll land among the raiders. The drone drops you a Salvage Crate as you arrive.", {"elites": 2.0, "start_crates": 1}]]},
			{"label": "Ignore it", "hint": "", "outcomes": [[1.0, "The signal fades behind you.", {}]]}]},
	"trader": {"title": "Wandering Trader", "text": "A Mawjig trader hails you: blueprints for salvage, no questions asked.",
		"choices": [
			{"label": "Trade 2 blueprints", "hint": "From your biggest pile, for a crate and a reroll.", "needs_blueprints": 2, "outcomes": [
				[1.0, "Done. You'll start with a Salvage Crate and a spare reroll.", {"spend_blueprints": 2, "start_crates": 1, "rerolls": 1}]]},
			{"label": "Decline", "hint": "", "outcomes": [[1.0, "The trader shrugs and drifts off.", {}]]}]},
	"ambush": {"title": "Ambush", "text": "Hunters lie in wait in the debris ahead.",
		"choices": [
			{"label": "Punch through", "hint": "Their salvage is yours, but they shoot first.", "outcomes": [
				[1.0, "You blast through. +2 of this planet's blueprints, and you'll start at 80% armor.", {"blueprints_planet": 2, "start_armor": 0.8}]]},
			{"label": "Take the long way", "hint": "No fight, but they'll be ready.", "outcomes": [
				[1.0, "You slip past, but the planet knows you're coming: enemy bullets fly faster.", {"bullet_speed": 1.1}]]}]},
	"beacon": {"title": "Mawjig Beacon", "text": "A beacon hums with Mawjig. Touching it could do anything.",
		"choices": [
			{"label": "Touch it", "hint": "Power, maybe with a price.", "outcomes": [
				[0.7, "It sings to your frame. You'll start with a field upgrade.", {"start_field": "random"}],
				[0.3, "It screams. You'll start with a field upgrade, but enemy bullets fly faster.", {"start_field": "random", "bullet_speed": 1.12}]]},
			{"label": "Leave it", "hint": "", "outcomes": [[1.0, "Some things are better left humming.", {}]]}]},
}


## Debug launches can force the next launch's event (main.gd: event=<id>).
static var forced := ""


## The event met on the way to this planet, or "" for a quiet trip.
static func roll(node: Dictionary, missions_flown: int, map_seed: int) -> String:
	if forced != "":
		var id := forced
		forced = ""
		return id
	if missions_flown < FIRST_AFTER_MISSIONS or node.get("lesson", "") != "" or node.get("is_gate", false):
		return ""
	var rng := _rng(node["id"], missions_flown, map_seed, 0)
	if rng.randf() >= CHANCE:
		return ""
	var ids := EVENTS.keys()
	return ids[rng.randi() % ids.size()]


## Picks the outcome of a choice: [text, effects].
static func resolve(event_id: String, choice_index: int, node_id: String, missions_flown: int, map_seed: int) -> Array:
	var outcomes: Array = EVENTS[event_id]["choices"][choice_index]["outcomes"]
	var roll := _rng(node_id, missions_flown, map_seed, 1 + choice_index).randf()
	for outcome: Array in outcomes:
		roll -= float(outcome[0])
		if roll < 0.0:
			return [outcome[1], outcome[2]]
	var last: Array = outcomes[outcomes.size() - 1]
	return [last[1], last[2]]


static func _rng(node_id: String, missions_flown: int, map_seed: int, stream: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s|%d|%d|%d" % [node_id, missions_flown, map_seed, stream])
	return rng
