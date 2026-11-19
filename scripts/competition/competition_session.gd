extends Control

signal close_requested

const PlayerAnimation = preload("res://scripts/visual/player_animation.gd")
const RaceClock = preload("res://scripts/competition/race_clock.gd")
const JumpMotion = preload("res://scripts/competition/jump_motion.gd")
const MouseFrames: SpriteFrames = preload("res://assets/art/animation/mouse-frames.tres")
const MouseIdleFrames: SpriteFrames = preload("res://assets/art/animation/mouse-idle-frames.tres")
const MouseArt: Texture2D = preload("res://assets/art/characters/mouse.png")
const RabbitArt: Texture2D = preload("res://assets/art/characters/rabbit.png")
const FoxArt: Texture2D = preload("res://assets/art/characters/fox.png")
const HubBackground: Texture2D = preload("res://assets/art/competition/competition-hub.png")
const RaceBackground: Texture2D = preload("res://assets/art/competition/rainbow-meadow-race.png")
const MeadowLog: Texture2D = preload("res://assets/art/competition/meadow-log-obstacle.png")
const UI_FONT: Font = preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const DESIGN_SIZE := Vector2(1280.0, 720.0)
const MOVE_SPEED := 260.0
const PLAYER_FOOT := Vector2(0.0, 36.0)
const ROAD_WIDTH := 86.0
const LOW_HURDLE_RADIUS := 25.0
const HIGH_LOG_RADIUS := 23.0
const JUMP_CLEARANCE := 18.0
const CHECKPOINT_RADIUS := 42.0

const INK := Color("294438")
const CREAM := Color("fff7df")
const GRASS := Color("79bd72")
const GRASS_LIGHT := Color("a5d87e")
const WOOD := Color("a96d43")
const WOOD_LIGHT := Color("d9a66a")
const GOLD := Color("f4cc72")

enum Screen { HUB, PREPARE, RACE, FINISH, COUNTDOWN, PAUSED }

