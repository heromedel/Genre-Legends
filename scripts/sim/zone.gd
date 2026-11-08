class_name Zone
extends RefCounted
## An area effect: acid puddles, burning ground, black holes, warning circles that become explosions,
## laser beams and expanding shockwave rings. "hostile" zones hurt the player; the rest hurt enemies.

var kind := "fire"
var pos := Vector2.ZERO
var radius := 40.0
var life := 2.0
var max_life := 2.0
var damage := 10.0
var tick := 0.5               # seconds between damage ticks
var tick_timer := 0.0
var hostile := false
var warn := 0.0               # seconds of telegraph before it becomes dangerous
var angle := 0.0              # lasers
var length := 0.0
var width := 0.0
var spin := 0.0               # lasers can sweep
var color := Color.WHITE
var hit_ids := {}             # rings hit each enemy once
var clears_bullets := false
var dead := false
