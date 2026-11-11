class_name RouteEvents
## Things that happen on the way to a planet (GDD 12D): derelicts, distress calls, traders, ambushes, storms.
## Each is a real choice. Most options cost something (Armor at the start, crystals, blueprints, a harder mission)
## and pay something different, so there's rarely a free best answer. Some options only appear when your
## loadout has the right tech ("needs_tech"): the build you fly matters on the way there too.
## Outcomes either pay out at once (blueprints, crystals, Frame Blueprints, a free dive) or change the mission,
## carried in the planet's "event" entry for Mission to apply and announce as the mission starts.
## Rolls come from the map seed, the planet and how many missions you've flown, so they're repeatable, and the
## event you met last time is skipped so the same one never comes twice in a row.

## How often a launch meets an event, once you've flown a couple of missions.
const CHANCE := 0.4
const FIRST_AFTER_MISSIONS := 2

## Outcome effects.
##   Paid at once: blueprints_random, blueprints_planet, spend_blueprints, crystals (+/-), frame_blueprints, free_dive.
##   Carried into the mission: start_armor (fraction), start_crates, rerolls, start_field ("random"), start_risky
##   ("random"), start_heat (0-100), elites, bullet_speed, enemy_hp, boss_health (multipliers), and
##   wager_blueprints / wager_crystals (paid with the results, only for a win).
## Choice gates: needs_tech (any of these equipped shows the option), needs_crystals, needs_blueprints.
const EVENTS := {
	"derelict": {"title": "Derelict Freighter", "text": "A gutted freighter drifts across your route. Its hold might still be sealed, or rigged.",
		"choices": [
			{"label": "Board it", "outcomes": [
				[0.65, "The hold was full. +4 blueprints.", {"blueprints_random": 4}],
				[0.35, "It was rigged. You tear free with nothing, and you'll start at 70% Armor.", {"start_armor": 0.7}]]},
			{"label": "Shield up and board it", "needs_tech": ["shield_generator", "mirror_aegis"], "outcomes": [
				[1.0, "The charge goes off against your shield. The hold is yours: +4 blueprints.", {"blueprints_random": 4}]]},
			{"label": "Scan it from a distance", "outcomes": [
				[1.0, "Your scanners pull one schematic from its memory. +1 blueprint.", {"blueprints_random": 1}]]}]},
	"distress": {"title": "Distress Call", "text": "A survey drone is pinned down by raiders on the planet below. It's carrying salvage.",
		"choices": [
			{"label": "Answer it", "outcomes": [
				[1.0, "You'll land among the raiders, with twice the elites. The drone drops you a Salvage Crate as you arrive.", {"elites": 2.0, "start_crates": 1}]]},
			{"label": "Send decoys (3 crystals)", "needs_crystals": 3, "outcomes": [
				[1.0, "The decoys draw the raiders off. The drone gets clear and drops you a Salvage Crate.", {"crystals": -3, "start_crates": 1}]]},
			{"label": "Ignore it", "outcomes": [[1.0, "The signal fades behind you.", {}]]}]},
	"trader": {"title": "Wandering Trader", "text": "A Mawjig trader hails you: salvage for salvage, no questions asked.",
		"choices": [
			{"label": "Trade 2 blueprints", "needs_blueprints": 2, "outcomes": [
				[1.0, "Two blueprints from your biggest pile buy a Salvage Crate and a spare reroll.", {"spend_blueprints": 2, "start_crates": 1, "rerolls": 1}]]},
			{"label": "Pay the trader (4 crystals)", "needs_crystals": 4, "outcomes": [
				[1.0, "He fits something to your frame before you can ask what. You'll start with a field upgrade.", {"crystals": -4, "start_field": "random"}]]},
			{"label": "Let him charge his cells from your reactor", "needs_tech": ["aux_generator", "overheat_core", "coolant_loop"], "outcomes": [
				[1.0, "He pays in spare parts, but charging his cells runs your reactor hard and cooks the plating around it: +2 rerolls, and you'll start at 60% heat and 90% Armor.", {"rerolls": 2, "start_heat": 60.0, "start_armor": 0.9}]]},
			{"label": "Decline", "outcomes": [[1.0, "The trader shrugs and drifts off.", {}]]}]},
	"ambush": {"title": "Ambush", "text": "Hunters lie in wait in the debris field ahead. There's no clean way past.",
		"choices": [
			{"label": "Punch through", "outcomes": [
				[1.0, "You blast through and loot the wrecks: +2 of this planet's blueprints, but you'll start at 80% Armor.", {"blueprints_planet": 2, "start_armor": 0.8}]]},
			{"label": "Blast a path", "needs_tech": ["nova_bomb", "thruster_explosion", "ion_cannon"], "outcomes": [
				[1.0, "Your special clears the debris in one shot. +2 of this planet's blueprints, and you're barely scratched (90% Armor).", {"blueprints_planet": 2, "start_armor": 0.9}]]},
			{"label": "Take the long way", "outcomes": [
				[1.0, "You slip past, but the planet knows you're coming: enemy bullets fly faster.", {"bullet_speed": 1.1}]]}]},
	"loose_core": {"title": "Loose Mawjig Core", "text": "A reactor core has spilled from a wreck and tumbles across your route, still crackling with raw Mawjig.",
		"choices": [
			{"label": "Tap its charge", "outcomes": [
				[0.5, "The charge settles into your systems and tunes them. You'll start with a field upgrade.", {"start_field": "random"}],
				[0.3, "The charge tunes your systems, but dumps its heat into your reactor. You'll start with a field upgrade, at 80% heat.", {"start_field": "random", "start_heat": 80.0}],
				[0.2, "It arcs through your frame and burns out. You'll start at 75% Armor, with nothing to show for it.", {"start_armor": 0.75}]]},
			{"label": "Draw it through your Mawjig tech", "needs_tech": ["flux_repeater", "starfall", "soul_lantern", "time_brake"], "outcomes": [
				[1.0, "Your Mawjig tech takes the charge cleanly. You'll start with a field upgrade, with no backlash.", {"start_field": "random"}]]},
			{"label": "Siphon it through the Coolant Loop", "needs_tech": ["coolant_loop"], "outcomes": [
				[1.0, "The loop bleeds off the heat and keeps the charge. You'll start with a field upgrade.", {"start_field": "random"}]]},
			{"label": "Let it tumble past", "outcomes": [[1.0, "You give it a wide berth and let it crackle away into the dark.", {}]]}]},
	"jump_beacon": {"title": "Damaged Jump Beacon", "text": "The jump beacon that guides Jig Drives into this cluster is flickering. Someone has been at it.",
		"choices": [
			{"label": "Repair it for the network", "outcomes": [
				[1.0, "It takes a while, but the beacon holds steady again. Operations pays for the repair: +4 crystals. Word of your work reaches the planet first: enemies are a little tougher.", {"crystals": 4, "enemy_hp": 1.1}]]},
			{"label": "Strip it for parts", "outcomes": [
				[1.0, "Its guidance core is worth a lot to R&D: +3 blueprints. Traffic control flags your frame, and more elites come looking.", {"blueprints_random": 3, "elites": 1.5}]]},
			{"label": "Report it and fly on", "outcomes": [[1.0, "You log the fault for the network and fly on.", {}]]}]},
	"bounty": {"title": "Rival Hunter", "text": "A bounty hunter blocks your path and offers a wager: whoever clears the planet first takes the purse.",
		"choices": [
			{"label": "Take the wager", "outcomes": [
				[1.0, "The hunter stirs up the planet: twice the elites, and every boss here, mini-bosses too, a fifth tougher. Win the mission and the purse is yours: +4 of this planet's blueprints and 5 crystals. Lose, and you get nothing extra.", {"elites": 2.0, "boss_health": 1.2, "wager_blueprints": 4, "wager_crystals": 5}]]},
			{"label": "Turn it down", "outcomes": [
				[1.0, "The hunter laughs and spreads the word. A few more elites come looking for you.", {"elites": 1.4}]]}]},
	"sabotage": {"title": "Inside Job", "text": "Operations has a contact near the planet's boss. A little help would go a long way.",
		"choices": [
			{"label": "Fund the sabotage (6 crystals)", "needs_crystals": 6, "outcomes": [
				[1.0, "The charges are set. Every boss here, mini-bosses too, will have a quarter less health.", {"crystals": -6, "boss_health": 0.75}]]},
			{"label": "Plant the charges yourself", "outcomes": [
				[0.7, "In and out. Every boss here, mini-bosses too, will have a fifth less health, but the guards winged you: 80% Armor.", {"boss_health": 0.8, "start_armor": 0.8}],
				[0.3, "The guards were waiting. You get out at 70% Armor, charges unplanted.", {"start_armor": 0.7}]]},
			{"label": "Leave it to the contact", "outcomes": [[1.0, "Operations sighs. You'll do it the hard way.", {}]]}]},
	"ion_squall": {"title": "Ion Squall", "text": "A storm of charged dust sweeps across the route. It'll cook anything that runs hot.",
		"choices": [
			{"label": "Ride it out", "outcomes": [
				[1.0, "The squall bakes your reactor and scorches your plating: you'll start at 70% heat and 90% Armor, but the static charge gives you a spare reroll.", {"start_heat": 70.0, "start_armor": 0.9, "rerolls": 1}]]},
			{"label": "Vent through it", "needs_tech": ["coolant_loop"], "outcomes": [
				[1.0, "Your Coolant Loop drinks the storm. +2 rerolls and you arrive cool.", {"rerolls": 2}]]},
			{"label": "Go around", "outcomes": [
				[1.0, "You arrive late, and the planet's defenders have dug in: enemies are a little tougher.", {"enemy_hp": 1.12}]]}]},
	"convoy": {"title": "Refugee Convoy", "text": "A convoy of battered transports limps past. Their engineers wave you down.",
		"choices": [
			{"label": "Give them plating for their hulls", "outcomes": [
				[1.0, "They patch their hulls with plating off your own frame and hand you a set of frame plans in thanks. +1 Frame Blueprint, and you'll start at 85% Armor.", {"frame_blueprints": 1, "start_armor": 0.85}]]},
			{"label": "Escort them to the jump point", "outcomes": [
				[1.0, "A quiet escort. They pay in crystals: +4, but the escort costs you time and the defenders dig in: enemies are a little tougher.", {"crystals": 4, "enemy_hp": 1.1}]]},
			{"label": "Wave them on", "outcomes": [[1.0, "They limp on toward the jump point.", {}]]}]},
	"prototype": {"title": "Prototype Testers", "text": "An R&D lab ship wants a field test of something unstable. They'll pay in research.",
		"choices": [
			{"label": "Fit the prototype", "outcomes": [
				[1.0, "It's live. You'll start with a field upgrade and a risky card, and the lab sends +3 blueprints now.", {"start_field": "random", "start_risky": "random", "blueprints_random": 3}]]},
			{"label": "Test it on the range only", "outcomes": [
				[1.0, "Safe data, small pay. +1 blueprint.", {"blueprints_random": 1}]]}]},
	"wreck_field": {"title": "Wreck Field", "text": "The route cuts through a graveyard of old warships. Some still have power.",
		"choices": [
			{"label": "Send the drone in", "outcomes": [
				[1.0, "The drone marks a wreck worth diving. A free Derelict Dive waits at the Depot, but a turret wakes up as you leave: 85% Armor.", {"free_dive": 1, "start_armor": 0.85}]]},
			{"label": "Strip a hull yourself", "outcomes": [
				[0.6, "Its systems are still warm. +3 of this planet's blueprints.", {"blueprints_planet": 3}],
				[0.4, "The hull shifts and pins you for a moment. +1 of this planet's blueprints, and you'll start at 75% Armor.", {"blueprints_planet": 1, "start_armor": 0.75}]]},
			{"label": "Skirt the field", "outcomes": [[1.0, "You give the dead a wide berth.", {}]]}]},
}


