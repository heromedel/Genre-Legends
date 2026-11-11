class_name Enemy
extends RefCounted
## One enemy, or one hittable part of a boss. Its behaviour lives in EnemySystem (by "brain")
## or in its boss script; its look lives in EnemyArt (by "look").

var id := 0
var kind := ""
var brain := ""
var look := ""
var pos := Vector2.ZERO
var vel := Vector2.ZERO
var facing := PI * 0.5        # radians; enemies in the shooters face down the screen
var hp := 10.0
var max_hp := 10.0
var radius := 12.0
var contact := 10.0
var xp := 1
var color := Color.WHITE
var elite := false
var elite_mod := ""            # a promoted elite's twist: shielded, splitting or mirrored
var shield_hp := 0.0           # a shielded elite's barrier, spent before its health
var objective := false        # counts toward the mission's goal
var drops_crate := false
var drops_repair := false           # Star Cluster has no placed repairs, so its barge carries one (GDD 13G)
var front_shield := false     # blocks shots arriving from in front of it
var ghost := false            # passes through walls
var dead := false
var invulnerable := false
var untargetable := false     # auto-aim ignores it (secret walls)
var reflects := false         # mirrored plate: throws straight shots back at the player
var hidden := false           # burrowed, or not yet emerged: can't be hit and doesn't hurt
var flash := 0.0              # hit flash for the art
var unstable := false           # destabilized by the Flux Repeater or Mawjig Resonance: takes more damage
var timer := 0.0              # general-purpose behaviour timer
var fire_timer := 0.0
var state := 0                # behaviour state machine step
var memory := {}              # behaviour scratch values
var orbit_hits := {}          # per-saw hit cooldowns from the Orbital Halo
var boss = null               # the BossBase that owns this part, if any
var part := ""                # which part of the boss this is
var room := Vector2i.ZERO     # dungeon room it belongs to
var spawn_age := 0.0
