extends "res://scripts/boot/main.gd"

const CANDIDATE_DIR := "res://assets/art/incoming/M01-turtle/walk_right/"
const CANDIDATE_FPS := 6.0
const FOOT_ANCHOR := Vector2(256.0, 440.0)
const DISPLAY_CANVAS_HEIGHT := 153.0
const PREVIEW_ROAM_SPEED := 22.0
const PREVIEW_ROAM_END := Vector2(1240.0, 280.0)

var candidate_frames: Array[Texture2D] = []
var candidate_frame := 0
var candidate_elapsed := 0.0
var candidate_label: Label
var candidate_roam_mode := false
var candidate_motion_state := "LOOP"
var candidate_collision_stopped := false
var candidate_physics_delta := 0.0
var candidate_logged_distance := 0.0
var candidate_telemetry_elapsed := 0.0


func _ready() -> void:
	super._ready()
	# Keep this sandbox deterministic and separate from every user save.
	game_state = GameState.new()
	for index in range(3):
		game_state.wood_delivered[index] = true
		game_state.placed[index] = true
		game_state.pond_stones_placed[index] = true
	game_state.q004_completed = true
	game_state.fox_moved_in = true
	game_state.quest_completed = true
	game_state.bridge_repaired = true
	game_state.area_unlocked = true
	game_state.seed_collected = true
	game_state.pond_opened = true
	game_state.seed_planted = true
	game_state.q005_watered = true
	player_position = Vector2(1010.0, 390.0)
	candidate_roam_mode = "--candidate-roam" in OS.get_cmdline_user_args()
	if candidate_roam_mode:
		candidate_motion_state = "IDLE"
		print("TURTLE_PREVIEW_ROAM_START ", JSON.stringify({"position": [turtle_position.x, turtle_position.y], "target": [PREVIEW_ROAM_END.x, PREVIEW_ROAM_END.y], "walkable_start": _is_walkable(turtle_position), "obstacle_test": _player_overlaps_solid_obstacle(Vector2(1182.0, 171.0))}))
	for index in range(6):
		candidate_frames.append(load(CANDIDATE_DIR + "%03d.png" % index) as Texture2D)
	candidate_label = Label.new()
	candidate_label.text = "M01 candidate preview  |  walk_right  |  6 FPS  |  %s  |  single direction only" % candidate_motion_state
	candidate_label.position = Vector2(24.0, 82.0)
	candidate_label.add_theme_font_override("font", UI_FONT)
	candidate_label.add_theme_font_size_override("font_size", 17)
	candidate_label.add_theme_color_override("font_color", Color("294438"))
	candidate_label.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.9))
	candidate_label.add_theme_constant_override("shadow_offset_x", 1)
	candidate_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(candidate_label)


func _physics_process(delta: float) -> void:
	candidate_physics_delta = delta
	super._physics_process(delta)


func _process(delta: float) -> void:
	if candidate_frames.is_empty():
		return
	if candidate_label != null:
		candidate_label.text = "M01 candidate preview  |  walk_right  |  6 FPS  |  %s  |  single direction only" % candidate_motion_state
	if candidate_roam_mode and candidate_motion_state != "WALK":
		return
	candidate_elapsed += delta
	var frame_duration := 1.0 / CANDIDATE_FPS
	if candidate_elapsed >= frame_duration:
		var steps := int(candidate_elapsed / frame_duration)
		candidate_elapsed = fmod(candidate_elapsed, frame_duration)
		candidate_frame = (candidate_frame + steps) % candidate_frames.size()
		queue_redraw()


func _keep_turtle_at_habitat() -> void:
	if not candidate_roam_mode or game_state == null or not game_state.is_pond_complete():
		turtle_position = Q005_TURTLE_POSITION
		candidate_motion_state = "LOOP" if not candidate_roam_mode else "IDLE"
		return
	if candidate_collision_stopped:
		return
	var remaining := PREVIEW_ROAM_END - turtle_position
	if remaining.length() <= 0.1:
		candidate_motion_state = "IDLE"
		if candidate_logged_distance > 0.0:
			print("TURTLE_PREVIEW_ROAM_STOP ", JSON.stringify({"position": [turtle_position.x, turtle_position.y], "actual_distance": candidate_logged_distance, "grounded": _is_ground_support(turtle_position + Vector2(0.0, 51.0)), "collision_probe_blocked": not _is_walkable(Vector2(1240.0, 280.0))}))
			candidate_logged_distance = 0.0
		return
	var displacement := remaining.normalized() * minf(PREVIEW_ROAM_SPEED * candidate_physics_delta, remaining.length())
	var candidate_position := turtle_position + displacement
	if not _is_walkable(candidate_position):
		candidate_motion_state = "IDLE"
		candidate_collision_stopped = true
		print("TURTLE_PREVIEW_ROAM_BLOCKED ", JSON.stringify({"from": [turtle_position.x, turtle_position.y], "candidate": [candidate_position.x, candidate_position.y], "state": candidate_motion_state, "grounded": _is_ground_support(turtle_position + Vector2(0.0, 51.0))}))
		return
	turtle_position = candidate_position
	candidate_motion_state = "WALK" if displacement.length() > 0.05 else "IDLE"
	candidate_logged_distance += displacement.length()
	candidate_telemetry_elapsed += candidate_physics_delta
	if candidate_telemetry_elapsed >= 0.2:
		candidate_telemetry_elapsed = 0.0
		print("TURTLE_PREVIEW_ROAM_STEP ", JSON.stringify({"position": [turtle_position.x, turtle_position.y], "actual_delta": [displacement.x, displacement.y], "state": candidate_motion_state, "grounded": _is_ground_support(turtle_position + Vector2(0.0, 51.0))}))


func _draw_turtle(position: Vector2) -> void:
	if candidate_frames.is_empty() or candidate_frames[candidate_frame] == null:
		super._draw_turtle(position)
		return
	var texture := candidate_frames[candidate_frame]
	var zoom := _camera_zoom_scale()
	var displayed_height := DISPLAY_CANVAS_HEIGHT * zoom
	var displayed_width := displayed_height * float(texture.get_width()) / float(texture.get_height())
	var foot_offset := 87.0 * (1.0 - 0.39) - 2.0
	var foot := _world_to_screen(position + Vector2(0.0, foot_offset))
	_draw_ellipse_custom(foot + Vector2(2.0, 2.5), Vector2(27.0 * zoom, 4.8 * zoom), Color(0.16, 0.20, 0.13, 0.20))
	_draw_ellipse_custom(foot + Vector2(0.0, 1.5), Vector2(20.0 * zoom, 2.8 * zoom), Color(0.28, 0.34, 0.19, 0.12))
	draw_set_transform(foot, 0.0, Vector2.ONE * (displayed_height / texture.get_height()))
	draw_texture(texture, -FOOT_ANCHOR)
	_restore_world_draw_transform()
