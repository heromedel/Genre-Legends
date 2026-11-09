class_name DungeonStage
extends Stage
## Dungeon Delve (GDD 6D): rooms on a grid, crawler style, leaning on the genre's tropes (GDD 1B):
## doors slam shut until the room is clear, the boss door is marked and locked until you find the key,
## a treasure room holds a pedestal, a cracked wall hides a secret room, a minimap fills in as you explore,
## and not every chest is a chest.

const ROOM := Vector2(1200, 800)
const WALL := 46.0
const DOOR := 170.0

var rooms: Dictionary = {}          # Vector2i -> {kind, doors: {dir: neighbour}, state, depth}
var current := Vector2i.ZERO
var previous := Vector2i.ZERO
var start_room := Vector2i.ZERO
var boss_room := Vector2i.ZERO
var breached := false            # chained missions: the boss door led up to the surface
var key_room := Vector2i.ZERO
var secret_room := Vector2i(999, 999)
var secret_from := Vector2i.ZERO
var secret_wall_id := -1
var secret_open := false
var has_key := false
var room_enemies: Array = []        # ids of enemies spawned for the current room
var spawn_delay := 0.0
var doors_closed := false
var secret_visited := false

const DIRECTIONS := {"n": Vector2i(0, -1), "s": Vector2i(0, 1), "w": Vector2i(-1, 0), "e": Vector2i(1, 0)}
const OPPOSITE := {"n": "s", "s": "n", "w": "e", "e": "w"}


func stage_name() -> String:
	return "Dungeon"


func setup() -> void:
	form = "mech"
	camera_mode = "room"
	_generate()
	var bounds := Rect2()
	for key in rooms:
		bounds = room_rect(key) if bounds.size == Vector2.ZERO else bounds.merge(room_rect(key))
	world.bounds = bounds
	world.shot_bounds = bounds.grow(100)
	current = start_room
	mission.player.pos = room_rect(start_room).get_center() + Vector2(0, 200)
	rooms[start_room]["state"] = "cleared"
	rooms[start_room]["visited"] = true
	_build_walls()


func room_rect(key: Vector2i) -> Rect2:
	return Rect2(Vector2(key) * ROOM, ROOM)


# ---------------------------------------------------------------- generation

func _generate() -> void:
	var target := 13 + world.rng.randi_range(0, 2)
	rooms[Vector2i.ZERO] = _new_room(0)
	var frontier := [Vector2i.ZERO]
	var guard := 0
	while rooms.size() < target and guard < 400:
		guard += 1
		var from: Vector2i = frontier[world.rng.randi() % frontier.size()]
		var direction: String = DIRECTIONS.keys()[world.rng.randi() % 4]
		var to: Vector2i = from + DIRECTIONS[direction]
		if rooms.has(to) or _neighbour_count(to) > 1:
			continue
		rooms[to] = _new_room(rooms[from]["depth"] + 1)
		_connect(from, direction)
		frontier.append(to)
	# Boss room: the deepest room. Key: the deepest room on a different branch.
	var deepest := Vector2i.ZERO
	for key in rooms:
		if rooms[key]["depth"] > rooms[deepest]["depth"]:
			deepest = key
	boss_room = deepest
	rooms[boss_room]["kind"] = "boss"
	var dead_ends := rooms.keys().filter(func(k): return k != start_room and k != boss_room and rooms[k]["doors"].size() == 1)
	var others := rooms.keys().filter(func(k): return k != start_room and k != boss_room)
	key_room = _deepest_of(dead_ends if not dead_ends.is_empty() else others)
	rooms[key_room]["kind"] = "key"
	var treasure_choices := dead_ends.filter(func(k): return k != key_room)
	if treasure_choices.is_empty():
		treasure_choices = others.filter(func(k): return k != key_room)
	if not treasure_choices.is_empty():
		rooms[treasure_choices[world.rng.randi() % treasure_choices.size()]]["kind"] = "treasure"
	var plain := rooms.keys().filter(func(k): return rooms[k]["kind"] == "combat")
	if plain.size() > 2:
		rooms[plain[world.rng.randi() % plain.size()]]["kind"] = "shrine"
	# The Mimic King's hall: a plain room about halfway down (GDD 9B mini-boss).
	var halfway := rooms.keys().filter(func(k): return rooms[k]["kind"] == "combat" and rooms[k]["depth"] >= 2)
	if not halfway.is_empty():
		rooms[halfway[world.rng.randi() % halfway.size()]]["kind"] = "miniboss"
	_add_secret_room()


