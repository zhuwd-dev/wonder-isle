extends Control

const GameState = preload("res://scripts/game/game_state.gd")
const UI_FONT = preload("res://assets/fonts/NotoSansCJKsc-GameSubset.otf")
const MOUSE_ART: Texture2D = preload("res://assets/art/characters/mouse.png")
const RABBIT_ART: Texture2D = preload("res://assets/art/characters/rabbit.png")
const FOX_ART: Texture2D = preload("res://assets/art/characters/fox.png")
const TURTLE_ART: Texture2D = preload("res://assets/art/characters/turtle.png")
const BIRD_ART: Texture2D = preload("res://assets/art/characters/bird.png")
const ISLAND_BACKGROUND: Texture2D = preload("res://assets/art/environment/floating-garden-bg.jpg")
const BRIDGE_ART: Texture2D = preload("res://assets/art/environment/woodland-footbridge.png")
const PLANK_ART: Texture2D = preload("res://assets/art/props/weathered-planks.png")
const CRATE_ART: Texture2D = preload("res://assets/art/props/island-wood-crate.png")
const SAVE_PATH := "user://qxisland_stage2_save.json"
const WORLD_SIZE := Vector2(1280, 720)
const PLAYER_SPEED := 260.0
const PLAYER_RADIUS := 18.0
const CAMERA_MIN_ZOOM := 1.0
const CAMERA_MAX_ZOOM := 1.65
const CAMERA_ZOOM_STEP := 1.2
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
# Give the small garden actions a forgiving touch target at browser/mobile scale.
const Q005_INTERACTION_RADIUS := 42.0
const Q005_WATERING_RADIUS := 64.0
const Q005_PLANT_POSITIONS := [Vector2(1028, 480), Vector2(1080, 480), Vector2(1132, 480)]
const Q005_PLANT_SLOTS := [
	Rect2(1012, 466, 32, 28),
	Rect2(1064, 466, 32, 28),
	Rect2(1116, 466, 32, 28),
]
const Q005_GARDEN_RECT := Rect2(1000, 438, 160, 84)
const Q005_TURTLE_POSITION := Vector2(1160, 280)
const Q005_TURTLE_INTERACTION_RADIUS := 72.0
const WOOD_POSITIONS := [Vector2(160, 330), Vector2(360, 400), Vector2(620, 540)]
const HOUSE_POSITION := Vector2(520, 500)
const HOUSE_INTERACTION_RADIUS := 88.0
const HOUSE_RECT := Rect2(448, 442, 144, 116)
const Q012_RABBIT_POSITION := Vector2(592, 226)
const Q006_DECOR_PLOT_RECT := Rect2(928, 544, 288, 30)
const Q006_DECOR_BOUNDS := Rect2(916, 148, 306, 484)
const Q006_DECOR_ISLAND_POLYGON := [
	Vector2(944, 162), Vector2(958, 146), Vector2(1024, 138), Vector2(1138, 146),
	Vector2(1180, 170), Vector2(1194, 224), Vector2(1190, 562), Vector2(1164, 592),
	Vector2(1070, 606), Vector2(974, 600), Vector2(940, 568),
]
const Q006_DECOR_CLEARANCE := 58.0
const Q006_DECOR_SLOTS := [
	Rect2(940, 547, 76, 24),
	Rect2(1034, 547, 76, 24),
	Rect2(1128, 547, 76, 24),
]
const Q006_DECOR_INVENTORY_ORIGIN := Vector2(904, 606)
const Q006_DECOR_INVENTORY_STEP := 80.0
const Q007_SHELL_POSITION := Vector2(930, 430)
const Q007_REWARD_POSITION := Vector2(930, 430)
const Q008_PATH_MATERIAL_POSITIONS := [Vector2(938, 661), Vector2(1018, 661), Vector2(1098, 661)]
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
const Q009_BIRDHOUSE_INTERACTION_RADIUS := 82.0
const Q010_SEED_POSITIONS := [Vector2(180, 430), Vector2(550, 300), Vector2(260, 430)]
const Q010_SEED_LABELS := ["红花种子", "蓝花种子", "金色种子"]
const Q011_AREA_RECT := Rect2(196, 568, 188, 56)
const Q011_SLOT_RECTS := [
	Rect2(210, 576, 48, 24),
	Rect2(270, 576, 48, 24),
	Rect2(330, 576, 48, 24),
]
const Q011_ITEM_NAMES := ["木箱", "布包", "竹篮"]
const Q011_INVENTORY_ORIGIN := Vector2(904, 620)
const Q011_INVENTORY_STEP := 80.0
const JOYSTICK_CENTER := Vector2(96, 622)
const JOYSTICK_RADIUS := 54.0
const JOYSTICK_DEADZONE := 0.14
const JOYSTICK_HIT_RADIUS := 88.0
const INTERACT_BUTTON_SIZE := Vector2(116, 92)
const INVENTORY_PANEL_RECT := Rect2(890, 558, 264, 138)
const INVENTORY_ORIGIN := Vector2(904, 624)
const INVENTORY_STEP := 80.0
const COLLECT_SPARKLE_DURATION := 0.72
const Q005_GROWTH_DURATION := 1.4
const BRIDGE_REPAIR_DURATION := 1.05
const CELEBRATION_DURATION := 2.4
const TASK_TRANSITION_DURATION := 1.15
const POND_INTERACTION_RADIUS := 112.0
const BRIDGE_SLOTS := [
	Rect2(789, 367, 16, 18),
	Rect2(806, 366, 16, 18),
	Rect2(828, 367, 16, 18),
]
const VISUAL_PALETTE := {
	"sky": Color("c8edf0"),
	"sky_band": Color("e7f5e7"),
	"sun": Color("ffd986"),
	"cloud": Color("fffdf1"),
	"island_grass": Color("82c77c"),
	"island_highlight": Color("b7d98b"),
	"island_shadow": Color(0.20, 0.32, 0.25, 0.24),
	"right_locked": Color("83c47a"),
	"right_open": Color("82c77c"),
	"river": Color("55b7ca"),
	"river_light": Color("a8e0d8"),
	"river_edge": Color("f2d39b"),
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
	"panel": Color(0.99, 0.97, 0.87, 0.96),
	"panel_border": Color("c4b27d"),
	"ink": Color("294438"),
}

var game_state
var save_path := SAVE_PATH
var player_position := Vector2(250, 500)
var player_facing := Vector2.RIGHT
var camera_center := WORLD_SIZE * 0.5
var camera_zoom := 1.0
var camera_pan_active := false
var camera_pan_touch_index := -1
var camera_pan_last_screen := Vector2.ZERO
var animation_time := 0.0
var player_walk_phase := 0.0
var player_is_moving := false
var collect_sparkle_remaining := 0.0
var collect_sparkle_position := Vector2.ZERO
var collect_sparkle_color := Color("fff1a8")
var q005_growth_remaining := 0.0
var bridge_repair_remaining := 0.0
var celebration_remaining := 0.0
var task_transition_remaining := 0.0
var task_transition_position := Vector2.ZERO
var task_transition_text := ""
var pond_ripple_remaining := 0.0
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
var zoom_out_button: Button
var zoom_in_button: Button
var zoom_reset_button: Button
var interaction_button_label := ""
var interaction_button_ready := false
var interaction_button_tooltip := ""
var build_button: Button
var remove_decor_button: Button
var q011_button: Button
var panel_style_cache: Dictionary = {}
var soft_panel_style_cache: Dictionary = {}
var slot_card_style: StyleBoxFlat


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
	print("奇趣小岛绘本场景加载成功")
	print("存档路径: ", save_path)


func _physics_process(delta: float) -> void:
	animation_time += delta
	collect_sparkle_remaining = maxf(collect_sparkle_remaining - delta, 0.0)
	q005_growth_remaining = maxf(q005_growth_remaining - delta, 0.0)
	bridge_repair_remaining = maxf(bridge_repair_remaining - delta, 0.0)
	celebration_remaining = maxf(celebration_remaining - delta, 0.0)
	task_transition_remaining = maxf(task_transition_remaining - delta, 0.0)
	pond_ripple_remaining = maxf(pond_ripple_remaining - delta, 0.0)
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
			player_walk_phase = fposmod(player_walk_phase + delta * TAU * 3.2, TAU)
	_update_interact_button()
	_update_interact_button_animation()
	queue_redraw()


func _start_collect_sparkles(position: Vector2, color := Color("fff1a8")) -> void:
	collect_sparkle_position = position
	collect_sparkle_color = color
	collect_sparkle_remaining = COLLECT_SPARKLE_DURATION
	queue_redraw()


func _start_task_transition(position: Vector2, label: String) -> void:
	task_transition_position = position
	task_transition_text = label
	task_transition_remaining = TASK_TRANSITION_DURATION
	_start_collect_sparkles(position, Color("fff1a8"))


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
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] and event.pressed:
			_change_camera_zoom(CAMERA_ZOOM_STEP if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / CAMERA_ZOOM_STEP, event.position)
			get_viewport().set_input_as_handled()
			return
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
		if event.pressed:
			if _handle_interact_button_pointer(event.position, true):
				return
			if _is_virtual_joystick_hit(event.position) and _begin_virtual_joystick(event.position, -1, true):
				get_viewport().set_input_as_handled()
				return
			if _is_button_control_position(event.position):
				return
			_begin_world_pointer(event.position, -1)
		else:
			if camera_pan_active and camera_pan_touch_index == -1:
				_end_camera_pan()
				get_viewport().set_input_as_handled()
				return
			if _handle_interact_button_pointer(event.position, false):
				return
			if virtual_joystick_mouse_active:
				_end_virtual_joystick()
				get_viewport().set_input_as_handled()
				return
			if _is_button_control_position(event.position):
				return
			_pointer_up(_screen_to_world(event.position), event.position)
	elif event is InputEventMouseMotion:
		if virtual_joystick_mouse_active:
			_update_virtual_joystick(event.position)
		elif camera_pan_active and camera_pan_touch_index == -1:
			_update_camera_pan(event.position)
		elif dragging_board >= 0:
			drag_position = _screen_to_world(event.position)
			queue_redraw()
		elif dragging_pond_stone >= 0:
			pond_drag_position = _screen_to_world(event.position)
			queue_redraw()
		elif dragging_q005_plant >= 0:
			q005_plant_drag_position = _screen_to_world(event.position)
			queue_redraw()
		elif dragging_q006_decor >= 0:
			q006_decor_drag_position = _screen_to_world(event.position)
			queue_redraw()
		elif dragging_q008_path >= 0:
			q008_path_drag_position = _screen_to_world(event.position)
			queue_redraw()
		elif dragging_q011_item >= 0:
			q011_drag_position = _screen_to_world(event.position)
			queue_redraw()
	elif event is InputEventScreenTouch:
		if event.pressed:
			if _handle_interact_button_pointer(event.position, true):
				return
			if not virtual_joystick_active and _is_virtual_joystick_hit(event.position) and _begin_virtual_joystick(event.position, event.index, false):
				get_viewport().set_input_as_handled()
				return
			if _is_button_control_position(event.position):
				return
			_begin_world_pointer(event.position, event.index)
		else:
			if camera_pan_active and camera_pan_touch_index == event.index:
				_end_camera_pan()
				get_viewport().set_input_as_handled()
				return
			if _handle_interact_button_pointer(event.position, false):
				return
			if virtual_joystick_active and not virtual_joystick_mouse_active and virtual_joystick_touch_index == event.index:
				_end_virtual_joystick()
				get_viewport().set_input_as_handled()
				return
			if _is_button_control_position(event.position):
				return
			_pointer_up(_screen_to_world(event.position), event.position)
	elif event is InputEventScreenDrag:
		if virtual_joystick_active and not virtual_joystick_mouse_active and virtual_joystick_touch_index == event.index:
			_update_virtual_joystick(event.position)
			get_viewport().set_input_as_handled()
		elif camera_pan_active and camera_pan_touch_index == event.index:
			_update_camera_pan(event.position)
			get_viewport().set_input_as_handled()
		elif dragging_board >= 0:
			drag_position = _screen_to_world(event.position)
			queue_redraw()
		elif dragging_pond_stone >= 0:
			pond_drag_position = _screen_to_world(event.position)
			queue_redraw()
		elif dragging_q005_plant >= 0:
			q005_plant_drag_position = _screen_to_world(event.position)
			queue_redraw()
		elif dragging_q006_decor >= 0:
			q006_decor_drag_position = _screen_to_world(event.position)
			queue_redraw()
		elif dragging_q008_path >= 0:
			q008_path_drag_position = _screen_to_world(event.position)
			queue_redraw()
		elif dragging_q011_item >= 0:
			q011_drag_position = _screen_to_world(event.position)
			queue_redraw()


func _begin_world_pointer(screen_position: Vector2, touch_index: int) -> void:
	var world_position := _screen_to_world(screen_position)
	if _can_begin_camera_pan(world_position, screen_position):
		camera_pan_active = true
		camera_pan_touch_index = touch_index
		camera_pan_last_screen = screen_position
		get_viewport().set_input_as_handled()
		return
	_pointer_down(world_position, screen_position)


