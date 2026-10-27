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
		_fail("Q010 disk cycle requires a mode and --test-save-path")
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
		_fail("unknown Q010 disk mode: %s" % mode)
	_finish()


func _write_partial() -> void:
	var main = await _spawn_main()
	main._restart_game()
	_complete_q005(main)
	_expect(main.game_state.collect_q010_seed(0), "partial save must collect the first Q010 seed")
	main._save_game()
	var saved = _read_save()
	_expect(saved.get("schema_version") == 13, "partial Q010 save must use Schema 13")
	_expect(saved.get("q010_seeds_collected") == [true, false, false], "partial Q010 save must preserve one seed")
	main.queue_free()
	await process_frame


func _read_partial() -> void:
	var main = await _spawn_main()
	_expect(main.game_state.q010_seeds_collected == [true, false, false], "one collected Q010 seed must restore across processes")
	_expect(main.game_state.can_start_q010(), "partial Q010 progress must remain playable")
	_expect(main.game_state.collect_q010_seed(1), "restored Q010 progress must accept the second seed")
	main._save_game()
	_expect(_read_save().get("q010_seeds_collected") == [true, true, false], "two-seed progress must save")
	main.queue_free()
	await process_frame


func _read_partial_two() -> void:
	var main = await _spawn_main()
	_expect(main.game_state.q010_seeds_collected == [true, true, false], "two collected Q010 seeds must restore across processes")
	_expect(main.game_state.collect_q010_seed(2), "restored Q010 progress must accept the final seed")
	main._save_game()
	_expect(main.game_state.is_q010_complete(), "finishing restored Q010 progress must complete the task")
	main.queue_free()
	await process_frame


func _read_complete() -> void:
	var main = await _spawn_main()
	_expect(main.game_state.q010_seeds_collected == [true, true, true], "completed Q010 seeds must restore across processes")
	_expect(main.game_state.is_q010_complete(), "completed Q010 progress must restore completion")
	_expect(main._q010_prompt_text() == "种子收藏完成！植物外观已解锁。", "completed Q010 restart must show completion prompt")
	_expect(main.game_state.is_q005_complete(), "Q010 completion restore must preserve Q005")
	main.queue_free()
	await process_frame


func _read_reset() -> void:
	var main = await _spawn_main()
	_expect(main.game_state.is_q010_complete(), "reset test must start from completed Q010 progress")
	main._restart_game()
	_expect(main.game_state.q010_seeds_collected == [false, false, false], "reset must clear Q010 seeds")
	_expect(not main.game_state.is_q010_complete(), "reset must clear Q010 completion")
	var saved = _read_save()
	_expect(saved.get("q010_seeds_collected") == [false, false, false], "reset must save cleared Q010 seeds")
	main.queue_free()
	await process_frame


func _spawn_main():
	var scene := load("res://scenes/boot/Main.tscn")
	var main = scene.instantiate()
	root.add_child(main)
	await process_frame
	_expect(main.get("save_path") == save_path, "Q010 disk cycle must use the isolated save path")
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


	main.game_state.deliver_q005_harvest()
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
	push_error("[Q010DiskCycle] " + message)


func _finish() -> void:
	if failures == 0:
		print("[Q010DiskCycle] PASS: %s" % mode)
	else:
		push_error("[Q010DiskCycle] FAIL: %d assertions (%s)" % [failures, mode])
	quit(failures)
