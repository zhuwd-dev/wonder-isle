extends SceneTree

var errors: Array[String] = []
func check(ok: bool, label: String) -> void:
	if ok:
		print("PASS: ", label)
	else:
		errors.append(label)
		push_error("FAIL: " + label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var node = load("res://scenes/competition/CompetitionSession.tscn").instantiate()
	root.add_child(node)
	await process_frame
	node.set_physics_process(false)
	node.call("_start_race")
	var start: Vector2 = node.player_position
	Input.action_press("move_right")
	node.call("_physics_process", 1.0)
	Input.action_release("move_right")
	check(node.screen == node.Screen.COUNTDOWN and node.player_position == start and not node.race_clock.running, "countdown blocks movement and timer")
	node.call("_physics_process", 2.1)
	check(node.screen == node.Screen.RACE and node.race_clock.running, "countdown starts clock once")
	Input.action_press("move_right")
	node.touch_direction = Vector2.RIGHT
	node.call("_toggle_pause")
	var paused_position: Vector2 = node.player_position
	var paused_time: float = node.race_clock.elapsed_seconds()
	node.call("_physics_process", 0.2)
	node.call("_notification", Node.NOTIFICATION_WM_WINDOW_FOCUS_IN)
	check(node.screen == node.Screen.PAUSED and node.race_clock.paused and node.player_position == paused_position and absf(node.race_clock.elapsed_seconds() - paused_time) < 0.02 and node.touch_direction == Vector2.ZERO and not Input.is_action_pressed("move_right"), "manual pause freezes race and clears input even on focus regain")
	node.call("_toggle_pause")
	check(node.screen == node.Screen.RACE and node.race_clock.running and not node.race_clock.paused, "resume continues the same race")
	var route: PackedVector2Array = node.call("_race_points")
	var first: Vector2 = route[10]
	var second: Vector2 = route[21]
	var d1: Vector2 = (route[11] - route[9]).normalized()
	var d2: Vector2 = (route[22] - route[20]).normalized()
	node.last_player_position = second - d2 * 4
	node.player_position = second + d2 * 4
	node.call("_update_checkpoints")
	check(node.checkpoint_index == 0, "second checkpoint cannot activate first")
	node.last_player_position = first - d1 * 4
	node.player_position = first + d1 * 4
	node.call("_update_checkpoints")
	check(node.checkpoint_index == 1, "first checkpoint activates forward")
	node.call("_update_checkpoints")
	check(node.checkpoint_index == 1, "first checkpoint cannot be counted twice")
	node.last_player_position = second + d2 * 4
	node.player_position = second - d2 * 4
	node.call("_update_checkpoints")
	check(node.checkpoint_index == 1, "second checkpoint rejects reverse crossing")
	node.last_player_position = second - d2 * 4
	node.player_position = second + d2 * 4
	node.call("_update_checkpoints")
	check(node.checkpoint_index == 2, "second checkpoint activates forward")
	var low: Vector2 = node.call("_low_hurdle_position")
	var forward: Vector2 = (route[4] - route[2]).normalized()
	check(node.call("_blocked_by_obstacle", low + forward * 2, low - forward * 2), "low hurdle blocks grounded crossing")
	node.jump_motion.start()
	node.jump_motion.advance(node.jump_motion.duration * 0.5)
	check(not node.call("_blocked_by_obstacle", low + forward * 2, low - forward * 2), "jump clears low hurdle")
	check(node.call("_blocked_by_obstacle", node.call("_high_log_position"), low), "jump cannot clear high log")
	var finish: Vector2 = node.call("_race_finish_position")
	node.jump_motion.active = false
	node.route_segment = route.size() - 2
	node.checkpoint_index = 1
	node.player_position = finish + Vector2(-5, 5)
	Input.action_press("move_right")
	Input.action_press("move_up")
	node.call("_physics_process", 0.06)
	Input.action_release("move_right")
	Input.action_release("move_up")
	check(node.screen == node.Screen.RACE, "finish requires all checkpoints")
	node.checkpoint_index = 2
	node.player_position = finish + Vector2(5, -5)
	Input.action_press("move_left")
	Input.action_press("move_down")
	node.call("_physics_process", 0.06)
	Input.action_release("move_left")
	Input.action_release("move_down")
	check(node.screen == node.Screen.RACE, "finish rejects reverse crossing")
	node.player_position = finish + Vector2(-5, 5)
	Input.action_press("move_right")
	Input.action_press("move_up")
	node.call("_physics_process", 0.06)
	Input.action_release("move_right")
	Input.action_release("move_up")
	check(node.screen == node.Screen.FINISH and not node.race_clock.running, "forward finish stops clock after all checkpoints")
	node.call("_start_race")
	check(node.checkpoint_index == 0 and node.route_segment == 0 and not node.race_clock.running and node.call("_star_count") == 0, "replay resets race, stars and clock")
	node.queue_free()
	await process_frame
	print("R01 RULE GUARDS: ", "PASS" if errors.is_empty() else "FAIL")
	quit(0 if errors.is_empty() else 1)
