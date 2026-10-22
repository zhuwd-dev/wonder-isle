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
		_fail("Q011 runtime test requires --test-save-path")
		_finish()
		return
	var scene := load("res://scenes/boot/Main.tscn")
	main = scene.instantiate()
	root.add_child(main)
	await process_frame
	_expect(main.get("save_path") == save_path, "Q011 runtime must use the isolated save path")
	main._restart_game()
	_expect(not main.q011_button.visible, "Q011 button must stay hidden while locked")
	main._toggle_q011_mode()
	_expect(not main.q011_mode, "locked Q011 must not enter placement mode")
	_expect(main._q011_slot_at(Vector2(430, 588)) == -1, "locked Q011 must have no valid slot target")

	_complete_q001_q002(main)
	main._refresh_build_controls()
	_expect(main.game_state.q011_completed_task_count() == 2, "Q001 and Q002 must leave Q011 locked at runtime")
	_expect(not main.q011_button.visible, "two prior completions must keep the Q011 control locked")
	_complete_q003(main)
	main._refresh_build_controls()
	_expect(main.game_state.q011_completed_task_count() >= 3, "the main story must complete at least three tasks")
	_expect(not main.q011_button.visible, "Q011 must stay hidden until the main story is finished")
	_complete_q004_and_q005(main)
	main._refresh_build_controls()
	_expect(main.game_state.q011_completed_task_count() >= 3, "the completed main story must satisfy the Q011 progress requirement")
	_expect(not main.q011_button.visible, "Q011 must stay hidden until the earlier side tasks are complete")
	_expect(not main._can_use_q007_side_task(), "Q007 must be the first optional task after the main story")
	for decor_id in range(3):
		_expect(main.game_state.place_q006_decoration(decor_id, decor_id), "Q006 must complete before Q007")
	main._refresh_build_controls()
	_expect(not main._can_use_q007_side_task(), "Q006 completion must pause optional tasks for the ending")
	_expect(main.game_state.complete_q012(), "the ending must complete before side exploration")
	main._refresh_build_controls()
	_expect(main._can_use_q007_side_task(), "Q012 completion must reveal optional Q007")
	_expect(not main._can_use_q009_side_task(), "Q009 must remain hidden until Q007 is complete")
	_expect(main.game_state.collect_q007_shell(), "Q007 must complete before Q009")
	for material_id in range(3):
		_expect(main.game_state.collect_q009_material(material_id), "Q009 must complete before Q010")
	_expect(main._can_use_q010_side_task(), "Q009 completion must reveal Q010")
	_expect(not main._can_use_q008_side_task(), "Q008 must remain hidden until Q010 is complete")
	for seed_id in range(3):
		_expect(main.game_state.collect_q010_seed(seed_id), "Q010 must complete before Q008")
	_expect(main._can_use_q008_side_task(), "Q010 completion must reveal Q008")
	_expect(not main._can_use_q011_mode(), "Q011 must stay hidden until Q008 is complete")
	for material_id in range(3):
		_expect(main.game_state.place_q008_path(material_id, material_id), "Q008 must complete before Q011")
	main._refresh_build_controls()
	_expect(main.q011_button.visible, "the Q011 control must appear after Q008 is finished")
	_expect(not main.game_state.is_q011_complete(), "the extra plot must start unfinished")

	main.q011_button.emit_signal("pressed")
	_expect(main.q011_mode, "the Q011 control must enter its independent placement mode")
	_expect(not main.build_mode, "Q011 mode must exclude Q006 build mode")
	_expect(main.dragging_q008_path == -1, "Q011 mode must clear any Q008 drag state")
	_expect(main._task_prompt_text() == "额外地块整理：已放置 0/3 件物品。", "Q011 mode must display its initial progress")

	var q011_rect = main._q011_item_inventory_rect(1)
	_expect(main.game_state.q011_item_is_available(1), "the unlocked Q011 tray must offer unplaced items")
	_mouse_button(q011_rect.get_center(), true)
	_expect(main.dragging_q011_item == 1, "the actual Main input path must begin a Q011 item drag")
	_mouse_motion(Vector2(800, 500))
	_mouse_button(Vector2(800, 500), false)
	_expect(main.dragging_q011_item == -1, "an invalid release must cancel the temporary Q011 drag")
	_expect(main.game_state.q011_slot_occupants == [-1, -1, -1], "an invalid release must not consume or place an item")
	_expect(_read_save().get("q011_slot_occupants") == [-1, -1, -1], "an invalid Q011 release must not change the save")
	_expect(main.game_state.q011_item_is_available(1), "an item released outside a slot must remain in the tray")

	var q011_slot_0: Vector2 = main.Q011_SLOT_RECTS[0].get_center()
	_mouse_button(q011_rect.get_center(), true)
	_mouse_motion(q011_slot_0)
	_mouse_button(q011_slot_0, false)
	_expect(main.game_state.q011_slot_occupants == [1, -1, -1], "Q011 must allow a nonmatching item in slot zero")
	_expect(not main.game_state.q011_item_is_available(1), "a placed Q011 item must disappear from the tray")
	_expect(_read_save().get("q011_slot_occupants") == [1, -1, -1], "successful Q011 placement must save immediately")
	_expect(main._task_prompt_text() == "额外地块整理：已放置 1/3 件物品。", "partial Q011 progress must show one of three")

	var q008_material: Vector2 = main.Q008_PATH_MATERIAL_POSITIONS[0]
	main.q011_button.emit_signal("pressed")
	_expect(not main.q011_mode, "the Q011 control must exit placement mode")
	_mouse_button(q008_material, true)
	_expect(main.dragging_q008_path == -1, "completed Q008 materials must not start another path drag")
	_expect(main.game_state.q011_slot_occupants == [1, -1, -1], "Q008 placement must not change Q011 state")

	main.build_button.emit_signal("pressed")
	_expect(main.build_mode, "Q006 build mode must still open after Q011 unlock")
	_expect(not main.q011_button.visible, "the Q011 control must not overlap Q006 build controls")
	var q006_slot: Vector2 = main._q006_decor_slot_rect(0).get_center()
	main._toggle_remove_mode()
	_mouse_button(q006_slot, true)
	_expect(main.game_state.q006_decor_inventory[0], "completed Q006 decorations must remain editable")
	main._toggle_remove_mode()
	_mouse_button(main._q006_decor_inventory_rect(0).get_center(), true)
	_expect(main.dragging_q006_decor == 0, "Q006 decoration dragging must remain available in its own mode")
	_mouse_motion(q006_slot)
	_mouse_button(q006_slot, false)
	_expect(main.game_state.q006_slot_occupants[0] == 0, "Q006 placement must continue to use its own state")
	_expect(main.game_state.q011_slot_occupants == [1, -1, -1], "Q006 placement must not change Q011 state")
	main.build_button.emit_signal("pressed")
	_expect(not main.build_mode, "Q006 build mode must exit normally")

	main.q011_button.emit_signal("pressed")
	_expect(main.q011_mode, "Q011 mode must reopen with its partial progress")
	_place_q011_item(main, 0, 2)
	_expect(main.game_state.q011_slot_occupants == [1, -1, 0], "Q011 placements may be completed in any order")
	_place_q011_item(main, 2, 1)
	_expect(main.game_state.is_q011_complete(), "placing three distinct Q011 objects must complete the task")
	_expect(not main.q011_mode, "Q011 mode must end after completion")
	_expect(main.message == "整理完成！额外地块已开放。", "Q011 completion must show the required feedback")
	_expect(main._task_prompt_text() == "整理完成！额外地块已开放。", "the completion prompt must remain visible")
	_expect(_read_save().get("q011_slot_occupants") == [1, 2, 0], "Q011 completion must save all three placements")
	_expect(main._loaded_progress_message() == "已恢复进度：整理完成，额外地块已开放。", "a completed Q011 must report restoration of the open plot")

	main.queue_free()
	await process_frame
	_finish()