var screen := Screen.HUB
var player_position := Vector2(640.0, 430.0)
var player_animation = PlayerAnimation.new(MouseFrames if _has_walk_frames() else MouseIdleFrames)
var race_clock = RaceClock.new()
var jump_motion = JumpMotion.new()
var race_elapsed_at_finish := 0.0
var session_best_time := 0.0
var race_checkpoint := Vector2.ZERO
var checkpoint_index := 0
var checkpoint_hint_time := 0.0
var touch_active := false
var touch_id := -1
var jump_touch_id := -1
var touch_origin := Vector2.ZERO
var touch_direction := Vector2.ZERO
var mouse_stick_active := false
var message := "欢迎来到欢乐竞技岛！去看看彩虹草地赛吧。"
var celebration_time := 0.0
var action_button: Button
var back_button: Button
var replay_button: Button
var return_hub_button: Button
var checkpoint_button: Button
var pause_button: Button
var pressed_ui := false
var animation_clock := 0.0
var last_player_position := Vector2.ZERO
var world_width := 1280.0
var world_scale := 1.0
var world_offset := Vector2.ZERO
var test_telemetry_enabled := false
var test_telemetry_elapsed := 0.0
var test_airborne_distance := 0.0
var test_peak_jump_height := 0.0
var countdown_remaining := 0.0
var countdown_paused := false
var best_is_new := false
var route_segment := 0
var stars_collected := [false, false, false, false, false]
var feedback_player: AudioStreamPlayer
var feedback_cooldown := 0.0
var countdown_digit := 0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_to_group("competition_session")
	test_telemetry_enabled = "--test-telemetry" in OS.get_cmdline_user_args()
	_load_best_time()
	feedback_player = AudioStreamPlayer.new()
	feedback_player.volume_db = -21.0
	add_child(feedback_player)
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
	checkpoint_button = _make_button("回检查点", Vector2(150, 52))
	checkpoint_button.pressed.connect(_return_to_checkpoint)
	pause_button = _make_button("暂停", Vector2(150, 52))
	pause_button.pressed.connect(_toggle_pause)
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
	_update_world_layout(view)
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
	for button in [back_button, action_button, replay_button, return_hub_button, checkpoint_button, pause_button]:
		button.add_theme_font_size_override("font_size", roundi(21.0 * ui_scale))
	back_button.position = Vector2(maxf(12.0 * ui_scale, view.x - back_button.size.x - 18.0 * ui_scale), 16.0 * ui_scale)
	action_button.position = Vector2(maxf(12.0 * ui_scale, view.x - action_button.size.x - 18.0 * ui_scale), maxf(12.0 * ui_scale, view.y - action_button.size.y - 16.0 * ui_scale))
	replay_button.position = Vector2((output_size.x * 0.5 - 194.0) * ui_scale, output_size.y * 0.63 * ui_scale)
	return_hub_button.position = Vector2((output_size.x * 0.5 + 14.0) * ui_scale, output_size.y * 0.63 * ui_scale)
	checkpoint_button.size = Vector2(150, 52) * ui_scale
	checkpoint_button.custom_minimum_size = checkpoint_button.size
	checkpoint_button.position = Vector2(maxf(12.0 * ui_scale, view.x - checkpoint_button.size.x - 18.0 * ui_scale), back_button.position.y + back_button.size.y + 8.0 * ui_scale)
	pause_button.size = Vector2(150, 52) * ui_scale
	pause_button.custom_minimum_size = pause_button.size
	pause_button.position = Vector2(checkpoint_button.position.x, checkpoint_button.position.y + (checkpoint_button.size.y + 8.0 * ui_scale if checkpoint_index > 0 else 0.0))
	if screen == Screen.PREPARE:
		action_button.position = Vector2((view.x - action_button.size.x) * 0.5, view.y * 0.78 - action_button.size.y * 0.5)
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
	feedback_cooldown = maxf(0.0, feedback_cooldown - delta)
	if screen == Screen.PAUSED:
		_clear_touch_input()
		_emit_test_telemetry(delta)
		return
	if screen == Screen.COUNTDOWN:
		if not countdown_paused:
			countdown_remaining -= delta
			var digit := maxi(0, ceili(countdown_remaining))
			if digit != countdown_digit:
				countdown_digit = digit
				_play_feedback(660.0 if digit > 0 else 880.0)
			if countdown_remaining <= 0.0:
				_clear_touch_input()
				for action in ["move_left", "move_right", "move_up", "move_down"]:
					Input.action_release(action)
				screen = Screen.RACE
				race_clock.start()
				message = "出发！沿小路经过所有路标。"
				_update_buttons()
		_emit_test_telemetry(delta)
		queue_redraw()
		return
	if screen == Screen.RACE and race_clock.paused:
		# A hidden browser can keep receiving physics ticks. Freeze gameplay as well
		# as the timer, and discard any joystick state that survived focus loss.
		_clear_touch_input()
		_emit_test_telemetry(delta)
		return
	animation_clock += delta
	checkpoint_hint_time = maxf(0.0, checkpoint_hint_time - delta)
	if screen == Screen.FINISH:
		celebration_time += delta
		_emit_test_telemetry(delta)
		queue_redraw()
		return
	last_player_position = player_position
	if screen == Screen.PREPARE:
		_emit_test_telemetry(delta)
		queue_redraw()
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if touch_direction.length_squared() > 0.01:
		direction = touch_direction
	if direction.length() > 1.0:
		direction = direction.normalized()
	if direction != Vector2.ZERO:
		# Bound a single movement step so a stalled frame cannot tunnel through
		# a narrow obstacle or skip an ordered checkpoint.
		var next_position := player_position + direction * MOVE_SPEED * minf(delta, 0.04)
		if screen == Screen.RACE:
			next_position = _constrain_to_race_route(next_position)
			if _blocked_by_obstacle(next_position, player_position):
				message = "高木桩挡住啦，从右侧绕过去。" if next_position.distance_to(_high_log_position()) < HIGH_LOG_RADIUS else "矮木栏挡住啦，按跳跃越过去。"
				_play_feedback(260.0, 0.08, 0.7)
				next_position = player_position
		player_position = next_position
	if screen == Screen.RACE:
		if test_telemetry_enabled and jump_motion.active:
			test_airborne_distance += player_position.distance_to(last_player_position)
		jump_motion.advance(delta)
		if test_telemetry_enabled:
			test_peak_jump_height = maxf(test_peak_jump_height, jump_motion.height())
		if jump_motion.just_landed:
			_play_feedback(440.0, 0.07)
		_update_checkpoints()
		_update_stars()
	player_animation.update(player_position - last_player_position, delta)
	var finish_direction := (_race_points()[-1] - _race_points()[-2]).normalized()
	var crossed_finish := (last_player_position - _race_finish_position()).dot(finish_direction) < 0.0 and (player_position - _race_finish_position()).dot(finish_direction) >= 0.0
	if screen == Screen.RACE and checkpoint_index == _checkpoint_positions().size() and crossed_finish and player_position.distance_to(_race_finish_position()) <= ROAD_WIDTH * 0.6:
		screen = Screen.FINISH
		race_elapsed_at_finish = race_clock.stop()
		_play_feedback(880.0, 0.18)
		if session_best_time <= 0.0 or race_elapsed_at_finish < session_best_time:
			session_best_time = race_elapsed_at_finish
			best_is_new = true
			_save_best_time()
		jump_motion.active = false
		# Leave the player at the finish rather than teleporting onto scenery.
		celebration_time = 0.0
		message = "挑战完成！看看这次用了多久。"
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
	var physical_coordinate_scale := _physical_viewport_size().y / maxf(get_viewport_rect().size.y, 1.0)
	print("TEST_COMPETITION ", JSON.stringify({
		"screen": screen,
		"x": player_position.x,
		"y": player_position.y,
		"world_width": world_width,
		"viewport": get_viewport_rect().size,
		"physical_viewport": _physical_viewport_size(),
		"nearest_entry": _nearest_hub_entry(),
		"action_text": action_button.text if is_instance_valid(action_button) else "",
		"action_position": [action_button.position.x * physical_coordinate_scale, action_button.position.y * physical_coordinate_scale] if is_instance_valid(action_button) else [0.0, 0.0],
		"action_size": [action_button.size.x * physical_coordinate_scale, action_button.size.y * physical_coordinate_scale] if is_instance_valid(action_button) else [0.0, 0.0],
		"checkpoint_position": [checkpoint_button.position.x * physical_coordinate_scale, checkpoint_button.position.y * physical_coordinate_scale] if is_instance_valid(checkpoint_button) else [0.0, 0.0],
		"checkpoint_size": [checkpoint_button.size.x * physical_coordinate_scale, checkpoint_button.size.y * physical_coordinate_scale] if is_instance_valid(checkpoint_button) else [0.0, 0.0],
		"back_position": [back_button.position.x * physical_coordinate_scale, back_button.position.y * physical_coordinate_scale] if is_instance_valid(back_button) else [0.0, 0.0],
		"back_size": [back_button.size.x * physical_coordinate_scale, back_button.size.y * physical_coordinate_scale] if is_instance_valid(back_button) else [0.0, 0.0],
		"checkpoint_index": checkpoint_index,
		"race_checkpoint": [race_checkpoint.x, race_checkpoint.y],
		"jump_active": jump_motion.active,
		"jump_height": jump_motion.height(),
		"touch_active": touch_active,
		"touch_direction": [touch_direction.x, touch_direction.y],
		"test_airborne_distance": test_airborne_distance,
		"test_peak_jump_height": test_peak_jump_height,
		"clock_running": race_clock.running,
		"clock_paused": race_clock.paused,
		"race_time": race_clock.elapsed_seconds(),
		"best_time": session_best_time,
		"stars": _star_count(),
		"message": message,
		"animation": player_animation.animation,
		"frame": player_animation.current_frame_index(),
	}))

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_on_back_pressed()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_SPACE:
			if screen == Screen.RACE:
				_request_jump()
				get_viewport().set_input_as_handled()
		elif event.keycode in [KEY_E, KEY_ENTER]:
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
		if event.pressed and screen == Screen.RACE and is_instance_valid(action_button) and action_button.get_global_rect().has_point(event.position):
			jump_touch_id = event.index
			_request_jump()
		elif not event.pressed and event.index == jump_touch_id:
			jump_touch_id = -1
		elif event.pressed and touch_id == -1 and _is_stick_zone(event.position):
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
			_prepare_race()
		elif nearest == "exit":
			close_requested.emit()
		elif nearest == "animals":
			message = "动物伙伴正在准备比赛。"
		elif nearest == "friends":
			message = "好友竞技即将开放，先来试试单人赛吧！"
		else:
			message = "走到彩虹草地赛入口，按互动开始体验。"
	elif screen == Screen.PREPARE:
		_start_race()
	elif screen == Screen.RACE:
		_request_jump()
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
	race_clock.stop()
	race_clock.reset()
	jump_motion.active = false
	jump_motion.elapsed = 0.0
	_clear_touch_input()
	screen = Screen.HUB
	player_position = Vector2(world_width * 0.5, 430.0)
	message = "大厅随时欢迎你！想再挑战一次吗？"
	celebration_time = 0.0
	_layout_controls()

