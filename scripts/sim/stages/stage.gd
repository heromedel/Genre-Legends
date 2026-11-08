class_name Stage
extends RefCounted
## The base for every mission type's stage: what the arena looks like, what spawns when, and when it's won.
## A Mission runs one stage at a time and can hand off to another mid-mission (GDD 6G proposal).

var mission: Mission
var world: World
var form := "ship"              # the frame's form for this stage (GDD 5E)
var camera_mode := "fixed"      # fixed: the whole field is on screen; follow: camera tracks the frame
var boss: BossBase = null
var boss_started := false


func _init(owner: Mission) -> void:
	mission = owner
	world = owner.world


func stage_name() -> String:
	return "Stage"


func setup() -> void:
	pass


func step(_dt: float) -> void:
	pass


func is_cleared() -> bool:
	return false


func has_next_stage() -> bool:
	return false


func next_stage() -> Stage:
	return null


## Called after the frame moves, so stages can react (dungeon doors, corridor scrolling).
func after_player_moved() -> void:
	pass


func on_key_collected() -> void:
	pass


## Debug: jump to the boss fight. Each stage clears whatever stands between the frame and its boss.
func debug_skip_to_boss() -> void:
	pass


## Short text for the HUD: what to do right now.
func objective_text() -> String:
	return ""


## Spawns the stage's boss with its warning intro.
func start_boss(new_boss: BossBase) -> void:
	boss = new_boss
	boss_started = true
	boss.spawn()
	world.emit("boss_warning", {"name": boss.boss_name, "title": boss.title})
	world.emit("sound", {"name": "warning"})
	mission.note("Boss appeared: %s" % boss.boss_name)


## Picks an enemy kind from a weighted roster with the mission's rng.
func pick_from_roster(roster: Dictionary) -> String:
	var total := 0
	for kind in roster:
		total += roster[kind]
	var roll := world.rng.randi() % total
	for kind in roster:
		roll -= roster[kind]
		if roll < 0:
			return kind
	return roster.keys()[0]
