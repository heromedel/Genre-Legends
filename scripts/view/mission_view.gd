class_name MissionView
extends Node2D
## Plays a Mission on screen: steps the simulation on a fixed 60 Hz tick, records input for the play log,
## turns simulation events into effects, sound, screen shake and banners, and draws the world in layers:
## background, ground effects, bodies, additive glow and effects, darkness, then the HUD on top.

signal finished(result: Dictionary)
signal abandoned()

var mission: Mission
var first_clear := false
var background: BackgroundArt
var fx := Fx.new()
var input: PlayerInput
var hud: Hud
var special_button: Overlays.TouchButton
var pause_button: Overlays.TouchButton
var overlay: Control = null
var overlay_kind := ""
var paused := false
var done := false

var world_root: Node2D
var layers := {}
var camera_center := Vector2.ZERO
var camera_scale := 1.0
var shake := 0.0
var time := 0.0
var transform_time := 0.0
var hit_flash := 0.0
var _accumulator := 0.0


class DrawLayer:
	extends Node2D
	var paint: Callable
	func _draw() -> void:
		paint.call(self)


func setup(new_mission: Mission, is_first_clear: bool) -> void:
	mission = new_mission
	first_clear = is_first_clear


func _ready() -> void:
	var node := mission.node
	var region: int = node.get("region", 0)
	var palette: Dictionary = MissionData.REGION_PALETTES[region % MissionData.REGION_PALETTES.size()]
	background = BackgroundArt.new(palette, int(node.get("planet_look", 0)) & 0xffff)
	_prepare_background()
	world_root = Node2D.new()
	add_child(world_root)
	for layer_name in ["background", "ground_fx", "bodies", "glow", "effects", "dark"]:
		var layer := DrawLayer.new()
		layer.paint = Callable(self, "_paint_" + layer_name)
		if layer_name in ["ground_fx", "glow", "effects"]:
			var material := CanvasItemMaterial.new()
			material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			layer.material = material
		if layer_name == "background":
			layer.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		world_root.add_child(layer)
		layers[layer_name] = layer
	var hud_layer := CanvasLayer.new()
	add_child(hud_layer)
	input = PlayerInput.new()
	hud_layer.add_child(input)
	hud = Hud.new()
	hud.mission = mission
	hud_layer.add_child(hud)
	special_button = Overlays.TouchButton.new()
	special_button.icon = mission.run.special_tech()
	special_button.color = Color(1, 0.8, 0.4)
	special_button.on_press = func(): input.queue_special()
	special_button.size = Vector2(96, 96)
	hud_layer.add_child(special_button)
	pause_button = Overlays.TouchButton.new()
	pause_button.icon = "pause"
	pause_button.size = Vector2(56, 56)
	pause_button.on_press = func(): set_paused(true)
	hud_layer.add_child(pause_button)
	_layout_buttons()
	get_viewport().size_changed.connect(_layout_buttons)
	camera_center = mission.player.pos
	PlayLog.set_screen("mission:%s" % node["type"])
	PlayLog.begin_mission(mission, mission.run.loadout, mission.run.tech_mk)
	Sound.play_music(node["type"])
	_handle_events(mission.drain_events())


func _prepare_background() -> void:
	match mission.node["type"]:
		"planet":
			background.prepare_planet(PlanetStage.WORLD_SIZE)
		"dungeon":
			background.prepare_dungeon()


func _layout_buttons() -> void:
	var screen := get_viewport_rect().size
	special_button.position = Vector2(screen.x - 130, screen.y - 140)
	pause_button.position = Vector2(screen.x - 76, 14)
	input.blocked_rects = [Rect2(special_button.position, special_button.size).grow(14), Rect2(pause_button.position, pause_button.size).grow(14)]


func set_paused(value: bool) -> void:
	if done:
		return
	paused = value
	input.clear()
	if paused:
		PlayLog.note("input", "paused")
		_show_overlay("pause", Overlays.build_pause(func(): set_paused(false), _abandon))
	else:
		PlayLog.note("input", "resumed")
		_close_overlay()


func _abandon() -> void:
	PlayLog.abandon_mission(mission)
	done = true
	abandoned.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		set_paused(not paused)


func _notification(what: int) -> void:
	# Going to the background (home button, app switch) pauses the mission.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if not paused and not done and mission != null and mission.state in ["play", "intro"]:
			set_paused(true)


