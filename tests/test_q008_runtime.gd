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
		_fail("Q008 runtime test requires --test-save-path")
		_finish()
		return

	var scene := load("res://scenes/boot/Main.tscn")
	main = scene.instantiate()
	root.add_child(main)
	await process_frame
	_expect(main.get("save_path") == save_path, "Q008 runtime must use the isolated save path")
	main._restart_game()
	_expect(not main.game_state.can_start_q008(), "Q008 must be locked before bridge completion")
	_expect(main._q008_path_slot_at(main.Q008_PATH_SLOT_RECTS[0].position + Vector2(4, 4)) == -1, "locked Q008 slots must not be interactive")

	_complete_bridge_runtime()
	_expect(main.game_state.can_start_q008(), "bridge completion must unlock Q008 at runtime")
	_expect(not main._can_use_q008_side_task(), "Q008 stones must remain hidden during the main story")
	_expect(main._q008_path_slot_at(main.Q008_PATH_SLOT_RECTS[0].position + Vector2(4, 4)) == -1, "staged Q008 slots must not be interactive")
	_expect(not main.game_state.seed_planted, "Q008 runtime must not require Q002")
	_expect(not main.game_state.is_pond_complete(), "Q008 runtime must not require Q003")
	_expect(not main.game_state.is_q004_complete(), "Q008 runtime must not require Q004")
	_expect(not main.game_state.is_q005_complete(), "Q008 runtime must not require Q005")
	_expect(not main.game_state.is_q006_complete(), "Q008 runtime must not require Q006")
	_expect(not main.game_state.is_q007_complete(), "Q008 runtime must not require Q007")
	_expect(main._task_prompt_text() == "下一步：过桥到右侧寻找发光的种子。", "Q008 must not replace the existing main task prompt")
	_expect(main._task_action_hint_text() == "过桥到右侧靠近发光种子，按 E 或点右下角“收集 / 互动”。", "Q008 must not replace the existing main action hint")
	_expect(main._q008_prompt_text() == "小路任务：已铺设 0/3 块路面石板。", "Q008 must show its progress in the path area")

	_complete_main_story_runtime()
	_expect(main._are_core_tasks_complete(), "Q008 must become available only after the core tasks are complete")
	_expect(not main._can_use_q008_side_task(), "Q008 must stay hidden until Q010 is complete")
	_expect(not main._can_use_q009_side_task(), "Q009 must stay hidden until the shell task is complete")
	_expect(not main._can_use_q010_side_task(), "Q010 must stay hidden until the birdhouse task is complete")
	_expect(not main._can_use_q011_mode(), "Q011 must stay hidden until Q008 is complete")
	_complete_prior_optional_tasks()
	_expect(main._can_use_q008_side_task(), "completed main story must reveal the optional path task")
	_expect(main._task_stage_label() == "可选 4/5", "the path task must be marked as optional task four of five")

	var source_0 := _center(main._q008_path_material_rect(0))
	var source_1 := _center(main._q008_path_material_rect(1))
	var source_2 := _center(main._q008_path_material_rect(2))
	var slot_0 := _center(main.Q008_PATH_SLOT_RECTS[0])
	var slot_1 := _center(main.Q008_PATH_SLOT_RECTS[1])
	var slot_2 := _center(main.Q008_PATH_SLOT_RECTS[2])

	_mouse_button(source_0, true)
	_mouse_motion(slot_0)
	_expect(main._q008_path_slot_is_drop_target(0), "an empty Q008 slot must be marked as a valid target while dragging")
	_expect(main._q008_path_slot_is_hovered(0), "the Q008 slot under the pointer must receive its hover highlight")
	_expect(not main._q008_path_slot_is_hovered(1), "a non-hovered Q008 slot must not receive the hover highlight")
	_mouse_motion(Vector2(610, 450))
	_mouse_button(Vector2(610, 450), false)
	_expect(main.game_state.q008_path_slot_occupants == [-1, -1, -1], "an invalid Q008 release must not advance progress")
	_expect(main.game_state.q008_path_material_is_available(0), "an invalid Q008 release must preserve the material")

	_mouse_button(source_2, true)
	_mouse_motion(slot_1)
	_mouse_button(slot_1, false)
	_expect(main.game_state.q008_path_slot_occupants == [-1, 2, -1], "a valid Q008 drop must place a material in the selected slot")
	_mouse_button(source_0, true)
	_mouse_motion(slot_2)
	_mouse_button(slot_2, false)
	_mouse_button(source_1, true)
	_mouse_motion(slot_0)
	_mouse_button(slot_0, false)
	_expect(main.game_state.q008_path_slot_occupants == [1, 2, 0], "Q008 must allow materials in arbitrary slot order")
	_expect(main.game_state.is_q008_complete(), "three runtime Q008 placements must complete the task")
	_expect(main._q008_prompt_text() == "小路连起来完成！", "Q008 completion must update the path-area prompt")
	_expect(main.message == "小路连起来完成！", "Q008 completion must show direct feedback")
	_expect(_read_save().get("q008_completed") == true, "Q008 completion must save immediately")

	main._pointer_down(slot_0)
	_expect(main.dragging_q008_path == -1, "a placed Q008 material must not be draggable again")
	_expect(main.game_state.q008_path_slot_occupants == [1, 2, 0], "repeated Q008 interaction must not change completion")

	# Q008 must not steal pointer input while the existing Q006 build mode is active.
	main._restart_game()
	_complete_main_story_runtime()
	_complete_prior_optional_tasks()
	main.build_mode = true
	main._pointer_down(_center(main._q008_path_material_rect(0)))
	_expect(main.dragging_q008_path == -1, "Q006 build mode must retain input priority over Q008")
	main.build_mode = false

	main.queue_free()
	await process_frame
	_finish()


func _complete_bridge_runtime() -> void:
	for board_id in range(3):
		main.game_state.collect_board(board_id)
		main.game_state.place_board(board_id, board_id)
	main._save_game()


func _complete_main_story_runtime() -> void:
	if not main.game_state.is_complete():
		_complete_bridge_runtime()
	main.game_state.collect_seed()
	main.game_state.plant_seed()
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


func _complete_prior_optional_tasks() -> void:
	for decor_id in range(3):
		main.game_state.place_q006_decoration(decor_id, decor_id)
	main.game_state.complete_q012()
	main.game_state.collect_q007_shell()
	for material_id in range(3):
		main.game_state.collect_q009_material(material_id)
	for seed_id in range(3):
		main.game_state.collect_q010_seed(seed_id)
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
	push_error("[Q008RuntimeTest] " + message)


func _finish() -> void:
	if failures == 0:
		print("[Q008RuntimeTest] PASS")
	else:
		push_error("[Q008RuntimeTest] FAIL: %d assertions" % failures)
	quit(failures)
