extends SceneTree
const Animator = preload("res://scripts/visual/player_animation.gd")
const Validation = preload("res://scripts/visual/art_validation.gd")
var failures := 0
func expect(value: bool, label: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL ", label)
func _init() -> void:
	var a := Animator.new()
	expect(a.current_texture() == null, "missing official frames must use fallback")
	var idle_only: SpriteFrames = preload("res://assets/art/animation/mouse-idle-frames.tres")
	a = Animator.new(idle_only)
	expect(a.has_idle_set(), "approved directional idle resource must be usable independently")
	for facing in Animator.DIRECTIONS:
		a.direction = facing
		a.animation = "idle_" + facing
		expect(a.current_texture() != null and a.current_texture().resource_path.ends_with("idle_%s/00.png" % facing), "idle view must match %s facing" % facing)
		a.animation = "walk_" + facing
		expect(a.current_texture() != null and a.current_texture().resource_path.ends_with("idle_%s/00.png" % facing), "missing walk cycle must safely display %s facing" % facing)
	for pair in [[Vector2.DOWN, "down"], [Vector2.UP, "up"], [Vector2.LEFT, "left"], [Vector2.RIGHT, "right"]]:
		a.update(pair[0] * 26, 0.1)
		expect(a.animation == "walk_" + pair[1], "movement direction")
		a.update(Vector2.ZERO, 0.1)
		expect(a.animation == "idle_" + pair[1], "standing direction")
	a.update(Vector2(20, 20), 0.1)
	expect(a.direction == "right", "stable diagonal axis")
	a.update(Vector2(19, 20), 0.1)
	expect(a.direction == "right", "diagonal jitter must not change axis")
	var image := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	image.fill_rect(Rect2i(30, 12, 190, 220), Color.WHITE)
	var entry := {"canvas": [256, 256], "body_height": [208, 224]}
	expect(Validation.check_image(image, entry).is_empty(), "test-only synthetic valid alpha bounds")
	image.fill(Color.WHITE)
	expect(not Validation.check_image(image, entry).is_empty(), "opaque/clipped image must fail")
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for direction in Animator.DIRECTIONS:
		for state in ["idle", "walk"]:
			var name: String = state + "_" + direction
			frames.add_animation(name)
			frames.set_animation_speed(name, 10)
			for i in range(1 if state == "idle" else 6):
				frames.add_frame(name, ImageTexture.create_from_image(image))
	a = Animator.new(frames)
	a.update(Vector2.RIGHT * 26, 0.1)
	expect(a.has_complete_set() and a.current_texture() != null, "complete in-memory test frames must play")
	var first_texture := a.current_texture()
	a.update(Vector2.RIGHT * 26, 0.1)
	expect(a.current_texture() != first_texture, "walk playback must advance the frame")
	a.update(Vector2.ZERO, 0.1)
	expect(a.animation == "idle_right" and a.elapsed == 0, "stopping resets to standing frame")
	var spec = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/production-art.json"))
	expect(Validation.inspect(spec)["errors"].is_empty(), "disabled missing assets are reported without breaking game")
	if spec["mouse"]["enabled"]:
		expect(Animator.new(preload("res://assets/art/animation/mouse-frames.tres")).has_complete_set(), "enabled official frames must be built before release")
	spec["mouse"]["enabled"] = true
	spec["mouse"]["animations"]["walk_down"]["frames"][0] = "assets/art/characters/mouse/missing.png"
	expect(not Validation.inspect(spec)["errors"].is_empty(), "enabled incomplete assets must fail")
	print("art pipeline failures=", failures)
	quit(0 if failures == 0 else 1)
