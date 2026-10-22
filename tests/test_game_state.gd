extends SceneTree

var failures := 0


func _init() -> void:
	var state_script = load("res://scripts/game/game_state.gd")
	if state_script == null:
		_fail("GameState 脚本尚未实现")
		_finish()
		return

	var state = state_script.new()
	_expect(state.board_count() == 0, "新游戏木板数量应为 0")
	_expect(not state.place_board(0, 0), "未集齐木板时不能放置木板")
	var early_state = state_script.new()
	_expect(early_state.collect_board(0), "收集第一块木板后应能开始放置")
	_expect(early_state.place_board(0, 0), "只收集第一块木板时应能放置对应木板")
	_expect(not early_state.is_complete(), "只放置第一块木板时不能完成修桥")
	var two_board_state = state_script.new()
	two_board_state.collect_board(0)
	two_board_state.collect_board(1)
	_expect(two_board_state.place_board(0, 0), "只收集两块木板时第一块应能放置")
	_expect(two_board_state.place_board(1, 1), "只收集两块木板时第二块应能放置")
	_expect(not two_board_state.is_complete(), "只放置两块木板时不能完成修桥")
	_expect(state.collect_board(0), "应能收集第 1 块木板")
	_expect(not state.collect_board(0), "同一块木板不能重复计数")
	_expect(state.collect_board(1), "应能收集第 2 块木板")
	_expect(state.collect_board(2), "应能收集第 3 块木板")
	_expect(not state.collect_board(3), "不存在的木板不能被收集")
	_expect(state.board_count() == 3, "收集进度应为 3")
	_expect(state.can_repair_bridge(), "集齐 3 块木板后应允许修桥")
	_expect(not state.place_board(0, 1), "木板放错指定位置时应拒绝")
	_expect(state.place_board(0, 0), "木板放到对应位置时应接受")
	_expect(state.place_board(1, 1), "第 2 块木板应能正确放置")
	_expect(state.place_board(2, 2), "第 3 块木板应能正确放置")
	_expect(state.is_complete(), "3 块木板正确放置后任务应完成")
	_expect(not state.place_board(2, 2), "已放置木板不能重复触发")

	var seed_state = state_script.new()
	_expect(not seed_state.can_collect_seed(), "修桥前不能收集种子")
	_expect(not seed_state.collect_seed(), "修桥前收集种子应被拒绝")
	_expect(not seed_state.plant_seed(), "修桥前种植应被拒绝")
	for board_id in range(3):
		seed_state.collect_board(board_id)
		seed_state.place_board(board_id, board_id)
	_expect(seed_state.is_complete(), "种子任务测试前桥梁应已修复")
	_expect(seed_state.can_collect_seed(), "修桥后应允许收集种子")
	_expect(seed_state.collect_seed(), "种子应能收集")
	_expect(not seed_state.collect_seed(), "种子不能重复收集")
	_expect(seed_state.can_plant_seed(), "收集种子后应允许种植")
	_expect(seed_state.plant_seed(), "收集种子后应能种植")
	_expect(seed_state.seed_planted, "种植后应记录种植状态")
	_expect(not seed_state.plant_seed(), "种植完成后不能重复触发")
	_expect(seed_state.can_start_pond_task(), "种植完成后应开启池塘石头任务")
	_expect(seed_state.can_place_pond_stone(0), "池塘石头任务开始后应能放置石头")
	_expect(seed_state.place_pond_stone(0), "第 1 块池塘石头应能放置")
	_expect(seed_state.place_pond_stone(1), "第 2 块池塘石头应能放置")
	_expect(seed_state.place_pond_stone(2), "第 3 块池塘石头应能放置")
	_expect(seed_state.is_pond_complete(), "3 块池塘石头正确放置后应开放池塘")
	_expect(not seed_state.place_pond_stone(2), "已放置池塘石头不能重复触发")

	var seed_saved: Dictionary = seed_state.to_save_data()
	_expect(seed_saved.get("schema_version") == 11, "新增 Q010 后存档应使用 Schema 11")
	_expect(seed_saved.get("seed_collected") == true, "新存档应保存种子收集状态")
	_expect(seed_saved.get("seed_planted") == true, "新存档应保存种植状态")
	_expect(seed_saved.get("pond_stones_placed") == [true, true, true], "新存档应保存池塘石头状态")
	_expect(seed_saved.get("pond_opened") == true, "新存档应保存池塘开放状态")
	var seed_restored = state_script.new()
	_expect(seed_restored.load_save_data(seed_saved), "池塘完成存档应能加载")
	_expect(seed_restored.seed_collected and seed_restored.seed_planted, "种子完成状态应能恢复")
	_expect(seed_restored.is_pond_complete(), "池塘完成状态应能恢复")

	var legacy_save := {
		"schema_version": 1,
		"collected": [true, true, true],
		"placed": [true, true, true],
		"quest_completed": true,
		"bridge_repaired": true,
		"area_unlocked": true,
	}
	var migrated = state_script.new()
	_expect(migrated.load_save_data(legacy_save), "Schema 1 旧存档应能迁移")
	_expect(migrated.is_complete(), "旧存档桥梁完成状态应保留")
	_expect(not migrated.seed_collected and not migrated.seed_planted, "旧存档的新任务状态应默认为未完成")
	_expect(not migrated.is_pond_complete(), "旧存档的池塘任务应默认为未完成")
	_expect(migrated.to_save_data().get("schema_version") == 11, "迁移后再次保存应升级到 Schema 11")
	var schema2_save := {
		"schema_version": 2,
		"collected": [true, true, true],
		"placed": [true, true, true],
		"quest_completed": true,
		"bridge_repaired": true,
		"area_unlocked": true,
		"seed_collected": true,
		"seed_planted": true,
	}
	var migrated_schema2 = state_script.new()
	_expect(migrated_schema2.load_save_data(schema2_save), "Schema 2 存档应能迁移到池塘任务版本")
	_expect(migrated_schema2.seed_planted and not migrated_schema2.is_pond_complete(), "Schema 2 迁移后池塘任务应默认未完成")
	_expect(not migrated.load_save_data({
		"schema_version": 3,
		"collected": [true, true, true],
		"placed": [true, true, true],
		"quest_completed": true,
		"bridge_repaired": true,
		"area_unlocked": true,
		"seed_collected": true,
		"seed_planted": true,
		"pond_stones_placed": [true, false, false],
		"pond_opened": true,
	}), "种植但未收集种子的非法存档应被拒绝")
	_expect(not migrated.load_save_data({
		"schema_version": 3,
		"collected": [true, true, true],
		"placed": [true, true, true],
		"quest_completed": true,
		"bridge_repaired": true,
		"area_unlocked": true,
		"seed_collected": false,
		"seed_planted": true,
		"pond_stones_placed": [false, false, false],
		"pond_opened": false,
	}), "种植但未收集种子的 Schema 3 存档应被拒绝")
	seed_state.reset()
	_expect(not seed_state.seed_collected and not seed_state.seed_planted, "重新开始应重置种子任务状态")
	_expect(not seed_state.is_pond_complete(), "重新开始应重置池塘任务状态")

	var partial_state = state_script.new()
	for board_id in range(3):
		partial_state.collect_board(board_id)
	partial_state.place_board(0, 0)
	partial_state.place_board(1, 1)
	_expect(not partial_state.is_complete(), "two boards must not complete the quest")
	_expect(not partial_state.bridge_repaired and not partial_state.area_unlocked, "two boards must not open the bridge area")

	var saved: Dictionary = state.to_save_data()
	var restored = state_script.new()
	_expect(restored.load_save_data(saved), "合法存档应能加载")
	_expect(restored.is_complete(), "恢复后任务完成状态应保留")
	_expect(restored.board_count() == 3, "恢复后收集数量应保留")
	_expect(not restored.load_save_data({"schema_version": "错误"}), "错误存档应被拒绝")
	var state_before_invalid_save: Dictionary = restored.to_save_data()
	_expect(not restored.load_save_data({
		"schema_version": 1,
		"collected": [true, true, true],
		"placed": [true, true, true],
		"quest_completed": false,
		"bridge_repaired": true,
		"area_unlocked": true,
	}), "内部状态不一致的存档应被拒绝")
	_expect(restored.to_save_data() == state_before_invalid_save, "rejected save must not partially mutate the state")
	restored.reset()
	_expect(restored.board_count() == 0 and not restored.is_complete(), "重新开始应重置任务状态")

	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	failures += 1
	push_error("[GameStateTest] " + message)


func _finish() -> void:
	if failures == 0:
		print("[GameStateTest] PASS")
	else:
		push_error("[GameStateTest] FAIL: %d 个断言失败" % failures)
	quit(failures)
