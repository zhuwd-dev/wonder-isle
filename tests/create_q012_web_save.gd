extends SceneTree

const GameState = preload("res://scripts/game/game_state.gd")


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("Q012 browser fixture requires an output path")
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
	for decor_id in range(GameState.Q006_DECOR_TOTAL):
		state.place_q006_decoration(decor_id, decor_id)

	if not state.is_q006_complete() or state.is_q012_complete():
		push_error("Q012 browser fixture must stop after the garden decoration and before the ending")
		quit(1)
		return

	var file := FileAccess.open(str(args[0]), FileAccess.WRITE)
	if file == null:
		push_error("Could not create Q012 browser fixture")
		quit(1)
		return
	file.store_string(JSON.stringify(state.to_save_data()))
	file.close()
	print("Created Q012 browser fixture: ", args[0])
	quit()
