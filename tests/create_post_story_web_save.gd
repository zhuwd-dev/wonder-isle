extends SceneTree

const GameState = preload("res://scripts/game/game_state.gd")


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("Post-story browser fixture requires an output path")
		quit(2)
		return

	var state := GameState.new()
	for board_id in range(GameState.BOARD_TOTAL):
		state.collect_board(board_id)
		state.place_board(board_id, board_id)
	state.collect_seed()
	state.plant_seed()
	for wood_id in range(GameState.Q004_WOOD_TOTAL):
		state.collect_wood(wood_id)
		state.deliver_wood(wood_id)
	for stone_id in range(GameState.POND_STONE_TOTAL):
		state.place_pond_stone(stone_id)
	state.water_q005()
	for plant_id in range(GameState.Q005_PLANT_TOTAL):
		state.collect_q005_plant(plant_id)
		state.place_q005_plant(plant_id, plant_id)
	state.deliver_q005_harvest()
	for decor_id in range(GameState.Q006_DECOR_TOTAL):
		state.place_q006_decoration(decor_id, decor_id)
	state.complete_q012()

	if not state.is_q012_complete() or state.is_q007_complete():
		push_error("Post-story browser fixture must unlock optional quests and stop before Q007")
		quit(1)
		return
	var restored := GameState.new()
	if not restored.load_save_data(state.to_save_data()) or not restored.is_q012_complete():
		push_error("Post-story browser fixture must round-trip through save validation")
		quit(1)
		return

	var file := FileAccess.open(str(args[0]), FileAccess.WRITE)
	if file == null:
		push_error("Could not create post-story browser fixture")
		quit(1)
		return
	file.store_string(JSON.stringify(state.to_save_data()))
	file.close()
	print("Created post-story browser fixture: ", args[0])
	quit()
