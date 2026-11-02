extends RefCounted

const DIRECTIONS := ["down", "up", "left", "right"]
const WALK_FPS := 10.0
const REFERENCE_SPEED := 260.0
var direction := "right"
var animation := "idle_right"
var elapsed := 0.0
var frames: SpriteFrames

func _init(source: SpriteFrames = null) -> void:
	frames = source

func update(displacement: Vector2, delta: float) -> void:
	var moving := displacement.length_squared() > 0.0001 and delta > 0.0
	if moving:
		# Keep the previous axis near a diagonal to prevent direction flicker.
		var v := displacement.normalized()
		var horizontal := direction in ["left", "right"]
		if absf(v.x) > absf(v.y) + 0.12:
			horizontal = true
		elif absf(v.y) > absf(v.x) + 0.12:
			horizontal = false
		direction = ("right" if v.x >= 0 else "left") if horizontal else ("down" if v.y >= 0 else "up")
	var next := ("walk_" if moving else "idle_") + direction
	if animation != next:
		animation = next
		elapsed = 0.0
	if moving:
		elapsed += delta * clampf(displacement.length() / delta / REFERENCE_SPEED, 0.0, 1.5)

func has_complete_set() -> bool:
	if frames == null:
		return false
	for facing in DIRECTIONS:
		for state in ["idle", "walk"]:
			var name: String = state + "_" + facing
			if not frames.has_animation(name) or frames.get_frame_count(name) != (1 if state == "idle" else 6):
				return false
			for index in range(frames.get_frame_count(name)):
				if frames.get_frame_texture(name, index) == null:
					return false
	return true

func current_texture() -> Texture2D:
	if not has_complete_set():
		return null
	var count := frames.get_frame_count(animation)
	return frames.get_frame_texture(animation, int(elapsed * frames.get_animation_speed(animation)) % count)
