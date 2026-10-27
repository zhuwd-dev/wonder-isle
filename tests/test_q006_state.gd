extends SceneTree

var failures := 0


func _init() -> void:
	var state_script = load("res://scripts/game/game_state.gd")
	if state_script == null:
		_fail("GameState script must load")
		_finish()
		return

	var locked = state_script.new()
	_expect(not locked.can_start_q006(), "Q006 must be locked before Q002")
	_expect(not locked.place_q006_decoration(0, 0), "Q006 decoration must be locked before Q002")

	var state = state_script.new()
	_complete_q002(state)
	_expect(state.can_start_q006(), "Q002 completion must unlock Q006")
	_expect(state.q006_decor_inventory == [true, true, true], "Q006 must expose three initial decorations")

	var independent = state_script.new()
	_complete_q002(independent)
	_expect(independent.can_start_q006(), "Q006 must not require Q003-Q005")

	var fence_position := Vector2(948, 464)
	var pot_position := Vector2(1050, 486)
	var lamp_position := Vector2(1150, 522)
	_expect(state.place_q006_decoration_at(0, fence_position), "wood fence must be placeable at a chosen position")
	_expect(not state.place_q006_decoration_at(0, Vector2(960, 476)), "the same decoration must not be placed twice")
	_expect(state.q006_decor_inventory == [false, true, true], "successful placement must consume only that inventory item")
	_expect(state.place_q006_decoration_at(1, pot_position), "flower pot must be placeable away from preset slot centers")
	_expect(state.place_q006_decoration_at(2, lamp_position), "yard lamp must be placeable away from preset slot centers")
	_expect(state.is_q006_complete(), "three freely placed decorations must complete Q006")
	_expect(state.q006_windmill_unlocked, "Q006 completion must unlock the windmill")
	_expect(not state.place_q006_decoration_at(2, Vector2(1160, 530)), "completed decoration must not duplicate")

	_expect(state.move_q006_decoration_to(1, 1, Vector2(1084, 504)), "a placed decoration must move to a new free position")
	_expect(state.q006_decor_positions[1] == Vector2(1084, 504), "free movement must save the exact selected position in memory")
	_expect(not state.move_q006_decoration_to(1, 0, Vector2(1090, 510)), "a move with the wrong source must be rejected")
	_expect(state.q006_decor_positions[1] == Vector2(1084, 504), "an invalid move must preserve the current position")
	_expect(state.remove_q006_decoration(0, 0), "a placed decoration must be removable")
	_expect(state.q006_decor_inventory[0], "removing a decoration must return it to inventory")
	_expect(state.is_q006_complete(), "removing a decoration must not roll back Q006")
	_expect(state.place_q006_decoration_at(0, Vector2(970, 536)), "a removed decoration must be reusable at another free position")

	var saved: Dictionary = state.to_save_data()
	_expect(saved.get("schema_version") == 13, "Q006 save must use Schema 13")
	_expect(saved.get("q006_decor_placed") == [true, true, true], "Schema 13 must save placed decorations")
	_expect(saved.get("q006_slot_occupants") == [0, 1, 2], "Schema 13 must save decoration identity tracking")
	_expect(saved.get("q006_decor_positions") == [[970.0, 536.0], [1084.0, 504.0], [1150.0, 522.0]], "Schema 13 must save freely chosen decoration positions")
	_expect(saved.get("q006_completed") == true, "Schema 13 must save Q006 completion")
	_expect(saved.get("q006_windmill_unlocked") == true, "Schema 13 must save the windmill reward")

	var restored = state_script.new()
	_expect(restored.load_save_data(saved), "a valid Schema 13 save must load")
	_expect(restored.is_q006_complete(), "Schema 13 must restore Q006 completion")
	_expect(restored.q006_slot_occupants == [0, 1, 2], "Schema 13 must restore decoration identity tracking")
	_expect(restored.q006_decor_positions == [Vector2(970, 536), Vector2(1084, 504), Vector2(1150, 522)], "Schema 13 must restore exact free-placement positions")

	for schema_version in range(1, 6):
		var old_save := _schema5_save()
		old_save["schema_version"] = schema_version
		if schema_version < 5:
			old_save.erase("q005_watered")
			old_save.erase("q005_plants_collected")
			old_save.erase("q005_plant_slots")
			old_save.erase("q005_completed")
		var migrated = state_script.new()
		_expect(migrated.load_save_data(old_save), "Schema %d must migrate to Schema 13" % schema_version)
		_expect(not migrated.is_q006_complete(), "Schema %d migration must leave Q006 incomplete" % schema_version)
		_expect(migrated.q006_decor_inventory == [false, false, false], "Schema %d migration must not grant decorations before Q002" % schema_version)

	var invalid = saved.duplicate(true)
	invalid["q006_slot_occupants"] = [0, 0, 2]
	_expect(not restored.load_save_data(invalid), "duplicate slot occupants must be rejected")
	_expect(restored.q006_slot_occupants == [0, 1, 2], "rejected Q006 data must not partially mutate state")

	invalid = saved.duplicate(true)
	invalid["q006_decor_inventory"] = [true, true, false]
	_expect(not restored.load_save_data(invalid), "inventory and placement mismatch must be rejected")

	invalid = saved.duplicate(true)
	invalid["q006_windmill_unlocked"] = false
	_expect(not restored.load_save_data(invalid), "completed Q006 without reward must be rejected")

	state.reset()
	_expect(not state.can_start_q006(), "reset must lock Q006")
	_expect(state.q006_decor_placed == [false, false, false], "reset must clear Q006 placement")
	_expect(state.q006_slot_occupants == [-1, -1, -1], "reset must clear Q006 slots")
	_expect(not state.q006_completed and not state.q006_windmill_unlocked, "reset must clear Q006 reward")

	_finish()


func _complete_q002(state) -> void:
	for board_id in range(3):
		state.collect_board(board_id)
		state.place_board(board_id, board_id)
	state.collect_seed()
	state.plant_seed()


func _schema5_save() -> Dictionary:
	return {
		"schema_version": 5,
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
	}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	failures += 1
	push_error("[Q006StateTest] " + message)


func _finish() -> void:
	if failures == 0:
		print("[Q006StateTest] PASS")
	else:
		push_error("[Q006StateTest] FAIL: %d assertions" % failures)
	quit(failures)
