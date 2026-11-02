extends RefCounted
## Read-only objective selection; never mutates progress or introduces prerequisites.
static func stage(state, decorating := false, tidying := false) -> String:
	if tidying and state.can_start_q011():
		return "q011_tidy"
	if decorating and state.can_edit_q006():
		return "q006_decor"
	if not state.is_complete():
		return "q001_deliver" if state.board_count() > state.placed_count() else "q001_collect"
	if not state.seed_collected:
		return "q002_seed"
	if not state.seed_planted:
		return "q002_plant"
	if not state.is_q004_complete():
		return "q004_deliver" if state.wood_count() > state.delivered_wood_count() else "q004_collect"
	if not state.is_pond_complete():
		return "q003_pond"
	if not state.is_q005_complete():
		if not state.q005_watered:
			return "q005_water"
		return "q005_deliver" if state.q005_plant_count() == 3 else "q005_harvest"
	if not state.is_q006_complete():
		return "q006_decor"
	if not state.is_q012_complete():
		return "q012_celebrate"
	if not state.is_q007_complete():
		return "q007_shell"
	if not state.is_q009_complete():
		return "q009_deliver" if state.q009_material_count() == 3 else "q009_collect"
	if not state.is_q010_complete():
		return "q010_collect"
	if not state.is_q008_complete():
		return "q008_path"
	if not state.is_q011_complete():
		return "q011_start"
	return "free"
