class_name World
extends RefCounted
## Everything that exists inside a mission right now, and the shared rules for how it moves and collides:
## shots, pickups, area effects, blade sweeps, walls, damage and death.
## Enemy behaviour lives in EnemySystem, player tech in WeaponSystem, mission flow in Mission.
##
## The simulation is deterministic: it only uses `rng` (seeded per mission) and runs on a fixed step,
## so a recorded input list replays a mission exactly. Presentation reads `events` and never writes back.

const DT := 1.0 / 60.0
const PICKUP_RADIUS := 105.0
## Straight shots a mirrored elite can turn away before its mirror cracks.
const MIRROR_ELITE_HITS := 15
## How many drops Tractor Beam can reel in at once.
const TRACTOR_BEAMS := 4
## Seconds before the boss's prize starts drifting toward you.
const PRIZE_DRIFT_DELAY := 3.0
## Chain Reaction (Explosive II): how long each link waits, and how many links a cascade can run.
const CHAIN_REACTION_DELAY := 0.12
const CHAIN_REACTION_GENERATIONS := 3
## How far a Chain Bolt's kill arcs to find the next enemy, and how much of the bolt each jump keeps (GDD 13W).
const CHAIN_RANGE := 260.0
const CHAIN_KEEPS := 0.8
## Meteors (Starfall, Doom Bell) streak in from the upper left; Comet Trail fires lie along that path.
const METEOR_FROM := Vector2(-0.5, -0.866)
const GRAZE_MARGIN := 26.0
const MIRROR_RADIUS := 66.0

var rng := RandomNumberGenerator.new()
var tick := 0
var time := 0.0
var player: PlayerFrame
var run: RunState

var enemies: Array = []
var player_shots: Array = []
var enemy_shots: Array = []
var pickups: Array = []
var zones: Array = []
var blades: Array = []          # Arc Blade sweeps in progress
var autofire := true             # weapons fire on their own (Settings); off: only while you hold fire
var auto_aim := true             # the mech turns to the nearest enemy when you aren't aiming (Settings)
var prize_waiting := false      # the last boss's prize is on the field; the mission ends once it's taken
var wisps := 0                  # Soul Lantern: wisps circling the frame, each good for one bullet
var _plate_armor_applied := 0.0 # how much Armor the plating has added to the frame so far
var siphoned_this_stage := 0.0  # Mawjig Siphon's repairs this stage (it caps per stage)
var allies: Array = []          # {pos, fire_timer, look}: things fighting on your side, like a turned clone
var events: Array = []          # things that happened this tick, for art and sound

var bounds := Rect2(0, 0, 1200, 800)        # where the player can go
var shot_bounds := Rect2(-80, -80, 1360, 960)
var walls: Array = []                       # solid Rect2s
var next_enemy_id := 1

# Difficulty and modifiers, set by Mission from the planet's danger and special condition.
var enemy_hp_scale := 1.0
var enemy_damage_scale := 1.0
var bullet_speed_scale := 1.0
var spawn_scale := 1.0
var xp_scale := 1.0
var crate_chance := 0.35
var elite_blueprint_tech := ""
var elite_chance := 0.0          # chance an ordinary enemy spawns as an elite with a twist
var elite_mods: Array = []       # which twists elites can have on this planet
var reward_tech := ""            # the planet's blueprint tech; elites with a twist sometimes carry one
var dark := false
var gentle := false              # the first planet: slower, sparser enemy fire
var enemy_fire_scale := 1.0      # how fast enemies and bosses cycle their attacks (danger and Threat)

# Hooks the Mission listens to.
var on_player_hurt: Callable
var on_collect: Callable

# Resonance tiers this tick (GDD 9H), refreshed by Mission so combat checks are cheap.
var resonance := {"energy": 0, "explosive": 0, "kinetic": 0, "mawjig": 0}
var chain_blasts: Array = []     # Chain Reaction blasts waiting to go off: {pos, delay, generation}
var _chain_generation := 0       # how deep in a cascade the blast going off right now is


func refresh_resonance() -> void:
	resonance = run.resonance_tiers()


func emit(type: String, data: Dictionary = {}) -> void:
	data["type"] = type
	events.append(data)


func enemy_time_scale() -> float:
	return 0.25 if player.time_brake > 0.0 else 1.0


# ---------------------------------------------------------------- spawning

func spawn_enemy(kind: String, at: Vector2, overrides: Dictionary = {}) -> Enemy:
	var data := EnemyData.get_enemy(kind)
	var enemy := Enemy.new()
	enemy.id = next_enemy_id
	next_enemy_id += 1
	enemy.kind = kind
	enemy.brain = data["brain"]
	enemy.look = data["look"]
	enemy.pos = at
	enemy.max_hp = data["hp"] * enemy_hp_scale
	enemy.hp = enemy.max_hp
	enemy.radius = data["radius"]
	enemy.contact = data["contact"] * enemy_damage_scale
	enemy.xp = data["xp"]
	enemy.color = data["color"]
	enemy.elite = data.get("elite", false)
	enemy.objective = data.get("objective", false)
	enemy.drops_crate = data.get("drops_crate", false)
	enemy.front_shield = data.get("front_shield", false)
	enemy.ghost = data.get("ghost", false)
	enemy.fire_timer = rng.randf_range(0.6, 1.8)
	for key in overrides:
		enemy.set(key, overrides[key])
	if not overrides.has("elite"):
		_maybe_promote(enemy, data)
	enemies.append(enemy)
	return enemy


## Elites with a twist: tougher, worth more, and each one asks something different of your build.
## Shielded: a barrier soaks damage first. Splitting: it breaks into two when destroyed.
## Mirrored: straight shots bounce off it; it takes homing shots, blades, blasts and meteors.
const ELITE_MIN_HP := 20
const ELITE_EXCLUDED := ["boss_part", "cracked_wall", "supply_barge", "mimic", "hive_nest"]


