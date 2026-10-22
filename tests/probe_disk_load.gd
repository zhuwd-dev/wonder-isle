extends SceneTree

var save_path := ""


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	for index in range(max(args.size() - 1, 0)):
		if str(args[index]) == "--test-save-path":
			save_path = str(args[index + 1])
			break
	call_deferred("_run")


func _run() -> void:
	if save_path.is_empty():
		push_error("[DiskLoadProbe] 必须提供 --test-save-path")
		quit(1)
		return
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		push_error("[DiskLoadProbe] FileAccess.open failed")
		quit(1)
		return
	var text := file.get_as_text()
	var data = JSON.parse_string(text)
	print("[DiskLoadProbe] raw=", text)
	print("[DiskLoadProbe] parsed_type=", typeof(data))
	print("[DiskLoadProbe] schema_type=", typeof(data.get("schema_version")), " collected_type=", typeof(data.get("collected")), " placed_type=", typeof(data.get("placed")))
	print("[DiskLoadProbe] flag_types=", typeof(data.get("quest_completed")), ",", typeof(data.get("bridge_repaired")), ",", typeof(data.get("area_unlocked")))
	print("[DiskLoadProbe] bool_type_constant=", TYPE_BOOL, " int_type_constant=", TYPE_INT)
	var state_script = load("res://scripts/game/game_state.gd")
	var state = state_script.new()
	print("[DiskLoadProbe] load_result=", state.load_save_data(data))
	print("[DiskLoadProbe] state=", state.to_save_data())
	quit(0)
