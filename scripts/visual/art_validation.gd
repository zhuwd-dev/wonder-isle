extends RefCounted

static func check_image(image: Image, entry: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if image == null:
		errors.append("PNG could not be decoded")
		return errors
	var dimensions: Array = entry["canvas"]
	if image.is_empty() or image.get_size() != Vector2i(dimensions[0], dimensions[1]):
		errors.append("incorrect canvas dimensions")
		return errors
	if image.detect_alpha() == Image.ALPHA_NONE:
		errors.append("missing effective transparency")
	var bounds := image.get_used_rect()
	if bounds.size == Vector2i.ZERO:
		errors.append("empty frame")
	elif bounds.position.x < 4 or bounds.position.y < 4 or bounds.end.x > image.get_width() - 4 or bounds.end.y > image.get_height() - 4:
		errors.append("art touches the safety border; possible clipping")
	if entry.has("body_height") and (bounds.size.y < entry["body_height"][0] or bounds.size.y > entry["body_height"][1]):
		errors.append("visible body height out of range")
	return errors

static func inspect(spec: Dictionary, strict := false) -> Dictionary:
	var errors := PackedStringArray()
	var missing := PackedStringArray()
	var mouse: Dictionary = spec["mouse"]
	if Vector2(mouse["canvas"][0], mouse["canvas"][1]) != Vector2(256, 256) or Vector2(mouse["anchor"][0], mouse["anchor"][1]) != Vector2(128, 232) or not is_equal_approx(float(mouse["world_scale"]), 0.30):
		errors.append("mouse canvas/anchor/scale does not match runtime contract")
	var required := []
	for direction in ["down", "up", "left", "right"]:
		for state in ["idle", "walk"]:
			var name: String = state + "_" + direction
			required.append(name)
			var animation: Dictionary = mouse["animations"].get(name, {})
			var count := 1 if state == "idle" else 6
			if animation.get("frames", []).size() != count or animation.get("fps", 0) != (1 if state == "idle" else 10) or not animation.get("loop", false):
				errors.append("invalid animation contract: " + name)
			for index in range(animation.get("frames", []).size()):
				var path: String = animation["frames"][index]
				if path != "assets/art/characters/mouse/%s/%02d.png" % [name, index]:
					errors.append("animation filename mismatch: " + path)
				var required_now: bool = strict or mouse["enabled"] or (state == "idle" and mouse.get("idle_enabled", false))
				_check_file(path, mouse, required_now, errors, missing)
	if mouse["animations"].size() != required.size():
		errors.append("unexpected animation names")
	for key in spec["items"]:
		var entry: Dictionary = spec["items"][key]
		var size: Array = entry["canvas"]
		var anchor: Array = entry["anchor"]
		if anchor[0] < 0 or anchor[1] < 0 or anchor[0] >= size[0] or anchor[1] >= size[1] or entry["world_scale"] <= 0:
			errors.append("invalid anchor/scale: " + key)
		_check_file(entry["path"], entry, strict or entry["enabled"], errors, missing)
	return {"errors": errors, "missing": missing}

static func _check_file(path: String, entry: Dictionary, required: bool, errors: PackedStringArray, missing: PackedStringArray) -> void:
	if not path.ends_with(".png") or not path.begins_with("assets/art/") or ".." in path:
		errors.append("invalid PNG path: " + path)
		return
	if not FileAccess.file_exists("res://" + path):
		missing.append(path)
		if required:
			errors.append("required PNG missing: " + path)
		return
	var image := Image.load_from_file("res://" + path)
	var file := FileAccess.open("res://" + path, FileAccess.READ)
	if file == null or file.get_buffer(8).hex_encode() != "89504e470d0a1a0a":
		errors.append("invalid PNG signature: " + path)
		return
	for error in check_image(image, entry):
		errors.append(path + ": " + error)
