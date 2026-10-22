class_name IslandGameState
extends RefCounted

const SCHEMA_VERSION := 12
const LEGACY_SCHEMA_VERSION := 1
const SEED_SCHEMA_VERSION := 2
const POND_SCHEMA_VERSION := 3
const Q004_SCHEMA_VERSION := 4
const Q005_SCHEMA_VERSION := 5
const Q006_SCHEMA_VERSION := 6
const Q007_SCHEMA_VERSION := 7
const Q008_SCHEMA_VERSION := 8
const Q009_SCHEMA_VERSION := 9
const Q010_SCHEMA_VERSION := 10
const Q011_SCHEMA_VERSION := 11
const Q012_SCHEMA_VERSION := 12
const BOARD_TOTAL := 3
const POND_STONE_TOTAL := 3
const Q004_WOOD_TOTAL := 3
const Q005_PLANT_TOTAL := 3
const Q006_DECOR_TOTAL := 3
const Q006_SLOT_TOTAL := 3
const Q006_DECOR_IDS := ["wood_fence", "flower_pot", "yard_lamp"]
const Q006_WINDMILL_ID := "windmill"
const Q007_REWARD_DECOR_ID := "pearl_shell_decor"
const Q008_PATH_SLOT_TOTAL := 3
const Q008_PATH_MATERIAL_IDS := ["path_paver_0", "path_paver_1", "path_paver_2"]
const Q009_MATERIAL_TOTAL := 3
const Q009_MATERIAL_IDS := ["q009_material_0", "q009_material_1", "q009_material_2"]
const Q010_SEED_TOTAL := 3
const Q010_SEED_IDS := ["q010_seed_0", "q010_seed_1", "q010_seed_2"]
const Q011_ITEM_TOTAL := 3

var collected: Array[bool] = [false, false, false]
var placed: Array[bool] = [false, false, false]
var quest_completed := false
var bridge_repaired := false
var area_unlocked := false
var seed_collected := false
var seed_planted := false
var pond_stones_placed: Array[bool] = [false, false, false]
var pond_opened := false
var wood_collected: Array[bool] = [false, false, false]
var wood_delivered: Array[bool] = [false, false, false]
var q004_completed := false
var fox_moved_in := false
var q005_watered := false
var q005_plants_collected: Array[bool] = [false, false, false]
var q005_plant_slots: Array[bool] = [false, false, false]
var q005_completed := false
var q006_decor_inventory: Array[bool] = [false, false, false]
var q006_decor_placed: Array[bool] = [false, false, false]
var q006_slot_occupants: Array[int] = [-1, -1, -1]
var q006_completion_proof: Array[bool] = [false, false, false]
var q006_completed := false
var q006_windmill_unlocked := false
var q007_shell_collected := false
var q007_completed := false
var q007_reward_unlocked := false
var q008_path_slot_occupants: Array[int] = [-1, -1, -1]
var q008_completed := false
var q009_materials_collected: Array[bool] = [false, false, false]
var q009_completed := false
var q010_seeds_collected: Array[bool] = [false, false, false]
var q011_slot_occupants: Array[int] = [-1, -1, -1]
var q012_completed := false


func reset() -> void:
	collected = [false, false, false]
	placed = [false, false, false]
	quest_completed = false
	bridge_repaired = false
	area_unlocked = false
	seed_collected = false
	seed_planted = false
	pond_stones_placed = [false, false, false]
	pond_opened = false
	wood_collected = [false, false, false]
	wood_delivered = [false, false, false]
	q004_completed = false
	fox_moved_in = false
	q005_watered = false
	q005_plants_collected = [false, false, false]
	q005_plant_slots = [false, false, false]
	q005_completed = false
	q006_decor_inventory = [false, false, false]
	q006_decor_placed = [false, false, false]
	q006_slot_occupants = [-1, -1, -1]
	q006_completion_proof = [false, false, false]
	q006_completed = false
	q006_windmill_unlocked = false
	q007_shell_collected = false
	q007_completed = false
	q007_reward_unlocked = false
	q008_path_slot_occupants = [-1, -1, -1]
	q008_completed = false
	q009_materials_collected = [false, false, false]
	q009_completed = false
	q010_seeds_collected = [false, false, false]
	q011_slot_occupants = [-1, -1, -1]
	q012_completed = false


func board_count() -> int:
	var total := 0
	for value in collected:
		if value:
			total += 1
	return total


func placed_count() -> int:
	var total := 0
	for value in placed:
		if value:
			total += 1
	return total


func collect_board(board_id: int) -> bool:
	if board_id < 0 or board_id >= BOARD_TOTAL or collected[board_id]:
		return false
	collected[board_id] = true
	return true


func can_repair_bridge() -> bool:
	return board_count() == BOARD_TOTAL


func can_place_board(board_id: int) -> bool:
	return board_id >= 0 and board_id < BOARD_TOTAL and collected[board_id] and not placed[board_id]


func place_board(board_id: int, slot_id: int) -> bool:
	if not can_place_board(board_id) or slot_id != board_id:
		return false
	placed[board_id] = true
	if placed_count() == BOARD_TOTAL:
		bridge_repaired = true
		quest_completed = true
		area_unlocked = true
	return true


