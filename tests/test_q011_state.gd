extends SceneTree

var failures := 0


func _init() -> void:
	var state_script = load("res://scripts/game/game_state.gd")
	if state_script == null:
		_fail("GameState script must load")
		_finish()
		return

	var state = state_script.new()
	_expect(state.q011_completed_task_count() == 0, "a new game must have zero completed prior tasks")
	_expect(not state.can_start_q011(), "Q011 must be locked at zero completed tasks")
	_expect(not state.place_q011_item(0, 0), "Q011 must reject placement while locked")
	_complete_q001(state)
	_expect(state.q011_completed_task_count() == 1, "Q001 must count toward Q011 unlock")
	_expect(not state.can_start_q011(), "Q011 must remain locked after one prior task")
	_complete_q002(state)
	_expect(state.q011_completed_task_count() == 2, "Q002 must count once alongside Q001")
	_expect(not state.can_start_q011(), "Q011 must remain locked after two prior tasks")
	_complete_q003(state)
	_expect(state.q011_completed_task_count() == 3, "Q003 must provide the third prior task")
	_expect(state.can_start_q011(), "any three completed prior tasks must unlock Q011")
	_expect(not state.is_q010_complete(), "Q010 completion must not be required for Q011")
	_expect(state.q011_item_is_available(0), "unplaced Q011 items must be available after unlock")
	_expect(not state.q011_item_is_available(-1), "negative Q011 item IDs must be rejected")
	_expect(not state.q011_item_is_available(3), "out-of-range Q011 item IDs must be rejected")
	_expect(not state.can_place_q011_item(-1, 0), "negative item IDs must not be placeable")
	_expect(not state.can_place_q011_item(3, 0), "out-of-range item IDs must not be placeable")
	_expect(not state.can_place_q011_item(0, -1), "negative slot IDs must not be placeable")
	_expect(not state.can_place_q011_item(0, 3), "out-of-range slot IDs must not be placeable")

	_expect(state.place_q011_item(2, 0), "Q011 items may be placed in arbitrary order")
	_expect(state.place_q011_item(0, 2), "Q011 items may use any remaining slot")
	_expect(not state.place_q011_item(2, 1), "the same Q011 item must not occupy two slots")
	_expect(not state.place_q011_item(1, 0), "an occupied Q011 slot must not be overwritten")
	_expect(state.place_q011_item(1, 1), "the final Q011 item may use the final slot")
	_expect(state.q011_slot_occupants == [2, 1, 0], "Q011 slots must retain their placed item IDs")
	_expect(state.q011_placed_count() == 3, "Q011 progress must count occupied slots")
	_expect(state.is_q011_complete(), "three distinct placed items and three prior tasks must complete Q011")
	_expect(not state.can_start_q011(), "completed Q011 must not restart")
	_expect(not state.q011_item_is_available(0), "placed Q011 items must disappear from availability")

	var saved: Dictionary = state.to_save_data()
	_expect(saved.get("schema_version") == 11, "Q011 saves must use Schema 11")
	_expect(saved.get("q011_slot_occupants") == [2, 1, 0], "Schema 11 must save Q011 slot occupants")
	_expect(not saved.has("q011_completed") and not saved.has("q011_area_unlocked"), "Q011 completion and area unlock must remain derived")
	var restored = state_script.new()
	_expect(restored.load_save_data(saved), "a valid Schema 11 save must load")
	_expect(restored.q011_slot_occupants == [2, 1, 0], "Schema 11 must restore Q011 occupants")
	_expect(restored.is_q011_complete(), "Schema 11 must derive Q011 completion after load")

	var invalid: Dictionary = saved.duplicate(true)
	invalid["q011_slot_occupants"] = [-1, 0]
	_expect(not restored.load_save_data(invalid), "invalid Q011 array lengths must be rejected")
	_expect(restored.to_save_data() == saved, "a failed Q011 load must not partially mutate state")
	invalid = saved.duplicate(true)
	invalid["q011_slot_occupants"] = [0, true, 2]
	_expect(not restored.load_save_data(invalid), "Q011 booleans must not be accepted as integer occupants")
	_expect(restored.to_save_data() == saved, "invalid Q011 member types must not partially mutate state")
	invalid = saved.duplicate(true)
	invalid["q011_slot_occupants"] = [0, 1.5, 2]
	_expect(not restored.load_save_data(invalid), "Q011 fractional occupants must be rejected")
	invalid = saved.duplicate(true)
	invalid["q011_slot_occupants"] = [-2, 1, 2]
	_expect(not restored.load_save_data(invalid), "Q011 occupants below -1 must be rejected")
	invalid = saved.duplicate(true)
	invalid["q011_slot_occupants"] = [0, 1, 3]
	_expect(not restored.load_save_data(invalid), "Q011 occupants above 2 must be rejected")
	invalid = saved.duplicate(true)
	invalid["q011_slot_occupants"] = [0, 0, 2]
	_expect(not restored.load_save_data(invalid), "duplicate Q011 occupants must be rejected")
	_expect(restored.to_save_data() == saved, "every rejected Q011 save must preserve the current state")

	var locked_data: Dictionary = state_script.new().to_save_data()
	locked_data["q011_slot_occupants"] = [1, -1, -1]
	_expect(not restored.load_save_data(locked_data), "Q011 progress without three prior completed tasks must be rejected")
	_expect(restored.to_save_data() == saved, "a locked Q011 progress save must not partially mutate state")

	var all_prior = state_script.new()
	_complete_all_prior_tasks(all_prior)
	_expect(all_prior.q011_completed_task_count() == 9, "Q001 through Q009 must each count once without Q010")
	_expect(not all_prior.is_q010_complete(), "Q010 may remain incomplete while Q011 is unlocked")
	_expect(all_prior.can_start_q011(), "nine completed old tasks must unlock Q011 without Q010")
	_complete_q010(all_prior)
	_expect(all_prior.q011_completed_task_count() == 10, "Q001 through Q010 must count each task exactly once")

	var migration_source: Dictionary = all_prior.to_save_data()
	for schema_version in range(1, 11):
		var old_save := migration_source.duplicate(true)
		old_save["schema_version"] = schema_version
		old_save["q011_slot_occupants"] = ["ignored before schema 11"]
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
		if schema_version < 10:
			old_save.erase("q010_seeds_collected")
		var migrated = state_script.new()
		_expect(migrated.load_save_data(old_save), "Schema %d must migrate to Schema 11" % schema_version)
		_expect(migrated.q011_slot_occupants == [-1, -1, -1], "Schema %d must start Q011 empty and ignore Q011 data" % schema_version)
		_expect(migrated.to_save_data().get("schema_version") == 11, "Schema %d must save as Schema 11 after migration" % schema_version)
		_expect(migrated.is_complete(), "Schema %d migration must preserve Q001" % schema_version)
		if schema_version >= 4:
			_expect(migrated.is_q004_complete(), "Schema %d migration must preserve Q004" % schema_version)
		if schema_version >= 5:
			_expect(migrated.is_q005_complete(), "Schema %d migration must preserve Q005" % schema_version)
		if schema_version >= 6:
			_expect(migrated.is_q006_complete(), "Schema %d migration must preserve Q006" % schema_version)
		if schema_version >= 7:
			_expect(migrated.is_q007_complete(), "Schema %d migration must preserve Q007" % schema_version)
		if schema_version >= 8:
			_expect(migrated.is_q008_complete(), "Schema %d migration must preserve Q008" % schema_version)
		if schema_version >= 9:
			_expect(migrated.is_q009_complete(), "Schema %d migration must preserve Q009" % schema_version)
		if schema_version < 10:
			_expect(not migrated.is_q010_complete(), "Schema %d migration must default Q010 incomplete" % schema_version)

	state.reset()
	_expect(state.q011_slot_occupants == [-1, -1, -1], "reset must clear Q011 slots")
	_expect(state.q011_placed_count() == 0 and not state.is_q011_complete(), "reset must clear Q011 progress and completion")
	_expect(not state.can_start_q011(), "reset must relock Q011")
	_finish()