func _maybe_promote(enemy: Enemy, data: Dictionary) -> void:
	if elite_chance <= 0.0 or enemy.elite or enemy.objective or elite_mods.is_empty():
		return
	if int(data["hp"]) < ELITE_MIN_HP or ELITE_EXCLUDED.has(enemy.kind):
		return
	if rng.randf() >= elite_chance:
		return
	enemy.elite = true
	enemy.elite_mod = elite_mods[rng.randi() % elite_mods.size()]
	enemy.max_hp *= 2.2
	enemy.hp = enemy.max_hp
	enemy.radius *= 1.25
	# An elite's body hits as hard as a boss's (GDD 13C).
	enemy.contact = maxf(enemy.contact, MissionData.HIT_BODY * enemy_damage_scale)
	enemy.xp *= 3
	match enemy.elite_mod:
		"shielded":
			enemy.shield_hp = enemy.max_hp * 0.6
		"mirrored":
			enemy.reflects = true


## Fires one enemy bullet. Damage and speed are scaled by the planet's danger.
func enemy_shot(at: Vector2, angle: float, speed: float, options: Dictionary = {}) -> Shot:
	var shot := Shot.new()
	shot.pos = at
	shot.origin = at
	var speed_scale := bullet_speed_scale * (0.8 if gentle else 1.0)
	shot.vel = Vector2.from_angle(angle) * speed * speed_scale
	shot.radius = options.get("radius", 6.0)
	shot.damage = options.get("damage", 10.0) * enemy_damage_scale
	shot.look = options.get("look", "orb")
	shot.color = options.get("color", Color(1.0, 0.4, 0.55))
	shot.life = options.get("life", 6.0)
	shot.accel = options.get("accel", 0.0)
	shot.max_speed = options.get("max_speed", 0.0)
	enemy_shots.append(shot)
	return shot


func enemy_aimed(at: Vector2, count: int, spread: float, speed: float, options: Dictionary = {}) -> void:
	var base := (player.pos - at).angle()
	for i in count:
		var offset := 0.0 if count == 1 else lerpf(-spread * 0.5, spread * 0.5, float(i) / float(count - 1))
		enemy_shot(at, base + offset, speed, options)


func enemy_ring(at: Vector2, count: int, speed: float, offset: float = 0.0, options: Dictionary = {}) -> void:
	for i in count:
		enemy_shot(at, offset + TAU * float(i) / float(count), speed, options)


func player_shot(at: Vector2, velocity: Vector2, damage: float, tech: String, look: String, color: Color) -> Shot:
	var shot := Shot.new()
	shot.pos = at
	shot.origin = at
	shot.vel = velocity
	shot.damage = damage
	shot.tech = tech
	shot.look = look
	shot.color = color
	# Kinetic resonance: everything punches through one more enemy.
	if resonance["kinetic"] >= 1:
		shot.pierce += 1
	player_shots.append(shot)
	return shot


func add_zone(kind: String, at: Vector2, radius: float, life: float, damage: float, hostile: bool, options: Dictionary = {}) -> Zone:
	var zone := Zone.new()
	zone.kind = kind
	zone.pos = at
	zone.radius = radius
	zone.life = life
	zone.max_life = life
	zone.damage = damage
	zone.hostile = hostile
	zone.warn = options.get("warn", 0.0)
	zone.tick = options.get("tick", 0.5)
	zone.angle = options.get("angle", 0.0)
	zone.length = options.get("length", 0.0)
	zone.width = options.get("width", 0.0)
	zone.spin = options.get("spin", 0.0)
	zone.color = options.get("color", Color(1, 0.5, 0.2))
	zone.clears_bullets = options.get("clears_bullets", false)
	zones.append(zone)
	return zone


func drop_pickup(kind: String, at: Vector2, value: float = 1.0, tech: String = "") -> Pickup:
	var pickup := Pickup.new()
	pickup.kind = kind
	pickup.pos = at
	pickup.value = value
	pickup.tech = tech
	pickup.vel = Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(40.0, 140.0)
	pickup.life = 9.0 if kind == "shard" else 14.0
	pickups.append(pickup)
	return pickup


# ---------------------------------------------------------------- queries

func nearest_enemy(from: Vector2, max_range: float, exclude: Dictionary = {}) -> Enemy:
	var best: Enemy = null
	var best_distance := max_range * max_range
	for enemy: Enemy in enemies:
		if enemy.dead or enemy.hidden or enemy.invulnerable or enemy.untargetable or exclude.has(enemy.id):
			continue
		var d := from.distance_squared_to(enemy.pos)
		if d < best_distance:
			best_distance = d
			best = enemy
	return best


func enemy_by_id(enemy_id: int) -> Enemy:
	for enemy: Enemy in enemies:
		if enemy.id == enemy_id and not enemy.dead:
			return enemy
	return null


func random_enemy_near(from: Vector2, max_range: float) -> Enemy:
	var candidates := []
	for enemy: Enemy in enemies:
		if not enemy.dead and not enemy.hidden and not enemy.invulnerable and not enemy.untargetable and from.distance_to(enemy.pos) < max_range:
			candidates.append(enemy)
	if candidates.is_empty():
		return null
	return candidates[rng.randi() % candidates.size()]


func point_in_wall(point: Vector2) -> bool:
	for wall: Rect2 in walls:
		if wall.has_point(point):
			return true
	return false


## Pushes a circle out of every wall it overlaps. Returns the corrected position.
func push_out_of_walls(at: Vector2, radius: float) -> Vector2:
	var result := at
	for wall: Rect2 in walls:
		var closest := result.clamp(wall.position, wall.end)
		var offset := result - closest
		var distance_squared := offset.length_squared()
		if distance_squared >= radius * radius:
			continue
		if distance_squared < 0.0001:
			# Centre is inside the wall: push out along the shortest axis.
			var left := result.x - wall.position.x
			var right := wall.end.x - result.x
			var top := result.y - wall.position.y
			var bottom := wall.end.y - result.y
			var smallest := minf(minf(left, right), minf(top, bottom))
			if smallest == left:
				result.x = wall.position.x - radius
			elif smallest == right:
				result.x = wall.end.x + radius
			elif smallest == top:
				result.y = wall.position.y - radius
			else:
				result.y = wall.end.y + radius
		else:
			result = closest + offset.normalized() * radius
	return result


# ---------------------------------------------------------------- damage

