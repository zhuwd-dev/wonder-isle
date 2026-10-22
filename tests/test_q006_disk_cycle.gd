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
		_fail("Q006 disk cycle requires --test-save-path")
		_finish()
		return
	match mode:
		"write-unlocked":
			await _write_unlocked()
		"write-partial":
			await _write_partial()
		"read-partial":
			await _read_partial()
		"write-complete":
			await _write_complete()
		"read-complete":
			await _read_complete()
		"write-moved":
			await _write_moved()
		"read-moved":
			await _read_moved()
		"write-removed":
			await _write_removed()
		"read-removed":
			await _read_removed()
		"read-reset":
			await _read_reset()
		_:
			_fail("unknown Q006 disk cycle mode: %s" % mode)
	_finish()


func _spawn_main():
	var scene = load("res://scenes/boot/Main.tscn")
	var instance = scene.instantiate()
	root.add_child(instance)
	await process_frame
	_expect(instance.get("save_path") == save_path, "Q006 disk cycle must use the isolated save path")
	return instance


func _write_partial() -> void:
	var main = await _spawn_main()
	main._restart_game()
	_complete_q002(main)
	_expect(main.game_state.place_q006_decoration(0, 0), "partial Q006 placement must succeed")
	main._save_game()
	main.queue_free()


func _write_unlocked() -> void:
	var main = await _spawn_main()
	main._restart_game()
	_complete_q002(main)
	main._save_game()
	main.queue_free()


func _read_partial() -> void:
	var main = await _spawn_main()
	_expect(main.game_state.q006_decor_placed == [true, false, false], "partial Q006 placement must restore")
	_expect(main.game_state.q006_slot_occupants == [0, -1, -1], "partial Q006 slot must restore")
	_expect(not main.game_state.is_q006_complete(), "partial Q006 save must remain incomplete")
	main.queue_free()


func _write_complete() -> void:
	var main = await _spawn_main()
	_expect(main.game_state.place_q006_decoration(1, 1), "second Q006 placement after restart must succeed")
	_expect(main.game_state.place_q006_decoration(2, 2), "third Q006 placement after restart must succeed")
	_expect(main.game_state.is_q006_complete(), "complete Q006 save must complete the task")
	main._save_game()
	main.queue_free()


func _read_complete() -> void:
	var main = await _spawn_main()
	_expect(main.game_state.is_q006_complete(), "completed Q006 must restore across processes")
	_expect(main.game_state.q006_windmill_unlocked, "windmill reward must restore across processes")
	_expect(main.game_state.q006_slot_occupants == [0, 1, 2], "completed Q006 slots must restore")
	main.queue_free()


func _write_moved() -> void:
	var main = await _spawn_main()
	_expect(main.game_state.remove_q006_decoration(0, 0), "moving setup must remove the first decoration")
	_expect(main.game_state.move_q006_decoration(1, 1, 0), "moving setup must move the second decoration")
	main._save_game()
	main.queue_free()


func _read_moved() -> void:
	var main = await _spawn_main()
	_expect(main.game_state.is_q006_complete(), "moving must preserve Q006 completion")
	_expect(main.game_state.q006_slot_occupants == [1, -1, 2], "moved Q006 placement must restore")
	_expect(main.game_state.q006_decor_inventory == [true, false, false], "moved Q006 inventory must restore")
	main.queue_free()


func _write_removed() -> void:
	var main = await _spawn_main()
	_expect(main.game_state.remove_q006_decoration(1, 0), "remove setup must remove the moved decoration")
	main._save_game()
	main.queue_free()


func _read_removed() -> void:
	var main = await _spawn_main()
	_expect(main.game_state.is_q006_complete(), "removal must preserve Q006 completion")
	_expect(main.game_state.q006_decor_inventory == [true, true, false], "removal must restore both decorations to inventory")
	_expect(main.game_state.q006_slot_occupants == [-1, -1, 2], "removal must release the slot across processes")
	main._restart_game()
	main.queue_free()


func _read_reset() -> void:
	var main = await _spawn_main()
	_expect(not main.game_state.is_complete(), "reset must clear Q001")
	_expect(not main.game_state.seed_planted, "reset must clear Q002")
	_expect(not main.game_state.is_q006_complete(), "reset must clear Q006")
	_expect(main.game_state.q006_decor_inventory == [false, false, false], "reset must clear Q006 inventory")
	_expect(not main.game_state.q006_windmill_unlocked, "reset must clear the windmill reward")
	main.queue_free()


func _complete_q002(main) -> void:
	for board_id in range(3):
		main.game_state.collect_board(board_id)
		main.game_state.place_board(board_id, board_id)
	main.game_state.collect_seed()
	main.game_state.plant_seed()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	failures += 1
	push_error("[Q006DiskCycleTest] " + message)


func _finish() -> void:
	if failures == 0:
		print("[Q006DiskCycleTest] PASS: ", mode)
	else:
		push_error("[Q006DiskCycleTest] FAIL: %d assertions" % failures)
	quit(failures)