# ---------------------------------------------------------------- stepping

func _physics_process(_delta: float) -> void:
	if paused or done or mission == null:
		return
	if mission.state == "offer" and overlay_kind != "offer":
		_open_offer()
	elif mission.state == "crate" and overlay_kind != "crate":
		_open_crate()
	var frame := input.poll()
	var choice_made := frame.choice >= 0
	if mission.state in ["offer", "crate"] and not choice_made:
		return
	if choice_made and mission.state == "offer":
		PlayLog.record_choice(mission.offer_cards[frame.choice], mission.offer_cards)
	PlayLog.record_input(frame)
	mission.step(frame)
	if AdminConsole.god_mode:
		mission.player.armor = mission.player.max_armor
		mission.player.alive = true
	var events := mission.drain_events()
	PlayLog.observe(mission, frame, events)
	_handle_events(events)
	if overlay_kind in ["offer", "crate"] and mission.state not in ["offer", "crate"]:
		_close_overlay()
	if mission.is_finished():
		done = true
		var result := mission.results(first_clear)
		PlayLog.end_mission(mission, result)
		finished.emit(result)


func _handle_events(events: Array) -> void:
	for event in events:
		fx.handle(event, mission.world)
		match event["type"]:
			"sound":
				Sound.play(event["name"])
			"shake":
				if Save.setting("screen_shake"):
					shake = minf(shake + event["amount"], 22.0)
			"banner":
				hud.show_banner(event["text"], event["style"])
			"boss_warning":
				hud.show_warning(event["name"], event["title"])
				Sound.play_music("boss")
			"flash":
				hud.flash(event["color"], event["amount"])
			"player_hit":
				hud.hurt()
				hit_flash = 0.15
			"stage_start":
				transform_time = 0.8
				input.form = event["form"]
				input.clear()
			"escaped":
				hud.show_banner("%s ESCAPED" % event["name"].to_upper(), "red")
			"boss_defeated":
				Sound.play_music(mission.node["type"])
			"wave":
				if event["index"] > 1:
					hud.show_banner("WAVE %d" % event["index"], "cyan")


func _open_offer() -> void:
	var cards := mission.offer_cards
	_show_overlay("offer", Overlays.build_offer(cards, mission.offer_source, func(index: int):
		input.queue_choice(index)
		Sound.play("pick")))
	Sound.play("level_up")


func _open_crate() -> void:
	var reel := Overlays.CrateReel.new()
	reel.cards = mission.crate_cards
	reel.on_done = func(): input.queue_choice(0)
	_show_overlay("crate", reel)
	Sound.play("reel")


func _show_overlay(kind: String, control: Control) -> void:
	_close_overlay()
	overlay = control
	overlay_kind = kind
	hud.get_parent().add_child(control)
	input.clear()


func _close_overlay() -> void:
	if overlay != null:
		overlay.queue_free()
	overlay = null
	overlay_kind = ""


# ---------------------------------------------------------------- camera and drawing

func _process(delta: float) -> void:
	if mission == null:
		return
	time += delta
	transform_time = maxf(transform_time - delta, 0.0)
	hit_flash = maxf(hit_flash - delta, 0.0)
	fx.update(delta if not paused else 0.0)
	_update_camera(delta)
	for layer in layers.values():
		layer.queue_redraw()
	hud.view_rect_world = _view_rect()
	hud.world_to_screen = world_root.transform
	hud.tick(delta)
	var weapons := mission.weapons
	special_button.visible = mission.run.special_tech() != ""
	if special_button.visible:
		var total := weapons.special_cooldown_total()
		special_button.enabled = mission.run.is_online(mission.run.special_tech())
		special_button.charges = mission.player.special_charges
		special_button.cooldown = 0.0 if mission.player.special_charges > 0 else clampf(mission.player.special_cooldown / total, 0.0, 1.0)
		special_button.label = "" if special_button.enabled else "OFFLINE"
		special_button.queue_redraw()
	input.set_player_screen_position(world_root.transform * mission.player.pos)


