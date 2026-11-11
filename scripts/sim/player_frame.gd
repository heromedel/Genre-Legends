class_name PlayerFrame
extends RefCounted
## The player's frame inside a mission: where it is, which form it's in, its Armor (one pool, read as hits,
## GDD 13A) and the Shield Generator's charges, and the meters its support tech fills. How it moves and how it takes hits live here;
## what it fires lives in WeaponSystem.

## Hitboxes are smaller than the art (GDD 13F): with a six-hit budget, a shot that clips a wingtip should miss.
const SHIP_RADIUS := 8.0
const MECH_RADIUS := 10.0
## Ship form follows the finger, but no faster than this, so it can't teleport through bullets.
const SHIP_MAX_DRAG_PER_TICK := 30.0

var frame_id := "vanguard"
var form := "ship"              # ship or mech; matches the stage (GDD 5E)
var pos := Vector2.ZERO
var vel := Vector2.ZERO
var facing := -PI * 0.5         # aim angle in radians
var radius := SHIP_RADIUS
var speed := 300.0

var armor := 80.0
var max_armor := 80.0
var shield_charges := 0         # Shield Generator: hits it will block before it needs to recharge (GDD 13K)
var max_shield_charges := 0
var shield_recharge := 0.0      # seconds until the next charge comes back
var grace := 0.0                # seconds of hit immunity left
var alive := true

# Support tech meters
var graze := 0.0
var overdrive := 0.0            # seconds of Overdrive left
var heat := 0.0                 # frame heat, 0 to 100 (GDD 21D): overclocking and the Overheat Core raise it
var heavy_hit := FrameData.HEAVY_HIT   # a big hit, two cells or more; Mission sets it from the planet's plain bullet
var vent_trip := 0.0            # seconds the powered parts stay offline after an overclocked vent
# Plates (GDD 21H)
var weave_cooldown := 0.0       # Jig-Weave Composite: seconds until it can shrug off another light hit
var phase_held := 0.0           # Jig Phase Plate: Armor held off from the last hit, fading when phase_time runs out
var phase_time := 0.0
var hardened := 0.0             # Lunarium Bulk Plate: max Armor gained by work-hardening this mission
var mirror_time := 0.0          # seconds of Mirror Aegis bubble left
var special_cooldown := 0.0
var special_charges := 1
var time_brake := 0.0           # seconds of Time Brake left
var echo_counter := 0
var afterimages: Array = []     # recent positions: the Tempest's afterimage, Drone Pods' trail, the trail art
var dash_time := 0.0            # Thruster Explosion: seconds of dash left
var dash_dir := Vector2.ZERO
var since_kill := 0.0           # Blood Pact: seconds since the last kill
var ion_time := 0.0             # Ion Cannon: seconds of beam left

## Thruster Explosion's dash speed, in units per second.
const DASH_SPEED := 1500.0
## How many recent positions the trail keeps (Drone Pods ride it, up to 36 ticks back).
const TRAIL_LENGTH := 40


func setup(frame: String, stage_form: String, stats: Dictionary) -> void:
	frame_id = frame
	max_armor = stats["armor"]
	armor = max_armor
	speed = stats["speed"]
	set_form(stage_form)


func set_form(stage_form: String) -> void:
	form = stage_form
	radius = SHIP_RADIUS if form == "ship" else MECH_RADIUS
	facing = -PI * 0.5


func armor_fraction() -> float:
	return armor / max_armor


## Moves the frame for one tick. Ship form follows finger drags; mech form walks with the stick.
func move(input: InputFrame, dt: float, speed_multiplier: float) -> void:
	var move_speed := speed * speed_multiplier
	if dash_time > 0.0:
		# Thruster Explosion: the dash carries you, whatever the stick says.
		dash_time -= dt
		vel = dash_dir * DASH_SPEED
		pos += vel * dt
	elif form == "ship":
		var drag := input.drag.limit_length(SHIP_MAX_DRAG_PER_TICK * speed_multiplier)
		vel = drag / dt + input.move * move_speed * 1.25
		pos += drag + input.move * move_speed * 1.25 * dt
	else:
		var target := input.move * move_speed
		vel = vel.lerp(target, clampf(dt * 14.0, 0.0, 1.0))
		pos += vel * dt
	afterimages.push_front(pos)
	if afterimages.size() > TRAIL_LENGTH:
		afterimages.pop_back()


## Counts down timers.
func tick_timers(dt: float) -> void:
	grace = maxf(grace - dt, 0.0)
	overdrive = maxf(overdrive - dt, 0.0)
	mirror_time = maxf(mirror_time - dt, 0.0)
	time_brake = maxf(time_brake - dt, 0.0)
	ion_time = maxf(ion_time - dt, 0.0)
	weave_cooldown = maxf(weave_cooldown - dt, 0.0)
	if phase_time > 0.0:
		phase_time -= dt
		if phase_time <= 0.0:
			phase_held = 0.0


## Applies a hit to Armor and returns the damage taken. Loss is by attrition (Game Design Philosophy): a
## window of immunity follows every hit, longer after a big one, so one bad volley costs one hit (GDD 13E).
func take_hit(amount: float) -> float:
	if not alive or grace > 0.0 or amount <= 0.0:
		return 0.0
	grace = FrameData.HEAVY_HIT_GRACE if amount >= heavy_hit else FrameData.HIT_GRACE
	armor -= amount
	if armor <= 0.0:
		armor = 0.0
		alive = false
	return amount


## The Shield Generator takes the hit instead: one charge gone, a moment of immunity, and the recharge starts.
func block_with_shield(recharge_seconds: float) -> void:
	shield_charges -= 1
	grace = FrameData.HIT_GRACE
	if shield_recharge <= 0.0:
		shield_recharge = recharge_seconds


func repair(amount: float) -> void:
	armor = minf(max_armor, armor + amount)
