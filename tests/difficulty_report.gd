extends SceneTree
## Difficulty report (GDD 9A): the average-player bot plays each of the first region's six steps in every
## mission type, with the starting kit, and reports hits taken, armor left, win rate and how long the boss took,
## against the targets (GDD 13I): planet 1 1-3 hits, planets 2-3 3-5, planets 4-5 4-6 with a loss now and then,
## the gate about 1 in 4 lost; a planet 1 boss 30-45 s, a gate boss 60-90 s (13H).
## Run:  godot --headless -s tests/difficulty_report.gd -- [runs per cell]

const TARGETS := [
	"1-3 hits, boss 30-45 s", "3-5 hits", "3-5 hits (needles: worse without a shield)",
	"4-6 hits, a loss now and then", "4-6 hits, a loss now and then", "about 1 in 4 lost (gate), boss 60-90 s",
]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var runs := int(args[0]) if args.size() > 0 else 3
	var lessons := {2: "needles", 5: "mirror"}
	for column in 6:
		print("Planet %d   target: %s" % [column + 1, TARGETS[column]])
		var types: Array = ["star_cluster"] if column == 0 or column == 5 else MissionData.PLAYABLE_TYPES
		for mission_type in types:
			# From planet 4 on, a real player has the Shield Generator the needle planet handed over.
			var shielded := ["pulse_driver", "", "", "", "nova_bomb", "shield_generator", "dsp1_plate"]
			var variants := [[TechData.STARTING_LOADOUT if column < 3 else shielded, "starter kit" if column < 3 else "+ Shield Generator"]]
			if column == 2:
				variants = [[TechData.STARTING_LOADOUT, "no shield"], [shielded, "with Shield Gen"]]
			if column == 5:
				variants = [[shielded, "no Swarm Pods"], [["pulse_driver", "swarm_pods", "", "", "nova_bomb", "shield_generator", "dsp1_plate"], "with Swarm Pods"]]
			for variant in variants:
				var hits := 0.0
				var armor := 0.0
				var wins := 0
				var seconds := 0.0
				var boss_seconds := 0.0
				var bosses := 0
				for run in runs:
					var node := {"id": "r0c%dn0" % column if column > 0 else "r0c0n0", "name": "D", "region": 0, "column": column, "row": 0.0,
						"type": mission_type, "need": MissionData.NEEDS[mission_type][0], "difficulty": 1.0, "danger": 1,
						"modifier": "", "reward_tech": "arc_blade", "prize": "", "prize_text": "", "baseline": column,
						"lesson": lessons.get(column, ""), "boss": "mirror_dreadnought" if column == 5 else "", "is_gate": column == 5}
					var mission := Mission.new(node, 500 + run * 31, "vanguard", variant[0], func(t): return 1)
					var bot := BotPilot.new(mission, run)
					bot.average = true
					var boss_start := -1.0
					while not mission.is_finished() and mission.tick < 60 * 60 * 9:
						mission.step(bot.next_input())
						for event in mission.drain_events():
							if event["type"] == "boss_warning":
								boss_start = mission.world.time
							elif event["type"] == "boss_defeated" and boss_start >= 0.0:
								boss_seconds += mission.world.time - boss_start
								bosses += 1
								boss_start = -1.0
					hits += mission.run.hits_taken
					armor += mission.player.armor_fraction()
					seconds += mission.world.time
					if mission.state == "won":
						wins += 1
				print("   %-12s %-18s hits %5.1f  armor left %3d%%  won %d/%d  %3.0fs  boss fights %3.0fs" % [mission_type, variant[1], hits / runs, int(armor / runs * 100), wins, runs, seconds / runs, boss_seconds / maxi(bosses, 1)])
	quit()
