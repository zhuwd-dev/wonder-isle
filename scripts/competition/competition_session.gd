extends Control

signal close_requested

const PlayerAnimation = preload("res://scripts/visual/player_animation.gd")
const MouseFrames: SpriteFrames = preload("res://assets/art/animation/mouse-frames.tres")
const MouseIdleFrames: SpriteFrames = preload("res://assets/art/animation/mouse-idle-frames.tres")
const MouseArt: Texture2D = preload("res://assets/art/characters/mouse.png")
const RabbitArt: Texture2D = preload("res://assets/art/characters/rabbit.png")
const FoxArt: Texture2D = preload("res://assets/art/characters/fox.png")
const HubBackground: Texture2D = preload("res://assets/art/competition/competition-hub.png")
const RaceBackground: Texture2D = preload("res://assets/art/competition/rainbow-meadow-race.png")
const MeadowLog: Texture2D = preload("res://assets/art/competition/meadow-log-obstacle.png")
const UI_FONT: Font = preload("res://assets/fonts/competition-ui-cjk.otf")
const DESIGN_SIZE := Vector2(1280.0, 720.0)
const MOVE_SPEED := 260.0
const PLAYER_FOOT := Vector2(0.0, 36.0)
const ROAD_WIDTH := 168.0
const LOG_CENTER := Vector2(890.0, 330.0)

const INK := Color("294438")
const CREAM := Color("fff7df")
const GRASS := Color("79bd72")
const GRASS_LIGHT := Color("a5d87e")
const WOOD := Color("a96d43")
const WOOD_LIGHT := Color("d9a66a")
const GOLD := Color("f4cc72")

enum Screen { HUB, RACE, FINISH }

var screen := Screen.HUB
var player_position := Vector2(640.0, 430.0)
var player_animation = PlayerAnimation.new(MouseFrames if _has_walk_frames() else MouseIdleFrames)
var touch_active := false
var touch_id := -1
var touch_origin := Vector2.ZERO
var touch_direction := Vector2.ZERO
var mouse_stick_active := false
var message := "欢迎来到欢乐竞技岛！去看看彩虹草地赛吧。"
var celebration_time := 0.0
var action_button: Button
var back_button: Button
var replay_button: Button
var return_hub_button: Button
var pressed_ui := false
var animation_clock := 0.0
var last_player_position := Vector2.ZERO
var world_width := 1280.0
var world_scale := 1.0
var world_offset := Vector2.ZERO
var test_telemetry_enabled := false
var test_telemetry_elapsed := 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_to_group("competition_session")
	test_telemetry_enabled = "--test-telemetry" in OS.get_cmdline_user_args()
	_create_buttons()
	get_viewport().size_changed.connect(_schedule_layout_controls)
	_layout_controls()

func _has_walk_frames() -> bool:
	return MouseFrames.has_animation("walk_down") and MouseFrames.get_frame_count("walk_down") >= 2

func _create_buttons() -> void:
	action_button = _make_button("去挑战", Vector2(190, 76))
	action_button.pressed.connect(_on_action_pressed)
	back_button = _make_button("回生活小岛", Vector2(170, 60))
	back_button.pressed.connect(_on_back_pressed)
	replay_button = _make_button("再玩一次", Vector2(180, 70))
	replay_button.pressed.connect(_start_race)
	return_hub_button = _make_button("返回大厅", Vector2(180, 70))
	return_hub_button.pressed.connect(_return_to_hub)
	replay_button.visible = false
	return_hub_button.visible = false

func _make_button(label: String, button_size: Vector2) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = button_size
	button.size = button_size
	button.add_theme_font_override("font", UI_FONT)
	button.add_theme_font_size_override("font_size", 21)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("f7f1dc")
	normal.border_color = Color("b9c991")
	normal.set_border_width_all(3)
	normal.set_corner_radius_all(22)
	normal.shadow_color = Color(0.11, 0.2, 0.11, 0.23)
	normal.shadow_size = 7
	normal.shadow_offset = Vector2(0, 4)
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("fff9e9")
	button.add_theme_stylebox_override("hover", hover)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("e8d9ae")
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", Color("1d392b"))
	add_child(button)
	return button

