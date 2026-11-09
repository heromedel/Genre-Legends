class_name ArtGallery
extends Control
## Debug page for art tests: draws one piece of the game's art alone, centred, on a plain background,
## at a chosen zoom, so old and new art can be compared at the same size (main.gd: gallery=<subject>&zoom=N).
## Subjects: ship, mech, dart, any boss id (hive_carrier, warden, ...), or an SVG drawn through VectorArt
## (gallery=docs/art_test/ship.svg; add rim=1 for the rim light).

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
	var rim := false

	func _process(delta: float) -> void:
		time += delta
		queue_redraw()

	func _draw() -> void:
		match subject:
			"ship", "mech":
				FrameArt.draw_frame(self, "vanguard", subject, Vector2.ZERO, -PI * 0.5, time, {})
			"dart":
				EnemyArt.draw(self, enemy, time)
			_ when subject.ends_with(".svg"):
				VectorArt.draw(self, "res://" + subject, Transform2D.IDENTITY, {"rim": Color(0.5, 0.9, 1.0) if rim else Color(0, 0, 0, 0)})
			_:
				BossArt.draw(self, boss, time)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var node := {"id": "gallery", "name": "Gallery", "region": 0, "column": 1, "row": 0.0, "type": "star_cluster", "need": "",
		"difficulty": 1.0, "danger": 1, "modifier": "", "reward_tech": "", "prize": "", "prize_text": ""}
	var mission := Mission.new(node, 1, "vanguard", ["pulse_driver"], func(_t): return 1)
	_stage = Stand.new()
	_stage.subject = subject
	_stage.rim = rim
	if subject == "dart":
		_stage.enemy = mission.world.spawn_enemy("dart", Vector2.ZERO)
		_stage.enemy.facing = PI * 0.5
	elif subject not in ["ship", "mech"] and not subject.ends_with(".svg"):
		_stage.boss = BossRoster.make(subject, mission.world)
		_stage.boss.spawn()
		_stage.boss.entering = false
		_stage.boss.origin = Vector2.ZERO
		_stage.boss.place_parts()
	_stage.scale = Vector2(zoom, zoom)
	add_child(_stage)


func _process(_delta: float) -> void:
	_stage.position = size * 0.5


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), GROUND if subject == "mech" else SPACE)
