extends SceneTree
var scene: Node3D
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("verify")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
func release() -> void:
	for action in ["walk_left", "walk_right", "walk_up", "walk_down"]: Input.action_release(action)
func walk(target: Vector3) -> void:
	for i in range(700):
		var delta: Vector3 = target - scene.player.position
		release()
		if Vector2(delta.x, delta.z).length() < 0.025: return
		if absf(delta.x) > 0.015: Input.action_press("walk_right" if delta.x > 0 else "walk_left")
		if absf(delta.z) > 0.015: Input.action_press("walk_down" if delta.z > 0 else "walk_up")
		await physics_frame
	release()
	check(false, "Blocked route " + str(target) + " at " + str(scene.player.position))
func key(code: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	scene._input(event)
	# Unit boundary: simulate the external OS grant, not browser permission.
	if code == KEY_ESCAPE and scene.mode == "STAND_UP" and scene.interaction_restore_allowed:
		scene.capture_requested = true # Simulated pending native request; no browser permission claim.
		scene._pointer_lock_changed(true)
	event.pressed = false
	scene._input(event)

func mouse_motion() -> void:
	var event := InputEventMouseMotion.new()
	event.screen_relative = Vector2(300, 100)
	root.push_input(event, true)
func wait_mode(value: String) -> void:
	for i in range(600):
		if scene.mode == value: return
		await physics_frame
	check(false, "Mode timeout " + value + " actual " + scene.mode)
func cycle(id: String) -> void:
	var seat: Dictionary = scene.seats[id]
	await walk(scene.vec(seat.approach))
	release()
	await physics_frame
	check(scene._nearest_seat() == id, "Seat not reachable " + id)
	if id == "sofa_middle":
		var blocker := StaticBody3D.new()
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(0.05, 2, 0.5)
		collision.shape = shape
		blocker.add_child(collision)
		blocker.position = scene._stand_point(seat) + Vector3(0, 1, 0)
		scene.add_child(blocker)
		await physics_frame
		key(KEY_F)
		await wait_mode("EXPLORE")
		check(scene.seat_id.is_empty() and scene.seat_exceptions.is_empty(), "Failed alignment did not clean up")
		check(scene.player.position.distance_to(scene.vec(seat.approach)) < 0.1, "Failed alignment did not return safely")
		check(scene.navigation_active, "Failed alignment paused navigation")
		blocker.queue_free()
		await physics_frame
	for index in range(3):
		key(KEY_F)
		if index == 0: scene.transition_clock = 4.0
		key(KEY_F)
		await wait_mode("SEATED")
		check(scene.animation == "SitIdle", "Wrong seated animation " + id)
		check(scene.avatar.scale == Vector3.ONE, "Scaled avatar " + id)
		var bones: Dictionary = scene._bone_points()
		check(absf(float(bones["Hips"][1]) - float(seat.surface_height) - 0.105) < 0.025, "Hip/seat contact " + id)
		for foot in ["Foot.L", "Foot.R"]:
			check(absf(float(bones[foot][1]) - float(seat.root[1]) - 0.085) < 0.02, "Foot support " + id)
		check(scene.player.position.distance_to(scene.vec(seat.root)) < 0.03, "Root alignment " + id)
		if id == "entry_stool" and index == 0:
			var blocker := StaticBody3D.new()
			var collision := CollisionShape3D.new()
			var shape := BoxShape3D.new()
			shape.size = Vector3(0.05, 2, 0.5)
			collision.shape = shape
			blocker.add_child(collision)
			blocker.position = scene.vec(seat.exit) + Vector3(0, 1, 0)
			scene.add_child(blocker)
			await physics_frame
			key(KEY_ESCAPE)
			await wait_mode("EXITING")
			await wait_mode("SEATED")
			check(scene.seat_id == id and scene.animation == "SitIdle", "Blocked exit did not restore seated state")
			check(scene.player.position.distance_to(scene.vec(seat.root)) < 0.03, "Blocked exit did not return to seat root")
			check(scene.completed_cycles[id] == 0, "Blocked exit counted as completed cycle")
			check(not scene.auto_moving, "Blocked exit left automatic movement active")
			check(not scene.pointer_locked, "Blocked exit retained pointer capture")
			check(scene.player.get_collision_exceptions().size() == scene.seat_exceptions.size(), "Blocked exit collision exceptions diverged")
			blocker.queue_free()
			await physics_frame
			await physics_frame
			print("EXIT_RETRY_READY ", JSON.stringify({"mode": scene.mode, "cycles": scene.completed_cycles[id], "seat_exceptions": scene.seat_exceptions.size()}))
		var before: Vector3 = scene.player.position
		var yaw: float = scene.target_camera_yaw
		Input.action_press("walk_up")
		mouse_motion()
		key(KEY_F)
		for i in range(45): await physics_frame
		check(scene.player.position.distance_to(before) < 0.001 and scene.target_camera_yaw == yaw, "Input leaked " + id)
		key(KEY_ESCAPE)
		await wait_mode("EXPLORE")
		check(scene.player.position.distance_to(scene.vec(seat.exit)) < 0.03, "Exit alignment " + id)
		check(scene.awaiting_movement_release, "Held movement release lock missing")
		check(scene.seat_exceptions.is_empty() and scene.player.get_collision_exceptions().is_empty(), "Successful exit did not clear collision exceptions")
		check(scene.completed_cycles[id] == index + 1, "Successful exit counted incorrectly " + id)
		release()
		await physics_frame
		await physics_frame
		while scene.camera_blend_elapsed < 0.45: await process_frame
		await physics_frame
		check(not scene.awaiting_movement_release, "Movement remained locked after key release")
		if id == "entry_stool" and index == 0:
			print("EXIT_RETRY_OK ", JSON.stringify({"mode": scene.mode, "cycles": scene.completed_cycles[id], "seat_exceptions": scene.seat_exceptions.size(), "physics_exceptions": scene.player.get_collision_exceptions().size(), "input_locked": scene.awaiting_movement_release}))
		await walk(scene.vec(seat.approach))
		release()
	check(scene.completed_cycles[id] == 3, "Cycle count " + id)
func verify() -> void:
	scene = load("res://playroom.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	scene.capture_requested = true # Simulated pending native request; no browser permission claim.
	scene._pointer_lock_changed(true)
	await physics_frame
	await walk(Vector3(-0.8, 0, -0.65))
	await cycle("entry_stool")
	await walk(Vector3(0, 0, -1.5))
	await walk(Vector3(0, 0, -3.6))
	await cycle("sofa_middle")
	await cycle("window_seat")
	await walk(Vector3(0, 0, -3.6))
	await walk(Vector3(0, 0, -0.65))
	await walk(Vector3(0, 0, 1))
	await walk(Vector3(-0.7, 0, 3.1))
	await cycle("dining_chair")
	await walk(Vector3(-0.7, 0, 3.1))
	await walk(Vector3(0, 0, 1))
	await walk(Vector3(6.85, 0, 1))
	await walk(Vector3(6.85, 0, 3.7))
	await cycle("study_chair")
	release()
	check(scene.transition_collisions.is_empty(), "Transition intersects furniture: " + str(scene.transition_collisions))
	print("SCENE_V2_SEATS_VERIFY ", JSON.stringify({"failures": failures, "cycles": scene.completed_cycles}))
	quit(0 if failures.is_empty() else 1)