func _layout_controls() -> void:
	var view := get_viewport_rect().size
	var output_size := _physical_viewport_size()
	var ui_scale := _ui_scale_factor()
	back_button.size = Vector2(170, 60) * ui_scale
	back_button.custom_minimum_size = back_button.size
	action_button.size = Vector2(190, 76) * ui_scale
	action_button.custom_minimum_size = action_button.size
	replay_button.size = Vector2(180, 70) * ui_scale
	replay_button.custom_minimum_size = replay_button.size
	return_hub_button.size = Vector2(180, 70) * ui_scale
	return_hub_button.custom_minimum_size = return_hub_button.size
	for button in [back_button, action_button, replay_button, return_hub_button]:
		button.add_theme_font_size_override("font_size", roundi(21.0 * ui_scale))
	back_button.position = Vector2(maxf(12.0 * ui_scale, view.x - back_button.size.x - 18.0 * ui_scale), 16.0 * ui_scale)
	action_button.position = Vector2(maxf(12.0 * ui_scale, view.x - action_button.size.x - 18.0 * ui_scale), maxf(12.0 * ui_scale, view.y - action_button.size.y - 16.0 * ui_scale))
	replay_button.position = Vector2((output_size.x * 0.5 - 194.0) * ui_scale, output_size.y * 0.63 * ui_scale)
	return_hub_button.position = Vector2((output_size.x * 0.5 + 14.0) * ui_scale, output_size.y * 0.63 * ui_scale)
	_update_buttons()
	queue_redraw()

func _schedule_layout_controls() -> void:
	call_deferred("_layout_controls")

func _physical_viewport_size() -> Vector2:
	var window_size := DisplayServer.window_get_size()
	var viewport_size := get_viewport_rect().size
	if window_size.x > 0 and window_size.y > 0 and viewport_size.x > 0 and viewport_size.y > 0:
		var window_aspect := float(window_size.x) / float(window_size.y)
		var viewport_aspect := viewport_size.x / viewport_size.y
		if absf(window_aspect - viewport_aspect) <= 0.03 * viewport_aspect:
			return Vector2(window_size)
	return viewport_size

func _ui_scale_factor() -> float:
	return minf(get_viewport_rect().size.y / maxf(_physical_viewport_size().y, 1.0), 3.0)

func _physics_process(delta: float) -> void:
	animation_clock += delta
	if screen == Screen.FINISH:
		celebration_time += delta
		_emit_test_telemetry(delta)
		queue_redraw()
		return
	last_player_position = player_position
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if touch_direction.length_squared() > 0.01:
		direction = touch_direction
	if direction.length() > 1.0:
		direction = direction.normalized()
	if direction != Vector2.ZERO:
		var next_position := player_position + direction * MOVE_SPEED * delta
		if screen == Screen.RACE:
			next_position = _constrain_to_race_route(next_position)
			if _hit_log(next_position):
				message = "繞過木樁，沿著彩虹小路走！"
				next_position = player_position
		player_position = next_position
	player_animation.update(player_position - last_player_position, delta)
	if screen == Screen.RACE and player_position.distance_to(_race_finish_position()) <= 62.0:
		screen = Screen.FINISH
		# Keep the character beside the celebration card so it remains visible
		# at narrow mobile aspect ratios.
		player_position = _race_finish_position() + Vector2(150.0, 80.0)
		celebration_time = 0.0
		message = "选一个按钮，再玩一局或返回大厅！"
	_update_buttons()
	_emit_test_telemetry(delta)
	queue_redraw()

