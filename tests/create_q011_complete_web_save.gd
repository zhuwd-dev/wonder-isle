extends SceneTree

const GameState = preload("res://scripts/game/game_state.gd")


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("Q011 browser fixture requires an output path")
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
	state.complete_q012()
	state.collect_q007_shell()
	for material_id in range(GameState.Q009_MATERIAL_TOTAL):
		state.collect_q009_material(material_id)
	for seed_id in range(GameState.Q010_SEED_TOTAL):
		state.collect_q010_seed(seed_id)
	for path_id in range(GameState.Q008_PATH_SLOT_TOTAL):
		state.place_q008_path(path_id, path_id)
	for item_id in range(GameState.Q011_ITEM_TOTAL):
		state.place_q011_item(item_id, item_id)
	if not state.is_q011_complete():
		push_error("Q011 browser fixture must represent a finished island")
		quit(1)
		return

	var file := FileAccess.open(str(args[0]), FileAccess.WRITE)
	if file == null:
		push_error("Could not create Q011 browser fixture")
		quit(1)
		return
	file.store_string(JSON.stringify(state.to_save_data()))
	file.close()
	print("Created Q011 browser fixture: ", args[0])
	quit()
