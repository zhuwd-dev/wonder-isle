extends SceneTree

var save_path := ""
var mode := ""
var failures := 0


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
		_fail("Q009 disk cycle requires a mode and --test-save-path")
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
		_fail("unknown Q009 disk mode: %s" % mode)
	_finish()


func _write_partial() -> void:
	var main = await _spawn_main()
	main._restart_game()
	_complete_q004(main)
	_expect(main.game_state.collect_q009_material(1), "partial save must collect the first Q009 material")
	main._save_game()
	var saved = _read_save()
	_expect(saved.get("schema_version") == 12, "partial Q009 save must use Schema 12")
	_expect(saved.get("q009_materials_collected") == [false, true, false], "partial Q009 save must preserve materials")
	_expect(saved.get("q009_completed") == false, "partial Q009 save must remain incomplete")
	main.queue_free()
	await process_frame


func _read_partial() -> void:
	var main = await _spawn_main()
	_expect(main.game_state.q009_materials_collected == [false, true, false], "partial Q009 progress must restore across processes")
	_expect(main.game_state.can_start_q009(), "partial Q009 progress must remain playable")
	_expect(main.game_state.collect_q009_material(0), "restored Q009 progress must accept the second material")
	_expect(main.game_state.collect_q009_material(2), "restored Q009 progress must accept the final material")
	_expect(main.game_state.is_q009_complete(), "finishing restored Q009 progress must complete the task")
	main._save_game()
	main.queue_free()
	await process_frame


func _write_complete() -> void:
	var main = await _spawn_main()
	main._restart_game()
	_complete_q004(main)
	for material_id in range(3):
		_expect(main.game_state.collect_q009_material(material_id), "complete save must collect all Q009 materials")
	main._save_game()
	_expect(_read_save().get("q009_completed") == true, "complete Q009 save must record completion")
	main.queue_free()
	await process_frame


func _read_complete() -> void:
	var main = await _spawn_main()
	_expect(main.game_state.is_q009_complete(), "completed Q009 progress must restore across processes")
	_expect(main.game_state.q009_bird_interaction_unlocked(), "completed Q009 must restore bird interaction")
	_expect(main._q009_prompt_text() == "鸟屋计划完成！小鸟互动已开放。", "completed Q009 restart must show completion prompt")
	main.queue_free()
	await process_frame


func _read_reset() -> void:
	var main = await _spawn_main()
	_expect(main.game_state.is_q009_complete(), "reset test must start from completed Q009 progress")
	main._restart_game()
	_expect(main.game_state.q009_materials_collected == [false, false, false], "reset must clear Q009 materials")
	_expect(not main.game_state.q009_completed, "reset must clear Q009 completion")
	_expect(not main.game_state.q009_bird_interaction_unlocked(), "reset must clear bird interaction")
	var saved = _read_save()
	_expect(saved.get("q009_materials_collected") == [false, false, false], "reset must save cleared Q009 materials")
	_expect(saved.get("q009_completed") == false, "reset must save cleared Q009 completion")
	main.queue_free()
	await process_frame


func _spawn_main():
	var scene := load("res://scenes/boot/Main.tscn")
	var main = scene.instantiate()
	root.add_child(main)
	await process_frame
	_expect(main.get("save_path") == save_path, "Q009 disk cycle must use the isolated save path")
	return main


func _complete_q004(main) -> void:
	for board_id in range(3):
		main.game_state.collect_board(board_id)
		main.game_state.place_board(board_id, board_id)
	main.game_state.collect_seed()
	main.game_state.plant_seed()
	for wood_id in range(3):
		main.game_state.collect_wood(wood_id)
		main.game_state.deliver_wood(wood_id)


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
	push_error("[Q009DiskCycle] " + message)


func _finish() -> void:
	if failures == 0:
		print("[Q009DiskCycle] PASS: %s" % mode)
	else:
		push_error("[Q009DiskCycle] FAIL: %d assertions (%s)" % [failures, mode])
	quit(failures)
