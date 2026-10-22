extends SceneTree

var save_path := ""

var failures := 0
var mode := ""


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	mode = str(args[0]) if not args.is_empty() else ""
	for index in range(max(args.size() - 1, 0)):
		if str(args[index]) == "--test-save-path":
			save_path = str(args[index + 1])
			break
	call_deferred("_run")


func _run() -> void:
	if save_path.is_empty():
		_fail("存档测试必须提供 --test-save-path，禁止写入正式存档")
		_finish()
		return
	if mode == "write":
		await _write_completed_save()
	elif mode == "write-bridge":
		await _write_bridge_save()
	elif mode == "write-pond-start":
		await _write_pond_start_save()
	elif mode == "write-pond-progress":
		await _write_pond_progress_save()
	elif mode == "read-pond-progress":
		await _read_pond_progress_after_process_restart()
	elif mode == "write-q004-progress":
		await _write_q004_progress_save()
	elif mode == "read-q004-progress":
		await _read_q004_progress_after_process_restart()
	elif mode == "write-q004-complete":
		await _write_q004_complete_save()
	elif mode == "read-q004-complete":
		await _read_q004_complete_after_process_restart()
	elif mode == "write-all-complete":
		await _write_all_complete_save()
	elif mode == "read":
		await _read_after_process_restart()
	elif mode == "final-read":
		await _read_planted_after_process_restart()
	else:
		_fail("用法要求 user arg 为 write、write-bridge、write-pond-start、write-pond-progress、read-pond-progress、write-q004-progress、read-q004-progress、write-q004-complete、read-q004-complete、write-all-complete、read 或 final-read")
	_finish()


func _spawn_main():
	var scene = load("res://scenes/boot/Main.tscn")
	var instance = scene.instantiate()
	root.add_child(instance)
	await process_frame
	_expect(instance.get("save_path") == save_path, "存档测试必须使用专用存档路径")
	return instance


func _write_completed_save() -> void:
	var main = await _spawn_main()
	main._restart_game()
	for board_id in range(3):
		main.game_state.collect_board(board_id)
	for board_id in range(3):
		main.game_state.place_board(board_id, board_id)
	_expect(main.game_state.collect_seed(), "修桥完成后应能收集种子")
	main._save_game()
	var saved = _read_save()
	_expect(saved is Dictionary, "写入后应能读取 JSON 存档")
	_expect(saved.get("schema_version") == 11, "存档 schema_version 应为 11")
	_expect(saved.get("collected") == [true, true, true], "存档应记录 3 块木板已收集")
	_expect(saved.get("placed") == [true, true, true], "存档应记录 3 块木板已放置")
	_expect(saved.get("quest_completed") == true, "存档应记录任务完成")
	_expect(saved.get("bridge_repaired") == true, "存档应记录桥已修复")
	_expect(saved.get("area_unlocked") == true, "存档应记录区域已开放")
	_expect(saved.get("seed_collected") == true, "存档应记录种子已收集")
	_expect(saved.get("seed_planted") == false, "首次跨进程测试应保留未种植状态")
	_expect(saved.get("pond_stones_placed") == [false, false, false], "存档应记录池塘石头尚未放置")
	_expect(saved.get("pond_opened") == false, "存档应记录池塘尚未开放")
	_expect(saved.get("wood_collected") == [false, false, false], "存档应记录 Q004 木材尚未收集")
	_expect(saved.get("wood_delivered") == [false, false, false], "存档应记录 Q004 木材尚未交付")
	_expect(saved.get("q004_completed") == false and saved.get("fox_moved_in") == false, "存档应记录 Q004 尚未完成")
	main.queue_free()


func _write_bridge_save() -> void:
	var main = await _spawn_main()
	main._restart_game()
	for board_id in range(3):
		main.game_state.collect_board(board_id)
	for board_id in range(3):
		main.game_state.place_board(board_id, board_id)
	main._save_game()
	var saved = _read_save()
	_expect(saved is Dictionary, "桥完成截图存档应可读取")
	_expect(saved.get("schema_version") == 11, "桥完成截图存档应使用 Schema 11")
	_expect(saved.get("quest_completed") == true, "桥完成截图存档应记录任务完成")
	_expect(saved.get("seed_collected") == false, "桥完成截图应保留未收集种子状态")
	_expect(saved.get("seed_planted") == false, "桥完成截图应保留未种植状态")
	main.queue_free()


