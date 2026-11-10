extends SceneTree

var failures: Array[String] = []
var session: Control
var island: Control
var close_count := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/competition/CompetitionSession.tscn") as PackedScene
	_expect(packed != null, "V2.0 competition scene loads")
	if packed == null:
		_quit_with_report()
		return
	session = packed.instantiate() as Control
	root.add_child(session)
	session.close_requested.connect(_on_close_requested)
	await process_frame
	_expect(session.get("screen") == 0, "session opens in the hub")
	_expect(session.call("_nearest_hub_entry") == "exit", "hub spawn is beside the life-island bridge exit")
	_expect(not session.get("action_button").visible, "hub does not duplicate the persistent life-island exit button")
	session.set("player_position", Vector2(640.0, 242.0))
	_expect(session.call("_nearest_hub_entry") == "single", "single-player entrance is reachable")
	session.call("_update_buttons")
	_expect(session.get("action_button").visible, "single-player action appears at the race entrance")
	session.call("_on_action_pressed")
	_expect(session.get("screen") == 1, "single-player entrance opens the R01 briefing")
	_expect(not session.get("race_clock").running, "race clock stays stopped during the briefing")
	_expect(session.get("action_button").text == "开始挑战", "briefing offers a clear start action")
	session.call("_on_action_pressed")
	_expect(session.get("screen") == 2, "start action begins the timed R01 race")
	_expect(session.get("player_position") == session.call("_race_start_position"), "R01 starts at the start line")
	_expect(session.get("race_clock").running, "clock starts only after the player starts")
	await create_timer(0.08).timeout
	_expect(session.get("race_clock").elapsed_seconds() > 0.0, "race clock uses elapsed monotonic time")
	session.call("_notification", Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	var paused_time: float = session.get("race_clock").elapsed_seconds()
	await create_timer(0.08).timeout
	_expect(session.get("race_clock").paused and absf(session.get("race_clock").elapsed_seconds() - paused_time) < 0.025, "window focus loss pauses the race timer")
	session.call("_notification", Node.NOTIFICATION_WM_WINDOW_FOCUS_IN)
	_expect(not session.get("race_clock").paused and session.get("race_clock").running, "window focus regain resumes the race timer")
	var jump = session.get("jump_motion")
	_expect(jump.start(), "jump can be started on the ground")
	jump.advance(jump.duration * 0.5)
	_expect(jump.height() >= 50.0, "jump has a distinct airborne height")
	var before_air_move: Vector2 = session.get("player_position")
	Input.action_press("move_right")
	session.call("_physics_process", 0.05)
	Input.action_release("move_right")
	_expect(session.get("player_position") != before_air_move and jump.active, "movement remains available during a jump")
	var low_hurdle: Vector2 = session.call("_low_hurdle_position")
	_expect(not session.call("_blocked_by_obstacle", low_hurdle, session.get("player_position")), "airborne player can cross the low hurdle")
	jump.advance(jump.duration * 0.5)
	_expect(not jump.active and jump.just_landed, "jump reaches the landing state")
	var low_hurdle_inside: Vector2 = low_hurdle + Vector2(8.0, 0.0)
	session.set("player_position", low_hurdle_inside)
	_expect(not session.call("_blocked_by_obstacle", low_hurdle_inside + Vector2(10.0, 0.0), low_hurdle_inside), "player can walk out after landing inside the low-hurdle radius")
	_expect(session.call("_blocked_by_obstacle", low_hurdle_inside - Vector2(4.0, 0.0), low_hurdle_inside), "ground movement cannot push farther into the low hurdle")
	jump.start()
	jump.advance(jump.duration * 0.5)
	var high_log: Vector2 = session.call("_high_log_position")
	_expect(session.call("_blocked_by_obstacle", high_log, session.get("player_position")), "jumping does not disable high-log collision")
	jump.active = false
	session.set("player_position", session.call("_checkpoint_positions")[0])
	session.call("_update_checkpoints")
	_expect(session.get("checkpoint_index") == 1, "middle checkpoint activates at its route marker")
	var elapsed_before_recovery: float = session.get("race_clock").elapsed_seconds()
	session.call("_return_to_checkpoint")
	_expect(session.get("player_position") == session.get("race_checkpoint"), "manual recovery returns to the latest safe marker")
	_expect(session.get("race_clock").elapsed_seconds() >= elapsed_before_recovery, "checkpoint recovery preserves the running timer")
	session.set("player_position", session.call("_race_finish_position"))
	session.call("_physics_process", 1.0 / 60.0)
	_expect(session.get("screen") == 3, "reaching the goal opens the result card")
	_expect(not session.get("race_clock").running, "finishing stops the race clock")
	_expect(session.get("race_elapsed_at_finish") > 0.0, "finish records the current run time")
	_expect(session.get("replay_button").visible, "finish offers a replay")
	_expect(session.get("return_hub_button").visible, "finish offers a return to the hub")
	session.call("_start_race")
	_expect(session.get("screen") == 2 and session.get("checkpoint_index") == 0, "replay resets race and checkpoint state")
	_expect(session.get("jump_motion").height() == 0.0, "replay clears airborne state")
	session.call("_return_to_hub")
	_expect(session.get("screen") == 0 and not session.get("race_clock").running, "returning to the hub releases race state")
	session.set("player_position", Vector2(320.0, 270.0))
	session.call("_on_action_pressed")
	_expect(str(session.get("message")).contains("准备比赛"), "AI entrance is clearly marked as unavailable")
	session.set("player_position", Vector2(998.0, 285.0))
	session.call("_on_action_pressed")
	_expect(str(session.get("message")).contains("好友竞技即将开放"), "friends entrance is clearly marked as unavailable")
	session.call("_on_back_pressed")
	_expect(close_count == 1, "hub can return to the life island")
	if session != null and is_instance_valid(session):
		session.queue_free()
	await process_frame
	var main_script := load("res://scripts/boot/main.gd") as Script
	island = main_script.new() as Control
	root.add_child(island)
	await process_frame
	var state = island.get("game_state")
	state.reset()
	island.set("player_position", Vector2(150.0, 520.0))
	island.call("_update_interact_button")
	_expect(island.get("interaction_button_label") == "先修小桥", "life-island gate explains Q001 lock")
	island.call("_try_collect_nearby")
	_expect(island.get("competition_session") == null, "unfinished Q001 cannot enter competition")
	for board_id in range(3):
		state.collect_board(board_id)
		state.place_board(board_id, board_id)
	island.call("_update_interact_button")
	_expect(island.get("interaction_button_label") == "去竞技岛", "Q001 completion unlocks the gate")
	island.call("_try_collect_nearby")
	var opened = island.get("competition_session")
	_expect(opened != null, "life island enters the separate competition session")
	_expect(state.is_complete() and not state.is_q012_complete(), "competition entry leaves first-stage quest state intact")
	if opened != null:
		opened.emit_signal("close_requested")
	_expect(island.get("competition_session") == null, "competition returns to the existing life-island scene")
	island.queue_free()
	await process_frame
	_quit_with_report()

func _on_close_requested() -> void:
	close_count += 1

func _expect(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		failures.append(description)
		push_error("FAIL: " + description)

func _quit_with_report() -> void:
	if failures.is_empty():
		print("COMPETITION TESTS PASS")
	else:
		printerr("COMPETITION TESTS FAIL: %d/%d" % [failures.size(), 12])
	quit(0 if failures.is_empty() else 1)
