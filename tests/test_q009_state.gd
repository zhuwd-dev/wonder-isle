extends SceneTree

var failures := 0


func _init() -> void:
	var state_script = load("res://scripts/game/game_state.gd")
	if state_script == null:
		_fail("GameState script must load")
		_finish()
		return

	var locked = state_script.new()
	_expect(not locked.can_start_q009(), "Q009 must be locked before Q004 is complete")
	_expect(not locked.collect_q009_material(0), "Q009 materials must not be collectable before Q004")

	var state = state_script.new()
	_complete_q004(state)
	_expect(state.is_q004_complete(), "Q009 test state must have Q004 complete")
	_expect(state.can_start_q009(), "Q004 completion must unlock Q009")
	_expect(not state.seed_planted or state.is_q004_complete(), "Q009 should not add a new dependency")
	_expect(not state.is_pond_complete(), "Q009 must not require Q003")
	_expect(not state.is_q005_complete(), "Q009 must not require Q005")
	_expect(not state.is_q006_complete(), "Q009 must not require Q006")
	_expect(not state.is_q007_complete(), "Q009 must not require Q007")
	_expect(not state.is_q008_complete(), "Q009 must not require Q008")
	_expect(state.q009_material_count() == 0, "Q009 must start with no collected materials")

	_expect(not state.collect_q009_material(-1), "invalid Q009 material IDs must be rejected")
	_expect(not state.collect_q009_material(3), "out-of-range Q009 material IDs must be rejected")
	_expect(state.collect_q009_material(1), "an unlocked Q009 material must be collectable")
	_expect(not state.collect_q009_material(1), "a Q009 material must not be collected twice")
	_expect(state.q009_material_count() == 1, "Q009 material progress must count unique materials")
	_expect(not state.is_q009_complete(), "partial Q009 material progress must remain incomplete")
	_expect(state.collect_q009_material(0), "the second Q009 material must be collectable")
	_expect(state.collect_q009_material(2), "the final Q009 material must be collectable")
	_expect(not state.is_q009_complete(), "collecting materials must not auto-build the birdhouse")
	_expect(not state.q009_bird_interaction_unlocked(), "bird interaction must wait until materials are delivered")
	_expect(state.q009_material_delivery_count() == 0, "collected materials must remain undelivered")
	_expect(state.deliver_next_q009_material(), "the first birdhouse delivery must succeed")
	_expect(state.q009_material_delivery_count() == 1 and not state.is_q009_complete(), "one delivery must show visible partial progress")
	_expect(state.deliver_next_q009_material(), "the second birdhouse delivery must succeed")
	_expect(state.deliver_next_q009_material(), "the final birdhouse delivery must succeed")
	_expect(not state.deliver_next_q009_material(), "the same material cannot be delivered twice")
	_expect(state.is_q009_complete(), "three collected and delivered materials must complete the task")
	_expect(state.q009_bird_interaction_unlocked(), "Q009 completion must unlock bird interaction")
	_expect(not state.collect_q009_material(0), "completed Q009 must reject repeated collection")

	var saved: Dictionary = state.to_save_data()
	_expect(saved.get("schema_version") == 13, "Q009 saves must use Schema 13")
	_expect(saved.get("q009_materials_collected") == [true, true, true], "Schema 13 must save Q009 materials")
	_expect(saved.get("q009_materials_delivered") == [true, true, true], "Schema 13 must save birdhouse deliveries")
	_expect(saved.get("q009_completed") == true, "Schema 13 must save Q009 completion")

	var restored = state_script.new()
	_expect(restored.load_save_data(saved), "a valid Schema 13 save must load")
	_expect(restored.q009_materials_collected == [true, true, true], "Schema 13 must restore Q009 materials")
	_expect(restored.is_q009_complete(), "Schema 13 must restore Q009 completion")

	for schema_version in range(1, 9):
		var old_save := _schema8_save()
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
		if schema_version < 8:
			old_save.erase("q008_path_slot_occupants")
			old_save.erase("q008_completed")
		var migrated = state_script.new()
		_expect(migrated.load_save_data(old_save), "Schema %d must migrate to Schema 13" % schema_version)
		_expect(migrated.is_q004_complete() if schema_version >= 4 else not migrated.is_q004_complete(), "Schema %d migration must preserve or default Q004" % schema_version)
		_expect(migrated.q009_materials_collected == [false, false, false], "Schema %d migration must start Q009 empty" % schema_version)
		_expect(not migrated.q009_completed, "Schema %d migration must leave Q009 incomplete" % schema_version)

	var invalid = saved.duplicate(true)
	invalid["q009_materials_collected"] = [true, true]
	_expect(not restored.load_save_data(invalid), "invalid Q009 array lengths must be rejected")
	_expect(restored.is_q009_complete(), "rejected Q009 data must not partially mutate state")

	invalid = saved.duplicate(true)
	invalid["q009_materials_collected"] = [true, "bad", true]
	_expect(not restored.load_save_data(invalid), "invalid Q009 material types must be rejected")
	_expect(restored.is_q009_complete(), "rejected Q009 types must not partially mutate state")

	invalid = saved.duplicate(true)
	invalid["q009_completed"] = false
	_expect(not restored.load_save_data(invalid), "inconsistent Q009 completion must be rejected")

	invalid = saved.duplicate(true)
	invalid["q009_materials_delivered"] = [true, false, true]
	_expect(not restored.load_save_data(invalid), "Q009 completion without all deliveries must be rejected")

	invalid = saved.duplicate(true)
	invalid["q009_materials_collected"] = [true, false, false]
	invalid["q009_completed"] = false
	invalid["q004_completed"] = false
	invalid["fox_moved_in"] = false
	invalid["wood_delivered"] = [false, false, false]
	invalid["wood_collected"] = [false, false, false]
	_expect(not restored.load_save_data(invalid), "Q009 progress without Q004 must be rejected")
	_expect(restored.is_q009_complete(), "invalid prerequisite data must not partially mutate state")

	state.reset()
	_expect(state.q009_materials_collected == [false, false, false], "reset must clear Q009 materials")
	_expect(not state.q009_completed, "reset must clear Q009 completion")
	_expect(not state.q009_bird_interaction_unlocked(), "reset must clear bird interaction")

	_finish()