## Hurts an enemy. Returns true if it died.
func hurt_enemy(enemy: Enemy, amount: float, tech: String = "") -> bool:
	if enemy.dead or enemy.invulnerable or enemy.hidden or amount <= 0.0:
		return false
	var from_resonance := tech == "resonance"
	# Mawjig resonance: hits hex, and hexed enemies take more damage.
	if resonance["mawjig"] >= 1:
		if enemy.hex_marked:
			amount *= 1.3
		elif not from_resonance:
			enemy.hex_marked = true
	# A shielded elite's barrier soaks damage before its health does.
	if enemy.shield_hp > 0.0:
		var absorbed := minf(enemy.shield_hp, amount)
		enemy.shield_hp -= absorbed
		amount -= absorbed
		enemy.flash = 0.1
		if enemy.shield_hp <= 0.0:
			emit("shield_break", {"pos": enemy.pos})
		if amount <= 0.0:
			return false
	enemy.hp -= amount
	enemy.flash = 0.1
	run.damage_dealt += amount
	if enemy.state == 0 and enemy.brain == "mimic":
		enemy.state = 1
	if not from_resonance and resonance["energy"] >= 1:
		_energy_resonance_hit(enemy)
	if enemy.hp <= 0.0:
		kill_enemy(enemy, tech)
		return true
	return false


## Kinetic resonance II: two fragments fly on past the enemy the shot just hit.
func _splinter(shot: Shot) -> void:
	shot.splintered = true
	if player_shots.size() > 500:
		return
	for side in [-1.0, 1.0]:
		var fragment := player_shot(shot.pos, shot.vel.rotated(side * 0.45) * 0.9, shot.damage * 0.45, "splinter", "shard", Color(1, 0.85, 0.5))
		fragment.life = 0.45
		fragment.hit_ids = shot.hit_ids.duplicate()


## Energy resonance II (Capacitor Discharge): every hit you take, or a Shield Generator charge breaking, lets go
## in a lightning nova (GDD 13P), so it works for every build, shield or not.
func _capacitor_discharge() -> void:
	clear_bullets(player.pos, 200.0)
	var struck := {}
	for i in 6:
		var target := nearest_enemy(player.pos, 380.0, struck)
		if target == null:
			break
		struck[target.id] = true
		emit("lightning", {"from": player.pos, "to": target.pos})
		hurt_enemy(target, 40.0 + 10.0 * resonance["energy"], "resonance")
	emit("explosion", {"pos": player.pos, "size": 200.0, "color": Color(0.5, 0.9, 1.0), "ring": true})
	emit("sound", {"name": "laser"})


## Energy resonance: every few hits, lightning arcs from the struck enemy to another.
func _energy_resonance_hit(enemy: Enemy) -> void:
	run.hit_counter += 1
	var every := 2 if resonance["energy"] >= 3 else 4
	if run.hit_counter % every != 0:
		return
	var hit := {enemy.id: true}
	var from := enemy.pos
	for i in (2 if resonance["energy"] >= 3 else 1):
		var next := nearest_enemy(from, 230.0, hit)
		if next == null:
			break
		hit[next.id] = true
		emit("lightning", {"from": from, "to": next.pos})
		hurt_enemy(next, 18.0 + 5.0 * resonance["energy"], "resonance")
		from = next.pos


func kill_enemy(enemy: Enemy, tech: String = "") -> void:
	if enemy.dead:
		return
	enemy.dead = true
	run.kills += 1
	if enemy.boss == null:
		run.kills_by_kind[enemy.kind] = int(run.kills_by_kind.get(enemy.kind, 0)) + 1
	var size := enemy.radius * (2.4 if enemy.elite else 1.6)
	emit("explosion", {"pos": enemy.pos, "size": size, "color": enemy.color})
	emit("sound", {"name": "explode_big" if enemy.radius > 22 or enemy.elite else "explode"})
	if enemy.boss != null:
		enemy.boss.on_part_destroyed(self, enemy)
		return
	if enemy.elite:
		emit("elite_down", {"pos": enemy.pos, "color": enemy.color})
	# Data Shards: bigger enemies drop more.
	var shard_total := enemy.xp * xp_scale
	while shard_total > 0.0:
		var value := 3.0 if shard_total >= 6.0 else 1.0
		drop_pickup("shard", enemy.pos, minf(value, shard_total))
		shard_total -= value
	if enemy.drops_crate or (enemy.elite and rng.randf() < crate_chance * 1.4):
		drop_pickup("crate", enemy.pos)
	if enemy.elite and elite_blueprint_tech != "":
		drop_pickup("blueprint", enemy.pos, 1.0, elite_blueprint_tech)
	elif enemy.elite_mod != "" and reward_tech != "" and rng.randf() < 0.3:
		drop_pickup("blueprint", enemy.pos, 1.0, reward_tech)
	if enemy.elite_mod == "splitting":
		for side in [-1.0, 1.0]:
			var half := spawn_enemy(enemy.kind, enemy.pos + Vector2(side * 18.0, 0), {"elite": false})
			half.max_hp *= 0.6
			half.hp = half.max_hp
			half.memory["no_formation"] = true
			half.memory["awake"] = true
			half.vel = Vector2(side * 180.0, -40.0)
	var data := EnemyData.get_enemy(enemy.kind)
	if data.has("splits_into"):
		var pieces: int = data.get("split_count", 2)
		for i in pieces:
			var child := spawn_enemy(data["splits_into"], enemy.pos + Vector2.from_angle(TAU * i / pieces) * 16.0)
			child.memory["no_formation"] = true
			child.memory["awake"] = true
			child.vel = Vector2.from_angle(TAU * i / pieces) * 160.0
			child.room = enemy.room
	if tech != "resonance" and resonance["explosive"] >= 1 and rng.randf() < 0.34:
		explode(enemy.pos, 80.0, 26.0 + 6.0 * resonance["explosive"], "resonance", Color(1.0, 0.55, 0.25))
	if run.field_count("blood_pact") > 0:
		player.repair(1.5)
		player.since_kill = 0.0
	if run.is_online("soul_lantern"):
		wisps = mini(wisps + 1, max_wisps())
	# Hexplosion fork, or Mawjig resonance II: hexed enemies burst and spread the hex.
	if enemy.hex_marked and (run.fork_of("hex_repeater") == "a" or resonance["mawjig"] >= 2) and tech != "resonance":
		explode(enemy.pos, 95.0, 34.0 * run.damage_multiplier("hex_repeater", player.armor_fraction()), "hex_repeater", Color(0.85, 0.45, 1.0), true)
	# Mawjig Siphon: 1 Armor a kill per stack, at most 10 a stage per stack, so killing never replaces dodging.
	var siphon := run.field_count("mawjig_siphon")
	if siphon > 0 and siphoned_this_stage < 10.0 * siphon:
		player.repair(1.0)
		siphoned_this_stage += 1.0