func _start_race() -> void:
	race_clock.reset()
	best_is_new = false
	race_elapsed_at_finish = 0.0
	jump_motion.active = false
	jump_motion.elapsed = 0.0
	checkpoint_index = 0
	route_segment = 0
	stars_collected = [false, false, false, false, false]
	test_airborne_distance = 0.0
	test_peak_jump_height = 0.0
	race_checkpoint = _race_start_position()
	checkpoint_hint_time = 0.0
	_clear_touch_input()
	screen = Screen.COUNTDOWN
	countdown_remaining = 3.0
	countdown_paused = false
	countdown_digit = 4
	player_position = _race_start_position()
	player_animation.direction = "right"
	player_animation.animation = "idle_right"
	player_animation.elapsed = 0.0
	message = "准备出发！倒数结束后开始计时。"
	celebration_time = 0.0
	_layout_controls()

func _prepare_race() -> void:
	race_clock.reset()
	jump_motion.active = false
	race_checkpoint = _race_start_position()
	checkpoint_index = 0
	_clear_touch_input()
	screen = Screen.PREPARE
	player_position = _race_start_position()
	race_elapsed_at_finish = 0.0
	message = "先看看操作图示，再按“开始挑战”。"
	_layout_controls()

func _request_jump() -> void:
	if screen != Screen.RACE or race_clock.paused:
		return
	if jump_motion.start():
		message = "跳起来啦！落地后继续向前。"
		_play_feedback(620.0)
		queue_redraw()

