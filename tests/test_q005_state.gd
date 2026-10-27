extends SceneTree

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var state_script = load("res://scripts/game/game_state.gd")
	var locked = state_script.new()
	_expect(not locked.can_start_q005(), "Q005 must be locked before Q003")
	_expect(not locked.water_q005(), "Q005 watering must be locked before Q003")
	_expect(not locked.collect_q005_plant(0), "Q005 plants must be locked before Q003")
	_expect(not locked.place_q005_plant(0, 0), "Q005 slots must be locked before Q003")

	var state = state_script.new()
	_complete_q003(state)
	_expect(state.can_start_q005(), "Q003 completion must unlock Q005")
	_expect(not state.is_q005_complete(), "newly unlocked Q005 must be incomplete")
	_expect(not state.q005_watered, "new Q005 must not be watered")
	_expect(not state.collect_q005_plant(0), "plants must not be collectible before watering")
	_expect(not state.place_q005_plant(0, 0), "plant slots must not accept plants before watering")
	_expect(state.water_q005(), "the garden must be waterable once after Q003")
	_expect(not state.water_q005(), "watering must not repeat")
	_expect(state.collect_q005_plant(0), "watering must unlock plant collection")
	_expect(not state.collect_q005_plant(0), "the same plant must not be collected twice")
	_expect(not state.place_q005_plant(1, 1), "an uncollected plant must not be placed")
	_expect(not state.place_q005_plant(0, 1), "a plant must only enter its matching slot")
	_expect(state.place_q005_plant(0, 0), "the first collected plant must enter its matching slot")
	_expect(not state.place_q005_plant(0, 0), "the same plant and slot must not be counted twice")
	_expect(not state.is_q005_complete(), "Q005 must not complete before all plants are placed")
	_expect(state.collect_q005_plant(1), "the second plant must be collectible")
	_expect(state.collect_q005_plant(2), "the third plant must be collectible")
	_expect(state.place_q005_plant(1, 1), "the second plant must enter its matching slot")
	_expect(not state.is_q005_complete(), "Q005 must remain incomplete until all plants are placed")
	_expect(state.place_q005_plant(2, 2), "the final plant must enter its matching slot")
	_expect(state.is_q005_complete(), "watering and three placed plants must complete Q005")
	_expect(not state.can_start_q005(), "completed Q005 must not restart")

	var q004_independent = state_script.new()
	_complete_q002(q004_independent)
	for wood_id in range(state_script.Q004_WOOD_TOTAL):
		_expect(q004_independent.collect_wood(wood_id), "Q004 setup wood must be collectible")
		_expect(q004_independent.deliver_wood(wood_id), "Q004 setup wood must be deliverable")
	_expect(q004_independent.is_q004_complete(), "Q004 setup must complete Q004")
	for stone_id in range(state_script.POND_STONE_TOTAL):
		_expect(q004_independent.place_pond_stone(stone_id), "Q003 setup stone must be placeable")
	_expect(q004_independent.can_start_q005(), "Q005 must not depend on Q004")

	var saved: Dictionary = state.to_save_data()
	_expect(saved.get("schema_version") == 12, "Q005 save must use Schema 12")
	_expect(saved.get("q005_watered") == true, "Schema 12 must save watering")
	_expect(saved.get("q005_plants_collected") == [true, true, true], "Schema 12 must save plant collection")
	_expect(saved.get("q005_plant_slots") == [true, true, true], "Schema 12 must save plant slots")
	_expect(saved.get("q005_completed") == true, "Schema 12 must save Q005 completion")
	var restored = state_script.new()
	_expect(restored.load_save_data(saved), "a completed Q005 save must load")
	_expect(restored.is_q005_complete(), "a completed Q005 save must restore completion")

	var schema4_save := _schema4_save()
	var migrated = state_script.new()
	_expect(migrated.load_save_data(schema4_save), "Schema 4 must migrate to Q005")
	_expect(migrated.is_pond_complete(), "Schema 4 pond state must be preserved")
	_expect(not migrated.q005_watered, "Schema 4 watering must default to false")
	_expect(migrated.q005_plants_collected == [false, false, false], "Schema 4 plants must default empty")
	_expect(migrated.q005_plant_slots == [false, false, false], "Schema 4 slots must default empty")
	_expect(not migrated.is_q005_complete(), "Schema 4 must not unlock Q005 completion")
	_expect(migrated.to_save_data().get("schema_version") == 12, "migrated Schema 4 must save as Schema 12")

	var schema1_migrated = state_script.new()
	_expect(schema1_migrated.load_save_data({
		"schema_version": 1,
		"collected": [true, false, false],
		"placed": [false, false, false],
		"quest_completed": false,
		"bridge_repaired": false,
		"area_unlocked": false,
	}), "Schema 1 must migrate to Q005")
	_expect(not schema1_migrated.can_start_q005(), "Schema 1 migration must keep Q005 locked")

	var schema2_migrated = state_script.new()
	_expect(schema2_migrated.load_save_data({
		"schema_version": 2,
		"collected": [true, true, true],
		"placed": [true, true, true],
		"quest_completed": true,
		"bridge_repaired": true,
		"area_unlocked": true,
		"seed_collected": true,
		"seed_planted": true,
	}), "Schema 2 must migrate to Q005")
	_expect(schema2_migrated.seed_planted and not schema2_migrated.can_start_q005(), "Schema 2 migration must preserve Q002 and keep Q005 locked")

	var schema3_migrated = state_script.new()
	_expect(schema3_migrated.load_save_data({
		"schema_version": 3,
		"collected": [true, true, true],
		"placed": [true, true, true],
		"quest_completed": true,
		"bridge_repaired": true,
		"area_unlocked": true,
		"seed_collected": true,
		"seed_planted": true,
		"pond_stones_placed": [true, false, false],
		"pond_opened": false,
	}), "Schema 3 must migrate to Q005")
	_expect(schema3_migrated.pond_stones_placed == [true, false, false], "Schema 3 migration must preserve Q003 progress")
	_expect(not schema3_migrated.q005_watered and not schema3_migrated.is_q005_complete(), "Schema 3 migration must default Q005 incomplete")

	var invalid_before_pond := _schema4_save()
	invalid_before_pond["pond_stones_placed"] = [false, false, false]
	invalid_before_pond["pond_opened"] = false
	invalid_before_pond["schema_version"] = 5
	invalid_before_pond["q005_watered"] = true
	invalid_before_pond["q005_plants_collected"] = [false, false, false]
	invalid_before_pond["q005_plant_slots"] = [false, false, false]
	invalid_before_pond["q005_completed"] = false
	_expect(not migrated.load_save_data(invalid_before_pond), "Q005 progress before Q003 must be rejected")

	var invalid_uncollected := saved.duplicate(true)
	invalid_uncollected["q005_plants_collected"] = [false, true, true]
	invalid_uncollected["q005_plant_slots"] = [true, false, false]
	_expect(not migrated.load_save_data(invalid_uncollected), "an uncollected plant in a slot must be rejected")

	var invalid_completion := saved.duplicate(true)
	invalid_completion["q005_watered"] = false
	_expect(not migrated.load_save_data(invalid_completion), "incomplete watering with completed Q005 must be rejected")

	var invalid_type := saved.duplicate(true)
	invalid_type["q005_plant_slots"] = [true, "false", true]
	_expect(not migrated.load_save_data(invalid_type), "invalid Q005 field types must be rejected")

	state.reset()
	_expect(not state.q005_watered, "reset must clear Q005 watering")
	_expect(state.q005_plants_collected == [false, false, false], "reset must clear Q005 plant collection")
	_expect(state.q005_plant_slots == [false, false, false], "reset must clear Q005 slots")
	_expect(not state.is_q005_complete(), "reset must clear Q005 completion")
	_finish()


func _complete_q002(state) -> void:
	for board_id in range(3):
		state.collect_board(board_id)
		state.place_board(board_id, board_id)
	state.collect_seed()
	state.plant_seed()


func _complete_q003(state) -> void:
	_complete_q002(state)
	for stone_id in range(3):
		state.place_pond_stone(stone_id)


func _schema4_save() -> Dictionary:
	return {
		"schema_version": 4,
		"collected": [true, true, true],
		"placed": [true, true, true],
		"quest_completed": true,
		"bridge_repaired": true,
		"area_unlocked": true,
		"seed_collected": true,
		"seed_planted": true,
		"pond_stones_placed": [true, true, true],
		"pond_opened": true,
		"wood_collected": [false, false, false],
		"wood_delivered": [false, false, false],
		"q004_completed": false,
		"fox_moved_in": false,
	}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	failures += 1
	push_error("[Q005StateTest] " + message)


func _finish() -> void:
	if failures == 0:
		print("[Q005StateTest] PASS")
	else:
		push_error("[Q005StateTest] FAIL: %d assertions" % failures)
	quit(failures)
