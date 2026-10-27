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
	_expect(main._task_prompt_text() == "乌龟花园：先浇水，再采收 3 朵花（0/3）。", "Q005 unlock prompt must show the order and current progress")

	for plant_id in range(3):
		main.player_position = main.Q005_PLANT_POSITIONS[plant_id]
		main._try_collect_nearby()
		_expect(not main.game_state.q005_plants_collected[plant_id], "Q005 plants must stay unavailable until watering")
		_expect(main.message == "先给花园浇水，植物长好后才能采集。", "early plant interaction must explain the required order")
	_expect(main._task_action_hint_text().contains("先到花圃旁的浇水点"), "the next-step hint must state that watering comes first")
	main.player_position = main.POND_RECT.get_center()
	main._update_interact_button()
	_expect(main.interact_button.text == "看池塘" and main.interaction_button_ready, "the pond must expose an explicit nearby interaction")
	main._try_collect_nearby()
	_expect(main.pond_ripple_remaining > 0.0 and main.message.contains("涟漪"), "pond interaction must visibly ripple and report the result")

	main.player_position = main.Q005_WATERING_POINT_POSITION
	main._update_interact_button()
	_expect(main.interact_button.text == "浇水" and main.interaction_button_ready, "the action button must name watering at the water point")
	main._try_collect_nearby()
	_expect(main.game_state.q005_watered, "watering point interaction must update runtime state")
	_expect(main.q005_growth_remaining > 0.0, "watering must trigger a visible seedling growth animation")
	_expect(main._task_action_hint_text().contains("逐株走近花苗") and main._task_action_hint_text().contains("采收 3 朵花"), "watering must advance the hint to flower collection")
	main._try_collect_nearby()
	_expect(main.game_state.q005_watered, "repeated watering must remain idempotent")
	for plant_id in range(3):
		main.player_position = main.Q005_PLANT_POSITIONS[plant_id]
		main._update_interact_button()
		_expect(main.interact_button.text == "采花" and main.interaction_button_ready, "the action button must identify the nearby ripe flower")
		main._try_collect_nearby()
		_expect(main.game_state.q005_plants_collected[plant_id], "watered Q005 plants must collect through runtime interaction")
		_expect(main.game_state.q005_plant_slots[plant_id], "harvest must leave the plant bed occupied without another drag")
		main._try_collect_nearby()
		_expect(main.q005_plant_count() == plant_id + 1, "repeated plant interaction must not duplicate collection")

	_expect(not main.game_state.is_q005_complete(), "harvesting three flowers must not skip the delivery interaction")
	_expect(main.dragging_q005_plant == -1, "the flower harvest must not create a redundant inventory drag")
	_expect(main._task_prompt_text().contains("花束已采齐"), "the complete harvest must direct the player to the turtle")
	main.player_position = main.Q005_TURTLE_POSITION + Vector2(200, 0)
	main._update_interact_button()
	_expect(main.interact_button.text == "找乌龟" and not main.interaction_button_ready, "the delivery control must direct the player toward the turtle")
	main._try_collect_nearby()
	_expect(not main.game_state.q005_harvest_delivered, "a distant interaction must not deliver the flowers")
	main.player_position = main.Q005_TURTLE_POSITION
	main._update_interact_button()
	_expect(main.interact_button.text == "送花" and main.interaction_button_ready, "the nearby turtle must expose the bouquet delivery action")
	main._try_collect_nearby()
	_expect(main.game_state.q005_harvest_delivered, "interacting beside the turtle must deliver the bouquet")
	_expect(main.game_state.is_q005_complete(), "watering, harvesting and delivering must complete Q005")
	_expect(main.task_transition_remaining > 0.0, "bouquet delivery must trigger a short task transition")
	_expect(main._task_prompt_text() == "下一步：布置花园装饰（0/3）。", "Q005 completion must clearly lead to the optional garden task")
	_expect(main._task_action_hint_text().contains("把剩余 3 件装饰拖到右侧自由摆放区"), "Q005 completion must explain the next action")
	_expect(main._hud_title_text() == "奇趣小岛 · 花园装饰任务", "Q005 completion must update the HUD title")
	_expect(main.build_button.visible, "the optional garden build button must unlock after the main story")
	_expect(main.build_button.text == "开始布置", "the current next action must be named directly on the build button")
	var build_style: StyleBox = main.build_button.get_theme_stylebox("normal")
	_expect(build_style is StyleBoxFlat and build_style.bg_color == Color("68bd72"), "the current next action button must use its green primary style")
	_expect(not main._should_show_q006_slots(), "empty garden slots must stay hidden outside build mode")
	_expect(not main._should_show_rabbit_dialog(), "the rabbit's seed guidance must end after the seed is planted")
	_expect(not main._should_show_region_access_card(), "the bridge access card must disappear after the area opens")
	_expect(not main._can_use_q007_side_task(), "Q007 must stay hidden while Q006 is the current task")
	_expect(not main._can_use_q009_side_task(), "Q009 must stay hidden while Q006 is the current task")
	_expect(not main._can_use_q010_side_task(), "Q010 must stay hidden while Q006 is the current task")
	_expect(not main._can_use_q008_side_task(), "Q008 must stay hidden while Q006 is the current task")
	_expect(not main._can_use_q011_mode(), "Q011 must stay hidden while Q006 is the current task")
	_expect(_read_save().get("q005_completed") == true, "Q005 completion must be saved immediately")
	_expect(_read_save().get("q005_harvest_delivered") == true, "bouquet delivery must be persisted")
	main._try_collect_nearby()
	_expect(main.message.contains("谢谢你把池塘和花园照料得这么好"), "the turtle must remain interactable after the main garden task")
	main.message = "临时反馈"
	main._tick_transient_message(4.1)
	_expect(main.message.is_empty(), "completion feedback must clear after its short display lifetime")

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