func _return_to_checkpoint() -> void:
	if screen != Screen.RACE or checkpoint_index <= 0:
		return
	player_position = race_checkpoint
	last_player_position = race_checkpoint
	route_segment = 10 if checkpoint_index == 1 else 21
	jump_motion.active = false
	jump_motion.elapsed = 0.0
	_clear_touch_input()
	message = "回到安全路标啦，计时会继续。"
	queue_redraw()

func _toggle_pause() -> void:
	if screen == Screen.RACE:
		race_clock.pause()
		_clear_touch_input()
		for action in ["move_left", "move_right", "move_up", "move_down"]:
			if InputMap.has_action(action):
				Input.action_release(action)
		screen = Screen.PAUSED
		message = "比赛已暂停。准备好后继续吧。"
	elif screen == Screen.PAUSED:
		_clear_touch_input()
		screen = Screen.RACE
		race_clock.resume()
		message = "继续沿小路前进！"
	_layout_controls()

func _clear_touch_input() -> void:
	touch_active = false
	touch_id = -1
	jump_touch_id = -1
	touch_direction = Vector2.ZERO
	mouse_stick_active = false

func _play_feedback(frequency: float, duration := 0.11, cooldown := 0.08) -> void:
	if feedback_player == null or feedback_cooldown > 0.0:
		return
	feedback_cooldown = cooldown
	var sample_rate := 22050
	var count := maxi(1, roundi(duration * sample_rate))
	var samples := PackedByteArray()
	samples.resize(count * 2)
	for index in range(count):
		var envelope := sin(PI * float(index) / float(count))
		var value := roundi(sin(TAU * frequency * float(index) / float(sample_rate)) * envelope * 6500.0)
		samples.encode_s16(index * 2, value)
	var clip := AudioStreamWAV.new()
	clip.format = AudioStreamWAV.FORMAT_16_BITS
	clip.mix_rate = sample_rate
	clip.data = samples
	feedback_player.stream = clip
	feedback_player.play()

func _notification(what: int) -> void:
	if what in [NOTIFICATION_WM_WINDOW_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED]:
		countdown_paused = true
		race_clock.pause()
		_clear_touch_input()
		for action in ["move_left", "move_right", "move_up", "move_down"]:
			if InputMap.has_action(action):
				Input.action_release(action)
		queue_redraw()
	elif what in [NOTIFICATION_WM_WINDOW_FOCUS_IN, NOTIFICATION_APPLICATION_RESUMED]:
		countdown_paused = false
		if screen != Screen.PAUSED:
			race_clock.resume()
		queue_redraw()

func _update_buttons() -> void:
	if not is_instance_valid(action_button):
		return
	back_button.text = "回生活小岛" if screen == Screen.HUB else "返回大厅"
	back_button.visible = screen != Screen.FINISH
	var show_action := screen != Screen.FINISH
	checkpoint_button.visible = screen == Screen.RACE and checkpoint_index > 0
	pause_button.visible = screen in [Screen.RACE, Screen.PAUSED]
	pause_button.text = "继续" if screen == Screen.PAUSED else "暂停"
	pause_button.position.y = checkpoint_button.position.y + (checkpoint_button.size.y + 8.0 * _ui_scale_factor() if checkpoint_index > 0 else 0.0)
	if screen == Screen.HUB:
		var nearest := _nearest_hub_entry()
		action_button.text = "去挑战" if nearest == "single" else ("回生活小岛" if nearest == "exit" else "互动")
		action_button.tooltip_text = "进入彩虹草地赛" if nearest == "single" else ("离开竞技岛" if nearest == "exit" else "靠近木牌后选择互动")
		# The persistent top-right back button already handles the bridge exit.
		# Hiding the contextual action here prevents two identical exit buttons
		# from appearing when the player first arrives beside the bridge.
		action_button.visible = nearest != "exit"
	elif screen == Screen.PREPARE:
		action_button.text = "开始挑战"
		action_button.tooltip_text = "开始计时并进入彩虹草地赛"
		action_button.visible = true
	elif screen == Screen.RACE:
		action_button.text = "跳跃"
		action_button.tooltip_text = "跳过矮木栏（Space）"
		action_button.visible = show_action
	else:
		action_button.visible = false
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
	var offset := Vector2((world_width - DESIGN_SIZE.x) * 0.5, 0.0)
	var points := PackedVector2Array([
		Vector2(160, 545), Vector2(300, 550), Vector2(405, 537), Vector2(493, 511),
		Vector2(540, 472), Vector2(545, 436), Vector2(500, 400), Vector2(405, 374),
		Vector2(305, 345), Vector2(270, 311), Vector2(280, 279), Vector2(345, 245),
		Vector2(445, 218), Vector2(560, 204), Vector2(650, 213), Vector2(715, 240),
		Vector2(725, 270), Vector2(710, 305), Vector2(731, 342), Vector2(790, 370),
		Vector2(910, 380), Vector2(1010, 369), Vector2(1073, 343), Vector2(1090, 310),
		Vector2(1072, 275), Vector2(1030, 240), Vector2(1004, 208), Vector2(1015, 184),
		Vector2(1050, 160), Vector2(1068, 147), Vector2(1081, 134),
	])
	for index in range(points.size()):
		# Route positions refer to the player's logical origin; the visible
		# foot is 36 pixels below it. Align that foot to the painted road.
		points[index] += offset - PLAYER_FOOT
	return points

