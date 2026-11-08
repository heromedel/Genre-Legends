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
var miniboss: BossBase = null       # a mid-stage fight (GDD 9B)
var debug_boss_phase := 0           # debug launches: the boss starts its fight in this phase


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


## How far through the stage the player got, 0..1, for partial rewards on a loss (GDD 9D).
## Reaching the boss counts for most of it.
func progress_fraction() -> float:
	if boss != null:
		return 0.8 + 0.2 * (1.0 - boss.hp_fraction())
	return clampf(stage_progress(), 0.0, 1.0) * 0.75


## Each stage's own measure of progress before its boss, 0..1.
func stage_progress() -> float:
	return 0.0


## Debug: jump to just before the mini-boss.
func debug_skip_to_miniboss() -> void:
	pass


## Short text for the HUD: what to do right now.
func objective_text() -> String:
	return ""


## Spawns the stage's boss with its warning intro.
func start_boss(new_boss: BossBase) -> void:
	boss = new_boss
	boss_started = true
	boss.spawn()
	boss.memory["debug_phase"] = debug_boss_phase
	world.emit("boss_warning", {"name": boss.boss_name, "title": boss.title})
	world.emit("sound", {"name": "warning"})
	mission.note("Boss appeared: %s" % boss.boss_name)


## Spawns a mid-stage mini-boss with a smaller warning.
func start_miniboss(new_boss: BossBase) -> void:
	miniboss = new_boss
	miniboss.spawn()
	world.emit("banner", {"text": "MINI-BOSS INCOMING", "style": "red"})
	world.emit("sound", {"name": "warning"})
	mission.note("Mini-boss appeared: %s" % miniboss.boss_name)


## True while a mini-boss is on the field.
func miniboss_active() -> bool:
	return miniboss != null and not miniboss.finished


func update_miniboss(dt: float) -> void:
	if miniboss != null and not miniboss.finished:
		miniboss.update(dt)


## The boss the HUD's health bar should show right now.
func active_boss() -> BossBase:
	if boss != null and not boss.finished:
		return boss
	if miniboss_active():
		return miniboss
	return null


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