func _complete_q001(state) -> void:
	if state.is_complete():
		return
	for board_id in range(3):
		state.collect_board(board_id)
		state.place_board(board_id, board_id)


func _complete_q002(state) -> void:
	_complete_q001(state)
	if not state.seed_collected:
		state.collect_seed()
	if not state.seed_planted:
		state.plant_seed()


func _complete_q003(state) -> void:
	_complete_q002(state)
	for stone_id in range(3):
		state.place_pond_stone(stone_id)


func _complete_q005(state) -> void:
	_complete_q003(state)
	if not state.q005_watered:
		state.water_q005()
	for plant_id in range(3):
		if not state.q005_plants_collected[plant_id]:
			state.collect_q005_plant(plant_id)
		if not state.q005_plant_slots[plant_id]:
			state.place_q005_plant(plant_id, plant_id)


func _complete_all_prior_tasks(state) -> void:
	_complete_q005(state)
	for wood_id in range(3):
		if not state.wood_collected[wood_id]:
			state.collect_wood(wood_id)
		if not state.wood_delivered[wood_id]:
			state.deliver_wood(wood_id)
	for decor_id in range(3):
		state.place_q006_decoration(decor_id, decor_id)
	if not state.q007_shell_collected:
		state.collect_q007_shell()
	for material_id in range(3):
		if not state.q008_path_slot_occupants.has(material_id):
			state.place_q008_path(material_id, material_id)
	for material_id in range(3):
		if not state.q009_materials_collected[material_id]:
			state.collect_q009_material(material_id)


func _complete_q010(state) -> void:
	_complete_q005(state)
	for seed_id in range(3):
		if not state.q010_seeds_collected[seed_id]:
			state.collect_q010_seed(seed_id)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	failures += 1
	push_error("[Q011StateTest] " + message)


func _finish() -> void:
	if failures == 0:
		print("[Q011StateTest] PASS")
	else:
		push_error("[Q011StateTest] FAIL: %d assertions" % failures)
	quit(failures)