func _emit_test_telemetry(delta: float) -> void:
	if not test_telemetry_enabled:
		return
	test_telemetry_elapsed += delta
	if test_telemetry_elapsed < 0.05:
		return
	test_telemetry_elapsed = fposmod(test_telemetry_elapsed, 0.05)
	print("TEST_COMPETITION ", JSON.stringify({"screen": screen, "x": player_position.x, "y": player_position.y, "world_width": world_width, "viewport": get_viewport_rect().size, "physical_viewport": _physical_viewport_size(), "nearest_entry": _nearest_hub_entry(), "action_text": action_button.text if is_instance_valid(action_button) else "", "action_position": action_button.position if is_instance_valid(action_button) else Vector2.ZERO, "action_size": action_button.size if is_instance_valid(action_button) else Vector2.ZERO, "message": message, "animation": player_animation.animation, "frame": player_animation.current_frame_index()}))

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_on_back_pressed()
			get_viewport().set_input_as_handled()
		elif event.keycode in [KEY_E, KEY_SPACE, KEY_ENTER]:
			_on_action_pressed()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _is_stick_zone(event.position):
			mouse_stick_active = true
			touch_origin = event.position
			_update_stick(event.position)
		elif not event.pressed and mouse_stick_active:
			mouse_stick_active = false
			touch_direction = Vector2.ZERO
			queue_redraw()
	elif event is InputEventMouseMotion and mouse_stick_active:
		_update_stick(event.position)
	elif event is InputEventScreenTouch:
		if event.pressed and touch_id == -1 and _is_stick_zone(event.position):
			touch_id = event.index
			touch_active = true
			touch_origin = event.position
			_update_stick(event.position)
		elif not event.pressed and event.index == touch_id:
			touch_id = -1
			touch_active = false
			touch_direction = Vector2.ZERO
			queue_redraw()
	elif event is InputEventScreenDrag and event.index == touch_id:
		_update_stick(event.position)

func _is_stick_zone(position: Vector2) -> bool:
	var view := get_viewport_rect().size
	return position.x <= minf(180.0, view.x * 0.25) and position.y >= view.y * 0.56

func _update_stick(position: Vector2) -> void:
	var offset := position - touch_origin
	touch_direction = Vector2.ZERO if offset.length() < 14.0 else offset.limit_length(56.0) / 56.0
	queue_redraw()

func _on_action_pressed() -> void:
	if screen == Screen.HUB:
		var nearest := _nearest_hub_entry()
		if nearest == "single":
			_start_race()
		elif nearest == "exit":
			close_requested.emit()
		elif nearest == "animals":
			message = "动物伙伴正在准备比赛。"
		elif nearest == "friends":
			message = "好友竞技即将开放，先来试试单人赛吧！"
		else:
			message = "走到彩虹草地赛入口，按互动开始体验。"
	elif screen == Screen.RACE:
		message = "沿着花朵路标走到彩虹终点！"
	elif screen == Screen.FINISH:
		_start_race()
	_update_buttons()
	queue_redraw()

func _on_back_pressed() -> void:
	if screen == Screen.HUB:
		close_requested.emit()
	else:
		_return_to_hub()

func _return_to_hub() -> void:
	screen = Screen.HUB
	player_position = Vector2(world_width * 0.5, 430.0)
	message = "大厅随时欢迎你！想再挑战一次吗？"
	celebration_time = 0.0
	_update_buttons()
	queue_redraw()

func _start_race() -> void:
	screen = Screen.RACE
	player_position = _race_start_position()
	player_animation.direction = "right"
	player_animation.animation = "idle_right"
	player_animation.elapsed = 0.0
	message = "沿着彩虹小路，绕过木桩，去找终点！"
	celebration_time = 0.0
	_update_buttons()
	queue_redraw()