func _can_begin_camera_pan(world_position: Vector2, screen_position: Vector2) -> bool:
	if camera_zoom <= CAMERA_MIN_ZOOM + 0.01:
		return false
	# Fixed trays remain usable while the world is zoomed. A drag beginning on
	# one of these cards should always pick up its item, never move the map.
	for board_id in range(GameState.BOARD_TOTAL):
		if _inventory_rect(board_id).has_point(screen_position):
			return false
	for material_id in range(GameState.Q008_PATH_SLOT_TOTAL):
		if _q008_path_material_rect(material_id).grow(12).has_point(screen_position):
			return false
	for decor_id in range(GameState.Q006_DECOR_TOTAL):
		if _q006_decor_inventory_rect(decor_id).has_point(screen_position):
			return false
	for item_id in range(GameState.Q011_ITEM_TOTAL):
		if _q011_item_inventory_rect(item_id).has_point(screen_position):
			return false
	for board_id in range(GameState.BOARD_TOTAL):
		if not game_state.collected[board_id] and _board_rect(board_id).grow(12).has_point(world_position):
			return false
	if _can_start_pond_stage():
		for stone_id in range(GameState.POND_STONE_TOTAL):
			if not game_state.pond_stones_placed[stone_id] and _pond_stone_rect(stone_id).grow(12).has_point(world_position):
				return false
	if build_mode:
		for decor_id in range(GameState.Q006_DECOR_TOTAL):
			if game_state.q006_slot_for_decoration(decor_id) >= 0 and _q006_decor_rect(decor_id).grow(12).has_point(world_position):
				return false
	return true


func _screen_to_world(screen_position: Vector2) -> Vector2:
	return camera_center + (screen_position - _camera_viewport_size() * 0.5) / _camera_zoom_scale()


func _world_to_screen(world_position: Vector2) -> Vector2:
	return _camera_viewport_size() * 0.5 + (world_position - camera_center) * _camera_zoom_scale()


func _camera_viewport_size() -> Vector2:
	return Vector2(maxf(WORLD_SIZE.x, size.x), maxf(WORLD_SIZE.y, size.y))


func _camera_fit_scale() -> float:
	var viewport_size := _camera_viewport_size()
	return minf(viewport_size.x / WORLD_SIZE.x, viewport_size.y / WORLD_SIZE.y)


func _camera_zoom_scale() -> float:
	return _camera_fit_scale() * camera_zoom


func _camera_draw_offset() -> Vector2:
	return _camera_viewport_size() * 0.5 - camera_center * _camera_zoom_scale()


func _set_world_draw_transform() -> void:
	draw_set_transform(_camera_draw_offset(), 0.0, Vector2.ONE * _camera_zoom_scale())


func _restore_world_draw_transform() -> void:
	_set_world_draw_transform()


func _change_camera_zoom(factor: float, screen_anchor: Vector2) -> void:
	var world_anchor := _screen_to_world(screen_anchor)
	camera_zoom = clampf(camera_zoom * factor, CAMERA_MIN_ZOOM, CAMERA_MAX_ZOOM)
	camera_center = world_anchor - (screen_anchor - _camera_viewport_size() * 0.5) / _camera_zoom_scale()
	_clamp_camera_center()
	if zoom_reset_button != null:
		zoom_reset_button.text = "%d%%" % roundi(camera_zoom * 100.0)
	queue_redraw()


func _zoom_in() -> void:
	_change_camera_zoom(CAMERA_ZOOM_STEP, _camera_viewport_size() * 0.5)


func _zoom_out() -> void:
	_change_camera_zoom(1.0 / CAMERA_ZOOM_STEP, _camera_viewport_size() * 0.5)


func _reset_camera() -> void:
	camera_zoom = CAMERA_MIN_ZOOM
	camera_center = WORLD_SIZE * 0.5
	if zoom_reset_button != null:
		zoom_reset_button.text = "100%"
	queue_redraw()


func _clamp_camera_center() -> void:
	var half_view := _camera_viewport_size() * 0.5 / _camera_zoom_scale()
	camera_center.x = clampf(camera_center.x, half_view.x, WORLD_SIZE.x - half_view.x)
	camera_center.y = clampf(camera_center.y, half_view.y, WORLD_SIZE.y - half_view.y)


func _update_camera_pan(screen_position: Vector2) -> void:
	var screen_delta := screen_position - camera_pan_last_screen
	camera_center -= screen_delta / _camera_zoom_scale()
	camera_pan_last_screen = screen_position
	_clamp_camera_center()
	queue_redraw()


func _end_camera_pan() -> void:
	camera_pan_active = false
	camera_pan_touch_index = -1
	camera_pan_last_screen = Vector2.ZERO


func _is_world_drag_active() -> bool:
	return dragging_board >= 0 or dragging_pond_stone >= 0 or dragging_q005_plant >= 0 or dragging_q006_decor >= 0 or dragging_q008_path >= 0 or dragging_q011_item >= 0


func _handle_interact_button_pointer(position: Vector2, pressed: bool) -> bool:
	if interact_button == null or not interact_button.visible or not interact_button.get_global_rect().has_point(position):
		return false
	# Process the main touch action before the Control GUI pass; this keeps the
	# thumb-sized target reliable in WebGL and multitouch browsers.
	if pressed:
		_try_collect_nearby()
	get_viewport().set_input_as_handled()
	return true


func _is_virtual_joystick_hit(position: Vector2) -> bool:
	return position.distance_to(_virtual_joystick_center()) <= JOYSTICK_HIT_RADIUS


func _is_button_control_position(position: Vector2) -> bool:
	for control in [restart_button, build_button, remove_decor_button, q011_button, interact_button, zoom_out_button, zoom_in_button, zoom_reset_button]:
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
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and (virtual_joystick_active or camera_pan_active or _is_world_drag_active()):
		_end_virtual_joystick()
		_end_camera_pan()
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

	zoom_out_button = Button.new()
	zoom_out_button.name = "ZoomOutButton"
	zoom_out_button.text = "−"
	zoom_out_button.position = Vector2(648, 30)
	zoom_out_button.size = Vector2(48, 44)
	zoom_out_button.add_theme_font_size_override("font_size", 24)
	zoom_out_button.add_theme_color_override("font_color", Color("425d48"))
	zoom_out_button.tooltip_text = "缩小地图"
	zoom_out_button.pressed.connect(_zoom_out)
	add_child(zoom_out_button)
	_apply_button_style(zoom_out_button, false)

	zoom_in_button = Button.new()
	zoom_in_button.name = "ZoomInButton"
	zoom_in_button.text = "+"
	zoom_in_button.position = Vector2(702, 30)
	zoom_in_button.size = Vector2(48, 44)
	zoom_in_button.add_theme_font_size_override("font_size", 24)
	zoom_in_button.add_theme_color_override("font_color", Color("425d48"))
	zoom_in_button.tooltip_text = "放大地图；放大后可拖动画布查看各处"
	zoom_in_button.pressed.connect(_zoom_in)
	add_child(zoom_in_button)
	_apply_button_style(zoom_in_button, false)

	zoom_reset_button = Button.new()
	zoom_reset_button.name = "ZoomResetButton"
	zoom_reset_button.text = "100%"
	zoom_reset_button.position = Vector2(756, 30)
	zoom_reset_button.size = Vector2(82, 44)
	zoom_reset_button.add_theme_font_size_override("font_size", 14)
	zoom_reset_button.add_theme_color_override("font_color", Color("425d48"))
	zoom_reset_button.tooltip_text = "恢复全地图视野"
	zoom_reset_button.pressed.connect(_reset_camera)
	add_child(zoom_reset_button)
	_apply_button_style(zoom_reset_button, false)

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
	interact_button.text = "互动"
	interact_button.position = Vector2(1156, 616)
	interact_button.size = INTERACT_BUTTON_SIZE
	interact_button.add_theme_font_size_override("font_size", 22)
	interact_button.add_theme_color_override("font_color", Color("253b32"))
	interact_button.tooltip_text = "收集、浇水、交付或与伙伴互动"
	# Pointer presses are handled in _input before Control's GUI pass. Connecting
	# pressed here would process the same click twice and could deliver multiple
	# quest items from one tap. Keyboard interaction stays on the shared action.
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
	zoom_out_button.position = Vector2(layout_width - 632.0, 30.0)
	zoom_in_button.position = Vector2(layout_width - 578.0, 30.0)
	zoom_reset_button.position = Vector2(layout_width - 524.0, 30.0)
	build_button.position = Vector2(layout_width - 420.0, 24.0)
	remove_decor_button.position = Vector2(layout_width - 420.0, 88.0)
	q011_button.position = Vector2(layout_width - 420.0, 88.0)
	interact_button.position = Vector2(layout_width - INTERACT_BUTTON_SIZE.x - 8.0, maxf(8.0, visible_size.y - INTERACT_BUTTON_SIZE.y - 12.0))
	interact_button.pivot_offset = INTERACT_BUTTON_SIZE * 0.5
	_update_interact_button()
	_update_interact_button_animation()


func _update_interact_button_animation() -> void:
	if interact_button == null:
		return
	if interact_button.visible and interaction_button_ready:
		var pulse := 1.0 + sin(animation_time * 3.0) * 0.012
		interact_button.scale = Vector2.ONE * pulse
	else:
		interact_button.scale = Vector2.ONE


func _update_interact_button() -> void:
	if interact_button == null or game_state == null:
		return
	var action_label := "找木板"
	var action_ready := false
	var action_tooltip := "走近当前目标，使用互动按钮"

	if q011_mode:
		action_label = "放物品"
		action_tooltip = "把右下角托盘物品拖进左侧空槽"
	elif build_mode:
		action_label = "摆装饰"
		action_tooltip = "把托盘里的装饰拖到右侧草地空位"
	elif game_state.can_start_q012():
		action_label = "庆祝"
		action_ready = player_position.distance_to(Q012_RABBIT_POSITION) <= COLLECTION_RADIUS
		action_tooltip = "靠近兔子，参加小岛庆祝"
	elif _can_use_q007_side_task() and game_state.can_start_q007():
		action_label = "捡贝壳"
		action_ready = player_position.distance_to(Q007_SHELL_POSITION) <= COLLECTION_RADIUS
		action_tooltip = "靠近池塘边的隐藏贝壳并收集"
	elif _can_start_q005_stage():
		var watering_distance := player_position.distance_to(Q005_WATERING_POINT_POSITION)
		var nearby_plant_id := _nearest_uncollected_q005_plant()
		var turtle_distance := player_position.distance_to(Q005_TURTLE_POSITION)
		var pond_distance := player_position.distance_to(POND_RECT.get_center())
		if game_state.q005_plant_count() == GameState.Q005_PLANT_TOTAL and not game_state.q005_harvest_delivered:
			action_label = "送花" if turtle_distance <= Q005_TURTLE_INTERACTION_RADIUS else "找乌龟"
			action_ready = turtle_distance <= Q005_TURTLE_INTERACTION_RADIUS
			action_tooltip = "把采好的花交给乌龟" if action_ready else "花已采齐，回到乌龟身边交给它"
		elif turtle_distance <= Q005_TURTLE_INTERACTION_RADIUS:
			action_label = "问乌龟"
			action_ready = true
			action_tooltip = "和乌龟聊聊花园的照料方法"
		elif pond_distance <= POND_INTERACTION_RADIUS:
			action_label = "看池塘"
			action_ready = true
			action_tooltip = "看看刚整理好的池塘"
		elif not game_state.q005_watered:
			action_label = "浇水"
			action_ready = watering_distance <= Q005_WATERING_RADIUS
			action_tooltip = "先给乌龟花园浇水，花苗才会长大"
		else:
			if nearby_plant_id >= 0:
				action_label = "采花"
				action_ready = true
				action_tooltip = "采下这朵花；花圃会保留盛开的植株"
			else:
				action_label = "采花"
				action_tooltip = "沿着花圃寻找还没采过的花"
	elif _can_use_q010_side_task() and game_state.can_start_q010():
		action_label = "收种子"
		action_ready = _nearest_uncollected_q010_seed() >= 0
		if action_ready:
			action_tooltip = "靠近红花、蓝花或金色种子并收集"
		elif _can_use_q009_side_task() and game_state.q009_bird_interaction_unlocked() and player_position.distance_to(Q009_BIRD_POSITION) <= Q009_BIRD_INTERACTION_RADIUS:
			action_label = "打招呼"
			action_ready = true
			action_tooltip = "靠近小鸟打招呼"
		else:
			action_tooltip = "寻找并收集红花、蓝花和金色种子"
	elif game_state.can_start_q004():
		var near_house := player_position.distance_to(HOUSE_POSITION) <= HOUSE_INTERACTION_RADIUS
		var near_wood_id := _nearest_uncollected_wood()
		if near_house:
			action_label = "交木材" if game_state.wood_count() > game_state.delivered_wood_count() else "互动"
			action_ready = true
			action_tooltip = "把收集的木材交给狐狸，或查看建屋要求"
		else:
			action_label = "收木材" if game_state.wood_count() < GameState.Q004_WOOD_TOTAL else "交木材"
			action_ready = near_wood_id >= 0
			action_tooltip = "木材齐了就去狐狸小屋交付" if game_state.wood_count() >= GameState.Q004_WOOD_TOTAL else "靠近木材并收集"
	elif _can_use_q009_side_task() and game_state.can_start_q009():
		if game_state.q009_material_count() == GameState.Q009_MATERIAL_TOTAL:
			var near_birdhouse := player_position.distance_to(Q009_BIRDHOUSE_POSITION) <= Q009_BIRDHOUSE_INTERACTION_RADIUS
			action_label = "交材料" if near_birdhouse else "去鸟屋"
			action_ready = near_birdhouse
			action_tooltip = "在鸟屋旁逐份交付材料（%d/3）" % game_state.q009_material_delivery_count()
		else:
			action_label = "收材料"
			action_ready = _nearest_uncollected_q009_material() >= 0
			action_tooltip = "靠近树枝、羽毛或草绳并收集；集齐后到鸟屋交付"
	elif _can_use_q009_side_task() and game_state.q009_bird_interaction_unlocked():
		action_label = "打招呼"
		action_ready = player_position.distance_to(Q009_BIRD_POSITION) <= Q009_BIRD_INTERACTION_RADIUS
		action_tooltip = "靠近小鸟打招呼"
	elif game_state.can_collect_seed():
		action_label = "收种子"
		action_ready = player_position.distance_to(SEED_POSITION) <= COLLECTION_RADIUS
		action_tooltip = "靠近发光的种子并收集"
	elif game_state.can_plant_seed():
		action_label = "种下"
		action_ready = player_position.distance_to(FLOWERBED_POSITION) <= FLOWERBED_INTERACTION_RADIUS
		action_tooltip = "靠近右侧花圃种下种子"
	elif not game_state.is_complete():
		var nearby_board_id := _nearest_uncollected_board()
		if nearby_board_id >= 0:
			action_label = "收木板"
			action_ready = true
			action_tooltip = "捡起这块木板；收集三块后修复小桥"
		else:
			action_label = "找木板"
			action_tooltip = "沿着岛上的木板标记移动，靠近后收集"
	elif _can_show_pond_area() and player_position.distance_to(POND_RECT.get_center()) <= POND_INTERACTION_RADIUS:
		action_label = "看池塘"
		action_ready = true
		action_tooltip = "按下互动按钮，看看池塘的变化"
	elif player_position.distance_to(Q005_TURTLE_POSITION) <= Q005_TURTLE_INTERACTION_RADIUS and game_state.is_pond_complete():
		action_label = "问乌龟"
		action_ready = true
		action_tooltip = "和乌龟聊聊小岛上的新变化"

	if action_label == interaction_button_label and action_ready == interaction_button_ready and action_tooltip == interaction_button_tooltip:
		interact_button.visible = _should_show_interact_button()
		return
	interaction_button_label = action_label
	interaction_button_ready = action_ready
	interaction_button_tooltip = action_tooltip
	interact_button.text = action_label
	interact_button.tooltip_text = action_tooltip
	var style := StyleBoxFlat.new()
	style.bg_color = Color("459b63") if action_ready else Color("f5f0dc")
	style.border_color = Color("287548") if action_ready else Color("b9c9a7")
	style.set_border_width_all(2)
	style.set_corner_radius_all(24)
	style.shadow_color = Color(0.05, 0.20, 0.15, 0.24)
	style.shadow_size = 8 if action_ready else 4
	style.shadow_offset = Vector2(0, 4)
	style.anti_aliasing = true
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = Color("58b779") if action_ready else Color("fff9e9")
	var pressed := style.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("348653") if action_ready else Color("e8e2cf")
	interact_button.add_theme_stylebox_override("normal", style)
	interact_button.add_theme_stylebox_override("hover", hover)
	interact_button.add_theme_stylebox_override("pressed", pressed)
	interact_button.add_theme_color_override("font_color", Color("fff9e8") if action_ready else Color("405d4c"))
	interact_button.add_theme_color_override("font_hover_color", Color("ffffff") if action_ready else Color("294c3a"))
	interact_button.add_theme_color_override("font_pressed_color", Color("f8ffe9") if action_ready else Color("294c3a"))
	interact_button.visible = _should_show_interact_button()


