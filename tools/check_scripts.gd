extends SceneTree
## Loads every script so parse errors show up in one pass.  godot --headless -s tools/check_scripts.gd


func _init() -> void:
	var bad := 0
	for path in _scripts("res://scripts") + _scripts("res://tests"):
		var script = load(path)
		if script == null or not script.can_instantiate():
			print("FAILED: ", path)
			bad += 1
	print("checked, %d failed" % bad)
	quit(1 if bad > 0 else 0)


func _scripts(dir_path: String) -> Array:
	var found := []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return found
	for file in dir.get_files():
		if file.ends_with(".gd"):
			found.append(dir_path + "/" + file)
	for sub in dir.get_directories():
		found.append_array(_scripts(dir_path + "/" + sub))
	return found