func _update_buttons() -> void:
	if not is_instance_valid(action_button):
		return
	back_button.text = "回生活小岛" if screen == Screen.HUB else "返回大厅"
	back_button.visible = screen != Screen.FINISH
	var show_action := screen != Screen.FINISH
	if screen == Screen.HUB:
		var nearest := _nearest_hub_entry()
		action_button.text = "去挑战" if nearest == "single" else ("回生活小岛" if nearest == "exit" else "互动")
		action_button.tooltip_text = "进入彩虹草地赛" if nearest == "single" else ("离开竞技岛" if nearest == "exit" else "靠近木牌后选择互动")
		# The persistent top-right back button already handles the bridge exit.
		# Hiding the contextual action here prevents two identical exit buttons
		# from appearing when the player first arrives beside the bridge.
		action_button.visible = nearest != "exit"
	else:
		action_button.text = "继续前进"
		action_button.tooltip_text = "沿着赛道移动到彩虹拱门"
		action_button.visible = show_action
	replay_button.visible = screen == Screen.FINISH
	return_hub_button.visible = screen == Screen.FINISH

func _nearest_hub_entry() -> String:
	var candidates := {
		"single": Vector2(world_width * 0.5, 170.0),
		"animals": Vector2(world_width * 0.25, 270.0),
		"friends": Vector2(world_width * 0.78, 285.0),
		"exit": Vector2(world_width * 0.5, 520.0),
	}
	var nearest := ""
	var distance := 108.0
	for key in candidates:
		var current: float = player_position.distance_to(candidates[key])
		if current < distance:
			distance = current
			nearest = str(key)
	return nearest

func _race_points() -> PackedVector2Array:
	var cx := world_width * 0.5
	return PackedVector2Array([
		Vector2(cx - 462.0, 452.0), Vector2(cx - 320.0, 446.0),
		Vector2(cx - 245.0, 388.0), Vector2(cx - 150.0, 320.0),
		Vector2(cx - 15.0, 270.0), Vector2(cx + 115.0, 276.0),
		Vector2(cx + 200.0, 285.0), Vector2(cx + 300.0, 276.0),
		Vector2(cx + 385.0, 225.0), Vector2(cx + 410.0, 150.0),
	])

func _race_start_position() -> Vector2:
	return _race_points()[0] + Vector2(-4.0, 0.0)

func _race_finish_position() -> Vector2:
	return _race_points()[-1]

func _constrain_to_race_route(position: Vector2) -> Vector2:
	var points := _race_points()
	var nearest := position
	var best_distance := INF
	for index in range(points.size() - 1):
		var a := points[index]
		var b := points[index + 1]
		var segment := b - a
		var t := clampf((position - a).dot(segment) / maxf(segment.length_squared(), 0.001), 0.0, 1.0)
		var candidate := a + segment * t
		var distance := position.distance_to(candidate)
		if distance < best_distance:
			best_distance = distance
			nearest = candidate
	if best_distance > ROAD_WIDTH * 0.56:
		return nearest + (position - nearest).normalized() * ROAD_WIDTH * 0.56
	return position

func _hit_log(position: Vector2) -> bool:
	return position.distance_to(LOG_CENTER) < 36.0

func _draw() -> void:
	var view := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, view), Color("bfe8ec"), true)
	draw_circle(Vector2(view.x * 0.80, view.y * 0.13), minf(view.y * 0.10, 48.0), Color("ffdf93"))
	var previous_world_width := world_width
	world_scale = view.y / DESIGN_SIZE.y
	world_width = maxf(DESIGN_SIZE.x, view.x / maxf(world_scale, 0.001))
	if absf(world_width - previous_world_width) > 1.0:
		player_position.x += (world_width - previous_world_width) * 0.5
		last_player_position = player_position
	world_offset = Vector2(view.x * 0.5 - world_width * world_scale * 0.5, 0.0)
	draw_set_transform(world_offset, 0.0, Vector2.ONE * world_scale)
	if screen == Screen.HUB:
		_draw_hub()
		_draw_player()
	else:
		_draw_race()
		if player_position.y < LOG_CENTER.y:
			_draw_player()
			_draw_race_front()
		else:
			_draw_race_front()
			_draw_player()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if screen == Screen.FINISH:
		_draw_finish_card(view)
	_draw_ui(view)

