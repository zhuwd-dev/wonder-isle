extends SceneTree

var failures := 0


func _init() -> void:
	var state_script = load("res://scripts/game/game_state.gd")
	if state_script == null:
		_fail("GameState script must load")
		_finish()
		return

	var locked = state_script.new()
	_expect(not locked.can_start_q007(), "Q007 must be locked before the pond opens")
	_expect(not locked.collect_q007_shell(), "the shell must not be collectable before the pond opens")

	var state = state_script.new()
	_complete_q003(state)
	_expect(state.can_start_q007(), "the pond opening must unlock Q007")
	_expect(not state.is_q004_complete(), "Q007 must not require Q004")
	_expect(not state.is_q005_complete(), "Q007 must not require Q005")
	_expect(not state.is_q006_complete(), "Q007 must not require Q006")
	_expect(not state.is_q007_complete(), "Q007 must be incomplete before collecting the shell")
	_expect(state.collect_q007_shell(), "the hidden shell must be collectable after the pond opens")
	_expect(state.q007_shell_collected, "collecting the shell must persist its collected state")
	_expect(state.q007_completed, "collecting the shell must complete Q007")
	_expect(state.q007_reward_unlocked, "collecting the shell must unlock the reward")
	_expect(state.is_q007_complete(), "collecting the shell must complete Q007")
	_expect(not state.collect_q007_shell(), "the shell must not be collected twice")

	var saved: Dictionary = state.to_save_data()
	_expect(saved.get("schema_version") == 12, "Q007 must use Schema 12")
	_expect(saved.get("q007_shell_collected") == true, "Schema 12 must save shell collection")
	_expect(saved.get("q007_completed") == true, "Schema 12 must save Q007 completion")
	_expect(saved.get("q007_reward_unlocked") == true, "Schema 12 must save the Q007 reward")

	var restored = state_script.new()
	_expect(restored.load_save_data(saved), "a valid Schema 12 save must load")
	_expect(restored.is_q007_complete(), "Schema 12 must restore Q007 completion")

	for schema_version in range(1, 8):
		var old_save := _schema6_save()
		old_save["schema_version"] = schema_version
		if schema_version < 2:
			old_save.erase("seed_collected")
			old_save.erase("seed_planted")
		if schema_version < 3:
			old_save.erase("pond_stones_placed")
			old_save.erase("pond_opened")
		if schema_version < 4:
			old_save.erase("wood_collected")
			old_save.erase("wood_delivered")
			old_save.erase("q004_completed")
			old_save.erase("fox_moved_in")
		if schema_version < 5:
			old_save.erase("q005_watered")
			old_save.erase("q005_plants_collected")
			old_save.erase("q005_plant_slots")
			old_save.erase("q005_completed")
		if schema_version < 6:
			old_save.erase("q006_decor_inventory")
			old_save.erase("q006_decor_placed")
			old_save.erase("q006_slot_occupants")
			old_save.erase("q006_completion_proof")
			old_save.erase("q006_completed")
			old_save.erase("q006_windmill_unlocked")
		if schema_version < 7:
			old_save.erase("q007_shell_collected")
			old_save.erase("q007_completed")
			old_save.erase("q007_reward_unlocked")
		var migrated = state_script.new()
		_expect(migrated.load_save_data(old_save), "Schema %d must migrate to Schema 12" % schema_version)
		_expect(not migrated.q007_shell_collected, "Schema %d migration must not collect Q007 shell" % schema_version)
		_expect(not migrated.q007_completed, "Schema %d migration must not complete Q007" % schema_version)
		_expect(not migrated.q007_reward_unlocked, "Schema %d migration must not grant Q007 reward" % schema_version)

	var invalid = saved.duplicate(true)
	invalid["q007_completed"] = true
	invalid["q007_shell_collected"] = false
	_expect(not restored.load_save_data(invalid), "inconsistent Q007 completion must be rejected")
	_expect(restored.is_q007_complete(), "rejected Q007 data must not partially mutate state")

	invalid = saved.duplicate(true)
	invalid["q007_reward_unlocked"] = false
	_expect(not restored.load_save_data(invalid), "completed Q007 without reward must be rejected")
	_expect(restored.is_q007_complete(), "rejected reward data must not partially mutate state")

	invalid = saved.duplicate(true)
	invalid["q007_reward_unlocked"] = "true"
	_expect(not restored.load_save_data(invalid), "invalid Q007 field types must be rejected")
	_expect(restored.is_q007_complete(), "rejected Q007 type data must not partially mutate state")

	invalid = saved.duplicate(true)
	invalid["pond_opened"] = false
	_expect(not restored.load_save_data(invalid), "Q007 completion without an open pond must be rejected")

	state.reset()
	_expect(not state.q007_shell_collected, "reset must clear Q007 shell collection")
	_expect(not state.q007_completed, "reset must clear Q007 completion")
	_expect(not state.q007_reward_unlocked, "reset must clear Q007 reward")

	_finish()


func _complete_q003(state) -> void:
	for board_id in range(3):
		state.collect_board(board_id)
		state.place_board(board_id, board_id)
	state.collect_seed()
	state.plant_seed()
	for stone_id in range(3):
		state.place_pond_stone(stone_id)


func _schema6_save() -> Dictionary:
	return {
		"schema_version": 6,
		"collected": [true, true, true],
		"placed": [true, true, true],
		"quest_completed": true,
		"bridge_repaired": true,
		"area_unlocked": true,
		"seed_collected": true,
		"seed_planted": true,
		"pond_stones_placed": [true, true, true],
		"pond_opened": true,
		"wood_collected": [true, true, true],
		"wood_delivered": [true, true, true],
		"q004_completed": true,
		"fox_moved_in": true,
		"q005_watered": true,
		"q005_plants_collected": [true, true, true],
		"q005_plant_slots": [true, true, true],
		"q005_completed": true,
		"q006_decor_inventory": [false, false, false],
		"q006_decor_placed": [true, true, true],
		"q006_slot_occupants": [0, 1, 2],
		"q006_completion_proof": [true, true, true],
		"q006_completed": true,
		"q006_windmill_unlocked": true,
		"q007_shell_collected": false,
		"q007_completed": false,
		"q007_reward_unlocked": false,
	}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	failures += 1
	push_error("[Q007StateTest] " + message)


func _finish() -> void:
	if failures == 0:
		print("[Q007StateTest] PASS")
	else:
		push_error("[Q007StateTest] FAIL: %d assertions" % failures)
	quit(failures)
