extends SceneTree

var failures := 0


func _init() -> void:
	var state_script = load("res://scripts/game/game_state.gd")
	if state_script == null:
		_fail("GameState script must load")
		_finish()
		return

	var locked = state_script.new()
	_expect(not locked.can_start_q008(), "Q008 must be locked before the bridge is repaired")
	_expect(not locked.place_q008_path(0, 0), "Q008 placement must be locked before the bridge is repaired")

	var state = state_script.new()
	_complete_bridge(state)
	_expect(state.is_complete(), "Q008 test state must have a repaired bridge")
	_expect(not state.seed_planted, "Q008 must not require Q002")
	_expect(not state.is_pond_complete(), "Q008 must not require Q003")
	_expect(not state.is_q004_complete(), "Q008 must not require Q004")
	_expect(not state.is_q005_complete(), "Q008 must not require Q005")
	_expect(not state.is_q006_complete(), "Q008 must not require Q006")
	_expect(not state.is_q007_complete(), "Q008 must not require Q007")
	_expect(state.can_start_q008(), "Q001 completion must unlock Q008")
	_expect(state.q008_path_material_is_available(0), "an unlocked path material must be available")
	_expect(state.can_place_q008_path(0, 0), "an empty Q008 slot must accept an available material")
	_expect(not state.can_place_q008_path(9, 0), "an invalid Q008 material ID must be rejected")
	_expect(not state.can_place_q008_path(0, 9), "an invalid Q008 slot ID must be rejected")

	_expect(state.place_q008_path(2, 1), "a material must be placeable in any empty slot")
	_expect(state.q008_path_slot_occupants == [-1, 2, -1], "the first Q008 placement must occupy the selected slot")
	_expect(state.q008_path_placed_count() == 1, "Q008 placement count must track partial progress")
	_expect(not state.place_q008_path(2, 0), "the same material must not occupy two Q008 slots")
	_expect(not state.place_q008_path(0, 1), "an occupied Q008 slot must reject another material")
	_expect(state.place_q008_path(0, 2), "a second material must be placeable in another empty slot")
	_expect(state.place_q008_path(1, 0), "the final material must be placeable in the remaining slot")
	_expect(state.q008_path_slot_occupants == [1, 2, 0], "Q008 placements must preserve the material IDs")
	_expect(state.q008_completed, "three occupied Q008 slots must complete the task")
	_expect(state.is_q008_complete(), "three occupied Q008 slots must make Q008 complete")
	_expect(not state.can_start_q008(), "a completed Q008 must not restart")
	_expect(not state.place_q008_path(0, 0), "a completed Q008 must reject repeated placement")

	var saved: Dictionary = state.to_save_data()
	_expect(saved.get("schema_version") == 12, "Q008 saves must use Schema 12")
	_expect(saved.get("q008_path_slot_occupants") == [1, 2, 0], "Schema 12 must save Q008 slot occupants")
	_expect(saved.get("q008_completed") == true, "Schema 12 must save Q008 completion")

	var restored = state_script.new()
	_expect(restored.load_save_data(saved), "a valid Schema 12 save must load")
	_expect(restored.q008_path_slot_occupants == [1, 2, 0], "Schema 12 must restore Q008 slots")
	_expect(restored.is_q008_complete(), "Schema 12 must restore Q008 completion")

	for schema_version in range(1, 8):
		var old_save := _schema7_save()
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
		_expect(migrated.is_complete(), "Schema %d migration must preserve Q001" % schema_version)
		_expect(migrated.q008_path_slot_occupants == [-1, -1, -1], "Schema %d migration must start Q008 empty" % schema_version)
		_expect(not migrated.q008_completed, "Schema %d migration must leave Q008 incomplete" % schema_version)

	var invalid = saved.duplicate(true)
	invalid["q008_path_slot_occupants"] = [0, 0, 2]
	_expect(not restored.load_save_data(invalid), "duplicate Q008 slots must be rejected")
	_expect(restored.q008_path_slot_occupants == [1, 2, 0], "rejected Q008 slots must not partially mutate state")

	invalid = saved.duplicate(true)
	invalid["q008_path_slot_occupants"] = [0, 1]
	_expect(not restored.load_save_data(invalid), "invalid Q008 slot lengths must be rejected")

	invalid = saved.duplicate(true)
	invalid["q008_path_slot_occupants"] = [0, 1, 9]
	_expect(not restored.load_save_data(invalid), "invalid Q008 material IDs must be rejected")

	invalid = saved.duplicate(true)
	invalid["q008_completed"] = false
	_expect(not restored.load_save_data(invalid), "inconsistent Q008 completion must be rejected")

	invalid = saved.duplicate(true)
	invalid["q008_path_slot_occupants"] = [0, -1, -1]
	invalid["q008_completed"] = false
	invalid["bridge_repaired"] = false
	invalid["quest_completed"] = false
	invalid["area_unlocked"] = false
	invalid["placed"] = [false, false, false]
	_expect(not restored.load_save_data(invalid), "Q008 progress without a repaired bridge must be rejected")

	state.reset()
	_expect(state.q008_path_slot_occupants == [-1, -1, -1], "reset must clear Q008 slots")
	_expect(not state.q008_completed, "reset must clear Q008 completion")
	_expect(not state.can_start_q008(), "reset must lock Q008")

	_finish()


func _complete_bridge(state) -> void:
	for board_id in range(3):
		state.collect_board(board_id)
		state.place_board(board_id, board_id)


func _schema7_save() -> Dictionary:
	return {
		"schema_version": 7,
		"collected": [true, true, true],
		"placed": [true, true, true],
		"quest_completed": true,
		"bridge_repaired": true,
		"area_unlocked": true,
		"seed_collected": false,
		"seed_planted": false,
		"pond_stones_placed": [false, false, false],
		"pond_opened": false,
		"wood_collected": [false, false, false],
		"wood_delivered": [false, false, false],
		"q004_completed": false,
		"fox_moved_in": false,
		"q005_watered": false,
		"q005_plants_collected": [false, false, false],
		"q005_plant_slots": [false, false, false],
		"q005_completed": false,
		"q006_decor_inventory": [false, false, false],
		"q006_decor_placed": [false, false, false],
		"q006_slot_occupants": [-1, -1, -1],
		"q006_completion_proof": [false, false, false],
		"q006_completed": false,
		"q006_windmill_unlocked": false,
		"q007_shell_collected": false,
		"q007_completed": false,
		"q007_reward_unlocked": false,
	}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	failures += 1
	push_error("[Q008StateTest] " + message)


func _finish() -> void:
	if failures == 0:
		print("[Q008StateTest] PASS")
	else:
		push_error("[Q008StateTest] FAIL: %d assertions" % failures)
	quit(failures)