func _complete_q001_q002(target) -> void:
	for board_id in range(3):
		target.game_state.collect_board(board_id)
		target.game_state.place_board(board_id, board_id)
	target.game_state.collect_seed()
	target.game_state.plant_seed()
	target._save_game()


func _complete_q003(target) -> void:
	for stone_id in range(3):
		target.game_state.place_pond_stone(stone_id)
	target._save_game()


func _complete_q004_and_q005(target) -> void:
	for wood_id in range(3):
		target.game_state.collect_wood(wood_id)
		target.game_state.deliver_wood(wood_id)
	target.game_state.water_q005()
	for plant_id in range(3):
		target.game_state.collect_q005_plant(plant_id)
		target.game_state.place_q005_plant(plant_id, plant_id)
	target._save_game()


func _place_q011_item(target, item_id: int, slot_id: int) -> void:
	var source: Vector2 = target._q011_item_inventory_rect(item_id).get_center()
	var destination: Vector2 = target.Q011_SLOT_RECTS[slot_id].get_center()
	_mouse_button(source, true)
	_mouse_motion(destination)
	_mouse_button(destination, false)


func _mouse_button(position: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = position
	main._input(event)


func _mouse_motion(position: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = position
	main._input(event)


func _read_save():
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
	push_error("[Q011RuntimeTest] " + message)


func _finish() -> void:
	if failures == 0:
		print("[Q011RuntimeTest] PASS")
	else:
		push_error("[Q011RuntimeTest] FAIL: %d assertions" % failures)
	quit(failures)
