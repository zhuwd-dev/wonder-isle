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
		_fail("Q010 runtime test requires --test-save-path")
		_finish()
		return

	var scene := load("res://scenes/boot/Main.tscn")
	main = scene.instantiate()
	root.add_child(main)
	await process_frame
	_expect(main.get("save_path") == save_path, "Q010 runtime must use the isolated save path")

	main._restart_game()
	main.player_position = main.Q010_SEED_POSITIONS[0]
	_press_interact()
	_expect(main.game_state.q010_seed_count() == 0, "Q010 seeds must be locked before Q005")

	_complete_q005_runtime()
	_expect(main.game_state.can_start_q010(), "Q005 completion must unlock Q010 at runtime")
	_expect(not main._can_use_q010_side_task(), "Q010 must stay hidden until Q007 and Q009 are complete")
	_expect(not main.game_state.q010_seeds_collected.has(true), "locked Q010 interaction must not collect seeds")
	for decor_id in range(3):
		_expect(main.game_state.place_q006_decoration(decor_id, decor_id), "Q006 must complete before the side-quest chain")
	_expect(main.game_state.complete_q012(), "Q012 must complete before optional side tasks")
	_expect(main.game_state.collect_q007_shell(), "Q007 must complete before Q009")
	for material_id in range(3):
		_expect(main.game_state.collect_q009_material(material_id), "Q009 materials must complete before Q010")
	_expect(not main.game_state.is_q009_complete(), "Q009 must wait for delivery after collecting materials")
	for delivery_id in range(3):
		_expect(main.game_state.deliver_next_q009_material(), "Q009 materials must be delivered before Q010")
	main._save_game()
	_expect(main._can_use_q010_side_task(), "Q009 completion must unlock Q010")
	_expect(main._task_stage_label() == "可选 3/5", "the seed collection task must be marked as optional task three of five")
	_expect(main._should_show_q009_task_card(), "the optional bird greeting may stay visible while seed collection is active")
	_expect(main._should_show_q010_task_card(), "the active seed collection card must be visible")
	_expect(main.Q010_SEED_POSITIONS[1].distance_to(main.Q012_RABBIT_POSITION) > 80.0, "the blue seed must stay visually separated from the rabbit")
	_expect(not main._can_use_q008_side_task(), "Q008 must stay hidden until Q010 is complete")
	_expect(not main._can_use_q011_mode(), "Q011 must stay hidden until Q008 is complete")
	_expect(main._q010_prompt_text() == "种子收藏：已收集 0/3 个指定种子。", "Q010 must show its progress prompt")

	for seed_id in range(3):
		main.player_position = main.Q010_SEED_POSITIONS[seed_id]
		_press_interact()
		_expect(main.game_state.q010_seeds_collected[seed_id], "runtime interaction must collect Q010 seed %d" % seed_id)
		_expect(main.game_state.q010_seed_count() == seed_id + 1, "Q010 runtime progress must count collected seeds")

	_expect(main.game_state.is_q010_complete(), "collecting three Q010 seeds must complete the task")
	_expect(not main._should_show_q010_task_card(), "the completed seed card must leave the screen when the path task becomes active")
	_expect(not main._should_show_q009_task_card(), "the old birdhouse card must leave the screen when the path task becomes active")
	_expect(main.message == "种子收藏完成！植物外观已解锁。", "Q010 completion must show direct feedback")
	_expect(main._q010_prompt_text() == "种子收藏完成！植物外观已解锁。", "Q010 completion prompt must be visible")
	_expect(main._q010_action_hint_text() == "可选：回乌龟花园看看新花。", "Q010 must label the garden visit as optional")
	_expect(_read_save().get("q010_seeds_collected") == [true, true, true], "Q010 completion must save immediately")

	main.player_position = main.Q010_SEED_POSITIONS[0]
	_press_interact()
	_expect(main.game_state.q010_seed_count() == 3, "repeated Q010 interaction must not change progress")
	_expect(main.game_state.is_q010_complete(), "repeated Q010 interaction must not undo completion")

	main._restart_game()
	_expect(not main.game_state.q010_seeds_collected.has(true), "restart must clear Q010 seeds")
	_expect(not main.game_state.is_q010_complete(), "restart must lock Q010 completion")
	main.queue_free()
	await process_frame
	_finish()


func _complete_q005_runtime() -> void:
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
	main.game_state.deliver_q005_harvest()
	main._save_game()


func _press_interact() -> void:
	main._try_collect_nearby()


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
	push_error("[Q010RuntimeTest] " + message)


func _finish() -> void:
	if failures == 0:
		print("[Q010RuntimeTest] PASS")
	else:
		push_error("[Q010RuntimeTest] FAIL: %d assertions" % failures)
	quit(failures)
