extends Control

const GameState = preload("res://scripts/game/game_state.gd")
const UI_FONT = preload("res://assets/fonts/NotoSansCJKsc-GameSubset.otf")
const SAVE_PATH := "user://qxisland_stage2_save.json"
const WORLD_SIZE := Vector2(1280, 720)
const PLAYER_SPEED := 260.0
const PLAYER_RADIUS := 18.0
const COLLECTION_RADIUS := 72.0
const RIVER_RECT := Rect2(720, 110, 180, 530)
const BRIDGE_RECT := Rect2(760, 330, 120, 90)
# The walkable lane includes both bridge approaches, so the player's collision
# box can reach the bridge before it intersects the river.
const BRIDGE_PASSAGE_RECT := Rect2(702, 330, 216, 90)
const BOARD_POSITIONS := [Vector2(350, 250), Vector2(475, 500), Vector2(625, 555)]
const SEED_POSITION := Vector2(1010, 350)
const FLOWERBED_POSITION := Vector2(1080, 480)
const FLOWERBED_INTERACTION_RADIUS := 76.0
const POND_RECT := Rect2(936, 270, 190, 130)
const POND_STONE_POSITIONS := [Vector2(945, 470), Vector2(1170, 340), Vector2(1170, 520)]
const POND_SLOTS := [
	Rect2(970, 350, 40, 30),
	Rect2(1018, 350, 40, 30),
	Rect2(1066, 350, 40, 30),
]
const Q005_WATERING_POINT_POSITION := Vector2(976, 520)
const Q005_INTERACTION_RADIUS := 42.0
const Q005_PLANT_POSITIONS := [Vector2(1028, 480), Vector2(1080, 480), Vector2(1132, 480)]
const Q005_PLANT_SLOTS := [
	Rect2(1012, 466, 32, 28),
	Rect2(1064, 466, 32, 28),
	Rect2(1116, 466, 32, 28),
]
const Q005_GARDEN_RECT := Rect2(1000, 438, 160, 84)
const Q005_TURTLE_POSITION := Vector2(1160, 280)
const WOOD_POSITIONS := [Vector2(160, 330), Vector2(360, 400), Vector2(620, 540)]
const HOUSE_POSITION := Vector2(520, 500)
const HOUSE_INTERACTION_RADIUS := 88.0
const HOUSE_RECT := Rect2(448, 442, 144, 116)
const Q012_RABBIT_POSITION := Vector2(592, 226)
const Q006_DECOR_PLOT_RECT := Rect2(928, 544, 288, 30)
const Q006_DECOR_SLOTS := [
	Rect2(940, 547, 76, 24),
	Rect2(1034, 547, 76, 24),
	Rect2(1128, 547, 76, 24),
]
const Q006_DECOR_INVENTORY_ORIGIN := Vector2(928, 606)
const Q006_DECOR_INVENTORY_STEP := 96.0
const Q007_SHELL_POSITION := Vector2(930, 430)
const Q007_REWARD_POSITION := Vector2(930, 430)
const Q008_PATH_MATERIAL_POSITIONS := [Vector2(971, 661), Vector2(1067, 661), Vector2(1163, 661)]
const Q008_PATH_SLOT_RECTS := [
	Rect2(532, 362, 56, 26),
	Rect2(592, 362, 56, 26),
	Rect2(652, 362, 56, 26),
]
const Q009_MATERIAL_POSITIONS := [Vector2(240, 570), Vector2(300, 300), Vector2(680, 580)]
const Q009_MATERIAL_LABELS := ["树枝", "羽毛", "草绳"]
const Q009_BIRDHOUSE_POSITION := Vector2(650, 500)
const Q009_BIRD_POSITION := Vector2(650, 465)
const Q009_BIRD_INTERACTION_RADIUS := 72.0
const Q010_SEED_POSITIONS := [Vector2(180, 430), Vector2(550, 300), Vector2(260, 430)]
const Q010_SEED_LABELS := ["红花种子", "蓝花种子", "金色种子"]
const Q011_AREA_RECT := Rect2(196, 568, 188, 56)
const Q011_SLOT_RECTS := [
	Rect2(210, 576, 48, 24),
	Rect2(270, 576, 48, 24),
	Rect2(330, 576, 48, 24),
]
const Q011_ITEM_NAMES := ["木箱", "布包", "竹篮"]
const Q011_INVENTORY_ORIGIN := Vector2(932, 620)
const Q011_INVENTORY_STEP := 96.0
const JOYSTICK_CENTER := Vector2(96, 622)
const JOYSTICK_RADIUS := 54.0
const JOYSTICK_DEADZONE := 0.14
const JOYSTICK_HIT_RADIUS := 88.0
const INTERACT_BUTTON_SIZE := Vector2(64, 58)
const COLLECT_SPARKLE_DURATION := 0.72
const Q005_GROWTH_DURATION := 1.4
const BRIDGE_REPAIR_DURATION := 1.05
const CELEBRATION_DURATION := 2.4
const BRIDGE_SLOTS := [
	Rect2(772, 356, 34, 38),
	Rect2(813, 356, 34, 38),
	Rect2(854, 356, 18, 38),
]
const INVENTORY_ORIGIN := Vector2(932, 638)
const INVENTORY_STEP := 96.0
const VISUAL_PALETTE := {
	"sky": Color("b9e8ef"),
	"sky_band": Color("def5ef"),
	"sun": Color("ffe59a"),
	"cloud": Color("f4ffff"),
	"island_grass": Color("78c977"),
	"island_highlight": Color("a9df88"),
	"island_shadow": Color(0.22, 0.53, 0.40, 0.22),
	"right_locked": Color("a8b9ac"),
	"right_open": Color("72c978"),
	"river": Color("49acd0"),
	"river_light": Color("8bd9e3"),
	"river_edge": Color("d4edb3"),
	"bridge_damaged": Color("6b4b37"),
	"bridge_repaired": Color("9a6940"),
	"bridge_edge": Color("e1b66f"),
	"target_idle": Color("ffe38a"),
	"target_idle_fill": Color(1.0, 0.89, 0.54, 0.16),
	"target_valid": Color("62c982"),
	"target_valid_fill": Color(0.38, 0.79, 0.51, 0.25),
	"board": Color("d5a468"),
	"board_collected": Color("f2c879"),
	"board_outline": Color("704d35"),
	"player": Color("e86c65"),
	"player_outline": Color("70363a"),
	"rabbit_request": Color("fff4df"),
	"rabbit_complete": Color("e9ffe8"),
	"panel": Color(0.08, 0.19, 0.16, 0.90),
	"panel_border": Color("6cae87"),
	"ink": Color("214232"),
}

var game_state
var save_path := SAVE_PATH
var player_position := Vector2(250, 500)
var player_facing := Vector2.RIGHT
var animation_time := 0.0
var player_walk_phase := 0.0
var player_is_moving := false
var collect_sparkle_remaining := 0.0
var collect_sparkle_position := Vector2.ZERO
var collect_sparkle_color := Color("fff1a8")
var q005_growth_remaining := 0.0
var bridge_repair_remaining := 0.0
var celebration_remaining := 0.0
var touch_direction := Vector2.ZERO
var virtual_joystick_active := false
var virtual_joystick_mouse_active := false
var virtual_joystick_touch_index := -1
var virtual_joystick_offset := Vector2.ZERO
var dragging_board := -1
var drag_position := Vector2.ZERO
var dragging_pond_stone := -1
var pond_drag_position := Vector2.ZERO
var dragging_q005_plant := -1
var q005_plant_drag_position := Vector2.ZERO
var dragging_q006_decor := -1
var q006_decor_drag_from_slot := -1
var q006_decor_drag_position := Vector2.ZERO
var dragging_q008_path := -1
var q008_path_drag_position := Vector2.ZERO
var dragging_q011_item := -1
var q011_drag_start_position := Vector2.ZERO
var q011_drag_position := Vector2.ZERO
var build_mode := false
var q011_mode := false
var remove_decor_mode := false
var message_remaining_seconds := 0.0
var message: String = "兔子需要帮助：收集 3 块木板，修好小桥。":
	set(value):
		message = value
		message_remaining_seconds = 4.0 if not message.is_empty() else 0.0
var message_color := Color("fff7cf")
var restart_button: Button
var interact_button: Button
var build_button: Button
var remove_decor_button: Button
var q011_button: Button


func _ready() -> void:
	var ui_theme := Theme.new()
	ui_theme.default_font = UI_FONT
	theme = ui_theme
	game_state = GameState.new()
	_configure_runtime_inputs()
	_configure_save_path()
	_load_game()
	_create_controls()
	get_viewport().size_changed.connect(_layout_controls)
	_layout_controls()
	if message_remaining_seconds <= 0.0 and not message.is_empty():
		message_remaining_seconds = 4.0
	queue_redraw()
	print("奇趣小岛阶段 2 灰盒场景加载成功")
	print("存档路径: ", save_path)


func _physics_process(delta: float) -> void:
	animation_time += delta
	collect_sparkle_remaining = maxf(collect_sparkle_remaining - delta, 0.0)
	q005_growth_remaining = maxf(q005_growth_remaining - delta, 0.0)
	bridge_repair_remaining = maxf(bridge_repair_remaining - delta, 0.0)
	celebration_remaining = maxf(celebration_remaining - delta, 0.0)
	player_is_moving = false
	_tick_transient_message(delta)
	if Input.is_action_just_pressed("interact"):
		_try_collect_nearby()

	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if touch_direction != Vector2.ZERO:
		direction = touch_direction
	if direction.length() > 1.0:
		direction = direction.normalized()
	if direction != Vector2.ZERO:
		player_facing = direction
		var candidate := player_position + direction * PLAYER_SPEED * delta
		if _is_walkable(candidate):
			player_position = candidate
			player_is_moving = true
			player_walk_phase = fposmod(player_walk_phase + delta * TAU * 2.3, TAU)
	queue_redraw()


func _start_collect_sparkles(position: Vector2, color := Color("fff1a8")) -> void:
	collect_sparkle_position = position
	collect_sparkle_color = color
	collect_sparkle_remaining = COLLECT_SPARKLE_DURATION
	queue_redraw()


func _character_bob(phase: float, amplitude := 1.8) -> float:
	return sin(animation_time * 2.2 + phase) * amplitude


func _character_is_blinking(phase: float) -> bool:
	var blink_cycle := fposmod(animation_time + phase, 4.2)
	return blink_cycle > 4.02 and blink_cycle < 4.16


func _tick_transient_message(delta: float) -> void:
	if message_remaining_seconds <= 0.0:
		return
	message_remaining_seconds = maxf(message_remaining_seconds - delta, 0.0)
	if message_remaining_seconds == 0.0:
		message = ""


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _is_virtual_joystick_hit(event.position) and _begin_virtual_joystick(event.position, -1, true):
				get_viewport().set_input_as_handled()
				return
			if _is_button_control_position(event.position):
				return
			_pointer_down(event.position)
		else:
			if virtual_joystick_mouse_active:
				_end_virtual_joystick()
				get_viewport().set_input_as_handled()
				return
			if _is_button_control_position(event.position):
				return
			_pointer_up(event.position)
	elif event is InputEventMouseMotion:
		if virtual_joystick_mouse_active:
			_update_virtual_joystick(event.position)
		elif dragging_board >= 0:
			drag_position = event.position
			queue_redraw()
		elif dragging_pond_stone >= 0:
			pond_drag_position = event.position
			queue_redraw()
		elif dragging_q005_plant >= 0:
			q005_plant_drag_position = event.position
			queue_redraw()
		elif dragging_q006_decor >= 0:
			q006_decor_drag_position = event.position
			queue_redraw()
		elif dragging_q008_path >= 0:
			q008_path_drag_position = event.position
			queue_redraw()
		elif dragging_q011_item >= 0:
			q011_drag_position = event.position
			queue_redraw()
	elif event is InputEventScreenTouch:
		if event.pressed:
			if not virtual_joystick_active and _is_virtual_joystick_hit(event.position) and _begin_virtual_joystick(event.position, event.index, false):
				get_viewport().set_input_as_handled()
				return
			if _is_button_control_position(event.position):
				return
			_pointer_down(event.position)
		else:
			if virtual_joystick_active and not virtual_joystick_mouse_active and virtual_joystick_touch_index == event.index:
				_end_virtual_joystick()
				get_viewport().set_input_as_handled()
				return
			if _is_button_control_position(event.position):
				return
			_pointer_up(event.position)
	elif event is InputEventScreenDrag:
		if virtual_joystick_active and not virtual_joystick_mouse_active and virtual_joystick_touch_index == event.index:
			_update_virtual_joystick(event.position)
			get_viewport().set_input_as_handled()
		elif dragging_board >= 0:
			drag_position = event.position
			queue_redraw()
		elif dragging_pond_stone >= 0:
			pond_drag_position = event.position
			queue_redraw()
		elif dragging_q005_plant >= 0:
			q005_plant_drag_position = event.position
			queue_redraw()
		elif dragging_q006_decor >= 0:
			q006_decor_drag_position = event.position
			queue_redraw()
		elif dragging_q008_path >= 0:
			q008_path_drag_position = event.position
			queue_redraw()
		elif dragging_q011_item >= 0:
			q011_drag_position = event.position
			queue_redraw()


func _is_virtual_joystick_hit(position: Vector2) -> bool:
	return position.distance_to(_virtual_joystick_center()) <= JOYSTICK_HIT_RADIUS


func _is_button_control_position(position: Vector2) -> bool:
	for control in [restart_button, build_button, remove_decor_button, q011_button, interact_button]:
		if control != null and control.visible and control.get_global_rect().has_point(position):
			return true
	return false


func _begin_virtual_joystick(position: Vector2, touch_index: int, is_mouse: bool) -> bool:
	if virtual_joystick_active:
		return false
	virtual_joystick_active = true
	virtual_joystick_mouse_active = is_mouse
	virtual_joystick_touch_index = touch_index
	_update_virtual_joystick(position)
	return true


func _update_virtual_joystick(position: Vector2) -> void:
	virtual_joystick_offset = (position - _virtual_joystick_center()).limit_length(JOYSTICK_RADIUS)
	var strength := virtual_joystick_offset.length() / JOYSTICK_RADIUS
	if strength <= JOYSTICK_DEADZONE:
		touch_direction = Vector2.ZERO
	else:
		var adjusted_strength := inverse_lerp(JOYSTICK_DEADZONE, 1.0, strength)
		touch_direction = virtual_joystick_offset.normalized() * adjusted_strength
	queue_redraw()


func _end_virtual_joystick() -> void:
	virtual_joystick_active = false
	virtual_joystick_mouse_active = false
	virtual_joystick_touch_index = -1
	virtual_joystick_offset = Vector2.ZERO
	touch_direction = Vector2.ZERO
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and (virtual_joystick_active or dragging_board >= 0 or dragging_pond_stone >= 0 or dragging_q005_plant >= 0 or dragging_q006_decor >= 0 or dragging_q008_path >= 0 or dragging_q011_item >= 0):
		_end_virtual_joystick()
		dragging_board = -1
		drag_position = Vector2.ZERO
		dragging_pond_stone = -1
		pond_drag_position = Vector2.ZERO
		dragging_q005_plant = -1
		q005_plant_drag_position = Vector2.ZERO
		dragging_q006_decor = -1
		q006_decor_drag_from_slot = -1
		q006_decor_drag_position = Vector2.ZERO
		dragging_q008_path = -1
		q008_path_drag_position = Vector2.ZERO
		dragging_q011_item = -1
		q011_drag_start_position = Vector2.ZERO
		q011_drag_position = Vector2.ZERO
		q011_mode = false
		message = "窗口失去焦点，拖拽已取消，资源没有丢失。"
		message_color = Color("ffe1b8")
		queue_redraw()


func _configure_runtime_inputs() -> void:
	_bind_keys("move_left", [KEY_A, KEY_LEFT])
	_bind_keys("move_right", [KEY_D, KEY_RIGHT])
	_bind_keys("move_up", [KEY_W, KEY_UP])
	_bind_keys("move_down", [KEY_S, KEY_DOWN])
	_bind_keys("interact", [KEY_E, KEY_SPACE, KEY_ENTER])


func _configure_save_path() -> void:
	var args := OS.get_cmdline_user_args()
	for index in range(max(args.size() - 1, 0)):
		if str(args[index]) == "--test-save-path":
			var candidate := str(args[index + 1])
			if not candidate.is_empty():
				save_path = candidate
			break