func _update_camera(delta: float) -> void:
	var screen := get_viewport_rect().size
	var stage := mission.stage
	var target := mission.player.pos
	match stage.camera_mode:
		"fixed":
			var field := mission.world.bounds
			camera_scale = minf(screen.x / field.size.x, screen.y / field.size.y)
			target = field.get_center()
			camera_center = target
		"room":
			var dungeon := stage as DungeonStage
			var room := dungeon.room_rect(dungeon.current)
			camera_scale = minf(screen.x / room.size.x, screen.y / room.size.y)
			camera_center = camera_center.lerp(room.get_center(), clampf(delta * 9.0, 0.0, 1.0))
		_:
			camera_scale = clampf(minf(screen.x, screen.y) / 660.0, 0.8, 1.4)
			camera_center = camera_center.lerp(target, clampf(delta * 8.0, 0.0, 1.0))
	shake = maxf(shake - delta * 30.0, 0.0)
	var shake_offset := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake
	input.world_scale = camera_scale
	world_root.scale = Vector2(camera_scale, camera_scale)
	world_root.position = screen * 0.5 - camera_center * camera_scale + shake_offset


func _view_rect() -> Rect2:
	var screen := get_viewport_rect().size
	var size := screen / camera_scale
	return Rect2(camera_center - size * 0.5, size)


func _paint_background(ci: CanvasItem) -> void:
	var view := _view_rect().grow(40)
	var stage := mission.stage
	match mission.node["type"]:
		"star_cluster":
			background.draw_space(ci, view, (stage as StarClusterStage).scroll * 4.0, time)
		"corridor":
			var corridor := stage as CorridorStage
			background.draw_space(ci, view, corridor.distance, time, false)
			background.draw_corridor_walls(ci, corridor, time)
		"planet":
			background.draw_planet(ci, view, mission.world, time)
		"dungeon":
			background.draw_dungeon(ci, view, stage as DungeonStage, time)


func _paint_ground_fx(ci: CanvasItem) -> void:
	for zone: Zone in mission.world.zones:
		ShotArt.draw_zone(ci, zone, time)
	if mission.stage is DungeonStage:
		background.draw_dungeon_light(ci, _view_rect(), mission.stage, time)


func _paint_bodies(ci: CanvasItem) -> void:
	var world := mission.world
	var view := _view_rect().grow(80)
	for pickup: Pickup in world.pickups:
		if view.has_point(pickup.pos):
			ShotArt.draw_pickup(ci, pickup, time)
	for enemy: Enemy in world.enemies:
		if enemy.brain != "boss_part" and view.has_point(enemy.pos):
			EnemyArt.draw(ci, enemy, time)
	if mission.stage.boss != null and not mission.stage.boss.finished:
		BossArt.draw(ci, mission.stage.boss, time)
	_draw_halo_saws(ci)
	var player := mission.player
	if player.alive and mission.state != "lost":
		var speed := clampf(player.vel.length() / 300.0, 0.0, 1.0)
		var flicker := player.grace > 0.0 and player.grace < 5.0 and int(time * 16.0) % 2 == 0
		FrameArt.draw_frame(ci, mission.run.frame_id, player.form, player.pos, player.facing, time,
			{"speed": speed, "flash": 1.0 if flicker else hit_flash})
	for shot: Shot in world.enemy_shots:
		ShotArt.draw_enemy_shot(ci, shot, time)