## Soul Lantern's wisps: 1 + level of them (3 more with Lantern Ward), circling the frame.
func max_wisps() -> int:
	if not run.is_online("soul_lantern"):
		return 0
	return 1 + run.level_of("soul_lantern") + (3 if run.fork_of("soul_lantern") == "b" else 0)


func wisp_positions() -> Array:
	var positions := []
	for i in wisps:
		positions.append(player.pos + Vector2.from_angle(time * 2.6 + TAU * i / maxf(wisps, 1)) * 50.0)
	return positions


## Allies fly in formation beside you and fire your main weapon's bolts forward (GDD 11E's turned clone).
func update_allies(dt: float) -> void:
	for i in allies.size():
		var ally: Dictionary = allies[i]
		var side := -1.0 if i % 2 == 0 else 1.0
		var slot := player.pos + Vector2.from_angle(player.facing + PI * 0.5) * 70.0 * side - Vector2.from_angle(player.facing) * 20.0
		ally["pos"] = (ally["pos"] as Vector2).lerp(slot, minf(1.0, 6.0 * dt))
		ally["fire_timer"] = float(ally["fire_timer"]) - dt
		if ally["fire_timer"] <= 0.0:
			ally["fire_timer"] = 0.2
			var shot := player_shot(ally["pos"], Vector2.from_angle(player.facing) * 900.0, 7.0 + 1.5 * run.level_of(run.main_weapon()),
				"ally", "bolt", Color(0.8, 0.6, 1.0))
			shot.life = 1.1


## A player explosion that damages every enemy in range once.
func explode(at: Vector2, radius: float, damage: float, tech: String, color: Color, spreads_hex: bool = false) -> void:
	# Explosive resonance III (Wildfire): blasts leave flames burning.
	if resonance["explosive"] >= 3 and radius >= 40.0 and zones.size() < 40:
		add_zone("fire", at, radius * 0.6, 1.6, 6.0, false, {"tick": 0.4, "color": Color(1, 0.5, 0.2)})
	emit("explosion", {"pos": at, "size": radius, "color": color, "ring": true})
	for enemy: Enemy in enemies.duplicate():
		if enemy.dead or enemy.hidden:
			continue
		if at.distance_to(enemy.pos) < radius + enemy.radius:
			if spreads_hex:
				enemy.hex_marked = true
			var killed := hurt_enemy(enemy, damage, tech)
			# Explosive resonance II (Chain Reaction): what a blast kills goes off a moment later.
			if killed and resonance["explosive"] >= 2 and _chain_generation < CHAIN_REACTION_GENERATIONS:
				chain_blasts.append({"pos": enemy.pos, "delay": CHAIN_REACTION_DELAY, "generation": _chain_generation + 1})


## Chain Reaction's queued blasts go off one beat after the kill that set them, so the cascade ripples outward.
func update_chain_blasts(dt: float) -> void:
	var due := []
	for blast: Dictionary in chain_blasts:
		blast["delay"] = float(blast["delay"]) - dt
		if blast["delay"] <= 0.0:
			due.append(blast)
	for blast: Dictionary in due:
		chain_blasts.erase(blast)
		_chain_generation = blast["generation"]
		explode(blast["pos"], 64.0, 20.0 + 8.0 * resonance["explosive"], "resonance", Color(1.0, 0.6, 0.3))
		_chain_generation = 0
	if not due.is_empty():
		emit("sound", {"name": "explode"})


## Removes enemy bullets inside a circle; returns how many.
func clear_bullets(at: Vector2, radius: float) -> int:
	var cleared := 0
	for shot: Shot in enemy_shots:
		if not shot.dead and at.distance_to(shot.pos) < radius:
			shot.dead = true
			cleared += 1
			if cleared % 3 == 0:
				emit("spark", {"pos": shot.pos, "color": shot.color})
	return cleared


## Turns an enemy bullet into a player bullet heading back the way it came, or at the nearest enemy.
func reflect_shot(shot: Shot, damage: float, homing: bool, splits: int) -> void:
	shot.dead = true
	var target := nearest_enemy(shot.pos, 700.0)
	var direction := -shot.vel.normalized()
	if target != null:
		direction = (target.pos - shot.pos).normalized()
	var speed := maxf(shot.vel.length() * 1.6, 520.0)
	var count := maxi(1, splits)
	for i in count:
		var angle := direction.angle() + (0.0 if count == 1 else lerpf(-0.35, 0.35, float(i) / float(count - 1)))
		var reflected := player_shot(shot.pos, Vector2.from_angle(angle) * speed, damage, "mirror_aegis", "reflect", Color(0.7, 1.0, 1.0))
		reflected.radius = 6.0
		reflected.life = 1.6
		if homing:
			reflected.homing = 6.0
	emit("spark", {"pos": shot.pos, "color": Color(0.7, 1.0, 1.0)})


## Seconds a Shield Generator charge takes to come back: 12 at level 1, one less each level (GDD 13K).
func shield_recharge_seconds() -> float:
	return 13.0 - maxi(run.level_of("shield_generator"), 1)


## Sets max Armor to the frame's plus what the plating adds now, keeping the damage already taken.
func refresh_plate_armor() -> void:
	var bonus := run.plate_armor()
	var gained := bonus - _plate_armor_applied
	player.max_armor += gained
	player.armor = clampf(player.armor + maxf(gained, 0.0), 0.0, player.max_armor)
	_plate_armor_applied = bonus