func _new_room(depth: int) -> Dictionary:
	return {"kind": "combat", "doors": {}, "state": "new", "depth": depth, "visited": false,
		"layout": world.rng.randi() % 4, "seed": world.rng.randi()}


func _connect(from: Vector2i, direction: String) -> void:
	var to: Vector2i = from + DIRECTIONS[direction]
	rooms[from]["doors"][direction] = to
	rooms[to]["doors"][OPPOSITE[direction]] = from


func _neighbour_count(key: Vector2i) -> int:
	var count := 0
	for direction in DIRECTIONS:
		if rooms.has(key + DIRECTIONS[direction]):
			count += 1
	return count


func _deepest_of(keys: Array) -> Vector2i:
	var best: Vector2i = keys[0]
	for key in keys:
		if rooms[key]["depth"] > rooms[best]["depth"]:
			best = key
	return best


## A secret room hangs off an ordinary room behind a cracked wall.
func _add_secret_room() -> void:
	for key in rooms.keys():
		if rooms[key]["kind"] != "combat" and rooms[key]["kind"] != "shrine":
			continue
		for direction in DIRECTIONS:
			var to: Vector2i = key + DIRECTIONS[direction]
			if not rooms.has(to) and _neighbour_count(to) == 1:
				rooms[to] = _new_room(rooms[key]["depth"] + 1)
				rooms[to]["kind"] = "secret"
				rooms[key]["secret_dir"] = direction
				rooms[to]["doors"][OPPOSITE[direction]] = key
				secret_room = to
				secret_from = key
				return


# ---------------------------------------------------------------- walls and doors

## Walls for the current room, with door gaps. Closed doors (combat, locked boss door, unopened secret)
## are filled in.
func _build_walls() -> void:
	world.walls = room_walls(current)


## Walls of any room, as they stand right now. The art uses this for neighbouring rooms too.
func room_walls(key: Vector2i) -> Array:
	var rect := room_rect(key)
	var room: Dictionary = rooms[key]
	var walls := []
	for direction in DIRECTIONS:
		walls.append_array(_wall_side(rect, direction, door_open(key, direction)))
	walls.append_array(_obstacles(rect, room))
	return walls


## Whether the doorway on one side of a room is passable right now.
func door_open(key: Vector2i, direction: String) -> bool:
	var room: Dictionary = rooms[key]
	var open: bool = room["doors"].has(direction)
	if room.get("secret_dir", "") == direction:
		open = secret_open
	if open and doors_closed and key == current:
		open = false
	if open and room["doors"].get(direction) == boss_room and not has_key:
		open = false
	return open


func _wall_side(rect: Rect2, direction: String, open: bool) -> Array:
	var horizontal := direction == "n" or direction == "s"
	var length := rect.size.x if horizontal else rect.size.y
	var gap := DOOR if open else 0.0
	var piece := (length - gap) * 0.5
	var result := []
	match direction:
		"n":
			result.append(Rect2(rect.position.x, rect.position.y, piece, WALL))
			result.append(Rect2(rect.position.x + piece + gap, rect.position.y, piece, WALL))
		"s":
			result.append(Rect2(rect.position.x, rect.end.y - WALL, piece, WALL))
			result.append(Rect2(rect.position.x + piece + gap, rect.end.y - WALL, piece, WALL))
		"w":
			result.append(Rect2(rect.position.x, rect.position.y, WALL, piece))
			result.append(Rect2(rect.position.x, rect.position.y + piece + gap, WALL, piece))
		"e":
			result.append(Rect2(rect.end.x - WALL, rect.position.y, WALL, piece))
			result.append(Rect2(rect.end.x - WALL, rect.position.y + piece + gap, WALL, piece))
	return result


## Pillars and blocks inside a room, from one of a few layouts. Boss and treasure rooms keep their own shape.
func _obstacles(rect: Rect2, room: Dictionary) -> Array:
	var c := rect.get_center()
	var block := Vector2(70, 70)
	if room["kind"] == "boss":
		return [Rect2(c + Vector2(-380, -240) - block * 0.5, block), Rect2(c + Vector2(380, -240) - block * 0.5, block),
			Rect2(c + Vector2(-380, 240) - block * 0.5, block), Rect2(c + Vector2(380, 240) - block * 0.5, block)]
	if room["kind"] in ["treasure", "shrine", "key", "secret", "miniboss"] or room["depth"] == 0:
		return []
	match room["layout"]:
		0:
			return [Rect2(c + Vector2(-260, -150) - block * 0.5, block), Rect2(c + Vector2(260, -150) - block * 0.5, block),
				Rect2(c + Vector2(-260, 150) - block * 0.5, block), Rect2(c + Vector2(260, 150) - block * 0.5, block)]
		1:
			return [Rect2(c - Vector2(110, 60), Vector2(220, 120))]
		2:
			return [Rect2(c + Vector2(-330, -40), Vector2(160, 80)), Rect2(c + Vector2(170, -40), Vector2(160, 80))]
	return []


