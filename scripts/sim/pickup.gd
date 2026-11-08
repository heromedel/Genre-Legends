class_name Pickup
extends RefCounted
## Something the frame can collect: Data Shards (XP), Salvage Crates, blueprints and repair cells.
## Drops are missable: they fade out if left too long.

var pos := Vector2.ZERO
var vel := Vector2.ZERO
var kind := "shard"           # shard, crate, blueprint, repair, key
var value := 1.0
var tech := ""                # blueprint drops carry the tech they unlock
var life := 14.0
var age := 0.0
var magnetized := false
var anchored := false         # stays put: treasure pedestals
var dead := false
