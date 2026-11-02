extends SceneTree
const Validation = preload("res://scripts/visual/art_validation.gd")
func _init() -> void:
	var spec = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/production-art.json"))
	var args := OS.get_cmdline_user_args()
	var report := Validation.inspect(spec, "--strict" in args)
	for path in report["missing"]:
		print("ASSET_REQUIRED ", path)
	for error in report["errors"]:
		printerr("FAIL ", error)
	if not report["errors"].is_empty():
		quit(1)
		return
	if "--build-mouse" in args:
		if not spec["mouse"]["enabled"]:
			printerr("Enable the complete mouse set only after all frames pass validation")
			quit(1)
			return
		var frames := SpriteFrames.new()
		frames.remove_animation("default")
		for name in spec["mouse"]["animations"]:
			var animation: Dictionary = spec["mouse"]["animations"][name]
			frames.add_animation(name)
			frames.set_animation_speed(name, animation["fps"])
			frames.set_animation_loop(name, animation["loop"])
			for path in animation["frames"]:
				frames.add_frame(name, load("res://" + path))
		var error := ResourceSaver.save(frames, "res://assets/art/animation/mouse-frames.tres")
		if error != OK:
			quit(1)
			return
	print("PASS active art assets; missing optional assets=", report["missing"].size())
	quit(0)
