class_name WeaponSystem
extends RefCounted
## Fires the player's online tech each tick, and runs the support systems and the special button.
## Every tech works in every form (GDD 5F): in ship form weapons fire up the screen, in mech form they
## fire where you aim, or at the nearest enemy when you don't.
## Numbers follow TechData's level texts: level 2 adds the first boost, level 3 is the fork,
## levels 4 and 5 push the chosen fork further.

const AUTO_AIM_RANGE := 560.0

var world: World
var run: RunState
var player: PlayerFrame
var halo_angle := 0.0
var halo_pulse := 0.0
var vent_echo := 0.0          # Chain Vent's delayed second blast
var rage_timer := 0.0
var railstorm_timer := 2.0
var flare_cooldown := 0.0
var doom_bell_timer := 8.0
var pod_positions: Array = []   # Option Pods, where they are now (the view draws them here)
var ion_beams: Array = []       # Ion Cannon beams this tick: [from, angle, width] (the view draws them)
var wisp_dart_timer := 1.4      # Will-o'-Wisps: seconds until a wisp darts out
var ion_tick := 0.0             # Ion Cannon damages in pulses, ten times a second
var dash_blast_timer := 0.0     # Thruster Explosion: seconds until the next blast along the dash


func _init(target_world: World) -> void:
	world = target_world
	run = world.run
	player = world.player


func update(input: InputFrame, dt: float) -> void:
	_update_facing(input)
	var fire_rate := _fire_rate_multiplier()
	# With auto-fire off (Settings), weapons fire only while you hold fire; supports and the halo's
	# orbit keep working either way.
	var firing := world.autofire or input.fire
	for tech_id in run.online_tech():
		var slot: String = TechData.TECH[tech_id]["slot"]
		if slot == "special":
			continue
		if not firing and slot != "support" and tech_id != "orbital_halo":
			run.tech_timer[tech_id] = maxf(float(run.tech_timer.get(tech_id, 0.0)) - dt, 0.0)
			continue
		run.tech_timer[tech_id] = float(run.tech_timer.get(tech_id, 0.0)) - dt * (fire_rate if slot != "support" else 1.0)
		_update_tech(tech_id, dt)
	_update_special(input, dt)
	_update_ion_beam(dt)
	_update_dash(dt)
	_update_overdrive(dt)
	_update_resonance(dt)
	if vent_echo > 0.0:
		vent_echo -= dt
		if vent_echo <= 0.0:
			_vent(1.5)


func _update_facing(input: InputFrame) -> void:
	if player.form == "ship":
		player.facing = -PI * 0.5
		return
	if input.aim.length() > 0.25:
		player.facing = input.aim.angle()
		return
	# Auto-aim is an accessibility option (Settings, off by default): without it the mech faces where
	# you're moving once you let go of the aim stick.
	var target := auto_aim_target() if world.auto_aim else null
	if target != null:
		player.facing = (target.pos - player.pos).angle()
	elif input.move.length() > 0.2:
		player.facing = input.move.angle()


## Auto-aim picks the nearest enemy, but treats one whose shield faces you as three times as far away,
## so the frame doesn't waste its fire on a wall of armor while something softer is in reach.
func auto_aim_target() -> Enemy:
	var best: Enemy = null
	var best_score := AUTO_AIM_RANGE
	for enemy: Enemy in world.enemies:
		if enemy.dead or enemy.hidden or enemy.invulnerable or enemy.untargetable:
			continue
		var offset := player.pos - enemy.pos
		var score := offset.length()
		if score > AUTO_AIM_RANGE:
			continue
		if enemy.front_shield and absf(angle_difference(enemy.facing, offset.angle())) < deg_to_rad(70.0):
			score *= 3.0
		if score < best_score:
			best_score = score
			best = enemy
	return best


func _fire_rate_multiplier() -> float:
	var mult := 1.0
	if player.overdrive > 0.0:
		mult *= 1.8
	if run.is_online("overheat_core") and player.heat > _heat_max() * 0.5:
		mult *= 1.25
	if player.time_brake > 0.0 and run.fork_of("time_brake") == "b":
		mult *= 1.3
	return mult


func _damage(tech_id: String, base: float, per_level: float) -> float:
	var level := run.level_of(tech_id)
	return base * (1.0 + per_level * (level - 1)) * run.damage_multiplier(tech_id, player.armor_fraction())


