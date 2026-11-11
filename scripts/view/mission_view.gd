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
var shown_offer_serial := -1
var paused := false
## Resuming after the browser closed: the mission is rebuilt and fast-forwarded through the inputs it had.
var checkpoint_launch: Dictionary = {}   # how main launched it, saved with the inputs so it can be rebuilt
var resume_frames: Array = []            # inputs to fast-forward through before play resumes
var abandon_after_restore := false       # the player chose to abandon it: settle it once it's caught up
var _restored := 0                       # how many of them have run
var _restore_screen: Label
var _inputs := InputRecording.new()      # every input so far, for the checkpoint
var _checkpoint_timer := CHECKPOINT_SECONDS
## How often a mission in progress is saved, so closing the browser mid-mission loses at most this much.
const CHECKPOINT_SECONDS := 5.0
var done := false

var world_root: Node2D
var layers := {}
var camera_center := Vector2.ZERO
var camera_scale := 1.0
var shake := 0.0
var time := 0.0
## How long the frame takes to fold from one form into the other (FrameArt.draw_morph).
const TRANSFORM_SECONDS := 0.8
var transform_time := 0.0
var hit_flash := 0.0
var tech_online_since := {}      # tech id -> view time it came online, for GearArt's unfold
var _accumulator := 0.0
var hitstop := 0.0               # seconds the action freezes on a big moment (view only; no ticks run)
var cutscene: Cutscene = null   # while a transition plays, the mission waits (no ticks run)
var skip_cutscenes := false     # debug test launches skip them unless asked (cutscene=1)
var splash: ResonanceSplash = null   # while a Resonance tier is announced, the mission waits too
var pending_splashes: Array = []     # tiers unlocked behind the cards, shown as soon as the cards close


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
	var line: String = node.get("radio", "")
	if line != "":
		hud.show_radio(line)
	Sound.play_music(node["type"])
	_handle_events(mission.drain_events())
	if not resume_frames.is_empty():
		_begin_restore()
		return
	# The launch from the Dropship and the arrival, by mission type (GDD 5E).
	var arrival: String = {"planet": "launch_planet", "dungeon": "launch_dungeon"}.get(node["type"], "launch_space")
	_play_cutscene(arrival, Callable())


## Plays a transition over everything; the mission waits until it ends or is skipped.
func _play_cutscene(kind: String, then: Callable) -> void:
	if skip_cutscenes:
		if then.is_valid():
			then.call()
		return
	var scene := Cutscene.new()
	scene.kind = kind
	scene.frame_id = mission.run.frame_id
	scene.gear = _gear()
	scene.ground = background.palette.get("ground", Color(0.3, 0.4, 0.3))
	scene.on_done = func():
		cutscene = null
		if then.is_valid():
			then.call()
	cutscene = scene
	hud.get_parent().add_child(scene)
	PlayLog.note("cutscene", kind)


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
		_show_overlay("pause", Overlays.build_pause(func(): set_paused(false), _abandon, mission.run))
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
	# Going to the background (home button, app switch, closing the tab) saves and pauses the mission.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		_write_checkpoint()
		if not paused and not done and mission != null and mission.state in ["play", "intro"]:
			set_paused(true)


# ---------------------------------------------------------------- saving and resuming

## Saves the mission in progress: how it was launched and every input so far.
func _write_checkpoint() -> void:
	if done or checkpoint_launch.is_empty() or _restored < resume_frames.size():
		return
	Save.write_checkpoint({"launch": checkpoint_launch, "inputs": _inputs.encode(), "ticks": _inputs.ticks})


func _begin_restore() -> void:
	_restore_screen = UiKit.label("", 26, Color(0.7, 0.9, 1.0), "title")
	_restore_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_restore_screen.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_restore_screen.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.01, 0.02, 0.05, 0.97)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.add_child(_restore_screen)
	hud.get_parent().add_child(backdrop)


