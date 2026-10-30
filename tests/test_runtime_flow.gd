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
	var animation_time_before: float = main.animation_time
	main._physics_process(0.1)
	_expect(main.animation_time > animation_time_before, "character animation time must advance with the game loop")
	_expect(not main.game_state.is_complete(), "a new runtime flow must start before bridge completion")
	_expect(not main.game_state.seed_collected, "a new runtime flow must not have the seed")
	_expect(not main.game_state.can_start_pond_task(), "pond task must be locked at the start")
	_expect(main._task_stage_label() == "主线 1/7", "the HUD must identify the first of seven connected main-story steps")
	_expect(main._should_show_rabbit_area(), "the rabbit must be visible while it introduces the first task")
	_expect(is_equal_approx(main.camera_zoom, 1.0), "a new game must open in the full-map view")
	_expect(main._is_button_control_position(main.zoom_in_button.position + main.zoom_in_button.size / 2.0), "zoom controls must capture taps instead of starting a world drag")
	var zoom_anchor := Vector2(820, 360)
	var world_anchor: Vector2 = main._screen_to_world(zoom_anchor)
	main._change_camera_zoom(1.35, zoom_anchor)
	_expect(main._world_to_screen(world_anchor).distance_to(zoom_anchor) < 0.01, "zooming at a point must keep that map point under the pointer")
	var center_before_pan: Vector2 = main.camera_center
	main.camera_pan_last_screen = Vector2(640, 360)
	main._update_camera_pan(Vector2(700, 390))
	_expect(main.camera_center != center_before_pan, "dragging the zoomed map must move its camera center")
	main._reset_camera()
	_expect(main.camera_zoom == 1.0 and main.camera_center == main.WORLD_SIZE * 0.5, "the full-map control must restore the complete island view")
	_expect(main.interact_button.position == Vector2(1156, 616), "the interaction control must sit in the bottom-right thumb zone")
	_expect(main.interact_button.size == Vector2(116, 92), "the bottom-right interaction control must be large enough for touch")
	_expect(not main.INVENTORY_PANEL_RECT.intersects(Rect2(main.interact_button.position, main.interact_button.size)), "the interaction control must not overlap the inventory tray")
	_expect(main.INVENTORY_PANEL_RECT.position.x >= 880, "the inventory tray must stay clear of the bottom instruction banner")
	_expect(main._inventory_rect(2).end.x <= main.INVENTORY_PANEL_RECT.end.x, "the last inventory slot must remain inside the tray")
	_expect(main._is_button_control_position(main.interact_button.position + main.interact_button.size / 2.0), "the moved interaction button must not leak clicks into world dragging")
	_expect(main.Q011_AREA_RECT.end.x < main.HOUSE_RECT.position.x, "the extra-plot area must not overlap the fox house")
	_mouse_button(main.JOYSTICK_CENTER, true)
	_expect(main.virtual_joystick_active, "pressing the round joystick must capture the mouse pointer")
	_mouse_motion(main.JOYSTICK_CENTER + Vector2(0, -100))
	_expect(main.touch_direction.y < -0.99 and absf(main.touch_direction.x) < 0.01, "dragging the joystick upward must produce upward movement")
	_expect(is_equal_approx(main.virtual_joystick_offset.length(), main.JOYSTICK_RADIUS), "the joystick knob must stay inside its circular travel range")
	_mouse_button(main.JOYSTICK_CENTER + Vector2(0, -100), false)
	_expect(not main.virtual_joystick_active and main.touch_direction == Vector2.ZERO, "releasing the joystick must stop movement")
	var touch_down := InputEventScreenTouch.new()
	touch_down.index = 3
	touch_down.position = main.JOYSTICK_CENTER
	touch_down.pressed = true
	main._input(touch_down)
	var other_finger := InputEventScreenDrag.new()
	other_finger.index = 4
	other_finger.position = main.JOYSTICK_CENTER + Vector2.RIGHT * main.JOYSTICK_RADIUS
	main._input(other_finger)
	_expect(main.touch_direction == Vector2.ZERO, "a second finger must not steer the active joystick")
	var touch_drag := InputEventScreenDrag.new()
	touch_drag.index = 3
	touch_drag.position = main.JOYSTICK_CENTER + Vector2.RIGHT * main.JOYSTICK_RADIUS
	main._input(touch_drag)
	_expect(main.touch_direction.x > 0.99 and absf(main.touch_direction.y) < 0.01, "the captured finger must steer the joystick in any direction")
	var touch_up := InputEventScreenTouch.new()
	touch_up.index = 3
	touch_up.position = touch_drag.position
	touch_up.pressed = false
	main._input(touch_up)
	_expect(not main.virtual_joystick_active and main.touch_direction == Vector2.ZERO, "lifting the steering finger must release the joystick")
	main.touch_direction = Vector2.RIGHT
	main._physics_process(0.1)
	_expect(main.player_is_moving and main.player_walk_phase > 0.0, "moving with the virtual stick must advance the walk cycle")
	main.touch_direction = Vector2.ZERO
	main.player_position = Vector2(250, 500)

	# Q001: collect all boards through the proximity interaction path.
	main.player_position = main.SEED_POSITION
	main._try_collect_nearby()
	_expect(not main.game_state.seed_collected, "seed interaction must be locked before bridge repair")
	main._pointer_down(main.POND_STONE_POSITIONS[0])
	_expect(main.dragging_pond_stone == -1, "pond stones must be locked before Q002")

	for board_id in range(3):
		main.player_position = main.BOARD_POSITIONS[board_id]
		main._update_interact_button()
		_expect(main.interact_button.text == "收木板" and main.interaction_button_ready, "the touch action must name a nearby board and show that it is in range")
		main._try_collect_nearby()
		_expect(main.game_state.collected[board_id], "runtime proximity interaction must collect each board")
		_expect(main.collect_sparkle_remaining > 0.0, "collecting a board must show the short sparkle feedback")

	_expect(main.game_state.board_count() == 3, "runtime flow must collect all three boards")
	main._update_interact_button()
	_expect(not main.interact_button.visible, "the interaction button must get out of the way while the player drags boards")

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
	_expect(main.bridge_repair_remaining > 0.0, "repairing the bridge must trigger its finishing shimmer")
	_expect(main._task_stage_label() == "主线 2/7", "repairing the bridge must advance the visible main-story step")
	_expect(main._is_walkable(Vector2(800, 375)), "the repaired bridge must be walkable")
	_expect(main.game_state.area_unlocked, "bridge completion must unlock the right area")
	_expect(main.game_state.can_start_q008(), "the optional path task may be staged after the main story")
	_expect(not main._can_use_q008_side_task(), "optional path stones must stay hidden during the bridge and seed introduction")

	# Q002: use the actual proximity interaction path for seed and flowerbed.
	main.player_position = main.SEED_POSITION
	main._update_interact_button()
	_expect(main.interact_button.text == "收种子" and main.interaction_button_ready, "the touch action must name the nearby seed")
	main._try_collect_nearby()
	_expect(main.game_state.seed_collected, "runtime interaction must collect the seed after bridge repair")
	_expect(not main.game_state.seed_planted, "collecting the seed must not plant it immediately")
	main._try_collect_nearby()
	_expect(main.game_state.seed_collected, "repeated seed interaction must be idempotent")
	main.player_position = main.FLOWERBED_POSITION
	main._update_interact_button()
	_expect(main.interact_button.text == "种下" and main.interaction_button_ready, "the touch action must name planting at the flowerbed")
	main._try_collect_nearby()
	_expect(main.game_state.seed_planted, "runtime interaction at the flowerbed must plant the seed")
	_expect(main._should_show_rabbit_dialog(), "the rabbit must guide the player into the fox task after planting")
	_expect(main._rabbit_feedback_text().contains("狐狸") and main._rabbit_feedback_text().contains("木材"), "the rabbit must name the next wood-gathering objective")
	_expect(main._should_show_rabbit_area(), "the rabbit must remain visible while guiding the fox task")
	_expect(not main._can_start_pond_stage(), "the pond task must wait until the fox house is complete")
	_expect(not main._can_use_q006_build_mode(), "garden decorations must stay hidden during the main introduction")
	_expect(not main.build_button.visible, "the build button must stay hidden until the main story is complete")
	_expect(main._task_prompt_text() == "任务：帮狐狸建小屋。先收集 3 份木材。", "planting must lead directly to the fox house task")
	_expect(main._task_stage_label() == "主线 3/7", "planting the seed must advance to the fox-house step")

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
	_expect(not main._should_show_rabbit_area(), "the idle rabbit must leave during pond and garden tasks")
	_expect(main._can_start_pond_stage(), "the pond stage must unlock after the fox house is complete")
	_expect(main._task_stage_label() == "主线 4/7", "the completed fox house must advance to pond repair")
	_expect(main._task_prompt_text() == "狐狸入住了！池塘石头已摆放 0/3。", "the pond step must show concrete placement progress")

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
	_expect(main._task_prompt_text() == "乌龟花园：先浇水，再采收 3 朵花（0/3）。", "pond completion must unlock the Q005 task prompt")
	_expect(main._task_stage_label() == "主线 5/7", "pond completion must advance to the turtle-garden step")
	_expect(main._task_action_hint_text() == "先到花圃旁的浇水点，按 E 或点右下角“浇水”。", "pond completion must identify watering as the one current action")
	_expect(main._hud_title_text() == "奇趣小岛 · 乌龟花园任务", "pond completion must update the HUD title for Q005")

	_mouse_button(stone_0, true)
	_expect(main.dragging_pond_stone == -1, "a placed pond stone must not be draggable again")

	main.player_position = main.Q005_WATERING_POINT_POSITION
	main._update_interact_button()
	_expect(main.interact_button.text == "浇水" and main.interaction_button_ready, "the touch action must identify watering as the current garden action")
	main._try_collect_nearby()
	_expect(main.game_state.q005_watered, "the connected flow must water the turtle garden")
	_expect(main._task_action_hint_text().contains("逐株走近花苗") and main._task_action_hint_text().contains("采收 3 朵花"), "watering must advance the guidance to flower collection")
	for plant_id in range(3):
		main.player_position = main.Q005_PLANT_POSITIONS[plant_id]
		main._update_interact_button()
		_expect(main.interact_button.text == "采花" and main.interaction_button_ready, "watering must change the nearby touch action to flower collection")
		main._try_collect_nearby()
		_expect(main.game_state.q005_plants_collected[plant_id] and main.game_state.q005_plant_slots[plant_id], "the connected flow must harvest flowers while leaving the garden planted")
		if plant_id == 0:
			_expect(main._task_action_hint_text().contains("逐株走近花苗"), "partial flower collection must keep collection as the current action")
	_expect(main._task_action_hint_text().contains("回到乌龟身边") and main._task_action_hint_text().contains("送花"), "collecting all flowers must lead to one clear delivery interaction")
	_expect(not main.game_state.is_q005_complete(), "a full basket must still wait for the turtle interaction")
	main.player_position = main.Q005_TURTLE_POSITION
	main._update_interact_button()
	_expect(main.interact_button.text == "送花" and main.interaction_button_ready, "the turtle must expose bouquet delivery when approached")
	main._try_collect_nearby()
	_expect(main.game_state.q005_harvest_delivered and main.game_state.is_q005_complete(), "the turtle interaction must complete the connected garden task")

	var saved: Variant = _read_save()
	_expect(saved is Dictionary, "runtime interactions must create a JSON save")
	_expect(saved.get("pond_stones_placed") == [true, true, true], "runtime completion must be saved immediately")
	_expect(saved.get("pond_opened") == true, "runtime pond completion must be saved immediately")
	_expect(main.game_state.is_q005_complete(), "the connected core flow must complete the turtle garden")
	_expect(main._task_stage_label() == "主线 6/7", "the restored turtle garden must advance to decoration")
	_expect(main._task_prompt_text() == "下一步：布置花园装饰（0/3）。", "the turtle garden must lead directly to the final decoration task")
	_expect(main.build_button.visible and main.build_button.text == "开始布置", "the next main-story action must be visible on the build button")

	# Q006 → Q012: continue the same fresh runtime through the ending.
	main._toggle_build_mode()
	_expect(main.build_mode, "the final main-story task must enter decoration mode")
	var decor_positions := [Vector2(950, 230), Vector2(1040, 174), Vector2(1110, 215)]
	_mouse_button(_center(main._q006_decor_inventory_rect(0)), true)
	_mouse_motion(main.Q005_PLANT_POSITIONS[0])
	_expect(not main._q006_decor_drop_is_valid(0, main.Q005_PLANT_POSITIONS[0]), "free placement must still prevent stacking decor on a planted flower")
	_mouse_button(main.Q005_PLANT_POSITIONS[0], false)
	_expect(main.game_state.q006_decor_inventory[0], "an obstructed decoration drop must remain in the tray")
	for decor_id in range(3):
		_mouse_button(_center(main._q006_decor_inventory_rect(decor_id)), true)
		_mouse_motion(decor_positions[decor_id])
		_expect(main._q006_decor_drop_is_valid(decor_id, decor_positions[decor_id]), "an open garden patch must accept a free decoration drop")
		_mouse_button(decor_positions[decor_id], false)
		_expect(main.game_state.q006_decor_placed[decor_id] and main.game_state.q006_decor_positions[decor_id] == decor_positions[decor_id], "the connected flow must preserve every chosen garden position")
	_expect(main.game_state.is_q006_complete(), "three decorations must complete the final garden task")
	_expect(not main.build_mode, "completing the garden must close decoration mode")
	_expect(main.game_state.can_start_q012(), "the completed garden must unlock the rabbit celebration")
	_expect(main._should_show_rabbit_area(), "the rabbit must return for the final celebration objective")
	_expect(main._task_stage_label() == "主线 7/7", "finishing decorations must identify the final main-story step")
	_expect(main._task_prompt_text() == "最后一步：走到兔子身边，点右下角“庆祝”。", "the garden must direct the player to the rabbit celebration")
	_expect(main._task_action_hint_text().contains("这是主线最后一步"), "the ending prompt must explain that this interaction finishes the story")
	_expect(main.interact_button.text == "庆祝", "the touch action must name the final celebration")
	_expect(not main._can_use_q007_side_task(), "optional exploration must remain locked before the ending interaction")
	main.player_position = main.Q012_RABBIT_POSITION
	main._try_collect_nearby()
	_expect(main.game_state.is_q012_complete(), "the rabbit interaction must finish the connected main story")
	_expect(main.celebration_remaining > 0.0, "finishing the story must trigger the celebration animation")
	_expect(main.task_transition_remaining > 0.0, "the final objective must trigger a transition animation")
	main.celebration_remaining = 0.0
	main._update_interact_button()
	_expect(main._should_show_rabbit_area(), "the rabbit must remain as a companion after the celebration")
	_expect(_read_save().get("q012_completed") == true, "the connected main-story ending must save immediately")
	_expect(main._can_use_q007_side_task(), "finishing the story must unlock optional exploration")
	_expect(main._task_stage_label() == "可选 1/5", "the ending must begin a clearly separate optional-task track")
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