func is_complete() -> bool:
	return quest_completed and bridge_repaired and area_unlocked and placed_count() == BOARD_TOTAL


func can_collect_seed() -> bool:
	return is_complete() and not seed_collected


func collect_seed() -> bool:
	if not can_collect_seed():
		return false
	seed_collected = true
	return true


func can_plant_seed() -> bool:
	return is_complete() and seed_collected and not seed_planted


func plant_seed() -> bool:
	if not can_plant_seed():
		return false
	seed_planted = true
	return true


func is_seed_complete() -> bool:
	return seed_planted


func can_start_pond_task() -> bool:
	return is_seed_complete() and not is_pond_complete()


func can_place_pond_stone(stone_id: int) -> bool:
	return can_start_pond_task() and stone_id >= 0 and stone_id < POND_STONE_TOTAL and not pond_stones_placed[stone_id]


func place_pond_stone(stone_id: int) -> bool:
	if not can_place_pond_stone(stone_id):
		return false
	pond_stones_placed[stone_id] = true
	if _all_pond_stones_placed():
		pond_opened = true
	return true


func is_pond_complete() -> bool:
	return pond_opened and _all_pond_stones_placed()


func _all_pond_stones_placed() -> bool:
	for value in pond_stones_placed:
		if not value:
			return false
	return true


func q005_plant_count() -> int:
	return _count_true(q005_plants_collected)


func q005_plant_slot_count() -> int:
	return _count_true(q005_plant_slots)


func can_start_q005() -> bool:
	return is_pond_complete() and not is_q005_complete()


func can_water_q005() -> bool:
	return can_start_q005() and not q005_watered


func water_q005() -> bool:
	if not can_water_q005():
		return false
	q005_watered = true
	_update_q005_completion()
	return true


func can_collect_q005_plant(plant_id: int) -> bool:
	return can_start_q005() and plant_id >= 0 and plant_id < Q005_PLANT_TOTAL and not q005_plants_collected[plant_id]


func collect_q005_plant(plant_id: int) -> bool:
	if not can_collect_q005_plant(plant_id):
		return false
	q005_plants_collected[plant_id] = true
	return true


func can_place_q005_plant(plant_id: int, slot_id: int) -> bool:
	return can_start_q005() and plant_id >= 0 and plant_id < Q005_PLANT_TOTAL and slot_id >= 0 and slot_id < Q005_PLANT_TOTAL and plant_id == slot_id and q005_plants_collected[plant_id] and not q005_plant_slots[slot_id]


func place_q005_plant(plant_id: int, slot_id: int) -> bool:
	if not can_place_q005_plant(plant_id, slot_id):
		return false
	q005_plant_slots[slot_id] = true
	_update_q005_completion()
	return true


func is_q005_complete() -> bool:
	return q005_completed and is_pond_complete() and q005_watered and q005_plant_count() == Q005_PLANT_TOTAL and q005_plant_slot_count() == Q005_PLANT_TOTAL


func _update_q005_completion() -> void:
	if q005_watered and q005_plant_count() == Q005_PLANT_TOTAL and q005_plant_slot_count() == Q005_PLANT_TOTAL and is_pond_complete():
		q005_completed = true


func wood_count() -> int:
	return _count_true(wood_collected)


func delivered_wood_count() -> int:
	return _count_true(wood_delivered)


func can_start_q004() -> bool:
	return is_seed_complete() and not is_q004_complete()


func can_collect_wood(wood_id: int) -> bool:
	return can_start_q004() and wood_id >= 0 and wood_id < Q004_WOOD_TOTAL and not wood_collected[wood_id]


func collect_wood(wood_id: int) -> bool:
	if not can_collect_wood(wood_id):
		return false
	wood_collected[wood_id] = true
	return true


func can_deliver_wood(wood_id: int) -> bool:
	return can_start_q004() and wood_id >= 0 and wood_id < Q004_WOOD_TOTAL and wood_collected[wood_id] and not wood_delivered[wood_id]


func deliver_wood(wood_id: int) -> bool:
	if not can_deliver_wood(wood_id):
		return false
	wood_delivered[wood_id] = true
	if _all_wood_delivered():
		q004_completed = true
		fox_moved_in = true
	return true


func deliver_next_wood() -> bool:
	if not can_start_q004():
		return false
	for wood_id in range(Q004_WOOD_TOTAL):
		if can_deliver_wood(wood_id):
			return deliver_wood(wood_id)
	return false


func is_q004_complete() -> bool:
	return q004_completed and fox_moved_in and _all_wood_delivered()


func _all_wood_delivered() -> bool:
	return delivered_wood_count() == Q004_WOOD_TOTAL


func q006_placed_count() -> int:
	return _count_true(q006_decor_placed)


func can_start_q006() -> bool:
	_ensure_q006_unlock()
	return is_seed_complete() and not q006_completed


func can_edit_q006() -> bool:
	_ensure_q006_unlock()
	return is_seed_complete()


func q006_decor_id(decor_id: int) -> String:
	if decor_id < 0 or decor_id >= Q006_DECOR_TOTAL:
		return ""
	return Q006_DECOR_IDS[decor_id]


