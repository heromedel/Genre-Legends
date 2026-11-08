class_name PlayerFrame
extends RefCounted
## The player's frame inside a mission: where it is, which form it's in, its armor and shield,
## and the meters its support tech fills. How it moves and how it takes hits live here;
## what it fires lives in WeaponSystem.

const SHIP_RADIUS := 12.0
const MECH_RADIUS := 15.0
## Ship form follows the finger, but no faster than this, so it can't teleport through bullets.
const SHIP_MAX_DRAG_PER_TICK := 30.0

var frame_id := "vanguard"
var form := "ship"              # ship or mech; matches the stage (GDD 5E)
var pos := Vector2.ZERO
var vel := Vector2.ZERO
var facing := -PI * 0.5         # aim angle in radians
var radius := SHIP_RADIUS
var speed := 300.0

var armor := 100.0
var max_armor := 100.0
var shield := 40.0
var max_shield := 40.0
var shield_delay := 0.0         # seconds until the shield starts recharging
var grace := 0.0                # seconds of hit immunity left
var alive := true
var second_wind_used := false

# Support tech meters
var graze := 0.0
var overdrive := 0.0            # seconds of Overdrive left
var heat := 0.0
var mirror_time := 0.0          # seconds of Mirror Aegis bubble left
var special_cooldown := 0.0
var special_charges := 1
var time_brake := 0.0           # seconds of Time Brake left
var echo_counter := 0
var afterimages: Array = []     # recent positions: the Tempest's afterimage, Option Pods' trail, the trail art
var dash_time := 0.0            # Thruster Explosion: seconds of dash left
var dash_dir := Vector2.ZERO
var ion_time := 0.0             # Ion Cannon: seconds of beam left

## Thruster Explosion's dash speed, in units per second.
const DASH_SPEED := 1500.0
## How many recent positions the trail keeps (Option Pods ride it, up to 36 ticks back).
const TRAIL_LENGTH := 40


func setup(frame: String, stage_form: String) -> void:
	frame_id = frame
	var data := FrameData.get_frame(frame)
	max_armor = data["armor"]
	armor = max_armor
	max_shield = data["shield"]
	shield = max_shield
	speed = data["speed"]
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


## Recharges the shield after a quiet spell and counts down timers.
func tick_timers(dt: float, shield_regen_multiplier: float) -> void:
	grace = maxf(grace - dt, 0.0)
	overdrive = maxf(overdrive - dt, 0.0)
	mirror_time = maxf(mirror_time - dt, 0.0)
	time_brake = maxf(time_brake - dt, 0.0)
	ion_time = maxf(ion_time - dt, 0.0)
	if shield_delay > 0.0:
		shield_delay -= dt
	elif shield < max_shield:
		shield = minf(max_shield, shield + FrameData.SHIELD_REGEN_PER_SECOND * shield_regen_multiplier * dt)


## Applies a hit. Shield soaks first, then armor. Returns the damage actually taken.
## Loss is by attrition (Game Design Philosophy): a short grace window follows every hit.
func take_hit(amount: float) -> float:
	if not alive or grace > 0.0 or amount <= 0.0:
		return 0.0
	var taken := amount
	shield_delay = FrameData.SHIELD_DELAY
	grace = FrameData.HIT_GRACE
	var soaked := minf(shield, amount)
	shield -= soaked
	armor -= amount - soaked
	if armor <= 0.0:
		armor = 0.0
		alive = false
	return taken


func repair(amount: float) -> void:
	armor = minf(max_armor, armor + amount)