# ---------------------------------------------------------------- moving between rooms

func after_player_moved() -> void:
	var key := Vector2i(floori(mission.player.pos.x / ROOM.x), floori(mission.player.pos.y / ROOM.y))
	if key == current or not rooms.has(key):
		return
	previous = current
	current = key
	_enter_room()


func _enter_room() -> void:
	var room: Dictionary = rooms[current]
	var first_visit: bool = not room["visited"]
	room["visited"] = true
	world.emit("room_entered", {"room": current, "kind": room["kind"]})
	mission.note("Entered %s room %s" % [room["kind"], str(current)])
	# Push the frame a little into the room so it isn't standing in the doorway when doors close.
	var into := room_rect(current).get_center() - mission.player.pos
	mission.player.pos += into.normalized() * 70.0
	if room["state"] == "new":
		match room["kind"]:
			"combat", "key", "secret":
				_start_combat(room)
			"boss":
				_start_boss_room()
			"miniboss":
				room["state"] = "active"
				doors_closed = true
				world.emit("doors", {"closed": true})
				var guardian := BossRoster.make(BossRoster.for_node(mission.node, "miniboss"), world)
				guardian.origin = room_rect(current).get_center() + Vector2(0, -120)
				guardian.setup_room(room_rect(current))
				start_miniboss(guardian)
			"treasure":
				var pedestal := world.drop_pickup("pedestal", room_rect(current).get_center())
				pedestal.vel = Vector2.ZERO
				pedestal.anchored = true
				room["state"] = "cleared"
				world.emit("banner", {"text": "TREASURE ROOM", "style": "gold"})
			"shrine":
				var repair := world.drop_pickup("repair", room_rect(current).get_center())
				repair.vel = Vector2.ZERO
				repair.anchored = true
				var crate := world.drop_pickup("crate", room_rect(current).get_center() + Vector2(0, 90))
				crate.vel = Vector2.ZERO
				crate.anchored = true
				room["state"] = "cleared"
				world.emit("banner", {"text": "SHRINE", "style": "cyan"})
	if current == secret_room:
		secret_visited = true
	if current == secret_room and first_visit:
		world.emit("banner", {"text": "SECRET ROOM", "style": "gold"})
	if room.has("secret_dir") and not secret_open and secret_wall_id < 0:
		_place_cracked_wall(room)
	_build_walls()


func _start_combat(room: Dictionary) -> void:
	room["state"] = "active"
	doors_closed = true
	spawn_delay = 0.45
	world.emit("doors", {"closed": true})
	world.emit("sound", {"name": "door_slam"})
	var rng := RandomNumberGenerator.new()
	rng.seed = room["seed"]
	var rect := room_rect(current)
	var depth: int = room["depth"]
	var count := clampi(int((3 + depth + rng.randi_range(0, 2)) * world.spawn_scale), 3, 12)
	var roster: Dictionary = EnemyData.ROSTERS["dungeon"]
	var entry := mission.player.pos
	for i in count:
		var kind := _weighted(rng, roster)
		var at := Vector2(rng.randf_range(rect.position.x + 140, rect.end.x - 140), rng.randf_range(rect.position.y + 130, rect.end.y - 130))
		if at.distance_to(entry) < 280.0:
			at = rect.get_center() + (rect.get_center() - entry).normalized() * 200.0 + Vector2(rng.randf_range(-120, 120), rng.randf_range(-80, 80))
		var enemy := world.spawn_enemy(kind, at)
		enemy.room = current
		enemy.hidden = true
		enemy.memory["awake"] = true
		room_enemies.append(enemy.id)
	# Trope: a chest in a combat room. It is not a chest.
	if room["kind"] == "combat" and rng.randf() < 0.3:
		var mimic := world.spawn_enemy("mimic", rect.get_center() + Vector2(rng.randf_range(-200, 200), -160))
		mimic.room = current
		mimic.untargetable = true
		mimic.memory["awake"] = true
		room_enemies.append(mimic.id)
	if room["kind"] == "key":
		room["holds_key"] = true


func _weighted(rng: RandomNumberGenerator, roster: Dictionary) -> String:
	var total := 0
	for kind in roster:
		total += roster[kind]
	var roll := rng.randi() % total
	for kind in roster:
		roll -= roster[kind]
		if roll < 0:
			return kind
	return roster.keys()[0]