func _draw_hub() -> void:
	draw_texture_rect(HubBackground, Rect2(0.0, 0.0, world_width, 720.0), false)
	var center := world_width * 0.5
	_draw_hub_marker(Vector2(center, 188.0), "彩虹草地赛", Color("e5b94e"), 0)
	_draw_hub_marker(Vector2(world_width * 0.25, 322.0), "动物比赛", Color("d98374"), 1)
	_draw_hub_marker(Vector2(world_width * 0.78, 330.0), "好友房间", Color("69aebd"), 2)
	_draw_hub_marker(Vector2(center, 552.0), "回生活小岛", Color("8dbb75"), 3)
	var nearest := _nearest_hub_entry()
	if nearest != "":
		var point := _hub_entry_position(nearest)
		var marker_scale := _ui_scale_factor()
		draw_arc(point + Vector2(0, 30), (58.0 + sin(animation_clock * 3.0) * 3.0) * marker_scale, 0.0, TAU, 48, Color("fff2a3", 0.86), 4.0 * marker_scale)

func _hub_entry_position(entry: String) -> Vector2:
	var center := world_width * 0.5
	if entry == "single": return Vector2(center, 170.0)
	if entry == "animals": return Vector2(world_width * 0.25, 270.0)
	if entry == "friends": return Vector2(world_width * 0.78, 285.0)
	return Vector2(center, 520.0)


func _draw_hub_marker(position: Vector2, label: String, accent: Color, kind: int) -> void:
	var marker_scale := _ui_scale_factor()
	var pulse := 1.0 + sin(animation_clock * 2.4 + float(kind)) * 0.025
	var marker := Rect2(position - Vector2(84, 19) * marker_scale * pulse, Vector2(168, 38) * marker_scale * pulse)
	_draw_rounded_rect(marker, Color(0.98, 0.95, 0.82, 0.88), Color(accent, 0.92), 17.0 * marker_scale)
	var text_left := position.x - 80.0 * marker_scale
	var text_width := 160.0 * marker_scale
	if kind == 1:
		draw_texture_rect(RabbitArt, Rect2(position + Vector2(-68, -13) * marker_scale, Vector2(20, 25) * marker_scale), false)
		draw_texture_rect(FoxArt, Rect2(position + Vector2(-45, -13) * marker_scale, Vector2(21, 25) * marker_scale), false)
		text_left = position.x - 24.0 * marker_scale
		text_width = 100.0 * marker_scale
	elif kind == 2:
		for index in range(3):
			draw_circle(position + Vector2(-67 + index * 15, 0) * marker_scale, 4.0 * marker_scale, [Color("ef9a9d"), Color("efc86e"), Color("87c38a")][index])
		text_left = position.x - 40.0 * marker_scale
		text_width = 110.0 * marker_scale
	elif kind == 3:
		draw_circle(position + Vector2(-65, 0) * marker_scale, 5.0 * marker_scale, Color("fff0b0"))
		text_left = position.x - 48.0 * marker_scale
		text_width = 125.0 * marker_scale
	_draw_text_center(label, Vector2(text_left, position.y + 6 * marker_scale), roundi(16 * marker_scale), INK, text_width)

func _draw_race() -> void:
	draw_texture_rect(RaceBackground, Rect2(0.0, 0.0, world_width, 720.0), false)
	var label_scale := _ui_scale_factor()
	var start := _race_start_position()
	var finish := _race_finish_position()
	_draw_rounded_rect(Rect2(start + Vector2(-45, -96) * label_scale, Vector2(90, 30) * label_scale), Color(0.98, 0.95, 0.82, 0.92), Color("d7b964"), 14.0 * label_scale)
	_draw_text_center("起点", start + Vector2(-45, -75) * label_scale, roundi(16 * label_scale), INK, 90.0 * label_scale)
	_draw_rounded_rect(Rect2(finish + Vector2(-46, 72) * label_scale, Vector2(92, 30) * label_scale), Color(0.98, 0.95, 0.82, 0.92), Color("d7b964"), 14.0 * label_scale)
	_draw_text_center("终点", finish + Vector2(-46, 93) * label_scale, roundi(16 * label_scale), INK, 92.0 * label_scale)

