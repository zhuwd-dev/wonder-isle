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
		_fail("Q007 disk cycle requires --test-save-path")
		_finish()
		return
	match mode:
		"write-unlocked":
			await _write_unlocked()
		"read-unlocked":
			await _read_unlocked()
		"write-complete":
			await _write_complete()
		"read-complete":
			await _read_complete()
		"read-reset":
			await _read_reset()
		_:
			_fail("unknown Q007 disk cycle mode: %s" % mode)
	_finish()


func _spawn_main():
	var scene = load("res://scenes/boot/Main.tscn")
	var instance = scene.instantiate()
	root.add_child(instance)
	await process_frame
	_expect(instance.get("save_path") == save_path, "Q007 disk cycle must use the isolated save path")
	return instance


func _write_unlocked() -> void:
	var main = await _spawn_main()
	main._restart_game()
	_complete_q003(main)
	main._save_game()
	_expect(not main.game_state.q007_shell_collected, "unlocked save must not collect the shell")
	_expect(_read_save().get("schema_version") == 13, "unlocked save must use Schema 13")
	main.queue_free()


func _read_unlocked() -> void:
	var main = await _spawn_main()
	_expect(main.game_state.can_start_q007(), "Q007 must remain available after process restart")
	_expect(not main.game_state.q007_reward_unlocked, "unlocked restart must not grant the reward")
	main.queue_free()


func _write_complete() -> void:
	var main = await _spawn_main()
	_expect(main.game_state.collect_q007_shell(), "the restored Q007 save must collect the shell")
	main._save_game()
	_expect(_read_save().get("q007_completed") == true, "completed save must persist Q007 completion")
	main.queue_free()


func _read_complete() -> void:
	var main = await _spawn_main()
	_expect(main.game_state.is_q007_complete(), "completed Q007 must restore across processes")
	_expect(main.game_state.q007_reward_unlocked, "Q007 reward must restore across processes")
	main.queue_free()


func _read_reset() -> void:
	var main = await _spawn_main()
	main._restart_game()
	_expect(not main.game_state.q007_shell_collected, "reset must clear Q007 shell collection")
	_expect(not main.game_state.q007_completed, "reset must clear Q007 completion")
	_expect(not main.game_state.q007_reward_unlocked, "reset must clear Q007 reward")
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
	push_error("[Q007DiskCycleTest] " + message)


func _finish() -> void:
	if failures == 0:
		print("[Q007DiskCycleTest] PASS: ", mode)
	else:
		push_error("[Q007DiskCycleTest] FAIL: %d assertions" % failures)
	quit(failures)