func q006_decor_is_available(decor_id: int) -> bool:
	return can_edit_q006() and decor_id >= 0 and decor_id < Q006_DECOR_TOTAL and q006_decor_inventory[decor_id]


func can_place_q006_decoration(decor_id: int, slot_id: int) -> bool:
	return can_edit_q006() and decor_id >= 0 and decor_id < Q006_DECOR_TOTAL and slot_id >= 0 and slot_id < Q006_SLOT_TOTAL and decor_id == slot_id and q006_decor_inventory[decor_id] and q006_slot_occupants[slot_id] < 0


func place_q006_decoration(decor_id: int, slot_id: int) -> bool:
	if not can_place_q006_decoration(decor_id, slot_id):
		return false
	q006_decor_inventory[decor_id] = false
	q006_decor_placed[decor_id] = true
	q006_slot_occupants[slot_id] = decor_id
	q006_completion_proof[decor_id] = true
	_update_q006_completion()
	return true


func can_move_q006_decoration(decor_id: int, from_slot: int, to_slot: int) -> bool:
	return can_edit_q006() and decor_id >= 0 and decor_id < Q006_DECOR_TOTAL and from_slot >= 0 and from_slot < Q006_SLOT_TOTAL and to_slot >= 0 and to_slot < Q006_SLOT_TOTAL and from_slot != to_slot and q006_slot_occupants[from_slot] == decor_id and q006_slot_occupants[to_slot] < 0


func move_q006_decoration(decor_id: int, from_slot: int, to_slot: int) -> bool:
	if not can_move_q006_decoration(decor_id, from_slot, to_slot):
		return false
	q006_slot_occupants[from_slot] = -1
	q006_slot_occupants[to_slot] = decor_id
	return true


func can_remove_q006_decoration(decor_id: int, slot_id: int) -> bool:
	return can_edit_q006() and decor_id >= 0 and decor_id < Q006_DECOR_TOTAL and slot_id >= 0 and slot_id < Q006_SLOT_TOTAL and q006_slot_occupants[slot_id] == decor_id


func remove_q006_decoration(decor_id: int, slot_id: int) -> bool:
	if not can_remove_q006_decoration(decor_id, slot_id):
		return false
	q006_slot_occupants[slot_id] = -1
	q006_decor_placed[decor_id] = false
	q006_decor_inventory[decor_id] = true
	return true


func is_q006_complete() -> bool:
	return q006_completed and q006_windmill_unlocked and _all_flags_true(q006_completion_proof)


func _update_q006_completion() -> void:
	if _all_flags_true(q006_decor_placed):
		q006_completed = true
		q006_windmill_unlocked = true


func _ensure_q006_unlock() -> void:
	if not is_seed_complete():
		return
	for decor_id in range(Q006_DECOR_TOTAL):
		if not q006_decor_placed[decor_id]:
			q006_decor_inventory[decor_id] = true


func can_start_q007() -> bool:
	return is_pond_complete() and not is_q007_complete()


func can_collect_q007_shell() -> bool:
	return can_start_q007() and not q007_shell_collected


func collect_q007_shell() -> bool:
	if not can_collect_q007_shell():
		return false
	q007_shell_collected = true
	q007_completed = true
	q007_reward_unlocked = true
	return true


func is_q007_complete() -> bool:
	return q007_completed and q007_shell_collected and q007_reward_unlocked


func can_start_q008() -> bool:
	return is_complete() and not is_q008_complete()


func q008_path_material_is_available(material_id: int) -> bool:
	return can_start_q008() and material_id >= 0 and material_id < Q008_PATH_SLOT_TOTAL and not q008_path_slot_occupants.has(material_id)


func can_place_q008_path(material_id: int, slot_id: int) -> bool:
	return can_start_q008() and material_id >= 0 and material_id < Q008_PATH_SLOT_TOTAL and slot_id >= 0 and slot_id < Q008_PATH_SLOT_TOTAL and not q008_path_slot_occupants.has(material_id) and q008_path_slot_occupants[slot_id] < 0


func place_q008_path(material_id: int, slot_id: int) -> bool:
	if not can_place_q008_path(material_id, slot_id):
		return false
	q008_path_slot_occupants[slot_id] = material_id
	if _all_q008_path_slots_occupied():
		q008_completed = true
	return true


func q008_path_placed_count() -> int:
	var total := 0
	for material_id in q008_path_slot_occupants:
		if material_id >= 0:
			total += 1
	return total


func is_q008_complete() -> bool:
	return q008_completed and is_complete() and _all_q008_path_slots_occupied()


func _all_q008_path_slots_occupied() -> bool:
	for material_id in q008_path_slot_occupants:
		if material_id < 0:
			return false
	return true


func q009_material_count() -> int:
	return _count_true(q009_materials_collected)


func can_start_q009() -> bool:
	return is_q004_complete() and not is_q009_complete()


func can_collect_q009_material(material_id: int) -> bool:
	return can_start_q009() and material_id >= 0 and material_id < Q009_MATERIAL_TOTAL and not q009_materials_collected[material_id]


func collect_q009_material(material_id: int) -> bool:
	if not can_collect_q009_material(material_id):
		return false
	q009_materials_collected[material_id] = true
	if _all_flags_true(q009_materials_collected):
		q009_completed = true
	return true


