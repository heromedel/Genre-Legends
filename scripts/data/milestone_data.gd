class_name MilestoneData
## Milestones (GDD 9D): achievements that pay out, so every run moves you forward, won or lost.
## Common ones come naturally; hard ones are rare feats in the spirit of The Binding of Isaac.
## Some bring new enemies into the galaxy. Hidden ones show as "???" until earned.
## "counter" milestones count across missions (Save.data.counters); the rest are checked per mission.
## Rewards: "blueprints:<tech>:<n>", "random_blueprints:<n>", "tech:<tech>", "enemy:<enemy kind>".

const MILESTONES := [
	{"id": "first_sortie", "name": "First Sortie", "text": "Win a mission.", "reward": "random_blueprints:3"},
	{"id": "lost_and_found", "name": "Lost and Found", "text": "Lose 3 missions. It happens to everyone.", "counter": "losses", "goal": 3, "reward": "random_blueprints:4"},
	{"id": "fork_in_the_road", "name": "Fork in the Road", "text": "Choose 5 forks.", "counter": "forks", "goal": 5, "reward": "random_blueprints:4"},
	{"id": "crate_digger", "name": "Crate Digger", "text": "Open 12 Salvage Crates.", "counter": "crates", "goal": 12, "reward": "random_blueprints:5"},
	{"id": "resonant", "name": "Resonant", "text": "Reach Resonance tier II in any element.", "reward": "random_blueprints:4"},
	{"id": "fused", "name": "Fused", "text": "Create a fusion.", "reward": "random_blueprints:6"},
	{"id": "gatebreaker", "name": "Gatebreaker", "text": "Break a region gate.", "reward": "random_blueprints:6"},
	{"id": "wasp_swatter", "name": "Wasp Swatter", "text": "Destroy 80 Wasps.", "counter": "kill_wasp", "goal": 80, "reward": "enemy:cluster_drone"},
	{"id": "hive_breaker", "name": "Hive Breaker", "text": "Destroy 12 Hive Nests.", "counter": "kill_hive_nest", "goal": 12, "reward": "enemy:centi_mech"},
	{"id": "mimic_hunter", "name": "Mimic Hunter", "text": "Defeat 6 Mimics.", "counter": "kill_mimic", "goal": 6, "reward": "tech:hex_repeater"},
	{"id": "comeback", "name": "Comeback", "text": "Win a mission with less than 15% armor left.", "reward": "blueprints:graze_engine:4"},
	# Hard, rare feats.
	{"id": "untouchable", "name": "Untouchable", "text": "Defeat a boss without being hit during the fight.", "hidden": true, "reward": "tech:thunder_lance"},
	{"id": "purist", "name": "Purist", "text": "Win a mission with nothing but your main weapon online.", "hidden": true, "reward": "tech:orbital_halo"},
	{"id": "glass_cannon", "name": "Glass Cannon", "text": "Win a mission after taking Glass Reactor.", "hidden": true, "reward": "tech:overheat_core"},
	{"id": "resonance_master", "name": "Resonance Master", "text": "Reach Resonance tier III.", "hidden": true, "reward": "tech:time_brake"},
	{"id": "veteran_ace", "name": "Veteran Ace", "text": "Win a mission on Veteran threat without dropping below half armor.", "hidden": true, "reward": "random_blueprints:10"},
	{"id": "explorer", "name": "Explorer", "text": "Find a dungeon's secret room and still win the mission.", "hidden": true, "reward": "tech:starfall"},
]

## What the radio says when a milestone brings a new enemy into the galaxy (GDD 9D).
const ENEMY_ANNOUNCEMENTS := {
	"cluster_drone": "Cluster Drones have been spotted in the galaxy. Destroy one and it bursts into homing shards.",
	"centi_mech": "Centi-Mechs are loose on planets across the galaxy. Kill the head and the next segment takes over.",
}


static func by_id(milestone_id: String) -> Dictionary:
	for milestone in MILESTONES:
		if milestone["id"] == milestone_id:
			return milestone
	return {}
