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
		_fail("runtime flow test requires --test-save-path")
		_finish()
		return

	var scene := load("res://scenes/boot/Main.tscn")
	main = scene.instantiate()
	root.add_child(main)
	await process_frame
	_expect(main.get("save_path") == save_path, "runtime flow must use the isolated save path")

	main._restart_game()
	_expect(not main.game_state.is_complete(), "a new runtime flow must start before bridge completion")
	_expect(not main.game_state.seed_collected, "a new runtime flow must not have the seed")
	_expect(not main.game_state.can_start_pond_task(), "pond task must be locked at the start")

	# Q001: collect all boards through the proximity interaction path.
	main.player_position = main.SEED_POSITION
	main._try_collect_nearby()
	_expect(not main.game_state.seed_collected, "seed interaction must be locked before bridge repair")
	main._pointer_down(main.POND_STONE_POSITIONS[0])
	_expect(main.dragging_pond_stone == -1, "pond stones must be locked before Q002")

	for board_id in range(3):
		main.player_position = main.BOARD_POSITIONS[board_id]
		main._try_collect_nearby()
		_expect(main.game_state.collected[board_id], "runtime proximity interaction must collect each board")

	_expect(main.game_state.board_count() == 3, "runtime flow must collect all three boards")

	# Q001: exercise actual mouse button, motion, and release events.
	var first_inventory := _center(main._inventory_rect(0))
	var first_slot := _center(main.BRIDGE_SLOTS[0])
	_mouse_button(first_inventory, true)
	_mouse_motion(Vector2(600, 400))
	_mouse_button(Vector2(600, 400), false)
	_expect(not main.game_state.placed[0], "an invalid board release must not consume the board")
	_mouse_button(first_inventory, true)
	_mouse_motion(first_slot)
	_mouse_button(first_slot, false)
	_expect(main.game_state.placed[0], "a valid mouse board drop must place the first board")

	for board_id in range(1, 3):
		_mouse_button(_center(main._inventory_rect(board_id)), true)
		_mouse_motion(_center(main.BRIDGE_SLOTS[board_id]))
		_mouse_button(_center(main.BRIDGE_SLOTS[board_id]), false)
		_expect(main.game_state.placed[board_id], "a valid mouse board drop must place each remaining board")

	_expect(main.game_state.is_complete(), "the bridge must repair after three runtime board drops")
	_expect(main._is_walkable(Vector2(800, 375)), "the repaired bridge must be walkable")
	_expect(main.game_state.area_unlocked, "bridge completion must unlock the right area")
	_expect(main.game_state.can_start_q008(), "the optional path task may be staged after the main story")
	_expect(not main._can_use_q008_side_task(), "optional path stones must stay hidden during the bridge and seed introduction")

	# Q002: use the actual proximity interaction path for seed and flowerbed.
	main.player_position = main.SEED_POSITION
	main._try_collect_nearby()
	_expect(main.game_state.seed_collected, "runtime interaction must collect the seed after bridge repair")
	_expect(not main.game_state.seed_planted, "collecting the seed must not plant it immediately")
	main._try_collect_nearby()
	_expect(main.game_state.seed_collected, "repeated seed interaction must be idempotent")
	main.player_position = main.FLOWERBED_POSITION
	main._try_collect_nearby()
	_expect(main.game_state.seed_planted, "runtime interaction at the flowerbed must plant the seed")
	_expect(main._should_show_rabbit_dialog(), "the rabbit must guide the player into the fox task after planting")
	_expect(main._rabbit_feedback_text().contains("狐狸") and main._rabbit_feedback_text().contains("木材"), "the rabbit must name the next wood-gathering objective")
	_expect(not main._can_start_pond_stage(), "the pond task must wait until the fox house is complete")
	_expect(not main._can_use_q006_build_mode(), "garden decorations must stay hidden during the main introduction")
	_expect(not main.build_button.visible, "the build button must stay hidden until the main story is complete")
	_expect(main._task_prompt_text() == "任务：帮狐狸建小屋。先收集 3 份木材。", "planting must lead directly to the fox house task")

	# Complete the fox house before revealing the pond stones.
	for wood_id in range(3):
		main.player_position = main.WOOD_POSITIONS[wood_id]
		main._try_collect_nearby()
		_expect(main.game_state.wood_collected[wood_id], "the fox task must collect wood through runtime interaction")
	main.player_position = main.HOUSE_POSITION
	for delivery_id in range(3):
		main._try_collect_nearby()
	_expect(main.game_state.is_q004_complete(), "three wood deliveries must finish the fox house before Q003")
	_expect(not main._should_show_rabbit_dialog(), "the fox guidance must clear when its task is finished")
	_expect(main._can_start_pond_stage(), "the pond stage must unlock after the fox house is complete")

	# Q003: mouse drag, invalid release, recovery, completion, and duplicate protection.
	var stone_0: Vector2 = main.POND_STONE_POSITIONS[0]
	var stone_1: Vector2 = main.POND_STONE_POSITIONS[1]
	var stone_2: Vector2 = main.POND_STONE_POSITIONS[2]
	var pond_slot_0: Vector2 = _center(main.POND_SLOTS[0])
	var pond_slot_1: Vector2 = _center(main.POND_SLOTS[1])
	var pond_slot_2: Vector2 = _center(main.POND_SLOTS[2])

	_mouse_button(stone_0, true)
	_expect(main.dragging_pond_stone == 0, "the first pond stone must enter mouse drag state")
	_mouse_motion(pond_slot_0)
	_mouse_button(pond_slot_0, false)
	_expect(main.game_state.pond_stones_placed == [true, false, false], "the first pond stone must be placed in its matching slot")

	_mouse_button(stone_1, true)
	_expect(main.dragging_pond_stone == 1, "the second pond stone must enter mouse drag state")
	_mouse_motion(Vector2(600, 400))
	_mouse_button(Vector2(600, 400), false)
	_expect(main.game_state.pond_stones_placed == [true, false, false], "an invalid pond release must not advance progress")
	_mouse_button(stone_1, true)
	_mouse_motion(pond_slot_1)
	_mouse_button(pond_slot_1, false)
	_expect(main.game_state.pond_stones_placed == [true, true, false], "the second pond stone must recover after an invalid release")

	_mouse_button(stone_2, true)
	_mouse_motion(pond_slot_2)
	_mouse_button(pond_slot_2, false)
	_expect(main.game_state.is_pond_complete(), "the third pond stone must open the pond")
	_expect(main.game_state.pond_opened, "pond completion must set the opened state")
	_expect(main.game_state.pond_stones_placed == [true, true, true], "pond completion must record all three stones")
	_expect(main._task_prompt_text() == "任务：照料乌龟的花园。先浇水并收集 3 株植物。", "pond completion must unlock the Q005 task prompt")
	_expect(main._task_action_hint_text() == "靠近浇水点按互动；也可以先收集花园里的植物。", "pond completion must show the Q005 action hint")
	_expect(main._hud_title_text() == "奇趣小岛 · 乌龟花园任务", "pond completion must update the HUD title for Q005")

	_mouse_button(stone_0, true)
	_expect(main.dragging_pond_stone == -1, "a placed pond stone must not be draggable again")

	main.player_position = main.Q005_WATERING_POINT_POSITION
	main._try_collect_nearby()
	_expect(main.game_state.q005_watered, "the connected flow must water the turtle garden")
	for plant_id in range(3):
		main.player_position = main.Q005_PLANT_POSITIONS[plant_id]
		main._try_collect_nearby()
		_expect(main.game_state.q005_plants_collected[plant_id], "the connected flow must collect every garden plant")
		_mouse_button(_center(main._q005_plant_inventory_rect(plant_id)), true)
		_mouse_motion(_center(main.Q005_PLANT_SLOTS[plant_id]))
		_mouse_button(_center(main.Q005_PLANT_SLOTS[plant_id]), false)
		_expect(main.game_state.q005_plant_slots[plant_id], "the connected flow must place every garden plant")

	var saved: Variant = _read_save()
	_expect(saved is Dictionary, "runtime interactions must create a JSON save")
	_expect(saved.get("pond_stones_placed") == [true, true, true], "runtime completion must be saved immediately")
	_expect(saved.get("pond_opened") == true, "runtime pond completion must be saved immediately")
	_expect(main.game_state.is_q005_complete(), "the connected core flow must complete the turtle garden")
	_expect(main._task_prompt_text() == "下一步：布置花园装饰（0/3）。", "the turtle garden must lead directly to the final decoration task")
	_expect(main.build_button.visible and main.build_button.text == "开始布置", "the next main-story action must be visible on the build button")

	# Q006 → Q012: continue the same fresh runtime through the ending.
	main._toggle_build_mode()
	_expect(main.build_mode, "the final main-story task must enter decoration mode")
	for decor_id in range(3):
		_mouse_button(_center(main._q006_decor_inventory_rect(decor_id)), true)
		_mouse_motion(_center(main.Q006_DECOR_SLOTS[decor_id]))
		_mouse_button(_center(main.Q006_DECOR_SLOTS[decor_id]), false)
		_expect(main.game_state.q006_decor_placed[decor_id], "the connected flow must place every garden decoration")
	_expect(main.game_state.is_q006_complete(), "three decorations must complete the final garden task")
	_expect(not main.build_mode, "completing the garden must close decoration mode")
	_expect(main.game_state.can_start_q012(), "the completed garden must unlock the rabbit celebration")
	_expect(main._task_prompt_text() == "花园装饰已完成！回到兔子身边参加小岛庆祝。", "the garden must direct the player to the rabbit")
	_expect(main._task_action_hint_text() == "走到兔子身边按 E 或点击“互动 / 收集”，和伙伴们一起庆祝。", "the ending prompt must explain how to finish the story")
	_expect(not main._can_use_q007_side_task(), "optional exploration must remain locked before the ending interaction")
	main.player_position = main.Q012_RABBIT_POSITION
	main._try_collect_nearby()
	_expect(main.game_state.is_q012_complete(), "the rabbit interaction must finish the connected main story")
	_expect(_read_save().get("q012_completed") == true, "the connected main-story ending must save immediately")
	_expect(main._can_use_q007_side_task(), "finishing the story must unlock optional exploration")
	_expect(main._task_prompt_text() == "主线故事完成！可选支线：到池塘边寻找隐藏贝壳。", "the post-ending prompt must label the next task optional")

	# Reset through the normal game entry point and verify all three task layers.
	main._restart_game()
	_expect(main.game_state.collected == [false, false, false], "restart must reset Q001 collection")
	_expect(main.game_state.placed == [false, false, false], "restart must reset Q001 placement")
	_expect(not main.game_state.is_complete(), "restart must reset bridge completion")
	_expect(not main.game_state.seed_collected and not main.game_state.seed_planted, "restart must reset Q002")
	_expect(main.game_state.pond_stones_placed == [false, false, false], "restart must reset Q003 stones")
	_expect(not main.game_state.pond_opened, "restart must close the pond")

	main.queue_free()
	await process_frame
	_finish()


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
	push_error("[RuntimeFlowTest] " + message)


func _finish() -> void:
	if failures == 0:
		print("[RuntimeFlowTest] PASS")
	else:
		push_error("[RuntimeFlowTest] FAIL: %d assertions" % failures)
	quit(failures)