func _should_show_interact_button() -> bool:
	if game_state == null or q011_mode or build_mode:
		return false
	if game_state.is_q012_complete() and celebration_remaining > 0.0:
		return false
	if game_state.can_start_q012():
		return true
	if _can_use_q007_side_task() and game_state.can_start_q007():
		return true
	if _can_start_q005_stage():
		return true
	if _can_use_q010_side_task() and game_state.can_start_q010():
		return true
	if game_state.can_start_q004():
		return true
	if _can_use_q009_side_task() and game_state.can_start_q009():
		return true
	if _can_use_q008_side_task() and game_state.can_start_q008():
		return false
	if _can_use_q011_mode():
		return false
	if _can_use_q009_side_task() and game_state.q009_bird_interaction_unlocked():
		return player_position.distance_to(Q009_BIRD_POSITION) <= Q009_BIRD_INTERACTION_RADIUS
	if game_state.can_collect_seed() or game_state.can_plant_seed():
		return true
	if not game_state.is_complete():
		return game_state.board_count() < GameState.BOARD_TOTAL
	return _can_show_pond_area() and player_position.distance_to(POND_RECT.get_center()) <= POND_INTERACTION_RADIUS or player_position.distance_to(Q005_TURTLE_POSITION) <= Q005_TURTLE_INTERACTION_RADIUS and game_state.is_pond_complete()


func _nearest_uncollected_board() -> int:
	return _nearest_available_position(BOARD_POSITIONS, game_state.collected, COLLECTION_RADIUS)


func _nearest_uncollected_q005_plant() -> int:
	return _nearest_available_position(Q005_PLANT_POSITIONS, game_state.q005_plants_collected, Q005_INTERACTION_RADIUS)


func _nearest_uncollected_q010_seed() -> int:
	return _nearest_available_position(Q010_SEED_POSITIONS, game_state.q010_seeds_collected, COLLECTION_RADIUS)


func _nearest_uncollected_wood() -> int:
	return _nearest_available_position(WOOD_POSITIONS, game_state.wood_collected, COLLECTION_RADIUS)


func _nearest_uncollected_q009_material() -> int:
	return _nearest_available_position(Q009_MATERIAL_POSITIONS, game_state.q009_materials_collected, COLLECTION_RADIUS)


func _nearest_available_position(positions: Array, unavailable: Array, radius: float) -> int:
	var nearest_id := -1
	var nearest_distance := radius
	for item_id in range(mini(positions.size(), unavailable.size())):
		if unavailable[item_id]:
			continue
		var target_position: Vector2 = positions[item_id]
		var distance: float = player_position.distance_to(target_position)
		if distance <= nearest_distance:
			nearest_id = item_id
			nearest_distance = distance
	return nearest_id


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
		message = "花园装饰模式已打开：右侧草地都可摆放，绿色提示圈表示位置合适。"
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
	_update_interact_button()


func _apply_build_button_style(highlighted: bool) -> void:
	_apply_button_style(build_button, highlighted)
	build_button.add_theme_color_override("font_color", Color("fff9e8") if highlighted else Color("405d4c"))
	build_button.add_theme_color_override("font_hover_color", Color("ffffff") if highlighted else Color("294c3a"))
	build_button.add_theme_color_override("font_pressed_color", Color("f8ffe9") if highlighted else Color("294c3a"))
	build_button.add_theme_font_size_override("font_size", 20 if highlighted else 22)