func _ready_to_fire(tech_id: String, cooldown: float) -> bool:
	if run.tech_timer[tech_id] > 0.0:
		return false
	run.tech_timer[tech_id] = cooldown
	return true


func _update_tech(tech_id: String, dt: float) -> void:
	match tech_id:
		"pulse_driver": _pulse_driver()
		"thunder_lance": _thunder_lance()
		"hex_repeater": _hex_repeater()
		"arc_blade": _arc_blade()
		"swarm_pods": _swarm_pods()
		"orbital_halo": _orbital_halo(dt)
		"starfall": _starfall()
		"mirror_aegis": _mirror_aegis()
		"overheat_core": pass   # driven by main weapon volleys
		"graze_engine": pass    # driven by World's graze callback
		"option_pods": _option_pods(dt)
		"soul_lantern": _soul_lantern()


# ---------------------------------------------------------------- main weapons

## Called by every main weapon volley: heat, echoes and afterimages hang off the main weapon.
func _main_volley(fire: Callable) -> void:
	fire.call(player.pos, 1.0)
	# Option Pods copy every volley from wherever they are.
	if run.is_online("option_pods"):
		var copy := (0.35 + 0.07 * run.level_of("option_pods")) * (1.3 if run.fork_of("option_pods") == "a" else 1.0)
		for pod: Vector2 in pod_positions:
			fire.call(pod, copy)
	var echo := run.field_count("echo_chamber")
	if echo > 0:
		player.echo_counter += 1
		if player.echo_counter >= (4 if echo == 1 else 3):
			player.echo_counter = 0
			fire.call(player.pos + Vector2.from_angle(player.facing + PI * 0.5) * 10.0, 1.0)
	if FrameData.get_frame(run.frame_id)["trait"] == "afterimage" and player.afterimages.size() > 8:
		fire.call(player.afterimages[8], 0.4)
	if run.is_online("overheat_core"):
		player.heat += 1.0
		if player.heat >= _heat_max():
			player.heat = 0.0
			_vent(1.0)
			if run.fork_of("overheat_core") == "b":
				vent_echo = 0.4


func _pulse_driver() -> void:
	var level := run.level_of("pulse_driver")
	if not _ready_to_fire("pulse_driver", 0.15 if level < 5 else 0.12):
		return
	var damage := _damage("pulse_driver", 9.0, 0.14)
	var fork := run.fork_of("pulse_driver")
	var phoenix := run.has_fusion("phoenix_driver")
	var color := Color(1.0, 0.6, 0.25) if phoenix else Color(0.45, 0.9, 1.0)
	var fire := func(origin: Vector2, scale: float) -> void:
		var angles: Array = [0.0]
		if level >= 4:
			angles = [-0.16, 0.0, 0.16]
		var offsets: Array = [0.0] if level < 2 else ([-9.0, 9.0] if level < 4 else [0.0])
		for offset: float in offsets:
			for spread: float in angles:
				var side := Vector2.from_angle(player.facing + PI * 0.5) * offset
				var shot := world.player_shot(origin + side, Vector2.from_angle(player.facing + spread) * 980.0,
					damage * scale, "pulse_driver", "phoenix" if phoenix else "bolt", color)
				shot.radius = 5.0
				shot.life = 1.1
				if phoenix:
					shot.pierce = 3
					shot.radius = 8.0
				if fork == "a":
					# Now that misses bounce off the field's edges, every bounce lands; 1 at the fork, 2 at level 5.
					shot.bounces = 1 + (level - 3) / 2
					shot.bounce_bonus = 0.18
				elif fork == "b":
					shot.split_after = 0.2
					shot.split_count = 3 if level < 5 else 5
	_main_volley(fire)
	world.emit("sound", {"name": "shot"})


func _thunder_lance() -> void:
	var level := run.level_of("thunder_lance")
	if not _ready_to_fire("thunder_lance", 0.85 - 0.06 * level):
		return
	var damage := _damage("thunder_lance", 42.0, 0.2)
	var fork := run.fork_of("thunder_lance")
	var fire := func(origin: Vector2, scale: float) -> void:
		var angles: Array = [0.0]
		if fork == "b":
			angles = [-0.12, 0.12] if level < 5 else [-0.14, 0.0, 0.14]
		for spread: float in angles:
			var shot := world.player_shot(origin, Vector2.from_angle(player.facing + spread) * 2300.0,
				damage * scale, "thunder_lance", "rail", Color(0.6, 0.85, 1.0))
			shot.radius = 8.0
			shot.pierce = 99
			shot.life = 0.6
			if fork == "a":
				shot.chain_arcs = 2 if level < 5 else 3
	_main_volley(fire)
	world.emit("sound", {"name": "rail"})