func _draw_halo_saws(ci: CanvasItem) -> void:
	if fx.halo.is_empty() or not mission.run.is_online("orbital_halo"):
		return
	for saw: Vector2 in fx.halo["saws"]:
		ci.draw_set_transform(saw, time * 14.0, Vector2.ONE)
		var teeth := PackedVector2Array()
		for i in 12:
			var a := TAU * i / 12.0
			teeth.append(Vector2.from_angle(a) * 11.0)
			teeth.append(Vector2.from_angle(a + 0.18) * 16.0)
			teeth.append(Vector2.from_angle(a + 0.36) * 11.0)
		Art.shape(ci, teeth, Color(0.62, 0.66, 0.72), Color(1, 1, 1), 1.0)
		ci.draw_circle(Vector2.ZERO, 8.0, Color(0.35, 0.38, 0.45))
		ci.draw_arc(Vector2.ZERO, 8.0, 0, TAU, 16, Color(1, 0.85, 0.5), 1.5, true)
		ci.draw_circle(Vector2.ZERO, 2.5, Color(0.1, 0.1, 0.12))
		ci.draw_set_transform(saw, 0.0, Vector2.ONE)
		ci.draw_arc(Vector2.ZERO, 19.0, time * 14.0, time * 14.0 + 1.6, 10, Color(1, 1, 1, 0.35), 2.0, true)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _paint_glow(ci: CanvasItem) -> void:
	var world := mission.world
	var view := _view_rect().grow(80)
	for enemy: Enemy in world.enemies:
		if enemy.brain != "boss_part" and view.has_point(enemy.pos):
			EnemyArt.draw_glow(ci, enemy)
	if mission.stage.boss != null and not mission.stage.boss.finished:
		BossArt.draw_glow(ci, mission.stage.boss, time)
	for pickup: Pickup in world.pickups:
		if view.has_point(pickup.pos):
			ShotArt.draw_pickup_glow(ci, pickup)
	for shot: Shot in world.enemy_shots:
		ShotArt.draw_enemy_shot_glow(ci, shot)
	var player := mission.player
	if player.alive:
		FrameArt.draw_glow(ci, mission.run.frame_id, player.form, player.pos, player.facing,
			{"overdrive": player.overdrive > 0.0, "last_stand": mission.run.field_count("last_stand") > 0 and player.armor_fraction() < 0.34})
		if player.mirror_time > 0.0:
			ci.draw_arc(player.pos, World.MIRROR_RADIUS, 0, TAU, 40, Color(0.6, 1, 1, 0.8), 4.0, true)
			Art.draw_glow(ci, player.pos, World.MIRROR_RADIUS * 1.4, Color(0.4, 0.9, 1.0, 0.25))
		if mission.run.fork_of("mirror_aegis") == "b" and mission.run.is_online("mirror_aegis"):
			ci.draw_arc(player.pos, 58.0, player.facing - 1.08, player.facing + 1.08, 16, Color(0.6, 1, 1, 0.6), 3.0, true)
	if transform_time > 0.0:
		FrameArt.draw_transform(ci, player.pos, 1.0 - transform_time / 0.8, FrameData.get_frame(mission.run.frame_id)["hull"])


func _paint_effects(ci: CanvasItem) -> void:
	var world := mission.world
	for shot: Shot in world.player_shots:
		ShotArt.draw_player_shot(ci, shot, time)
	for blade in world.blades:
		_draw_blade(ci, blade)
	fx.draw(ci, UiKit.font("bold"))


## The Arc Blade: a bright sword edge sweeping round the frame with a fading afterimage trail.
func _draw_blade(ci: CanvasItem, blade: Dictionary) -> void:
	if blade["time"] < 0.0:
		return
	var center := mission.player.pos
	var radius: float = blade["radius"]
	var angle: float = blade["angle"]
	var start: float = blade["start"]
	var trail_from := maxf(start, angle - 1.4)
	for i in 6:
		var t := float(i) / 6.0
		var a := lerpf(trail_from, angle, t)
		ci.draw_arc(center, radius * (0.55 + 0.45 * t), a, angle, 10, Color(0.5, 0.95, 1.0, 0.12 + t * 0.2), radius * 0.18, true)
	var tip := center + Vector2.from_angle(angle) * radius
	var hilt := center + Vector2.from_angle(angle) * radius * 0.25
	ci.draw_line(hilt, tip, Color(0.5, 0.95, 1.0, 0.7), 16.0, true)
	ci.draw_line(hilt, tip, Color(1, 1, 1, 1.0), 5.0, true)
	Art.draw_glow(ci, tip, 30.0, Color(0.6, 1.0, 1.0, 0.8))


func _paint_dark(ci: CanvasItem) -> void:
	if not mission.world.dark:
		return
	var view := _view_rect().grow(200)
	var lamp := 300.0
	var at := mission.player.pos
	var hole := Rect2(at - Vector2(lamp, lamp), Vector2(lamp, lamp) * 2.0)
	ci.draw_texture_rect(Art.dark_hole(), hole, false, Color(1, 1, 1, 0.93))
	var shade := Color(0, 0, 0, 0.93)
	ci.draw_rect(Rect2(view.position, Vector2(view.size.x, hole.position.y - view.position.y)), shade)
	ci.draw_rect(Rect2(Vector2(view.position.x, hole.end.y), Vector2(view.size.x, view.end.y - hole.end.y)), shade)
	ci.draw_rect(Rect2(Vector2(view.position.x, hole.position.y), Vector2(hole.position.x - view.position.x, hole.size.y)), shade)
	ci.draw_rect(Rect2(Vector2(hole.end.x, hole.position.y), Vector2(view.end.x - hole.end.x, hole.size.y)), shade)