func _apply_button_style(button: Button, highlighted: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("459b63") if highlighted else Color("f5f0dc")
	normal.border_color = Color("287548") if highlighted else Color("b9c9a7")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(16)
	normal.shadow_color = Color(0.05, 0.20, 0.15, 0.20)
	normal.shadow_size = 6 if highlighted else 4
	normal.shadow_offset = Vector2(0, 3)
	normal.anti_aliasing = true
	normal.content_margin_left = 10.0
	normal.content_margin_right = 10.0
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("58b779") if highlighted else Color("fff9e9")
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("348653") if highlighted else Color("e8e2cf")
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


func _should_show_q011_area_contents() -> bool:
	return _can_show_q011_area() and (q011_mode or game_state.is_q011_complete())


func _pointer_down(position: Vector2, screen_position := Vector2(-1.0, -1.0)) -> void:
	if screen_position.x < 0.0:
		screen_position = position
	if dragging_board >= 0 or dragging_pond_stone >= 0 or dragging_q005_plant >= 0 or dragging_q006_decor >= 0 or dragging_q008_path >= 0 or dragging_q011_item >= 0:
		return
	if q011_mode:
		if _can_use_q011_mode():
			for item_id in range(GameState.Q011_ITEM_TOTAL):
				if game_state.q011_item_is_available(item_id) and _q011_item_inventory_rect(item_id).has_point(screen_position):
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
			for placed_decor_id in range(GameState.Q006_DECOR_TOTAL):
				var placed_slot: int = game_state.q006_slot_for_decoration(placed_decor_id)
				if placed_slot >= 0 and _q006_decor_rect(placed_decor_id).grow(12).has_point(position):
					if game_state.remove_q006_decoration(placed_decor_id, placed_slot):
						_save_game()
						message = "装饰已收回托盘，可以换个位置摆放。"
						message_color = Color("d9ffd0")
						queue_redraw()
					return
			message = "请点击已放置的装饰。"
			message_color = Color("ffe1b8")
			queue_redraw()
			return
		for placed_decor_id in range(GameState.Q006_DECOR_TOTAL):
			var placed_slot: int = game_state.q006_slot_for_decoration(placed_decor_id)
			if placed_slot >= 0 and _q006_decor_rect(placed_decor_id).grow(12).has_point(position):
				dragging_q006_decor = placed_decor_id
				q006_decor_drag_from_slot = placed_slot
				q006_decor_drag_position = position
				message = "拖动装饰到右侧草地，绿圈亮起时松开。"
				message_color = Color("fff7cf")
				queue_redraw()
				return
		for decor_id in range(GameState.Q006_DECOR_TOTAL):
			if game_state.q006_decor_is_available(decor_id) and _q006_decor_inventory_rect(decor_id).has_point(screen_position):
				dragging_q006_decor = decor_id
				q006_decor_drag_from_slot = -1
				q006_decor_drag_position = position
				message = "把装饰拖到右侧草地，绿圈亮起时松开。"
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
		# Flower collection is an interaction step; the bloom remains in its bed,
		# so there is no second inventory-to-the-same-plot drag operation.
		pass

	if _can_use_q008_side_task() and game_state.can_start_q008():
		for material_id in range(GameState.Q008_PATH_SLOT_TOTAL):
			if not game_state.q008_path_material_is_available(material_id):
				continue
			if _q008_path_material_rect(material_id).grow(12).has_point(screen_position):
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
		if game_state.can_place_board(board_id) and _inventory_rect(board_id).has_point(screen_position):
			dragging_board = board_id
			drag_position = position
			message = "拖动木板到桥上的高亮位置，绿色时松开。"
			message_color = Color("fff7cf")
			queue_redraw()
			return


func _pointer_up(position: Vector2, _screen_position := Vector2(-1.0, -1.0)) -> void:
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
		var q006_was_complete: bool = game_state.is_q006_complete()
		var drop_valid := _q006_decor_drop_is_valid(decor_id, position)
		dragging_q006_decor = -1
		q006_decor_drag_from_slot = -1
		q006_decor_drag_position = Vector2.ZERO
		var placed_successfully := false
		if drop_valid and from_slot >= 0:
			placed_successfully = game_state.move_q006_decoration_to(decor_id, from_slot, position)
		elif drop_valid:
			placed_successfully = game_state.place_q006_decoration_at(decor_id, position)
		if placed_successfully:
			_start_task_transition(position, "装饰摆好了")
			message = "摆放成功！可在右侧草地自由移动，也能继续放下一件。"
			message_color = Color("d9ffd0")
			_save_game()
			if not q006_was_complete and game_state.is_q006_complete():
				build_mode = false
				remove_decor_mode = false
				_start_task_transition(position, "花园布置完成")
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
			_start_collect_sparkles(POND_SLOTS[target_slot].get_center(), Color("a9e7f0"))
			message = "池边石头放好 %d/3！" % game_state.pond_stones_placed.count(true)
			message_color = Color("d9ffd0")
			_save_game()
			if game_state.is_pond_complete():
				pond_ripple_remaining = 1.0
				_start_task_transition(POND_RECT.get_center(), "池塘恢复清澈")
				message = "池塘整理好了！下一步：去照料乌龟的花园。"
				message_color = Color("fff1a8")
		else:
			message = "这个位置不合适，石头没有丢失。"
			message_color = Color("ffe1b8")
		queue_redraw()
		return

	if dragging_q005_plant >= 0:
		dragging_q005_plant = -1
		q005_plant_drag_position = Vector2.ZERO
		message = "花苗已经留在花圃里，不需要再拖回去。走近乌龟交花束即可。"
		message_color = Color("fff1a8")
		queue_redraw()
		return

	if dragging_q008_path >= 0:
		var material_id := dragging_q008_path
		var target_slot := _q008_path_slot_at(position)
		dragging_q008_path = -1
		q008_path_drag_position = Vector2.ZERO
		if target_slot >= 0 and game_state.place_q008_path(material_id, target_slot):
			_start_collect_sparkles(Q008_PATH_SLOT_RECTS[target_slot].get_center(), Color("fff1a8"))
			message = "路面石板放好 %d/3！" % game_state.q008_path_placed_count()
			message_color = Color("d9ffd0")
			_save_game()
			if game_state.is_q008_complete():
				_start_task_transition(Q008_PATH_SLOT_RECTS[target_slot].get_center(), "小路连起来了")
				message = "三块石板连成小路！小路整理完成。"
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
		message = "桥板放好 %d/3！" % game_state.placed_count()
		message_color = Color("d9ffd0")
		_save_game()
		if game_state.is_complete():
			bridge_repair_remaining = BRIDGE_REPAIR_DURATION
			_start_task_transition(BRIDGE_RECT.get_center(), "小桥修好了")
			message = "太棒了！小桥修好了，右侧区域已经开放！"
			message_color = Color("fff1a8")
	else:
		message = "还差一点：请把木板拖到它对应的桥上空位。木板没有丢失。"
		message_color = Color("ffe1b8")
	queue_redraw()


func _try_collect_nearby() -> void:
	if game_state.is_q012_complete() and celebration_remaining > 0.0:
		return
	if game_state.can_start_q012():
		if player_position.distance_to(Q012_RABBIT_POSITION) <= COLLECTION_RADIUS:
			if game_state.complete_q012():
				celebration_remaining = CELEBRATION_DURATION
				_start_task_transition(Q012_RABBIT_POSITION, "主线完成 · 开始庆祝")
				_save_game()
				message = "主线故事完成！和兔子一起庆祝吧，之后可自由探索。"
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

	if _try_pond_interaction():
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

	if _try_turtle_interaction():
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
				_start_task_transition(FLOWERBED_POSITION, "种子种下了")
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
		message = "请走到木板旁边，再按右下角按钮或 E 键。"
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
	var turtle_distance := player_position.distance_to(Q005_TURTLE_POSITION)
	if game_state.q005_plant_count() == GameState.Q005_PLANT_TOTAL and not game_state.q005_harvest_delivered:
		if turtle_distance <= Q005_TURTLE_INTERACTION_RADIUS and game_state.deliver_q005_harvest():
			_start_task_transition(Q005_TURTLE_POSITION, "乌龟收到花束")
			_save_game()
			message = "花束交给乌龟了！花园恢复生机，可以开始布置装饰。"
			message_color = Color("fff1a8")
		else:
			message = "花束已经采好，走到乌龟身边点“送花”。"
			message_color = Color("fff7cf")
		return true
	if turtle_distance <= Q005_TURTLE_INTERACTION_RADIUS:
		if not game_state.q005_watered:
			message = "乌龟：先给浇水点浇水，花苗长好后再采花。"
		elif game_state.q005_plant_count() < GameState.Q005_PLANT_TOTAL:
			message = "乌龟：花已经开了，采下三朵后带回来给我看看吧。"
		message_color = Color("d9ffd0")
		return true
	var watering_distance := player_position.distance_to(Q005_WATERING_POINT_POSITION)
	# Match the button label and tutorial order: before the garden is watered,
	# the watering point always wins over overlapping flower hit areas.
	if not game_state.q005_watered and watering_distance <= Q005_WATERING_RADIUS:
		if game_state.water_q005():
			q005_growth_remaining = Q005_GROWTH_DURATION
			_start_task_transition(Q005_WATERING_POINT_POSITION, "花苗喝饱水了")
			_save_game()
			message = "浇水成功！等花苗长好，再逐株采下三朵花。"
			message_color = Color("d9ffd0")
		else:
			message = "花园已经浇过水了。走近盛开的花，逐株采收。"
			message_color = Color("fff1a8")
		return true
	var target_id := -1
	var nearest_distance := Q005_INTERACTION_RADIUS
	for plant_id in range(GameState.Q005_PLANT_TOTAL):
		if game_state.q005_plants_collected[plant_id]:
			continue
		var distance := player_position.distance_to(Q005_PLANT_POSITIONS[plant_id])
		if distance <= nearest_distance:
			target_id = plant_id
			nearest_distance = distance
	if target_id >= 0 and not game_state.q005_watered:
		message = "先给花园浇水，植物长好后才能采集。"
		message_color = Color("fff1a8")
		return true
	if target_id >= 0 and game_state.collect_q005_plant(target_id):
		_start_task_transition(Q005_PLANT_POSITIONS[target_id], "采下一朵花")
		_save_game()
		if game_state.q005_plant_count() == GameState.Q005_PLANT_TOTAL:
			message = "三朵花都采好了！花圃仍然盛开，回到乌龟身边交花束。"
			message_color = Color("fff1a8")
		else:
			message = "采到一朵花！收获 %d/3；花圃会保留盛开的植株。" % game_state.q005_plant_count()
			message_color = Color("d9ffd0")
		return true
	if _can_show_pond_area() and player_position.distance_to(POND_RECT.get_center()) <= POND_INTERACTION_RADIUS:
		return _try_pond_interaction()
	return false


func _try_pond_interaction() -> bool:
	if not _can_show_pond_area() or player_position.distance_to(POND_RECT.get_center()) > POND_INTERACTION_RADIUS:
		return false
	if game_state.is_pond_complete():
		pond_ripple_remaining = 1.0
		message = "池塘水面荡开一圈涟漪，乌龟开心地探出头。"
		message_color = Color("d9ffd0")
	else:
		message = "池塘还需要 %d 块石头。把石头拖到池边的轮廓里。" % (GameState.POND_STONE_TOTAL - game_state.pond_stones_placed.count(true))
		message_color = Color("fff7cf")
	return true


func _try_turtle_interaction() -> bool:
	if not game_state.is_pond_complete() or player_position.distance_to(Q005_TURTLE_POSITION) > Q005_TURTLE_INTERACTION_RADIUS:
		return false
	message = "乌龟：谢谢你把池塘和花园照料得这么好！"
	message_color = Color("d9ffd0")
	_start_collect_sparkles(Q005_TURTLE_POSITION, Color("a9df88"))
	return true


func _try_q004_interaction() -> void:
	if player_position.distance_to(HOUSE_POSITION) <= HOUSE_INTERACTION_RADIUS:
		if game_state.deliver_next_wood():
			_save_game()
			if game_state.is_q004_complete():
				_start_task_transition(HOUSE_POSITION, "狐狸搬进新家")
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
	if game_state.q009_material_count() == GameState.Q009_MATERIAL_TOTAL:
		if player_position.distance_to(Q009_BIRDHOUSE_POSITION) > Q009_BIRDHOUSE_INTERACTION_RADIUS:
			message = "材料已经找齐了！走到鸟屋旁边点“交材料”，亲手帮小鸟搭建。"
			message_color = Color("fff1a8")
			return true
		if game_state.deliver_next_q009_material():
			_start_task_transition(Q009_BIRDHOUSE_POSITION, "鸟屋逐渐搭起来")
			_save_game()
			if game_state.is_q009_complete():
				_start_task_transition(Q009_BIRDHOUSE_POSITION, "小鸟有新家了")
				message = "鸟屋建好了！去小鸟身边和它打个招呼。"
				message_color = Color("fff1a8")
			else:
				message = "材料交付 %d/3，小鸟正在搭建鸟屋。" % game_state.q009_material_delivery_count()
				message_color = Color("d9ffd0")
			return true
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
		if game_state.q009_material_count() == GameState.Q009_MATERIAL_TOTAL:
			message = "材料收集齐了！现在去鸟屋旁边逐份交付。"
			message_color = Color("fff1a8")
		else:
			message = "找到%s！材料收集 %d/3。" % [Q009_MATERIAL_LABELS[nearest_id], game_state.q009_material_count()]
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
	return Rect2(INVENTORY_ORIGIN + Vector2(INVENTORY_STEP * board_id, 0), Vector2(76, 46))


func _pond_stone_rect(stone_id: int) -> Rect2:
	return Rect2(POND_STONE_POSITIONS[stone_id] - Vector2(22, 16), Vector2(44, 32))


func _pond_drag_target_at(position: Vector2) -> int:
	if dragging_pond_stone < 0 or not game_state.can_place_pond_stone(dragging_pond_stone):
		return -1
	if dragging_pond_stone >= POND_SLOTS.size():
		return -1
	return dragging_pond_stone if POND_SLOTS[dragging_pond_stone].grow(18).has_point(position) else -1


func _q005_plant_inventory_rect(plant_id: int) -> Rect2:
	return Rect2(INVENTORY_ORIGIN + Vector2(INVENTORY_STEP * plant_id, 0), Vector2(76, 46))


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
	return Rect2(Q006_DECOR_INVENTORY_ORIGIN + Vector2(Q006_DECOR_INVENTORY_STEP * decor_id, 0), Vector2(76, 42))


func _q006_decor_slot_rect(slot_id: int) -> Rect2:
	return Q006_DECOR_SLOTS[slot_id]


func _q006_decor_rect(decor_id: int) -> Rect2:
	if decor_id < 0 or decor_id >= game_state.q006_decor_positions.size():
		return Rect2()
	return Rect2(game_state.q006_decor_positions[decor_id] - Vector2(28, 23), Vector2(56, 46))


func _q006_decor_drop_is_valid(decor_id: int, position: Vector2) -> bool:
	if decor_id < 0 or decor_id >= GameState.Q006_DECOR_TOTAL:
		return false
	var safe_bounds := Q006_DECOR_BOUNDS.grow(-14.0)
	if not safe_bounds.has_point(position) or not Geometry2D.is_point_in_polygon(position, PackedVector2Array(Q006_DECOR_ISLAND_POLYGON)):
		return false
	if POND_RECT.grow(28.0).has_point(position) or Q005_GARDEN_RECT.grow(20.0).has_point(position):
		return false
	if position.distance_to(Q005_TURTLE_POSITION) < 76.0:
		return false
	if position.distance_to(Q007_REWARD_POSITION) < 42.0:
		return false
	for flower_position in [Vector2(1182, 205), Vector2(1182, 584)]:
		if position.distance_to(flower_position) < 42.0:
			return false
	for stone_id in range(GameState.POND_STONE_TOTAL):
		if game_state.pond_stones_placed[stone_id] and position.distance_to(POND_STONE_POSITIONS[stone_id]) < 44.0:
			return false
	for other_id in range(GameState.Q006_DECOR_TOTAL):
		if other_id == decor_id or not game_state.q006_decor_placed[other_id]:
			continue
		if position.distance_to(game_state.q006_decor_positions[other_id]) < Q006_DECOR_CLEARANCE:
			return false
	return true


func _q006_decor_slot_at(position: Vector2) -> int:
	if dragging_q006_decor < 0:
		return -1
	return dragging_q006_decor if _q006_decor_drop_is_valid(dragging_q006_decor, position) else -1


func _q006_decor_slot_is_drop_target(slot_id: int) -> bool:
	return dragging_q006_decor >= 0 and slot_id == dragging_q006_decor and _q006_decor_drop_is_valid(dragging_q006_decor, q006_decor_drag_position)


func _q006_decor_slot_is_hovered(slot_id: int) -> bool:
	return _q006_decor_slot_is_drop_target(slot_id)


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
	return Rect2(Q011_INVENTORY_ORIGIN + Vector2(Q011_INVENTORY_STEP * item_id, 0), Vector2(76, 44))


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
	_reset_camera()
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
	draw_rect(Rect2(Vector2.ZERO, _camera_viewport_size()), VISUAL_PALETTE["sky"], true)
	_set_world_draw_transform()
	_draw_background()
	_draw_world(font)
	_draw_feedback_effects()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_interact_button_glow()
	_draw_hud(font)
	_draw_touch_hint(font)
	if _is_world_drag_active():
		_set_world_draw_transform()
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
	if _is_world_drag_active():
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


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
	if task_transition_remaining > 0.0 and not task_transition_text.is_empty():
		var progress := 1.0 - task_transition_remaining / TASK_TRANSITION_DURATION
		var fade_in := clampf(progress / 0.16, 0.0, 1.0)
		var fade_out := clampf((1.0 - progress) / 0.24, 0.0, 1.0)
		var alpha := minf(fade_in, fade_out)
		var eased_progress := 1.0 - pow(1.0 - progress, 3.0)
		var ripple_color := Color(0.95, 1.0, 0.79, alpha * 0.66)
		for ring_id in range(2):
			var ring_delay := float(ring_id) * 0.16
			var ring_progress := clampf(eased_progress - ring_delay, 0.0, 1.0)
			var ring_alpha := alpha * (1.0 - ring_progress * 0.72)
			draw_arc(task_transition_position, 21.0 + ring_progress * 50.0, 0.0, TAU, 40, Color(ripple_color, ring_alpha), 2.5 - ring_progress * 0.8)
		var label_width := maxf(118.0, UI_FONT.get_string_size(task_transition_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16).x + 28.0)
		var label_scale := 0.90 + clampf(progress / 0.18, 0.0, 1.0) * 0.10
		var label_size := Vector2(label_width, 38.0) * label_scale
		var label_rect := Rect2(task_transition_position + Vector2(-label_size.x * 0.5, -67.0 - eased_progress * 13.0), label_size)
		var label_fill := Color("faf2d2")
		var label_border := Color("d6ae62")
		_draw_soft_panel(label_rect, label_fill, label_border, 17, 0.12)
		draw_circle(label_rect.position + Vector2(15, 19), 4.0, Color(0.39, 0.69, 0.43, alpha))
		draw_string(UI_FONT, label_rect.position + Vector2(28, 24), task_transition_text, HORIZONTAL_ALIGNMENT_CENTER, label_width - 36, 16, Color(0.22, 0.35, 0.28, alpha))
	if pond_ripple_remaining > 0.0:
		var progress := 1.0 - pond_ripple_remaining / 1.0
		var ripple_alpha := 1.0 - progress
		for ring_id in range(3):
			var ring_progress := clampf(progress + float(ring_id) * 0.12, 0.0, 1.0)
			var ring_color := Color(0.89, 0.99, 0.95, ripple_alpha * 0.52)
			draw_arc(POND_RECT.get_center(), 14.0 + ring_progress * 70.0, 0.0, TAU, 42, ring_color, 2.0)


func _draw_interact_button_glow() -> void:
	if interact_button == null or not interact_button.visible or not interaction_button_ready:
		return
	var button_center := interact_button.position + interact_button.size * 0.5
	var button_pulse := 0.5 + sin(animation_time * 3.2) * 0.5
	var glow_color := Color(0.58, 0.92, 0.61, 0.07 + button_pulse * 0.07)
	_draw_ellipse_custom(button_center, Vector2(interact_button.size.x * 0.54 + button_pulse * 2.0, interact_button.size.y * 0.53 + button_pulse * 2.0), glow_color)
	if celebration_remaining > 0.0:
		var celebration_progress := 1.0 - celebration_remaining / CELEBRATION_DURATION
		var celebration_glow := 0.025 + (0.5 + sin(animation_time * 2.0) * 0.5) * 0.04
		_draw_ellipse_custom(Q012_RABBIT_POSITION + Vector2(0, 8), Vector2(74, 90), Color(1.0, 0.92, 0.62, celebration_glow))
		var confetti_colors := [Color("f2c879"), Color("e96b70"), Color("67a9dc"), Color("a9df88"), Color("fff1a8"), Color("f6e2bb")]
		var confetti_alpha := clampf(celebration_remaining / 0.7, 0.0, 1.0)
		for confetti_id in range(42):
			var column := float((confetti_id * 67) % 1180) + 42.0
			var fall := fposmod(celebration_progress * 0.82 + float(confetti_id) * 0.047, 1.0)
			var sway := sin(animation_time * 2.7 + float(confetti_id) * 1.6) * (7.0 + float(confetti_id % 5) * 1.5)
			var confetti_position := Vector2(column + sway, 118.0 + fall * 520.0)
			var confetti_color: Color = confetti_colors[confetti_id % confetti_colors.size()]
			confetti_color.a = confetti_alpha * (0.76 if confetti_id % 4 == 0 else 0.90)
			var spin := animation_time * (1.4 + float(confetti_id % 4) * 0.2) + float(confetti_id) * 0.9
			var petal_size := Vector2(3.0 + float(confetti_id % 3), 6.0 + float(confetti_id % 4))
			var points := PackedVector2Array()
			for corner in [Vector2(-petal_size.x, -petal_size.y), Vector2(petal_size.x, -petal_size.y), Vector2(petal_size.x, petal_size.y), Vector2(-petal_size.x, petal_size.y)]:
				points.append(confetti_position + corner.rotated(spin))
			draw_colored_polygon(points, confetti_color)


func _draw_background() -> void:
	draw_texture_rect(ISLAND_BACKGROUND, Rect2(Vector2.ZERO, WORLD_SIZE), false)
	# A veil of warm daylight keeps the painted landscape gentle under the journal UI.
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color(1.0, 0.98, 0.88, 0.035))
	_draw_floating_petals()