## Runs as many of the saved inputs as fit in a frame, exactly as they first ran, then hands back control,
## paused, so the player can get ready.
func _continue_restore() -> void:
	var started := Time.get_ticks_msec()
	while _restored < resume_frames.size() and Time.get_ticks_msec() - started < RESTORE_MSEC_PER_FRAME:
		var frame: InputFrame = resume_frames[_restored]
		_restored += 1
		PlayLog.record_input(frame)
		_inputs.add(frame)
		mission.step(frame)
		if AdminConsole.god_mode:
			mission.player.armor = mission.player.max_armor
			mission.player.alive = true
		mission.drain_events()
	_restore_screen.text = "Restoring your mission  %d%%" % int(100.0 * _restored / resume_frames.size())
	if _restored >= resume_frames.size():
		_restore_screen.get_parent().queue_free()
		input.form = mission.player.form
		camera_center = mission.player.pos
		PlayLog.note("mission", "Resumed at %s" % _clock_text())
		if abandon_after_restore:
			_abandon()
		else:
			set_paused(true)


## Fast-forwarding takes this much of each frame, so the restore screen stays responsive.
const RESTORE_MSEC_PER_FRAME := 40


func _clock_text() -> String:
	return "%d:%02d" % [int(mission.world.time) / 60, int(mission.world.time) % 60]


# ---------------------------------------------------------------- stepping

func _physics_process(delta: float) -> void:
	if paused or done or mission == null:
		return
	if _restored < resume_frames.size():
		_continue_restore()
		return
	if cutscene != null or splash != null:
		return
	# A Resonance tier unlocked by the card just picked: announce it before anything else opens.
	if not pending_splashes.is_empty():
		_show_resonance_splash(pending_splashes.pop_front())
		return
	# Hit-stop: the world holds still for a heartbeat on big kills. No tick runs, so replays are unaffected.
	if hitstop > 0.0:
		hitstop -= delta
		return
	if mission.state == "offer" and (overlay_kind != "offer" or shown_offer_serial != mission.offer_serial):
		_open_offer()
	elif mission.state == "crate" and overlay_kind != "crate":
		_open_crate()
	var frame := input.poll()
	var choice_made := frame.choice >= 0
	if mission.state in ["offer", "crate"] and not choice_made:
		return
	if choice_made and mission.state == "offer":
		if frame.choice == UpgradeOffers.REROLL_CHOICE:
			PlayLog.note("choice", "rerolled the cards (%d rerolls left before this)" % mission.run.rerolls)
		elif frame.choice < mission.offer_cards.size():
			PlayLog.record_choice(mission.offer_cards[frame.choice], mission.offer_cards)
	PlayLog.record_input(frame)
	_inputs.add(frame)
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
		# Home to the Dropship (or towed aboard after a loss), then the results.
		_play_cutscene("return_win" if result["won"] else "return_loss", func(): finished.emit(result))


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
				transform_time = TRANSFORM_SECONDS
				# A chained mission handing over: down the fissure, or up out of the dungeon.
				if mission.stages_played.size() > 1:
					_play_cutscene("dive" if event["form"] == "ship" else "breakout", Callable())
				input.form = event["form"]
				input.clear()
			"escaped":
				hud.show_banner("%s ESCAPED" % event["name"].to_upper(), "red")
			"boss_defeated":
				Sound.play_music(mission.node["type"])
				_big_moment(event["pos"], Color(1, 0.9, 0.7), 3.0, 0.45)
			"elite_down":
				_big_moment(event["pos"], event["color"], 0.6, 0.06)
			"power_moment":
				_big_moment(mission.player.pos, event["color"], float(event["size"]), 0.12 * float(event["size"]))
			"resonance":
				pending_splashes.append(event)
			"needle_warning":
				# A needle vent in the dungeon wall lights up just before it fires.
				fx.ring(event["pos"], 46.0, LessonHazards.VENT_WARNING_SECONDS, Color(0.85, 1.0, 0.45), 5.0)
				fx.sparks(event["pos"], Color(0.85, 1.0, 0.45), 10, 140.0)
			"wave":
				# Mid-fight, a wave count is just noise over the boss (0.4 cold review).
				if event["index"] > 1 and mission.stage.active_boss() == null:
					hud.show_banner("WAVE %d" % event["index"], "cyan")


