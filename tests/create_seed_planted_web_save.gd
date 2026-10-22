extends SceneTree

const GameState = preload("res://scripts/game/game_state.gd")


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("Seed-planted browser fixture requires an output path")
		quit(2)
		return

	var state := GameState.new()
	for board_id in range(GameState.BOARD_TOTAL):
		state.collect_board(board_id)
		state.place_board(board_id, board_id)
	state.collect_seed()
	state.plant_seed()
	if not state.seed_planted or state.is_q004_complete():
		push_error("Seed-planted browser fixture must stop before the fox task")
		quit(1)
		return

	var file := FileAccess.open(str(args[0]), FileAccess.WRITE)
	if file == null:
		push_error("Could not create seed-planted browser fixture")
		quit(1)
		return
	file.store_string(JSON.stringify(state.to_save_data()))
	file.close()
	print("Created seed-planted browser fixture: ", args[0])
	quit()