func _draw_floating_petals() -> void:
	var petal_colors := [Color("fff2cf"), Color("f7c5cf"), Color("d9eff1")]
	for petal_id in range(10):
		var phase := animation_time * (0.17 + float(petal_id % 3) * 0.025) + float(petal_id) * 1.73
		var x_base := float((petal_id * 139 + 72) % 1220) + 30.0
		var y := 150.0 + fposmod(animation_time * (11.0 + float(petal_id % 4) * 1.8) + float(petal_id) * 83.0, 500.0)
		var petal_position := Vector2(x_base + sin(phase) * 18.0, y + cos(phase * 0.7) * 5.0)
		var petal_size := Vector2(2.0 + float(petal_id % 2), 4.0 + float(petal_id % 3))
		var petal_color: Color = petal_colors[petal_id % petal_colors.size()]
		petal_color.a = 0.42
		var petal_points := PackedVector2Array([
			petal_position + Vector2(-petal_size.x, 0).rotated(phase),
			petal_position + Vector2(0, -petal_size.y).rotated(phase),
			petal_position + Vector2(petal_size.x, 0).rotated(phase),
			petal_position + Vector2(0, petal_size.y).rotated(phase),
		])
		draw_colored_polygon(petal_points, petal_color)


func _draw_world(font: Font) -> void:
	_draw_environment_glimmers()
	_draw_river()
	_draw_bridge(font)
	_draw_rabbit_area(font)
	_draw_region_area(font)
	_draw_seed_area(font)
	_draw_pond_area(font)
	_draw_q004_area(font)
	_draw_q005_area(font)
	_draw_q006_area(font)
	if celebration_remaining <= 0.0:
		_draw_q008_area(font)
		_draw_q007_area(font)
		_draw_q009_area(font)
		_draw_q010_area(font)
		_draw_q011_area(font)
	_draw_boards(font)
	_draw_player()


func _draw_environment_glimmers() -> void:
	for glimmer_id in range(6):
		var phase := animation_time * 0.82 + float(glimmer_id) * 1.91
		var position := Vector2(180.0 + float((glimmer_id * 173) % 900), 204.0 + float((glimmer_id * 97) % 380))
		var alpha := 0.20 + (sin(phase) + 1.0) * 0.12
		var glimmer_color := Color(1.0, 0.96, 0.76, alpha)
		draw_circle(position + Vector2(sin(phase) * 4.0, cos(phase) * 3.0), 1.6 + (sin(phase) + 1.0) * 0.7, glimmer_color)


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
	_draw_island_shape(right_island, VISUAL_PALETTE["island_grass"])
	_draw_grass_details()
	_draw_ground_texture()
	_draw_locked_area_preview()
	_draw_ground_flowers()


func _draw_island_shape(points: PackedVector2Array, fill: Color) -> void:
	var smooth_points := _smooth_closed_polygon(points, 6)
	var island_center := Vector2.ZERO
	for point in points:
		island_center += point
	island_center /= float(points.size())
	var shadow := PackedVector2Array()
	var shore := PackedVector2Array()
	var meadow := PackedVector2Array()
	for point in smooth_points:
		shadow.append(point + Vector2(0, 9))
		shore.append(point.lerp(island_center, 0.018))
		meadow.append(point.lerp(island_center, 0.042))
	draw_colored_polygon(shadow, VISUAL_PALETTE["island_shadow"])
	draw_colored_polygon(smooth_points, Color("d8bd81"))
	draw_colored_polygon(shore, Color("f0d7a1"))
	draw_colored_polygon(meadow, fill)
	var edge := meadow.duplicate()
	edge.append(meadow[0])
	draw_polyline(edge, Color("aed785"), 3.0, true)
	var inner_glint := PackedVector2Array()
	for point in meadow:
		inner_glint.append(point + Vector2(0, 3))
	inner_glint.append(inner_glint[0])
	draw_polyline(inner_glint, Color(0.95, 0.94, 0.70, 0.38), 1.4, true)


func _smooth_closed_polygon(points: PackedVector2Array, steps_per_edge := 5) -> PackedVector2Array:
	var smoothed := PackedVector2Array()
	for index in range(points.size()):
		var p0: Vector2 = points[posmod(index - 1, points.size())]
		var p1: Vector2 = points[index]
		var p2: Vector2 = points[(index + 1) % points.size()]
		var p3: Vector2 = points[(index + 2) % points.size()]
		for step in range(steps_per_edge):
			var t := float(step) / float(steps_per_edge)
			var t2 := t * t
			var t3 := t2 * t
			var sample := 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3)
			smoothed.append(sample)
	return smoothed


func _draw_grass_details() -> void:
	var grass_positions := [Vector2(126, 194), Vector2(176, 580), Vector2(652, 196), Vector2(1018, 556), Vector2(1160, 510), Vector2(300, 146), Vector2(1144, 150), Vector2(690, 590)]
	for grass_id in range(grass_positions.size()):
		var position: Vector2 = grass_positions[grass_id]
		var sway := sin(animation_time * 1.7 + float(grass_id) * 1.4) * 2.0
		draw_line(position + Vector2(-2, 2), position + Vector2(5 + sway, -10), Color("c5df91"), 2.3)
		draw_line(position + Vector2(4, 2), position + Vector2(13 + sway, -7), Color("c5df91"), 2.3)
		draw_line(position + Vector2(7, 1), position + Vector2(8 + sway, -5), Color("d3e8a2"), 1.6)


func _draw_ground_texture() -> void:
	var grass_clusters := [
		Vector2(210, 205), Vector2(634, 214), Vector2(174, 558), Vector2(664, 578),
		Vector2(568, 300), Vector2(954, 231), Vector2(1172, 252), Vector2(1150, 575),
	]
	for cluster_id in range(grass_clusters.size()):
		_draw_grass_cluster(grass_clusters[cluster_id], 0.72 + float(cluster_id % 3) * 0.12, cluster_id)
	var footpath := [
		Vector2(318, 526), Vector2(354, 514), Vector2(390, 500), Vector2(428, 484),
		Vector2(466, 470), Vector2(504, 453), Vector2(542, 437), Vector2(580, 420),
		Vector2(618, 404), Vector2(655, 391), Vector2(688, 380),
	]
	for stone_id in range(footpath.size()):
		var stone_position: Vector2 = footpath[stone_id]
		var variation := sin(float(stone_id) * 2.1) * 2.0
		_draw_ellipse_custom(stone_position + Vector2(0, 2), Vector2(10 + float(stone_id % 3), 5), Color(0.39, 0.35, 0.25, 0.12))
		_draw_ellipse_custom(stone_position + Vector2(0, variation), Vector2(8 + float(stone_id % 3), 4), Color(0.83, 0.75, 0.57, 0.48))
		draw_line(stone_position + Vector2(-4, -1), stone_position + Vector2(3, -2), Color(0.98, 0.92, 0.75, 0.40), 1.2, true)


func _draw_grass_cluster(center: Vector2, scale: float, phase: int) -> void:
	var ground := center + Vector2(0, 4)
	_draw_ellipse_custom(ground, Vector2(12.0 * scale, 3.5 * scale), Color(0.20, 0.40, 0.25, 0.12))
	var leaf_colors := [Color("65a768"), Color("79b875"), Color("9ac477"), Color("6ca56a")]
	for leaf_id in range(5):
		var angle := -PI * 0.86 + float(leaf_id) * PI * 0.22 + sin(animation_time * 1.1 + float(phase + leaf_id)) * 0.025
		var direction := Vector2(cos(angle), sin(angle))
		var perpendicular := direction.orthogonal()
		var base := center + Vector2(float(leaf_id - 2) * 1.2, 3.0) * scale
		var tip := base + direction * (11.0 + float((leaf_id + phase) % 3) * 2.0) * scale
		var width := (2.4 + float(leaf_id % 2) * 0.5) * scale
		var blade := PackedVector2Array([
			base - perpendicular * width,
			base + direction * 4.0 * scale,
			tip,
			base + direction * 4.0 * scale + perpendicular * width,
		])
		draw_colored_polygon(blade, leaf_colors[(leaf_id + phase) % leaf_colors.size()])
		draw_line(base, tip, Color(0.83, 0.92, 0.66, 0.40), 0.9, true)


func _draw_locked_area_preview() -> void:
	# The painted island art already previews the far garden naturally. Avoid ghost UI outlines.
	return


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
	# The environment illustration contains the water. Animated caustics give it a quiet loop.
	for glint_id in range(5):
		var glint_phase := animation_time * 1.55 + float(glint_id) * 1.31
		var glint_x := 728.0 + fposmod(animation_time * 9.0 + float(glint_id) * 31.0, 164.0)
		var glint_y := 188.0 + float(glint_id) * 82.0 + sin(glint_phase) * 4.0
		var glint_color := Color(0.91, 0.99, 0.93, 0.32 + (sin(glint_phase) + 1.0) * 0.10)
		draw_line(Vector2(glint_x, glint_y), Vector2(glint_x + 9.0, glint_y - 1.0), glint_color, 1.7, true)


func _main_story_progress() -> int:
	if not game_state.is_complete():
		return 0
	if not game_state.seed_collected:
		return 1
	if not game_state.seed_planted:
		return 2
	if not game_state.is_q004_complete():
		return 3
	if not game_state.is_pond_complete():
		return 4
	if not game_state.is_q005_complete():
		return 5
	if not game_state.is_q006_complete():
		return 6
	return 7 if game_state.is_q012_complete() else 6


