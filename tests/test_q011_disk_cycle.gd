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
		_fail("Q011 disk cycle requires a mode and --test-save-path")
		_finish()
		return
	if mode == "write-partial":
		await _write_partial()
	elif mode == "read-partial":
		await _read_partial()
	elif mode == "read-partial-two":
		await _read_partial_two()
	elif mode == "read-complete":
		await _read_complete()
	elif mode == "read-reset":
		await _read_reset()
	else:
		_fail("unknown Q011 disk mode: %s" % mode)
	_finish()


func _write_partial() -> void:
	var main = await _spawn_main()
	main._restart_game()
	_complete_q005(main)
	_expect(main.game_state.q011_completed_task_count() >= 3, "disk setup must unlock Q011")
	_expect(main.game_state.place_q011_item(2, 0), "first Q011 item must be placeable before process exit")
	main._save_game()
	var saved := _read_save()
	_expect(saved.get("schema_version") == 12, "partial Q011 saves must use Schema 12")
	_expect(saved.get("q011_slot_occupants") == [2, -1, -1], "partial Q011 saves must preserve the first slot")
	main.queue_free()
	await process_frame


func _read_partial() -> void:
	var main = await _spawn_main()
	_expect(main.game_state.q011_slot_occupants == [2, -1, -1], "one placed Q011 item must restore across processes")
	_expect(main.game_state.can_start_q011(), "partial Q011 progress must remain placeable")
	_expect(not main.game_state.q011_item_is_available(2), "restored Q011 items must not return to the tray")
	_expect(main.game_state.place_q011_item(0, 1), "restored Q011 progress must accept a second item")
	main._save_game()
	_expect(_read_save().get("q011_slot_occupants") == [2, 0, -1], "two-item Q011 progress must save")
	main.queue_free()
	await process_frame


func _read_partial_two() -> void:
	var main = await _spawn_main()
	_expect(main.game_state.q011_slot_occupants == [2, 0, -1], "two Q011 items must restore across processes")
	_expect(main.game_state.q011_placed_count() == 2, "restored two-item progress must count correctly")
	_expect(main.game_state.place_q011_item(1, 2), "restored Q011 progress must accept its final item")
	_expect(main.game_state.is_q011_complete(), "three restored placements must derive Q011 completion")
	main._save_game()
	_expect(_read_save().get("q011_slot_occupants") == [2, 0, 1], "Q011 completion must save all placements")
	main.queue_free()
	await process_frame


func _read_complete() -> void:
	var main = await _spawn_main()
	_expect(main.game_state.q011_slot_occupants == [2, 0, 1], "completed Q011 slots must restore across processes")
	_expect(main.game_state.is_q011_complete(), "Q011 completion must be derived after process restart")
	_expect(main._loaded_progress_message() == "已恢复进度：主线与支线都已完成，可以自由探索。", "restarted Main must report that the island tasks are finished")
	_expect(main._task_prompt_text() == "额外地块整理完成！可以自由探索，或点击“建造”调整花园。", "restarted Main must offer clear post-completion choices")
	_expect(not main.q011_button.visible, "a completed Q011 must not expose another placement session")
	main.queue_free()
	await process_frame


func _read_reset() -> void:
	var main = await _spawn_main()
	_expect(main.game_state.is_q011_complete(), "reset check must start from completed Q011")
	main._restart_game()
	_expect(main.game_state.q011_slot_occupants == [-1, -1, -1], "reset must clear Q011 across the runtime entry point")
	_expect(not main.game_state.is_q011_complete(), "reset must remove the completed plot state")
	_expect(_read_save().get("q011_slot_occupants") == [-1, -1, -1], "reset must save empty Q011 slots")
	main.queue_free()
	await process_frame


func _spawn_main():
	var scene := load("res://scenes/boot/Main.tscn")
	var main = scene.instantiate()
	root.add_child(main)
	await process_frame
	_expect(main.get("save_path") == save_path, "Q011 disk cycle must use the isolated save path")
	return main


func _complete_q005(main) -> void:
	for board_id in range(3):
		main.game_state.collect_board(board_id)
		main.game_state.place_board(board_id, board_id)
	main.game_state.collect_seed()
	main.game_state.plant_seed()
	for stone_id in range(3):
		main.game_state.place_pond_stone(stone_id)
	main.game_state.water_q005()
	for plant_id in range(3):
		main.game_state.collect_q005_plant(plant_id)
		main.game_state.place_q005_plant(plant_id, plant_id)


func _read_save() -> Dictionary:
	if not FileAccess.file_exists(save_path):
		return {}
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return {}
	var data = JSON.parse_string(file.get_as_text())
	if data is Dictionary and data.get("q011_slot_occupants") is Array:
		var normalized_slots: Array[int] = []
		for occupant in data["q011_slot_occupants"]:
			normalized_slots.append(int(occupant))
		data["q011_slot_occupants"] = normalized_slots
	return data if data is Dictionary else {}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	failures += 1
	push_error("[Q011DiskCycle] " + message)


func _finish() -> void:
	if failures == 0:
		print("[Q011DiskCycle] PASS: %s" % mode)
	else:
		push_error("[Q011DiskCycle] FAIL: %d assertions (%s)" % [failures, mode])
	quit(failures)