func _open_offer() -> void:
	var cards := mission.offer_cards
	var first_showing := overlay_kind != "offer"
	shown_offer_serial = mission.offer_serial
	_show_overlay("offer", Overlays.build_offer(cards, mission.offer_source, func(index: int):
		input.queue_choice(index)
		Sound.play("pick"), mission.run, func(): input.queue_choice(UpgradeOffers.REROLL_CHOICE)))
	if first_showing:
		Sound.play("level_up")


## A Resonance tier unlocked: the cards close, the action holds, and the splash says what the tier does.
func _show_resonance_splash(event: Dictionary) -> void:
	_close_overlay()
	var color: Color = TechData.ELEMENT_COLORS[event["element"]]
	_big_moment(mission.player.pos, color, 1.0, 0.0)
	Sound.play("overdrive")
	splash = ResonanceSplash.new()
	splash.element = event["element"]
	splash.tier = event["tier"]
	splash.on_done = func(): splash = null
	hud.get_parent().add_child(splash)


## A big moment: the action freezes for a heartbeat, the screen flashes, and rings burst out.
func _big_moment(at: Vector2, color: Color, size: float, freeze: float) -> void:
	hitstop = maxf(hitstop, freeze)
	for i in int(2 + size * 2):
		fx.ring(at, 120.0 * size + i * 140.0 * size, 0.5 + i * 0.12, color, 6.0 - i)
	fx.sparks(at, color, int(20 * size), 420.0 * size)
	hud.flash(color, minf(0.25 * size, 0.9))
	if size >= 2.0:
		Sound.play("jackpot")


