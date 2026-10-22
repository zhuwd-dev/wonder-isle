extends SceneTree

var failures := 0
var expected_save_path := ""


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	for index in range(args.size() - 1):
		if str(args[index]) == "--test-save-path":
			expected_save_path = str(args[index + 1])
			break
	call_deferred("_run")


func _run() -> void:
	var scene := load("res://scenes/boot/Main.tscn")
	var main = scene.instantiate()
	root.add_child(main)
	await process_frame
	_expect(not expected_save_path.is_empty(), "测试必须提供专用存档路径")
	_expect(main.get("save_path") == expected_save_path, "游戏实例应使用测试专用存档路径")
	main.queue_free()
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("[SavePathIsolationTest] " + message)


func _finish() -> void:
	if failures == 0:
		print("[SavePathIsolationTest] PASS")
	else:
		push_error("[SavePathIsolationTest] FAIL: %d 个断言失败" % failures)
	quit(failures)