func _write_pond_start_save() -> void:
	var main = await _spawn_main()
	main._restart_game()
	for board_id in range(3):
		main.game_state.collect_board(board_id)
	for board_id in range(3):
		main.game_state.place_board(board_id, board_id)
	main.game_state.collect_seed()
	main.game_state.plant_seed()
	main._save_game()
	var saved = _read_save()
	_expect(saved.get("schema_version") == 11, "池塘开始态存档应使用 Schema 11")
	_expect(saved.get("seed_planted") == true, "池塘开始态应记录种子已种植")
	_expect(saved.get("pond_stones_placed") == [false, false, false], "池塘开始态不应有已放置石头")
	main.queue_free()


func _write_pond_progress_save() -> void:
	var main = await _spawn_main()
	main._restart_game()
	for board_id in range(3):
		main.game_state.collect_board(board_id)
	for board_id in range(3):
		main.game_state.place_board(board_id, board_id)
	main.game_state.collect_seed()
	main.game_state.plant_seed()
	main.game_state.place_pond_stone(0)
	main._save_game()
	var saved = _read_save()
	_expect(saved.get("schema_version") == 11, "池塘进行态存档应使用 Schema 11")
	_expect(saved.get("pond_stones_placed") == [true, false, false], "池塘进行态应记录 1 块已放置石头")
	_expect(saved.get("pond_opened") == false, "池塘进行态不应提前开放池塘")
	main.queue_free()


func _read_pond_progress_after_process_restart() -> void:
	var main = await _spawn_main()
	_expect(main.game_state.is_seed_complete(), "池塘中途恢复前应保留已种植状态")
	_expect(main.game_state.pond_stones_placed == [true, false, false], "新进程应恢复已放置的第 1 块石头")
	_expect(not main.game_state.is_pond_complete(), "中途恢复不应提前开放池塘")
	_expect(main._task_prompt_text() == "任务：帮狐狸建小屋。先收集 3 份木材。", "中途恢复后应显示狐狸小屋任务提示")
	var locked_stone_position: Vector2 = main.POND_STONE_POSITIONS[1]
	main._pointer_down(locked_stone_position)
	_expect(main.dragging_pond_stone == -1, "旧存档中的池塘进度应在狐狸入住前保持锁定")
	for wood_id in range(3):
		_expect(main.game_state.collect_wood(wood_id), "恢复池塘存档后应能收集狐狸小屋木材")
		_expect(main.game_state.deliver_wood(wood_id), "恢复池塘存档后应能交付狐狸小屋木材")
	_expect(main.game_state.is_q004_complete(), "交付木材后狐狸小屋应完成并开放池塘任务")
	for stone_id in [1, 2]:
		var stone_position: Vector2 = main.POND_STONE_POSITIONS[stone_id]
		var slot_position: Vector2 = main.POND_SLOTS[stone_id].position + main.POND_SLOTS[stone_id].size / 2.0
		main._pointer_down(stone_position)
		main._pointer_up(slot_position)
	_expect(main.game_state.is_pond_complete(), "恢复中途进度后放置剩余石头应开放池塘")
	_expect(_read_save().get("pond_opened") == true, "中途恢复完成后应立即保存池塘开放状态")
	main.queue_free()
	await process_frame


func _write_q004_progress_save() -> void:
	var main = await _spawn_main()
	main._restart_game()
	for board_id in range(3):
		main.game_state.collect_board(board_id)
		main.game_state.place_board(board_id, board_id)
	main.game_state.collect_seed()
	main.game_state.plant_seed()
	_expect(main.game_state.collect_wood(0), "Q004 部分进度应能收集第 1 份木材")
	_expect(main.game_state.deliver_wood(0), "Q004 部分进度应能交付第 1 份木材")
	main._save_game()
	var saved = _read_save()
	_expect(saved.get("schema_version") == 11, "Q004 部分进度存档应使用 Schema 11")
	_expect(saved.get("wood_collected") == [true, false, false], "Q004 部分进度应保存木材收集状态")
	_expect(saved.get("wood_delivered") == [true, false, false], "Q004 部分进度应保存木材交付状态")
	_expect(saved.get("q004_completed") == false and saved.get("fox_moved_in") == false, "Q004 部分进度不应提前完成")
	_expect(saved.get("pond_stones_placed") == [false, false, false], "Q004 不应改变 Q003 状态")
	main.queue_free()


