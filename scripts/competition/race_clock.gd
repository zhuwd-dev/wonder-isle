extends RefCounted
class_name CompetitionRaceClock

var running := false
var paused := false
var started_usec := 0
var paused_at_usec := 0
var paused_total_usec := 0
var finished_usec := 0

func start() -> void:
	running = true
	paused = false
	started_usec = Time.get_ticks_usec()
	paused_at_usec = 0
	paused_total_usec = 0
	finished_usec = 0

func pause() -> void:
	if running and not paused:
		paused = true
		paused_at_usec = Time.get_ticks_usec()

func resume() -> void:
	if running and paused:
		paused_total_usec += Time.get_ticks_usec() - paused_at_usec
		paused_at_usec = 0
		paused = false

func stop() -> float:
	if running:
		finished_usec = paused_at_usec if paused else Time.get_ticks_usec()
		running = false
		paused = false
	return elapsed_seconds()

func reset() -> void:
	running = false
	paused = false
	started_usec = 0
	paused_at_usec = 0
	paused_total_usec = 0
	finished_usec = 0

func elapsed_seconds() -> float:
	if started_usec == 0:
		return 0.0
	var end_usec := finished_usec
	if running:
		end_usec = paused_at_usec if paused else Time.get_ticks_usec()
	if end_usec == 0:
		return 0.0
	return maxf(0.0, float(end_usec - started_usec - paused_total_usec) / 1_000_000.0)

func formatted() -> String:
	var total_seconds := floori(elapsed_seconds())
	return "%02d:%02d" % [floori(float(total_seconds) / 60.0), total_seconds % 60]
