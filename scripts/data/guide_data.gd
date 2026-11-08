class_name GuideData
## The Guide to Guardians: what the Command Center's guide page says. Lore and how-it-works entries are
## always there; enemies, bosses, tech and fusions are filled in as you meet, beat or unlock them.
## Pure data; the Hub decides what's discovered from the save.

const LORE := [
	["Mawjig", "Materials Worth of Jigawatts. A measurement of matter and energy used in advanced or physics bending technology. Mawjig tech hexes, bends and calls things down from nowhere."],
	["Frames", "Your frame is one machine with many forms. It flies as a ship through star clusters and corridors and walks as a mech on planets and in dungeons, shifting as each mission starts."],
	["Realms", "Star systems sit in star clusters, in regions of the galaxy. A realm is something else: another dimension, a plane, a pocket of space folded shut. A Jig Drive can't reach one. Some say a temporal variant could, and old rumors speak of a relic called the Orb of Chulak."],
]

const HOW_IT_WORKS := [
	["Level-ups", "Data Shards fill your level bar. Each level-up offers cards: bring tech online, level it, or take a field upgrade. Two rerolls per mission."],
	["Forks", "At level 3 every tech forks into one of two paths that change how it behaves. You choose; crates never choose for you."],
	["Resonance", "Levels of online tech of one element add up (field upgrades count 2). At 5, 10 and 15 points that element unlocks its next tier."],
	["Fusions", "Two specific pieces of tech, both at level 5, fuse into something new. Both keep working."],
	["Salvage Crates", "Three reels add up to how many upgrades you get, from 1 to 6. Most crates give 1 to 3; a 6 is a true jackpot. Lucky Salvage improves the odds."],
	["Blueprints and Mk", "Missions pay blueprints, even when you lose. About 3 unlock a tech; more raise its Mk, which lets it level higher in missions and hit harder."],
	["Risky cards", "Big power with a real cost, like losing your shield. Taking one is a bet on how you play."],
	["Elites", "Some enemies arrive as elites with a twist. Shielded ones have a barrier to break first; splitting ones break in two; mirrored ones throw straight shots back, so hit them with homing shots, blades, blasts or meteors. Elites are worth more and sometimes carry blueprints."],
	["Route events", "Things happen on the way to a planet: derelicts, distress calls, traders, ambushes, Mawjig beacons. Each is a choice, and some choices change the mission you're flying into."],
]

## One line per enemy, shown once you've destroyed one. Kinds without a line here never get an entry.
const ENEMIES := {
	"dart": "Formation fighter. Flies into its slot, sways with the swarm, then peels off and dives at you.",
	"wasp": "Weaves down the screen in a wide snake, firing short spreads.",
	"splitter": "Slow and tough. Throws rings of bullets and breaks into Darts when destroyed.",
	"bulwark_wing": "Its front plating blocks your shots. Hit it from the side, or with anything that curves.",
	"minelayer": "Crosses the screen dropping mines that drift down and burst into rings.",
	"ace": "An elite pilot that loops across the top of the field. Leaves after a while if you can't catch it.",
	"supply_barge": "A fat freighter crossing the screen. Destroy it before it escapes and it drops a Salvage Crate.",
	"wall_turret": "Bolted into the corridor walls, firing short aimed bursts.",
	"drill": "A kamikaze that lines you up and rams.",
	"crawler": "Fast, weak and many. Runs straight at you.",
	"spitter": "Lobs acid where you're about to be. The green circle is your warning.",
	"sentry": "A stationary gun that turns to track you.",
	"brute": "Lines up, telegraphs, and charges. Bursts a ring of bullets where it stops.",
	"burrower": "Travels underground and erupts under your feet. Watch for the rumble.",
	"hive_nest": "The heart of an infestation. Hurting it makes the brood pour out.",
	"warlord": "An elite that leads crawlers into battle and fires heavy spreads.",
	"skullbot": "Bounces around the room like a screensaver and fires every time it hits a wall.",
	"wisp": "A Mawjig ghost that drifts through walls.",
	"pillar_turret": "A spinning eye that sprays bullets in turning lines.",
	"mimic": "A treasure chest. Until it isn't. Beat it for a Salvage Crate.",
	"gloop": "A slime that splits into Glooplings when it dies.",
	"knight": "Shield up front. It lunges, slashes, then stands exposed for a moment: punish it, or flank it.",
	"cluster_drone": "Splits into four homing shards when destroyed. Arrived with the Wasp Swatter milestone.",
	"centi_mech": "A head and a chain of segments. Kill the head and the next segment takes over.",
}

## Bosses and mini-bosses by their look id, shown once beaten.
const BOSSES := {
	"twin_aces": ["Twin Aces", "Two aces flying mirror-image loops with crossfire through the middle. Down one and the other gets furious."],
	"hive_carrier": ["Hive Carrier", "Launches fighters from four hangar bays. Break enough bays and the core opens; near the end it sweeps the field with lasers. Each sweep is shown in advance and always leaves a lane."],
	"turret_fortress": ["Bulkhead Fortress", "A bulkhead across the trench. Knock out its turrets to expose the gate's core; the corridor waits until it falls."],
	"wyrm_engine": ["Wyrm Engine", "A mechanical serpent. Shoot away half its segments and the head starts charging along telegraphed lines."],
	"brood_queen": ["Brood Queen", "Two egg sacs birth crawlers and shield her head. Burst the sacs, then dodge her acid."],
	"siege_crawler": ["Siege Crawler", "Every leg is a gun. Shoot out the legs and it crashes down, exposing its core."],
	"mimic_king": ["Mimic King", "A crowned treasure chest that hops at you and lands in rings of teeth, spilling gold when hurt."],
	"hollow_king": ["The Hollow King", "Blinks between pillars, snuffs out the lights, and finally makes the walls fire curtains with one gap."],
	"clone_projector": ["Clone Projector", "Scans you and fields a hologram that fires your own bolts back. Kill the clone, or break the projector's shell and grab the device to make the clone fight for you."],
	"bounty_ace": ["Bounty Hunter Ace", "A rival hunter with two shield drones. Strafes the field with mines, snipes along shown lines, then calls in other hunters and throws a closing net with one gap."],
	"crusher_gate": ["Crusher Gate", "Pistons slam across the trench at your height, leaving one gap. Break a piston to silence its side and open the core."],
	"leviathan": ["Leviathan", "A dreadnought longer than the screen glides overhead. Its batteries pass one by one; its engine core fights at the end."],
	"dune_maw": ["Dune Maw", "A sand worm that tunnels toward you and erupts where the ground rumbles. Hit it while it's up."],
	"storm_colossus": ["Storm Colossus", "Arms spray wheeling streams and lightning falls on you. Break the arms and it kneels, turning four storm beams a quarter turn."],
	"gazer": ["Gazer", "Two eyes take turns opening. Shut, they can't be hurt; open, they lock a beam onto you."],
	"warden": ["The Warden", "The jailer, chained by two shackles, swinging a flail that blocks shots. Break the shackles and it breaks free."],
	"mirror_dreadnought": ["Mirror Dreadnought", "Its mirrored underside throws straight shots back. Reach the vents on its back with homing shots, meteors, blasts or nerve."],
}