func _hex_repeater() -> void:
	var level := run.level_of("hex_repeater")
	if not _ready_to_fire("hex_repeater", 0.36 - 0.03 * level):
		return
	var damage := _damage("hex_repeater", 12.0, 0.16)
	var fork := run.fork_of("hex_repeater")
	var horizon := run.has_fusion("event_horizon")
	var fire := func(origin: Vector2, scale: float) -> void:
		var count := 2 if level < 4 else 3
		for i in count:
			var angle := player.facing + lerpf(-0.6, 0.6, float(i) / float(count - 1))
			var shot := world.player_shot(origin, Vector2.from_angle(angle) * (480.0 + 30.0 * level),
				damage * scale, "hex_repeater", "hex", Color(0.85, 0.5, 1.0))
			shot.radius = 7.0
			shot.homing = 4.0 + 0.5 * level
			shot.life = 1.8
			shot.hex_mark = fork == "a"
			shot.hex_shatter = fork == "b"
			shot.devours = horizon
	_main_volley(fire)
	world.emit("sound", {"name": "hex"})


# ---------------------------------------------------------------- weapons

func _arc_blade() -> void:
	var level := run.level_of("arc_blade")
	if not _ready_to_fire("arc_blade", 1.5 - 0.1 * level):
		return
	var fork := run.fork_of("arc_blade")
	var reflex := run.has_fusion("reflex_blade")
	var span := deg_to_rad(210.0 if level < 4 else 250.0)
	var radius := (118.0 + 12.0 * level) * (1.4 if reflex else 1.0)
	var damage := _damage("arc_blade", 34.0, 0.22)
	var spins := 1
	if fork == "b":
		span = TAU
		spins = 2
	for spin in spins:
		var start := player.facing - span * 0.5
		world.blades.append({
			"start": start, "end": start + span, "angle": start,
			"time": -0.18 * spin, "duration": 0.24 if span < TAU else 0.32,
			"radius": radius, "damage": damage, "hit": {},
			"phantom": fork == "a", "reflect": reflex, "span": span,
		})
	world.emit("sound", {"name": "slash"})


func _swarm_pods() -> void:
	var level := run.level_of("swarm_pods")
	if not _ready_to_fire("swarm_pods", 2.1 - 0.1 * level):
		return
	var fork := run.fork_of("swarm_pods")
	var count := 3 + level
	if fork == "b":
		count *= 2
	var damage := _damage("swarm_pods", 15.0, 0.16)
	for i in count:
		var side := -1.0 if i % 2 == 0 else 1.0
		var launch := player.facing + side * (0.9 + 0.12 * (i / 2))
		var shot := world.player_shot(player.pos, Vector2.from_angle(launch) * 180.0, damage, "swarm_pods", "missile", Color(1.0, 0.6, 0.3))
		shot.homing = 5.5
		shot.accel = 900.0
		shot.max_speed = 640.0
		shot.splash = 46.0 + (8.0 if level >= 4 else 0.0)
		shot.life = 2.4
		shot.radius = 6.0
		shot.bomblets = 3 if fork == "a" else 0
		shot.retarget = fork == "b"
		shot.calls_meteor = run.has_fusion("armageddon_protocol")
	world.emit("sound", {"name": "missiles"})