func _draw_bridge(font: Font) -> void:
	# Painterly timber art carries the bridge; the three transparent deck gaps
	# in the texture line up with the interactive repair slots below.
	var bridge_draw_size := Vector2(164, 105)
	draw_set_transform(_world_to_screen(BRIDGE_RECT.get_center()), 0.24, Vector2.ONE * _camera_zoom_scale())
	draw_texture_rect(BRIDGE_ART, Rect2(-bridge_draw_size * 0.5, bridge_draw_size), false)
	_restore_world_draw_transform()

	for slot_id in range(BRIDGE_SLOTS.size()):
		var slot: Rect2 = BRIDGE_SLOTS[slot_id]
		var installed: bool = game_state.placed[slot_id] or game_state.bridge_repaired
		var plank_points := PackedVector2Array([
			Vector2(-slot.size.x * 0.5 + 1, -slot.size.y * 0.5 + 2),
			Vector2(slot.size.x * 0.5 - 2, -slot.size.y * 0.5),
			Vector2(slot.size.x * 0.5, slot.size.y * 0.5 - 2),
			Vector2(-slot.size.x * 0.5, slot.size.y * 0.5),
		])
		draw_set_transform(_world_to_screen(slot.get_center()), 0.24, Vector2.ONE * _camera_zoom_scale())
		if installed:
			draw_colored_polygon(plank_points, Color("d6a76c"))
			draw_polyline(plank_points, Color("76533d"), 2.0, true)
			draw_line(Vector2(-slot.size.x * 0.5 + 3, -slot.size.y * 0.5 + 4), Vector2(slot.size.x * 0.5 - 3, -slot.size.y * 0.5 + 4), Color("f1d49d", 0.86), 1.2, true)
			draw_line(Vector2(-slot.size.x * 0.5 + 5, 0), Vector2(slot.size.x * 0.5 - 5, 0), Color("a5794d", 0.72), 1.0, true)
		else:
			# Empty joints glow softly; water remains visible through each gap.
			var target_color: Color = VISUAL_PALETTE["target_valid"] if _drag_target_slot_at(drag_position) == slot_id else Color("f6dfaa", 0.85)
			var target_fill: Color = VISUAL_PALETTE["target_valid_fill"] if _drag_target_slot_at(drag_position) == slot_id else Color("f7e7c2", 0.18)
			draw_colored_polygon(plank_points, target_fill)
			draw_polyline(plank_points, target_color, 1.5, true)
		_restore_world_draw_transform()
		if dragging_board >= 0 and slot_id == dragging_board and game_state.can_place_board(dragging_board):
			var target_color: Color = VISUAL_PALETTE["target_valid"] if _drag_target_slot_at(drag_position) == slot_id else VISUAL_PALETTE["target_idle"]
			var target_fill: Color = VISUAL_PALETTE["target_valid_fill"] if _drag_target_slot_at(drag_position) == slot_id else VISUAL_PALETTE["target_idle_fill"]
			draw_rect(_slot_drop_rect(slot_id), target_fill, true)
			draw_rect(_slot_drop_rect(slot_id), target_color, false, 4.0)
	if dragging_board >= 0:
		var drag_hint := "绿色高亮位置可以松开" if _drag_target_slot_at(drag_position) >= 0 else "把木板移到高亮位置再松开"
		draw_string(font, Vector2(700, 465), drag_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, VISUAL_PALETTE["ink"])
	if game_state.bridge_repaired:
		if bridge_repair_remaining > 0.0:
			var repair_progress := 1.0 - bridge_repair_remaining / BRIDGE_REPAIR_DURATION
			var shimmer_x := lerpf(770.0, 870.0, repair_progress)
			var shimmer_alpha := 1.0 - repair_progress
			_draw_ellipse_custom(Vector2(shimmer_x, 377), Vector2(18, 34), Color(1.0, 0.91, 0.57, shimmer_alpha * 0.5))
			draw_line(Vector2(shimmer_x, 345), Vector2(shimmer_x, 408), Color(1.0, 0.98, 0.78, shimmer_alpha), 4.0)
		_draw_bridge_status(font, _bridge_status_text())
	else:
		# The small snapped cord makes the repair state legible without a crude X.
		draw_line(Vector2(810, 344), Vector2(818, 352), Color("805b3e"), 2.0, true)
		draw_line(Vector2(818, 352), Vector2(824, 344), Color("805b3e"), 2.0, true)
		_draw_bridge_status(font, "待修复")


func _draw_bridge_status(font: Font, label: String) -> void:
	var rect := Rect2(752, 304, 136, 27)
	_draw_soft_panel(rect, Color("fff7e5", 0.96), Color("d8bd83"), 13, 0.10)
	draw_string(font, rect.position + Vector2(8, 19), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16, 14, Color("536c4c"))


func _draw_rabbit_area(font: Font) -> void:
	if not _should_show_rabbit_area():
		return
	if _should_show_rabbit_dialog():
		var bubble_fill := Color("fff7dc")
		_draw_soft_panel(Rect2(392, 133, 400, 48), bubble_fill, Color("d7a85b"), 16, 0.10)
		draw_colored_polygon(PackedVector2Array([Vector2(582, 181), Vector2(600, 181), Vector2(592, 197)]), bubble_fill)
		draw_circle(Vector2(414, 157), 12.0, Color("e8bd62"))
		draw_string(font, Vector2(436, 163), _rabbit_feedback_text(), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, VISUAL_PALETTE["ink"])
	if game_state.can_start_q012():
		var pulse := 0.5 + sin(animation_time * 3.0) * 0.5
		draw_arc(Q012_RABBIT_POSITION, 75.0 + pulse * 5.0, 0.0, TAU, 48, Color(1.0, 0.88, 0.48, 0.58), 4.0)
		var finale_tag := Rect2(Q012_RABBIT_POSITION + Vector2(-82, -107), Vector2(164, 30))
		_draw_panel(finale_tag, Color("fff5d9"), Color("d5a45f"), 12)
		draw_string(font, finale_tag.position + Vector2(10, 20), "主线最后一步 · 庆祝", HORIZONTAL_ALIGNMENT_CENTER, finale_tag.size.x - 20, 14, VISUAL_PALETTE["ink"])
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
	var sign_rect := Rect2(952, 169, 246, 78)
	_draw_soft_panel(sign_rect, Color("fff5db"), Color("d5b46f"), 18, 0.12)
	draw_circle(Vector2(977, 194), 15.0, Color("e7c77d"))
	draw_circle(Vector2(977, 194), 9.0, Color("f9e9bd"))
	draw_arc(Vector2(977, 194), 5.0, PI, TAU, 12, Color("836a42"), 2.0)
	draw_rect(Rect2(972, 194, 10, 8), Color("836a42"), true)
	draw_string(font, Vector2(1002, 194), "桥那边的新天地", HORIZONTAL_ALIGNMENT_LEFT, 184, 17, VISUAL_PALETTE["ink"])
	draw_string(font, Vector2(1002, 222), "修好小桥，就能去探险", HORIZONTAL_ALIGNMENT_LEFT, 184, 13, Color("607561"))


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
		if player_position.distance_to(POND_RECT.get_center()) <= POND_INTERACTION_RADIUS:
			draw_string(font, POND_RECT.position + Vector2(28, 144), "点互动看水纹", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("f4fff0"))
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
	for plant_id in range(GameState.Q005_PLANT_TOTAL):
		var plant_position: Vector2 = Q005_PLANT_POSITIONS[plant_id]
		var plant_scale := 1.0
		if game_state.q005_watered and not game_state.q005_plants_collected[plant_id] and q005_growth_remaining > 0.0:
			var growth_progress := clampf(1.0 - q005_growth_remaining / Q005_GROWTH_DURATION, 0.0, 1.0)
			var eased_growth := growth_progress * growth_progress * (3.0 - 2.0 * growth_progress)
			plant_scale = lerpf(0.35, 1.0, eased_growth)
			plant_position.y -= eased_growth * 9.0
		var harvested: bool = game_state.q005_plants_collected[plant_id]
		_draw_ellipse_custom(Q005_PLANT_POSITIONS[plant_id] + Vector2(0, 14), Vector2(21, 6), Color(0.20, 0.39, 0.19, 0.18))
		_draw_q005_plant_at(plant_position, harvested, game_state.is_q010_complete(), not game_state.q005_watered and not harvested, plant_scale)
		if not game_state.is_q005_complete():
			var plant_label := "已采" if harvested else ("待浇水" if not game_state.q005_watered else "待采收")
			draw_string(font, Q005_PLANT_POSITIONS[plant_id] + Vector2(-23, 31), plant_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, VISUAL_PALETTE["ink"])

	if not game_state.is_q005_complete():
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
	if game_state.q005_plant_count() == GameState.Q005_PLANT_TOTAL and not game_state.q005_harvest_delivered:
		var callout := Rect2(Q005_TURTLE_POSITION + Vector2(-88, -80), Vector2(176, 34))
		_draw_panel(callout, Color("fff5d9"), Color("d5a45f"), 12)
		draw_string(font, callout.position + Vector2(12, 22), "花束交给乌龟 →", HORIZONTAL_ALIGNMENT_CENTER, callout.size.x - 24, 15, VISUAL_PALETTE["ink"])


func _draw_q006_area(font: Font) -> void:
	if not _can_use_q006_build_mode():
		return
	var placed_count: int = game_state.q006_placed_count()
	if not build_mode and placed_count == 0:
		return
	if build_mode:
		var placement_outline := PackedVector2Array(Q006_DECOR_ISLAND_POLYGON)
		placement_outline.append(placement_outline[0])
		draw_polyline(placement_outline, Color("d5efb0"), 3.0, true)
		draw_string(font, Vector2(944, 171), "右侧草地可自由摆放", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, VISUAL_PALETTE["ink"])
	for decor_id in range(GameState.Q006_DECOR_TOTAL):
		if not game_state.q006_decor_placed[decor_id] or dragging_q006_decor == decor_id:
			continue
		_draw_q006_decor_at(game_state.q006_decor_positions[decor_id], decor_id, false)
	if dragging_q006_decor >= 0:
		var valid_drop := _q006_decor_drop_is_valid(dragging_q006_decor, q006_decor_drag_position)
		var target_color := Color("64d887") if valid_drop else Color("e8a65e")
		draw_circle(q006_decor_drag_position, 31.0, Color(target_color.r, target_color.g, target_color.b, 0.20))
		draw_arc(q006_decor_drag_position, 31.0, 0.0, TAU, 32, target_color, 3.0)


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
		if game_state.q009_material_count() == GameState.Q009_MATERIAL_TOTAL:
			_draw_q009_birdhouse_frame(Q009_BIRDHOUSE_POSITION, game_state.q009_material_delivery_count())
			draw_string(font, Q009_BIRDHOUSE_POSITION + Vector2(-46, 68), "鸟屋施工 %d/3" % game_state.q009_material_delivery_count(), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, VISUAL_PALETTE["ink"])
	else:
		_draw_q009_birdhouse(Q009_BIRDHOUSE_POSITION)
		_draw_q009_bird(Q009_BIRD_POSITION)
		draw_string(font, Q009_BIRDHOUSE_POSITION + Vector2(-26, 62), "鸟屋", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, VISUAL_PALETTE["ink"])
		draw_string(font, Q009_BIRD_POSITION + Vector2(-44, -30), "小鸟：欢迎！", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("fff1a8"))


func _q009_prompt_text() -> String:
	if game_state.is_q009_complete():
		return "鸟屋计划完成！小鸟互动已开放。"
	if game_state.q009_material_count() == GameState.Q009_MATERIAL_TOTAL:
		return "材料已收集 3/3，鸟屋交付 %d/3。" % game_state.q009_material_delivery_count()
	return "鸟屋计划：已收集 %d/3 份材料。" % game_state.q009_material_count()


func _q009_action_hint_text() -> String:
	if game_state.is_q009_complete():
		return "可选：靠近小鸟按互动键打招呼。"
	if game_state.q009_material_count() == GameState.Q009_MATERIAL_TOTAL:
		return "到鸟屋旁点互动，逐份交材料并看着它搭起来。"
	return "找到树枝、羽毛和草绳，靠近后按互动键收集。"


func _draw_q009_birdhouse_frame(position: Vector2, delivered_count: int) -> void:
	var base := Color("bd9562")
	var accent := Color("d5a468")
	_draw_ellipse_custom(position + Vector2(0, 34), Vector2(38, 8), Color(0.19, 0.13, 0.10, 0.16))
	draw_line(position + Vector2(-30, 18), position + Vector2(30, 18), base, 6.0)
	if delivered_count >= 1:
		draw_line(position + Vector2(-26, 14), position + Vector2(-26, -18), accent, 5.0)
		draw_line(position + Vector2(26, 14), position + Vector2(26, -18), accent, 5.0)
	if delivered_count >= 2:
		draw_line(position + Vector2(-31, -16), position + Vector2(0, -43), Color("d96f58"), 6.0)
		draw_line(position + Vector2(0, -43), position + Vector2(31, -16), Color("d96f58"), 6.0)
	if delivered_count >= 3:
		draw_line(position + Vector2(-29, -14), position + Vector2(29, -14), accent, 5.0)
		draw_line(position + Vector2(-28, 13), position + Vector2(28, 13), accent, 5.0)
	for material_id in range(GameState.Q009_MATERIAL_TOTAL):
		var dot_color := Color("90ca75") if material_id < delivered_count else Color("e4d2ad")
		draw_circle(position + Vector2(-18 + material_id * 18, 31), 4.0, dot_color)


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
	if not _should_show_q011_area_contents():
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
	_draw_character_sprite(BIRD_ART, position, 58.0, 0.38, 1.4, 1.1)

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
	_draw_character_sprite(TURTLE_ART, position, 87.0, 0.39, 2.1, 1.0)

func _draw_wood_at(position: Vector2) -> void:
	_draw_grass_cluster(position + Vector2(-34, 15), 0.42, 2)
	_draw_grass_cluster(position + Vector2(34, 15), 0.36, 4)
	_draw_ellipse_custom(position + Vector2(2, 18), Vector2(32, 8), Color(0.16, 0.22, 0.13, 0.16))
	_draw_ellipse_custom(position + Vector2(0, 15), Vector2(25, 4), Color(0.28, 0.20, 0.13, 0.18))
	draw_texture_rect(CRATE_ART, Rect2(position - Vector2(36, 27), Vector2(72, 54)), false)


func _draw_fox(position: Vector2) -> void:
	_draw_character_sprite(FOX_ART, position, 78.0, 0.40, 0.8, 1.5)

func _draw_boards(font: Font) -> void:
	for board_id in range(GameState.BOARD_TOTAL):
		if not game_state.collected[board_id]:
			_draw_board_at(BOARD_POSITIONS[board_id], VISUAL_PALETTE["board"], false)
			draw_string(font, BOARD_POSITIONS[board_id] + Vector2(-24, 43), "木板", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, VISUAL_PALETTE["ink"])