func _race_start_position() -> Vector2:
	return _race_points()[0] + Vector2(-4.0, 0.0)

func _race_finish_position() -> Vector2:
	return _race_points()[-1]

func _constrain_to_race_route(position: Vector2) -> Vector2:
	var points := _race_points()
	var nearest := position
	var best_distance := INF
	# Only the current section and its immediate neighbours are reachable.
	# Nearby bends of the painted path cannot be used to jump ahead in the route.
	var best_index := route_segment
	for index in range(maxi(0, route_segment - 1), mini(points.size() - 1, route_segment + 2)):
		var a := points[index]
		var b := points[index + 1]
		var segment := b - a
		var t := clampf((position - a).dot(segment) / maxf(segment.length_squared(), 0.001), 0.0, 1.0)
		var candidate := a + segment * t
		var distance := position.distance_to(candidate)
		if distance < best_distance:
			best_distance = distance
			nearest = candidate
			best_index = index
	route_segment = best_index
	if best_distance > ROAD_WIDTH * 0.56:
		return nearest + (position - nearest).normalized() * ROAD_WIDTH * 0.56
	return position

func _low_hurdle_position() -> Vector2:
	return _race_points()[3]

func _high_log_position() -> Vector2:
	return _race_points()[18] + Vector2(-14, 8)

func _checkpoint_positions() -> Array[Vector2]:
	var points := _race_points()
	return [points[10], points[21]]

func _star_positions() -> Array[Vector2]:
	var points := _race_points()
	return [points[2], points[8], points[14], points[20], points[25]]

func _update_stars() -> void:
	var stars := _star_positions()
	for index in range(stars.size()):
		if not stars_collected[index] and player_position.distance_to(stars[index]) < 24.0:
			stars_collected[index] = true
			message = "收集到一颗彩虹星！继续向前。"
			_play_feedback(780.0)

func _star_count() -> int:
	var total := 0
	for collected in stars_collected:
		if collected:
			total += 1
	return total

func _blocked_by_obstacle(position: Vector2, previous_position: Vector2) -> bool:
	if position.distance_to(_high_log_position()) < HIGH_LOG_RADIUS:
		# If a resize or recovery leaves the player just inside the collision
		# radius, permit movement outward so they cannot become trapped.
		return position.distance_to(_high_log_position()) <= previous_position.distance_to(_high_log_position())
	var hurdle := _low_hurdle_position()
	if jump_motion.height() >= JUMP_CLEARANCE:
		return false
	# The low rail spans the route: approaching its forward plane on foot
	# cannot be bypassed by walking around the visible endpoints.
	var points := _race_points()
	var forward := (points[4] - points[2]).normalized()
	var before := (previous_position - hurdle).dot(forward)
	var after := (position - hurdle).dot(forward)
	var lateral := absf((position - hurdle).dot(forward.orthogonal()))
	return lateral <= ROAD_WIDTH * 0.65 and before < 0.0 and after >= 0.0

func _best_time_path() -> String:
	return "user://rainbow_r01_best_preview.json" if "--save-namespace=preview" in OS.get_cmdline_user_args() else "user://rainbow_r01_best.json"

func _load_best_time() -> void:
	if FileAccess.file_exists(_best_time_path()):
		var file := FileAccess.open(_best_time_path(), FileAccess.READ)
		if file != null:
			var data = JSON.parse_string(file.get_as_text())
			if data is Dictionary and data.get("version") == 1:
				var value = data.get("best_seconds")
				if (value is float or value is int) and value > 0.0 and value < 86400.0:
					session_best_time = float(value)
	if OS.has_feature("web"):
		var mirror = JavaScriptBridge.eval("(() => { try { const n = Number(localStorage.getItem(%s)); return Number.isFinite(n) && n > 0 && n < 86400 ? n : 0; } catch (_) { return 0; } })()" % JSON.stringify(_best_time_mirror_key()), true)
		if (mirror is float or mirror is int) and mirror > 0.0 and (session_best_time <= 0.0 or mirror < session_best_time):
			session_best_time = float(mirror)

func _best_time_mirror_key() -> String:
	return "wonder-isle-r01-best-preview-v1" if "--save-namespace=preview" in OS.get_cmdline_user_args() else "wonder-isle-r01-best-v1"

func _save_best_time() -> void:
	var file := FileAccess.open(_best_time_path(), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"version": 1, "best_seconds": session_best_time}))
		file.close()
	if OS.has_feature("web"):
		# Keep the best of both tabs; a stale tab cannot replace a faster time.
		JavaScriptBridge.eval("(() => { try { const key = %s, value = %s, old = Number(localStorage.getItem(key)); if (!Number.isFinite(old) || old <= 0 || old >= 86400 || value < old) localStorage.setItem(key, String(value)); } catch (_) {} })()" % [JSON.stringify(_best_time_mirror_key()), JSON.stringify(session_best_time)], true)

