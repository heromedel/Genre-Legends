class_name ArtGallery
extends Control
## Debug page for art tests: draws one piece of the game's art alone, centred, on a plain background,
## at a chosen zoom, so old and new art can be compared at the same size (main.gd: gallery=<subject>&zoom=N).
## Subjects: ship, mech, dart, "enemies" (every regular enemy in a grid, named), any boss id (hive_carrier, warden, ...), or an SVG drawn through VectorArt
## (gallery=art/test/ship.svg; add rim=1 for the rim light), or "morph": the transformation looping,
## without the spin on the left and with it on the right, or "cutscene:<kind>": one of the Dropship
## transitions on a loop (cutscene:return_win, cutscene:launch_planet, ...). Frames: add frame=tempest (or bulwark).

const SPACE := Color(0.04, 0.05, 0.12)
const GROUND := Color(0.42, 0.39, 0.29)

var subject := "ship"
var zoom := 3.0
var rim := false
var _stage: Stand


## The zoomed canvas the art is drawn on: centred, scaled, in game units. The art's own transforms
## (EnemyArt and BossArt set theirs) stack on top of this node's.
class Stand:
	extends Node2D
	var subject := "ship"
	var time := 0.0
	var boss: BossBase
	var enemy: Enemy
	var lineup: Array = []      # "enemies": every regular enemy, laid out in a grid
	var rim := false

	func _process(delta: float) -> void:
		time += delta
		queue_redraw()

	func _draw() -> void:
		match subject:
			"ship", "mech":
				FrameArt.draw_frame(self, Save.data["frame"], subject, Vector2.ZERO, -PI * 0.5, time, {})
			"dart":
				EnemyArt.draw(self, enemy, time)
			"enemies":
				for shown: Enemy in lineup:
					EnemyArt.draw(self, shown, time)
					draw_string(UiKit.font("bold"), shown.pos + Vector2(-32, 34), shown.look, HORIZONTAL_ALIGNMENT_CENTER, 64, 7, Color(0.8, 0.9, 1.0))
			"morph":
				# Mech, fold into the ship, hold, fold back: 0.8 s each way with a pause between.
				var cycle := fmod(time, 3.2)
				var progress := clampf(cycle / 0.8, 0.0, 1.0) if cycle < 1.6 else 1.0 - clampf((cycle - 1.6) / 0.8, 0.0, 1.0)
				for side in [-1.0, 1.0]:
					FrameArt.draw_morph(self, Save.data["frame"], Vector2(side * 70.0, 0.0), -PI * 0.5, progress, time, {"spin": side > 0.0})
					draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
					draw_string(UiKit.font("bold"), Vector2(side * 70.0 - 40.0, 62.0), "spin" if side > 0.0 else "no spin", HORIZONTAL_ALIGNMENT_CENTER, 80, 9, Color(0.8, 0.9, 1.0))
			_ when subject.ends_with(".svg"):
				VectorArt.draw(self, "res://" + subject, Transform2D.IDENTITY, {"rim": Color(0.5, 0.9, 1.0) if rim else Color(0, 0, 0, 0)})
			_:
				BossArt.draw(self, boss, time)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if subject.begins_with("cutscene:"):
		_loop_cutscene()
		return
	var node := {"id": "gallery", "name": "Gallery", "region": 0, "column": 1, "row": 0.0, "type": "star_cluster", "need": "",
		"difficulty": 1.0, "danger": 1, "modifier": "", "reward_tech": "", "prize": "", "prize_text": ""}
	var mission := Mission.new(node, 1, "vanguard", ["pulse_driver"], func(_t): return 1)
	_stage = Stand.new()
	_stage.subject = subject
	_stage.rim = rim
	if subject == "dart":
		_stage.enemy = mission.world.spawn_enemy("dart", Vector2.ZERO)
		_stage.enemy.facing = PI * 0.5
	elif subject == "enemies":
		var kinds := EnemyData.ENEMIES.keys().filter(func(k): return k not in ["boss_part", "cracked_wall", "gloopling"])
		kinds.append("mimic")     # a second Mimic, awake, beside the sleeping one
		for i in kinds.size():
			var shown := mission.world.spawn_enemy(kinds[i], Vector2((i % 7 - 3) * 74.0, (i / 7 - 1.5) * 78.0))
			shown.facing = PI * 0.5
			shown.state = 1 if i == kinds.size() - 1 else 0
			shown.hidden = false
			_stage.lineup.append(shown)
	elif subject not in ["ship", "mech", "morph"] and not subject.ends_with(".svg"):
		_stage.boss = BossRoster.make(subject, mission.world)
		_stage.boss.spawn()
		_stage.boss.entering = false
		_stage.boss.origin = Vector2.ZERO
		_stage.boss.place_parts()
	_stage.scale = Vector2(zoom, zoom)
	add_child(_stage)


func _process(_delta: float) -> void:
	if _stage:
		_stage.position = size * 0.5


## Plays the transition, then plays it again (a tap skips to the next loop, as in a mission).
func _loop_cutscene() -> void:
	var scene := Cutscene.new()
	scene.kind = subject.trim_prefix("cutscene:")
	scene.frame_id = Save.data["frame"]
	scene.on_done = func(): _loop_cutscene.call_deferred()
	add_child(scene)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), GROUND if subject == "mech" else SPACE)