func is_q009_complete() -> bool:
	return q009_completed and is_q004_complete() and _all_flags_true(q009_materials_collected)


func q009_bird_interaction_unlocked() -> bool:
	return is_q009_complete()


func q010_seed_count() -> int:
	return _count_true(q010_seeds_collected)


func can_start_q010() -> bool:
	return is_q005_complete() and not is_q010_complete()


func can_collect_q010_seed(seed_id: int) -> bool:
	return can_start_q010() and seed_id >= 0 and seed_id < Q010_SEED_TOTAL and not q010_seeds_collected[seed_id]


func collect_q010_seed(seed_id: int) -> bool:
	if not can_collect_q010_seed(seed_id):
		return false
	q010_seeds_collected[seed_id] = true
	return true


func is_q010_complete() -> bool:
	return is_q005_complete() and _all_flags_true(q010_seeds_collected)


func q011_completed_task_count() -> int:
	var completed := [
		is_complete(),
		is_seed_complete(),
		is_pond_complete(),
		is_q004_complete(),
		is_q005_complete(),
		is_q006_complete(),
		is_q007_complete(),
		is_q008_complete(),
		is_q009_complete(),
		is_q010_complete(),
	]
	var total := 0
	for is_completed in completed:
		if is_completed:
			total += 1
	return total


func can_start_q011() -> bool:
	return q011_completed_task_count() >= 3 and not is_q011_complete()


func q011_item_is_available(item_id: int) -> bool:
	return can_start_q011() and item_id >= 0 and item_id < Q011_ITEM_TOTAL and not q011_slot_occupants.has(item_id)


func can_place_q011_item(item_id: int, slot_id: int) -> bool:
	return can_start_q011() and item_id >= 0 and item_id < Q011_ITEM_TOTAL and slot_id >= 0 and slot_id < Q011_ITEM_TOTAL and not q011_slot_occupants.has(item_id) and q011_slot_occupants[slot_id] == -1


func place_q011_item(item_id: int, slot_id: int) -> bool:
	if not can_place_q011_item(item_id, slot_id):
		return false
	q011_slot_occupants[slot_id] = item_id
	return true


func q011_placed_count() -> int:
	var total := 0
	for item_id in q011_slot_occupants:
		if item_id >= 0:
			total += 1
	return total


func is_q011_complete() -> bool:
	return q011_completed_task_count() >= 3 and q011_placed_count() == Q011_ITEM_TOTAL and q011_slot_occupants.has(0) and q011_slot_occupants.has(1) and q011_slot_occupants.has(2)


func can_start_q012() -> bool:
	return is_q006_complete() and not q012_completed


func complete_q012() -> bool:
	if not can_start_q012():
		return false
	q012_completed = true
	return true


func is_q012_complete() -> bool:
	return q012_completed and is_q006_complete()


func _count_true(values: Array[bool]) -> int:
	var total := 0
	for value in values:
		if value:
			total += 1
	return total


func to_save_data() -> Dictionary:
	_ensure_q006_unlock()
	return {
		"schema_version": SCHEMA_VERSION,
		"collected": collected.duplicate(),
		"placed": placed.duplicate(),
		"quest_completed": quest_completed,
		"bridge_repaired": bridge_repaired,
		"area_unlocked": area_unlocked,
		"seed_collected": seed_collected,
		"seed_planted": seed_planted,
		"pond_stones_placed": pond_stones_placed.duplicate(),
		"pond_opened": pond_opened,
		"wood_collected": wood_collected.duplicate(),
		"wood_delivered": wood_delivered.duplicate(),
		"q004_completed": q004_completed,
		"fox_moved_in": fox_moved_in,
		"q005_watered": q005_watered,
		"q005_plants_collected": q005_plants_collected.duplicate(),
		"q005_plant_slots": q005_plant_slots.duplicate(),
		"q005_completed": q005_completed,
		"q006_decor_inventory": q006_decor_inventory.duplicate(),
		"q006_decor_placed": q006_decor_placed.duplicate(),
		"q006_slot_occupants": q006_slot_occupants.duplicate(),
		"q006_completion_proof": q006_completion_proof.duplicate(),
		"q006_completed": q006_completed,
		"q006_windmill_unlocked": q006_windmill_unlocked,
		"q007_shell_collected": q007_shell_collected,
		"q007_completed": q007_completed,
		"q007_reward_unlocked": q007_reward_unlocked,
		"q008_path_slot_occupants": q008_path_slot_occupants.duplicate(),
		"q008_completed": q008_completed,
		"q009_materials_collected": q009_materials_collected.duplicate(),
		"q009_completed": q009_completed,
		"q010_seeds_collected": q010_seeds_collected.duplicate(),
		"q011_slot_occupants": q011_slot_occupants.duplicate(),
		"q012_completed": q012_completed,
	}