## Every hit on the player goes through here: the Shield Generator, plating, Lantern Ward, Resonance, field
## upgrades and the tally.
func damage_player(amount: float, source: String) -> void:
	if not player.alive or player.grace > 0.0 or amount <= 0.0:
		return
	# A Shield Generator charge takes the whole hit, whatever its size (GDD 13K).
	if player.shield_charges > 0:
		player.block_with_shield(shield_recharge_seconds())
		emit("player_shield_break", {"pos": player.pos})
		emit("sound", {"name": "shield_break"})
		if run.fork_of("shield_generator") == "b":
			# Breaker Pulse: the breaking bubble blasts the bullets around you away.
			clear_bullets(player.pos, 230.0)
			emit("explosion", {"pos": player.pos, "size": 230.0, "color": Color(0.5, 0.85, 1.0), "ring": true})
		if resonance["energy"] >= 2:
			_capacitor_discharge()
		return
	# DSP-1 Spaced Armor: a big hit loses some of its punch in the gap between the plates.
	if run.plating() == "dsp1_plate" and run.fork_of("dsp1_plate") == "a" and amount >= FrameData.HEAVY_HIT:
		amount -= 5.0
	# Lantern Ward: a wisp throws itself in front of the hit and takes half of it.
	if run.fork_of("soul_lantern") == "b" and wisps > 0:
		wisps -= 1
		amount *= 0.5
		emit("spark", {"pos": player.pos, "color": Color(0.85, 0.6, 1.0)})
	var taken := player.take_hit(amount)
	if taken <= 0.0:
		return
	if resonance["energy"] >= 2:
		_capacitor_discharge()
	run.damage_taken += taken
	run.hits_taken += 1
	emit("player_hit", {"pos": player.pos, "amount": taken, "source": source})
	emit("sound", {"name": "player_hit"})
	emit("shake", {"amount": 7.0 + taken * 0.25})
	var shrapnel := run.field_count("shrapnel_skin")
	if shrapnel > 0:
		for i in 10 * shrapnel:
			var shot := player_shot(player.pos, Vector2.from_angle(TAU * i / (10.0 * shrapnel)) * 620.0, 14.0, "shrapnel", "shard", Color(1, 0.8, 0.5))
			shot.life = 0.7
	if on_player_hurt.is_valid():
		on_player_hurt.call(taken, source)


# ---------------------------------------------------------------- per-tick updates

func update_player_shots(dt: float) -> void:
	for shot: Shot in player_shots:
		if shot.dead:
			continue
		shot.age += dt
		shot.life -= dt
		if shot.life <= 0.0:
			shot.dead = true
			if shot.splash > 0.0:
				_on_shot_impact(shot, null)
			continue
		if shot.homing > 0.0:
			_steer_shot(shot, dt)
		if shot.accel > 0.0:
			shot.vel = shot.vel.normalized() * minf(shot.vel.length() + shot.accel * dt, shot.max_speed)
		if shot.devours:
			# Event Horizon: each hex orb is a small black hole. It drags in bullets (and eats them) and
			# smaller enemies, then collapses in a burst that hexes everything around it.
			for enemy_bullet in enemy_shots:
				if not enemy_bullet.dead and shot.pos.distance_to(enemy_bullet.pos) < 90.0:
					enemy_bullet.vel = enemy_bullet.vel.lerp((shot.pos - enemy_bullet.pos) * 4.0, 0.2)
					if shot.pos.distance_to(enemy_bullet.pos) < 16.0:
						enemy_bullet.dead = true
			for enemy: Enemy in enemies:
				if not enemy.dead and enemy.boss == null and not enemy.elite and shot.pos.distance_to(enemy.pos) < 110.0:
					enemy.pos = enemy.pos.move_toward(shot.pos, 140.0 * dt)
			if shot.life <= 0.2:
				_collapse_horizon(shot)
		shot.pos += shot.vel * dt
		if shot.split_after > 0.0 and shot.age >= shot.split_after:
			_split_shot(shot)
			continue
		if not walls.is_empty() and point_in_wall(shot.pos):
			shot.dead = true
			if shot.splash > 0.0:
				_on_shot_impact(shot, null)
			else:
				emit("spark", {"pos": shot.pos, "color": shot.color})
			continue
		if not shot_bounds.has_point(shot.pos):
			shot.dead = true
			continue
		for enemy: Enemy in enemies:
			if enemy.dead or enemy.hidden or shot.hit_ids.has(enemy.id):
				continue
			var reach := enemy.radius + shot.radius
			if shot.pos.distance_squared_to(enemy.pos) > reach * reach:
				continue
			# Mirrored hulls throw straight shots back; homing shots curve around them.
			# Homing shots get round a mirrored elite's mirror and hit it (the Guide says so); against the Mirror
			# Dreadnought they curve past its mirrored hull to reach the vents on its back (GDD 9C).
			if enemy.reflects and not (shot.homing > 0.0 and enemy.boss == null):
				if shot.homing > 0.0:
					continue
				shot.dead = true
				# A mirrored elite's mirror cracks after enough hits, so no build is ever locked out by one.
				if enemy.boss == null:
					enemy.memory["mirror_hits"] = int(enemy.memory.get("mirror_hits", 0)) + 1
					if enemy.memory["mirror_hits"] >= MIRROR_ELITE_HITS:
						enemy.reflects = false
						enemy.elite_mod = "cracked"
						emit("shield_break", {"pos": enemy.pos})
						emit("sound", {"name": "shatter"})
				# A mirrored elite throws back at most one shot every 0.4 s; the rest just glance off.
				var ready := enemy.boss != null or time - float(enemy.memory.get("last_reflect", -9.0)) > 0.4
				if ready:
					enemy.memory["last_reflect"] = time
					enemy_shot(shot.pos, (player.pos - shot.pos).angle() + rng.randf_range(-0.2, 0.2), 320.0,
						{"damage": MissionData.HIT_CHIP, "radius": 5.0, "color": Color(1.0, 0.55, 0.85)})
				emit("spark", {"pos": shot.pos, "color": Color(0.85, 0.95, 1.0), "blocked": true})
				break
			if enemy.front_shield and _hits_front(enemy, shot) and shot.splash <= 0.0:
				shot.dead = true
				emit("spark", {"pos": shot.pos, "color": Color(0.6, 0.8, 1.0), "blocked": true})
				emit("sound", {"name": "block"})
				break
			if enemy.invulnerable:
				shot.dead = true
				emit("spark", {"pos": shot.pos, "color": Color(0.8, 0.8, 0.8), "blocked": true})
				break
			shot.hit_ids[enemy.id] = true
			hurt_enemy(enemy, shot.damage, shot.tech)
			# Kinetic resonance II (Splinter Rounds): a shot that has flown a while bursts on its first hit.
			if resonance["kinetic"] >= 2 and shot.age > 0.3 and not shot.splintered and shot.tech != "splinter":
				_splinter(shot)
			_on_shot_impact(shot, enemy)
			if shot.chains > 0 and enemy.dead:
				_chain_bolt(enemy, shot.damage, shot.chains)
			if shot.pierce > 0:
				shot.pierce -= 1
			else:
				shot.dead = true
			break
	player_shots = player_shots.filter(func(s): return not s.dead)