func _open_crate() -> void:
	var reel := Overlays.CrateReel.new()
	reel.cards = mission.crate_cards
	reel.faces = mission.crate_faces
	reel.reels = mission.offers.crate_reels()
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
	_checkpoint_timer -= delta
	if _checkpoint_timer <= 0.0:
		_checkpoint_timer = CHECKPOINT_SECONDS
		_write_checkpoint()
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
	hud.covered = overlay_kind != "" or cutscene != null or splash != null
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
			background.draw_corridor_floor(ci, view, corridor, time)
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
	if mission.stage.miniboss_active():
		BossArt.draw(ci, mission.stage.miniboss, time)
	_draw_halo_saws(ci)
	_draw_support_companions(ci)
	# The last few enemies in a locked dungeon room pulse red, so you can always find them.
	if mission.stage is DungeonStage:
		var last_ones: Array = (mission.stage as DungeonStage).room_enemies_left()
		if not last_ones.is_empty() and last_ones.size() <= 3:
			for enemy: Enemy in last_ones:
				ci.draw_arc(enemy.pos, enemy.radius + 14.0 + 4.0 * sin(time * 6.0), 0, TAU, 20, Color(1, 0.3, 0.3, 0.75), 3.0, true)
	if mission.stage is PlanetStage and mission.stage.fissure_open:
		BackgroundArt.draw_fissure(ci, mission.stage.fissure_pos, time)
	for ally: Dictionary in world.allies:
		BossArt.draw_hologram(ci, mission.run.frame_id, ally["pos"], mission.player.facing, time, false, mission.run.loadout)
	var player := mission.player
	if player.alive and mission.state != "lost":
		var speed := clampf(player.vel.length() / 300.0, 0.0, 1.0)
		var flicker := player.grace > 0.0 and player.grace < 5.0 and int(time * 16.0) % 2 == 0
		# Frame heat (GDD 21D): the frame glows orange as it runs hot, then red, and flickers while it vents.
		if player.heat > 50.0 or player.vent_trip > 0.0:
			var hot := clampf((player.heat - 50.0) / 50.0, 0.0, 1.0)
			if player.vent_trip > 0.0:
				hot = 0.6 + 0.4 * sin(time * 20.0)
			var heat_color := Color(1.0, 0.55 - 0.3 * hot, 0.2)
			Art.draw_glow(ci, player.pos, 60.0, Art.with_alpha(heat_color, 0.2 + 0.5 * hot))
			# A ring of heat shimmer that closes as the frame nears a vent.
			ci.draw_arc(player.pos, 44.0, -PI * 0.5, -PI * 0.5 + TAU * player.heat / 100.0, 32, Art.with_alpha(heat_color, 0.5 + 0.4 * hot), 3.0, true)
		if transform_time > 0.0:
			# Changing form mid-mission (a chained stage): the frame folds from one form into the other.
			var toward_ship := 1.0 - transform_time / TRANSFORM_SECONDS
			FrameArt.draw_morph(ci, mission.run.frame_id, player.pos, player.facing, toward_ship if player.form == "ship" else 1.0 - toward_ship, time, {})
		else:
			# Wraith Drive: mid-dash the frame is a ghost, half there, trailing violet.
			var wraith := player.dash_time > 0.0 and mission.run.has_fusion("wraith_drive")
			if wraith:
				Art.draw_glow(ci, player.pos, 70.0, Color(0.7, 0.4, 1.0, 0.6))
			FrameArt.draw_frame(ci, mission.run.frame_id, player.form, player.pos, player.facing, time,
				{"speed": speed, "flash": 1.0 if flicker else hit_flash, "gear": _gear(), "fusions": mission.run.fusions,
				"resonance": _top_resonance(), "alpha": 0.45 if wraith else 1.0})
		# The Shield Generator's bubble while it holds a charge: a thin shimmering shell, brighter with two.
		if player.shield_charges > 0 and player.vent_trip <= 0.0:
			var bubble := (34.0 if player.form == "ship" else 40.0) + sin(time * 5.0) * 1.5
			Art.draw_glow(ci, player.pos, bubble * 1.4, Color(0.4, 0.85, 1.0, 0.12 * player.shield_charges))
			ci.draw_arc(player.pos, bubble, 0, TAU, 40, Color(0.55, 0.92, 1.0, 0.35 + 0.2 * player.shield_charges), 2.0, true)
			ci.draw_arc(player.pos, bubble, time * 2.0, time * 2.0 + 1.1, 12, Color(0.9, 1.0, 1.0, 0.8), 2.5, true)
	for shot: Shot in world.enemy_shots:
		ShotArt.draw_enemy_shot(ci, shot, time)


## Drone Pods, Soul Lantern wisps and the Ion Cannon's beams: things that fly or fire beside the frame.
func _draw_support_companions(ci: CanvasItem) -> void:
	if mission.run.is_online("option_pods"):
		for pod: Vector2 in mission.weapons.pod_positions:
			ci.draw_circle(pod, 9.0, Color(1, 0.55, 0.2))
			ci.draw_circle(pod, 5.0 + sin(time * 12.0), Color(1, 0.95, 0.7))
	for wisp: Vector2 in mission.world.wisp_positions():
		var lick := sin(time * 15.0 + wisp.x) * 2.0
		ci.draw_colored_polygon(PackedVector2Array([wisp + Vector2(0, -12 + lick), wisp + Vector2(6, 2), wisp + Vector2(0, 7), wisp + Vector2(-6, 2)]), Color(0.8, 0.55, 1.0, 0.9))
		ci.draw_circle(wisp + Vector2(0, 1), 3.0, Color(1, 0.9, 1.0))
	for beam: Array in mission.weapons.ion_beams:
		var from: Vector2 = beam[0]
		var to := from + Vector2.from_angle(beam[1]) * 1500.0
		var width: float = beam[2]
		ci.draw_line(from, to, Color(0.4, 0.85, 1.0, 0.35), width * 1.6, true)
		ci.draw_line(from, to, Color(0.6, 0.95, 1.0, 0.85), width * 0.8, true)
		ci.draw_line(from, to, Color(1, 1, 1, 0.95), width * 0.3, true)


