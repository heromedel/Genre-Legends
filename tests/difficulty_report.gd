extends SceneTree
## Difficulty report (GDD 9A): the average-player bot plays each of the first region's six steps in every
## mission type, with the starting kit, and reports hits taken, armor left and win rate against the targets.
## Run:  godot --headless -s tests/difficulty_report.gd -- [runs per cell]

const TARGETS := [
	"2-5 hits, 75-90% armor", "6-10 hits, 50-70% armor", "6-10 hits, 50-70% armor (needles: worse without shields)",
	"10-15 hits, 35-55% armor", "10-15 hits, 35-55% armor", "about 1 in 4 lost (gate)",
]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var runs := int(args[0]) if args.size() > 0 else 3
	var lessons := {2: "needles", 5: "mirror"}
	for column in 6:
		print("Planet %d   target: %s" % [column + 1, TARGETS[column]])
		var types: Array = ["star_cluster"] if column == 0 or column == 5 else MissionData.PLAYABLE_TYPES
		for mission_type in types:
			# From planet 4 on, a real player has the Mirror Aegis the needle planet handed over.
			var variants := [[TechData.STARTING_LOADOUT if column < 3 else ["pulse_driver", "arc_blade", "", "mirror_aegis", "nova_bomb"], "starter kit" if column < 3 else "+ Mirror Aegis"]]
			if column == 2:
				variants = [[TechData.STARTING_LOADOUT, "no shields"], [["pulse_driver", "arc_blade", "", "mirror_aegis", "nova_bomb"], "with Mirror Aegis"]]
			if column == 5:
				variants = [[["pulse_driver", "arc_blade", "", "mirror_aegis", "nova_bomb"], "no Swarm Pods"], [["pulse_driver", "arc_blade", "swarm_pods", "mirror_aegis", "nova_bomb"], "with Swarm Pods"]]
			for variant in variants:
				var hits := 0.0
				var armor := 0.0
				var wins := 0
				var seconds := 0.0
				for run in runs:
					var node := {"id": "r0c%dn0" % column if column > 0 else "r0c0n0", "name": "D", "region": 0, "column": column, "row": 0.0,
						"type": mission_type, "need": MissionData.NEEDS[mission_type][0], "difficulty": 1.0, "danger": 1,
						"modifier": "", "reward_tech": "arc_blade", "prize": "", "prize_text": "", "baseline": column,
						"lesson": lessons.get(column, ""), "boss": "mirror_dreadnought" if column == 5 else "", "is_gate": column == 5}
					var mission := Mission.new(node, 500 + run * 31, "vanguard", variant[0], func(t): return 1)
					var bot := BotPilot.new(mission, run)
					bot.average = true
					while not mission.is_finished() and mission.tick < 60 * 60 * 9:
						mission.step(bot.next_input())
						mission.drain_events()
					hits += mission.run.hits_taken
					armor += mission.player.armor_fraction()
					seconds += mission.world.time
					if mission.state == "won":
						wins += 1
				print("   %-12s %-18s hits %5.1f  armor left %3d%%  won %d/%d  %3.0fs" % [mission_type, variant[1], hits / runs, int(armor / runs * 100), wins, runs, seconds / runs])
	quit()