func _hits_front(enemy: Enemy, shot: Shot) -> bool:
	var incoming := (shot.pos - enemy.pos).angle()
	return absf(angle_difference(enemy.facing, incoming)) < deg_to_rad(70.0)


func _steer_shot(shot: Shot, dt: float) -> void:
	var target := enemy_by_id(shot.target_id) if shot.target_id >= 0 else null
	if target == null:
		if shot.target_id >= 0 and not shot.retarget:
			return
		target = nearest_enemy(shot.pos, 650.0)
		shot.target_id = target.id if target != null else -1
	if target == null:
		return
	var desired := (target.pos - shot.pos).angle()
	var current := shot.vel.angle()
	var turn := clampf(angle_difference(current, desired), -shot.homing * dt, shot.homing * dt)
	shot.vel = Vector2.from_angle(current + turn) * shot.vel.length()


func _split_shot(shot: Shot) -> void:
	shot.dead = true
	var count := shot.split_count
	var base := shot.vel.angle()
	for i in count:
		var angle := base + lerpf(-0.42, 0.42, float(i) / float(maxi(count - 1, 1)))
		var child := player_shot(shot.pos, Vector2.from_angle(angle) * shot.vel.length(), shot.damage * 0.62, shot.tech, "bolt", shot.color)
		child.radius = shot.radius * 0.8
		child.life = 0.9
	emit("spark", {"pos": shot.pos, "color": shot.color})


## Chain Bolts (GDD 13W): a kill arcs as lightning to the next enemy in reach, a little weaker each jump, and
## carries on only while it keeps killing, so a good shot through a crowd clears it in a crackling chain.
func _chain_bolt(from: Enemy, damage: float, jumps: int) -> void:
	var struck := {from.id: true}
	var at := from.pos
	for jump in jumps:
		var next := nearest_enemy(at, CHAIN_RANGE, struck)
		if next == null:
			return
		damage *= CHAIN_KEEPS
		struck[next.id] = true
		emit("lightning", {"from": at, "to": next.pos})
		hurt_enemy(next, damage, "pulse_driver")
		if not next.dead:
			return
		at = next.pos

func _collapse_horizon(shot: Shot) -> void:
	shot.devours = false
	shot.dead = true
	explode(shot.pos, 100.0, shot.damage * 1.5, "hex_repeater", Color(0.6, 0.3, 1.0), true)
	emit("sound", {"name": "black_hole"})


## On-hit effects carried by the shot: splash, cluster bomblets, chain lightning, hexes, meteors.
func _on_shot_impact(shot: Shot, enemy: Enemy) -> void:
	if shot.devours:
		_collapse_horizon(shot)
		return
	if shot.splash > 0.0:
		explode(shot.pos, shot.splash, shot.damage * 0.6, shot.tech, shot.color)
		emit("sound", {"name": "explode"})
		for i in shot.bomblets:
			var bomblet := player_shot(shot.pos, Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(160, 260), shot.damage * 0.4, shot.tech, "bomblet", shot.color)
			bomblet.life = rng.randf_range(0.25, 0.45)
			bomblet.splash = shot.splash * 0.6
			bomblet.radius = 4.0
		if shot.calls_meteor and rng.randf() < 0.3:
			call_meteor(shot.pos + Vector2(rng.randf_range(-40, 40), rng.randf_range(-40, 40)), 70.0, shot.damage * 1.5, false)
	if enemy == null:
		return
	if shot.hex_mark:
		enemy.hex_marked = true
	if shot.hex_shatter:
		shot.hex_shatter = false
		for i in 3:
			var hunter := player_shot(shot.pos, Vector2.from_angle(rng.randf() * TAU) * 420.0, shot.damage * 0.4, shot.tech, "orb_small", shot.color)
			hunter.homing = 7.0
			hunter.radius = 4.0
			hunter.life = 1.4
			hunter.hit_ids = shot.hit_ids.duplicate()
	if shot.chain_arcs > 0:
		var hit := {enemy.id: true}
		var from := enemy.pos
		for i in shot.chain_arcs:
			var next := nearest_enemy(from, 220.0, hit)
			if next == null:
				break
			hit[next.id] = true
			emit("lightning", {"from": from, "to": next.pos})
			hurt_enemy(next, shot.damage * 0.5, shot.tech)
			from = next.pos


## Starfall meteors and their relatives: a warning circle, then an impact.
func call_meteor(at: Vector2, radius: float, damage: float, burning: bool) -> void:
	var zone := add_zone("meteor", at, radius, 0.55, damage, false, {"warn": 0.5, "color": Color(0.85, 0.5, 1.0)})
	zone.hit_ids = {"burning": burning}