func _start_boss_room() -> void:
	# Chained (GDD 6G): the boss door opens on a shaft to the surface, and the fight continues up there.
	if has_next_stage():
		breached = true
		world.emit("banner", {"text": "BREAKING OUT TO THE SURFACE", "style": "gold"})
		mission.note("Broke out to the surface")
		return
	rooms[current]["state"] = "active"
	doors_closed = true
	world.emit("doors", {"closed": true})
	var king := BossRoster.make(BossRoster.for_node(mission.node, "boss"), world)
	king.setup_room(room_rect(current))
	king.memory["room_key"] = current
	start_boss(king)


func _place_cracked_wall(room: Dictionary) -> void:
	var rect := room_rect(current)
	var direction: String = room["secret_dir"]
	var at := rect.get_center()
	match direction:
		"n": at = Vector2(rect.get_center().x, rect.position.y + WALL * 0.5)
		"s": at = Vector2(rect.get_center().x, rect.end.y - WALL * 0.5)
		"w": at = Vector2(rect.position.x + WALL * 0.5, rect.get_center().y)
		"e": at = Vector2(rect.end.x - WALL * 0.5, rect.get_center().y)
	var wall := world.spawn_enemy("cracked_wall", at)
	wall.untargetable = true
	wall.ghost = true
	wall.room = current
	wall.memory["direction"] = direction
	secret_wall_id = wall.id


func step(dt: float) -> void:
	if spawn_delay > 0.0:
		spawn_delay -= dt
		if spawn_delay <= 0.0:
			for enemy_id in room_enemies:
				var enemy := world.enemy_by_id(enemy_id)
				if enemy != null and enemy.brain != "burrower":
					enemy.hidden = false
					world.emit("spawn_in", {"pos": enemy.pos})
	update_miniboss(dt)
	if boss != null:
		boss.update(dt)
	if secret_wall_id >= 0 and not secret_open and world.enemy_by_id(secret_wall_id) == null:
		secret_open = true
		world.emit("banner", {"text": "A SECRET PASSAGE!", "style": "gold"})
		world.emit("sound", {"name": "secret"})
		_build_walls()
	var room: Dictionary = rooms[current]
	if room["kind"] == "miniboss" and room["state"] == "active" and miniboss != null and miniboss.finished:
		_room_cleared(room)
	elif room["state"] == "active" and boss == null and room["kind"] != "miniboss" and spawn_delay <= 0.0:
		var alive := room_enemies.filter(func(id): return world.enemy_by_id(id) != null)
		if alive.is_empty():
			_room_cleared(room)


func _room_cleared(room: Dictionary) -> void:
	room["state"] = "cleared"
	room_enemies.clear()
	doors_closed = false
	world.emit("doors", {"closed": false})
	world.emit("sound", {"name": "door_open"})
	_build_walls()
	if room.get("holds_key", false):
		var key := world.drop_pickup("key", room_rect(current).get_center())
		key.vel = Vector2.ZERO
		key.anchored = true
		world.emit("banner", {"text": "THE BOSS KEY", "style": "gold"})
	elif world.rng.randf() < 0.3:
		world.drop_pickup("repair", room_rect(current).get_center())


func debug_skip_to_boss() -> void:
	has_key = true
	for enemy: Enemy in world.enemies:
		enemy.dead = true
	doors_closed = false
	mission.player.pos = room_rect(boss_room).get_center() + Vector2(0, 260)


func debug_skip_to_miniboss() -> void:
	for key in rooms:
		if rooms[key]["kind"] == "miniboss":
			mission.player.pos = room_rect(key).get_center() + Vector2(0, 250)
			for enemy: Enemy in world.enemies:
				enemy.dead = true
			doors_closed = false
			return


func stage_progress() -> float:
	var visited := rooms.values().filter(func(r): return r["visited"]).size()
	return float(visited) / float(rooms.size())


func on_key_collected() -> void:
	has_key = true
	world.emit("banner", {"text": "BOSS DOOR UNLOCKED", "style": "gold"})
	mission.note("Picked up the boss key")
	_build_walls()


func is_cleared() -> bool:
	return breached or (boss != null and boss.finished)


func objective_text() -> String:
	if boss != null:
		return "Defeat %s" % boss.boss_name
	if not has_key:
		return "Find the boss key"
	return "Open the boss door"


## Where the HUD's arrows point: nothing (dungeons are explored), except toward the boss door once you
## have the key and have seen it.
func objective_positions() -> Array:
	if has_key and rooms[boss_room]["doors"].values().any(func(k): return rooms[k]["visited"]):
		return [room_rect(boss_room).get_center()]
	return []
