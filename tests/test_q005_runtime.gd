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
		_fail("Q005 runtime test requires --test-save-path")
		_finish()
		return
	var scene := load("res://scenes/boot/Main.tscn")
	main = scene.instantiate()
	root.add_child(main)
	await process_frame
	_expect(main.get("save_path") == save_path, "Q005 runtime must use the isolated save path")
	main._restart_game()
	_expect(not main.game_state.can_start_q005(), "Q005 must be locked in a new runtime")

	_complete_q003_runtime()
	_expect(main.game_state.can_start_q005(), "Q003 completion must unlock Q005 at runtime")
	_expect(main.game_state.is_q004_complete(), "the main story must finish the fox house before the pond garden")
	_expect(main._task_prompt_text() == "任务：照料乌龟的花园。先浇水并收集 3 株植物。", "Q005 unlock prompt must be visible")

	for plant_id in range(3):
		main.player_position = main.Q005_PLANT_POSITIONS[plant_id]
		main._try_collect_nearby()
		_expect(main.game_state.q005_plants_collected[plant_id], "each Q005 plant must collect through runtime interaction")
		main._try_collect_nearby()
		_expect(main.q005_plant_count() == plant_id + 1, "repeated plant interaction must not duplicate collection")

	main.player_position = main.Q005_WATERING_POINT_POSITION
	main._try_collect_nearby()
	_expect(main.game_state.q005_watered, "watering point interaction must update runtime state")
	main._try_collect_nearby()
	_expect(main.game_state.q005_watered, "repeated watering must remain idempotent")

	var first_inventory := _center(main._q005_plant_inventory_rect(0))
	var first_slot := _center(main.Q005_PLANT_SLOTS[0])
	_screen_touch(first_inventory, true)
	_expect(main.dragging_q005_plant == 0, "screen touch must start Q005 plant dragging")
	_screen_drag(Vector2(600, 400))
	_screen_touch(Vector2(600, 400), false)
	_expect(not main.game_state.q005_plant_slots[0], "invalid screen release must not consume the plant")

	_mouse_button(first_inventory, true)
	var second_pointer := InputEventMouseButton.new()
	second_pointer.button_index = MOUSE_BUTTON_LEFT
	second_pointer.position = _center(main._q005_plant_inventory_rect(1))
	second_pointer.pressed = true
	main._input(second_pointer)
	_expect(main.dragging_q005_plant == 0, "a second pointer must not replace the active Q005 drag")
	main._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	_expect(main.dragging_q005_plant == -1, "window focus loss must clear the Q005 drag")

	_mouse_button(first_inventory, true)
	_mouse_motion(Vector2(600, 400))
	_mouse_button(Vector2(600, 400), false)
	_expect(not main.game_state.q005_plant_slots[0], "an invalid plant release must not consume the plant")
	_mouse_button(first_inventory, true)
	_mouse_motion(first_slot)
	_mouse_button(first_slot, false)
	_expect(main.game_state.q005_plant_slots[0], "a valid plant drag must fill the first slot")

	for plant_id in [1, 2]:
		_mouse_button(_center(main._q005_plant_inventory_rect(plant_id)), true)
		_mouse_motion(_center(main.Q005_PLANT_SLOTS[plant_id]))
		_mouse_button(_center(main.Q005_PLANT_SLOTS[plant_id]), false)
		_expect(main.game_state.q005_plant_slots[plant_id], "a valid plant drag must fill each remaining slot")

	_expect(main.game_state.is_q005_complete(), "three placed plants and watering must complete Q005")
	_expect(main._task_prompt_text() == "主线任务完成！点击“建造”布置花园装饰。", "Q005 completion must clearly lead to the optional garden task")
	_expect(main._task_action_hint_text() == "点击右上方“建造”，再把三件装饰拖到花园槽位。", "Q005 completion must explain the next action")
	_expect(main._hud_title_text() == "奇趣小岛 · 花园装饰任务", "Q005 completion must update the HUD title")
	_expect(main.build_button.visible, "the optional garden build button must unlock after the main story")
	_mouse_button(_center(main._q005_plant_inventory_rect(0)), true)
	_expect(main.dragging_q005_plant == -1, "a placed Q005 plant must not be draggable again")
	_expect(_read_save().get("q005_completed") == true, "Q005 completion must be saved immediately")

	main._restart_game()
	_expect(not main.game_state.is_q005_complete(), "restart must reset Q005 completion")
	_expect(not main.game_state.q005_watered, "restart must reset Q005 watering")
	_expect(main.game_state.q005_plants_collected == [false, false, false], "restart must reset Q005 collection")
	_expect(main.game_state.q005_plant_slots == [false, false, false], "restart must reset Q005 slots")
	_expect(not main.game_state.is_complete(), "restart must reset Q001")
	_expect(not main.game_state.seed_planted, "restart must reset Q002")
	_expect(not main.game_state.is_pond_complete(), "restart must reset Q003")

	main.queue_free()
	await process_frame
	_finish()


func _complete_q003_runtime() -> void:
	for board_id in range(3):
		main.player_position = main.BOARD_POSITIONS[board_id]
		main._try_collect_nearby()
	for board_id in range(3):
		_mouse_button(_center(main._inventory_rect(board_id)), true)
		_mouse_motion(_center(main.BRIDGE_SLOTS[board_id]))
		_mouse_button(_center(main.BRIDGE_SLOTS[board_id]), false)
	main.player_position = main.SEED_POSITION
	main._try_collect_nearby()
	main.player_position = main.FLOWERBED_POSITION
	main._try_collect_nearby()
	for wood_id in range(3):
		main.player_position = main.WOOD_POSITIONS[wood_id]
		main._try_collect_nearby()
	main.player_position = main.HOUSE_POSITION
	for delivery_id in range(3):
		main._try_collect_nearby()
	for stone_id in range(3):
		_mouse_button(main.POND_STONE_POSITIONS[stone_id], true)
		_mouse_motion(_center(main.POND_SLOTS[stone_id]))
		_mouse_button(_center(main.POND_SLOTS[stone_id]), false)


func _center(rect: Rect2) -> Vector2:
	return rect.position + rect.size / 2.0


func _mouse_button(position: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = position
	event.pressed = pressed
	main._input(event)


func _mouse_motion(position: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = position
	main._input(event)


func _screen_touch(position: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.position = position
	event.pressed = pressed
	main._input(event)


func _screen_drag(position: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.position = position
	main._input(event)


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
	push_error("[Q005RuntimeTest] " + message)


func _finish() -> void:
	if failures == 0:
		print("[Q005RuntimeTest] PASS")
	else:
		push_error("[Q005RuntimeTest] FAIL: %d assertions" % failures)
	quit(failures)
