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
		_fail("Q006 runtime test requires --test-save-path")
		_finish()
		return
	var scene := load("res://scenes/boot/Main.tscn")
	main = scene.instantiate()
	root.add_child(main)
	await process_frame
	_expect(main.get("save_path") == save_path, "Q006 runtime must use the isolated save path")
	main._restart_game()
	_complete_q002_runtime()
	_expect(main.game_state.can_start_q006(), "Q002 completion must unlock Q006 at runtime")
	_expect(not main.game_state.is_pond_complete(), "Q006 runtime must not require Q003")
	_expect(not main.game_state.is_q004_complete(), "Q006 runtime must not require Q004")
	_expect(not main.game_state.is_q005_complete(), "Q006 runtime must not require Q005")
	_expect(not main._can_use_q006_build_mode(), "Q006 must remain hidden until the main story is complete")
	_expect(not main.build_button.visible, "the build button must stay hidden while the fox and pond stories remain")

	main._toggle_build_mode()
	_expect(not main.build_mode, "the build mode must not interrupt an active main story task")
	_complete_main_story_runtime()
	_expect(main._can_use_q006_build_mode(), "the main story must unlock Q006 runtime controls")
	main._toggle_build_mode()
	_expect(main.build_mode, "the build button must enter Q006 build mode")
	_expect(main._task_prompt_text() == "任务：布置花园装饰。已完成 0/3。", "Q006 build prompt must be visible")

	var first_inventory := _center(main._q006_decor_inventory_rect(0))
	var first_slot := _center(main.Q006_DECOR_SLOTS[0])
	_mouse_button(first_inventory, true)
	_expect(main.dragging_q006_decor == 0, "Q006 inventory input must start decoration dragging")
	_mouse_motion(Vector2(600, 400))
	_mouse_button(Vector2(600, 400), false)
	_expect(not main.game_state.q006_decor_placed[0], "invalid decoration release must not place it")
	_expect(main.game_state.q006_decor_inventory[0], "invalid decoration release must preserve inventory")

	_mouse_button(first_inventory, true)
	_mouse_motion(first_slot)
	_mouse_button(first_slot, false)
	_expect(main.game_state.q006_decor_placed[0], "valid decoration release must fill its slot")
	_expect(_read_save().get("q006_decor_placed")[0] == true, "valid decoration placement must save immediately")

	for decor_id in [1, 2]:
		_mouse_button(_center(main._q006_decor_inventory_rect(decor_id)), true)
		_mouse_motion(_center(main.Q006_DECOR_SLOTS[decor_id]))
		_mouse_button(_center(main.Q006_DECOR_SLOTS[decor_id]), false)
		_expect(main.game_state.q006_decor_placed[decor_id], "each Q006 decoration must place through runtime input")

	_expect(main.game_state.is_q006_complete(), "three runtime decoration placements must complete Q006")
	_expect(main.game_state.q006_windmill_unlocked, "Q006 runtime completion must unlock the windmill")
	_expect(main._task_prompt_text() == "花园装饰完成！小风车已解锁。", "Q006 completion prompt must be visible")
	_expect(_read_save().get("q006_windmill_unlocked") == true, "Q006 reward must save immediately")
	main._toggle_build_mode()
	_expect(not main.build_mode, "the build button must exit Q006 build mode")
	_expect(main._task_prompt_text() == "花园装饰完成！下一步：到池塘边寻找隐藏贝壳。", "Q006 completion must guide the player to the next side task")
	main._toggle_build_mode()

	main._toggle_remove_mode()
	_expect(main.remove_decor_mode, "remove mode must be visibly switchable")
	_mouse_button(first_slot, true)
	_expect(not main.game_state.q006_decor_placed[0], "remove mode must remove a placed decoration")
	_expect(main.game_state.q006_decor_inventory[0], "removing a decoration must return it to inventory")
	_expect(main.game_state.is_q006_complete(), "removing after completion must not roll back Q006")
	main._toggle_remove_mode()

	_mouse_button(_center(main.Q006_DECOR_SLOTS[1]), true)
	_expect(main.dragging_q006_decor == 1, "a placed decoration must start a move drag")
	_mouse_motion(first_slot)
	_mouse_button(first_slot, false)
	_expect(main.game_state.q006_slot_occupants[0] == 1, "moving must occupy the new slot")
	_expect(main.game_state.q006_slot_occupants[1] == -1, "moving must release the old slot")

	_mouse_button(_center(main.Q006_DECOR_SLOTS[0]), true)
	_mouse_motion(_center(main.Q006_DECOR_SLOTS[2]))
	_mouse_button(_center(main.Q006_DECOR_SLOTS[2]), false)
	_expect(main.game_state.q006_slot_occupants[0] == 1, "invalid move must preserve the source slot")
	_expect(main.game_state.q006_slot_occupants[2] == 2, "invalid move must preserve the occupied target")

	main._restart_game()
	_expect(not main.game_state.is_q006_complete(), "restart must reset Q006")
	_expect(main.game_state.q006_decor_inventory == [false, false, false], "restart must remove Q006 inventory")
	_expect(not main.game_state.q006_windmill_unlocked, "restart must remove the windmill reward")
	main.queue_free()
	await process_frame
	_finish()


func _complete_q002_runtime() -> void:
	for board_id in range(3):
		main.game_state.collect_board(board_id)
		main.game_state.place_board(board_id, board_id)
	main.game_state.collect_seed()
	main.game_state.plant_seed()
	main._save_game()


func _complete_main_story_runtime() -> void:
	for wood_id in range(3):
		main.game_state.collect_wood(wood_id)
		main.game_state.deliver_wood(wood_id)
	for stone_id in range(3):
		main.game_state.place_pond_stone(stone_id)
	main.game_state.water_q005()
	for plant_id in range(3):
		main.game_state.collect_q005_plant(plant_id)
		main.game_state.place_q005_plant(plant_id, plant_id)
	main._save_game()


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
	push_error("[Q006RuntimeTest] " + message)


func _finish() -> void:
	if failures == 0:
		print("[Q006RuntimeTest] PASS")
	else:
		push_error("[Q006RuntimeTest] FAIL: %d assertions" % failures)
	quit(failures)