## Debug launches can force the next launch's event (main.gd: event=<id>).
static var forced := ""


## The event met on the way to this planet, or "" for a quiet trip. last_event is skipped, so the same event
## never comes twice in a row.
static func roll(node: Dictionary, missions_flown: int, map_seed: int, last_event: String = "") -> String:
	if forced != "":
		var id := forced
		forced = ""
		return id
	if missions_flown < FIRST_AFTER_MISSIONS or node.get("lesson", "") != "" or node.get("is_gate", false):
		return ""
	var rng := _rng(node["id"], missions_flown, map_seed, 0)
	if rng.randf() >= CHANCE:
		return ""
	var ids: Array = EVENTS.keys().filter(func(id): return id != last_event)
	return ids[rng.randi() % ids.size()]


## Whether a choice is offered with this loadout (needs_tech hides it unless one of the listed tech is equipped).
static func offered(choice: Dictionary, loadout: Array) -> bool:
	var needs: Array = choice.get("needs_tech", [])
	return needs.is_empty() or needs.any(func(t): return loadout.has(t))


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


## A short line for each way the event changes the mission, for the banner as it starts.
static func mission_summary(effects: Dictionary) -> Array:
	var lines := []
	if effects.has("start_crates"):
		lines.append("Salvage Crate waiting" if int(effects["start_crates"]) == 1 else "%d Salvage Crates waiting" % int(effects["start_crates"]))
	if effects.has("rerolls"):
		lines.append("+%d reroll%s" % [int(effects["rerolls"]), "" if int(effects["rerolls"]) == 1 else "s"])
	if float(effects.get("boss_health", 1.0)) < 1.0:
		lines.append("bosses weakened")
	if float(effects.get("boss_health", 1.0)) > 1.0:
		lines.append("bosses tougher")
	if float(effects.get("elites", 1.0)) > 1.0:
		lines.append("more elites")
	if effects.has("start_armor"):
		lines.append("Armor at %d%%" % roundi(float(effects["start_armor"]) * 100.0))
	if effects.has("wager_blueprints"):
		lines.append("win to claim the purse")
	if effects.has("start_heat"):
		lines.append("starting hot")
	if effects.has("bullet_speed"):
		lines.append("faster enemy bullets")
	if effects.has("enemy_hp"):
		lines.append("tougher enemies")
	return lines


static func _rng(node_id: String, missions_flown: int, map_seed: int, stream: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s|%d|%d|%d" % [node_id, missions_flown, map_seed, stream])
	return rng
