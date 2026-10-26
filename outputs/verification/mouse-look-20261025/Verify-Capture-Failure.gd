extends SceneTree
var scene: Node3D
var failures: Array[String] = []
func _initialize() -> void: call_deferred("verify")
func check(value: bool, message: String) -> void:
	if not value: failures.append(message)
func wait_mode(expected: String) -> void:
	for i in range(1800):
		await physics_frame
		if scene.mode == expected: return
	failures.append("Timeout " + expected)
func key(code: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	scene._input(event)
func verify() -> void:
	scene = load("res://playroom.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	# Engine-only setup and external permission result simulation, never browser evidence.
	scene.player.position = scene.vec(scene.seats.entry_stool.approach)
	scene.capture_requested = true
	scene._pointer_lock_changed(true)
	await physics_frame
	await physics_frame
	key(KEY_F)
	await wait_mode("SEATED")
	key(KEY_ESCAPE)
	# The native request is denied externally; emulate its actual visible state and notification.
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	scene._web_pointer_event(["lock_error"])
	await wait_mode("EXPLORE")
	for i in range(60): await process_frame
	check(scene.completed_cycles.entry_stool == 1, "Capture refusal prevented standing")
	check(not scene.navigation_active and not scene.pointer_locked and scene.resume_button.visible, "Capture refusal did not offer explicit resume")
	scene.capture_requested = true
	scene._pointer_lock_changed(true)
	await physics_frame
	await physics_frame
	key(KEY_F)
	await wait_mode("SEATED")
	scene._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	scene._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	key(KEY_ESCAPE)
	check(not scene.capture_requested and not scene.pointer_locked, "Focus loss still authorized seated Escape capture")
	await wait_mode("EXPLORE")
	for i in range(60): await process_frame
	check(scene.completed_cycles.entry_stool == 2 and not scene.navigation_active, "Focus-interrupted exit did not finish paused")
	print("MOUSE_CAPTURE_FAILURE_VERIFY ", JSON.stringify({"failures": failures, "cycles": scene.completed_cycles.entry_stool, "scope": "engine boundary simulation"}))
	quit(0 if failures.is_empty() else 1)