func _read_q004_progress_after_process_restart() -> void:
	var main = await _spawn_main()
	_expect(main.game_state.can_start_q004(), "Q004 部分进度恢复后应保持可进行")
	_expect(main.game_state.wood_collected == [true, false, false], "Q004 应恢复已收集的第 1 份木材")
	_expect(main.game_state.wood_delivered == [true, false, false], "Q004 应恢复已交付的第 1 份木材")
	_expect(not main.game_state.is_q004_complete(), "Q004 部分进度恢复后不应完成")
	_expect(not main.game_state.is_pond_complete(), "Q004 部分进度恢复不应开放池塘")
	_expect(main._task_prompt_text() == "木材已收集 1/3，已交付 1/3；继续寻找木材。", "Q004 部分进度恢复后应显示木材进度")
	for wood_id in [1, 2]:
		_expect(main.game_state.collect_wood(wood_id), "恢复后应能继续收集剩余木材")
		_expect(main.game_state.deliver_wood(wood_id), "恢复后应能继续交付剩余木材")
	main._save_game()
	_expect(main.game_state.is_q004_complete(), "恢复后完成剩余交付应完成 Q004")
	_expect(not main.game_state.is_pond_complete(), "Q004 完成不应改变 Q003")
	main.queue_free()
	await process_frame


func _write_q004_complete_save() -> void:
	var main = await _spawn_main()
	main._restart_game()
	for board_id in range(3):
		main.game_state.collect_board(board_id)
		main.game_state.place_board(board_id, board_id)
	main.game_state.collect_seed()
	main.game_state.plant_seed()
	for wood_id in range(3):
		main.game_state.collect_wood(wood_id)
		main.game_state.deliver_wood(wood_id)
	main._save_game()
	var saved = _read_save()
	_expect(saved.get("wood_collected") == [true, true, true], "Q004 完成存档应保存全部木材收集")
	_expect(saved.get("wood_delivered") == [true, true, true], "Q004 完成存档应保存全部木材交付")
	_expect(saved.get("q004_completed") == true and saved.get("fox_moved_in") == true, "Q004 完成存档应保存狐狸入住")
	_expect(saved.get("pond_stones_placed") == [false, false, false], "Q004 完成不应改变 Q003 状态")
	main.queue_free()


func _read_q004_complete_after_process_restart() -> void:
	var main = await _spawn_main()
	_expect(main.game_state.is_q004_complete(), "Q004 完成状态应跨进程恢复")
	_expect(main.game_state.fox_moved_in, "跨进程恢复后应保留狐狸入住")
	_expect(not main.game_state.is_pond_complete(), "Q004 完成后 Q003 仍应保持未完成")
	_expect(main._task_prompt_text() == "狐狸已经入住！池塘石头还可以继续摆好。", "Q004 完成恢复后应引导继续 Q003")
	main._restart_game()
	_expect(not main.game_state.can_start_q004(), "重新开始应锁定 Q004")
	_expect(main.game_state.wood_collected == [false, false, false], "重新开始应清除 Q004 木材收集")
	_expect(main.game_state.wood_delivered == [false, false, false], "重新开始应清除 Q004 木材交付")
	_expect(not main.game_state.q004_completed and not main.game_state.fox_moved_in, "重新开始应清除 Q004 完成和狐狸入住")
	main.queue_free()
	await process_frame


func _write_all_complete_save() -> void:
	var main = await _spawn_main()
	main._restart_game()
	for board_id in range(3):
		main.game_state.collect_board(board_id)
		main.game_state.place_board(board_id, board_id)
	main.game_state.collect_seed()
	main.game_state.plant_seed()
	for wood_id in range(3):
		main.game_state.collect_wood(wood_id)
		main.game_state.deliver_wood(wood_id)
	for stone_id in range(3):
		main.game_state.place_pond_stone(stone_id)
	main._save_game()
	var saved = _read_save()
	_expect(saved.get("q004_completed") == true and saved.get("fox_moved_in") == true, "全任务完成存档应保存 Q004 完成")
	_expect(saved.get("pond_stones_placed") == [true, true, true] and saved.get("pond_opened") == true, "全任务完成存档应保存 Q003 完成")
	main.queue_free()


