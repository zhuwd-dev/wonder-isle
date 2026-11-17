extends SceneTree

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = load("res://scenes/boot/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var state = load("res://scripts/game/game_state.gd").new()
	var data: Dictionary = state.to_save_data()
	var old_snapshot := JSON.stringify(data)
	var decoded: Dictionary = main._decode_save_snapshot(old_snapshot)
	_expect(decoded.valid and decoded.revision == 0, "legacy mirror without revision remains readable at revision zero")
	var disk: Dictionary = {"valid": true, "revision": 9, "data": data}
	var mirror: Dictionary = {"valid": true, "revision": 8, "data": data}
	_expect(main._select_save_snapshot(mirror, disk) == disk, "older valid mirror cannot replace a newer WebFS save")
	mirror.revision = 10
	_expect(main._select_save_snapshot(mirror, disk) == mirror, "newer valid mirror can recover a WebFS write not yet committed")
	mirror.revision = 9
	_expect(main._select_save_snapshot(mirror, disk) == disk, "WebFS wins equal-revision ties")
	mirror.valid = false
	_expect(main._select_save_snapshot(mirror, disk) == disk, "invalid mirror falls back to WebFS")
	var new_data := data.duplicate(true)
	new_data["_save_revision"] = 7
	decoded = main._decode_save_snapshot(JSON.stringify(new_data))
	_expect(decoded.valid and decoded.revision == 7, "WebFS snapshot revision is recognized")
	var envelope := {"format": "wonder-isle-save-mirror-v2", "namespace": "production", "revision": 8, "payload": data}
	decoded = main._decode_save_snapshot(JSON.stringify(envelope))
	_expect(decoded.valid and decoded.revision == 8, "valid newer mirror envelope is recognized")
	envelope["namespace"] = "preview"
	decoded = main._decode_save_snapshot(JSON.stringify(envelope))
	_expect(not decoded.valid, "mirror from another save namespace is rejected")
	envelope["namespace"] = "production"
	envelope["revision"] = -1
	decoded = main._decode_save_snapshot(JSON.stringify(envelope))
	_expect(not decoded.valid, "negative revision is rejected")
	decoded = main._decode_save_snapshot("{broken")
	_expect(not decoded.valid, "corrupt mirror safely fails validation")
	var future_schema: Dictionary = data.duplicate(true)
	future_schema["schema_version"] = 999
	decoded = main._decode_save_snapshot(JSON.stringify(future_schema))
	_expect(not decoded.valid, "unsupported schema safely fails validation")
	main.save_namespace = "preview"
	var preview_envelope := {"format": "wonder-isle-save-mirror-v2", "namespace": "preview", "revision": 1, "payload": data}
	decoded = main._decode_save_snapshot(JSON.stringify(preview_envelope))
	_expect(decoded.valid, "preview namespace accepts its own mirror")
	main.save_namespace = "production"
	_expect(not main._decode_save_snapshot(JSON.stringify(preview_envelope)).valid, "production namespace rejects preview data")
	main.queue_free()
	_finish()


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error("[SaveSnapshotPolicyTest] " + label)


func _finish() -> void:
	if failures == 0:
		print("[SaveSnapshotPolicyTest] PASS")
	else:
		push_error("[SaveSnapshotPolicyTest] FAIL: %d assertions" % failures)
	quit(failures)