func _draw_player() -> void:
	var foot_anchor := player_position + Vector2(0.0, 36.0)
	var stride := sin(player_walk_phase) if player_is_moving else 0.0
	var foot_lift := absf(stride)
	var planted := 1.0 - foot_lift
	var shadow_alpha := 0.22 + planted * 0.14
	_draw_ellipse_custom(foot_anchor + Vector2(2, 3), Vector2(21.0 - foot_lift * 4.0, 5.8 - foot_lift), Color(0.19, 0.15, 0.11, shadow_alpha))
	_draw_ellipse_custom(foot_anchor + Vector2(0, 2), Vector2(14.0 - foot_lift * 2.5, 3.6 - foot_lift * 0.6), Color(0.28, 0.34, 0.19, 0.14 + planted * 0.07))
	if player_is_moving:
		var left_step := stride
		var right_step := sin(player_walk_phase + PI)
		var left_lift := maxf(left_step, 0.0) * 3.0
		var right_lift := maxf(right_step, 0.0) * 3.0
		var print_alpha := 0.12 + planted * 0.10
		_draw_ellipse_custom(foot_anchor + Vector2(-7.0 + left_step * 4.0, -left_lift), Vector2(3.6, 2.0), Color(0.46, 0.31, 0.22, print_alpha))
		_draw_ellipse_custom(foot_anchor + Vector2(7.0 + right_step * 4.0, -right_lift), Vector2(3.6, 2.0), Color(0.46, 0.31, 0.22, print_alpha))
	var bob := absf(stride) * 6.0 if player_is_moving else 0.0
	var breath := 1.0 + sin(animation_time * 2.2) * 0.003
	var stride_squash := absf(stride) * 0.06 if player_is_moving else 0.0
	var sprite_height := 68.0 * breath * (1.0 - stride_squash)
	var sprite_width := sprite_height * MOUSE_ART.get_width() / MOUSE_ART.get_height()
	var lean := player_facing.x * 0.04 + stride * 0.16 if player_is_moving else sin(animation_time * 1.15) * 0.004
	var width_scale := 1.0 + (sin(player_walk_phase) * 0.07 if player_is_moving else 0.0)
	var facing_scale := -1.0 if player_facing.x < -0.1 else 1.0
	var body_sway := sin(player_walk_phase) * 1.4 if player_is_moving else 0.0
	draw_set_transform(_world_to_screen(player_position + Vector2(body_sway, -bob)), lean, Vector2(width_scale * facing_scale * _camera_zoom_scale(), _camera_zoom_scale()))
	draw_texture_rect(MOUSE_ART, Rect2(Vector2(-sprite_width * 0.5, -sprite_height * 0.42), Vector2(sprite_width, sprite_height)), false)
	_restore_world_draw_transform()


func _draw_character_sprite(texture: Texture2D, anchor: Vector2, height: float, face_ratio: float, phase: float, bob_amount: float) -> void:
	var breath := 1.0 + sin(animation_time * 2.2 + phase) * 0.004
	var walk_sway := sin(player_walk_phase) * 0.018 if phase == 0.0 and player_is_moving else 0.0
	var sway := sin(animation_time * 1.15 + phase) * 0.004 + walk_sway
	var sprite_height := height * breath
	var sprite_width := sprite_height * texture.get_width() / texture.get_height()
	var bob := _character_bob(phase, bob_amount * 0.35)
	var foot_y := anchor.y + height * (1.0 - face_ratio) - 2.0
	_draw_ellipse_custom(Vector2(anchor.x + 2.0, foot_y + 2.5), Vector2(height * 0.31, maxf(4.0, height * 0.055)), Color(0.16, 0.20, 0.13, 0.20))
	_draw_ellipse_custom(Vector2(anchor.x, foot_y + 1.5), Vector2(height * 0.23, maxf(2.5, height * 0.032)), Color(0.28, 0.34, 0.19, 0.12))
	draw_set_transform(_world_to_screen(anchor + Vector2(0, bob)), sway, Vector2(breath * _camera_zoom_scale(), breath * _camera_zoom_scale()))
	draw_texture_rect(texture, Rect2(Vector2(-sprite_width * 0.5, -sprite_height * face_ratio), Vector2(sprite_width, sprite_height)), false)
	_restore_world_draw_transform()

func _draw_panel(rect: Rect2, fill: Color, border: Color, radius: int) -> void:
	var cache_key := "%s|%s|%d" % [str(fill), str(border), radius]
	var style := panel_style_cache.get(cache_key) as StyleBoxFlat
	if style == null:
		style = StyleBoxFlat.new()
		style.bg_color = fill
		style.border_color = border
		style.set_border_width_all(2)
		style.set_corner_radius_all(radius)
		style.anti_aliasing = true
		panel_style_cache[cache_key] = style
	draw_style_box(style, rect)


func _draw_soft_panel(rect: Rect2, fill: Color, border: Color, radius: int, shadow_alpha := 0.18) -> void:
	var cache_key := "%s|%s|%d|%s" % [str(fill), str(border), radius, str(shadow_alpha)]
	var styles: Array = soft_panel_style_cache.get(cache_key, [])
	if styles.is_empty():
		var shadow := StyleBoxFlat.new()
		shadow.bg_color = fill
		shadow.set_corner_radius_all(radius)
		shadow.shadow_color = Color(0.08, 0.18, 0.16, shadow_alpha)
		shadow.shadow_size = 9
		shadow.shadow_offset = Vector2(0, 4)
		shadow.anti_aliasing = true
		var face := StyleBoxFlat.new()
		face.bg_color = fill
		face.border_color = border
		face.set_border_width_all(1)
		face.set_corner_radius_all(radius)
		face.anti_aliasing = true
		styles = [shadow, face]
		soft_panel_style_cache[cache_key] = styles
	draw_style_box(styles[0], rect)
	draw_style_box(styles[1], rect)
	var highlight := Color(1.0, 1.0, 0.91, 0.16)
	draw_line(rect.position + Vector2(radius, 2), rect.position + Vector2(rect.size.x - radius, 2), highlight, 1.0, true)


func _draw_rabbit(position: Vector2) -> void:
	_draw_character_sprite(RABBIT_ART, position, 92.0, 0.46, 2.1, 1.4)


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
	if lifted or color == VISUAL_PALETTE["board"]:
		# Keep the contact shadow attached to the ground even while the plank is
		# lifted by the drag animation. Grass tucks its edges into the landscape.
		_draw_grass_cluster(position + Vector2(-38, 18), 0.34, 1)
		_draw_grass_cluster(position + Vector2(38, 18), 0.32, 3)
		_draw_ellipse_custom(position + Vector2(2, 19), Vector2(34, 7), Color(0.16, 0.22, 0.13, 0.17))
		_draw_ellipse_custom(position + Vector2(1, 15), Vector2(25, 3.5), Color(0.25, 0.18, 0.12, 0.20))
		if lifted:
			draw_rect(rect.grow(16), VISUAL_PALETTE["target_idle"], false, 3.0)
		var plank_position := position - Vector2(0, 11) if lifted else position
		draw_texture_rect(PLANK_ART, Rect2(plank_position - Vector2(40, 27), Vector2(80, 54)), false)
		return
	var side_face := PackedVector2Array([
		rect.position + Vector2(1, rect.size.y - 7), rect.position + Vector2(rect.size.x - 1, rect.size.y - 9),
		rect.position + Vector2(rect.size.x, rect.size.y - 1), rect.position + Vector2(2, rect.size.y),
	])
	draw_colored_polygon(side_face, Color("82583b"))
	var top_face := PackedVector2Array([
		rect.position + Vector2(1, 1), rect.position + Vector2(rect.size.x - 4, 0),
		rect.position + Vector2(rect.size.x - 1, rect.size.y - 9), rect.position + Vector2(2, rect.size.y - 7),
	])
	draw_colored_polygon(top_face, color)
	var outline := PackedVector2Array(top_face)
	outline.append(top_face[0])
	draw_polyline(outline, VISUAL_PALETTE["board_outline"], 2.5, true)
	draw_line(rect.position + Vector2(10, 5), rect.position + Vector2(10, rect.size.y - 9), Color("956744"), 2.0, true)
	draw_line(rect.position + Vector2(24, 4), rect.position + Vector2(24, rect.size.y - 10), Color("956744"), 2.0, true)
	draw_line(rect.position + Vector2(5, 5), rect.position + Vector2(rect.size.x - 8, 4), Color("f2d096", 0.80), 1.5, true)


func _draw_pond_stone_at(position: Vector2, color: Color, lifted: bool) -> void:
	var stone_position := position - Vector2(0, 8) if lifted else position
	_draw_ellipse_custom(stone_position + Vector2(0, 14), Vector2(24, 8), Color(0.19, 0.13, 0.10, 0.16))
	_draw_ellipse_custom(stone_position, Vector2(20, 14), color)
	draw_arc(stone_position, 18.0, 0.0, TAU, 20, Color("596a69"), 3.0)
	draw_line(stone_position + Vector2(-8, -3), stone_position + Vector2(7, -7), Color("b9c3ba"), 2.0)
	if lifted:
		draw_arc(stone_position, 25.0, 0.0, TAU, 24, VISUAL_PALETTE["target_idle"], 3.0)


func _draw_hud(font: Font) -> void:
	var panel_width := minf(580.0, maxf(350.0, size.x - 250.0))
	var hud_rect := Rect2(18, 14, panel_width, 84)
	_draw_soft_panel(hud_rect, Color("fff9ed", 0.91), Color("d5bd83", 0.92), 20, 0.15)
	draw_rect(Rect2(hud_rect.position, Vector2(4, hud_rect.size.y)), Color("668e59"), true)
	var emblem_center := Vector2(48, 43)
	draw_circle(emblem_center + Vector2(0, 2), 16.0, Color(0.28, 0.35, 0.23, 0.13))
	draw_circle(emblem_center, 14.0, Color("ecd18e"))
	draw_circle(emblem_center, 10.0, Color("fff1c9"))
	_draw_ellipse_custom(emblem_center + Vector2(-3, 1), Vector2(2.8, 5.4), Color("6d9c62"))
	_draw_ellipse_custom(emblem_center + Vector2(3, -1), Vector2(2.8, 5.4), Color("91b875"))
	draw_circle(emblem_center, 1.8, Color("fffaf0"))
	draw_arc(emblem_center, 17.0, -2.55, -0.65, 12, Color("fffaf0", 0.78), 1.3)
	var title := _hud_title_text().replace("奇趣小岛 · ", "")
	draw_string(font, Vector2(72, 48), title, HORIZONTAL_ALIGNMENT_LEFT, panel_width - 224.0, 22, VISUAL_PALETTE["ink"])
	var badge_fill := Color("e8efd5") if not game_state.can_start_q012() else Color("f7e5b4")
	var badge_border := Color("a8bd85") if not game_state.can_start_q012() else Color("d6aa5d")
	var badge_rect := Rect2(hud_rect.end.x - 132.0, 25, 112, 27)
	_draw_soft_panel(badge_rect, badge_fill, badge_border, 13, 0.07)
	draw_string(font, badge_rect.position + Vector2(8, 19), _task_stage_label(), HORIZONTAL_ALIGNMENT_CENTER, badge_rect.size.x - 16, 13, Color("425d48"))
	draw_string(font, Vector2(72, 70), _hud_summary_text(), HORIZONTAL_ALIGNMENT_LEFT, panel_width - 94.0, 14, Color("506858"))
	var progress_count := _main_story_progress()
	var progress_x := 72.0
	var progress_y := 86.0
	var available_progress_width := panel_width - 94.0
	var segment_gap := 5.0
	var segment_width := (available_progress_width - segment_gap * 6.0) / 7.0
	for step_id in range(7):
		var x0 := progress_x + float(step_id) * (segment_width + segment_gap)
		var segment_color := Color("6c9b66") if step_id < progress_count else Color("dce2cc")
		if step_id == progress_count and progress_count < 7:
			segment_color = Color("dbb66e")
		draw_line(Vector2(x0, progress_y), Vector2(x0 + segment_width, progress_y), segment_color, 3.0, true)
	var show_inventory: bool = q011_mode or build_mode or game_state.can_start_q004() or not game_state.is_complete() or (_can_use_q008_side_task() and not game_state.is_q008_complete())
	if not show_inventory:
		return
	_draw_soft_panel(INVENTORY_PANEL_RECT, Color("f7edd8", 0.97), Color("ad8a5f"), 18, 0.15)
	draw_rect(INVENTORY_PANEL_RECT.grow(-5.0), Color("fffaf0", 0.18), false, 1.0, true)
	draw_rect(Rect2(INVENTORY_PANEL_RECT.position + Vector2(14, 16), Vector2(3, 20)), Color("6c9a65"), true)
	if q011_mode:
		_draw_q011_inventory(font)
	elif build_mode:
		_draw_q006_inventory(font)
	elif game_state.can_start_q004():
		_draw_q004_inventory(font)
	elif _can_use_q008_side_task() and not game_state.is_q008_complete():
		_draw_q008_inventory(font)
	else:
		draw_string(font, Vector2(928, 602), "小桥修缮 · 木板", HORIZONTAL_ALIGNMENT_LEFT, 158, 16, Color("425d48"))
		var board_count_label := "%d/3" % game_state.board_count()
		draw_string(font, Vector2(1082, 602), board_count_label, HORIZONTAL_ALIGNMENT_RIGHT, 48, 14, Color("8a714c"))
		for board_id in range(GameState.BOARD_TOTAL):
			var rect := _inventory_rect(board_id)
			if game_state.collected[board_id] and not game_state.placed[board_id] and dragging_board != board_id:
				_draw_board_at(rect.position + rect.size / 2.0, VISUAL_PALETTE["board_collected"], false)
			else:
				_draw_slot_card(rect)
			if game_state.placed[board_id]:
				_draw_check_badge(rect.get_center())