func _read_after_process_restart() -> void:
	var main = await _spawn_main()
	_expect(main.game_state.is_complete(), "新进程启动后应从磁盘恢复完成状态")
	_expect(main.game_state.board_count() == 3, "新进程恢复后的木板数量应为 3")
	_expect(main.game_state.bridge_repaired, "新进程恢复后桥应为已修复")
	_expect(main.game_state.area_unlocked, "新进程恢复后区域应为已开放")
	_expect(main.game_state.seed_collected, "新进程恢复后应保留种子收集状态")
	_expect(not main.game_state.seed_planted, "新进程恢复后种子应仍未种植")
	_expect(main._task_prompt_text() == "种子已找到，请到右侧花圃种下。", "种子未种植存档加载后应显示种植引导")
	main.player_position = main.FLOWERBED_POSITION
	main._try_collect_nearby()
	_expect(main.game_state.seed_planted, "花圃交互后应保存种植状态")
	_expect(_read_save().get("seed_planted") == true, "种植后应立即写入存档")
	_expect(main._task_prompt_text() == "任务：帮狐狸建小屋。先收集 3 份木材。", "种植后应进入狐狸小屋任务")
	for wood_id in range(3):
		_expect(main.game_state.collect_wood(wood_id), "种下种子后应能收集狐狸小屋木材")
		_expect(main.game_state.deliver_wood(wood_id), "种下种子后应能交付狐狸小屋木材")
	_expect(main._task_prompt_text() == "狐狸已经入住！池塘石头还可以继续摆好。", "狐狸入住后应切换到池塘整理任务")
	for stone_id in range(3):
		var stone_position: Vector2 = main.POND_STONE_POSITIONS[stone_id]
		var slot_position: Vector2 = main.POND_SLOTS[stone_id].position + main.POND_SLOTS[stone_id].size / 2.0
		main._pointer_down(stone_position)
		main._pointer_up(slot_position)
	_expect(main.game_state.is_pond_complete(), "跨进程流程中放置 3 块石头后应开放池塘")
	_expect(_read_save().get("pond_opened") == true, "池塘完成后应立即写入存档")
	main.queue_free()
	await process_frame


func _read_planted_after_process_restart() -> void:
	var main = await _spawn_main()
	_expect(main.game_state.is_seed_complete(), "再次启动后应恢复已种植状态")
	_expect(main.game_state.seed_collected, "已种植状态必须同时保留种子收集状态")
	_expect(main.game_state.is_pond_complete(), "再次启动后应恢复池塘开放状态")
	_expect(main._task_prompt_text() == "任务：照料乌龟的花园。先浇水并收集 3 株植物。", "池塘完成存档加载后应显示 Q005 引导")
	main.queue_free()
	await process_frame

	var invalid_file := FileAccess.open(save_path, FileAccess.WRITE)
	invalid_file.store_string("{\"schema_version\":\"bad\",\"collected\":[true]}")
	invalid_file.close()
	var recovered = await _spawn_main()
	_expect(not recovered.game_state.is_complete(), "损坏存档不应恢复为完成状态")
	_expect(recovered.game_state.board_count() == 0, "损坏存档应安全回到新游戏状态")
	_expect(not recovered.game_state.seed_collected and not recovered.game_state.seed_planted, "损坏存档恢复后种子状态应清空")
	recovered._restart_game()
	_expect(recovered._task_prompt_text() == "任务：帮助兔子修好小桥。先收集 3 块木板。", "重新开始后应恢复初始任务引导")
	var reset_data = _read_save()
	_expect(reset_data.get("collected") == [false, false, false], "重新开始应把存档收集状态重置")
	_expect(reset_data.get("placed") == [false, false, false], "重新开始应把存档放置状态重置")
	_expect(reset_data.get("quest_completed") == false, "重新开始应清除任务完成状态")
	_expect(reset_data.get("bridge_repaired") == false, "重新开始应清除桥修复状态")
	_expect(reset_data.get("area_unlocked") == false, "重新开始应锁定区域")
	_expect(reset_data.get("seed_collected") == false, "重新开始应清除种子收集状态")
	_expect(reset_data.get("seed_planted") == false, "重新开始应清除种植状态")
	_expect(reset_data.get("pond_stones_placed") == [false, false, false], "重新开始应清除池塘石头状态")
	_expect(reset_data.get("pond_opened") == false, "重新开始应关闭池塘")
	_expect(reset_data.get("wood_collected") == [false, false, false], "重新开始应清除 Q004 木材收集状态")
	_expect(reset_data.get("wood_delivered") == [false, false, false], "重新开始应清除 Q004 木材交付状态")
	_expect(reset_data.get("q004_completed") == false, "重新开始应清除 Q004 完成状态")
	_expect(reset_data.get("fox_moved_in") == false, "重新开始应清除狐狸入住状态")
	recovered.queue_free()


func _read_save():
	if not FileAccess.file_exists(save_path):
		return null
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return null
	return JSON.parse_string(file.get_as_text())


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	failures += 1
	push_error("[DiskSaveCycleTest] " + message)


func _finish() -> void:
	if failures == 0:
		print("[DiskSaveCycleTest] PASS: ", mode)
	else:
		push_error("[DiskSaveCycleTest] FAIL: %d 个断言失败" % failures)
	quit(failures)