func _bind_keys(action_name: String, key_codes: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var existing := InputMap.action_get_events(action_name)
	for key_code in key_codes:
		var found := false
		for event in existing:
			if event is InputEventKey and event.physical_keycode == key_code:
				found = true
				break
		if found:
			continue
		var key_event := InputEventKey.new()
		key_event.physical_keycode = key_code
		InputMap.action_add_event(action_name, key_event)


func _create_controls() -> void:
	restart_button = Button.new()
	restart_button.name = "RestartButton"
	restart_button.text = "重新开始"
	restart_button.position = Vector2(1060, 24)
	restart_button.size = Vector2(180, 56)
	restart_button.add_theme_font_size_override("font_size", 22)
	restart_button.add_theme_color_override("font_color", Color("253b32"))
	restart_button.tooltip_text = "清除本关进度并重新开始"
	restart_button.pressed.connect(_restart_game)
	add_child(restart_button)
	_apply_button_style(restart_button, false)

	build_button = Button.new()
	build_button.name = "BuildButton"
	build_button.text = "建造"
	build_button.position = Vector2(860, 24)
	build_button.size = Vector2(180, 56)
	build_button.add_theme_font_size_override("font_size", 22)
	build_button.add_theme_color_override("font_color", Color("253b32"))
	build_button.tooltip_text = "打开或关闭花园装饰建造模式"
	build_button.pressed.connect(_toggle_build_mode)
	add_child(build_button)

	remove_decor_button = Button.new()
	remove_decor_button.name = "RemoveDecorButton"
	remove_decor_button.text = "移除装饰"
	remove_decor_button.position = Vector2(860, 88)
	remove_decor_button.size = Vector2(180, 48)
	remove_decor_button.add_theme_font_size_override("font_size", 18)
	remove_decor_button.add_theme_color_override("font_color", Color("253b32"))
	remove_decor_button.tooltip_text = "先点击此按钮，再点击已放置的装饰"
	remove_decor_button.pressed.connect(_toggle_remove_mode)
	remove_decor_button.visible = false
	add_child(remove_decor_button)
	_apply_button_style(remove_decor_button, false)

	q011_button = Button.new()
	q011_button.name = "Q011Button"
	q011_button.text = "整理"
	q011_button.position = Vector2(860, 88)
	q011_button.size = Vector2(180, 48)
	q011_button.add_theme_font_size_override("font_size", 18)
	q011_button.add_theme_color_override("font_color", Color("253b32"))
	q011_button.tooltip_text = "打开或关闭额外地块整理模式"
	q011_button.pressed.connect(_toggle_q011_mode)
	q011_button.visible = false
	add_child(q011_button)
	_apply_button_style(q011_button, false)

	interact_button = Button.new()
	interact_button.name = "InteractButton"
	interact_button.text = "收集\n互动"
	interact_button.position = Vector2(1208, 652)
	interact_button.size = INTERACT_BUTTON_SIZE
	interact_button.add_theme_font_size_override("font_size", 15)
	interact_button.add_theme_color_override("font_color", Color("253b32"))
	interact_button.tooltip_text = "收集、浇水、交付或与伙伴互动"
	interact_button.pressed.connect(_try_collect_nearby)
	add_child(interact_button)
	_apply_button_style(interact_button, true)
	_refresh_build_controls()
	_layout_controls()


func _layout_controls() -> void:
	if restart_button == null:
		return
	var visible_size := size
	var layout_width := maxf(WORLD_SIZE.x, visible_size.x)
	restart_button.position = Vector2(layout_width - 220.0, 24.0)
	build_button.position = Vector2(layout_width - 420.0, 24.0)
	remove_decor_button.position = Vector2(layout_width - 420.0, 88.0)
	q011_button.position = Vector2(layout_width - 420.0, 88.0)
	interact_button.position = Vector2(layout_width - INTERACT_BUTTON_SIZE.x - 8.0, maxf(8.0, visible_size.y - INTERACT_BUTTON_SIZE.y - 10.0))


func _toggle_build_mode() -> void:
	if not _can_use_q006_build_mode():
		message = "完成狐狸小屋、池塘和花园任务后，就可以布置花园装饰。"
		message_color = Color("ffe1b8")
		return
	if game_state.is_q006_complete() and not game_state.is_q012_complete():
		return
	build_mode = not build_mode
	q011_mode = false
	dragging_q011_item = -1
	q011_drag_start_position = Vector2.ZERO
	q011_drag_position = Vector2.ZERO
	remove_decor_mode = false
	dragging_q006_decor = -1
	q006_decor_drag_from_slot = -1
	q006_decor_drag_position = Vector2.ZERO
	if build_mode:
		message = "花园装饰模式已打开：拖动装饰到对应槽位。"
		message_color = Color("fff7cf")
	else:
		message = "已退出花园装饰模式。"
		message_color = Color("fff7cf")
	_refresh_build_controls()
	queue_redraw()


func _toggle_q011_mode() -> void:
	if not _can_use_q011_mode():
		q011_mode = false
		dragging_q011_item = -1
		q011_drag_start_position = Vector2.ZERO
		q011_drag_position = Vector2.ZERO
		_refresh_build_controls()
		return
	q011_mode = not q011_mode
	build_mode = false
	remove_decor_mode = false
	dragging_q006_decor = -1
	q006_decor_drag_from_slot = -1
	q006_decor_drag_position = Vector2.ZERO
	dragging_q008_path = -1
	q008_path_drag_position = Vector2.ZERO
	dragging_q011_item = -1
	q011_drag_start_position = Vector2.ZERO
	q011_drag_position = Vector2.ZERO
	if q011_mode:
		message = "帮忙整理：把木箱、布包和竹篮放进任意空槽。"
		message_color = Color("fff7cf")
	else:
		message = "已退出额外地块整理模式。"
		message_color = Color("fff7cf")
	_refresh_build_controls()
	queue_redraw()


func _toggle_remove_mode() -> void:
	if not build_mode:
		return
	remove_decor_mode = not remove_decor_mode
	remove_decor_button.text = "取消移除" if remove_decor_mode else "移除装饰"
	message = "请点击已放置的装饰将它移除。" if remove_decor_mode else "已取消移除模式。"
	message_color = Color("fff7cf")
	queue_redraw()


func _refresh_build_controls() -> void:
	if build_button == null:
		return
	var available := _can_use_q006_build_mode()
	build_button.visible = available and (not game_state.is_q006_complete() or game_state.is_q012_complete())
	var next_step: bool = available and not game_state.is_q006_complete() and not build_mode
	build_button.text = "开始布置" if next_step else ("退出建造" if build_mode else "建造")
	_apply_build_button_style(next_step)
	remove_decor_button.visible = available and build_mode
	remove_decor_button.text = "取消移除" if remove_decor_mode else "移除装饰"
	q011_button.visible = _can_use_q011_mode() and not build_mode
	var q011_next_step := q011_button.visible and not q011_mode
	q011_button.text = "退出整理" if q011_mode else "开始整理"
	_apply_button_style(q011_button, q011_next_step)


func _apply_build_button_style(highlighted: bool) -> void:
	_apply_button_style(build_button, highlighted)
	build_button.add_theme_color_override("font_color", Color("173d2d") if highlighted else Color("253b32"))
	build_button.add_theme_color_override("font_hover_color", Color("123927"))
	build_button.add_theme_color_override("font_pressed_color", Color("102f23"))
	build_button.add_theme_font_size_override("font_size", 20 if highlighted else 22)


func _apply_button_style(button: Button, highlighted: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("68bd72") if highlighted else Color("e6eee2")
	normal.border_color = Color("3d8d58") if highlighted else Color("9ab5a0")
	normal.set_border_width_all(3 if highlighted else 2)
	normal.set_corner_radius_all(12)
	normal.content_margin_left = 8.0
	normal.content_margin_right = 8.0
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("82d789") if highlighted else Color("f2f7ef")
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("54a966") if highlighted else Color("d7e4d4")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color("253b32"))
	button.add_theme_color_override("font_hover_color", Color("173d2b"))
	button.add_theme_color_override("font_pressed_color", Color("173d2b"))


func _are_core_tasks_complete() -> bool:
	return game_state != null and game_state.is_complete() and game_state.is_seed_complete() and game_state.is_q004_complete() and game_state.is_pond_complete() and game_state.is_q005_complete()


func _can_start_pond_stage() -> bool:
	return game_state != null and game_state.is_q004_complete() and game_state.can_start_pond_task()


func _can_show_pond_area() -> bool:
	return game_state != null and game_state.is_q004_complete() and (game_state.can_start_pond_task() or game_state.is_pond_complete())


func _can_start_q005_stage() -> bool:
	return game_state != null and game_state.is_q004_complete() and game_state.can_start_q005()


func _can_use_q006_build_mode() -> bool:
	return _are_core_tasks_complete() and (game_state.can_edit_q006() or game_state.is_q006_complete())


func _can_use_q007_side_task() -> bool:
	return _are_core_tasks_complete() and game_state.is_q012_complete() and (game_state.can_start_q007() or game_state.is_q007_complete())


func _can_use_q008_side_task() -> bool:
	return _are_core_tasks_complete() and game_state.is_q012_complete() and game_state.is_q010_complete() and (game_state.can_start_q008() or game_state.is_q008_complete())


func _can_use_q009_side_task() -> bool:
	return _are_core_tasks_complete() and game_state.is_q012_complete() and game_state.is_q007_complete() and (game_state.can_start_q009() or game_state.is_q009_complete())


func _can_use_q010_side_task() -> bool:
	return _are_core_tasks_complete() and game_state.is_q012_complete() and game_state.is_q009_complete() and (game_state.can_start_q010() or game_state.is_q010_complete())


func _should_show_q009_task_card() -> bool:
	return _can_use_q009_side_task() and not game_state.is_q010_complete()


func _should_show_q010_task_card() -> bool:
	return _can_use_q010_side_task() and not game_state.is_q010_complete()


func _can_use_q011_mode() -> bool:
	return _can_show_q011_area() and game_state.can_start_q011()


func _can_show_q011_area() -> bool:
	return _are_core_tasks_complete() and game_state.is_q012_complete() and game_state.is_q008_complete() and (game_state.can_start_q011() or game_state.is_q011_complete())


func _pointer_down(position: Vector2) -> void:
	if dragging_board >= 0 or dragging_pond_stone >= 0 or dragging_q005_plant >= 0 or dragging_q006_decor >= 0 or dragging_q008_path >= 0 or dragging_q011_item >= 0:
		return
	if q011_mode:
		if _can_use_q011_mode():
			for item_id in range(GameState.Q011_ITEM_TOTAL):
				if game_state.q011_item_is_available(item_id) and _q011_item_inventory_rect(item_id).has_point(position):
					dragging_q011_item = item_id
					q011_drag_start_position = position
					q011_drag_position = position
					message = "把%s拖到任意空槽，绿色时松开。" % Q011_ITEM_NAMES[item_id]
					message_color = Color("fff7cf")
					queue_redraw()
					return
		message = "请从整理托盘中选择尚未放置的物品。"
		message_color = Color("ffe1b8")
		queue_redraw()
		return
	if build_mode and _can_use_q006_build_mode():
		if remove_decor_mode:
			for slot_id in range(GameState.Q006_SLOT_TOTAL):
				var placed_decor_id: int = game_state.q006_slot_occupants[slot_id]
				if placed_decor_id >= 0 and _q006_decor_slot_rect(slot_id).grow(10).has_point(position):
					if game_state.remove_q006_decoration(placed_decor_id, slot_id):
						_save_game()
						message = "装饰已移除，可以重新摆放。"
						message_color = Color("d9ffd0")
						queue_redraw()
					return
			message = "请点击已放置的装饰。"
			message_color = Color("ffe1b8")
			queue_redraw()
			return
		for slot_id in range(GameState.Q006_SLOT_TOTAL):
			var placed_decor_id: int = game_state.q006_slot_occupants[slot_id]
			if placed_decor_id >= 0 and _q006_decor_slot_rect(slot_id).grow(10).has_point(position):
				dragging_q006_decor = placed_decor_id
				q006_decor_drag_from_slot = slot_id
				q006_decor_drag_position = position
				message = "把装饰拖到空槽位，绿色时松开。"
				message_color = Color("fff7cf")
				queue_redraw()
				return
		for decor_id in range(GameState.Q006_DECOR_TOTAL):
			if game_state.q006_decor_is_available(decor_id) and _q006_decor_inventory_rect(decor_id).has_point(position):
				dragging_q006_decor = decor_id
				q006_decor_drag_from_slot = -1
				q006_decor_drag_position = position
				message = "把装饰拖到对应槽位，绿色时松开。"
				message_color = Color("fff7cf")
				queue_redraw()
				return
		message = "请选择装饰，或点击已放置的装饰开始移动。"
		message_color = Color("fff7cf")
		queue_redraw()
		return
	if _can_start_pond_stage():
		for stone_id in range(GameState.POND_STONE_TOTAL):
			if game_state.pond_stones_placed[stone_id]:
				continue
			if _pond_stone_rect(stone_id).grow(12).has_point(position):
				dragging_pond_stone = stone_id
				pond_drag_position = position
				message = "把石头拖到池塘边对应的轮廓里。"
				message_color = Color("fff7cf")
				queue_redraw()
				return

	if _can_start_q005_stage():
		for plant_id in range(GameState.Q005_PLANT_TOTAL):
			if not game_state.q005_plants_collected[plant_id] or game_state.q005_plant_slots[plant_id]:
				continue
			if _q005_plant_inventory_rect(plant_id).has_point(position):
				dragging_q005_plant = plant_id
				q005_plant_drag_position = position
				message = "把植物拖到花园中对应的空槽，绿色时松开。"
				message_color = Color("fff7cf")
				queue_redraw()
				return

	if _can_use_q008_side_task() and game_state.can_start_q008():
		for material_id in range(GameState.Q008_PATH_SLOT_TOTAL):
			if not game_state.q008_path_material_is_available(material_id):
				continue
			if _q008_path_material_rect(material_id).grow(12).has_point(position):
				dragging_q008_path = material_id
				q008_path_drag_position = position
				message = "把路面石板拖到小路的空槽位。"
				message_color = Color("fff7cf")
				queue_redraw()
				return

	for board_id in range(GameState.BOARD_TOTAL):
		if not game_state.collected[board_id] and _board_rect(board_id).grow(12).has_point(position):
			_try_collect_board(board_id)
			return

	for board_id in range(GameState.BOARD_TOTAL):
		if game_state.can_place_board(board_id) and _inventory_rect(board_id).has_point(position):
			dragging_board = board_id
			drag_position = position
			message = "拖动木板到桥上的高亮位置，绿色时松开。"
			message_color = Color("fff7cf")
			queue_redraw()
			return


func _pointer_up(position: Vector2) -> void:
	if dragging_q011_item >= 0:
		var item_id := dragging_q011_item
		var target_slot := _q011_slot_at(position)
		dragging_q011_item = -1
		q011_drag_start_position = Vector2.ZERO
		q011_drag_position = Vector2.ZERO
		if target_slot >= 0 and game_state.place_q011_item(item_id, target_slot):
			message = "%s放置成功！整理进度 %d/3。" % [Q011_ITEM_NAMES[item_id], game_state.q011_placed_count()]
			message_color = Color("d9ffd0")
			_save_game()
			if game_state.is_q011_complete():
				q011_mode = false
				message = "额外地块整理完成！可以自由探索，或点击“建造”调整花园。"
				message_color = Color("fff1a8")
		else:
			message = "这个位置不合适，%s没有丢失。" % Q011_ITEM_NAMES[item_id]
			message_color = Color("ffe1b8")
		_refresh_build_controls()
		queue_redraw()
		return

	if dragging_q006_decor >= 0:
		var decor_id := dragging_q006_decor
		var from_slot := q006_decor_drag_from_slot
		var target_slot := _q006_decor_slot_at(position)
		var q006_was_complete: bool = game_state.is_q006_complete()
		dragging_q006_decor = -1
		q006_decor_drag_from_slot = -1
		q006_decor_drag_position = Vector2.ZERO
		var placed_successfully := false
		if from_slot >= 0:
			if target_slot >= 0 and game_state.move_q006_decoration(decor_id, from_slot, target_slot):
				placed_successfully = true
		else:
			if target_slot >= 0 and game_state.place_q006_decoration(decor_id, target_slot):
				placed_successfully = true
		if placed_successfully:
			message = "装饰摆放成功！继续布置花园。"
			message_color = Color("d9ffd0")
			_save_game()
			if not q006_was_complete and game_state.is_q006_complete():
				build_mode = false
				remove_decor_mode = false
				message = "花园装饰完成！回到兔子身边参加小岛庆祝。"
				message_color = Color("fff1a8")
		else:
			message = "这个位置不合适，装饰没有丢失。"
			message_color = Color("ffe1b8")
		_refresh_build_controls()
		queue_redraw()
		return

	if dragging_pond_stone >= 0:
		var stone_id := dragging_pond_stone
		var target_slot := _pond_drag_target_at(position)
		dragging_pond_stone = -1
		pond_drag_position = Vector2.ZERO
		if target_slot >= 0 and game_state.place_pond_stone(stone_id):
			message = "石头放置正确！继续摆好其他轮廓。"
			message_color = Color("d9ffd0")
			_save_game()
			if game_state.is_pond_complete():
				message = "池塘整理好了！下一步：去照料乌龟的花园。"
				message_color = Color("fff1a8")
		else:
			message = "这个位置不合适，石头没有丢失。"
			message_color = Color("ffe1b8")
		queue_redraw()
		return

	if dragging_q005_plant >= 0:
		var plant_id := dragging_q005_plant
		var target_slot := _q005_plant_drag_target_at(position)
		dragging_q005_plant = -1
		q005_plant_drag_position = Vector2.ZERO
		if target_slot >= 0 and game_state.place_q005_plant(plant_id, target_slot):
			_start_collect_sparkles(Q005_PLANT_SLOTS[target_slot].get_center(), Color("a9e98b"))
			message = "植物摆放正确！继续照料花园。"
			message_color = Color("d9ffd0")
			_save_game()
			if game_state.is_q005_complete():
				message = "花园恢复生机！下一步：点击“开始布置”，装饰花园。"
				message_color = Color("fff1a8")
		else:
			message = "这个槽位不合适，植物没有丢失。"
			message_color = Color("ffe1b8")
		queue_redraw()
		return

	if dragging_q008_path >= 0:
		var material_id := dragging_q008_path
		var target_slot := _q008_path_slot_at(position)
		dragging_q008_path = -1
		q008_path_drag_position = Vector2.ZERO
		if target_slot >= 0 and game_state.place_q008_path(material_id, target_slot):
			message = "路面石板放置成功！继续铺设小路。"
			message_color = Color("d9ffd0")
			_save_game()
			if game_state.is_q008_complete():
				message = "小路连起来完成！"
				message_color = Color("fff1a8")
		else:
			message = "这个位置不合适，路面石板没有丢失。"
			message_color = Color("ffe1b8")
		queue_redraw()
		return

	if dragging_board < 0:
		return
	var board_id := dragging_board
	var target_slot := _drag_target_slot_at(position)
	dragging_board = -1
	if target_slot >= 0 and game_state.place_board(board_id, target_slot):
		_start_collect_sparkles(BRIDGE_SLOTS[target_slot].get_center(), Color("fff1a8"))
		message = "木板放置正确！继续修好桥。"
		message_color = Color("d9ffd0")
		_save_game()
		if game_state.is_complete():
			bridge_repair_remaining = BRIDGE_REPAIR_DURATION
			message = "太棒了！小桥修好了，右侧区域已经开放！"
			message_color = Color("fff1a8")
	else:
		message = "还差一点：请把木板拖到它对应的桥上空位。木板没有丢失。"
		message_color = Color("ffe1b8")
	queue_redraw()


func _try_collect_nearby() -> void:
	if game_state.can_start_q012():
		if player_position.distance_to(Q012_RABBIT_POSITION) <= COLLECTION_RADIUS:
			if game_state.complete_q012():
				celebration_remaining = CELEBRATION_DURATION
				_start_collect_sparkles(Q012_RABBIT_POSITION, Color("fff1a8"))
				_save_game()
				message = "小岛庆祝日开始！主线故事完成，接下来可以自由探索。"
				message_color = Color("fff1a8")
		else:
			message = "主线最后一步：走到兔子身边，按互动键参加小岛庆祝。"
			message_color = Color("fff1a8")
		queue_redraw()
		return

	if _can_use_q007_side_task() and game_state.can_start_q007() and _try_q007_interaction():
		queue_redraw()
		return

	if _can_start_q005_stage() and _try_q005_interaction():
		queue_redraw()
		return

	if _can_use_q010_side_task() and game_state.can_start_q010() and _try_q010_interaction():
		queue_redraw()
		return

	if game_state.can_start_q004():
		_try_q004_interaction()
		queue_redraw()
		return

	if _can_use_q009_side_task() and game_state.can_start_q009() and _try_q009_interaction():
		queue_redraw()
		return

	if _can_use_q009_side_task() and game_state.q009_bird_interaction_unlocked() and _try_q009_bird_interaction():
		queue_redraw()
		return

	if game_state.can_collect_seed():
		if player_position.distance_to(SEED_POSITION) <= COLLECTION_RADIUS:
			if game_state.collect_seed():
				_start_collect_sparkles(SEED_POSITION, Color("f2c879"))
				message = "找到种子啦！现在去右侧花圃种下。"
				message_color = Color("d9ffd0")
				_save_game()
		else:
			message = "过桥后到右侧找一找闪亮的种子。"
			message_color = Color("fff1a8")
		queue_redraw()
		return

	if game_state.can_plant_seed():
		if player_position.distance_to(FLOWERBED_POSITION) <= FLOWERBED_INTERACTION_RADIUS:
			if game_state.plant_seed():
				_start_collect_sparkles(FLOWERBED_POSITION, Color("a9e98b"))
				message = "种植成功！幼苗长出来了！"
				message_color = Color("d9ffd0")
				_save_game()
		else:
			message = "带着种子到右侧花圃，再按互动键种下。"
			message_color = Color("fff1a8")
		queue_redraw()
		return

	if game_state.is_seed_complete():
		if not game_state.is_q004_complete():
			message = "幼苗长出来了！下一步：帮狐狸收集木材、建好小屋。"
		elif not game_state.is_pond_complete():
			message = "狐狸已经入住了！下一步：把池塘边的石头放进轮廓。"
		else:
			message = "幼苗长出来了，继续探索右侧区域吧！"
		message_color = Color("d9ffd0")
		queue_redraw()
		return

	var nearest_id := -1
	var nearest_distance := COLLECTION_RADIUS
	for board_id in range(GameState.BOARD_TOTAL):
		if game_state.collected[board_id]:
			continue
		var distance := player_position.distance_to(BOARD_POSITIONS[board_id])
		if distance <= nearest_distance:
			nearest_distance = distance
			nearest_id = board_id
	if nearest_id >= 0:
		_try_collect_board(nearest_id)
	else:
		message = "请走到木板旁边，再按右下角“收集 / 互动”或 E 键。"
		message_color = Color("ffe1b8")


func _try_q007_interaction() -> bool:
	if player_position.distance_to(Q007_SHELL_POSITION) > COLLECTION_RADIUS:
		return false
	if game_state.collect_q007_shell():
		_start_collect_sparkles(Q007_SHELL_POSITION, Color("fff1a8"))
		_save_game()
		message = "隐藏的贝壳完成！获得珍珠贝壳摆件。"
		message_color = Color("fff1a8")
		return true
	return false


func _try_q005_interaction() -> bool:
	var target_kind := 0
	var target_id := -1
	var nearest_distance := Q005_INTERACTION_RADIUS
	var watering_distance := player_position.distance_to(Q005_WATERING_POINT_POSITION)
	if watering_distance <= nearest_distance:
		target_kind = 1
		nearest_distance = watering_distance
	for plant_id in range(GameState.Q005_PLANT_TOTAL):
		if game_state.q005_plants_collected[plant_id]:
			continue
		var distance := player_position.distance_to(Q005_PLANT_POSITIONS[plant_id])
		if distance <= nearest_distance:
			target_kind = 2
			target_id = plant_id
			nearest_distance = distance
	if target_kind == 1:
		if game_state.water_q005():
			q005_growth_remaining = Q005_GROWTH_DURATION
			_start_collect_sparkles(Q005_WATERING_POINT_POSITION, Color("9be7f0"))
			_save_game()
			message = "浇水成功！现在收集 3 株植物并摆进花园。"
			message_color = Color("d9ffd0")
		else:
			message = "花园已经浇过水了。继续收集并摆放植物。"
			message_color = Color("fff1a8")
		return true
	if target_kind == 2 and not game_state.q005_watered:
		message = "先给花园浇水，植物长好后才能采集。"
		message_color = Color("fff1a8")
		return true
	if target_kind == 2 and game_state.collect_q005_plant(target_id):
		_start_collect_sparkles(Q005_PLANT_POSITIONS[target_id], Color("a9e98b"))
		_save_game()
		message = "植物收集成功：%d/3。" % game_state.q005_plant_count()
		message_color = Color("d9ffd0")
		return true
	return false


func _try_q004_interaction() -> void:
	if player_position.distance_to(HOUSE_POSITION) <= HOUSE_INTERACTION_RADIUS:
		if game_state.deliver_next_wood():
			_save_game()
			if game_state.is_q004_complete():
				message = "小屋建好了！狐狸入住了！下一步：整理池塘边的石头。"
				message_color = Color("fff1a8")
			else:
				message = "木材交付成功！还需要 %d 份。" % (GameState.Q004_WOOD_TOTAL - game_state.delivered_wood_count())
				message_color = Color("d9ffd0")
			return
		if game_state.wood_count() < GameState.Q004_WOOD_TOTAL:
			message = "木材还不够，请先收集 %d 份。" % (GameState.Q004_WOOD_TOTAL - game_state.wood_count())
		else:
			message = "木材已经集齐，继续按互动键交付。"
		message_color = Color("fff1a8")
		return

	var nearest_id := -1
	var nearest_distance := COLLECTION_RADIUS
	for wood_id in range(GameState.Q004_WOOD_TOTAL):
		if game_state.wood_collected[wood_id]:
			continue
		var distance := player_position.distance_to(WOOD_POSITIONS[wood_id])
		if distance <= nearest_distance:
			nearest_distance = distance
			nearest_id = wood_id
	if nearest_id >= 0 and game_state.collect_wood(nearest_id):
		_start_collect_sparkles(WOOD_POSITIONS[nearest_id], Color("f2c879"))
		_save_game()
		message = "木材收集成功：%d/%d。" % [game_state.wood_count(), GameState.Q004_WOOD_TOTAL]
		message_color = Color("d9ffd0")
	elif game_state.wood_count() < GameState.Q004_WOOD_TOTAL:
		message = "请在岛上找到木材，再按互动键收集。"
		message_color = Color("fff1a8")
	else:
		message = "木材已集齐，请到小屋旁交付。"
		message_color = Color("fff1a8")


func _try_q009_interaction() -> bool:
	var nearest_id := -1
	var nearest_distance := COLLECTION_RADIUS
	for material_id in range(GameState.Q009_MATERIAL_TOTAL):
		if game_state.q009_materials_collected[material_id]:
			continue
		var distance := player_position.distance_to(Q009_MATERIAL_POSITIONS[material_id])
		if distance <= nearest_distance:
			nearest_distance = distance
			nearest_id = material_id
	if nearest_id >= 0 and game_state.collect_q009_material(nearest_id):
		_start_collect_sparkles(Q009_MATERIAL_POSITIONS[nearest_id], Color("fff1a8"))
		_save_game()
		if game_state.is_q009_complete():
			message = "鸟屋计划完成！小鸟互动已开放。"
			message_color = Color("fff1a8")
		else:
			message = "鸟屋材料收集成功：%d/3。" % game_state.q009_material_count()
			message_color = Color("d9ffd0")
		return true
	message = "请在岛上找到 3 份鸟屋材料，靠近后按互动键收集。"
	message_color = Color("fff1a8")
	return true


func _try_q009_bird_interaction() -> bool:
	if player_position.distance_to(Q009_BIRD_POSITION) > Q009_BIRD_INTERACTION_RADIUS:
		return false
	message = "小鸟：谢谢你帮我建好鸟屋！"
	message_color = Color("d9ffd0")
	return true


func _try_q010_interaction() -> bool:
	var nearest_id := -1
	var nearest_distance := COLLECTION_RADIUS
	for seed_id in range(GameState.Q010_SEED_TOTAL):
		if game_state.q010_seeds_collected[seed_id]:
			continue
		var distance := player_position.distance_to(Q010_SEED_POSITIONS[seed_id])
		if distance <= nearest_distance:
			nearest_distance = distance
			nearest_id = seed_id
	if nearest_id < 0 or not game_state.collect_q010_seed(nearest_id):
		return false
	_start_collect_sparkles(Q010_SEED_POSITIONS[nearest_id], Color("fff1a8"))
	_save_game()
	if game_state.is_q010_complete():
		message = "种子收藏完成！植物外观已解锁。"
		message_color = Color("fff1a8")
	else:
		message = "收集成功！%s：%d/3。" % [Q010_SEED_LABELS[nearest_id], game_state.q010_seed_count()]
		message_color = Color("d9ffd0")
	return true


func _try_collect_board(board_id: int) -> void:
	if player_position.distance_to(BOARD_POSITIONS[board_id]) > COLLECTION_RADIUS:
		message = "还要再靠近一点，就能捡起这块木板。"
		message_color = Color("ffe1b8")
		return
	if game_state.collect_board(board_id):
		_start_collect_sparkles(BOARD_POSITIONS[board_id], Color("f2c879"))
		message = "收集成功！木板：%d/3。" % game_state.board_count()
		message_color = Color("d9ffd0")
		_save_game()
	if game_state.board_count() == GameState.BOARD_TOTAL:
		message = "木板集齐了！拖动下方木板到桥上的对应空位。"
		message_color = Color("fff1a8")
	queue_redraw()


func _is_walkable(position: Vector2) -> bool:
	if position.x < 70 or position.x > WORLD_SIZE.x - 70 or position.y < 145 or position.y > WORLD_SIZE.y - 50:
		return false
	var player_rect := Rect2(position - Vector2.ONE * PLAYER_RADIUS, Vector2.ONE * PLAYER_RADIUS * 2.0)
	if player_rect.intersects(RIVER_RECT):
		var bridge_corridor := BRIDGE_PASSAGE_RECT
		if not game_state.bridge_repaired or not bridge_corridor.intersects(player_rect):
			return false
	return true


func _board_rect(board_id: int) -> Rect2:
	return Rect2(BOARD_POSITIONS[board_id] - Vector2(28, 14), Vector2(56, 28))


func _inventory_rect(board_id: int) -> Rect2:
	return Rect2(INVENTORY_ORIGIN + Vector2(INVENTORY_STEP * board_id, 0), Vector2(78, 46))


func _pond_stone_rect(stone_id: int) -> Rect2:
	return Rect2(POND_STONE_POSITIONS[stone_id] - Vector2(22, 16), Vector2(44, 32))


func _pond_drag_target_at(position: Vector2) -> int:
	if dragging_pond_stone < 0 or not game_state.can_place_pond_stone(dragging_pond_stone):
		return -1
	if dragging_pond_stone >= POND_SLOTS.size():
		return -1
	return dragging_pond_stone if POND_SLOTS[dragging_pond_stone].grow(18).has_point(position) else -1


func _q005_plant_inventory_rect(plant_id: int) -> Rect2:
	return Rect2(INVENTORY_ORIGIN + Vector2(INVENTORY_STEP * plant_id, 0), Vector2(78, 46))


func q005_plant_count() -> int:
	return game_state.q005_plant_count()


func _q005_plant_drag_target_at(position: Vector2) -> int:
	if dragging_q005_plant < 0 or not game_state.can_place_q005_plant(dragging_q005_plant, dragging_q005_plant):
		return -1
	if dragging_q005_plant >= Q005_PLANT_SLOTS.size():
		return -1
	return dragging_q005_plant if Q005_PLANT_SLOTS[dragging_q005_plant].grow(18).has_point(position) else -1


func _q005_plant_slot_is_drop_target(slot_id: int) -> bool:
	return dragging_q005_plant == slot_id and game_state.can_place_q005_plant(dragging_q005_plant, slot_id)


func _q005_plant_slot_is_hovered(slot_id: int) -> bool:
	return _q005_plant_slot_is_drop_target(slot_id) and Q005_PLANT_SLOTS[slot_id].grow(18).has_point(q005_plant_drag_position)


func _q006_decor_inventory_rect(decor_id: int) -> Rect2:
	return Rect2(Q006_DECOR_INVENTORY_ORIGIN + Vector2(Q006_DECOR_INVENTORY_STEP * decor_id, 0), Vector2(78, 42))


func _q006_decor_slot_rect(slot_id: int) -> Rect2:
	return Q006_DECOR_SLOTS[slot_id]


func _q006_decor_slot_at(position: Vector2) -> int:
	if dragging_q006_decor < 0:
		return -1
	for slot_id in range(GameState.Q006_SLOT_TOTAL):
		if _q006_decor_slot_rect(slot_id).grow(18).has_point(position):
			if q006_decor_drag_from_slot == slot_id and game_state.q006_slot_occupants[slot_id] == dragging_q006_decor:
				continue
			return slot_id
	return -1


func _q006_decor_slot_is_drop_target(slot_id: int) -> bool:
	if dragging_q006_decor < 0 or slot_id < 0 or slot_id >= GameState.Q006_SLOT_TOTAL:
		return false
	if q006_decor_drag_from_slot >= 0:
		return game_state.can_move_q006_decoration(dragging_q006_decor, q006_decor_drag_from_slot, slot_id)
	return game_state.can_place_q006_decoration(dragging_q006_decor, slot_id)


func _q006_decor_slot_is_hovered(slot_id: int) -> bool:
	return _q006_decor_slot_is_drop_target(slot_id) and _q006_decor_slot_rect(slot_id).grow(18).has_point(q006_decor_drag_position)


func _q008_path_material_rect(material_id: int) -> Rect2:
	return Rect2(Q008_PATH_MATERIAL_POSITIONS[material_id] - Vector2(28, 14), Vector2(56, 28))


func _q008_path_slot_at(position: Vector2) -> int:
	if not _can_use_q008_side_task() or dragging_q008_path < 0 or not game_state.q008_path_material_is_available(dragging_q008_path):
		return -1
	for slot_id in range(GameState.Q008_PATH_SLOT_TOTAL):
		if game_state.q008_path_slot_occupants[slot_id] < 0 and Q008_PATH_SLOT_RECTS[slot_id].grow(12).has_point(position):
			return slot_id
	return -1


func _q008_path_slot_is_drop_target(slot_id: int) -> bool:
	return _can_use_q008_side_task() and dragging_q008_path >= 0 and game_state.can_place_q008_path(dragging_q008_path, slot_id)


func _q008_path_slot_is_hovered(slot_id: int) -> bool:
	return _q008_path_slot_is_drop_target(slot_id) and Q008_PATH_SLOT_RECTS[slot_id].grow(12).has_point(q008_path_drag_position)


func _q011_item_inventory_rect(item_id: int) -> Rect2:
	return Rect2(Q011_INVENTORY_ORIGIN + Vector2(Q011_INVENTORY_STEP * item_id, 0), Vector2(78, 44))


func _q011_slot_at(position: Vector2) -> int:
	if not q011_mode or dragging_q011_item < 0 or not game_state.q011_item_is_available(dragging_q011_item):
		return -1
	for slot_id in range(GameState.Q011_ITEM_TOTAL):
		if game_state.q011_slot_occupants[slot_id] < 0 and Q011_SLOT_RECTS[slot_id].grow(12).has_point(position):
			return slot_id
	return -1


func _q009_material_rect(material_id: int) -> Rect2:
	return Rect2(Q009_MATERIAL_POSITIONS[material_id] - Vector2(24, 18), Vector2(48, 36))


func _slot_drop_rect(slot_id: int) -> Rect2:
	return BRIDGE_SLOTS[slot_id].grow(18)


func _drag_target_slot_at(position: Vector2) -> int:
	if dragging_board < 0 or not game_state.can_place_board(dragging_board):
		return -1
	if dragging_board >= BRIDGE_SLOTS.size():
		return -1
	return dragging_board if _slot_drop_rect(dragging_board).has_point(position) else -1


func _restart_game() -> void:
	game_state.reset()
	player_position = Vector2(250, 500)
	player_facing = Vector2.RIGHT
	player_walk_phase = 0.0
	player_is_moving = false
	collect_sparkle_remaining = 0.0
	q005_growth_remaining = 0.0
	bridge_repair_remaining = 0.0
	celebration_remaining = 0.0
	dragging_board = -1
	dragging_pond_stone = -1
	pond_drag_position = Vector2.ZERO
	dragging_q005_plant = -1
	q005_plant_drag_position = Vector2.ZERO
	build_mode = false
	remove_decor_mode = false
	dragging_q006_decor = -1
	q006_decor_drag_from_slot = -1
	q006_decor_drag_position = Vector2.ZERO
	dragging_q008_path = -1
	q008_path_drag_position = Vector2.ZERO
	q011_mode = false
	dragging_q011_item = -1
	q011_drag_start_position = Vector2.ZERO
	q011_drag_position = Vector2.ZERO
	_save_game()
	_refresh_build_controls()
	message = "已经重新开始：请先去帮助兔子收集 3 块木板。"
	message_color = Color("fff7cf")
	queue_redraw()


func _save_game() -> void:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		message = "进度暂时无法保存，请检查设备存储权限。"
		message_color = Color("ffcfb3")
		return
	file.store_string(JSON.stringify(game_state.to_save_data()))
	file.flush()
	file.close()
	_refresh_build_controls()


func _load_game() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return
	var data = JSON.parse_string(file.get_as_text())
	if data is Dictionary and game_state.load_save_data(data):
		message = _loaded_progress_message()
		return
	game_state.reset()
	message = "存档格式无法识别，已安全开始新游戏。"
	message_color = Color("ffe1b8")


func _loaded_progress_message() -> String:
	if game_state.can_start_q012():
		return "已恢复进度：花园装饰完成，请回到兔子身边参加庆祝。"
	if game_state.is_q011_complete():
		return ""
	if not game_state.is_complete():
		return "已恢复进度：木板 %d/3。" % game_state.board_count()
	if not game_state.seed_collected:
		return "已恢复进度：小桥已经修好，请过桥寻找种子。"
	if game_state.seed_collected:
		if not game_state.seed_planted:
			return "已恢复进度：种子已经找到，请到花圃种下。"
	if not game_state.is_q004_complete():
		if game_state.wood_count() < GameState.Q004_WOOD_TOTAL:
			return "已恢复进度：正在帮狐狸建小屋，木材 %d/3。" % game_state.wood_count()
		return "已恢复进度：木材已经集齐，请到小屋旁交付。"
	if not game_state.is_pond_complete():
		return "已恢复进度：狐狸已经入住，接下来整理池塘石头。"
	if not game_state.is_q005_complete():
		return "已恢复进度：池塘已经开放，乌龟的花园任务正在进行。"
	if not game_state.is_q006_complete():
		return "已恢复进度：下一步点击“开始布置”，摆好花园装饰。"
	if not game_state.is_q007_complete():
		return "已恢复进度：主线故事已完成；池塘边的贝壳是可选支线。"
	if not game_state.is_q009_complete():
		return "已恢复进度：鸟屋材料 %d/3。" % game_state.q009_material_count()
	if not game_state.is_q010_complete():
		return "已恢复进度：种子收藏 %d/3。" % game_state.q010_seed_count()
	if not game_state.is_q008_complete():
		return "已恢复进度：小路石板 %d/3。" % game_state.q008_path_placed_count()
	if game_state.q011_placed_count() > 0:
		return "已恢复进度：额外地块整理 %d/3。" % game_state.q011_placed_count()
	return "已恢复进度：主线任务已完成，可以继续自由探索。"


func _draw() -> void:
	var font := UI_FONT
	_draw_background()
	_draw_world(font)
	_draw_feedback_effects()
	_draw_hud(font)
	_draw_touch_hint(font)
	if dragging_board >= 0:
		_draw_board_at(drag_position, Color("fff2ad"), true)
	elif dragging_pond_stone >= 0:
		_draw_pond_stone_at(pond_drag_position, Color("fff2ad"), true)
	elif dragging_q005_plant >= 0:
		_draw_q005_plant_at(q005_plant_drag_position, false)
	elif dragging_q006_decor >= 0:
		_draw_q006_decor_at(q006_decor_drag_position, dragging_q006_decor, true)
	elif dragging_q008_path >= 0:
		_draw_q008_path_paver_at(q008_path_drag_position, dragging_q008_path, true)
	elif dragging_q011_item >= 0:
		_draw_q011_item_at(q011_drag_position, dragging_q011_item, true)


func _draw_feedback_effects() -> void:
	if collect_sparkle_remaining > 0.0:
		var progress := 1.0 - collect_sparkle_remaining / COLLECT_SPARKLE_DURATION
		var fade := 1.0 - progress
		var ring_color := collect_sparkle_color
		ring_color.a = fade * 0.8
		draw_arc(collect_sparkle_position, 9.0 + progress * 27.0, 0.0, TAU, 32, ring_color, 2.5)
		for sparkle_id in range(8):
			var angle := TAU * float(sparkle_id) / 8.0 + animation_time * 1.3
			var direction := Vector2(cos(angle), sin(angle))
			var radius := 10.0 + progress * 25.0
			var sparkle_center := collect_sparkle_position + direction * radius
			draw_line(sparkle_center - direction * 3.5, sparkle_center + direction * 3.5, ring_color, 2.5)
			draw_circle(sparkle_center, 2.0 + fade, ring_color)
	if celebration_remaining > 0.0:
		var celebration_progress := 1.0 - celebration_remaining / CELEBRATION_DURATION
		var confetti_colors := [Color("f2c879"), Color("e96b70"), Color("67a9dc"), Color("a9df88"), Color("fff1a8")]
		for confetti_id in range(18):
			var fall := fposmod(celebration_progress + float(confetti_id) * 0.071, 1.0)
			var horizontal_start := float((confetti_id * 37) % 130) - 65.0
			var sway := sin(animation_time * 5.0 + float(confetti_id)) * 9.0
			var confetti_position := Q012_RABBIT_POSITION + Vector2(horizontal_start + sway, -82.0 + fall * 118.0)
			var confetti_color: Color = confetti_colors[confetti_id % confetti_colors.size()]
			confetti_color.a = clampf(celebration_remaining / 0.6, 0.0, 1.0)
			draw_rect(Rect2(confetti_position, Vector2(5, 8)), confetti_color, true)


func _draw_background() -> void:
	var viewport_size := get_viewport_rect().size
	var background_size := Vector2(maxf(WORLD_SIZE.x, viewport_size.x), maxf(WORLD_SIZE.y, viewport_size.y))
	draw_rect(Rect2(Vector2.ZERO, background_size), VISUAL_PALETTE["sky"])
	draw_rect(Rect2(0, 96, background_size.x, 54), VISUAL_PALETTE["sky_band"])
	var sun_pulse := sin(animation_time * 0.65)
	draw_circle(Vector2(1135, 82), 50.0 + sun_pulse * 2.0, Color(1.0, 0.91, 0.63, 0.18))
	draw_circle(Vector2(1135, 82), 42, VISUAL_PALETTE["sun"])
	var cloud_bases := [180.0, 540.0, 1010.0]
	for cloud_id in range(cloud_bases.size()):
		var cloud_phase := animation_time * 0.38 + float(cloud_id) * 1.9
		var cloud_x: float = cloud_bases[cloud_id] + sin(cloud_phase) * 7.0
		var cloud_y := 78.0 + sin(cloud_phase * 0.8) * 2.0
		draw_circle(Vector2(cloud_x, cloud_y), 22, VISUAL_PALETTE["cloud"])
		draw_circle(Vector2(cloud_x + 26, cloud_y + 4), 30, VISUAL_PALETTE["cloud"])
		draw_circle(Vector2(cloud_x + 58, cloud_y), 20, VISUAL_PALETTE["cloud"])


func _draw_world(font: Font) -> void:
	_draw_islands()
	_draw_river()
	_draw_bridge(font)
	_draw_rabbit_area(font)
	_draw_region_area(font)
	_draw_seed_area(font)
	_draw_pond_area(font)
	_draw_q004_area(font)
	_draw_q005_area(font)
	_draw_q006_area(font)
	_draw_q008_area(font)
	_draw_q007_area(font)
	_draw_q009_area(font)
	_draw_q010_area(font)
	_draw_q011_area(font)
	_draw_boards(font)
	_draw_player()


func _draw_islands() -> void:
	var left_island := PackedVector2Array([
		Vector2(64, 148), Vector2(94, 126), Vector2(170, 118), Vector2(286, 126),
		Vector2(430, 114), Vector2(570, 126), Vector2(680, 154), Vector2(716, 220),
		Vector2(712, 570), Vector2(670, 626), Vector2(528, 642), Vector2(380, 632),
		Vector2(210, 646), Vector2(100, 616), Vector2(62, 548),
	])
	var right_island := PackedVector2Array([
		Vector2(904, 150), Vector2(940, 126), Vector2(1024, 118), Vector2(1138, 126),
		Vector2(1208, 156), Vector2(1222, 220), Vector2(1218, 570), Vector2(1182, 624),
		Vector2(1070, 640), Vector2(958, 632), Vector2(908, 580),
	])
	_draw_island_shape(left_island, VISUAL_PALETTE["island_grass"])
	var right_color: Color = VISUAL_PALETTE["right_open"] if game_state.area_unlocked else VISUAL_PALETTE["right_locked"]
	_draw_island_shape(right_island, right_color)
	_draw_grass_details()
	_draw_ground_flowers()


func _draw_island_shape(points: PackedVector2Array, fill: Color) -> void:
	var shadow := PackedVector2Array()
	for point in points:
		shadow.append(point + Vector2(0, 8))
	draw_colored_polygon(shadow, VISUAL_PALETTE["island_shadow"])
	var outline := points.duplicate()
	outline.append(points[0])
	draw_polyline(outline, Color("d6c98c"), 13.0, true)
	draw_colored_polygon(points, fill)
	draw_polyline(outline, Color("67af70"), 7.0, true)
	draw_polyline(outline, VISUAL_PALETTE["island_highlight"], 5.0, true)


func _draw_grass_details() -> void:
	var grass_positions := [Vector2(126, 194), Vector2(176, 580), Vector2(652, 196), Vector2(1018, 556), Vector2(1160, 510)]
	for grass_id in range(grass_positions.size()):
		var position: Vector2 = grass_positions[grass_id]
		var sway := sin(animation_time * 1.7 + float(grass_id) * 1.4) * 2.0
		draw_line(position, position + Vector2(5 + sway, -10), VISUAL_PALETTE["island_highlight"], 3.0)
		draw_line(position + Vector2(4, 0), position + Vector2(13 + sway, -6), VISUAL_PALETTE["island_highlight"], 3.0)


func _draw_ground_flowers() -> void:
	var flower_positions := [Vector2(112, 264), Vector2(108, 438), Vector2(670, 264), Vector2(666, 502)]
	if game_state.area_unlocked:
		flower_positions.append(Vector2(1182, 205))
		flower_positions.append(Vector2(1182, 584))
	var flower_colors := [Color("f2a08e"), Color("fff0bd"), Color("c4e8ee"), Color("f2c879")]
	for cluster_id in range(flower_positions.size()):
		var cluster_position: Vector2 = flower_positions[cluster_id]
		var flower_color: Color = flower_colors[cluster_id % flower_colors.size()]
		_draw_ellipse_custom(cluster_position + Vector2(0, 8), Vector2(18, 5), Color(0.19, 0.29, 0.24, 0.10))
		for flower_id in range(3):
			var flower_offset := Vector2(float(flower_id - 1) * 10.0, -4.0 if flower_id != 1 else -12.0)
			var bob := sin(animation_time * 1.35 + float(cluster_id) * 0.8 + float(flower_id)) * 1.0
			var flower_center := cluster_position + flower_offset + Vector2(0, bob)
			draw_line(cluster_position + Vector2(0, 8), flower_center + Vector2(0, 3), Color("5d9e59"), 2.0)
			draw_circle(flower_center + Vector2(-3, 0), 3.0, flower_color)
			draw_circle(flower_center + Vector2(3, 0), 3.0, flower_color)
			draw_circle(flower_center + Vector2(0, -3), 3.0, flower_color)
			draw_circle(flower_center, 2.0, Color("ffe59a"))
		if cluster_id % 2 == 0:
			draw_circle(cluster_position + Vector2(-6, 3), 3.0, Color("8fcf78"))
			draw_circle(cluster_position + Vector2(6, 2), 3.0, Color("9bdc7f"))


func _draw_river() -> void:
	draw_rect(RIVER_RECT, VISUAL_PALETTE["river"])
	draw_rect(Rect2(RIVER_RECT.position + Vector2(10, 0), RIVER_RECT.size - Vector2(20, 0)), Color("55b9d7"))
	draw_line(Vector2(RIVER_RECT.position.x + 2, RIVER_RECT.position.y), Vector2(RIVER_RECT.position.x + 2, RIVER_RECT.end.y), VISUAL_PALETTE["river_edge"], 5.0)
	draw_line(Vector2(RIVER_RECT.end.x - 2, RIVER_RECT.position.y), Vector2(RIVER_RECT.end.x - 2, RIVER_RECT.end.y), VISUAL_PALETTE["river_edge"], 5.0)
	for y in range(150, 620, 58):
		var current_phase := animation_time * 1.15 + float(y) * 0.025
		var wave := PackedVector2Array([
			Vector2(744 + sin(current_phase) * 4.0, y),
			Vector2(778 + sin(current_phase + 0.9) * 4.0, y - 5 + sin(current_phase + 0.4) * 1.8),
			Vector2(812 + sin(current_phase + 1.8) * 4.0, y + 5 + sin(current_phase + 1.2) * 1.8),
			Vector2(846 + sin(current_phase + 2.7) * 4.0, y - 4 + sin(current_phase + 2.0) * 1.8),
			Vector2(875 + sin(current_phase + 3.6) * 4.0, y),
		])
		draw_polyline(wave, VISUAL_PALETTE["river_light"], 3.0, true)
	for glint_id in range(3):
		var glint_phase := animation_time * 1.8 + float(glint_id) * 1.7
		var glint_x := 730.0 + fposmod(animation_time * 15.0 + float(glint_id) * 48.0, 150.0)
		var glint_y := 190.0 + float(glint_id) * 145.0 + sin(glint_phase) * 5.0
		var glint_color := Color(0.91, 0.98, 0.86, 0.30 + (sin(glint_phase) + 1.0) * 0.12)
		draw_line(Vector2(glint_x, glint_y), Vector2(glint_x + 14.0, glint_y - 1.0), glint_color, 2.0)


func _draw_bridge(font: Font) -> void:
	draw_rect(Rect2(BRIDGE_RECT.position + Vector2(0, 10), BRIDGE_RECT.size), Color(0.19, 0.13, 0.10, 0.20))
	var bridge_color: Color = VISUAL_PALETTE["bridge_repaired"] if game_state.bridge_repaired else VISUAL_PALETTE["bridge_damaged"]
	draw_rect(BRIDGE_RECT, bridge_color)
	draw_rect(BRIDGE_RECT, VISUAL_PALETTE["bridge_edge"], false, 4.0)
	draw_line(Vector2(760, 330), Vector2(880, 330), VISUAL_PALETTE["bridge_edge"], 7.0)
	draw_line(Vector2(760, 420), Vector2(880, 420), VISUAL_PALETTE["bridge_edge"], 7.0)
	for post_x in [766.0, 874.0]:
		draw_line(Vector2(post_x, 324), Vector2(post_x, 426), VISUAL_PALETTE["bridge_edge"], 5.0)

	for slot_id in range(BRIDGE_SLOTS.size()):
		var slot: Rect2 = BRIDGE_SLOTS[slot_id]
		var slot_color: Color = VISUAL_PALETTE["bridge_edge"] if game_state.placed[slot_id] or game_state.bridge_repaired else Color("b98b57")
		draw_rect(slot, slot_color)
		draw_rect(slot, VISUAL_PALETTE["board_outline"], false, 3.0)
		draw_line(slot.position + Vector2(7, 5), slot.position + Vector2(7, slot.size.y - 5), Color("b8834d"), 2.0)
		if dragging_board >= 0 and slot_id == dragging_board and game_state.can_place_board(dragging_board):
			var target_color: Color = VISUAL_PALETTE["target_valid"] if _drag_target_slot_at(drag_position) == slot_id else VISUAL_PALETTE["target_idle"]
			var target_fill: Color = VISUAL_PALETTE["target_valid_fill"] if _drag_target_slot_at(drag_position) == slot_id else VISUAL_PALETTE["target_idle_fill"]
			draw_rect(_slot_drop_rect(slot_id), target_fill, true)
			draw_rect(_slot_drop_rect(slot_id), target_color, false, 4.0)
	if dragging_board >= 0:
		var drag_hint := "绿色高亮位置可以松开" if _drag_target_slot_at(drag_position) >= 0 else "把木板移到高亮位置再松开"
		draw_string(font, Vector2(700, 465), drag_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, VISUAL_PALETTE["ink"])
	if game_state.bridge_repaired:
		draw_line(Vector2(770, 342), Vector2(870, 342), Color("f4d28b"), 6.0)
		if bridge_repair_remaining > 0.0:
			var repair_progress := 1.0 - bridge_repair_remaining / BRIDGE_REPAIR_DURATION
			var shimmer_x := lerpf(770.0, 870.0, repair_progress)
			var shimmer_alpha := 1.0 - repair_progress
			_draw_ellipse_custom(Vector2(shimmer_x, 377), Vector2(18, 34), Color(1.0, 0.91, 0.57, shimmer_alpha * 0.5))
			draw_line(Vector2(shimmer_x, 345), Vector2(shimmer_x, 408), Color(1.0, 0.98, 0.78, shimmer_alpha), 4.0)
		draw_string(font, Vector2(760, 315), _bridge_status_text(), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("fff1a8"))
	else:
		draw_line(Vector2(800, 344), Vector2(814, 358), Color("49342c"), 3.0)
		draw_line(Vector2(818, 358), Vector2(832, 346), Color("49342c"), 3.0)
		draw_string(font, Vector2(752, 315), "损坏的小桥", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("fff1a8"))


func _draw_rabbit_area(font: Font) -> void:
	if not _should_show_rabbit_area():
		return
	if _should_show_rabbit_dialog():
		var bubble_fill := Color("fff7dc")
		_draw_panel(Rect2(392, 122, 400, 48), bubble_fill, Color("d7a85b"), 16)
		draw_colored_polygon(PackedVector2Array([Vector2(582, 170), Vector2(600, 170), Vector2(592, 188)]), bubble_fill)
		draw_circle(Vector2(414, 146), 12.0, Color("e8bd62"))
		draw_string(font, Vector2(436, 152), _rabbit_feedback_text(), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, VISUAL_PALETTE["ink"])
	_draw_rabbit(Q012_RABBIT_POSITION)
	if game_state.can_start_q012():
		draw_circle(Q012_RABBIT_POSITION + Vector2(0, -67), 13.0, Color("e8bd62"))
		draw_string(font, Q012_RABBIT_POSITION + Vector2(-5, -61), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("fff7dc"))
		draw_string(font, Q012_RABBIT_POSITION + Vector2(18, -63), "庆祝", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("526b43"))


func _should_show_rabbit_dialog() -> bool:
	return not game_state.is_complete() or not game_state.seed_planted or not game_state.is_q004_complete()


func _should_show_rabbit_area() -> bool:
	return _should_show_rabbit_dialog() or game_state.can_start_q012() or game_state.is_q012_complete()


func _draw_region_area(font: Font) -> void:
	if not _should_show_region_access_card():
		return
	_draw_panel(Rect2(928, 164, 270, 94), Color(0.86, 0.91, 0.86, 0.82), Color("c6d5c7"), 18)
	draw_string(font, Vector2(952, 194), "桥后区域", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, VISUAL_PALETTE["ink"])
	draw_string(font, Vector2(952, 226), "修好小桥后开放", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, VISUAL_PALETTE["ink"])
	draw_string(font, Vector2(945, 360), "暂时不能通过", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("52685b"))


func _should_show_region_access_card() -> bool:
	return not game_state.area_unlocked


func _draw_seed_area(font: Font) -> void:
	if not game_state.is_complete() or game_state.is_pond_complete():
		return
	var bed_rect := Rect2(FLOWERBED_POSITION - Vector2(48, 32), Vector2(96, 64))
	draw_rect(Rect2(bed_rect.position + Vector2(0, 8), bed_rect.size), Color(0.19, 0.13, 0.10, 0.16))
	draw_rect(bed_rect, Color("a8784e"))
	draw_rect(bed_rect, Color("704d35"), false, 4.0)
	for row_y in [18.0, 34.0, 50.0]:
		draw_line(bed_rect.position + Vector2(10, row_y), bed_rect.position + Vector2(86, row_y), Color("d09a62"), 2.0)
	if game_state.seed_planted:
		var seedling_sway := sin(animation_time * 1.45 + 0.7) * 2.2
		var stem_base := FLOWERBED_POSITION + Vector2(0, 18)
		var stem_joint := FLOWERBED_POSITION + Vector2(seedling_sway * 0.35, 2)
		var stem_top := FLOWERBED_POSITION + Vector2(seedling_sway, -14)
		draw_line(stem_base, stem_joint, Color("4f9e55"), 5.0)
		draw_line(stem_joint, stem_top, Color("4f9e55"), 5.0)
		draw_circle(stem_top + Vector2(-10, 0), 9.0, Color("78c977"))
		draw_circle(stem_top + Vector2(10, 0), 9.0, Color("9be087"))
		draw_string(font, FLOWERBED_POSITION + Vector2(-30, 48), "幼苗", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, VISUAL_PALETTE["ink"])
	else:
		draw_string(font, FLOWERBED_POSITION + Vector2(-30, 48), "空花圃", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, VISUAL_PALETTE["ink"])
	if not game_state.seed_collected:
		draw_circle(SEED_POSITION + Vector2(0, 5), 15.0, Color(0.19, 0.13, 0.10, 0.16))
		draw_circle(SEED_POSITION, 12.0, Color("f2c879"))
		draw_arc(SEED_POSITION, 12.0, 0.0, TAU, 24, Color("704d35"), 3.0)
		draw_circle(SEED_POSITION + Vector2(-4, -4), 3.0, Color("fff1a8"))
		draw_string(font, SEED_POSITION + Vector2(-24, 34), "种子", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, VISUAL_PALETTE["ink"])


func _draw_pond_area(font: Font) -> void:
	if not _can_show_pond_area():
		return
	var pond_fill := Color("78cbd5") if not game_state.is_pond_complete() else Color("5bbbd0")
	_draw_panel(POND_RECT, pond_fill, VISUAL_PALETTE["river_edge"], 24)
	var pond_line_offsets := [34.0, 62.0, 90.0] if game_state.is_pond_complete() else [34.0, 66.0, 98.0]
	for line_id in range(pond_line_offsets.size()):
		var y: float = POND_RECT.position.y + pond_line_offsets[line_id]
		var wave_phase := animation_time * 0.9 + float(line_id) * 1.2
		var wave := PackedVector2Array([
			Vector2(POND_RECT.position.x + 18, y + sin(wave_phase) * 1.2),
			Vector2(POND_RECT.get_center().x, y + sin(wave_phase + 1.1) * 2.0),
			Vector2(POND_RECT.end.x - 18, y + sin(wave_phase + 2.2) * 1.2),
		])
		draw_polyline(wave, Color("a9e3e6"), 3.0, true)
	draw_string(font, POND_RECT.position + Vector2(54, -12), "池塘", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, VISUAL_PALETTE["ink"])
	if game_state.is_pond_complete():
		draw_string(font, POND_RECT.position + Vector2(34, 118), "池塘已开放", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("fff1a8"))
		return

	for slot_id in range(GameState.POND_STONE_TOTAL):
		var slot: Rect2 = POND_SLOTS[slot_id]
		var slot_color: Color = VISUAL_PALETTE["target_valid"] if game_state.pond_stones_placed[slot_id] else VISUAL_PALETTE["target_idle"]
		var slot_fill: Color = VISUAL_PALETTE["target_valid_fill"] if game_state.pond_stones_placed[slot_id] else VISUAL_PALETTE["target_idle_fill"]
		draw_rect(slot, slot_fill, true)
		draw_rect(slot, slot_color, false, 3.0)
		if game_state.pond_stones_placed[slot_id]:
			_draw_pond_stone_at(slot.position + slot.size / 2.0, Color("8d9a9c"), false)
		else:
			draw_string(font, slot.position + Vector2(12, 22), "轮廓", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, VISUAL_PALETTE["ink"])
	for stone_id in range(GameState.POND_STONE_TOTAL):
		if not game_state.pond_stones_placed[stone_id]:
			_draw_pond_stone_at(POND_STONE_POSITIONS[stone_id], Color("8d9a9c"), false)
			draw_string(font, POND_STONE_POSITIONS[stone_id] + Vector2(-18, 30), "石头", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, VISUAL_PALETTE["ink"])
	if dragging_pond_stone >= 0:
		var drag_hint := "绿色轮廓可以松开" if _pond_drag_target_at(pond_drag_position) >= 0 else "把石头移到对应轮廓再松开"
		draw_string(font, Vector2(936, 535), drag_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, VISUAL_PALETTE["ink"])


func _draw_q004_area(font: Font) -> void:
	if not game_state.seed_planted:
		return
	var house_fill := Color("d9f0d0") if not game_state.is_q004_complete() else Color("f4e5bd")
	var house_border := Color("7eae72") if not game_state.is_q004_complete() else Color("bd8b54")
	_draw_panel(HOUSE_RECT, house_fill, house_border, 18)
	var roof := PackedVector2Array([
		Vector2(HOUSE_RECT.position.x + 8, HOUSE_RECT.position.y + 34),
		Vector2(HOUSE_RECT.position.x + HOUSE_RECT.size.x / 2.0, HOUSE_RECT.position.y - 8),
		Vector2(HOUSE_RECT.end.x - 8, HOUSE_RECT.position.y + 34),
	])
	draw_colored_polygon(roof, Color("d7865d") if not game_state.is_q004_complete() else Color("d96f58"))
	draw_polyline(PackedVector2Array([roof[0], roof[1], roof[2]]), Color("704d35"), 4.0, true)
	draw_line(Vector2(HOUSE_RECT.position.x + 24, HOUSE_RECT.position.y + 30), Vector2(HOUSE_POSITION.x, HOUSE_RECT.position.y - 4), Color("efab76"), 2.0)
	draw_line(Vector2(HOUSE_POSITION.x, HOUSE_RECT.position.y - 4), Vector2(HOUSE_RECT.end.x - 24, HOUSE_RECT.position.y + 30), Color("efab76"), 2.0)
	var wall_rect := Rect2(HOUSE_RECT.position + Vector2(7, 34), Vector2(HOUSE_RECT.size.x - 14, HOUSE_RECT.size.y - 42))
	draw_rect(wall_rect, Color("fff1cb"), false, 2.0)
	for window_x in [HOUSE_RECT.position.x + 20.0, HOUSE_RECT.end.x - 36.0]:
		var window_rect := Rect2(window_x, HOUSE_POSITION.y - 5, 16, 20)
		draw_rect(window_rect.grow(2), Color("8b6346"), true)
		draw_rect(window_rect, Color("b5d7c3"), true)
		draw_rect(window_rect, Color("fff2c7"), false, 2.0)
		draw_line(Vector2(window_rect.position.x + 8, window_rect.position.y + 2), Vector2(window_rect.position.x + 8, window_rect.end.y - 2), Color("fff2c7"), 1.5)
	draw_rect(Rect2(HOUSE_POSITION.x - 24, HOUSE_POSITION.y - 4, 48, 58), Color("c58b55"))
	draw_rect(Rect2(HOUSE_POSITION.x - 24, HOUSE_POSITION.y - 4, 48, 58), Color("704d35"), false, 3.0)
	draw_circle(HOUSE_POSITION + Vector2(14, 22), 4.0, Color("ffe59a"))
	if game_state.is_q004_complete():
		draw_string(font, HOUSE_POSITION + Vector2(-52, 78), "狐狸的小屋", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, VISUAL_PALETTE["ink"])
		_draw_fox(HOUSE_POSITION + Vector2(0, -42))
	else:
		draw_string(font, HOUSE_POSITION + Vector2(-58, 78), "小屋建造中", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, VISUAL_PALETTE["ink"])
		draw_string(font, HOUSE_POSITION + Vector2(-54, 98), "交付 %d/3" % game_state.delivered_wood_count(), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, VISUAL_PALETTE["ink"])

	if game_state.is_q004_complete():
		return
	for wood_id in range(GameState.Q004_WOOD_TOTAL):
		if game_state.wood_collected[wood_id]:
			continue
		_draw_wood_at(WOOD_POSITIONS[wood_id])
		draw_string(font, WOOD_POSITIONS[wood_id] + Vector2(-24, 34), "木材", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, VISUAL_PALETTE["ink"])


func _draw_q005_area(font: Font) -> void:
	if not game_state.is_q004_complete() or not game_state.is_pond_complete():
		return
	var garden_fill := Color("b9d98b") if not game_state.q005_watered else Color("9ed477")
	var garden_border := Color("d5a45f") if not game_state.is_q005_complete() else Color("6cae87")
	_draw_panel(Q005_GARDEN_RECT, garden_fill, garden_border, 18)
	draw_string(font, Q005_GARDEN_RECT.position + Vector2(18, -12), "乌龟的花园", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, VISUAL_PALETTE["ink"])
	for slot_id in range(GameState.Q005_PLANT_TOTAL):
		var slot: Rect2 = Q005_PLANT_SLOTS[slot_id]
		var is_drag_target := _q005_plant_slot_is_drop_target(slot_id)
		var is_pointer_over_target := _q005_plant_slot_is_hovered(slot_id)
		var is_highlighted: bool = game_state.q005_plant_slots[slot_id] or is_drag_target
		var slot_color: Color = VISUAL_PALETTE["target_valid"] if is_highlighted else VISUAL_PALETTE["target_idle"]
		var slot_fill: Color = VISUAL_PALETTE["target_valid_fill"] if is_highlighted else VISUAL_PALETTE["target_idle_fill"]
		draw_rect(slot, slot_fill, true)
		if is_pointer_over_target:
			draw_rect(slot.grow(8), Color(0.20, 0.90, 0.40, 0.36), true)
			draw_rect(slot.grow(8), Color("16883f"), false, 5.0)
			draw_rect(slot, Color(0.58, 1.0, 0.56, 0.48), true)
		draw_rect(slot, Color("16883f") if is_drag_target else slot_color, false, 5.0 if is_drag_target else 3.0)
		if game_state.q005_plant_slots[slot_id]:
			_draw_q005_plant_at(slot.position + slot.size / 2.0, true, game_state.is_q010_complete())
		else:
			draw_string(font, slot.position + Vector2(5, 19), "空槽", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, VISUAL_PALETTE["ink"])
	for plant_id in range(GameState.Q005_PLANT_TOTAL):
		if game_state.q005_plants_collected[plant_id]:
			continue
		var plant_position: Vector2 = Q005_PLANT_POSITIONS[plant_id]
		var plant_scale := 1.0
		if game_state.q005_watered and q005_growth_remaining > 0.0:
			var growth_progress := clampf(1.0 - q005_growth_remaining / Q005_GROWTH_DURATION, 0.0, 1.0)
			var eased_growth := growth_progress * growth_progress * (3.0 - 2.0 * growth_progress)
			plant_scale = lerpf(0.35, 1.0, eased_growth)
			plant_position.y -= eased_growth * 9.0
		_draw_q005_plant_at(plant_position, false, false, not game_state.q005_watered, plant_scale)
		draw_string(font, Q005_PLANT_POSITIONS[plant_id] + Vector2(-26, 30), "待浇水" if not game_state.q005_watered else "植物", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VISUAL_PALETTE["ink"])

	var watering_color := Color("5bbbd0") if not game_state.q005_watered else Color("78c977")
	if not game_state.q005_watered:
		draw_circle(Q005_WATERING_POINT_POSITION, 23.0, Color(1.0, 0.90, 0.46, 0.18))
		draw_arc(Q005_WATERING_POINT_POSITION, 20.0, 0.0, TAU, 28, Color("fff1a8"), 3.0)
	draw_circle(Q005_WATERING_POINT_POSITION + Vector2(0, 7), 15.0, Color(0.19, 0.13, 0.10, 0.16))
	draw_circle(Q005_WATERING_POINT_POSITION, 13.0, watering_color)
	draw_arc(Q005_WATERING_POINT_POSITION, 13.0, 0.0, TAU, 20, Color("3d7f7b"), 3.0)
	draw_line(Q005_WATERING_POINT_POSITION + Vector2(-4, -4), Q005_WATERING_POINT_POSITION + Vector2(5, 4), Color("e5fbf2"), 3.0)
	draw_string(font, Q005_WATERING_POINT_POSITION + Vector2(-25, 32), "已浇水" if game_state.q005_watered else "先浇水", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, VISUAL_PALETTE["ink"])
	_draw_turtle(Q005_TURTLE_POSITION)
	draw_string(font, Q005_TURTLE_POSITION + Vector2(-24, 55), "乌龟", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, VISUAL_PALETTE["ink"])
	if dragging_q005_plant >= 0:
		var drag_hint := "绿色槽位可以松开" if _q005_plant_drag_target_at(q005_plant_drag_position) >= 0 else "把幼苗移到绿色槽位再松开"
		draw_string(font, Vector2(930, 540), drag_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, VISUAL_PALETTE["ink"])


func _draw_q006_area(font: Font) -> void:
	if not _can_use_q006_build_mode():
		return
	var placed_count: int = game_state.q006_placed_count()
	if not build_mode and placed_count == 0:
		return
	_draw_panel(Q006_DECOR_PLOT_RECT, Color("c7df9b"), Color("6cae87"), 14)
	draw_string(font, Vector2(Q006_DECOR_PLOT_RECT.position.x + 8, Q006_DECOR_PLOT_RECT.position.y - 6), "花园装饰区", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, VISUAL_PALETTE["ink"])
	for slot_id in range(GameState.Q006_SLOT_TOTAL):
		var slot: Rect2 = Q006_DECOR_SLOTS[slot_id]
		var decor_id: int = game_state.q006_slot_occupants[slot_id]
		if decor_id >= 0 and not (dragging_q006_decor == decor_id and q006_decor_drag_from_slot == slot_id):
			_draw_q006_decor_at(slot.position + slot.size / 2.0, decor_id, false)
		elif _should_show_q006_slots():
			var is_drop_target := _q006_decor_slot_is_drop_target(slot_id)
			var is_hovered_target := _q006_decor_slot_is_hovered(slot_id)
			var slot_color: Color = VISUAL_PALETTE["target_valid"] if is_drop_target else VISUAL_PALETTE["target_idle"]
			var slot_fill: Color = VISUAL_PALETTE["target_valid_fill"] if is_drop_target else VISUAL_PALETTE["target_idle_fill"]
			draw_rect(slot, slot_fill, true)
			if is_hovered_target:
				draw_rect(slot.grow(8), Color(0.20, 0.90, 0.40, 0.36), true)
				draw_rect(slot.grow(8), Color("16883f"), false, 5.0)
				draw_rect(slot, Color(0.58, 1.0, 0.56, 0.48), true)
			draw_rect(slot, Color("16883f") if is_drop_target else slot_color, false, 5.0 if is_drop_target else 3.0)
			draw_string(font, slot.position + Vector2(17, 23), "装饰位", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, VISUAL_PALETTE["ink"])


func _should_show_q006_slots() -> bool:
	return build_mode and _can_use_q006_build_mode()


func _draw_q008_area(font: Font) -> void:
	if not _can_use_q008_side_task():
		return

	var path_complete: bool = game_state.is_q008_complete()
	if path_complete:
		draw_rect(Rect2(526, 358, 184, 34), Color("d5a468"), true)
		draw_rect(Rect2(526, 358, 184, 34), Color("704d35"), false, 3.0)

	for slot_id in range(GameState.Q008_PATH_SLOT_TOTAL):
		var slot: Rect2 = Q008_PATH_SLOT_RECTS[slot_id]
		var material_id: int = game_state.q008_path_slot_occupants[slot_id]
		if material_id >= 0:
			_draw_q008_path_paver_at(slot.position + slot.size / 2.0, material_id, false)
		else:
			var is_drop_target := _q008_path_slot_is_drop_target(slot_id)
			var is_hovered := _q008_path_slot_is_hovered(slot_id)
			var slot_fill: Color = VISUAL_PALETTE["target_valid_fill"] if is_drop_target else VISUAL_PALETTE["target_idle_fill"]
			var slot_border: Color = VISUAL_PALETTE["target_valid"] if is_drop_target else VISUAL_PALETTE["target_idle"]
			draw_rect(slot, slot_fill, true)
			if is_hovered:
				draw_rect(slot.grow(8), Color(0.20, 0.90, 0.40, 0.36), true)
				draw_rect(slot.grow(8), Color("16883f"), false, 5.0)
				draw_rect(slot, Color(0.58, 1.0, 0.56, 0.48), true)
			draw_rect(slot, slot_border, false, 4.0 if is_drop_target else 3.0)
			draw_string(font, slot.position + Vector2(9, 18), "空槽", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, VISUAL_PALETTE["ink"])

	if path_complete:
		draw_string(font, Vector2(566, 342), "小路已连起来", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("fff1a8"))
	if dragging_q008_path >= 0:
		var drag_hint := "空槽可以松开" if _q008_path_slot_at(q008_path_drag_position) >= 0 else "把石板移到小路空槽再松开"
		draw_string(font, Vector2(520, 420), drag_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, VISUAL_PALETTE["ink"])


func _q008_prompt_text() -> String:
	if game_state.is_q008_complete():
		return "小路连起来完成！"
	return "小路任务：已铺设 %d/3 块路面石板。" % game_state.q008_path_placed_count()


func _draw_q007_area(font: Font) -> void:
	if not _can_use_q007_side_task():
		return
	if game_state.q007_shell_collected:
		if game_state.q007_reward_unlocked:
			_draw_q007_shell_at(Q007_REWARD_POSITION, true)
			draw_string(font, Q007_REWARD_POSITION + Vector2(-48, 42), "珍珠贝壳摆件", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, VISUAL_PALETTE["ink"])
		return
	_draw_q007_shell_at(Q007_SHELL_POSITION, false)
	draw_string(font, Q007_SHELL_POSITION + Vector2(-28, 38), "隐藏贝壳", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, VISUAL_PALETTE["ink"])


func _draw_q009_area(font: Font) -> void:
	if not _should_show_q009_task_card():
		return
	var complete: bool = game_state.is_q009_complete()
	var panel_color: Color = Color(0.91, 0.93, 0.86, 0.82) if complete else Color(0.82, 0.96, 0.80, 0.86)
	var panel_border: Color = Color("a9bda3") if complete else VISUAL_PALETTE["island_highlight"]
	_draw_panel(Rect2(74, 222, 300, 76), panel_color, panel_border, 16)
	draw_string(font, Vector2(94, 251), _q009_prompt_text(), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, VISUAL_PALETTE["ink"])
	draw_string(font, Vector2(94, 278), _q009_action_hint_text(), HORIZONTAL_ALIGNMENT_LEFT, 260, 14, VISUAL_PALETTE["ink"])
	if not game_state.is_q009_complete():
		for material_id in range(GameState.Q009_MATERIAL_TOTAL):
			if game_state.q009_materials_collected[material_id]:
				continue
			var material_position: Vector2 = Q009_MATERIAL_POSITIONS[material_id]
			_draw_q009_material_at(material_position, material_id)
			draw_string(font, material_position + Vector2(-24, 34), Q009_MATERIAL_LABELS[material_id], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, VISUAL_PALETTE["ink"])
	else:
		_draw_q009_birdhouse(Q009_BIRDHOUSE_POSITION)
		_draw_q009_bird(Q009_BIRD_POSITION)
		draw_string(font, Q009_BIRDHOUSE_POSITION + Vector2(-26, 62), "鸟屋", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, VISUAL_PALETTE["ink"])
		draw_string(font, Q009_BIRD_POSITION + Vector2(-44, -30), "小鸟：欢迎！", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("fff1a8"))


func _q009_prompt_text() -> String:
	if game_state.is_q009_complete():
		return "鸟屋计划完成！小鸟互动已开放。"
	return "鸟屋计划：已收集 %d/3 份材料。" % game_state.q009_material_count()


func _q009_action_hint_text() -> String:
	if game_state.is_q009_complete():
		return "可选：靠近小鸟按互动键打招呼。"
	return "找到树枝、羽毛和草绳，靠近后按互动键收集。"


func _draw_q010_area(font: Font) -> void:
	if not _should_show_q010_task_card():
		return
	var complete: bool = game_state.is_q010_complete()
	var panel_color: Color = Color(0.91, 0.93, 0.86, 0.82) if complete else Color(0.82, 0.96, 0.80, 0.86)
	var panel_border: Color = Color("a9bda3") if complete else VISUAL_PALETTE["island_highlight"]
	_draw_panel(Rect2(74, 312, 300, 76), panel_color, panel_border, 16)
	draw_string(font, Vector2(92, 342), _q010_prompt_text(), HORIZONTAL_ALIGNMENT_LEFT, 270, 17, VISUAL_PALETTE["ink"])
	draw_string(font, Vector2(92, 371), _q010_action_hint_text(), HORIZONTAL_ALIGNMENT_LEFT, 270, 14, VISUAL_PALETTE["ink"])
	if game_state.is_q010_complete():
		return
	for seed_id in range(GameState.Q010_SEED_TOTAL):
		if game_state.q010_seeds_collected[seed_id]:
			continue
		var seed_position: Vector2 = Q010_SEED_POSITIONS[seed_id]
		_draw_q010_seed_at(seed_position, seed_id)
		draw_string(font, seed_position + Vector2(-34, 32), Q010_SEED_LABELS[seed_id], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, VISUAL_PALETTE["ink"])


func _draw_q011_area(font: Font) -> void:
	if not _can_show_q011_area():
		return
	var complete: bool = game_state.is_q011_complete()
	var fill := Color("bfe4a0") if complete else Color("c7ad79")
	var border := Color("478b5b") if complete else Color("8a6846")
	_draw_panel(Q011_AREA_RECT, fill, border, 12)
	if complete:
		for stone_position in [Vector2(207, 608), Vector2(238, 608), Vector2(269, 608), Vector2(300, 608), Vector2(331, 608), Vector2(363, 608)]:
			_draw_ellipse_custom(stone_position, Vector2(9, 4), Color("d8c49a"))
			_draw_ellipse_custom(stone_position + Vector2(0, -1), Vector2(6, 2), Color("f0dfba"))
		for flower_position in [Vector2(202, 574), Vector2(377, 574)]:
			draw_circle(flower_position, 4.0, Color("e96b70"))
			draw_circle(flower_position + Vector2(-4, -2), 3.0, Color("fff1a8"))
			draw_circle(flower_position + Vector2(4, -2), 3.0, Color("fff1a8"))
		draw_string(font, Vector2(222, 567), "额外地块 · 已整理", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("214232"))
	else:
		draw_line(Vector2(201, 569), Vector2(206, 562), Color("668949"), 3.0)
		draw_line(Vector2(378, 569), Vector2(383, 562), Color("668949"), 3.0)
		draw_string(font, Vector2(216, 567), "整理物品 · %d/3" % game_state.q011_placed_count(), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("3e392b"))
	for slot_id in range(GameState.Q011_ITEM_TOTAL):
		var slot: Rect2 = Q011_SLOT_RECTS[slot_id]
		var item_id: int = game_state.q011_slot_occupants[slot_id]
		if complete:
			draw_rect(slot, Color("e3efc7"), true)
			draw_rect(slot, Color("559164"), false, 2.0)
		else:
			draw_rect(slot, Color("eed8a3"), true)
			draw_rect(slot, Color("896c47"), false, 2.0)
		if item_id >= 0:
			_draw_q011_item_at(slot.position + slot.size / 2.0, item_id, false)
		elif not (dragging_q011_item >= 0 and _q011_slot_at(q011_drag_position) == slot_id):
			draw_string(font, slot.position + Vector2(17, 17), "空", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("51442f"))
		if dragging_q011_item >= 0 and _q011_slot_at(q011_drag_position) == slot_id:
			draw_rect(slot.grow(5), VISUAL_PALETTE["target_valid_fill"], true)
			draw_rect(slot.grow(5), VISUAL_PALETTE["target_valid"], false, 3.0)
	if dragging_q011_item >= 0:
		var hint := "空槽可以松开" if _q011_slot_at(q011_drag_position) >= 0 else "把物品移到空槽再松开"
		draw_string(font, Vector2(202, 638), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, VISUAL_PALETTE["ink"])


func _draw_q011_item_at(position: Vector2, item_id: int, lifted: bool) -> void:
	var item_position := position - Vector2(0, 7) if lifted else position
	_draw_ellipse_custom(item_position + Vector2(0, 13), Vector2(19, 5), Color(0.19, 0.13, 0.10, 0.16))
	if lifted:
		draw_arc(item_position, 25.0, 0.0, TAU, 24, VISUAL_PALETTE["target_idle"], 3.0)
	if item_id == 0:
		var crate := Rect2(item_position + Vector2(-16, -10), Vector2(32, 20))
		draw_rect(crate, Color("bd814e"), true)
		draw_rect(crate, Color("704d35"), false, 2.0)
		draw_line(item_position + Vector2(-11, -8), item_position + Vector2(11, 8), Color("e3b575"), 2.0)
		draw_line(item_position + Vector2(11, -8), item_position + Vector2(-11, 8), Color("e3b575"), 2.0)
		draw_line(item_position + Vector2(0, -8), item_position + Vector2(0, 8), Color("8a5a39"), 2.0)
	elif item_id == 1:
		var bag := PackedVector2Array([
			item_position + Vector2(-14, -5), item_position + Vector2(-10, -11), item_position + Vector2(-4, -8),
			item_position + Vector2(1, -12), item_position + Vector2(7, -8), item_position + Vector2(13, -4),
			item_position + Vector2(11, 9), item_position + Vector2(5, 12), item_position + Vector2(-8, 11),
			item_position + Vector2(-14, 6),
		])
		draw_colored_polygon(bag, Color("d67e69"))
		draw_polyline(PackedVector2Array([bag[0], bag[1], bag[2], bag[3], bag[4], bag[5]]), Color("8a5148"), 2.0)
		draw_line(item_position + Vector2(-8, 1), item_position + Vector2(7, 3), Color("f3b89a"), 2.0)
		draw_line(item_position + Vector2(0, -10), item_position + Vector2(2, -15), Color("8a5148"), 2.0)
	else:
		var basket := PackedVector2Array([
			item_position + Vector2(-15, -3), item_position + Vector2(15, -3),
			item_position + Vector2(11, 10), item_position + Vector2(-11, 10),
		])
		draw_arc(item_position + Vector2(0, -5), 11.0, PI, TAU, 16, Color("815b36"), 2.0)
		draw_colored_polygon(basket, Color("d6aa62"))
		draw_polyline(PackedVector2Array([basket[0], basket[1], basket[2], basket[3], basket[0]]), Color("815b36"), 2.0)
		for weave_x in [-7.0, 0.0, 7.0]:
			draw_line(item_position + Vector2(weave_x - 3, -1), item_position + Vector2(weave_x - 1, 8), Color("f0d18b"), 2.0)
		draw_line(item_position + Vector2(-15, -3), item_position + Vector2(15, -3), Color("f1cf86"), 3.0)


func _q010_prompt_text() -> String:
	if game_state.is_q010_complete():
		return "种子收藏完成！植物外观已解锁。"
	return "种子收藏：已收集 %d/3 个指定种子。" % game_state.q010_seed_count()


func _q010_action_hint_text() -> String:
	if game_state.is_q010_complete():
		return "可选：回乌龟花园看看新花。"
	return "找到红花种子、蓝花种子和金色种子，靠近后按互动键收集。"


func _draw_q010_seed_at(position: Vector2, seed_id: int) -> void:
	var colors := [Color("e96b70"), Color("67a9dc"), Color("f0c85e")]
	var accent_colors := [Color("ffd0a8"), Color("d5f2ff"), Color("fff3ad")]
	_draw_ellipse_custom(position + Vector2(0, 12), Vector2(18, 6), Color(0.19, 0.13, 0.10, 0.16))
	draw_circle(position, 12.0, colors[seed_id])
	draw_arc(position, 12.0, 0.0, TAU, 20, Color("704d35"), 3.0)
	draw_circle(position + Vector2(-4, -4), 3.0, accent_colors[seed_id])
	if seed_id == 0:
		draw_circle(position + Vector2(5, 4), 3.0, Color("c6475c"))
	elif seed_id == 1:
		draw_line(position + Vector2(-6, 6), position + Vector2(6, -6), accent_colors[seed_id], 2.0)
	else:
		draw_line(position + Vector2(0, -8), position + Vector2(0, 8), accent_colors[seed_id], 2.0)
		draw_line(position + Vector2(-8, 0), position + Vector2(8, 0), accent_colors[seed_id], 2.0)


func _draw_q009_material_at(position: Vector2, material_id: int) -> void:
	_draw_ellipse_custom(position + Vector2(0, 15), Vector2(25, 6), Color(0.19, 0.13, 0.10, 0.16))
	if material_id == 0:
		draw_line(position + Vector2(-22, 8), position + Vector2(22, -8), Color("8e5d3c"), 8.0)
		draw_line(position + Vector2(-18, 3), position + Vector2(18, -11), Color("d5a468"), 3.0)
		draw_circle(position + Vector2(-8, 1), 5.0, Color("78c977"))
		draw_circle(position + Vector2(10, -9), 5.0, Color("9be087"))
	elif material_id == 1:
		var feather := PackedVector2Array([
			position + Vector2(0, 16), position + Vector2(-16, -12), position + Vector2(-4, -24),
			position + Vector2(13, -10),
		])
		draw_colored_polygon(feather, Color("fff4df"))
		draw_polyline(PackedVector2Array([position + Vector2(0, 16), position + Vector2(1, -20)]), Color("d7a85b"), 3.0)
	else:
		draw_arc(position + Vector2(0, -2), 17.0, -0.6, TAU - 0.6, 20, Color("d7865d"), 7.0)
		draw_arc(position + Vector2(0, -2), 10.0, 0.1, TAU + 0.1, 20, Color("f0bd78"), 4.0)


func _draw_q009_birdhouse(position: Vector2) -> void:
	_draw_ellipse_custom(position + Vector2(0, 34), Vector2(38, 8), Color(0.19, 0.13, 0.10, 0.16))
	draw_rect(Rect2(position + Vector2(-34, -22), Vector2(68, 54)), Color("d5a468"))
	draw_rect(Rect2(position + Vector2(-34, -22), Vector2(68, 54)), Color("704d35"), false, 3.0)
	var roof := PackedVector2Array([
		position + Vector2(-42, -20), position + Vector2(0, -52), position + Vector2(42, -20),
	])
	draw_colored_polygon(roof, Color("d96f58"))
	draw_polyline(PackedVector2Array([roof[0], roof[1], roof[2]]), Color("704d35"), 4.0, true)
	draw_circle(position + Vector2(0, 1), 13.0, Color("704d35"))
	draw_circle(position + Vector2(0, 1), 8.0, Color("3f5b4a"))
	draw_line(position + Vector2(0, 28), position + Vector2(0, 40), Color("704d35"), 4.0)


func _draw_q009_bird(position: Vector2) -> void:
	_draw_ellipse_custom(position + Vector2(0, 18), Vector2(20, 6), Color(0.19, 0.13, 0.10, 0.16))
	draw_circle(position, 15.0, Color("8ab9d1"))
	draw_circle(position + Vector2(-8, -12), 7.0, Color("8ab9d1"))
	draw_circle(position + Vector2(8, -12), 7.0, Color("8ab9d1"))
	_draw_ellipse_custom(position + Vector2(-7, 3), Vector2(8, 12), Color("5f96b3"))
	draw_circle(position + Vector2(5, -3), 2.5, Color("253b32"))
	draw_colored_polygon(PackedVector2Array([
		position + Vector2(15, -1), position + Vector2(25, 4), position + Vector2(15, 7),
	]), Color("e0a15f"))


func _draw_q006_decor_at(position: Vector2, decor_id: int, lifted: bool) -> void:
	var shadow_color := Color(0.19, 0.13, 0.10, 0.16)
	if decor_id == 0:
		_draw_ellipse_custom(position + Vector2(0, 11), Vector2(29, 6), shadow_color)
		for post_x in [-20.0, 0.0, 20.0]:
			draw_rect(Rect2(position + Vector2(post_x - 3, -16), Vector2(6, 28)), Color("9a6940"))
		for rail_y in [-9.0, 3.0]:
			draw_line(position + Vector2(-24, rail_y), position + Vector2(24, rail_y), Color("d5a468"), 5.0)
	elif decor_id == 1:
		_draw_ellipse_custom(position + Vector2(0, 12), Vector2(24, 6), shadow_color)
		draw_rect(Rect2(position + Vector2(-18, -8), Vector2(36, 21)), Color("d87862"))
		draw_rect(Rect2(position + Vector2(-21, -12), Vector2(42, 7)), Color("f2a16f"))
		draw_line(position + Vector2(0, -12), position + Vector2(0, -27), Color("4f9e55"), 4.0)
		draw_circle(position + Vector2(-8, -27), 7.0, Color("78c977"))
		draw_circle(position + Vector2(8, -27), 7.0, Color("9be087"))
	else:
		_draw_ellipse_custom(position + Vector2(0, 12), Vector2(23, 6), shadow_color)
		draw_line(position + Vector2(0, 10), position + Vector2(0, -25), Color("704d35"), 5.0)
		draw_circle(position + Vector2(0, -29), 11.0, Color("ffe59a"))
		draw_circle(position + Vector2(0, -29), 7.0, Color("f2c879"))
		draw_arc(position + Vector2(0, -29), 11.0, 0.0, TAU, 20, Color("704d35"), 3.0)
	if lifted:
		draw_arc(position, 31.0, 0.0, TAU, 24, VISUAL_PALETTE["target_idle"], 3.0)


func _draw_q007_shell_at(position: Vector2, reward: bool) -> void:
	_draw_ellipse_custom(position + Vector2(0, 12), Vector2(24, 7), Color(0.19, 0.13, 0.10, 0.16))
	var shell_color := Color("f0b7a4") if reward else Color("d89a87")
	_draw_ellipse_custom(position, Vector2(23, 15), shell_color)
	draw_arc(position, 22.0, PI, TAU, 18, Color("704d5a"), 3.0)
	for ridge_x in [-10.0, 0.0, 10.0]:
		draw_line(position + Vector2(ridge_x, -8), position + Vector2(ridge_x * 0.55, 9), Color("f6d0b5"), 2.0)
	if reward:
		draw_circle(position + Vector2(0, -3), 8.0, Color("fff4df"))
		draw_circle(position + Vector2(-2, -5), 3.0, Color("ffffff"))


func _draw_q008_path_paver_at(position: Vector2, material_id: int, lifted: bool) -> void:
	var paver_position := position - Vector2(0, 5) if lifted else position
	var colors := [Color("d5a468"), Color("c4935c"), Color("e0b879")]
	var paver_color: Color = colors[material_id]
	_draw_ellipse_custom(paver_position + Vector2(0, 13), Vector2(29, 7), Color(0.19, 0.13, 0.10, 0.16))
	if lifted:
		draw_rect(Rect2(paver_position - Vector2(30, 15), Vector2(60, 30)).grow(4), VISUAL_PALETTE["target_idle"], false, 3.0)
	draw_rect(Rect2(paver_position - Vector2(28, 13), Vector2(56, 26)), paver_color)
	draw_rect(Rect2(paver_position - Vector2(28, 13), Vector2(56, 26)), Color("704d35"), false, 3.0)
	draw_line(paver_position + Vector2(-18, -7), paver_position + Vector2(-9, 7), Color("f0c981"), 2.0)
	draw_line(paver_position + Vector2(0, -8), paver_position + Vector2(9, 7), Color("f0c981"), 2.0)
	draw_line(paver_position + Vector2(18, -7), paver_position + Vector2(25, 5), Color("f0c981"), 2.0)


func _draw_q005_plant_at(position: Vector2, grown: bool, appearance_unlocked := false, wilted := false, growth_scale := 1.0) -> void:
	var stem_color := Color("8a9866") if wilted else Color("4f9e55")
	if wilted:
		draw_line(position + Vector2(0, 12) * growth_scale, position, stem_color, 4.0 * growth_scale)
		draw_line(position + Vector2(0, 3) * growth_scale, position + Vector2(-9, 7) * growth_scale, Color("a2ae70"), 4.0 * growth_scale)
		draw_line(position + Vector2(0, 1) * growth_scale, position + Vector2(8, 6) * growth_scale, Color("b0b879"), 4.0 * growth_scale)
		return
	var plant_sway := sin(animation_time * 1.45 + position.x * 0.017) * 2.4 * growth_scale
	var stem_base := position + Vector2(0, 12) * growth_scale
	var stem_joint := position + Vector2(plant_sway * 0.35, 2) * growth_scale
	var stem_top := position + Vector2(plant_sway, -10) * growth_scale
	draw_line(stem_base, stem_joint, stem_color, 4.0 * growth_scale)
	draw_line(stem_joint, stem_top, stem_color, 4.0 * growth_scale)
	if grown:
		if appearance_unlocked:
			draw_circle(stem_top + Vector2(-10, 0) * growth_scale, 8.0 * growth_scale, Color("e96b70"))
			draw_circle(stem_top + Vector2(10, 0) * growth_scale, 8.0 * growth_scale, Color("67a9dc"))
			draw_circle(stem_top + Vector2(0, -10) * growth_scale, 7.0 * growth_scale, Color("f0c85e"))
			draw_circle(stem_top, 5.0 * growth_scale, Color("fff3ad"))
			draw_line(stem_top + Vector2(-3, 0) * growth_scale, stem_top + Vector2(3, 0) * growth_scale, Color("fff8df"), 2.0 * growth_scale)
		else:
			draw_circle(stem_top + Vector2(-9, 0) * growth_scale, 8.0 * growth_scale, Color("78c977"))
			draw_circle(stem_top + Vector2(9, 0) * growth_scale, 8.0 * growth_scale, Color("9be087"))
			draw_circle(stem_top + Vector2(0, -8) * growth_scale, 6.0 * growth_scale, Color("ffe38a"))
	else:
		draw_circle(stem_top + Vector2(-7, 5) * growth_scale, 7.0 * growth_scale, Color("75b85e"))
		draw_circle(stem_top + Vector2(7, 5) * growth_scale, 7.0 * growth_scale, Color("a0cf6b"))


func _draw_turtle(position: Vector2) -> void:
	position.y += _character_bob(2.1, 1.0)
	_draw_ellipse_custom(position + Vector2(0, 27), Vector2(28, 8), Color(0.19, 0.29, 0.24, 0.18))
	for leg_offset in [Vector2(-14, 12), Vector2(14, 12), Vector2(-14, -10), Vector2(14, -10)]:
		_draw_ellipse_custom(position + leg_offset, Vector2(8, 6), Color("73b779"))
	draw_circle(position, 24.0, Color("4f8f68"))
	draw_circle(position, 19.0, Color("a8bb72"))
	draw_arc(position, 17.0, PI * 0.1, PI * 0.9, 12, Color("d0d69a"), 2.0)
	draw_line(position + Vector2(0, -17), position + Vector2(0, 17), Color("4f8f68"), 2.0)
	draw_line(position + Vector2(-15, -8), position + Vector2(15, 8), Color("4f8f68"), 2.0)
	draw_line(position + Vector2(-15, 8), position + Vector2(15, -8), Color("4f8f68"), 2.0)
	draw_colored_polygon(PackedVector2Array([
		position + Vector2(-22, 2), position + Vector2(-30, -2), position + Vector2(-22, -7),
	]), Color("4f8f68"))
	draw_circle(position + Vector2(27, 0), 10.0, Color("8fcf78"))
	if _character_is_blinking(1.7):
		draw_line(position + Vector2(25, -3), position + Vector2(31, -3), Color("2f4b3a"), 2.5)
	else:
		draw_circle(position + Vector2(29, -3), 2.5, Color("2f4b3a"))
	draw_circle(position + Vector2(24, 3), 2.5, Color("f0a39a"))


func _draw_wood_at(position: Vector2) -> void:
	_draw_ellipse_custom(position + Vector2(0, 17), Vector2(27, 7), Color(0.19, 0.13, 0.10, 0.16))
	draw_rect(Rect2(position - Vector2(28, 16), Vector2(56, 30)), Color("bd814e"))
	draw_rect(Rect2(position - Vector2(28, 16), Vector2(56, 30)), Color("704d35"), false, 3.0)
	draw_line(position + Vector2(-13, -10), position + Vector2(-13, 9), Color("e2ad6b"), 2.0)
	draw_line(position + Vector2(0, -10), position + Vector2(0, 9), Color("e2ad6b"), 2.0)
	draw_line(position + Vector2(13, -10), position + Vector2(13, 9), Color("e2ad6b"), 2.0)


func _draw_fox(position: Vector2) -> void:
	position.y += _character_bob(0.8, 1.5)
	_draw_ellipse_custom(position + Vector2(0, 25), Vector2(27, 7), Color(0.19, 0.13, 0.10, 0.16))
	_draw_ellipse_custom(position + Vector2(-22, 16), Vector2(10, 7), Color("d96f58"))
	_draw_ellipse_custom(position + Vector2(-29, 16), Vector2(4, 5), Color("fff0d1"))
	_draw_ellipse_custom(position + Vector2(0, 19), Vector2(19, 12), Color("d96f58"))
	_draw_ellipse_custom(position + Vector2(0, 20), Vector2(10, 8), Color("fff0d1"))
	_draw_ellipse_custom(position + Vector2(-10, 27), Vector2(8, 4), Color("b85b49"))
	_draw_ellipse_custom(position + Vector2(10, 27), Vector2(8, 4), Color("b85b49"))
	draw_colored_polygon(PackedVector2Array([
		position + Vector2(-22, -13), position + Vector2(-13, -42), position + Vector2(-2, -18),
	]), Color("d96f58"))
	draw_colored_polygon(PackedVector2Array([
		position + Vector2(-16, -20), position + Vector2(-13, -35), position + Vector2(-7, -19),
	]), Color("f2b1a0"))
	draw_colored_polygon(PackedVector2Array([
		position + Vector2(22, -13), position + Vector2(13, -42), position + Vector2(2, -18),
	]), Color("d96f58"))
	draw_colored_polygon(PackedVector2Array([
		position + Vector2(16, -20), position + Vector2(13, -35), position + Vector2(7, -19),
	]), Color("f2b1a0"))
	draw_circle(position, 24.0, Color("d96f58"))
	draw_circle(position + Vector2(0, 8), 15.0, Color("fff0d1"))
	if _character_is_blinking(0.8):
		draw_line(position + Vector2(-11, -3), position + Vector2(-5, -3), Color("3b302c"), 2.5)
		draw_line(position + Vector2(5, -3), position + Vector2(11, -3), Color("3b302c"), 2.5)
	else:
		draw_circle(position + Vector2(-8, -3), 3.0, Color("3b302c"))
		draw_circle(position + Vector2(8, -3), 3.0, Color("3b302c"))
	draw_circle(position + Vector2(-7, -4), 1.1, Color("ffffff"))
	draw_circle(position + Vector2(9, -4), 1.1, Color("ffffff"))
	draw_circle(position + Vector2(-16, 8), 3.0, Color("f2a094"))
	draw_circle(position + Vector2(16, 8), 3.0, Color("f2a094"))
	draw_circle(position + Vector2(0, 8), 4.0, Color("3b302c"))
	draw_arc(position + Vector2(0, 10), 8.0, 0.0, PI, 12, Color("3b302c"), 2.0)


func _draw_boards(font: Font) -> void:
	for board_id in range(GameState.BOARD_TOTAL):
		if not game_state.collected[board_id]:
			_draw_board_at(BOARD_POSITIONS[board_id], VISUAL_PALETTE["board"], false)
			draw_string(font, BOARD_POSITIONS[board_id] + Vector2(-24, 43), "木板", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, VISUAL_PALETTE["ink"])


func _draw_player() -> void:
	_draw_ellipse_custom(player_position + Vector2(0, 20), Vector2(25, 8), Color(0.19, 0.29, 0.24, 0.20))
	var bounce := absf(sin(player_walk_phase)) * 3.0 if player_is_moving else sin(animation_time * 2.0) * 1.0
	var squash := 0.06 * sin(player_walk_phase * 2.0) if player_is_moving else 0.0
	var body_center := player_position + Vector2(0, -bounce)
	var body_radius := Vector2(PLAYER_RADIUS * (1.0 + squash), PLAYER_RADIUS * (1.0 - squash))
	var facing := player_facing.normalized()
	var side := Vector2(-facing.y, facing.x)
	var foot_phase := sin(player_walk_phase) * 1.5 if player_is_moving else 0.0
	_draw_ellipse_custom(body_center + Vector2(-7, 14 + foot_phase), Vector2(6, 4), Color("bd814e"))
	_draw_ellipse_custom(body_center + Vector2(7, 14 - foot_phase), Vector2(6, 4), Color("bd814e"))
	var backpack_center := body_center - facing * 12.0 + Vector2(0, 5)
	_draw_ellipse_custom(backpack_center, Vector2(7, 8), Color("9d6b4c"))
	_draw_ellipse_custom(backpack_center + facing * 1.5, Vector2(4, 5), Color("d5a468"))
	_draw_ellipse_custom(body_center, body_radius + Vector2(5, 5), Color("fff3bc"))
	_draw_ellipse_custom(body_center, body_radius, VISUAL_PALETTE["player"])
	var muzzle_center := body_center + facing * 6.0 + Vector2(0, 3)
	_draw_ellipse_custom(muzzle_center, Vector2(9, 7), Color("fff0d1"))
	for eye_side in [-1.0, 1.0]:
		var eye_center: Vector2 = body_center + facing * 2.0 + side * 5.0 * eye_side - Vector2(0, 4)
		draw_circle(eye_center, 3.6, Color("ffffff"))
		draw_circle(eye_center + facing * 1.8, 2.0, Color("3b302c"))
		draw_circle(eye_center + facing * 1.5 - Vector2(0, 1.2), 0.8, Color("ffffff"))
	draw_circle(muzzle_center + facing * 5.0, 2.2, Color("7d4441"))
	draw_arc(muzzle_center + facing * 2.0 + Vector2(0, 1), 4.0, facing.angle() + 0.4, facing.angle() + 2.5, 10, Color("7d4441"), 1.6)
	draw_colored_polygon(PackedVector2Array([
		body_center + Vector2(-5, -16), body_center + Vector2(0, -23), body_center + Vector2(5, -16),
	]), Color("83ae62"))


func _draw_panel(rect: Rect2, fill: Color, border: Color, radius: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	draw_style_box(style, rect)


func _draw_rabbit(position: Vector2) -> void:
	var celebration_bob := 1.3 if celebration_remaining > 0.0 else 0.0
	position.y += _character_bob(0.0, 2.0 + celebration_bob)
	var rabbit_color: Color = VISUAL_PALETTE["rabbit_complete"] if game_state.is_complete() else VISUAL_PALETTE["rabbit_request"]
	var rabbit_outline := Color("5f9c70") if game_state.is_complete() else Color("c99564")
	_draw_ellipse_custom(position + Vector2(0, 31), Vector2(34, 8), Color(0.19, 0.29, 0.24, 0.18))
	_draw_ellipse_custom(position + Vector2(0, 22), Vector2(19, 14), rabbit_outline)
	_draw_ellipse_custom(position + Vector2(0, 21), Vector2(16, 12), rabbit_color)
	_draw_ellipse_custom(position + Vector2(-11, 32), Vector2(8, 4), rabbit_color)
	_draw_ellipse_custom(position + Vector2(11, 32), Vector2(8, 4), rabbit_color)
	_draw_ellipse_custom(position + Vector2(-17, -33), Vector2(12, 30), rabbit_outline)
	_draw_ellipse_custom(position + Vector2(17, -33), Vector2(12, 30), rabbit_outline)
	_draw_ellipse_custom(position + Vector2(-17, -33), Vector2(10, 28), rabbit_color)
	_draw_ellipse_custom(position + Vector2(17, -33), Vector2(10, 28), rabbit_color)
	_draw_ellipse_custom(position + Vector2(-17, -34), Vector2(5, 20), Color("efb5b0"))
	_draw_ellipse_custom(position + Vector2(17, -34), Vector2(5, 20), Color("efb5b0"))
	draw_circle(position, 31.0, rabbit_outline)
	draw_circle(position, 28.0, rabbit_color)
	_draw_ellipse_custom(position + Vector2(0, 9), Vector2(12, 8), Color("fffdf5"))
	if _character_is_blinking(0.0):
		draw_line(position + Vector2(-13, -3), position + Vector2(-5, -3), Color("3c3030"), 3.0)
		draw_line(position + Vector2(5, -3), position + Vector2(13, -3), Color("3c3030"), 3.0)
	else:
		draw_circle(position + Vector2(-9, -3), 4.0, Color("3c3030"))
		draw_circle(position + Vector2(9, -3), 4.0, Color("3c3030"))
	draw_circle(position + Vector2(-10, -5), 1.4, Color("ffffff"))
	draw_circle(position + Vector2(8, -5), 1.4, Color("ffffff"))
	draw_circle(position + Vector2(-16, 7), 5.0, Color("f5b1a8"))
	draw_circle(position + Vector2(16, 7), 5.0, Color("f5b1a8"))
	draw_circle(position + Vector2(0, 9), 5.0, Color("f28a9b"))
	draw_arc(position + Vector2(0, 9), 10.0, 0.0, PI, 16, Color("4b9d63") if game_state.is_complete() else Color("a86767"), 3.0)


func _bridge_status_text() -> String:
	return "小桥已修好" if game_state.bridge_repaired else "损坏的小桥"


func _rabbit_feedback_text() -> String:
	if not _should_show_rabbit_dialog():
		return ""
	if not game_state.is_complete():
		return "兔子：帮我修好小桥，好吗？"
	if not game_state.seed_collected:
		return "兔子：谢谢你！过桥找发光种子吧！"
	if not game_state.seed_planted:
		return "兔子：种子找到了！去花圃种下吧！"
	return "兔子：去帮狐狸找 3 份木材吧！"


func _draw_ellipse_custom(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(24):
		var angle := TAU * float(i) / 24.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)


func _draw_board_at(position: Vector2, color: Color, lifted: bool) -> void:
	var rect := Rect2(position - Vector2(28, 14), Vector2(56, 28))
	if lifted:
		rect.position -= Vector2(0, 14)
	_draw_ellipse_custom(rect.position + Vector2(rect.size.x / 2.0, rect.size.y + 7), Vector2(34, 7), Color(0.19, 0.13, 0.10, 0.16))
	if lifted:
		draw_rect(rect.grow(5), VISUAL_PALETTE["target_idle"], false, 3.0)
	draw_rect(rect, color)
	draw_rect(rect, VISUAL_PALETTE["board_outline"], false, 3.0)
	draw_line(rect.position + Vector2(10, 5), rect.position + Vector2(10, rect.size.y - 5), Color("9b6d43"), 2.0)
	draw_line(rect.position + Vector2(24, 5), rect.position + Vector2(24, rect.size.y - 5), Color("9b6d43"), 2.0)
	draw_line(rect.position + Vector2(4, 6), rect.position + Vector2(rect.size.x - 4, 6), Color("efc57d"), 2.0)


func _draw_pond_stone_at(position: Vector2, color: Color, lifted: bool) -> void:
	var stone_position := position - Vector2(0, 8) if lifted else position
	_draw_ellipse_custom(stone_position + Vector2(0, 14), Vector2(24, 8), Color(0.19, 0.13, 0.10, 0.16))
	_draw_ellipse_custom(stone_position, Vector2(20, 14), color)
	draw_arc(stone_position, 18.0, 0.0, TAU, 20, Color("596a69"), 3.0)
	draw_line(stone_position + Vector2(-8, -3), stone_position + Vector2(7, -7), Color("b9c3ba"), 2.0)
	if lifted:
		draw_arc(stone_position, 25.0, 0.0, TAU, 24, VISUAL_PALETTE["target_idle"], 3.0)


func _draw_hud(font: Font) -> void:
	_draw_panel(Rect2(26, 22, 760, 104), VISUAL_PALETTE["panel"], VISUAL_PALETTE["panel_border"], 20)
	draw_string(font, Vector2(48, 58), _hud_title_text(), HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("fff7cf"))
	_draw_panel(Rect2(46, 72, 88, 26), Color("426b51"), Color("8fc47d"), 9)
	draw_string(font, Vector2(56, 91), _task_stage_label(), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("fff7cf"))
	draw_string(font, Vector2(148, 90), _task_prompt_text(), HORIZONTAL_ALIGNMENT_LEFT, 620, 18, Color("fff7cf"))
	if _should_show_hud_message():
		draw_string(font, Vector2(48, 112), message, HORIZONTAL_ALIGNMENT_LEFT, 720, 16, message_color)
	var show_inventory: bool = q011_mode or _can_use_q011_mode() or build_mode or _can_start_q005_stage() or game_state.can_start_q004() or not game_state.is_complete() or (_can_use_q008_side_task() and not game_state.is_q008_complete())
	if not show_inventory:
		return
	_draw_panel(Rect2(914, 574, 310, 110), VISUAL_PALETTE["panel"], VISUAL_PALETTE["panel_border"], 18)
	if q011_mode:
		_draw_q011_inventory(font)
	elif _can_use_q011_mode() and not build_mode:
		_draw_q011_inventory(font, true)
	elif build_mode:
		_draw_q006_inventory(font)
	elif _can_start_q005_stage():
		draw_string(font, Vector2(932, 602), "植物（拖到花园）", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("fff7cf"))
		for plant_id in range(GameState.Q005_PLANT_TOTAL):
			var plant_rect := _q005_plant_inventory_rect(plant_id)
			if game_state.q005_plants_collected[plant_id] and not game_state.q005_plant_slots[plant_id] and dragging_q005_plant != plant_id:
				_draw_q005_plant_at(plant_rect.position + plant_rect.size / 2.0, false)
			else:
				draw_rect(plant_rect, Color("d5e4cb"), false, 2.0)
			if game_state.q005_plant_slots[plant_id]:
				draw_string(font, plant_rect.position + Vector2(29, 29), "✓", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("d9ffd0"))
	elif game_state.can_start_q004():
		_draw_q004_inventory(font)
	elif _can_use_q008_side_task() and not game_state.is_q008_complete():
		_draw_q008_inventory(font)
	else:
		draw_string(font, Vector2(932, 602), "已收集木板（拖到桥上）", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("fff7cf"))
		for board_id in range(GameState.BOARD_TOTAL):
			var rect := _inventory_rect(board_id)
			if game_state.collected[board_id] and not game_state.placed[board_id] and dragging_board != board_id:
				_draw_board_at(rect.position + rect.size / 2.0, VISUAL_PALETTE["board_collected"], false)
			else:
				draw_rect(rect, Color("d5e4cb"), false, 2.0)
			if game_state.placed[board_id]:
				draw_string(font, rect.position + Vector2(29, 29), "✓", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("d9ffd0"))


func _draw_q004_inventory(font: Font) -> void:
	draw_string(font, Vector2(932, 602), "狐狸小屋木材（带到小屋交付）", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("fff7cf"))
	for wood_id in range(GameState.Q004_WOOD_TOTAL):
		var rect := _inventory_rect(wood_id)
		if game_state.wood_collected[wood_id] and not game_state.wood_delivered[wood_id]:
			_draw_wood_at(rect.position + rect.size / 2.0)
		else:
			draw_rect(rect, Color("d5e4cb"), false, 2.0)
		if game_state.wood_delivered[wood_id]:
			draw_string(font, rect.position + Vector2(29, 29), "✓", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("d9ffd0"))


func _draw_q008_inventory(font: Font) -> void:
	draw_string(font, Vector2(932, 602), "路面石板（拖到左侧小路）", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("fff7cf"))
	for material_id in range(GameState.Q008_PATH_SLOT_TOTAL):
		var rect := _q008_path_material_rect(material_id)
		if game_state.q008_path_material_is_available(material_id) and dragging_q008_path != material_id:
			_draw_q008_path_paver_at(rect.position + rect.size / 2.0, material_id, false)
		else:
			draw_rect(rect, Color("d5e4cb"), false, 2.0)
		if not game_state.q008_path_material_is_available(material_id):
			draw_string(font, rect.position + Vector2(29, 29), "✓", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("d9ffd0"))


func _draw_q011_inventory(font: Font, preview := false) -> void:
	var title := "整理物品（先点右上角开始整理）" if preview else "整理物品（拖到左侧空槽）"
	draw_string(font, Vector2(932, 602), title, HORIZONTAL_ALIGNMENT_LEFT, 280, 16, Color("fff7cf"))
	for item_id in range(GameState.Q011_ITEM_TOTAL):
		var rect := _q011_item_inventory_rect(item_id)
		if game_state.q011_item_is_available(item_id) and dragging_q011_item != item_id:
			_draw_q011_item_at(rect.position + rect.size / 2.0, item_id, false)
		else:
			draw_rect(rect, Color("d5e4cb"), false, 2.0)
		if not game_state.q011_item_is_available(item_id):
			draw_string(font, rect.position + Vector2(29, 28), "✓", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("d9ffd0"))


func _draw_q006_inventory(font: Font) -> void:
	draw_string(font, Vector2(932, 602), "装饰（拖到上方槽位）", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("fff7cf"))
	for decor_id in range(GameState.Q006_DECOR_TOTAL):
		var rect := _q006_decor_inventory_rect(decor_id)
		if game_state.q006_decor_is_available(decor_id) and dragging_q006_decor != decor_id:
			_draw_q006_decor_at(rect.position + rect.size / 2.0, decor_id, false)
		else:
			draw_rect(rect, Color("d5e4cb"), false, 2.0)
		if not game_state.q006_decor_is_available(decor_id):
			draw_string(font, rect.position + Vector2(30, 28), "✓", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("d9ffd0"))
	if game_state.q006_windmill_unlocked:
		draw_string(font, Vector2(932, 678), "小风车：已解锁（保留在库存）", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("fff1a8"))
	else:
		draw_string(font, Vector2(932, 678), "完成三件装饰后解锁小风车", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("d5e4cb"))


func _draw_touch_hint(font: Font) -> void:
	var visible_height := size.y
	var hint_y := minf(644.0, maxf(8.0, visible_height - 76.0))
	var joystick_center := _virtual_joystick_center()
	_draw_panel(Rect2(184, hint_y, 742, 52), Color(0.91, 0.98, 0.88, 0.94), VISUAL_PALETTE["island_highlight"], 14)
	_draw_panel(Rect2(196, hint_y + 12.0, 72, 28), Color("d7edcb"), Color("86b877"), 10)
	draw_string(font, Vector2(204, hint_y + 31.0), "现在做什么", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VISUAL_PALETTE["ink"])
	draw_string(font, Vector2(280, hint_y + 32.0), _task_action_hint_text(), HORIZONTAL_ALIGNMENT_LEFT, 620, 16, VISUAL_PALETTE["ink"])
	draw_string(font, joystick_center + Vector2(-68, -76), "拖动摇杆移动", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, VISUAL_PALETTE["ink"])
	_draw_virtual_joystick()


func _draw_virtual_joystick() -> void:
	var joystick_center := _virtual_joystick_center()
	var base_color := Color(0.09, 0.18, 0.16, 0.42)
	var outline_color := Color("e4f7d6")
	draw_circle(joystick_center, JOYSTICK_RADIUS + 8.0, Color(0.08, 0.16, 0.14, 0.18))
	draw_circle(joystick_center, JOYSTICK_RADIUS, base_color)
	draw_arc(joystick_center, JOYSTICK_RADIUS, 0.0, TAU, 40, outline_color, 3.0)
	draw_circle(joystick_center, 6.0, Color(0.87, 0.96, 0.78, 0.78))
	var knob_center := joystick_center + virtual_joystick_offset
	var knob_color := Color("80c987") if virtual_joystick_active else Color(0.88, 0.96, 0.81, 0.92)
	draw_circle(knob_center, 23.0, knob_color)
	draw_arc(knob_center, 23.0, 0.0, TAU, 32, Color("f4ffec"), 3.0)


func _virtual_joystick_center() -> Vector2:
	var visible_height := size.y
	return Vector2(JOYSTICK_CENTER.x, maxf(JOYSTICK_RADIUS + 12.0, minf(JOYSTICK_CENTER.y, visible_height - JOYSTICK_RADIUS - 24.0)))


func _task_prompt_text() -> String:
	if q011_mode:
		return "额外地块整理：已放置 %d/3 件物品。" % game_state.q011_placed_count()
	if _can_use_q011_mode() and not build_mode:
		return "额外地块整理：先点“开始整理”，再放置 3 件物品（%d/3）。" % game_state.q011_placed_count()
	if game_state.can_start_q012():
		return "花园装饰已完成！回到兔子身边参加小岛庆祝。"
	if build_mode and _can_use_q006_build_mode():
		if game_state.is_q006_complete():
			return "花园装饰已完成，可拖动已摆放的装饰调整位置。"
		return "任务：布置花园装饰。已完成 %d/3。" % game_state.q006_placed_count()
	if game_state.is_q011_complete():
		return "额外地块整理完成！可以自由探索，或点击“建造”调整花园。"
	if not game_state.is_complete():
		var collected_count: int = game_state.board_count()
		var placed_count: int = game_state.placed_count()
		if collected_count == 0:
			return "任务：帮助兔子修好小桥。先收集 3 块木板。"
		if collected_count < GameState.BOARD_TOTAL:
			if placed_count > 0:
				return "已收集 %d/3 块，还要 %d 块；已放置 %d/3 块。" % [collected_count, GameState.BOARD_TOTAL - collected_count, placed_count]
			return "已收集 %d/3 块木板，还要 %d 块。" % [collected_count, GameState.BOARD_TOTAL - collected_count]
		return "木板已集齐，已放置 %d/3 块；把剩余木板拖到桥面高亮位置。" % placed_count
	if not game_state.seed_collected:
		return "下一步：过桥到右侧寻找发光的种子。"
	if not game_state.seed_planted:
		return "下一步：到右侧花圃种下种子。"
	if not game_state.is_q004_complete():
		var wood_count: int = game_state.wood_count()
		var delivered_count: int = game_state.delivered_wood_count()
		if wood_count == 0:
			return "任务：帮狐狸建小屋。先收集 3 份木材。"
		if delivered_count < GameState.Q004_WOOD_TOTAL:
			if wood_count < GameState.Q004_WOOD_TOTAL:
				return "木材已收集 %d/3，已交付 %d/3；继续寻找木材。" % [wood_count, delivered_count]
			return "木材已集齐，交付进度：%d/3。" % delivered_count
	if not game_state.is_pond_complete():
		return "狐狸入住了！池塘石头已摆放 %d/3。" % game_state.pond_stones_placed.count(true)
	if not game_state.is_q005_complete():
		var collected_count: int = game_state.q005_plant_count()
		var placed_count: int = game_state.q005_plant_slot_count()
		if not game_state.q005_watered and placed_count == GameState.Q005_PLANT_TOTAL:
			return "植物已摆好，请给乌龟的花园浇水。"
		if not game_state.q005_watered:
			return "先给花园浇水，再收集并摆好 3 株植物（已收集 %d/3）。" % collected_count
		return "花园已浇水，植物已收集 %d/3，已摆放 %d/3。" % [collected_count, placed_count]
	if not game_state.is_q006_complete():
		return "下一步：布置花园装饰（%d/3）。" % game_state.q006_placed_count()
	if not game_state.is_q007_complete():
		return "主线故事完成！可选支线：到池塘边寻找隐藏贝壳。"
	if not game_state.is_q009_complete():
		return "可选支线：" + _q009_prompt_text()
	if not game_state.is_q010_complete():
		return "可选支线：" + _q010_prompt_text()
	if not game_state.is_q008_complete():
		return "可选支线：" + _q008_prompt_text()
	if not game_state.is_q011_complete():
		return "可选整理：额外地块已放置 %d/3 件物品。" % game_state.q011_placed_count()
	return "小岛主线和支线都完成了！继续自由探索吧。"


func _should_show_hud_message() -> bool:
	return not message.is_empty() and message != _task_prompt_text()


func _task_stage_label() -> String:
	if q011_mode:
		return "可选 5/5"
	if game_state.can_start_q012():
		return "主线 7/7"
	if build_mode and _can_use_q006_build_mode():
		return "主线 6/7" if not game_state.is_q006_complete() else "建造"
	if game_state.is_q011_complete():
		return "全部完成"
	if not game_state.is_complete():
		return "主线 1/7"
	if not game_state.seed_collected or not game_state.seed_planted:
		return "主线 2/7"
	if not game_state.is_q004_complete():
		return "主线 3/7"
	if not game_state.is_pond_complete():
		return "主线 4/7"
	if not game_state.is_q005_complete():
		return "主线 5/7"
	if not game_state.is_q006_complete():
		return "主线 6/7"
	if not game_state.is_q007_complete():
		return "可选 1/5"
	if not game_state.is_q009_complete():
		return "可选 2/5"
	if not game_state.is_q010_complete():
		return "可选 3/5"
	if not game_state.is_q008_complete():
		return "可选 4/5"
	if not game_state.is_q011_complete():
		return "可选 5/5"
	return "全部完成"


func _task_action_hint_text() -> String:
	if q011_mode:
		return "把右下角托盘的物品拖到左侧空槽，放满 3 件即可完成。"
	if _can_use_q011_mode() and not build_mode:
		return "右下角已显示 3 件物品；先点右上角绿色“开始整理”，再拖到左侧空槽。"
	if game_state.can_start_q012():
		return "走到兔子身边，按 E 或点右下角“收集 / 互动”参加庆祝。"
	if build_mode and _can_use_q006_build_mode():
		if remove_decor_mode:
			return "点击已放置的装饰移除；再次点击移除按钮可取消。"
		if game_state.is_q006_complete():
			return "拖动已摆放的装饰换位，或点“移除装饰”后收回。"
		return "拖动木栅栏、花盆和庭院路灯到对应槽位。"
	if game_state.is_q011_complete():
		return "没有必做任务：自由探索，或点右上角“建造”调整花园。"
	if not game_state.is_complete():
		if game_state.board_count() < GameState.BOARD_TOTAL:
			return "靠近木板，按 E、点右下角“收集 / 互动”，或直接点击木板。"
		return "拖动右下角已收集木板到桥上高亮位置。"
	if not game_state.seed_collected:
		return "过桥到右侧靠近发光种子，按 E 或点右下角“收集 / 互动”。"
	if not game_state.seed_planted:
		return "走到右侧花圃旁，按 E 或点右下角“收集 / 互动”种下种子。"
	if not game_state.is_q004_complete():
		if game_state.wood_count() < GameState.Q004_WOOD_TOTAL:
			return "靠近木材，按 E 或点右下角“收集 / 互动”拾取。"
		return "带着木材走到小屋旁，按 E 或点右下角“收集 / 互动”交付。"
	if not game_state.is_pond_complete():
		return "下一步：把池塘边剩余的石头拖进对应轮廓。"
	if not game_state.is_q005_complete():
		if not game_state.q005_watered:
			return "下一步：靠近“浇水点”，先浇水；浇水前不能采花。"
		if game_state.q005_plant_count() < GameState.Q005_PLANT_TOTAL:
			return "下一步：靠近长好的植物，按 E 或点右下角“收集 / 互动”采集 3 株。"
		return "下一步：把右下角的植物逐个拖到绿色空槽。"
	if not game_state.is_q006_complete():
		var remaining_decorations: int = GameState.Q006_DECOR_TOTAL - game_state.q006_placed_count()
		return "点击绿色“开始布置”，把剩余 %d 件装饰拖到空槽。" % remaining_decorations
	if not game_state.is_q007_complete():
		return "支线可以跳过：到池塘边找隐藏贝壳，靠近后按互动键。"
	if not game_state.is_q009_complete():
		return "支线可以跳过：" + _q009_action_hint_text()
	if not game_state.is_q010_complete():
		return "支线可以跳过：" + _q010_action_hint_text()
	if not game_state.is_q008_complete():
		return "支线可以跳过：把三块路面石板拖到小路空槽里。"
	if not game_state.is_q011_complete():
		return "支线可以跳过：先点右上角“开始整理”，再把 3 件物品放进空槽。"
	return "花园和小岛都已恢复，可以自由探索。"


func _hud_title_text() -> String:
	if game_state.can_start_q012():
		return "奇趣小岛 · 小岛庆祝日"
	if q011_mode:
		return "奇趣小岛 · 帮忙整理"
	if build_mode and _can_use_q006_build_mode():
		return "奇趣小岛 · 花园装饰"
	if not game_state.is_complete():
		return "奇趣小岛 · 修桥任务"
	if not game_state.seed_collected:
		return "奇趣小岛 · 寻找种子"
	if not game_state.seed_planted:
		return "奇趣小岛 · 种下种子"
	if not game_state.is_q004_complete():
		return "奇趣小岛 · 狐狸小屋任务"
	if not game_state.is_pond_complete():
		return "奇趣小岛 · 池塘整理任务"
	if not game_state.is_q005_complete():
		return "奇趣小岛 · 乌龟花园任务"
	if not game_state.is_q006_complete():
		return "奇趣小岛 · 花园装饰任务"
	if not game_state.is_q007_complete():
		return "奇趣小岛 · 寻找隐藏贝壳"
	if not game_state.is_q009_complete():
		return "奇趣小岛 · 鸟屋计划"
	if not game_state.is_q010_complete():
		return "奇趣小岛 · 种子收藏"
	if not game_state.is_q008_complete():
		return "奇趣小岛 · 铺设小路"
	if _can_use_q011_mode():
		return "奇趣小岛 · 额外地块整理"
	if game_state.is_q011_complete():
		return "奇趣小岛 · 全部任务完成"
	if game_state.is_q012_complete():
		return "奇趣小岛 · 主线完成"
	return "奇趣小岛 · 自由探索"