func _update_checkpoints() -> void:
	var points := _checkpoint_positions()
	for index in range(checkpoint_index, mini(checkpoint_index + 1, points.size())):
		var route := _race_points()
		var route_index := 10 if index == 0 else 21
		var direction := (route[route_index + 1] - route[route_index - 1]).normalized()
		var crossed := (last_player_position - points[index]).dot(direction) < 0.0 and (player_position - points[index]).dot(direction) >= 0.0
		if crossed and player_position.distance_to(points[index]) <= ROAD_WIDTH * 0.6:
			checkpoint_index = index + 1
			_play_feedback(740.0, 0.14)
			race_checkpoint = points[index]
			checkpoint_hint_time = 2.4
			message = "到這裡啦！路標已記住。"
			_update_buttons()
			return

func _update_world_layout(view: Vector2) -> void:
	# Route coordinates are centered in the expanded world. Rebase every saved
	# race position together so recovery remains correct after a window resize.
	var previous_world_width := world_width
	world_scale = view.y / DESIGN_SIZE.y
	world_width = maxf(DESIGN_SIZE.x, view.x / maxf(world_scale, 0.001))
	var shift := (world_width - previous_world_width) * 0.5
	if not is_zero_approx(shift):
		player_position.x += shift
		last_player_position = player_position
		if screen != Screen.HUB:
			race_checkpoint.x += shift
	world_offset = Vector2(view.x * 0.5 - world_width * world_scale * 0.5, 0.0)

func _draw() -> void:
	var view := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, view), Color("bfe8ec"), true)
	draw_circle(Vector2(view.x * 0.80, view.y * 0.13), minf(view.y * 0.10, 48.0), Color("ffdf93"))
	draw_set_transform(world_offset, 0.0, Vector2.ONE * world_scale)
	if screen == Screen.HUB:
		_draw_hub()
		_draw_player()
	else:
		_draw_race()
		if player_position.y < _high_log_position().y:
			_draw_player()
			_draw_race_front()
		else:
			_draw_race_front()
			_draw_player()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if screen == Screen.PREPARE:
		_draw_prepare_card(view)
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
	draw_texture_rect(RaceBackground, Rect2((world_width - DESIGN_SIZE.x) * 0.5, 0.0, DESIGN_SIZE.x, DESIGN_SIZE.y), false)
	if "--race-debug" in OS.get_cmdline_user_args():
		var debug_points := _race_points()
		for index in range(debug_points.size() - 1):
			draw_line(debug_points[index] + PLAYER_FOOT, debug_points[index + 1] + PLAYER_FOOT, Color(0.2, 0.5, 1.0, 0.25), ROAD_WIDTH * 1.12)
			draw_line(debug_points[index] + PLAYER_FOOT, debug_points[index + 1] + PLAYER_FOOT, Color("2468aa"), 2.0)
	var label_scale := _ui_scale_factor()
	var start := _race_start_position()
	var finish := _race_finish_position()
	_draw_rounded_rect(Rect2(start + Vector2(-45, -96) * label_scale, Vector2(90, 30) * label_scale), Color(0.98, 0.95, 0.82, 0.92), Color("d7b964"), 14.0 * label_scale)
	_draw_text_center("起点", start + Vector2(-45, -75) * label_scale, roundi(16 * label_scale), INK, 90.0 * label_scale)
	_draw_rounded_rect(Rect2(finish + Vector2(-46, 72) * label_scale, Vector2(92, 30) * label_scale), Color(0.98, 0.95, 0.82, 0.92), Color("d7b964"), 14.0 * label_scale)
	_draw_text_center("终点", finish + Vector2(-46, 93) * label_scale, roundi(16 * label_scale), INK, 92.0 * label_scale)
	var points := _checkpoint_positions()
	for index in range(points.size()):
		var point := points[index] + PLAYER_FOOT
		var activated := index < checkpoint_index
		var pulse := 1.0 + sin(animation_clock * 3.2) * 0.06 if not activated else 1.0
		_draw_shadow(point + Vector2(0, 17), Vector2(24, 8))
		draw_circle(point, 23.0 * pulse, Color(0.95, 0.78, 0.35, 0.18))
		draw_circle(point, 15.0 * pulse, Color("f6d77b") if activated else Color("fff3c7"))
		draw_circle(point, 9.0, Color("83bd79") if activated else Color("d9a55f"))
		_draw_text_center("✓" if activated else "路标", point + Vector2(-22, 5), 12, INK, 44)
	var stars := _star_positions()
	for index in range(stars.size()):
		if not stars_collected[index]:
			var star := stars[index] + PLAYER_FOOT + Vector2(0, -12)
			var vertices := PackedVector2Array()
			for vertex in range(10):
				var radius := 10.0 if vertex % 2 == 0 else 4.5
				var angle := -PI * 0.5 + float(vertex) * PI / 5.0
				vertices.append(star + Vector2(cos(angle), sin(angle)) * radius)
			draw_colored_polygon(vertices, Color("ffdf79"))
	var hurdle := _low_hurdle_position() + PLAYER_FOOT
	_draw_shadow(hurdle + Vector2(0, 12), Vector2(32, 10))
	var route := _race_points()
	var across_route := (route[4] - route[2]).angle() + PI * 0.5
	draw_set_transform(world_offset + hurdle * world_scale, across_route, Vector2.ONE * world_scale)
	draw_texture_rect(MeadowLog, Rect2(-46, -12, 92, 24), false)
	draw_set_transform(world_offset, 0.0, Vector2.ONE * world_scale)
	_draw_rounded_rect(Rect2(hurdle + Vector2(-38, -47), Vector2(76, 22)), Color("fff7df"), Color("d8bc71"), 10)
	_draw_text_center("跳一下", hurdle + Vector2(-38, -31), 13, INK, 76)
	var high := _high_log_position() + PLAYER_FOOT
	_draw_rounded_rect(Rect2(high + Vector2(-39, -61), Vector2(78, 22)), Color("fff7df"), Color("d8bc71"), 10)
	_draw_text_center("右侧绕行 →", high + Vector2(-39, -45), 13, INK, 78)

