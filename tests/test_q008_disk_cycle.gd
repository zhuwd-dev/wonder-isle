extends SceneTree

var failures := 0
var save_path := ""
var mode := ""


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	for index in range(max(args.size() - 1, 0)):
		if str(args[index]) == "--test-save-path":
			save_path = str(args[index + 1])
		elif index == 0:
			mode = str(args[index])
	call_deferred("_run")


func _run() -> void:
	if save_path.is_empty() or mode.is_empty():
		_fail("Q008 disk cycle requires a mode and --test-save-path")
		_finish()
		return
	if mode == "write-partial":
		await _write_partial()
	elif mode == "read-partial":
		await _read_partial()
	elif mode == "write-complete":
		await _write_complete()
	elif mode == "read-complete":
		await _read_complete()
	elif mode == "read-reset":
		await _read_reset()
	else:
		_fail("unknown Q008 disk mode: %s" % mode)
	_finish()


func _write_partial() -> void:
	var main = await _spawn_main()
	main._restart_game()
	_complete_bridge(main)
	_expect(main.game_state.place_q008_path(2, 1), "partial save must place the first Q008 material")
	_expect(main.game_state.place_q008_path(0, 2), "partial save must place the second Q008 material")
	main._save_game()
	var saved = _read_save()
	_expect(saved.get("schema_version") == 11, "partial Q008 save must use Schema 11")
	var partial_slots = saved.get("q008_path_slot_occupants")
	_expect(partial_slots is Array and partial_slots.size() == 3 and partial_slots[0] == -1 and partial_slots[1] == 2 and partial_slots[2] == 0, "partial Q008 save must preserve slot occupants")
	_expect(saved.get("q008_completed") == false, "partial Q008 save must remain incomplete")
	main.queue_free()
	await process_frame


func _read_partial() -> void:
	var main = await _spawn_main()
	_expect(main.game_state.q008_path_slot_occupants == [-1, 2, 0], "partial Q008 progress must restore across processes")
	_expect(not main.game_state.is_q008_complete(), "partial Q008 progress must not restore as complete")
	_expect(main.game_state.can_start_q008(), "partial Q008 progress must remain playable")
	_expect(main.game_state.place_q008_path(1, 0), "restored partial Q008 progress must accept the final material")
	_expect(main.game_state.is_q008_complete(), "finishing restored Q008 progress must complete the task")
	main._save_game()
	main.queue_free()
	await process_frame


func _write_complete() -> void:
	var main = await _spawn_main()
	main._restart_game()
	_complete_bridge(main)
	for material_id in range(3):
		_expect(main.game_state.place_q008_path(material_id, material_id), "complete save must place all Q008 materials")
	main._save_game()
	_expect(_read_save().get("q008_completed") == true, "complete Q008 save must record completion")
	main.queue_free()
	await process_frame


func _read_complete() -> void:
	var main = await _spawn_main()
	_expect(main.game_state.is_q008_complete(), "completed Q008 progress must restore across processes")
	_expect(main.game_state.q008_path_slot_occupants == [0, 1, 2], "completed Q008 slots must restore across processes")
	main.queue_free()
	await process_frame


func _read_reset() -> void:
	var main = await _spawn_main()
	_expect(main.game_state.is_q008_complete(), "reset test must start from completed Q008 progress")
	main._restart_game()
	_expect(main.game_state.q008_path_slot_occupants == [-1, -1, -1], "reset must clear Q008 slots")
	_expect(not main.game_state.q008_completed, "reset must clear Q008 completion")
	_expect(not main.game_state.can_start_q008(), "reset must lock Q008")
	var saved = _read_save()
	var reset_slots = saved.get("q008_path_slot_occupants")
	_expect(reset_slots is Array and reset_slots.size() == 3 and reset_slots[0] == -1 and reset_slots[1] == -1 and reset_slots[2] == -1, "reset must save cleared Q008 slots")
	_expect(saved.get("q008_completed") == false, "reset must save cleared Q008 completion")
	main.queue_free()
	await process_frame


func _spawn_main():
	var scene := load("res://scenes/boot/Main.tscn")
	var main = scene.instantiate()
	root.add_child(main)
	await process_frame
	_expect(main.get("save_path") == save_path, "Q008 disk cycle must use the isolated save path")
	return main


func _complete_bridge(main) -> void:
	for board_id in range(3):
		main.game_state.collect_board(board_id)
		main.game_state.place_board(board_id, board_id)


func _read_save():
	if not FileAccess.file_exists(save_path):
		return {}
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return {}
	var data = JSON.parse_string(file.get_as_text())
	return data if data is Dictionary else {}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	failures += 1
	push_error("[Q008DiskCycle] " + message)


func _finish() -> void:
	if failures == 0:
		print("[Q008DiskCycle] PASS: %s" % mode)
	else:
		push_error("[Q008DiskCycle] FAIL: %d assertions (%s)" % [failures, mode])
	quit(failures)