func _complete_q004(state) -> void:
	for board_id in range(3):
		state.collect_board(board_id)
		state.place_board(board_id, board_id)
	state.collect_seed()
	state.plant_seed()
	for wood_id in range(3):
		state.collect_wood(wood_id)
		state.deliver_wood(wood_id)


func _schema8_save() -> Dictionary:
	return {
		"schema_version": 8,
		"collected": [true, true, true],
		"placed": [true, true, true],
		"quest_completed": true,
		"bridge_repaired": true,
		"area_unlocked": true,
		"seed_collected": true,
		"seed_planted": true,
		"pond_stones_placed": [false, false, false],
		"pond_opened": false,
		"wood_collected": [true, true, true],
		"wood_delivered": [true, true, true],
		"q004_completed": true,
		"fox_moved_in": true,
		"q005_watered": false,
		"q005_plants_collected": [false, false, false],
		"q005_plant_slots": [false, false, false],
		"q005_completed": false,
		"q006_decor_inventory": [true, true, true],
		"q006_decor_placed": [false, false, false],
		"q006_slot_occupants": [-1, -1, -1],
		"q006_completion_proof": [false, false, false],
		"q006_completed": false,
		"q006_windmill_unlocked": false,
		"q007_shell_collected": false,
		"q007_completed": false,
		"q007_reward_unlocked": false,
		"q008_path_slot_occupants": [-1, -1, -1],
		"q008_completed": false,
	}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	failures += 1
	push_error("[Q009StateTest] " + message)


func _finish() -> void:
	if failures == 0:
		print("[Q009StateTest] PASS")
	else:
		push_error("[Q009StateTest] FAIL: %d assertions" % failures)
	quit(failures)