func _draw_halo_saws(ci: CanvasItem) -> void:
	if fx.halo.is_empty() or not mission.run.is_online("orbital_halo"):
		return
	# Storm Halo: crackling lightning between neighbouring saws, the fence that shocks and erases bullets.
	var saws: Array = fx.halo["saws"]
	if mission.run.has_fusion("storm_halo") and saws.size() >= 2:
		for i in saws.size():
			var from: Vector2 = saws[i]
			var to: Vector2 = saws[(i + 1) % saws.size()]
			var bolt := PackedVector2Array([from])
			var side := (to - from).orthogonal().normalized()
			for step in range(1, 6):
				bolt.append(from.lerp(to, step / 6.0) + side * randf_range(-7.0, 7.0))
			bolt.append(to)
			ci.draw_polyline(bolt, Color(0.5, 0.85, 1.0, 0.55), 6.0, true)
			ci.draw_polyline(bolt, Color(0.92, 0.98, 1.0, 0.95), 2.0, true)
	var broken: Array = fx.halo.get("broken", [])
	for saw_index in saws.size():
		var saw: Vector2 = saws[saw_index]
		if broken.has(saw_index):
			# A broken saw: a dim stub regrowing in place.
			ci.draw_arc(saw, 9.0, 0, TAU, 12, Color(0.6, 0.55, 0.45, 0.5), 2.0, true)
			continue
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


## The frame's visible equipment: each slot's tech, its level and fork, and how long it has been online.
func _gear() -> Array:
	var run := mission.run
	var gear := []
	for tech_id in run.loadout:
		var level := run.level_of(tech_id) if tech_id != "" else 0
		if level > 0 and not tech_online_since.has(tech_id):
			# Tech online from the very start (the main weapon) shows already unfolded.
			tech_online_since[tech_id] = time if mission.world.time > 0.5 else -99.0
		gear.append({"tech": tech_id, "level": level, "fork": run.fork_of(tech_id) if tech_id != "" else "",
			"online_for": time - float(tech_online_since.get(tech_id, time))})
	return gear


## The element with the highest Resonance tier, for the frame's trim.
func _top_resonance() -> Array:
	var best := ["", 0]
	var tiers: Dictionary = mission.run.resonance_tiers()
	for element in tiers:
		if int(tiers[element]) > int(best[1]):
			best = [element, tiers[element]]
	return best


func _paint_glow(ci: CanvasItem) -> void:
	var world := mission.world
	var view := _view_rect().grow(80)
	for enemy: Enemy in world.enemies:
		if enemy.brain != "boss_part" and view.has_point(enemy.pos):
			EnemyArt.draw_glow(ci, enemy)
	if mission.stage.boss != null and not mission.stage.boss.finished:
		BossArt.draw_glow(ci, mission.stage.boss, time)
	if mission.stage.miniboss_active():
		BossArt.draw_glow(ci, mission.stage.miniboss, time)
	for pickup: Pickup in world.pickups:
		if view.has_point(pickup.pos):
			ShotArt.draw_pickup_glow(ci, pickup)
	# Tractor Beam: a ribbon of light to every drop it is reeling in.
	if mission.run.field_count("tractor_beam") > 0:
		for pickup: Pickup in world.pickups:
			if pickup.magnetized and view.has_point(pickup.pos) and pickup.pos.distance_to(world.player.pos) > world.base_pickup_reach():
				ShotArt.draw_tractor_beam(ci, world.player.pos, pickup.pos, time)
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
	# Accessibility (Settings): enemy bullets can glow through the dark.
	if not Save.setting("bullet_glow"):
		return
	for shot: Shot in mission.world.enemy_shots:
		if not shot.dead and view.has_point(shot.pos) and shot.pos.distance_to(at) > lamp * 0.6:
			ci.draw_circle(shot.pos, shot.radius * 0.9, shot.color.lightened(0.4))
			ci.draw_arc(shot.pos, shot.radius + 3.0, 0, TAU, 10, Art.with_alpha(shot.color, 0.6), 1.5, true)