## Saws orbit the frame. Each saw hits an enemy at most every 0.3 s and shreds bullets it touches.
func _orbital_halo(dt: float) -> void:
	var level := run.level_of("orbital_halo")
	var fork := run.fork_of("orbital_halo")
	var count: int = [2, 3, 3, 4, 4][level - 1]
	if fork == "b":
		count *= 2
	var spin := 3.2 * (2.0 if fork == "b" else 1.0)
	halo_angle += spin * dt
	var radius := 88.0
	if fork == "a":
		halo_pulse += dt
		var cycle := fmod(halo_pulse, 4.0)
		if cycle > 2.8:
			radius = 88.0 + 170.0 * sin((cycle - 2.8) / 1.2 * PI)
	var damage := _damage("orbital_halo", 11.0, 0.18)
	var storm := run.has_fusion("storm_halo")
	var saws := []
	for i in count:
		saws.append(player.pos + Vector2.from_angle(halo_angle + TAU * i / count) * radius)
	world.emit("halo", {"saws": saws, "radius": radius})
	for saw_index in saws.size():
		var saw: Vector2 = saws[saw_index]
		for enemy: Enemy in world.enemies.duplicate():
			if enemy.dead or enemy.hidden:
				continue
			if saw.distance_to(enemy.pos) < enemy.radius + 14.0:
				var key := "%d" % saw_index
				if world.time < float(enemy.orbit_hits.get(key, 0.0)):
					continue
				enemy.orbit_hits[key] = world.time + 0.3
				world.hurt_enemy(enemy, damage, "orbital_halo")
				if storm:
					var next := world.nearest_enemy(enemy.pos, 200.0, {enemy.id: true})
					if next != null:
						world.emit("lightning", {"from": enemy.pos, "to": next.pos})
						world.hurt_enemy(next, damage * 0.8, "orbital_halo")
		for shot: Shot in world.enemy_shots:
			if not shot.dead and saw.distance_to(shot.pos) < 16.0:
				shot.dead = true
				world.emit("spark", {"pos": shot.pos, "color": Color(1, 0.9, 0.6)})


func _starfall() -> void:
	var level := run.level_of("starfall")
	# Meteors need something to fall on; hold fire until an enemy is near.
	if world.random_enemy_near(player.pos, 640.0) == null:
		return
	if not _ready_to_fire("starfall", 2.7 - 0.12 * level):
		return
	var fork := run.fork_of("starfall")
	var count: int = [1, 2, 2, 3, 3][level - 1]
	var radius := 78.0
	var damage := _damage("starfall", 46.0, 0.2)
	if fork == "b":
		count += 3
		radius = 58.0
		damage *= 0.7
	for i in count:
		var target := world.random_enemy_near(player.pos, 640.0)
		var at := player.pos + Vector2.from_angle(world.rng.randf() * TAU) * world.rng.randf_range(80.0, 260.0)
		if target != null:
			at = target.pos + target.vel * 0.4
		world.call_meteor(at, radius, damage, fork == "a")


# ---------------------------------------------------------------- support

func _mirror_aegis() -> void:
	var level := run.level_of("mirror_aegis")
	# Auto-flare: when a volley closes in, the bubble snaps on by itself (GDD 9C's shield lesson).
	flare_cooldown -= World.DT
	if player.mirror_time <= 0.0 and flare_cooldown <= 0.0:
		var close := 0
		for shot: Shot in world.enemy_shots:
			if shot.pos.distance_squared_to(player.pos) < 150.0 * 150.0:
				close += 1
		if close >= 4:
			player.mirror_time = 0.6 + 0.1 * level
			flare_cooldown = 2.2 - 0.2 * level
			world.emit("sound", {"name": "mirror"})
	if not _ready_to_fire("mirror_aegis", 7.0 - 0.6 * level):
		return
	player.mirror_time = 1.3 + 0.15 * level
	world.emit("sound", {"name": "mirror"})


func _heat_max() -> float:
	return 60.0 - 4.0 * run.level_of("overheat_core")


func _vent(scale: float) -> void:
	var level := run.level_of("overheat_core")
	var radius := (210.0 + 20.0 * level) * scale
	var damage := _damage("overheat_core", 40.0, 0.2)
	if run.has_fusion("supernova_core"):
		world.clear_bullets(player.pos, 2000.0)
		radius *= 1.5
		world.emit("flash", {"color": Color(1, 0.8, 0.5), "amount": 0.35})
	else:
		world.clear_bullets(player.pos, radius)
	world.explode(player.pos, radius, damage, "overheat_core", Color(1.0, 0.55, 0.25))
	world.emit("shake", {"amount": 6.0})
	world.emit("sound", {"name": "vent"})
	if run.fork_of("overheat_core") == "a":
		var ring := world.add_zone("fire", player.pos, radius * 0.75, 3.0, damage * 0.15, false, {"tick": 0.35, "color": Color(1, 0.45, 0.2)})
		ring.hit_ids = {}