func _draw_race_front() -> void:
	var obstacle_rect := Rect2(LOG_CENTER - Vector2(80.0, 43.0), Vector2(160.0, 86.0))
	draw_texture_rect(MeadowLog, obstacle_rect, false)

func _rotated_rect(center: Vector2, rect_size: Vector2, angle: float) -> PackedVector2Array:
	var half := rect_size * 0.5
	var points := PackedVector2Array()
	for point in [Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)]:
		points.append(center + point.rotated(angle))
	return points

func _draw_finish_arch(position: Vector2) -> void:
	_draw_shadow(position + Vector2(0, 48), Vector2(65, 16))
	for index in range(7):
		draw_arc(position + Vector2(0, 6), 45.0 + index * 7.0, PI, TAU, 36, [Color("e76d72"), Color("f2a45e"), Color("f3d46f"), Color("8bc879"), Color("63b9cd"), Color("7a8dd1"), Color("b085c6")][index], 8.0)
	draw_rect(Rect2(position.x - 74, position.y - 5, 10, 60), Color("a97847"), true)
	draw_rect(Rect2(position.x + 64, position.y - 5, 10, 60), Color("a97847"), true)
	_draw_text("终点", position + Vector2(-24, 70), 19, INK)

func _draw_finish_card(view: Vector2) -> void:
	var output_size := _physical_viewport_size()
	var scale_factor := get_viewport_rect().size.y / maxf(output_size.y, 1.0)
	draw_rect(Rect2(Vector2.ZERO, view), Color(0.08, 0.18, 0.13, 0.22), true)
	var rect := Rect2((output_size * 0.5 - Vector2(236, 108)) * scale_factor, Vector2(472, 216) * scale_factor)
	_draw_rounded_rect(rect, Color("fff7df"), Color("d9b761"), 30.0)
	_draw_text_center("太棒了！到达终点！", rect.position + Vector2(0, 78 * scale_factor), roundi(31 * scale_factor), Color("345c42"), rect.size.x)
	_draw_text_center("这条彩虹小路真好玩", rect.position + Vector2(0, 124 * scale_factor), roundi(19 * scale_factor), Color("66805c"), rect.size.x)
	for i in range(11):
		var x := rect.position.x + (30.0 + float(i * 41)) * scale_factor
		var y := rect.position.y + (22.0 + fposmod(float(i * 17) + celebration_time * (16.0 + i), 43.0)) * scale_factor
		draw_colored_polygon(PackedVector2Array([Vector2(x, y - 5 * scale_factor), Vector2(x + 2 * scale_factor, y), Vector2(x + 7 * scale_factor, y + scale_factor), Vector2(x + 3 * scale_factor, y + 4 * scale_factor), Vector2(x + 2 * scale_factor, y + 9 * scale_factor), Vector2(x - scale_factor, y + 5 * scale_factor), Vector2(x - 6 * scale_factor, y + 2 * scale_factor), Vector2(x - scale_factor, y)]), [Color("ef9c88"), Color("75b8d2"), Color("e8c56b"), Color("8abe74")][i % 4])

func _draw_player() -> void:
	var foot := player_position + PLAYER_FOOT
	var ui_scale := _ui_scale_factor()
	var character_scale := 0.30 * ui_scale
	_draw_shadow(foot + Vector2(2, 3), Vector2(20, 6) * ui_scale)
	var texture: Texture2D = player_animation.current_texture()
	if texture == null:
		texture = MouseArt
	draw_texture_rect(texture, Rect2(foot - Vector2(128, 232) * character_scale, Vector2(256, 256) * character_scale), false)

