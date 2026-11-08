class_name Shot
extends RefCounted
## A projectile, fired by the player or by enemies. Behaviour flags are set by whoever fires it
## (WeaponSystem for the player, EnemySystem and bosses for enemies) and read by World when it moves.

var pos := Vector2.ZERO
var vel := Vector2.ZERO
var radius := 5.0
var damage := 10.0
var life := 2.0
var age := 0.0
var look := "bolt"            # picks the art in ShotArt
var color := Color.WHITE
var tech := ""                # source tech, for stats and fusions
var dead := false

# Player shot behaviours
var pierce := 0               # extra enemies it can pass through
var bounces := 0              # ricochet: jumps to another enemy after a hit
var bounce_bonus := 0.0       # damage multiplier gained per bounce
var homing := 0.0             # turn rate in radians per second
var accel := 0.0              # missiles speed up
var max_speed := 0.0
var splash := 0.0             # explosion radius on hit
var bomblets := 0             # cluster warheads
var retarget := false         # hunter swarm: pick a new target if the old one dies
var target_id := -1
var split_after := 0.0        # splitfire: burst into a fan after this many seconds
var split_count := 0
var hex_mark := false         # hexplosion: hits mark the enemy
var hex_shatter := false      # hex swarm: shatter into smaller hunters
var chain_arcs := 0           # chain storm: lightning arcs on hit
var calls_meteor := false     # armageddon: impacts call a meteor
var devours := false          # event horizon: eats nearby enemy bullets
var hit_ids := {}             # enemies already hit, so piercing shots hit each once

# Enemy shot behaviours
var grazed := false           # the Graze Engine has already counted this bullet
var slowed := false           # caught in a Time Brake
var reflected := false
