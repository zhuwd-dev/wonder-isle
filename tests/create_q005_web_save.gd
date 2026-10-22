extends SceneTree

const GameState = preload("res://scripts/game/game_state.gd")


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("Q005 browser fixture requires an output path")
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

	if not state.can_start_q005() or state.q005_watered or state.q005_plant_count() > 0:
		push_error("Q005 browser fixture must stop before watering or plant collection")
		quit(1)
		return

	var file := FileAccess.open(str(args[0]), FileAccess.WRITE)
	if file == null:
		push_error("Could not create Q005 browser fixture")
		quit(1)
		return
	file.store_string(JSON.stringify(state.to_save_data()))
	file.close()
	print("Created Q005 browser fixture: ", args[0])
	quit()
