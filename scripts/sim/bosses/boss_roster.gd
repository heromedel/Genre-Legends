class_name BossRoster
## Which bosses and mini-bosses each mission type can field, which one a planet gets, and how to build
## one from its id. A planet's pick comes from its id and the map's seed, so it never shifts the map's
## own random sequence and is the same every time the map is rebuilt.

const POOLS := {
	"star_cluster": {"boss": ["hive_carrier", "bounty_ace"], "miniboss": ["twin_aces", "clone_projector"]},
	"corridor": {"boss": ["wyrm_engine", "leviathan"], "miniboss": ["turret_fortress", "crusher_gate"]},
	"planet": {"boss": ["siege_crawler", "storm_colossus"], "miniboss": ["brood_queen", "dune_maw"]},
	"dungeon": {"boss": ["hollow_king", "warden"], "miniboss": ["mimic_king", "gazer"]},
}


## The boss (kind "boss") or mini-boss (kind "miniboss") a planet fields.
static func pick(mission_type: String, kind: String, node_id: String, map_seed: int) -> String:
	var pool: Array = POOLS[mission_type][kind]
	# The very first planet eases you in with the classic pair.
	if node_id == "r0c0n0":
		return pool[0]
	return pool[absi(hash("%s|%s|%d" % [node_id, kind, map_seed])) % pool.size()]


## The planet's boss or mini-boss, falling back to the type's first one (old saves, debug planets).
static func for_node(node: Dictionary, kind: String) -> String:
	var chosen: String = node.get(kind, "")
	return chosen if chosen != "" else POOLS[node["type"]][kind][0]


static func make(boss_id: String, world: World) -> BossBase:
	match boss_id:
		"hive_carrier": return HiveCarrier.new(world)
		"bounty_ace": return BountyAce.new(world)
		"mirror_dreadnought": return MirrorDreadnought.new(world)
		"twin_aces": return TwinAces.new(world)
		"clone_projector": return CloneProjector.new(world)
		"wyrm_engine": return WyrmEngine.new(world)
		"leviathan": return Leviathan.new(world)
		"turret_fortress": return TurretFortress.new(world)
		"crusher_gate": return CrusherGate.new(world)
		"siege_crawler": return SiegeCrawler.new(world)
		"storm_colossus": return StormColossus.new(world)
		"brood_queen": return BroodQueen.new(world)
		"dune_maw": return DuneMaw.new(world)
		"hollow_king": return HollowKing.new(world)
		"warden": return Warden.new(world)
		"mimic_king": return MimicKing.new(world)
		"gazer": return Gazer.new(world)
	push_error("Unknown boss id: " + boss_id)
	return HiveCarrier.new(world)
