extends SceneTree

var failures := 0


func _init() -> void:
	var state_script = load("res://scripts/game/game_state.gd")
	if state_script == null:
		_fail("GameState script must load")
		_finish()
		return

	var locked = state_script.new()
	_expect(not locked.can_start_q010(), "Q010 must be locked before Q005 is complete")
	_expect(not locked.collect_q010_seed(0), "Q010 seeds must not be collectable before Q005")

	var state = state_script.new()
	_complete_q005(state)
	_expect(state.is_q005_complete(), "Q010 test state must have Q005 complete")
	_expect(not state.is_q004_complete(), "Q010 must not require Q004")
	_expect(not state.is_q006_complete(), "Q010 must not require Q006")
	_expect(not state.is_q007_complete(), "Q010 must not require Q007")
	_expect(not state.is_q008_complete(), "Q010 must not require Q008")
	_expect(not state.is_q009_complete(), "Q010 must not require Q009")
	_expect(state.can_start_q010(), "Q005 completion must unlock Q010")
	_expect(state.q010_seed_count() == 0, "Q010 must start with no collected seeds")
	_expect(not state.is_q010_complete(), "Q010 must start incomplete")

	_expect(not state.collect_q010_seed(-1), "invalid Q010 seed IDs must be rejected")
	_expect(not state.collect_q010_seed(3), "out-of-range Q010 seed IDs must be rejected")
	_expect(state.collect_q010_seed(1), "an unlocked Q010 seed must be collectable")
	_expect(not state.collect_q010_seed(1), "a Q010 seed must not be collected twice")
	_expect(state.q010_seed_count() == 1, "Q010 progress must count unique seeds")
	_expect(not state.is_q010_complete(), "partial Q010 progress must remain incomplete")
	_expect(state.collect_q010_seed(0), "the second Q010 seed must be collectable")
	_expect(state.collect_q010_seed(2), "the final Q010 seed must be collectable")
	_expect(state.q010_seed_count() == 3, "Q010 must count all collected seeds")
	_expect(state.is_q010_complete(), "three collected Q010 seeds must complete the task")
	_expect(not state.can_start_q010(), "a completed Q010 must not restart")
	_expect(not state.collect_q010_seed(0), "completed Q010 must reject repeated collection")

	var saved: Dictionary = state.to_save_data()
	_expect(saved.get("schema_version") == 12, "Q010 saves must use Schema 12")
	_expect(saved.get("q010_seeds_collected") == [true, true, true], "Schema 12 must save Q010 seed progress")
	_expect(not saved.has("q010_completed"), "Q010 must not save a redundant completion field")

	var restored = state_script.new()
	_expect(restored.load_save_data(saved), "a valid Schema 12 save must load")
	_expect(restored.q010_seeds_collected == [true, true, true], "Schema 12 must restore Q010 seeds")
	_expect(restored.is_q010_complete(), "Schema 12 must restore Q010 completion")

	var prior_tasks = state_script.new()
	_complete_all_prior_tasks(prior_tasks)
	var schema9_full: Dictionary = prior_tasks.to_save_data()
	schema9_full["schema_version"] = 9
	schema9_full.erase("q010_seeds_collected")
	var migrated_full = state_script.new()
	_expect(migrated_full.load_save_data(schema9_full), "Schema 9 with prior task progress must migrate")
	_expect(migrated_full.is_complete(), "Schema 9 migration must preserve Q001")
	_expect(migrated_full.is_q004_complete(), "Schema 9 migration must preserve Q004")
	_expect(migrated_full.is_q005_complete(), "Schema 9 migration must preserve Q005")
	_expect(migrated_full.is_q006_complete(), "Schema 9 migration must preserve Q006")
	_expect(migrated_full.is_q007_complete(), "Schema 9 migration must preserve Q007")
	_expect(migrated_full.is_q008_complete(), "Schema 9 migration must preserve Q008")
	_expect(migrated_full.is_q009_complete(), "Schema 9 migration must preserve Q009")
	_expect(migrated_full.q010_seeds_collected == [false, false, false], "Schema 9 migration must default Q010 empty")

	for schema_version in range(1, 10):
		var old_save := _schema9_save()
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
		if schema_version < 9:
			old_save.erase("q009_materials_collected")
			old_save.erase("q009_completed")
		var migrated = state_script.new()
		_expect(migrated.load_save_data(old_save), "Schema %d must migrate to Schema 12" % schema_version)
		_expect(migrated.q010_seeds_collected == [false, false, false], "Schema %d migration must start Q010 empty" % schema_version)
		_expect(not migrated.is_q010_complete(), "Schema %d migration must leave Q010 incomplete" % schema_version)

	var invalid = saved.duplicate(true)
	invalid["q010_seeds_collected"] = [true, true]
	_expect(not restored.load_save_data(invalid), "invalid Q010 array lengths must be rejected")
	_expect(restored.is_q010_complete(), "rejected Q010 data must not partially mutate state")

	invalid = saved.duplicate(true)
	invalid["q010_seeds_collected"] = [true, "bad", true]
	_expect(not restored.load_save_data(invalid), "invalid Q010 seed types must be rejected")
	_expect(restored.is_q010_complete(), "rejected Q010 types must not partially mutate state")

	invalid = saved.duplicate(true)
	invalid["q010_seeds_collected"] = [true, false, false]
	invalid["pond_stones_placed"] = [false, false, false]
	invalid["pond_opened"] = false
	invalid["q005_watered"] = false
	invalid["q005_plants_collected"] = [false, false, false]
	invalid["q005_plant_slots"] = [false, false, false]
	invalid["q005_completed"] = false
	_expect(not restored.load_save_data(invalid), "Q010 progress without Q005 must be rejected")
	_expect(restored.is_q010_complete(), "invalid prerequisite data must not partially mutate state")

	state.reset()
	_expect(state.q010_seeds_collected == [false, false, false], "reset must clear Q010 seeds")
	_expect(not state.is_q010_complete(), "reset must clear Q010 completion")
	_expect(not state.can_start_q010(), "reset must lock Q010")

	_finish()


func _complete_q005(state) -> void:
	for board_id in range(3):
		state.collect_board(board_id)
		state.place_board(board_id, board_id)
	state.collect_seed()
	state.plant_seed()
	for stone_id in range(3):
		state.place_pond_stone(stone_id)
	state.water_q005()
	for plant_id in range(3):
		state.collect_q005_plant(plant_id)
		state.place_q005_plant(plant_id, plant_id)


func _complete_all_prior_tasks(state) -> void:
	_complete_q005(state)
	for wood_id in range(3):
		state.collect_wood(wood_id)
		state.deliver_wood(wood_id)
	for decor_id in range(3):
		state.place_q006_decoration(decor_id, decor_id)
	state.collect_q007_shell()
	for material_id in range(3):
		state.place_q008_path(material_id, material_id)
	for material_id in range(3):
		state.collect_q009_material(material_id)


func _schema9_save() -> Dictionary:
	return {
		"schema_version": 9,
		"collected": [true, true, true],
		"placed": [true, true, true],
		"quest_completed": true,
		"bridge_repaired": true,
		"area_unlocked": true,
		"seed_collected": true,
		"seed_planted": true,
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
		"q009_materials_collected": [false, false, false],
		"q009_completed": false,
	}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	failures += 1
	push_error("[Q010StateTest] " + message)


func _finish() -> void:
	if failures == 0:
		print("[Q010StateTest] PASS")
	else:
		push_error("[Q010StateTest] FAIL: %d assertions" % failures)
	quit(failures)
