extends SceneTree

var failures := 0
var save_path := ""
var main


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	for index in range(max(args.size() - 1, 0)):
		if str(args[index]) == "--test-save-path":
			save_path = str(args[index + 1])
			break
	call_deferred("_run")


func _run() -> void:
	if save_path.is_empty():
		_fail("Q004 runtime test requires --test-save-path")
		_finish()
		return
	var scene := load("res://scenes/boot/Main.tscn")
	main = scene.instantiate()
	root.add_child(main)
	await process_frame
	_expect(main.get("save_path") == save_path, "Q004 runtime test must use the isolated save path")
	main._restart_game()

	_complete_q002_runtime()
	_expect(main.game_state.can_start_q004(), "Q002 completion must unlock Q004 at runtime")
	_expect(not main.game_state.is_pond_complete(), "Q004 must not require Q003 completion")
	_expect(main._task_prompt_text() == "任务：帮狐狸建小屋。先收集 3 份木材。", "Q004 unlock prompt must be visible")

	for wood_id in range(3):
		main.player_position = main.WOOD_POSITIONS[wood_id]
		main._try_collect_nearby()
		_expect(main.game_state.wood_collected[wood_id], "each Q004 wood must collect through runtime interaction")
		main._try_collect_nearby()
		_expect(main.game_state.wood_count() == wood_id + 1, "repeated interaction must not duplicate wood")

	main.player_position = main.HOUSE_POSITION
	main._try_collect_nearby()
	_expect(main.game_state.wood_delivered == [true, false, false], "one house interaction must deliver one wood")
	_expect(not main.game_state.is_q004_complete(), "one delivery must not complete Q004")
	main._try_collect_nearby()
	_expect(main.game_state.wood_delivered == [true, true, false], "second house interaction must deliver one more wood")
	main._try_collect_nearby()
	_expect(main.game_state.is_q004_complete(), "third house interaction must complete Q004")
	_expect(main.game_state.fox_moved_in, "Q004 completion must show the fox moved in")
	_expect(not main.game_state.is_pond_complete(), "Q003 must remain incomplete after Q004")
	_expect(main._task_prompt_text() == "狐狸已经入住！池塘石头还可以继续摆好。", "Q004 completion must not hide unfinished Q003")

	main._try_collect_nearby()
	_expect(main.game_state.delivered_wood_count() == 3, "repeated delivery after completion must not change count")
	main.player_position = main.POND_STONE_POSITIONS[0]
	main._pointer_down(main.POND_STONE_POSITIONS[0])
	_expect(main.dragging_pond_stone == 0, "Q003 must remain playable after Q004 completion")
	main._pointer_up(main.POND_SLOTS[0].position + main.POND_SLOTS[0].size / 2.0)
	_expect(main.game_state.pond_stones_placed[0], "Q003 stone placement must remain functional")

	main._restart_game()
	_expect(not main.game_state.can_start_q004(), "restart must lock Q004")
	_expect(main.game_state.wood_collected == [false, false, false], "restart must clear Q004 collection")
	_expect(main.game_state.wood_delivered == [false, false, false], "restart must clear Q004 delivery")
	_expect(not main.game_state.q004_completed and not main.game_state.fox_moved_in, "restart must clear fox occupancy")

	main.queue_free()
	await process_frame
	_finish()


func _complete_q002_runtime() -> void:
	for board_id in range(3):
		main.player_position = main.BOARD_POSITIONS[board_id]
		main._try_collect_nearby()
	for board_id in range(3):
		_mouse_drag(main._inventory_rect(board_id).position + main._inventory_rect(board_id).size / 2.0, main.BRIDGE_SLOTS[board_id].position + main.BRIDGE_SLOTS[board_id].size / 2.0)
	main.player_position = main.SEED_POSITION
	main._try_collect_nearby()
	main.player_position = main.FLOWERBED_POSITION
	main._try_collect_nearby()


func _mouse_drag(from_position: Vector2, to_position: Vector2) -> void:
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.position = from_position
	down.pressed = true
	main._input(down)
	var motion := InputEventMouseMotion.new()
	motion.position = to_position
	main._input(motion)
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.position = to_position
	up.pressed = false
	main._input(up)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	failures += 1
	push_error("[Q004RuntimeTest] " + message)


func _finish() -> void:
	if failures == 0:
		print("[Q004RuntimeTest] PASS")
	else:
		push_error("[Q004RuntimeTest] FAIL: %d assertions" % failures)
	quit(failures)
