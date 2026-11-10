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
	_expect(session.get("screen") == 1, "single-player entrance starts R01")
	_expect(session.get("player_position") == session.call("_race_start_position"), "R01 starts at the start line")
	session.set("player_position", session.call("_race_finish_position"))
	session.call("_physics_process", 1.0 / 60.0)
	_expect(session.get("screen") == 2, "reaching the goal opens the celebration")
	_expect(session.get("replay_button").visible, "finish offers a replay")
	_expect(session.get("return_hub_button").visible, "finish offers a return to the hub")
	session.call("_return_to_hub")
	_expect(session.get("screen") == 0, "player can return to the competition hub")
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