func _draw_race_front() -> void:
	var obstacle_center := _high_log_position() + PLAYER_FOOT
	_draw_shadow(obstacle_center + Vector2(0, 12), Vector2(28, 9))
	var obstacle_rect := Rect2(obstacle_center - Vector2(30.0, 17.0), Vector2(60.0, 34.0))
	draw_texture_rect(MeadowLog, obstacle_rect, false)

func _draw_prepare_card(view: Vector2) -> void:
	var output_size := _physical_viewport_size()
	var scale_factor := get_viewport_rect().size.y / maxf(output_size.y, 1.0)
	draw_rect(Rect2(Vector2.ZERO, view), Color(0.08, 0.18, 0.13, 0.18), true)
	var rect := Rect2((output_size * 0.5 - Vector2(290, 150)) * scale_factor, Vector2(580, 300) * scale_factor)
	_draw_rounded_rect(rect, Color("fff8e5"), Color("d9b761"), 30.0 * scale_factor)
	_draw_text_center("准备好了吗？", rect.position + Vector2(0, 54 * scale_factor), roundi(30 * scale_factor), Color("345c42"), rect.size.x)
	_draw_text_center("沿着彩虹小路，安全绕过或跳过障碍。", rect.position + Vector2(0, 88 * scale_factor), roundi(17 * scale_factor), Color("66805c"), rect.size.x)
	var icon_y := rect.position.y + 130.0 * scale_factor
	var center_x := rect.position.x + rect.size.x * 0.5
	for index in range(3):
		var center := Vector2(center_x + (index - 1) * 145.0 * scale_factor, icon_y)
		draw_circle(center, 31.0 * scale_factor, Color("e9efcf"))
		if index == 0:
			draw_circle(center, 13.0 * scale_factor, Color("7fb47a"))
			draw_circle(center + Vector2(0, -21) * scale_factor, 6.0 * scale_factor, Color("fff7df"))
			_draw_text_center("移动", center + Vector2(-40, 54) * scale_factor, roundi(14 * scale_factor), INK, 80 * scale_factor)
		elif index == 1:
			_draw_text_center("跳", center + Vector2(-28, 10) * scale_factor, roundi(24 * scale_factor), Color("8b6443"), 56 * scale_factor)
			_draw_text_center("Space", center + Vector2(-40, 54) * scale_factor, roundi(13 * scale_factor), INK, 80 * scale_factor)
		else:
			draw_arc(center + Vector2(0, 5), 22.0 * scale_factor, PI, TAU, 24, Color("e76d72"), 5.0 * scale_factor)
			draw_arc(center + Vector2(0, 5), 28.0 * scale_factor, PI, TAU, 24, Color("f3d46f"), 5.0 * scale_factor)
			_draw_text_center("终点", center + Vector2(-40, 54) * scale_factor, roundi(14 * scale_factor), INK, 80 * scale_factor)

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
	_draw_text_center("挑战完成！", rect.position + Vector2(0, 67 * scale_factor), roundi(31 * scale_factor), Color("345c42"), rect.size.x)
	_draw_text_center("本次用时：" + _format_race_time(race_elapsed_at_finish), rect.position + Vector2(0, 109 * scale_factor), roundi(21 * scale_factor), Color("66805c"), rect.size.x)
	_draw_text_center("彩虹星：%d / 5" % _star_count(), rect.position + Vector2(0, 129 * scale_factor), roundi(14 * scale_factor), Color("a07c3e"), rect.size.x)
	if session_best_time > 0.0:
		_draw_text_center(("新纪录！" if best_is_new else "个人最佳：") + _format_race_time(session_best_time), rect.position + Vector2(0, 145 * scale_factor), roundi(14 * scale_factor), Color("a07c3e"), rect.size.x)
	for i in range(11):
		var x := rect.position.x + (30.0 + float(i * 41)) * scale_factor
		var y := rect.position.y + (22.0 + fposmod(float(i * 17) + celebration_time * (16.0 + i), 43.0)) * scale_factor
		draw_colored_polygon(PackedVector2Array([Vector2(x, y - 5 * scale_factor), Vector2(x + 2 * scale_factor, y), Vector2(x + 7 * scale_factor, y + scale_factor), Vector2(x + 3 * scale_factor, y + 4 * scale_factor), Vector2(x + 2 * scale_factor, y + 9 * scale_factor), Vector2(x - scale_factor, y + 5 * scale_factor), Vector2(x - 6 * scale_factor, y + 2 * scale_factor), Vector2(x - scale_factor, y)]), [Color("ef9c88"), Color("75b8d2"), Color("e8c56b"), Color("8abe74")][i % 4])

