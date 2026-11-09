extends SceneTree
const Guide = preload("res://scripts/game/island_guidance.gd")
var failures := 0
func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL ", label)
func _init() -> void:
	call_deferred("run")
func run() -> void:
	var main = load("res://scenes/boot/Main.tscn").instantiate()
	root.size = Vector2i(1280, 720)
	root.add_child(main)
	main.game_state.reset()
	var s = main.game_state
	check(Guide.stage(s) == "q001_collect", "Q001 collect")
	s.collect_board(0)
	check(Guide.stage(s) == "q001_deliver", "Q001 carrying wood points to bridge")
	s.place_board(0, 0)
	for i in [1, 2]:
		s.collect_board(i)
		s.place_board(i, i)
	check(Guide.stage(s) == "q002_seed", "bridge completion points to seed")
	check(main._planting_focus_target() == 0.0, "no seed means no planting outline")
	s.collect_seed()
	check(Guide.stage(s) == "q002_plant", "carried seed points to soil")
	main.player_position = main.FLOWERBED_POSITION + Vector2(-100, 0)
	var near_strength: float = main._planting_focus_target()
	main.player_position = main.FLOWERBED_POSITION + Vector2(-40, 0)
	check(main._planting_focus_target() > near_strength and near_strength > 0, "two levels of planting feedback")
	s.plant_seed()
	check(main._planting_focus_target() == 0.0 and Guide.stage(s) == "q004_collect", "no repeated planting after completion")
	check(not main._house_delivery_available(), "no carried materials means no house delivery outline")
	for i in range(3):
		s.collect_wood(i)
		check(Guide.stage(s) == "q004_deliver" and main._house_delivery_available(), "each carried material points to house")
		s.deliver_next_wood()
		check(s.delivered_wood_count() == i + 1, "delivery progress preserved")
		check(not main._house_delivery_available(), "delivered materials do not keep delivery active")
	check(Guide.stage(s) == "q003_pond", "completed house points to unlocked pond")
	for i in range(3):
		s.place_pond_stone(i)
	check(Guide.stage(s) == "q005_water", "pond completion points to watering")
	s.water_q005()
	check(Guide.stage(s) == "q005_harvest", "watered garden points to harvesting")
	for i in range(3):
		s.collect_q005_plant(i)
	check(Guide.stage(s) == "q005_deliver", "flower bundle points to turtle")
	s.deliver_q005_harvest()
	check(Guide.stage(s) == "q006_decor", "garden completion points to decorations")
	for i in range(3):
		s.place_q006_decoration(i, i)
	check(Guide.stage(s) == "q012_celebrate", "main story points to celebration")
	s.complete_q012()
	check(Guide.stage(s) == "q007_shell", "optional quests unlock after celebration")
	s.collect_q007_shell()
	check(Guide.stage(s) == "q009_collect", "birdhouse material guidance")
	for i in range(3):
		s.collect_q009_material(i)
	check(Guide.stage(s) == "q009_deliver", "birdhouse delivery guidance")
	for i in range(3):
		s.deliver_next_q009_material()
	check(Guide.stage(s) == "q010_collect", "seed collection guidance")
	for i in range(3):
		s.collect_q010_seed(i)
	check(Guide.stage(s) == "q008_path", "path guidance")
	for i in range(3):
		s.place_q008_path(i, i)
	check(Guide.stage(s) == "q011_start" and Guide.stage(s, false, true) == "q011_tidy", "selected tidy task takes priority")
	check(Guide.stage(s, true, false) == "q006_decor", "selected decoration task takes priority")
	for i in range(3):
		s.place_q011_item(i, i)
	check(Guide.stage(s) == "free", "finished quests do not repeat old requests")
	var snapshot := JSON.stringify(s.to_save_data())
	main._guidance_details()
	check(JSON.stringify(s.to_save_data()) == snapshot, "asking for help is read-only")
	main.rabbit_help_requested = true
	main.rabbit_target_remaining = 4.0
	main.house_focus_level = 0.95
	main._restart_game()
	check(not main.rabbit_help_requested and main.rabbit_target_remaining == 0.0 and main.house_focus_level == 0.0, "confirmed restart clears transient guidance without stale target effects")
	print("child guidance failures=", failures)
	quit(0 if failures == 0 else 1)
