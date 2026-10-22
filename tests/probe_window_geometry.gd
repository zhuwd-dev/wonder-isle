extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene = load("res://scenes/boot/Main.tscn")
	var main = scene.instantiate()
	root.add_child(main)
	await process_frame
	print("[WindowGeometryProbe] main_size=", main.size)
	print("[WindowGeometryProbe] main_global_rect=", main.get_global_rect())
	print("[WindowGeometryProbe] viewport_rect=", get_root().get_viewport().get_visible_rect())
	print("[WindowGeometryProbe] window_size=", DisplayServer.window_get_size())
	print("[WindowGeometryProbe] screen_scale=", DisplayServer.screen_get_scale())
	main.queue_free()
	quit()