func _draw_q004_inventory(font: Font) -> void:
	draw_string(font, Vector2(928, 602), "木材（带到小屋交付）", HORIZONTAL_ALIGNMENT_LEFT, 230, 16, Color("425d48"))
	for wood_id in range(GameState.Q004_WOOD_TOTAL):
		var rect := _inventory_rect(wood_id)
		if game_state.wood_collected[wood_id] and not game_state.wood_delivered[wood_id]:
			_draw_wood_at(rect.position + rect.size / 2.0)
		else:
			_draw_slot_card(rect)
		if game_state.wood_delivered[wood_id]:
			_draw_check_badge(rect.get_center())


func _draw_q008_inventory(font: Font) -> void:
	draw_string(font, Vector2(928, 602), "石板（拖到左侧小路）", HORIZONTAL_ALIGNMENT_LEFT, 230, 16, Color("425d48"))
	for material_id in range(GameState.Q008_PATH_SLOT_TOTAL):
		var rect := _q008_path_material_rect(material_id)
		if game_state.q008_path_material_is_available(material_id) and dragging_q008_path != material_id:
			_draw_q008_path_paver_at(rect.position + rect.size / 2.0, material_id, false)
		else:
			_draw_slot_card(rect)
		if not game_state.q008_path_material_is_available(material_id):
			_draw_check_badge(rect.get_center())


func _draw_q011_inventory(font: Font) -> void:
	var title := "整理托盘（拖到左侧任意空位）"
	draw_string(font, Vector2(928, 602), title, HORIZONTAL_ALIGNMENT_LEFT, 230, 16, Color("425d48"))
	for item_id in range(GameState.Q011_ITEM_TOTAL):
		var rect := _q011_item_inventory_rect(item_id)
		if game_state.q011_item_is_available(item_id) and dragging_q011_item != item_id:
			_draw_q011_item_at(rect.position + rect.size / 2.0, item_id, false)
		else:
			_draw_slot_card(rect)
		if not game_state.q011_item_is_available(item_id):
			_draw_check_badge(rect.get_center())


func _draw_q006_inventory(font: Font) -> void:
	draw_string(font, Vector2(928, 602), "装饰（拖到右侧草地）", HORIZONTAL_ALIGNMENT_LEFT, 230, 16, Color("425d48"))
	for decor_id in range(GameState.Q006_DECOR_TOTAL):
		var rect := _q006_decor_inventory_rect(decor_id)
		if game_state.q006_decor_is_available(decor_id) and dragging_q006_decor != decor_id:
			_draw_q006_decor_at(rect.position + rect.size / 2.0, decor_id, false)
		else:
			_draw_slot_card(rect)
		if not game_state.q006_decor_is_available(decor_id):
			_draw_check_badge(rect.get_center())
	if game_state.q006_windmill_unlocked:
		draw_string(font, Vector2(914, 678), "小风车已解锁（保留在库存）", HORIZONTAL_ALIGNMENT_LEFT, 230, 14, Color("9b7542"))
	else:
		draw_string(font, Vector2(914, 678), "放满三件装饰后解锁小风车", HORIZONTAL_ALIGNMENT_LEFT, 230, 14, Color("788970"))


func _draw_slot_card(rect: Rect2) -> void:
	if slot_card_style == null:
		slot_card_style = StyleBoxFlat.new()
		slot_card_style.bg_color = Color("f6f1df")
		slot_card_style.border_color = Color("b8c69d")
		slot_card_style.set_border_width_all(1)
		slot_card_style.set_corner_radius_all(10)
		slot_card_style.shadow_color = Color(0.23, 0.27, 0.18, 0.12)
		slot_card_style.shadow_size = 2
		slot_card_style.shadow_offset = Vector2(0, 1)
		slot_card_style.anti_aliasing = true
	draw_style_box(slot_card_style, rect)
	draw_line(rect.position + Vector2(9, 2), rect.position + Vector2(rect.size.x - 9, 2), Color(1.0, 1.0, 0.91, 0.70), 1.0, true)


func _draw_check_badge(center: Vector2) -> void:
	# An inset check keeps the completion mark inside each tray slot without
	# adding a badge that spills past the item silhouette.
	draw_line(center + Vector2(-5, 1), center + Vector2(-1, 5), Color("3f8153"), 2.7, true)
	draw_line(center + Vector2(-1, 5), center + Vector2(6, -5), Color("3f8153"), 2.7, true)


func _draw_touch_hint(font: Font) -> void:
	var visible_height := size.y
	var hint_y := minf(644.0, maxf(8.0, visible_height - 76.0))
	var joystick_center := _virtual_joystick_center()
	_draw_soft_panel(Rect2(160, hint_y, 720, 50), Color("fff8e8"), Color("bfca99"), 18, 0.16)
	draw_circle(Vector2(185, hint_y + 25), 11.0, Color("e8cc88"))
	draw_circle(Vector2(185, hint_y + 25), 5.0, Color("fff4d3"))
	draw_string(font, Vector2(207, hint_y + 31.0), "接下来", HORIZONTAL_ALIGNMENT_LEFT, 64, 13, Color("718065"))
	draw_line(Vector2(277, hint_y + 12), Vector2(277, hint_y + 38), Color("d6d9bf"), 1.0, true)
	draw_string(font, Vector2(295, hint_y + 31.0), _task_action_hint_text(), HORIZONTAL_ALIGNMENT_LEFT, 570, 15, Color("334c3d"))
	var move_hint := Rect2(24, joystick_center.y - 82.0, 142, 26)
	_draw_panel(move_hint, Color("fff8e8", 0.92), Color("c4c998"), 12)
	draw_string(font, move_hint.position + Vector2(9, 18), "拖动圆盘移动", HORIZONTAL_ALIGNMENT_LEFT, 126, 13, Color("4e6953"))
	_draw_virtual_joystick()


func _draw_virtual_joystick() -> void:
	var joystick_center := _virtual_joystick_center()
	var base_color := Color(0.73, 0.83, 0.65, 0.88)
	var outline_color := Color("fff9e9")
	draw_circle(joystick_center + Vector2(0, 5), JOYSTICK_RADIUS + 8.0, Color(0.10, 0.23, 0.17, 0.18))
	draw_circle(joystick_center, JOYSTICK_RADIUS, base_color)
	draw_arc(joystick_center, JOYSTICK_RADIUS, 0.0, TAU, 40, outline_color, 3.0)
	draw_arc(joystick_center, JOYSTICK_RADIUS - 5.0, 0.0, TAU, 40, Color(0.38, 0.55, 0.36, 0.46), 1.5)
	draw_circle(joystick_center, 6.0, Color("e7efcf"))
	var knob_center := joystick_center + virtual_joystick_offset
	var knob_color := Color("79b974") if virtual_joystick_active else Color("fff9e9")
	draw_circle(knob_center + Vector2(0, 2), 23.0, Color(0.10, 0.23, 0.17, 0.15))
	draw_circle(knob_center, 23.0, knob_color)
	draw_arc(knob_center, 23.0, 0.0, TAU, 32, Color("789c69"), 2.5)
	draw_circle(knob_center, 6.0, Color("d8e9c1"))


func _virtual_joystick_center() -> Vector2:
	var visible_height := size.y
	return Vector2(JOYSTICK_CENTER.x, maxf(JOYSTICK_RADIUS + 12.0, minf(JOYSTICK_CENTER.y, visible_height - JOYSTICK_RADIUS - 24.0)))


func _hud_summary_text() -> String:
	if q011_mode:
		return "额外地块 · 摆放物品 %d/3" % game_state.q011_placed_count()
	if _can_use_q011_mode() and not build_mode:
		return "新地块已开放 · 点击整理开始布置"
	if game_state.can_start_q012():
		return "主线最后一步 · 找到兔子参加庆祝"
	if game_state.is_q012_complete() and celebration_remaining > 0.0:
		return "主线完成 · 和兔子一起庆祝"
	if build_mode and _can_use_q006_build_mode():
		return "花园装饰 · 已摆放 %d/3" % game_state.q006_placed_count()
	if game_state.is_q011_complete():
		return "任务全部完成 · 可以自由探索"
	if not game_state.is_complete():
		if game_state.board_count() < GameState.BOARD_TOTAL:
			return "修桥任务 · 收集木板 %d/3" % game_state.board_count()
		return "修桥任务 · 安装木板 %d/3" % game_state.placed_count()
	if not game_state.seed_collected:
		return "继续探索 · 过桥寻找发光种子"
	if not game_state.seed_planted:
		return "种下种子 · 前往右侧花圃"
	if not game_state.is_q004_complete():
		return "狐狸小屋 · 交付木材 %d/3" % game_state.delivered_wood_count()
	if not game_state.is_pond_complete():
		return "恢复池塘 · 已放置石头 %d/3" % game_state.pond_stones_placed.count(true)
	if not game_state.is_q005_complete():
		if not game_state.q005_watered:
			return "乌龟花园 · 先给花苗浇水"
		return "乌龟花园 · 收集花朵 %d/3" % game_state.q005_plant_count()
	if not game_state.is_q006_complete():
		return "花园装饰 · 已摆放 %d/3" % game_state.q006_placed_count()
	if not game_state.is_q007_complete():
		return "可选探索 · 池塘边藏着一枚贝壳"
	if not game_state.is_q009_complete():
		return "可选计划 · 帮小鸟收集建屋材料"
	if not game_state.is_q010_complete():
		return "可选收藏 · 寻找三种花朵种子"
	if not game_state.is_q008_complete():
		return "可选修整 · 把石板铺成一条小路"
	if not game_state.is_q011_complete():
		return "可选整理 · 布置额外地块"
	return "小岛任务完成 · 继续自由探索"


func _task_prompt_text() -> String:
	if q011_mode:
		return "额外地块整理：已放置 %d/3 件物品。" % game_state.q011_placed_count()
	if _can_use_q011_mode() and not build_mode:
		return "额外地块整理：先点右上角“开始整理”，再放置 3 件物品（%d/3）。" % game_state.q011_placed_count()
	if game_state.can_start_q012():
		return "最后一步：走到兔子身边，点右下角“庆祝”。"
	if game_state.is_q012_complete() and celebration_remaining > 0.0:
		return "主线故事完成！和兔子一起庆祝吧。"
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
		if game_state.q005_harvest_delivered:
			return "乌龟收到花束了！"
		if collected_count == GameState.Q005_PLANT_TOTAL:
			return "花束已采齐，回到乌龟身边交给它。"
		if not game_state.q005_watered:
			return "乌龟花园：先浇水，再采收 3 朵花（%d/3）。" % collected_count
		return "花苗长好了：采收 3 朵花（%d/3）。" % collected_count
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
	if game_state.is_q012_complete() and celebration_remaining > 0.0:
		return "庆祝中"
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
		return "先点右上角绿色“开始整理”；点下后物品托盘才会出现。"
	if game_state.can_start_q012():
		return "找到头顶有庆祝标记的兔子，靠近后点右下角“庆祝”；这是主线最后一步。"
	if game_state.is_q012_complete() and celebration_remaining > 0.0:
		return "小岛庆典开始了！稍后可以选择池塘边的可选任务。"
	if build_mode and _can_use_q006_build_mode():
		if remove_decor_mode:
			return "点击已放置的装饰移除；再次点击移除按钮可取消。"
		if game_state.is_q006_complete():
			return "在右侧草地拖动装饰即可自由调整位置；点“移除装饰”可收回托盘。"
		return "拖动木栅栏、花盆和路灯，在右侧草地任意空地摆放。"
	if game_state.is_q011_complete():
		return "没有必做任务：自由探索，或点右上角“建造”调整花园。"
	if not game_state.is_complete():
		if game_state.board_count() < GameState.BOARD_TOTAL:
			return "靠近木板，按 E、点右下角按钮，或直接点击木板。"
		return "拖动右下角已收集木板到桥上高亮位置。"
	if not game_state.seed_collected:
		return "过桥到右侧靠近发光种子，按 E 或点右下角按钮。"
	if not game_state.seed_planted:
		return "走到右侧花圃旁，按 E 或点右下角按钮种下种子。"
	if not game_state.is_q004_complete():
		if game_state.wood_count() < GameState.Q004_WOOD_TOTAL:
			return "靠近木材，按 E 或点右下角按钮拾取。"
		return "带着木材走到小屋旁，按 E 或点右下角按钮交付。"
	if not game_state.is_pond_complete():
		return "下一步：把池塘边剩余的石头拖进对应轮廓。"
	if not game_state.is_q005_complete():
		if not game_state.q005_watered:
			return "先到花圃旁的浇水点，按 E 或点右下角“浇水”。"
		if game_state.q005_plant_count() < GameState.Q005_PLANT_TOTAL:
			return "逐株走近花苗，按 E 或点右下角“采花”采收 3 朵花（%d/3）；花圃会保留植株。" % game_state.q005_plant_count()
		return "三朵花已采齐：回到乌龟身边，按 E 或点“送花”交给它。"
	if not game_state.is_q006_complete():
		var remaining_decorations: int = GameState.Q006_DECOR_TOTAL - game_state.q006_placed_count()
		return "点右上角“开始布置”，再把剩余 %d 件装饰拖到右侧自由摆放区。" % remaining_decorations
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
	if game_state.is_q012_complete() and celebration_remaining > 0.0:
		return "奇趣小岛 · 主线完成庆祝中"
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