func update_enemy_shots(dt: float) -> void:
	var slow := enemy_time_scale()
	var graze_online := run.is_online("graze_engine") or run.field_count("adrenaline_junkie") > 0
	var mirror_up := player.mirror_time > 0.0
	var bastion := run.fork_of("mirror_aegis") == "b" and run.is_online("mirror_aegis")
	var wisp_spots: Array = wisp_positions()
	for shot: Shot in enemy_shots:
		if shot.dead:
			continue
		if slow < 1.0:
			shot.slowed = true
		shot.life -= dt * slow
		if shot.life <= 0.0:
			shot.dead = true
			if shot.look == "mine":
				enemy_ring(shot.pos, 8, 160.0, rng.randf() * TAU, {"color": Color(1, 0.55, 0.3)})
				emit("explosion", {"pos": shot.pos, "size": 22.0, "color": Color(1, 0.55, 0.3)})
			continue
		if shot.homing > 0.0 and player.alive:
			# Homing enemy shots (needles) turn gently toward the frame.
			var turn := clampf(angle_difference(shot.vel.angle(), (player.pos - shot.pos).angle()), -shot.homing * dt * slow, shot.homing * dt * slow)
			shot.vel = shot.vel.rotated(turn)
		if shot.accel != 0.0:
			var speed := clampf(shot.vel.length() + shot.accel * dt * slow, 20.0, maxf(shot.max_speed, 20.0))
			shot.vel = shot.vel.normalized() * speed
		shot.pos += shot.vel * dt * slow
		if not shot_bounds.has_point(shot.pos) or (not walls.is_empty() and point_in_wall(shot.pos)):
			shot.dead = true
			continue
		if not player.alive:
			continue
		var distance := shot.pos.distance_to(player.pos)
		# Soul Lantern: a wisp swallows the bullet and is spent.
		if wisps > 0 and distance < 80.0:
			var swallowed := false
			for spot: Vector2 in wisp_spots:
				if shot.pos.distance_to(spot) < 14.0 + shot.radius:
					swallowed = true
					break
			if swallowed:
				shot.dead = true
				wisps -= 1
				wisp_spots = wisp_positions()
				emit("spark", {"pos": shot.pos, "color": Color(0.85, 0.6, 1.0)})
				continue
		if mirror_up and distance < MIRROR_RADIUS:
			_mirror_reflect(shot)
			continue
		if bastion and distance < 60.0 and absf(angle_difference(player.facing, (shot.pos - player.pos).angle())) < deg_to_rad(62.0):
			_mirror_reflect(shot)
			continue
		if distance < player.radius + shot.radius:
			# Bulwark's Fortress Field: its armoured front throws back a quarter of what hits it.
			if FrameData.get_frame(run.frame_id)["trait"] == "fortress_field" \
					and absf(angle_difference(player.facing, (shot.pos - player.pos).angle())) < FrameData.FORTRESS_FRONT and rng.randf() < 0.25:
				reflect_shot(shot, 18.0, false, 1)
				continue
			shot.dead = true
			damage_player(shot.damage, "bullet")
			continue
		if graze_online and not shot.grazed and distance < player.radius + shot.radius + GRAZE_MARGIN:
			shot.grazed = true
			if on_collect.is_valid():
				on_collect.call("graze", 1.0, "")
	enemy_shots = enemy_shots.filter(func(s): return not s.dead)


func _mirror_reflect(shot: Shot) -> void:
	var level := run.level_of("mirror_aegis")
	var damage := 16.0 * (1.0 + 0.2 * (level - 1)) * run.damage_multiplier("mirror_aegis", player.armor_fraction())
	reflect_shot(shot, damage, run.has_fusion("reflex_blade"), 3 if run.fork_of("mirror_aegis") == "a" else 1)


## How far away drops start flying to you on their own (the frame's own pull).
func base_pickup_reach() -> float:
	return PICKUP_RADIUS * (1.7 if player.form == "ship" else 1.0)


## Tractor Beam reaches a bit further than that, semi-nearby rather than across the screen (GDD 11D).
func pickup_reach() -> float:
	var extra: float = [0.0, 160.0, 260.0][mini(run.field_count("tractor_beam"), 2)]
	return base_pickup_reach() + extra


func update_pickups(dt: float) -> void:
	var reach := pickup_reach()
	var own_reach := base_pickup_reach()
	# Tractor Beam holds at most a few beams at once; other drops wait their turn (no screen of beams).
	var beams := 0
	for pickup: Pickup in pickups:
		if pickup.magnetized and not pickup.dead and pickup.pos.distance_to(player.pos) > own_reach:
			beams += 1
	for pickup: Pickup in pickups:
		if pickup.dead:
			continue
		pickup.age += dt
		if not pickup.anchored:
			pickup.life -= dt
		if pickup.life <= 0.0:
			pickup.dead = true
			if pickup.kind == "shard":
				run.shards_missed += 1
			continue
		var to_player := player.pos - pickup.pos
		var distance := to_player.length()
		# The boss's prize waits a moment to be admired, then drifts to you so you never have to hunt for it.
		if pickup.kind == "prize" and pickup.age > PRIZE_DRIFT_DELAY:
			pickup.anchored = false
			pickup.magnetized = true
		var pull := pickup.magnetized or distance < own_reach or (distance < reach and beams < TRACTOR_BEAMS)
		if not pickup.anchored and pickup.age > 0.35 and pull:
			if not pickup.magnetized and distance >= own_reach:
				beams += 1
			pickup.magnetized = true
			pickup.vel = to_player.normalized() * maxf(pickup.vel.length() + 1600.0 * dt, 280.0)
		else:
			pickup.vel *= 0.92
			# Shooter trope: drops drift down the screen toward the ship.
			if player.form == "ship" and not pickup.anchored:
				pickup.vel.y = maxf(pickup.vel.y, 110.0)
		pickup.pos += pickup.vel * dt
		if not walls.is_empty():
			pickup.pos = push_out_of_walls(pickup.pos, 6.0) if not pickup.magnetized else pickup.pos
		if distance < player.radius + 16.0:
			pickup.dead = true
			if on_collect.is_valid():
				on_collect.call(pickup.kind, pickup.value, pickup.tech)
	pickups = pickups.filter(func(p): return not p.dead)