## The Graze Engine fills on near misses; World calls this for each graze.
func on_graze() -> void:
	var level := run.level_of("graze_engine")
	player.graze += 1.0
	world.emit("graze", {"pos": player.pos})
	if run.fork_of("graze_engine") == "a":
		player.shield = minf(player.max_shield, player.shield + (1.0 if level < 5 else 2.0))
	var needed := (30.0 - 3.0 * level) * (0.5 if run.has_fusion("phoenix_driver") else 1.0)
	if player.graze >= needed:
		player.graze = 0.0
		player.overdrive = 4.0 + 0.5 * level
		world.emit("banner", {"text": "OVERDRIVE", "style": "gold"})
		world.emit("sound", {"name": "overdrive"})
		if run.fork_of("graze_engine") == "a":
			player.repair(10.0)


func graze_needed() -> float:
	var level := maxi(run.level_of("graze_engine"), 1)
	return (30.0 - 3.0 * level) * (0.5 if run.has_fusion("phoenix_driver") else 1.0)


func _update_overdrive(dt: float) -> void:
	if player.overdrive <= 0.0 or run.fork_of("graze_engine") != "b":
		return
	rage_timer -= dt
	if rage_timer <= 0.0:
		rage_timer = 0.3
		var origin: Vector2 = player.afterimages[mini(6, player.afterimages.size() - 1)]
		for i in 8:
			var shot := world.player_shot(origin, Vector2.from_angle(TAU * i / 8.0) * 560.0, _damage("graze_engine", 10.0, 0.15), "graze_engine", "bolt", Color(1, 0.85, 0.3))
			shot.life = 0.7


# ---------------------------------------------------------------- resonance

## Top-tier Resonance effects that fire on their own (GDD 9H).
func _update_resonance(dt: float) -> void:
	if world.resonance["kinetic"] >= 3:
		railstorm_timer -= dt
		if railstorm_timer <= 0.0:
			railstorm_timer = 2.0
			var target := world.nearest_enemy(player.pos, 900.0)
			if target != null:
				var slug := world.player_shot(player.pos, (target.pos - player.pos).normalized() * 2400.0, 55.0, "resonance", "rail", Color(1, 0.85, 0.45))
				slug.pierce = 99
				slug.radius = 9.0
				slug.life = 0.6
				world.emit("sound", {"name": "rail"})
	if world.resonance["mawjig"] >= 3:
		doom_bell_timer -= dt
		if doom_bell_timer <= 0.0:
			doom_bell_timer = 8.0
			var rung := 0
			for enemy: Enemy in world.enemies:
				if rung < 3 and enemy.hex_marked and not enemy.dead and not enemy.hidden:
					world.call_meteor(enemy.pos, 70.0, 50.0, false)
					rung += 1
			if rung > 0:
				world.emit("sound", {"name": "blink"})


# ---------------------------------------------------------------- support: pods and wisps

## Option Pods: two (three at level 4) ride your trail; Formation locks them beside you, Hunter Pods
## break away to circle the nearest enemies.
func _option_pods(dt: float) -> void:
	var level := run.level_of("option_pods")
	var count := 3 if level >= 4 else 2
	var fork := run.fork_of("option_pods")
	var targets := []
	var taken := {}
	for i in count:
		var spot: Vector2 = player.afterimages[mini(12 * (i + 1), player.afterimages.size() - 1)] if not player.afterimages.is_empty() else player.pos
		if fork == "a":
			var side := Vector2.from_angle(player.facing + PI * 0.5)
			spot = player.pos + side * (46.0 if i == 0 else -46.0) if i < 2 else player.pos - Vector2.from_angle(player.facing) * 40.0
		elif fork == "b":
			var prey := world.nearest_enemy(player.pos, 520.0, taken)
			if prey != null:
				taken[prey.id] = true
				spot = prey.pos + Vector2.from_angle(world.time * 2.5 + i * PI) * 90.0
		targets.append(spot)
	while pod_positions.size() < count:
		pod_positions.append(player.pos)
	pod_positions.resize(count)
	for i in count:
		pod_positions[i] = (pod_positions[i] as Vector2).lerp(targets[i], minf(1.0, 10.0 * dt))


## Soul Lantern: the wisps themselves live in World (they swallow bullets there); Will-o'-Wisps sends
## one darting at an enemy every so often.
func _soul_lantern() -> void:
	if run.fork_of("soul_lantern") != "a" or world.wisps <= 0:
		return
	wisp_dart_timer -= World.DT
	if wisp_dart_timer > 0.0:
		return
	wisp_dart_timer = 1.4
	_launch_wisps(1)


