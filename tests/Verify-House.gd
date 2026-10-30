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
		if Vector2(delta.x, delta.z).length() < 0.08: return
		if absf(delta.x) > 0.05: Input.action_press("walk_right" if delta.x > 0 else "walk_left")
		if absf(delta.z) > 0.05: Input.action_press("walk_down" if delta.z > 0 else "walk_up")
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
	for index in range(3):
		key(KEY_F)
		key(KEY_F)
		await wait_mode("SEATED")
		check(scene.animation == "SitIdle", "Wrong seated animation " + id)
		check(scene.avatar.scale == Vector3.ONE, "Scaled avatar " + id)
		check(scene.player.position.distance_to(scene.vec(seat.root)) < 0.03, "Root alignment " + id)
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
		release()
		await physics_frame
		await walk(scene.vec(seat.approach))
		release()
	check(scene.completed_cycles[id] == 3, "Cycle count " + id)
func visit(id: String, point: Vector3) -> void:
	await walk(point)
	check(scene._room_at(scene.player.position) == id, "Cannot reach " + id)
	check(scene.player.position.y > -0.1, "Missing floor " + id)
	for angle in range(0, 360, 45):
		var yaw := deg_to_rad(float(angle))
		for amount in [0.85, 1.15]:
			scene.camera_yaw = yaw
			scene.target_camera_yaw = yaw
			scene.zoom = amount
			scene.target_zoom = amount
			scene._update_camera(1, true)
			check(absf(scene.snapshot().camera_pitch_degrees - 40.0) < 0.1, "Camera pitch " + id)
			check(is_equal_approx(scene.camera.fov, 35.0), "Camera FOV " + id)
	scene.camera_yaw = 0
	scene.target_camera_yaw = 0
	scene._update_camera(1, true)
func verify() -> void:
	scene = load("res://playroom.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	scene.capture_requested = true # Simulated pending native request; no browser permission claim.
	scene._pointer_lock_changed(true)
	await physics_frame
	await visit("living", Vector3(0, 0, -2))
	await visit("balcony", Vector3(0, 0, -6.8))
	await walk(Vector3(0, 0, 1))
	await visit("hallway", Vector3(0.8, 0, 1))
	await visit("dining", Vector3(0.8, 0, 3))
	await walk(Vector3(0.8, 0, 5.7))
	await walk(Vector3(0,0,6.1))
	await visit("kitchen",Vector3(0,0,7.8))
	await walk(Vector3(0,0,6.1))
	await walk(Vector3(0.8, 0, 1))
	await walk(Vector3(3.25, 0, 1))
	await visit("wash", Vector3(3.25, 0, 2.9))
	await walk(Vector3(3.25, 0, 1))
	await walk(Vector3(6.85, 0, 1))
	await visit("study", Vector3(6.85, 0, 3.2))
	release()
	print("SCENE_V2_HOUSE_VERIFY ", JSON.stringify({"failures": failures}))
	quit(0 if failures.is_empty() else 1)