func update_zones(dt: float) -> void:
	var slow := enemy_time_scale()
	for zone: Zone in zones:
		if zone.dead:
			continue
		var zone_dt := dt * (slow if zone.hostile else 1.0)
		if zone.warn > 0.0:
			zone.warn -= zone_dt
			if zone.warn <= 0.0:
				_zone_triggers(zone)
			continue
		zone.life -= zone_dt
		if zone.life <= 0.0:
			zone.dead = true
			continue
		zone.angle += zone.spin * zone_dt
		match zone.kind:
			"black_hole":
				for enemy: Enemy in enemies:
					if not enemy.dead and not enemy.hidden and enemy.boss == null and enemy.pos.distance_to(zone.pos) < zone.radius:
						enemy.pos = enemy.pos.lerp(zone.pos, 0.06)
				clear_bullets(zone.pos, zone.radius * 0.6)
			"ring":
				var current_radius := zone.radius * (1.0 - zone.life / zone.max_life)
				for enemy: Enemy in enemies.duplicate():
					if enemy.dead or zone.hit_ids.has(enemy.id):
						continue
					if absf(enemy.pos.distance_to(zone.pos) - current_radius) < 26.0 + enemy.radius:
						zone.hit_ids[enemy.id] = true
						hurt_enemy(enemy, zone.damage, "ring")
				if zone.clears_bullets:
					for shot: Shot in enemy_shots:
						if absf(shot.pos.distance_to(zone.pos) - current_radius) < 22.0:
							shot.dead = true
			"enemy_ring":
				var ring_radius := zone.radius * (1.0 - zone.life / zone.max_life)
				if not zone.hit_ids.has("player") and absf(player.pos.distance_to(zone.pos) - ring_radius) < 18.0 + player.radius:
					zone.hit_ids["player"] = true
					damage_player(zone.damage, "shockwave")
			"laser":
				# A beam hits once per pass: you pay for being caught, not for every frame inside it.
				if zone.hostile and not zone.hit_ids.has("player") and _point_near_beam(player.pos, zone, player.radius):
					zone.hit_ids["player"] = true
					damage_player(zone.damage, "laser")
			_:
				zone.tick_timer -= zone_dt
				if zone.tick_timer <= 0.0:
					zone.tick_timer = zone.tick
					if zone.hostile:
						if player.pos.distance_to(zone.pos) < zone.radius + player.radius * 0.5:
							damage_player(zone.damage, zone.kind)
					else:
						for enemy: Enemy in enemies.duplicate():
							if not enemy.dead and enemy.pos.distance_to(zone.pos) < zone.radius + enemy.radius:
								hurt_enemy(enemy, zone.damage, zone.kind)
	zones = zones.filter(func(z): return not z.dead)


func _point_near_beam(point: Vector2, zone: Zone, extra: float) -> bool:
	var end := zone.pos + Vector2.from_angle(zone.angle) * zone.length
	var closest := Geometry2D.get_closest_point_to_segment(point, zone.pos, end)
	return point.distance_to(closest) < zone.width * 0.5 + extra


## A telegraphed zone has finished warning and goes off.
func _zone_triggers(zone: Zone) -> void:
	match zone.kind:
		"meteor":
			zone.dead = true
			explode(zone.pos, zone.radius, zone.damage, "starfall", Color(0.85, 0.5, 1.0))
			emit("shake", {"amount": 5.0})
			emit("sound", {"name": "meteor"})
			if zone.hit_ids.get("burning", false):
				# Comet Trail: the meteor leaves a flaming streak along the path it came in on.
				for i in 4:
					var along := zone.pos + METEOR_FROM * zone.radius * 0.7 * i
					add_zone("fire", along, zone.radius * (0.55 - 0.08 * i), 2.5, zone.damage * 0.14, false, {"tick": 0.4, "color": Color(1, 0.5, 0.9)})
			if run.has_fusion("armageddon_protocol"):
				for i in 3:
					var missile := player_shot(zone.pos, Vector2.from_angle(rng.randf() * TAU) * 260.0, zone.damage * 0.4, "swarm_pods", "missile", Color(1, 0.6, 0.3))
					missile.homing = 6.0
					missile.splash = 45.0
					missile.accel = 500.0
					missile.max_speed = 620.0
					missile.life = 2.0
		"bomb_warning":
			zone.dead = true
			emit("explosion", {"pos": zone.pos, "size": zone.radius, "color": Color(1, 0.45, 0.3), "ring": true})
			emit("sound", {"name": "explode"})
			if player.pos.distance_to(zone.pos) < zone.radius + player.radius * 0.6:
				damage_player(zone.damage, "blast")
		"acid_warning":
			zone.dead = true
			add_zone("acid", zone.pos, zone.radius, 3.5, zone.damage, true, {"tick": 0.45, "color": Color(0.5, 1.0, 0.4)})
			emit("sound", {"name": "splat"})
		"laser":
			emit("sound", {"name": "laser"})
		_:
			pass


## Arc Blade sweeps: damage enemies in the swept wedge and cut bullets out of the air.
func update_blades(dt: float) -> void:
	for blade in blades:
		var previous: float = blade["angle"]
		blade["time"] += dt
		var progress := clampf(blade["time"] / blade["duration"], 0.0, 1.0)
		blade["angle"] = lerpf(blade["start"], blade["end"], ease(progress, 0.6))
		var low := minf(previous, blade["angle"]) - 0.05
		var high := maxf(previous, blade["angle"]) + 0.05
		var center := player.pos
		for enemy: Enemy in enemies.duplicate():
			if enemy.dead or enemy.hidden or blade["hit"].has(enemy.id):
				continue
			var offset := enemy.pos - center
			if offset.length() > blade["radius"] + enemy.radius:
				continue
			if _angle_in_sweep(offset.angle(), low, high):
				blade["hit"][enemy.id] = true
				hurt_enemy(enemy, blade["damage"], "arc_blade")
				emit("slash_hit", {"pos": enemy.pos})
		for shot: Shot in enemy_shots:
			if shot.dead:
				continue
			var offset := shot.pos - center
			if offset.length() < blade["radius"] + 8.0 and _angle_in_sweep(offset.angle(), low, high):
				if blade["reflect"]:
					reflect_shot(shot, blade["damage"] * 0.4, true, 1)
					# Reflex Blade: every bullet the blade catches feeds the Graze Engine too.
					if run.has_fusion("reflex_blade") and on_collect.is_valid():
						on_collect.call("graze", 1.0, "")
				else:
					shot.dead = true
					emit("spark", {"pos": shot.pos, "color": Color(0.6, 1.0, 1.0)})
		if progress >= 1.0:
			blade["done"] = true
			if blade["phantom"]:
				var wave := player_shot(center, Vector2.from_angle(player.facing) * 640.0, blade["damage"] * 0.7, "arc_blade", "crescent", Color(0.6, 1.0, 1.0))
				wave.radius = 30.0
				wave.pierce = 99
				wave.life = 1.1
	blades = blades.filter(func(b): return not b.get("done", false))


func _angle_in_sweep(angle: float, low: float, high: float) -> bool:
	# Shift the angle into the turn that starts at `low`, then check it's before `high`.
	return low + fposmod(angle - low, TAU) <= high


func cleanup() -> void:
	enemies = enemies.filter(func(e): return not e.dead)