## Sends wisps out as homing spirits.
func _launch_wisps(count: int) -> void:
	var positions: Array = world.wisp_positions()
	for i in mini(count, world.wisps):
		var at: Vector2 = positions[i]
		var spirit := world.player_shot(at, Vector2.from_angle(world.rng.randf() * TAU) * 260.0, _damage("soul_lantern", 30.0, 0.15), "soul_lantern", "orb", Color(0.85, 0.6, 1.0))
		spirit.homing = 7.0
		spirit.accel = 700.0
		spirit.max_speed = 620.0
		spirit.life = 2.0
	world.wisps -= mini(count, world.wisps)


# ---------------------------------------------------------------- special

func special_ready() -> bool:
	var tech_id := run.special_tech()
	return tech_id != "" and run.is_online(tech_id) and (player.special_cooldown <= 0.0 or player.special_charges > 0)


func special_cooldown_total() -> float:
	var tech_id := run.special_tech()
	var level := maxi(run.level_of(tech_id), 1)
	match tech_id:
		"nova_bomb": return 22.0 - 2.0 * level
		"time_brake": return 20.0 - 1.5 * level
		"ion_cannon": return 18.0 - 1.5 * level
		"thruster_explosion": return 7.5 - 0.6 * level
	return 20.0


func max_special_charges() -> int:
	return 2 if run.fork_of("nova_bomb") == "b" and run.special_tech() == "nova_bomb" else 1


func _update_special(input: InputFrame, dt: float) -> void:
	var tech_id := run.special_tech()
	if tech_id == "" or not run.is_online(tech_id):
		return
	if player.special_charges < max_special_charges():
		player.special_cooldown -= dt
		if player.special_cooldown <= 0.0:
			player.special_charges += 1
			if player.special_charges < max_special_charges():
				player.special_cooldown = special_cooldown_total()
	if not input.special or player.special_charges <= 0:
		return
	player.special_charges -= 1
	if player.special_cooldown <= 0.0:
		player.special_cooldown = special_cooldown_total()
	match tech_id:
		"nova_bomb": _nova_bomb()
		"time_brake": _time_brake()
		"ion_cannon": _ion_cannon()
		"thruster_explosion": _thruster_explosion()
	world.emit("special_used", {"tech": tech_id})


func _ion_cannon() -> void:
	player.ion_time = 1.6 + (0.4 if run.level_of("ion_cannon") >= 5 else 0.0)
	ion_tick = 0.0
	world.emit("banner", {"text": "ION CANNON", "style": "cyan"})
	world.emit("shake", {"amount": 6.0})
	world.emit("sound", {"name": "rail"})


## While the Ion Cannon fires: beams from your frame (and your pods, with Starbreaker) burn every enemy
## along them in pulses and erase enemy bullets they touch.
func _update_ion_beam(dt: float) -> void:
	ion_beams.clear()
	if player.ion_time <= 0.0:
		return
	var level := run.level_of("ion_cannon")
	var fork := run.fork_of("ion_cannon")
	var width := 44.0 + (18.0 if level >= 4 else 0.0)
	var angles: Array = [player.facing]
	if fork == "a":
		angles = [player.facing + sin((1.6 - player.ion_time) * 2.4) * 0.6]
	elif fork == "b":
		angles = [player.facing - 0.22, player.facing + 0.22]
	var origins: Array = [player.pos]
	if run.has_fusion("starbreaker"):
		origins.append_array(pod_positions)
	for origin: Vector2 in origins:
		for angle: float in angles:
			ion_beams.append([origin, angle, width if origin == player.pos else width * 0.6])
	ion_tick -= dt
	var pulse := ion_tick <= 0.0
	if pulse:
		ion_tick = 0.1
	var damage := _damage("ion_cannon", 26.0, 0.2)
	for beam: Array in ion_beams:
		var from: Vector2 = beam[0]
		var to := from + Vector2.from_angle(beam[1]) * 1500.0
		var half: float = beam[2] * 0.5
		for shot: Shot in world.enemy_shots:
			if not shot.dead and shot.pos.distance_to(Geometry2D.get_closest_point_to_segment(shot.pos, from, to)) < half:
				shot.dead = true
		if pulse:
			for enemy: Enemy in world.enemies.duplicate():
				if enemy.dead or enemy.hidden:
					continue
				if enemy.pos.distance_to(Geometry2D.get_closest_point_to_segment(enemy.pos, from, to)) < half + enemy.radius:
					world.hurt_enemy(enemy, damage, "ion_cannon")


