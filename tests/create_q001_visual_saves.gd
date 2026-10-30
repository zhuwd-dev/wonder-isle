extends SceneTree

const GameState = preload("res://scripts/game/game_state.gd")

const VISUAL_STAGES := {
	"initial": 0,
	"collected-1": 1,
	"bridge-1": 1,
	"bridge-2": 2,
	"bridge-3": 3,
}


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("Q001 visual fixtures require an output directory")
		quit(2)
		return
	var output_directory := str(args[0])
	DirAccess.make_dir_recursive_absolute(output_directory)
	for stage_name in VISUAL_STAGES:
		var state := GameState.new()
		var placed_count: int = VISUAL_STAGES[stage_name]
		if stage_name == "collected-1":
			state.collect_board(0)
		elif stage_name != "initial":
			for board_id in range(GameState.BOARD_TOTAL):
				state.collect_board(board_id)
			for board_id in range(placed_count):
				state.place_board(board_id, board_id)
		var save_path := output_directory.path_join("q001-%s.json" % stage_name)
		var file := FileAccess.open(save_path, FileAccess.WRITE)
		if file == null:
			push_error("Could not write Q001 visual fixture: %s" % save_path)
			quit(1)
			return
		file.store_string(JSON.stringify(state.to_save_data()))
		file.close()
		print("Created Q001 visual fixture: ", save_path)
	quit()
