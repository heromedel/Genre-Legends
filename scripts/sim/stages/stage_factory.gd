class_name StageFactory
## Turns a mission type into its opening stage.


static func make(mission_type: String, mission: Mission) -> Stage:
	match mission_type:
		"star_cluster":
			return StarClusterStage.new(mission)
		"corridor":
			return CorridorStage.new(mission)
		"planet":
			return PlanetStage.new(mission)
		"dungeon":
			return DungeonStage.new(mission)
	return StarClusterStage.new(mission)
