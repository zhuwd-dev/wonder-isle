extends SceneTree

var failures := 0
var test_save_path := ""


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	for index in range(max(args.size() - 1, 0)):
		if str(args[index]) == "--test-save-path":
			test_save_path = str(args[index + 1])
			break
	call_deferred("_run")


func _run() -> void:
	if test_save_path.is_empty():
		_fail("碰撞测试必须提供 --test-save-path，禁止写入正式存档")
		_finish()
		return
	var main_scene = load("res://scenes/boot/Main.tscn")
	var main = main_scene.instantiate()
	root.add_child(main)
	await process_frame
	_expect(main.get("save_path") == test_save_path, "碰撞测试必须使用专用存档路径")
	main.game_state.reset()
	_expect(main.VISUAL_PALETTE.has("island_grass"), "视觉调色板应提供岛屿草地颜色")
	_expect(main.VISUAL_PALETTE["bridge_damaged"] != main.VISUAL_PALETTE["bridge_repaired"], "桥的损坏态和修复态应有不同颜色")
	_expect(main.VISUAL_PALETTE["target_valid"] != main.VISUAL_PALETTE["target_idle"], "放置目标的有效态和普通态应有不同颜色")
	_expect(main._task_prompt_text() == "任务：帮助兔子修好小桥。先收集 3 块木板。", "初始状态应显示修桥任务引导")
	_expect(not main._is_walkable(Vector2(710, 375)), "unrepaired bridge must block the left approach")
	_expect(not main._is_walkable(Vector2(800, 375)), "unrepaired bridge must block the river")
	var inventory_center: Vector2 = main._inventory_rect(0).position + main._inventory_rect(0).size / 2.0
	var slot_center: Vector2 = main.BRIDGE_SLOTS[0].position + main.BRIDGE_SLOTS[0].size / 2.0
	main._pointer_down(inventory_center)
	_expect(main.dragging_board == -1, "an uncollected board must not be draggable")
	main.game_state.collect_board(0)
	_expect(main._task_prompt_text() == "已收集 1/3 块木板，还要 2 块。", "收集一块后应引导继续收集")
	main._pointer_down(inventory_center)
	_expect(main.dragging_board == 0, "one collected board must be draggable")
	_expect(main._drag_target_slot_at(slot_center) == 0, "the matching slot must be the active drag target")
	_expect(main._drag_target_slot_at(Vector2(600, 400)) == -1, "an unrelated position must not be a drag target")
	main._pointer_up(Vector2(600, 400))
	_expect(main.dragging_board == -1, "invalid release must clear drag state")
	_expect(not main.game_state.placed[0], "invalid release must not place the board")
	main._pointer_down(inventory_center)
	main._pointer_up(slot_center)
	_expect(main.game_state.placed[0], "valid release must place a collected board")
	_expect(not main.game_state.is_complete(), "placing one board must not complete the bridge")
	main.game_state.collect_board(1)
	_expect(main._task_prompt_text() == "已收集 2/3 块，还要 1 块；已放置 1/3 块。", "收集两块后应同时显示收集和放置进度")
	var inventory_center_1: Vector2 = main._inventory_rect(1).position + main._inventory_rect(1).size / 2.0
	var slot_center_1: Vector2 = main.BRIDGE_SLOTS[1].position + main.BRIDGE_SLOTS[1].size / 2.0
	main._pointer_down(inventory_center_1)
	_expect(main.dragging_board == 1, "the second collected board must be independently draggable")
	main._pointer_up(slot_center_1)
	_expect(main.game_state.placed[1], "the second board must be placeable before the third is collected")
	_expect(not main.game_state.is_complete(), "placing two boards must not complete the bridge")
	main.game_state.collect_board(2)
	_expect(main._task_prompt_text() == "木板已集齐，已放置 2/3 块；把剩余木板拖到桥面高亮位置。", "收集三块后应进入放置引导")
	var inventory_center_2: Vector2 = main._inventory_rect(2).position + main._inventory_rect(2).size / 2.0
	var slot_center_2: Vector2 = main.BRIDGE_SLOTS[2].position + main.BRIDGE_SLOTS[2].size / 2.0
	var touch_down := InputEventScreenTouch.new()
	touch_down.position = inventory_center_2
	touch_down.pressed = true
	main._input(touch_down)
	_expect(main.dragging_board == 2, "the third collected board must be draggable immediately")
	var touch_drag := InputEventScreenDrag.new()
	touch_drag.position = slot_center_2
	main._input(touch_drag)
	var touch_up := InputEventScreenTouch.new()
	touch_up.position = slot_center_2
	touch_up.pressed = false
	main._input(touch_up)
	_expect(main.game_state.placed[2], "the third board must support touch placement")
	_expect(main._drag_target_slot_at(slot_center_2) == -1, "placed board must no longer have an active target")
	_expect(main.game_state.is_complete(), "placing the third board must complete the bridge")
	_expect(main._task_prompt_text() == "小桥已修好！到右侧寻找种子并种下。", "完成修桥后应引导后续种子任务")
	_expect(main._task_action_hint_text() == "过桥后到右侧寻找闪亮的种子，靠近后按互动键收集。", "完成修桥后应显示种子互动提示")
	main.player_position = main.SEED_POSITION
	main._try_collect_nearby()
	_expect(main.game_state.seed_collected, "修桥后靠近种子应能收集")
	_expect(not main.game_state.seed_planted, "收集种子后不应立即完成种植")
	_expect(main._task_prompt_text() == "种子已找到，请到右侧花圃种下。", "收集种子后应引导前往花圃")
	main._try_collect_nearby()
	_expect(main.game_state.seed_collected, "重复互动不能取消种子收集")
	main.player_position = Vector2(600, 400)
	main._try_collect_nearby()
	_expect(not main.game_state.seed_planted, "不在花圃范围内不能种植")
	main._pointer_down(main.POND_STONE_POSITIONS[0])
	_expect(main.dragging_pond_stone == -1, "种植前不能拖动池塘石头")
	main.player_position = main.FLOWERBED_POSITION
	main._try_collect_nearby()
	_expect(main.game_state.seed_planted, "在花圃范围内应能种植")
	_expect(main._task_prompt_text() == "任务：帮狐狸建小屋。先收集 3 份木材。", "种植完成后应引导狐狸小屋任务")
	_expect(main._task_action_hint_text() == "靠近木材后按 E 或点击互动 / 收集来拾取。", "种植完成后应显示木材收集提示")
	main._try_collect_nearby()
	_expect(main.game_state.seed_planted, "重复互动不能重复改变种植状态")
	main._pointer_down(main.POND_STONE_POSITIONS[0])
	_expect(main.dragging_pond_stone == -1, "池塘石头应等狐狸小屋完成后再开放")
	for wood_id in range(3):
		main.player_position = main.WOOD_POSITIONS[wood_id]
		main._try_collect_nearby()
		_expect(main.game_state.wood_collected[wood_id], "狐狸小屋任务应能收集木材")
	main.player_position = main.HOUSE_POSITION
	for delivery_id in range(3):
		main._try_collect_nearby()
	_expect(main.game_state.is_q004_complete(), "交付三份木材后狐狸应入住")
	_expect(main._can_start_pond_stage(), "狐狸入住后池塘任务应开放")
	var pond_slot_0: Vector2 = main.POND_SLOTS[0].position + main.POND_SLOTS[0].size / 2.0
	main._pointer_down(main.POND_STONE_POSITIONS[0])
	_expect(main.dragging_pond_stone == 0, "种植完成后第 1 块石头应能拖动")
	main._pointer_up(Vector2(600, 400))
	_expect(main.dragging_pond_stone == -1, "石头无效释放后应清除拖拽状态")
	_expect(not main.game_state.pond_stones_placed[0], "石头无效释放不能改变放置状态")
	main._pointer_down(main.POND_STONE_POSITIONS[0])
	main._pointer_up(pond_slot_0)
	_expect(main.game_state.pond_stones_placed[0], "第 1 块石头应能放入对应轮廓")
	var pond_slot_1: Vector2 = main.POND_SLOTS[1].position + main.POND_SLOTS[1].size / 2.0
	main._pointer_down(main.POND_STONE_POSITIONS[1])
	main._pointer_up(pond_slot_1)
	_expect(main.game_state.pond_stones_placed[1], "第 2 块石头应能独立放入对应轮廓")
	var touch_stone_down := InputEventScreenTouch.new()
	touch_stone_down.position = main.POND_STONE_POSITIONS[2]
	touch_stone_down.pressed = true
	main._input(touch_stone_down)
	_expect(main.dragging_pond_stone == 2, "第 3 块石头应支持触屏拖拽")
	var pond_slot_2: Vector2 = main.POND_SLOTS[2].position + main.POND_SLOTS[2].size / 2.0
	var touch_stone_drag := InputEventScreenDrag.new()
	touch_stone_drag.position = pond_slot_2
	main._input(touch_stone_drag)
	var touch_stone_up := InputEventScreenTouch.new()
	touch_stone_up.position = pond_slot_2
	touch_stone_up.pressed = false
	main._input(touch_stone_up)
	_expect(main.game_state.pond_stones_placed[2], "第 3 块石头应支持触屏放置")
	_expect(main.game_state.is_pond_complete(), "3 块石头放置后应开放池塘")
	_expect(main._task_prompt_text() == "任务：照料乌龟的花园。先浇水并收集 3 株植物。", "池塘完成后应开启 Q005")
	_expect(main._task_action_hint_text() == "靠近浇水点按互动；也可以先收集花园里的植物。", "池塘完成后应显示 Q005 操作提示")
	main._pointer_down(inventory_center_2)
	_expect(main.dragging_board == -1, "a placed board must not be draggable again")
	main.game_state.reset()
	main.game_state.collect_board(0)
	main._pointer_down(inventory_center)
	_expect(main.dragging_board == 0, "a reset board must be draggable again")
	main._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	_expect(main.dragging_board == -1, "window focus loss must cancel an active drag")
	main.game_state.reset()
	for board_id in range(3):
		main.game_state.collect_board(board_id)
	for board_id in range(3):
		main.game_state.place_board(board_id, board_id)
	_expect(main.game_state.is_complete(), "the third placed board must complete the quest")
	_expect(main._bridge_status_text() == "小桥已修好", "bridge completion text must update")
	_expect(main._rabbit_feedback_text() == "兔子：谢谢你！小桥修好了！", "rabbit completion feedback must update")
	_expect(main._is_walkable(Vector2(710, 375)), "repaired bridge must allow the left approach")
	_expect(main._is_walkable(Vector2(720, 375)), "repaired bridge must allow the river entry")
	_expect(main._is_walkable(Vector2(778, 375)), "修复后玩家应能进入桥面")
	_expect(main._is_walkable(Vector2(900, 375)), "修复后玩家应能从桥面走到右侧区域")
	_expect(main._is_walkable(Vector2(920, 375)), "repaired bridge must allow the right exit")
	_expect(not main._is_walkable(Vector2(800, 300)), "repaired bridge must not allow crossing above the bridge")
	_expect(not main._is_walkable(Vector2(800, 450)), "repaired bridge must not allow crossing below the bridge")
	main.queue_free()
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	failures += 1
	push_error("[GrayboxCollisionTest] " + message)


func _finish() -> void:
	if failures == 0:
		print("[GrayboxCollisionTest] PASS")
	else:
		push_error("[GrayboxCollisionTest] FAIL: %d 个断言失败" % failures)
	quit(failures)