func _draw_ui(view: Vector2) -> void:
	var output_size := _physical_viewport_size()
	var scale_factor := get_viewport_rect().size.y / maxf(output_size.y, 1.0)
	_draw_rounded_rect(Rect2(Vector2(16, 15) * scale_factor, Vector2(minf(output_size.x * 0.38, 480), 72) * scale_factor), Color(0.94, 0.96, 0.83, 0.94), Color("89b778"), 20.0 * scale_factor)
	_draw_text("欢乐竞技岛", Vector2(35, 47) * scale_factor, roundi(25 * scale_factor), INK)
	_draw_text("彩虹草地赛 · 基础体验" if screen != Screen.HUB else "选一个木牌，开始轻松挑战", Vector2(37, 72) * scale_factor, roundi(15 * scale_factor), Color("658061"))
	var hint_rect := Rect2(Vector2(140, output_size.y - 72) * scale_factor, Vector2(maxf(260, output_size.x - 390), 54) * scale_factor)
	_draw_rounded_rect(hint_rect, Color(0.98, 0.96, 0.86, 0.93), Color("b8cc9a"), 18.0)
	_draw_text(message, hint_rect.position + Vector2(17, 34) * scale_factor, roundi(15 * scale_factor), INK)
	if touch_active or mouse_stick_active:
		var center := touch_origin
		draw_circle(center, 53 * scale_factor, Color(0.12, 0.28, 0.18, 0.42))
		draw_circle(center, 45 * scale_factor, Color(0.77, 0.89, 0.62, 0.72))
		draw_circle(center + touch_direction * 40.0 * scale_factor, 20 * scale_factor, Color("fff8dd"))
	elif screen != Screen.FINISH:
		var center := Vector2(68, output_size.y - 83) * scale_factor
		draw_circle(center, 49 * scale_factor, Color(0.12, 0.28, 0.18, 0.25))
		draw_circle(center, 39 * scale_factor, Color(0.77, 0.89, 0.62, 0.72))
		draw_circle(center, 17 * scale_factor, Color("fff8dd"))

func _draw_shadow(center: Vector2, radius: Vector2) -> void:
	var points := PackedVector2Array()
	for index in range(16):
		var angle := TAU * float(index) / 16.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, Color(0.18, 0.25, 0.15, 0.24))

func _draw_flower(center: Vector2, scale: float, color: Color) -> void:
	var radius := 4.0 * scale
	draw_line(center + Vector2(0, 2), center + Vector2(0, 13 * scale), Color("518e4e"), 2.0 * scale)
	for offset in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
		draw_circle(center + offset * radius, radius, color)
	draw_circle(center, radius * 0.48, Color("f4d77c"))

func _draw_rounded_rect(rect: Rect2, fill: Color, border: Color, radius: float) -> void:
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	_fill_rounded_rect(rect.grow(2.0), border, r + 2.0)
	_fill_rounded_rect(rect, fill, r)

func _fill_rounded_rect(rect: Rect2, color: Color, radius: float) -> void:
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	draw_rect(Rect2(rect.position.x + r, rect.position.y, rect.size.x - 2.0 * r, rect.size.y), color, true)
	draw_rect(Rect2(rect.position.x, rect.position.y + r, rect.size.x, rect.size.y - 2.0 * r), color, true)
	for center in [rect.position + Vector2(r, r), rect.position + Vector2(rect.size.x - r, r), rect.position + Vector2(r, rect.size.y - r), rect.position + rect.size - Vector2(r, r)]:
		draw_circle(center, r, color)

func _draw_text(text: String, position: Vector2, font_size: int, color: Color) -> void:
	draw_string(UI_FONT, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw_text_center(text: String, position: Vector2, font_size: int, color: Color, width: float) -> void:
	draw_string(UI_FONT, position, text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, color)
