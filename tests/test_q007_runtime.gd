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
		_fail("Q007 runtime test requires --test-save-path")
		_finish()
		return
	var scene := load("res://scenes/boot/Main.tscn")
	main = scene.instantiate()
	root.add_child(main)
	await process_frame
	_expect(main.get("save_path") == save_path, "Q007 runtime must use the isolated save path")
	main._restart_game()
	_complete_q003_runtime()
	_expect(main.game_state.can_start_q007(), "opening the pond must unlock Q007 at runtime")
	_expect(main.game_state.is_q004_complete(), "the main story must complete the fox house before side tasks appear")
	_expect(main.game_state.is_q005_complete(), "the main story must complete the pond garden before side tasks appear")
	_expect(not main.game_state.is_q006_complete(), "Q007 must wait for the garden decorations")
	_expect(not main._can_use_q007_side_task(), "Q007 must stay hidden until Q006 is complete")
	_expect(not main._can_use_q009_side_task(), "Q009 must stay hidden until Q007 is complete")
	_expect(main._task_prompt_text() == "下一步：布置花园装饰（0/3）。", "the main story prompt must lead into optional content")

	main.player_position = Vector2(700, 500)
	main._try_collect_nearby()
	_expect(not main.game_state.q007_shell_collected, "the shell must not collect outside the interaction radius")

	main.player_position = main.Q007_SHELL_POSITION
	main._try_collect_nearby()
	_expect(not main.game_state.q007_shell_collected, "the shell must remain unavailable before Q006 is complete")

	for decor_id in range(3):
		_expect(main.game_state.place_q006_decoration(decor_id, decor_id), "completing Q006 must enable each decoration")
	main._save_game()
	_expect(not main._can_use_q007_side_task(), "the shell task must stay hidden until the main ending")
	_expect(main._task_prompt_text() == "花园装饰已完成！回到兔子身边参加小岛庆祝。", "Q006 completion must guide the player to the ending")
	main.player_position = main.Q012_RABBIT_POSITION
	main._try_collect_nearby()
	_expect(main.game_state.is_q012_complete(), "the rabbit interaction must finish the main story")
	_expect(main._can_use_q007_side_task(), "the main ending must unlock optional shell exploration")
	_expect(main._task_stage_label() == "可选 1/5", "the first post-ending task must start the separate optional-task track")
	_expect(main._task_prompt_text() == "主线故事完成！可选支线：到池塘边寻找隐藏贝壳。", "Q007 must be labeled optional after the ending")

	main.player_position = main.Q007_SHELL_POSITION

	main._try_collect_nearby()
	_expect(main.game_state.q007_shell_collected, "runtime interaction must collect the shell")
	_expect(main.game_state.is_q007_complete(), "runtime shell interaction must complete Q007")
	_expect(main.game_state.q007_reward_unlocked, "runtime shell interaction must unlock the reward")
	_expect(main.message == "隐藏的贝壳完成！获得珍珠贝壳摆件。", "runtime completion feedback must name the reward")
	_expect(_read_save().get("q007_reward_unlocked") == true, "runtime completion must save the reward immediately")

	main._try_collect_nearby()
	_expect(main.game_state.q007_shell_collected, "repeated runtime interaction must not undo shell collection")
	_expect(main.game_state.q007_completed, "repeated runtime interaction must not undo completion")
	_expect(main.game_state.q007_reward_unlocked, "repeated runtime interaction must not undo the reward")

	main._restart_game()
	_expect(not main.game_state.q007_shell_collected, "restart must reset Q007 shell collection")
	_expect(not main.game_state.q007_completed, "restart must reset Q007 completion")
	_expect(not main.game_state.q007_reward_unlocked, "restart must reset Q007 reward")
	main.queue_free()
	await process_frame
	_finish()


func _complete_q003_runtime() -> void:
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
	push_error("[Q007RuntimeTest] " + message)


func _finish() -> void:
	if failures == 0:
		print("[Q007RuntimeTest] PASS")
	else:
		push_error("[Q007RuntimeTest] FAIL: %d assertions" % failures)
	quit(failures)
