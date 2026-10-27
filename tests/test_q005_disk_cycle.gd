extends SceneTree

var save_path := ""
var mode := ""
var failures := 0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	mode = str(args[0]) if not args.is_empty() else ""
	for index in range(max(args.size() - 1, 0)):
		if str(args[index]) == "--test-save-path":
			save_path = str(args[index + 1])
			break
	call_deferred("_run")


func _run() -> void:
	if save_path.is_empty():
		_fail("Q005 disk cycle requires --test-save-path")
		_finish()
		return
	match mode:
		"write-unlocked":
			await _write_unlocked()
		"write-watered":
			await _write_watered()
		"read-watered":
			await _read_watered()
		"write-partial":
			await _write_partial()
		"read-partial":
			await _read_partial()
		"write-complete":
			await _write_complete()
		"write-complete-q004":
			await _write_complete_with_q004()
		"read-complete":
			await _read_complete()
		"read-reset":
			await _read_reset()
		_:
			_fail("unknown Q005 disk cycle mode: %s" % mode)
	_finish()


func _spawn_main():
	var scene = load("res://scenes/boot/Main.tscn")
	var instance = scene.instantiate()
	root.add_child(instance)
	await process_frame
	_expect(instance.get("save_path") == save_path, "Q005 disk cycle must use the isolated save path")
	return instance


func _write_watered() -> void:
	var main = await _spawn_main()
	main._restart_game()
	_complete_q003(main)
	_expect(main.game_state.water_q005(), "watered progress must be writable")
	main._save_game()
	var saved = _read_save()
	_expect(saved.get("schema_version") == 12, "watered progress must use Schema 12")
	_expect(saved.get("q005_watered") == true, "watered progress must be saved")
	_expect(saved.get("q005_plants_collected") == [false, false, false], "watered progress must not invent plants")
	_expect(saved.get("q005_plant_slots") == [false, false, false], "watered progress must not invent slots")
	main.queue_free()


func _write_unlocked() -> void:
	var main = await _spawn_main()
	main._restart_game()
	_complete_q003(main)
	main._save_game()
	main.queue_free()


func _read_watered() -> void:
	var main = await _spawn_main()
	_expect(main.game_state.is_pond_complete(), "watered restart must preserve Q003")
	_expect(main.game_state.q005_watered, "watered restart must preserve watering")
	_expect(not main.game_state.is_q005_complete(), "watering alone must not complete Q005")
	_expect(main.game_state.q005_plants_collected == [false, false, false], "watering restart must preserve empty plant inventory")
	main.queue_free()


func _write_partial() -> void:
	var main = await _spawn_main()
	main._restart_game()
	_complete_q003(main)
	_expect(main.game_state.water_q005(), "partial save watering must succeed before plants are collected")
	for plant_id in range(3):
		_expect(main.game_state.collect_q005_plant(plant_id), "partial save plant collection must succeed")
	_expect(main.game_state.place_q005_plant(0, 0), "partial save first slot must succeed")
	main._save_game()
	main.queue_free()


func _read_partial() -> void:
	var main = await _spawn_main()
	_expect(main.game_state.q005_watered, "partial restart must preserve watering")
	_expect(main.game_state.q005_plants_collected == [true, true, true], "partial restart must preserve collected plants")
	_expect(main.game_state.q005_plant_slots == [true, false, false], "partial restart must preserve one slot")
	_expect(not main.game_state.is_q005_complete(), "partial restart must remain incomplete")
	main.queue_free()


func _write_complete() -> void:
	var main = await _spawn_main()
	main._restart_game()
	_complete_q003(main)
	_expect(main.game_state.water_q005(), "complete save watering must succeed before plants are collected")
	for plant_id in range(3):
		_expect(main.game_state.collect_q005_plant(plant_id), "complete save plant collection must succeed")
	for plant_id in range(3):
		_expect(main.game_state.place_q005_plant(plant_id, plant_id), "complete save plant placement must succeed")
	_expect(main.game_state.is_q005_complete(), "complete save must complete Q005")
	main._save_game()
	main.queue_free()


func _write_complete_with_q004() -> void:
	var main = await _spawn_main()
	main._restart_game()
	_complete_q003(main)
	for wood_id in range(3):
		_expect(main.game_state.collect_wood(wood_id), "Q004 completion setup collection must succeed")
		_expect(main.game_state.deliver_wood(wood_id), "Q004 completion setup delivery must succeed")
	_expect(main.game_state.water_q005(), "Q005 completion setup watering must succeed before plants are collected")
	for plant_id in range(3):
		_expect(main.game_state.collect_q005_plant(plant_id), "Q005 completion setup plant collection must succeed")
	for plant_id in range(3):
		_expect(main.game_state.place_q005_plant(plant_id, plant_id), "Q005 completion setup placement must succeed")
	_expect(main.game_state.is_q005_complete(), "Q005 completion setup must complete Q005")
	main._save_game()
	main.queue_free()


func _read_complete() -> void:
	var main = await _spawn_main()
	_expect(main.game_state.is_q005_complete(), "completed Q005 must restore across processes")
	_expect(main.game_state.is_pond_complete(), "completed Q005 must preserve Q003")
	_expect(not main.game_state.is_q004_complete(), "Q005 completion must not require Q004")
	_expect(main._task_prompt_text() == "任务：帮狐狸建小屋。先收集 3 份木材。", "completed Q005 must stay queued until the fox task is complete")
	main._restart_game()
	main.queue_free()


func _read_reset() -> void:
	var main = await _spawn_main()
	_expect(not main.game_state.is_complete(), "reset restart must clear Q001")
	_expect(not main.game_state.seed_planted, "reset restart must clear Q002")
	_expect(not main.game_state.is_pond_complete(), "reset restart must clear Q003")
	_expect(not main.game_state.q005_watered, "reset restart must clear Q005 watering")
	_expect(main.game_state.q005_plants_collected == [false, false, false], "reset restart must clear Q005 collection")
	_expect(main.game_state.q005_plant_slots == [false, false, false], "reset restart must clear Q005 slots")
	_expect(not main.game_state.is_q005_complete(), "reset restart must clear Q005 completion")
	main.queue_free()


func _complete_q003(main) -> void:
	for board_id in range(3):
		main.game_state.collect_board(board_id)
		main.game_state.place_board(board_id, board_id)
	main.game_state.collect_seed()
	main.game_state.plant_seed()
	for stone_id in range(3):
		main.game_state.place_pond_stone(stone_id)


func _read_save():
	if not FileAccess.file_exists(save_path):
		return null
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return null
	return JSON.parse_string(file.get_as_text())


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	failures += 1
	push_error("[Q005DiskCycleTest] " + message)


func _finish() -> void:
	if failures == 0:
		print("[Q005DiskCycleTest] PASS: ", mode)
	else:
		push_error("[Q005DiskCycleTest] FAIL: %d assertions" % failures)
	quit(failures)
