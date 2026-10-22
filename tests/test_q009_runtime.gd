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
		_fail("Q009 runtime test requires --test-save-path")
		_finish()
		return

	var scene := load("res://scenes/boot/Main.tscn")
	main = scene.instantiate()
	root.add_child(main)
	await process_frame
	_expect(main.get("save_path") == save_path, "Q009 runtime must use the isolated save path")

	main._restart_game()
	main.player_position = main.Q009_MATERIAL_POSITIONS[0]
	_press_interact()
	_expect(not main.game_state.q009_materials_collected[0], "Q009 materials must be locked before Q004")

	_complete_q004_runtime()
	_expect(main.game_state.can_start_q009(), "Q004 completion must unlock Q009 at runtime")
	_expect(main.game_state.is_pond_complete(), "side tasks must wait until the pond is complete")
	_expect(main.game_state.is_q005_complete(), "side tasks must wait until the garden is complete")
	_expect(not main.game_state.is_q006_complete(), "Q009 runtime must not require Q006")
	_expect(not main.game_state.is_q007_complete(), "Q009 runtime must not require Q007")
	_expect(not main.game_state.is_q008_complete(), "Q009 runtime must not require Q008")
	_expect(main._q009_prompt_text() == "鸟屋计划：已收集 0/3 份材料。", "Q009 must show its material progress")

	for material_id in range(3):
		main.player_position = main.Q009_MATERIAL_POSITIONS[material_id]
		_press_interact()
		_expect(main.game_state.q009_materials_collected[material_id], "runtime interaction must collect Q009 material %d" % material_id)
		_expect(main.game_state.q009_material_count() == material_id + 1, "Q009 runtime progress must count collected materials")

	_expect(main.game_state.is_q009_complete(), "collecting three Q009 materials must complete the task")
	_expect(main.game_state.q009_bird_interaction_unlocked(), "Q009 completion must unlock bird interaction")
	_expect(main.message == "鸟屋计划完成！小鸟互动已开放。", "Q009 completion must show direct feedback")
	_expect(main._q009_prompt_text() == "鸟屋计划完成！小鸟互动已开放。", "Q009 completion prompt must be visible")
	_expect(main._q009_action_hint_text() == "靠近小鸟按互动键，和它打个招呼。", "Q009 completion action hint must be visible")
	_expect(_read_save().get("q009_completed") == true, "Q009 completion must save immediately")

	main.player_position = main.Q009_BIRD_POSITION
	_press_interact()
	_expect(main.message == "小鸟：谢谢你帮我建好鸟屋！", "bird interaction must show safe feedback")
	_press_interact()
	_expect(main.game_state.is_q009_complete(), "repeated bird interaction must not undo Q009 completion")

	main._restart_game()
	_expect(not main.game_state.q009_materials_collected.has(true), "restart must clear Q009 materials")
	_expect(not main.game_state.q009_completed, "restart must clear Q009 completion")
	_expect(not main.game_state.q009_bird_interaction_unlocked(), "restart must lock bird interaction")
	main.queue_free()
	await process_frame
	_finish()


func _complete_q004_runtime() -> void:
	for board_id in range(3):
		main.game_state.collect_board(board_id)
		main.game_state.place_board(board_id, board_id)
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


func _press_interact() -> void:
	main.interact_button.emit_signal("pressed")


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
	push_error("[Q009RuntimeTest] " + message)


func _finish() -> void:
	if failures == 0:
		print("[Q009RuntimeTest] PASS")
	else:
		push_error("[Q009RuntimeTest] FAIL: %d assertions" % failures)
	quit(failures)
