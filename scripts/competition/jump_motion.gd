extends RefCounted
class_name CompetitionJumpMotion

var duration := 0.64
var maximum_height := 58.0
var elapsed := 0.0
var active := false
var just_landed := false

func start() -> bool:
	just_landed = false
	if active:
		return false
	active = true
	elapsed = 0.0
	return true

func advance(delta: float) -> void:
	just_landed = false
	if not active:
		return
	elapsed = minf(elapsed + maxf(delta, 0.0), duration)
	if elapsed >= duration:
		active = false
		just_landed = true

func height() -> float:
	if not active:
		return 0.0
	var phase := clampf(elapsed / duration, 0.0, 1.0)
	return 4.0 * maximum_height * phase * (1.0 - phase)