func _thruster_explosion() -> void:
	var level := run.level_of("thruster_explosion")
	var direction := player.vel.normalized() if player.vel.length() > 40.0 else Vector2.from_angle(player.facing)
	player.dash_dir = direction
	player.dash_time = 0.26 + (0.08 if level >= 4 else 0.0)
	player.grace = maxf(player.grace, player.dash_time + 0.2)
	dash_blast_timer = 0.0
	if run.has_fusion("wraith_drive"):
		_launch_wisps(world.wisps)
		world.wisps = world.max_wisps()
	world.emit("shake", {"amount": 8.0})
	world.emit("sound", {"name": "explode_big"})


## During the dash: a blast every few frames along the way, clearing bullets around you.
func _update_dash(dt: float) -> void:
	if player.dash_time <= 0.0:
		if dash_blast_timer > 0.0:
			# The dash just ended: Shockwave's ring.
			dash_blast_timer = 0.0
			if run.fork_of("thruster_explosion") == "b":
				var ring := world.add_zone("ring", player.pos, 260.0, 0.4, _damage("thruster_explosion", 40.0, 0.2), false, {"color": Color(1, 0.85, 0.5), "clears_bullets": true})
				ring.hit_ids = {}
		return
	dash_blast_timer -= dt
	if dash_blast_timer > 0.0:
		return
	dash_blast_timer = 0.05
	var radius := 70.0 + (20.0 if run.level_of("thruster_explosion") >= 5 else 0.0)
	world.explode(player.pos, radius, _damage("thruster_explosion", 34.0, 0.2), "thruster_explosion", Color(1, 0.75, 0.35))
	world.clear_bullets(player.pos, radius)
	if run.fork_of("thruster_explosion") == "a":
		world.add_zone("fire", player.pos, radius * 0.6, 2.2, 8.0, false, {"tick": 0.4, "color": Color(1, 0.55, 0.2)})


func _nova_bomb() -> void:
	var level := run.level_of("nova_bomb")
	var damage := _damage("nova_bomb", 120.0, 0.2)
	var radius := 620.0 + (120.0 if level >= 4 else 0.0)
	if run.fork_of("nova_bomb") == "a":
		var at := player.pos + Vector2.from_angle(player.facing) * 220.0
		world.add_zone("black_hole", at, 260.0, 1.3, 0.0, false, {"color": Color(0.6, 0.3, 1.0)})
		var blast := world.add_zone("ring", at, radius, 0.6, damage * 1.3, false, {"color": Color(0.8, 0.6, 1.0), "warn": 1.2, "clears_bullets": true})
		blast.hit_ids = {}
		world.clear_bullets(player.pos, 2000.0)
		world.emit("banner", {"text": "BLACK HOLE", "style": "violet"})
		world.emit("sound", {"name": "black_hole"})
		return
	world.clear_bullets(player.pos, 2000.0)
	var ring := world.add_zone("ring", player.pos, radius, 0.5, damage, false, {"color": Color(1, 1, 1), "clears_bullets": true})
	ring.hit_ids = {}
	world.emit("flash", {"color": Color(1, 1, 1), "amount": 0.9})
	world.emit("shake", {"amount": 14.0})
	world.emit("sound", {"name": "nova"})


func _time_brake() -> void:
	var level := run.level_of("time_brake")
	player.time_brake = 4.0 + 0.5 * level + (2.0 if run.fork_of("time_brake") == "b" else 0.0)
	world.emit("banner", {"text": "TIME BRAKE", "style": "blue"})
	world.emit("sound", {"name": "time_brake"})


## Stasis Shatter: when the brake ends, slowed bullets become Data Shards.
func on_time_brake_ended() -> void:
	if run.fork_of("time_brake") != "a":
		return
	var converted := 0
	for shot: Shot in world.enemy_shots:
		if shot.slowed and not shot.dead:
			shot.dead = true
			converted += 1
			if converted % 2 == 0:
				world.drop_pickup("shard", shot.pos, 1.0)
	if converted > 0:
		world.emit("banner", {"text": "SHATTER x%d" % converted, "style": "blue"})
		world.emit("sound", {"name": "shatter"})
