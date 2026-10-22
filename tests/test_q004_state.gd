extends SceneTree

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var state_script = load("res://scripts/game/game_state.gd")
	var state = state_script.new()
	_expect(not state.can_start_q004(), "Q004 must be locked before Q002")
	_expect(not state.collect_wood(0), "wood must be locked before Q002")
	_expect(not state.deliver_wood(0), "wood must not be deliverable before Q002")

	_complete_q002(state)
	_expect(state.can_start_q004(), "Q002 completion must unlock Q004")
	_expect(not state.is_pond_complete(), "Q004 test should not require Q003 completion")
	_expect(not state.collect_wood(-1), "negative wood ids must be rejected")
	_expect(not state.collect_wood(state_script.Q004_WOOD_TOTAL), "out-of-range wood ids must be rejected")
	_expect(state.collect_wood(0), "the first Q004 wood must be collectible")
	_expect(not state.collect_wood(0), "the same Q004 wood must not be collected twice")
	_expect(not state.deliver_wood(1), "uncollected Q004 wood must not be deliverable")
	_expect(state.deliver_wood(0), "a collected Q004 wood must be deliverable")
	_expect(not state.deliver_wood(0), "delivered Q004 wood must not be delivered twice")
	_expect(state.collect_wood(1), "the second Q004 wood must be collectible")
	_expect(state.collect_wood(2), "the third Q004 wood must be collectible")
	_expect(state.deliver_wood(1), "the second Q004 wood must be deliverable")
	_expect(not state.is_q004_complete(), "Q004 must remain incomplete before the final delivery")
	_expect(state.deliver_wood(2), "the final Q004 wood must be deliverable")
	_expect(state.is_q004_complete(), "three delivered woods must complete Q004")
	_expect(state.q004_completed and state.fox_moved_in, "Q004 completion must move in the fox")
	_expect(not state.collect_wood(0), "completed Q004 must not collect wood again")
	_expect(not state.deliver_wood(2), "completed Q004 must not deliver wood again")

	var saved: Dictionary = state.to_save_data()
	_expect(saved.get("schema_version") == 12, "Q004 save must remain compatible with Schema 12")
	_expect(saved.get("wood_collected") == [true, true, true], "save must contain all collected Q004 woods")
	_expect(saved.get("wood_delivered") == [true, true, true], "save must contain all delivered Q004 woods")
	_expect(saved.get("q004_completed") == true, "save must contain Q004 completion")
	_expect(saved.get("fox_moved_in") == true, "save must contain fox occupancy")
	var restored = state_script.new()
	_expect(restored.load_save_data(saved), "a completed Q004 save must load")
	_expect(restored.is_q004_complete(), "a completed Q004 save must restore completion")

	var schema3_save := {
		"schema_version": 3,
		"collected": [true, true, true],
		"placed": [true, true, true],
		"quest_completed": true,
		"bridge_repaired": true,
		"area_unlocked": true,
		"seed_collected": true,
		"seed_planted": true,
		"pond_stones_placed": [false, false, false],
		"pond_opened": false,
	}
	var migrated = state_script.new()
	_expect(migrated.load_save_data(schema3_save), "Schema 3 must migrate to Q004")
	_expect(migrated.can_start_q004(), "migrated Q002 completion must unlock Q004")
	_expect(not migrated.is_q004_complete(), "migrated Q004 must start incomplete")
	_expect(migrated.wood_collected == [false, false, false], "migrated Q004 collection must default empty")

	var invalid_delivered := schema3_save.duplicate(true)
	invalid_delivered["schema_version"] = 4
	invalid_delivered["wood_collected"] = [false, false, false]
	invalid_delivered["wood_delivered"] = [true, false, false]
	invalid_delivered["q004_completed"] = false
	invalid_delivered["fox_moved_in"] = false
	_expect(not migrated.load_save_data(invalid_delivered), "delivered wood without collection must be rejected")

	var invalid_completion := schema3_save.duplicate(true)
	invalid_completion["schema_version"] = 4
	invalid_completion["wood_collected"] = [true, false, false]
	invalid_completion["wood_delivered"] = [true, false, false]
	invalid_completion["q004_completed"] = true
	invalid_completion["fox_moved_in"] = true
	_expect(not migrated.load_save_data(invalid_completion), "partial delivery marked complete must be rejected")

	var invalid_type := schema3_save.duplicate(true)
	invalid_type["schema_version"] = 4
	invalid_type["wood_collected"] = ["true", false, false]
	invalid_type["wood_delivered"] = [false, false, false]
	invalid_type["q004_completed"] = false
	invalid_type["fox_moved_in"] = false
	_expect(not migrated.load_save_data(invalid_type), "Q004 field type errors must be rejected")

	var invalid_pond_progress := schema3_save.duplicate(true)
	invalid_pond_progress["seed_collected"] = false
	invalid_pond_progress["seed_planted"] = false
	invalid_pond_progress["pond_stones_placed"] = [true, false, false]
	invalid_pond_progress["pond_opened"] = false
	_expect(not migrated.load_save_data(invalid_pond_progress), "pond progress before planting must be rejected")

	state.reset()
	_expect(not state.can_start_q004(), "restart must lock Q004")
	_expect(state.wood_collected == [false, false, false], "restart must clear Q004 collection")
	_expect(state.wood_delivered == [false, false, false], "restart must clear Q004 delivery")
	_expect(not state.q004_completed and not state.fox_moved_in, "restart must clear Q004 completion")
	_finish()


func _complete_q002(state) -> void:
	for board_id in range(3):
		state.collect_board(board_id)
		state.place_board(board_id, board_id)
	state.collect_seed()
	state.plant_seed()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("[Q004StateTest] " + message)


func _finish() -> void:
	if failures == 0:
		print("[Q004StateTest] PASS")
	else:
		push_error("[Q004StateTest] FAIL: %d assertions" % failures)
	quit(failures)