func load_save_data(data: Dictionary) -> bool:
	var schema_version = data.get("schema_version")
	if typeof(schema_version) != TYPE_INT and typeof(schema_version) != TYPE_FLOAT:
		return false
	var is_legacy_schema := is_equal_approx(float(schema_version), float(LEGACY_SCHEMA_VERSION))
	var is_seed_schema := is_equal_approx(float(schema_version), float(SEED_SCHEMA_VERSION))
	var is_pond_schema := is_equal_approx(float(schema_version), float(POND_SCHEMA_VERSION))
	var is_q004_schema := is_equal_approx(float(schema_version), float(Q004_SCHEMA_VERSION))
	var is_q005_schema := is_equal_approx(float(schema_version), float(Q005_SCHEMA_VERSION))
	var is_q006_schema := is_equal_approx(float(schema_version), float(Q006_SCHEMA_VERSION))
	var is_q007_schema := is_equal_approx(float(schema_version), float(Q007_SCHEMA_VERSION))
	var is_q008_schema := is_equal_approx(float(schema_version), float(Q008_SCHEMA_VERSION))
	var is_q009_schema := is_equal_approx(float(schema_version), float(Q009_SCHEMA_VERSION))
	var is_q010_schema := is_equal_approx(float(schema_version), float(Q010_SCHEMA_VERSION))
	var is_q011_schema := is_equal_approx(float(schema_version), float(Q011_SCHEMA_VERSION))
	var is_q012_schema := is_equal_approx(float(schema_version), float(Q012_SCHEMA_VERSION))
	if not is_legacy_schema and not is_seed_schema and not is_pond_schema and not is_q004_schema and not is_q005_schema and not is_q006_schema and not is_q007_schema and not is_q008_schema and not is_q009_schema and not is_q010_schema and not is_q011_schema and not is_q012_schema:
		return false
	var collected_data = data.get("collected")
	var placed_data = data.get("placed")
	if not collected_data is Array or not placed_data is Array:
		return false
	if collected_data.size() != BOARD_TOTAL or placed_data.size() != BOARD_TOTAL:
		return false
	var validated_collected: Array[bool] = []
	var validated_placed: Array[bool] = []
	for i in range(BOARD_TOTAL):
		if typeof(collected_data[i]) != TYPE_BOOL or typeof(placed_data[i]) != TYPE_BOOL:
			return false
		if placed_data[i] and not collected_data[i]:
			return false
		validated_collected.append(collected_data[i])
		validated_placed.append(placed_data[i])
	if typeof(data.get("quest_completed")) != TYPE_BOOL:
		return false
	if typeof(data.get("bridge_repaired")) != TYPE_BOOL:
		return false
	if typeof(data.get("area_unlocked")) != TYPE_BOOL:
		return false

	var expected_complete := true
	for value in validated_placed:
		if not value:
			expected_complete = false
			break
	if data["quest_completed"] != expected_complete:
		return false
	if data["bridge_repaired"] != expected_complete:
		return false
	if data["area_unlocked"] != data["bridge_repaired"]:
		return false

	var validated_seed_collected := false
	var validated_seed_planted := false
	if is_seed_schema or is_pond_schema or is_q004_schema or is_q005_schema or is_q006_schema or is_q007_schema or is_q008_schema or is_q009_schema or is_q010_schema or is_q011_schema or is_q012_schema:
		if typeof(data.get("seed_collected")) != TYPE_BOOL:
			return false
		if typeof(data.get("seed_planted")) != TYPE_BOOL:
			return false
		validated_seed_collected = data["seed_collected"]
		validated_seed_planted = data["seed_planted"]
	if validated_seed_planted and not validated_seed_collected:
		return false
	if (validated_seed_collected or validated_seed_planted) and not expected_complete:
		return false

	var validated_pond_stones: Array[bool] = [false, false, false]
	var validated_pond_opened := false
	if is_pond_schema or is_q004_schema or is_q005_schema or is_q006_schema or is_q007_schema or is_q008_schema or is_q009_schema or is_q010_schema or is_q011_schema or is_q012_schema:
		var pond_stones_data = data.get("pond_stones_placed")
		if not pond_stones_data is Array or pond_stones_data.size() != POND_STONE_TOTAL:
			return false
		for i in range(POND_STONE_TOTAL):
			if typeof(pond_stones_data[i]) != TYPE_BOOL:
				return false
			validated_pond_stones[i] = pond_stones_data[i]
		if typeof(data.get("pond_opened")) != TYPE_BOOL:
			return false
		validated_pond_opened = data["pond_opened"]
		if validated_pond_stones.has(true) and not validated_seed_planted:
			return false
	if validated_pond_opened and not validated_seed_planted:
		return false
	var expected_pond_complete := true
	for value in validated_pond_stones:
		if not value:
			expected_pond_complete = false
			break
	if validated_pond_opened != expected_pond_complete:
		return false

	var validated_wood_collected: Array[bool] = [false, false, false]
	var validated_wood_delivered: Array[bool] = [false, false, false]
	var validated_q004_completed := false
	var validated_fox_moved_in := false
	if is_q004_schema or is_q005_schema or is_q006_schema or is_q007_schema or is_q008_schema or is_q009_schema or is_q010_schema or is_q011_schema or is_q012_schema:
		var wood_collected_data = data.get("wood_collected")
		var wood_delivered_data = data.get("wood_delivered")
		if not wood_collected_data is Array or wood_collected_data.size() != Q004_WOOD_TOTAL:
			return false
		if not wood_delivered_data is Array or wood_delivered_data.size() != Q004_WOOD_TOTAL:
			return false
		for i in range(Q004_WOOD_TOTAL):
			if typeof(wood_collected_data[i]) != TYPE_BOOL or typeof(wood_delivered_data[i]) != TYPE_BOOL:
				return false
			if wood_delivered_data[i] and not wood_collected_data[i]:
				return false
			validated_wood_collected[i] = wood_collected_data[i]
			validated_wood_delivered[i] = wood_delivered_data[i]
		if typeof(data.get("q004_completed")) != TYPE_BOOL:
			return false
		if typeof(data.get("fox_moved_in")) != TYPE_BOOL:
			return false
		validated_q004_completed = data["q004_completed"]
		validated_fox_moved_in = data["fox_moved_in"]
	if (validated_wood_collected.has(true) or validated_wood_delivered.has(true) or validated_q004_completed or validated_fox_moved_in) and not validated_seed_planted:
		return false
	var expected_q004_complete := validated_wood_delivered == [true, true, true]
	if validated_q004_completed != expected_q004_complete:
		return false
	if validated_fox_moved_in != expected_q004_complete:
		return false

	var validated_q005_watered := false
	var validated_q005_plants_collected: Array[bool] = [false, false, false]
	var validated_q005_plant_slots: Array[bool] = [false, false, false]
	var validated_q005_completed := false
	if is_q005_schema or is_q006_schema or is_q007_schema or is_q008_schema or is_q009_schema or is_q010_schema or is_q011_schema or is_q012_schema:
		if typeof(data.get("q005_watered")) != TYPE_BOOL:
			return false
		var q005_plants_collected_data = data.get("q005_plants_collected")
		var q005_plant_slots_data = data.get("q005_plant_slots")
		if not q005_plants_collected_data is Array or q005_plants_collected_data.size() != Q005_PLANT_TOTAL:
			return false
		if not q005_plant_slots_data is Array or q005_plant_slots_data.size() != Q005_PLANT_TOTAL:
			return false
		for i in range(Q005_PLANT_TOTAL):
			if typeof(q005_plants_collected_data[i]) != TYPE_BOOL or typeof(q005_plant_slots_data[i]) != TYPE_BOOL:
				return false
			if q005_plant_slots_data[i] and not q005_plants_collected_data[i]:
				return false
			validated_q005_plants_collected[i] = q005_plants_collected_data[i]
			validated_q005_plant_slots[i] = q005_plant_slots_data[i]
		if typeof(data.get("q005_completed")) != TYPE_BOOL:
			return false
		validated_q005_watered = data["q005_watered"]
		validated_q005_completed = data["q005_completed"]
		if (validated_q005_watered or validated_q005_plants_collected.has(true) or validated_q005_plant_slots.has(true) or validated_q005_completed) and not expected_pond_complete:
			return false
	var expected_q005_complete := expected_pond_complete and validated_q005_watered and _all_flags_true(validated_q005_plants_collected) and _all_flags_true(validated_q005_plant_slots)
	if validated_q005_completed != expected_q005_complete:
		return false

	var validated_q006_decor_inventory: Array[bool] = [false, false, false]
	var validated_q006_decor_placed: Array[bool] = [false, false, false]
	var validated_q006_slot_occupants: Array[int] = [-1, -1, -1]
	var validated_q006_completion_proof: Array[bool] = [false, false, false]
	var validated_q006_completed := false
	var validated_q006_windmill_unlocked := false
	if is_q006_schema or is_q007_schema or is_q008_schema or is_q009_schema or is_q010_schema or is_q011_schema or is_q012_schema:
		var q006_inventory_data = data.get("q006_decor_inventory")
		var q006_placed_data = data.get("q006_decor_placed")
		var q006_slots_data = data.get("q006_slot_occupants")
		var q006_proof_data = data.get("q006_completion_proof")
		if not q006_inventory_data is Array or q006_inventory_data.size() != Q006_DECOR_TOTAL:
			return false
		if not q006_placed_data is Array or q006_placed_data.size() != Q006_DECOR_TOTAL:
			return false
		if not q006_slots_data is Array or q006_slots_data.size() != Q006_SLOT_TOTAL:
			return false
		if not q006_proof_data is Array or q006_proof_data.size() != Q006_DECOR_TOTAL:
			return false
		for i in range(Q006_DECOR_TOTAL):
			if typeof(q006_inventory_data[i]) != TYPE_BOOL or typeof(q006_placed_data[i]) != TYPE_BOOL or typeof(q006_proof_data[i]) != TYPE_BOOL:
				return false
			validated_q006_decor_inventory[i] = q006_inventory_data[i]
			validated_q006_decor_placed[i] = q006_placed_data[i]
			validated_q006_completion_proof[i] = q006_proof_data[i]
		for i in range(Q006_SLOT_TOTAL):
			if (typeof(q006_slots_data[i]) != TYPE_INT and typeof(q006_slots_data[i]) != TYPE_FLOAT) or not is_equal_approx(float(q006_slots_data[i]), round(float(q006_slots_data[i]))) or q006_slots_data[i] < -1 or q006_slots_data[i] >= Q006_DECOR_TOTAL:
				return false
			validated_q006_slot_occupants[i] = int(q006_slots_data[i])
		if typeof(data.get("q006_completed")) != TYPE_BOOL or typeof(data.get("q006_windmill_unlocked")) != TYPE_BOOL:
			return false
		validated_q006_completed = data["q006_completed"]
		validated_q006_windmill_unlocked = data["q006_windmill_unlocked"]
		if not validated_seed_planted and (validated_q006_decor_placed.has(true) or validated_q006_completion_proof.has(true) or validated_q006_completed or validated_q006_windmill_unlocked):
			return false
		if not validated_seed_planted:
			if validated_q006_decor_inventory.has(true) or validated_q006_decor_placed.has(true) or validated_q006_completion_proof.has(true):
				return false
		else:
			for i in range(Q006_DECOR_TOTAL):
				if validated_q006_decor_inventory[i] == validated_q006_decor_placed[i]:
					return false
				if validated_q006_decor_placed[i] and not validated_q006_completion_proof[i]:
					return false
		var seen_decorations: Array[int] = []
		for slot_id in range(Q006_SLOT_TOTAL):
			var decor_id: int = validated_q006_slot_occupants[slot_id]
			if decor_id < 0:
				continue
			if seen_decorations.has(decor_id) or not validated_q006_decor_placed[decor_id]:
				return false
			seen_decorations.append(decor_id)
		for decor_id in range(Q006_DECOR_TOTAL):
			if validated_q006_decor_placed[decor_id] and not seen_decorations.has(decor_id):
				return false
		if validated_q006_completed:
			if not _all_flags_true(validated_q006_completion_proof) or not validated_q006_windmill_unlocked:
				return false
		elif validated_q006_windmill_unlocked:
			return false

	var validated_q007_shell_collected := false
	var validated_q007_completed := false
	var validated_q007_reward_unlocked := false
	if is_q007_schema or is_q008_schema or is_q009_schema or is_q010_schema or is_q011_schema or is_q012_schema:
		if typeof(data.get("q007_shell_collected")) != TYPE_BOOL:
			return false
		if typeof(data.get("q007_completed")) != TYPE_BOOL:
			return false
		if typeof(data.get("q007_reward_unlocked")) != TYPE_BOOL:
			return false
		validated_q007_shell_collected = data["q007_shell_collected"]
		validated_q007_completed = data["q007_completed"]
		validated_q007_reward_unlocked = data["q007_reward_unlocked"]
	if (validated_q007_shell_collected or validated_q007_completed or validated_q007_reward_unlocked) and not validated_pond_opened:
		return false
	var expected_q007_complete := validated_q007_shell_collected
	if validated_q007_completed != expected_q007_complete:
		return false
	if validated_q007_reward_unlocked != expected_q007_complete:
		return false

	var validated_q008_path_slot_occupants: Array[int] = [-1, -1, -1]
	var validated_q008_completed := false
	if is_q008_schema or is_q009_schema or is_q010_schema or is_q011_schema or is_q012_schema:
		var q008_slots_data = data.get("q008_path_slot_occupants")
		if not q008_slots_data is Array or q008_slots_data.size() != Q008_PATH_SLOT_TOTAL:
			return false
		var seen_q008_materials: Array[int] = []
		for i in range(Q008_PATH_SLOT_TOTAL):
			var material_value = q008_slots_data[i]
			if (typeof(material_value) != TYPE_INT and typeof(material_value) != TYPE_FLOAT) or not is_equal_approx(float(material_value), round(float(material_value))) or material_value < -1 or material_value >= Q008_PATH_SLOT_TOTAL:
				return false
			var material_id := int(material_value)
			if material_id >= 0:
				if seen_q008_materials.has(material_id):
					return false
				seen_q008_materials.append(material_id)
			validated_q008_path_slot_occupants[i] = material_id
		if typeof(data.get("q008_completed")) != TYPE_BOOL:
			return false
		validated_q008_completed = data["q008_completed"]
	if _array_has_q008_progress(validated_q008_path_slot_occupants) and not expected_complete:
		return false
	var expected_q008_complete := _all_q008_slots_occupied(validated_q008_path_slot_occupants)
	if validated_q008_completed != expected_q008_complete:
		return false

	var validated_q009_materials_collected: Array[bool] = [false, false, false]
	var validated_q009_completed := false
	if is_q009_schema or is_q010_schema or is_q011_schema or is_q012_schema:
		var q009_materials_data = data.get("q009_materials_collected")
		if not q009_materials_data is Array or q009_materials_data.size() != Q009_MATERIAL_TOTAL:
			return false
		for i in range(Q009_MATERIAL_TOTAL):
			if typeof(q009_materials_data[i]) != TYPE_BOOL:
				return false
			validated_q009_materials_collected[i] = q009_materials_data[i]
		if typeof(data.get("q009_completed")) != TYPE_BOOL:
			return false
		validated_q009_completed = data["q009_completed"]
	if _all_flags_true(validated_q009_materials_collected) and not validated_q004_completed:
		return false
	if validated_q009_materials_collected.has(true) and not validated_q004_completed:
		return false
	var expected_q009_complete := _all_flags_true(validated_q009_materials_collected)
	if validated_q009_completed != expected_q009_complete:
		return false

	var validated_q010_seeds_collected: Array[bool] = [false, false, false]
	if is_q010_schema or is_q011_schema or is_q012_schema:
		var q010_seeds_data = data.get("q010_seeds_collected")
		if not q010_seeds_data is Array or q010_seeds_data.size() != Q010_SEED_TOTAL:
			return false
		for i in range(Q010_SEED_TOTAL):
			if typeof(q010_seeds_data[i]) != TYPE_BOOL:
				return false
			validated_q010_seeds_collected[i] = q010_seeds_data[i]
	if validated_q010_seeds_collected.has(true) and not expected_q005_complete:
		return false

	var validated_q011_slot_occupants: Array[int] = [-1, -1, -1]
	if is_q011_schema or is_q012_schema:
		var q011_slots_data = data.get("q011_slot_occupants")
		if not q011_slots_data is Array or q011_slots_data.size() != Q011_ITEM_TOTAL:
			return false
		var seen_q011_items: Array[int] = []
		for slot_id in range(Q011_ITEM_TOTAL):
			var occupant = q011_slots_data[slot_id]
			if (typeof(occupant) != TYPE_INT and typeof(occupant) != TYPE_FLOAT) or not is_equal_approx(float(occupant), round(float(occupant))) or occupant < -1 or occupant >= Q011_ITEM_TOTAL:
				return false
			var item_id := int(occupant)
			if item_id >= 0:
				if seen_q011_items.has(item_id):
					return false
				seen_q011_items.append(item_id)
			validated_q011_slot_occupants[slot_id] = item_id
		var completed_prior_tasks := 0
		if expected_complete:
			completed_prior_tasks += 1
		if validated_seed_planted:
			completed_prior_tasks += 1
		if expected_pond_complete and validated_pond_opened:
			completed_prior_tasks += 1
		if validated_q004_completed and validated_fox_moved_in:
			completed_prior_tasks += 1
		if validated_q005_completed and expected_q005_complete:
			completed_prior_tasks += 1
		if validated_q006_completed and validated_q006_windmill_unlocked and _all_flags_true(validated_q006_completion_proof):
			completed_prior_tasks += 1
		if validated_q007_completed and validated_q007_shell_collected and validated_q007_reward_unlocked:
			completed_prior_tasks += 1
		if validated_q008_completed and expected_complete and _all_q008_slots_occupied(validated_q008_path_slot_occupants):
			completed_prior_tasks += 1
		if validated_q009_completed and validated_q004_completed and _all_flags_true(validated_q009_materials_collected):
			completed_prior_tasks += 1
		if expected_q005_complete and _all_flags_true(validated_q010_seeds_collected):
			completed_prior_tasks += 1
		if seen_q011_items.size() > 0 and completed_prior_tasks < 3:
			return false

	var validated_q012_completed := false
	if is_q012_schema:
		if typeof(data.get("q012_completed")) != TYPE_BOOL:
			return false
		validated_q012_completed = data["q012_completed"]
	if validated_q012_completed and not validated_q006_completed:
		return false

	collected = validated_collected
	placed = validated_placed
	quest_completed = data["quest_completed"]
	bridge_repaired = data["bridge_repaired"]
	area_unlocked = data["area_unlocked"]
	seed_collected = validated_seed_collected
	seed_planted = validated_seed_planted
	pond_stones_placed = validated_pond_stones
	pond_opened = validated_pond_opened
	wood_collected = validated_wood_collected
	wood_delivered = validated_wood_delivered
	q004_completed = validated_q004_completed
	fox_moved_in = validated_fox_moved_in
	q005_watered = validated_q005_watered
	q005_plants_collected = validated_q005_plants_collected
	q005_plant_slots = validated_q005_plant_slots
	q005_completed = validated_q005_completed
	q006_decor_inventory = validated_q006_decor_inventory
	q006_decor_placed = validated_q006_decor_placed
	q006_slot_occupants = validated_q006_slot_occupants
	q006_completion_proof = validated_q006_completion_proof
	q006_completed = validated_q006_completed
	q006_windmill_unlocked = validated_q006_windmill_unlocked
	q007_shell_collected = validated_q007_shell_collected
	q007_completed = validated_q007_completed
	q007_reward_unlocked = validated_q007_reward_unlocked
	q008_path_slot_occupants = validated_q008_path_slot_occupants
	q008_completed = validated_q008_completed
	q009_materials_collected = validated_q009_materials_collected
	q009_completed = validated_q009_completed
	q010_seeds_collected = validated_q010_seeds_collected
	q011_slot_occupants = validated_q011_slot_occupants
	q012_completed = validated_q012_completed
	return true


func _all_flags_true(values: Array[bool]) -> bool:
	for value in values:
		if not value:
			return false
	return true


func _array_has_q008_progress(values: Array[int]) -> bool:
	for value in values:
		if value >= 0:
			return true
	return false


func _all_q008_slots_occupied(values: Array[int]) -> bool:
	for value in values:
		if value < 0:
			return false
	return true