func _draw_player() -> void:
	var foot := player_position + PLAYER_FOOT
	# World artwork must share the map scale. UI scaling is for screen
	# controls only; applying it here enlarges the player on narrow phones.
	var character_scale := 0.30
	var jump_height := jump_motion.height() if screen in [Screen.RACE, Screen.PAUSED] else 0.0
	var shadow_scale := clampf(1.0 - jump_height / 170.0, 0.62, 1.0)
	_draw_shadow(foot + Vector2(2, 3), Vector2(20, 6) * shadow_scale)
	var texture: Texture2D = player_animation.current_texture()
	if texture == null:
		texture = MouseArt
	if jump_motion.just_landed and screen == Screen.RACE:
		draw_circle(foot, 25.0, Color(1.0, 0.94, 0.62, 0.28))
	draw_texture_rect(texture, Rect2(foot - Vector2(128, 232) * character_scale - Vector2(0, jump_height), Vector2(256, 256) * character_scale), false)

func _draw_ui(view: Vector2) -> void:
	var output_size := _physical_viewport_size()
	var scale_factor := get_viewport_rect().size.y / maxf(output_size.y, 1.0)
	_draw_rounded_rect(Rect2(Vector2(16, 15) * scale_factor, Vector2(minf(output_size.x * 0.38, 480), 72) * scale_factor), Color(0.94, 0.96, 0.83, 0.94), Color("89b778"), 20.0 * scale_factor)
	_draw_text("欢乐竞技岛", Vector2(35, 47) * scale_factor, roundi(25 * scale_factor), INK)
	var subtitle := "选一个木牌，开始轻松挑战" if screen == Screen.HUB else ("准备开始 · 移动、跳跃、找终点" if screen == Screen.PREPARE else "彩虹草地赛 · 正式挑战")
	_draw_text(subtitle, Vector2(37, 72) * scale_factor, roundi(15 * scale_factor), Color("658061"))
	if screen == Screen.COUNTDOWN:
		_draw_text_center(str(maxi(1, ceili(countdown_remaining))), Vector2(output_size.x * 0.5 - 80.0, output_size.y * 0.47) * scale_factor, roundi(70 * scale_factor), INK, 160 * scale_factor)
	if screen == Screen.PAUSED:
		_draw_text_center("已暂停", Vector2(output_size.x * 0.5 - 100.0, output_size.y * 0.47) * scale_factor, roundi(44 * scale_factor), INK, 200 * scale_factor)
	if screen == Screen.RACE:
		var clock_rect := Rect2(Vector2(output_size.x * 0.5 - 78.0, 18.0) * scale_factor, Vector2(156.0, 58.0) * scale_factor)
		_draw_rounded_rect(clock_rect, Color("fff8e5"), Color("d8bd78"), 19.0 * scale_factor)
		_draw_text_center(("暂停 " if race_clock.paused else "用时 ") + race_clock.formatted(), clock_rect.position + Vector2(0, 37.0 * scale_factor), roundi(22.0 * scale_factor), INK, clock_rect.size.x)
	if screen == Screen.RACE:
		_draw_rounded_rect(Rect2(Vector2(16, 98) * scale_factor, Vector2(152, 43) * scale_factor), Color("fff7df", 0.88), Color("b8cc9a"), 15.0 * scale_factor)
		_draw_text("检查点 %d/2" % checkpoint_index, Vector2(31, 126) * scale_factor, roundi(15 * scale_factor), INK)
	if screen == Screen.RACE and checkpoint_hint_time > 0.0:
		var toast := Rect2(Vector2(output_size.x * 0.5 - 108.0, output_size.y * 0.23) * scale_factor, Vector2(216.0, 43.0) * scale_factor)
		_draw_rounded_rect(toast, Color("fff7df", 0.96), Color("9dca84"), 18.0 * scale_factor)
		_draw_text_center("到这里啦！", toast.position + Vector2(0, 28.0 * scale_factor), roundi(19 * scale_factor), INK, toast.size.x)
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

func _format_race_time(seconds: float) -> String:
	var total_seconds := maxi(0, floori(seconds))
	return "%02d:%02d" % [total_seconds / 60, total_seconds % 60]

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
