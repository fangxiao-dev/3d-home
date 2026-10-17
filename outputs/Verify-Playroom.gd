extends SceneTree

var failures: Array[String] = []
var scene: Node3D

func _initialize() -> void:
	call_deferred("_verify")

func _frames(count: int) -> void:
	for i in range(count):
		await physics_frame

func _move(actions: Array, frames: int) -> void:
	for action in actions:
		Input.action_press(action)
	await _frames(frames)
	for action in actions:
		Input.action_release(action)
	await _frames(2)

func _place(position_: Vector3) -> void:
	scene.player.position = position_
	scene.player.velocity = Vector3.ZERO
	await _frames(2)

func _press_key(code: Key, echo_: bool = false) -> void:
	var key := InputEventKey.new()
	key.physical_keycode = code
	key.pressed = true
	key.echo = echo_
	scene._unhandled_key_input(key)

func _press_f(echo_: bool = false) -> void:
	_press_key(KEY_F, echo_)

func _wheel(up_: bool) -> void:
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_WHEEL_UP if up_ else MOUSE_BUTTON_WHEEL_DOWN
	mouse.pressed = true
	scene._unhandled_input(mouse)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _mesh(prefix: String) -> MeshInstance3D:
	for node in scene.room.find_children("*", "MeshInstance3D", true, false):
		if str(node.name).begins_with(prefix):
			return node as MeshInstance3D
	return null

func _bounds(mesh: MeshInstance3D) -> AABB:
	return mesh.global_transform * mesh.get_aabb()

func _has_group(group: String) -> bool:
	return scene.snapshot().hidden_groups.has(group)

func _verify() -> void:
	scene = load("res://playroom.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	_check(scene.room_meshes.size() > 230, "Existing Blender room was not loaded")
	_check(scene.colliders.size() >= 12, "Furniture and room collisions are incomplete")
	_check(not scene.colliders.has("EntranceTable"), "Deleted entrance side table collision remains")
	_check(_mesh("Entrance side table") == null, "Deleted entrance side table mesh remains")
	_check(_mesh("Chair seat") == null and _mesh("Chair leg") == null, "Deleted wooden chair mesh remains")
	for collider_name in scene.colliders.keys():
		_check(not str(collider_name).begins_with("Chair"), "Deleted wooden chair collision remains")
	var return_base := _mesh("Sofa return base")
	var return_seat := _mesh("Sofa return seat")
	_check(return_base != null and return_seat != null, "Soft ottoman parts are missing")
	_check(_mesh("Sofa return back") == null and _mesh("Sofa return outer arm") == null, "Soft ottoman retained a backrest or arm")
	if return_base != null:
		_check(abs(_bounds(return_base).size.x - 0.86) < 0.04, "Soft ottoman width changed")
	var sofa_wall := _mesh("Sofa side wall")
	_check(sofa_wall != null and _bounds(sofa_wall).size.y > 3.2, "Room height did not reach 3.30m")
	var window_back := _mesh("Window daylight backing")
	_check(window_back != null and _bounds(window_back).end.y > 3.0, "Window upper edge did not follow room height")
	var shade := _mesh("Floor lampshade")
	_check(shade != null, "Static floor lamp decoration is missing")
	var ceiling_group_visible := not _has_group("ceiling_top")
	var ceiling_mesh_count := 0
	for mesh in scene.room_meshes:
		if mesh.get_meta("extras", {}).get("category", "") == "Ceiling":
			ceiling_mesh_count += 1
		if str(mesh.name).begins_with("Chandelier"):
			_check(mesh.visible == ceiling_group_visible, "Chandelier visibility is out of sync with ceiling_top")
	_check(ceiling_mesh_count > 0, "Interior ceiling meshes are missing")
	_check(scene.camera.projection == Camera3D.PROJECTION_PERSPECTIVE, "Camera is not perspective")
	_check(abs(scene.snapshot().camera_pitch_degrees - 29.0) < 0.2, "Camera pitch is not 29 degrees")
	_check(not _has_group("ceiling_top"), "Low camera unexpectedly hid the ceiling group")
	_check(abs(scene.snapshot().layout.room_width - 5.8) < 0.01 and abs(scene.snapshot().layout.room_depth - 5.8) < 0.01, "Runtime room dimensions are not 5.8m wide by 5.8m deep")
	for light in scene.find_children("*", "Light3D", true, false):
		_check(not light.shadow_enabled, "Room shadow maps should remain disabled")
	_check(scene.player.get_node_or_null("ContactShadow") != null, "Character contact shadow is missing")
	_check(scene.target_markers.size() == 3, "Three target markers were not created")
	_check(scene.closeup_presets.size() == 3, "Three target close-up presets were not created")

	var initial: Dictionary = scene.snapshot()
	var horizontal_camera_distance := Vector2(scene.camera.position.x - scene.player.position.x, scene.camera.position.z - scene.player.position.z).length()
	_check(abs(horizontal_camera_distance - 3.6) < 0.05, "Camera horizontal distance is not 3.6m")
	_check(abs(initial.camera_fov - 62.0) < 0.1, "Exploration FOV is not 62")
	_check(abs(initial.zoom - 1.0) < 0.001 and abs(initial.target_zoom - 1.0) < 0.001, "Camera zoom did not start at 1")
	_check(abs(initial.camera_yaw_degrees) < 0.1, "Camera yaw did not start at zero")

	var start: Vector3 = scene.player.position
	await _move(["walk_up"], 20)
	_check(scene.player.position.z < start.z - 0.5, "ArrowUp did not move forward")
	var straight_distance: float = scene.player.position.distance_to(start)
	await _place(start)
	await _move(["walk_up", "walk_right"], 20)
	_check(scene.player.position.distance_to(start) < straight_distance * 1.12, "Diagonal speed is too high")
	var tea_top := _mesh("Tea table top")
	_check(tea_top != null, "Tea table top is missing")
	var sofa_plinth := _mesh("Sofa plinth")
	var tv_body := _mesh("TV console body")
	var lamp_foot := _mesh("Floor lamp foot")
	var pet_mat := _mesh("Pet mat")
	_check(sofa_plinth != null and abs(sofa_plinth.global_position.x + 2.39) < 0.03, "Left furniture group did not move by -0.75m")
	_check(tv_body != null and abs(tv_body.global_position.x - 2.59) < 0.03, "Right furniture group did not move by +0.75m")
	_check(lamp_foot != null and abs(lamp_foot.global_position.x + 2.58) < 0.03, "Floor lamp did not move with the left furniture group")
	_check(pet_mat != null and abs(pet_mat.global_position.x - 2.48) < 0.03, "Pet bed did not move with the right furniture group")
	if tea_top != null:
		var tea_bounds := _bounds(tea_top)
		await _place(Vector3(0.6, 0.02, -2.65))
		await _move(["walk_left"], 45)
		_check(scene.player.position.x > tea_bounds.end.x and scene.player.position.x < tea_bounds.end.x + 0.35, "Player passed through real tea table")
	await _place(Vector3(return_base.global_position.x if return_base != null else -1.49, 0.02, -0.65))
	await _move(["walk_up"], 30)
	_check(scene.player.position.z > -1.0, "Player passed through soft ottoman")
	await _place(Vector3(0.4, 0.02, -2.8))
	await _move(["walk_right"], 45)
	_check(tv_body == null or scene.player.position.x < _bounds(tv_body).position.x, "Player passed through TV console")
	await _place(Vector3(0.4, 0.02, -4.9))
	await _move(["walk_right"], 45)
	var dresser_body := _mesh("Tall chest body")
	_check(dresser_body == null or scene.player.position.x < _bounds(dresser_body).position.x, "Player passed through dresser")
	await _place(Vector3(0, 0.02, -0.4))
	await _move(["walk_down"], 30)
	_check(scene.player.position.z < -0.22, "Player left through hallway boundary")
	await _place(Vector3(-1.7, 0.02, -0.4))
	await _move(["walk_left"], 30)
	_check(sofa_wall == null or scene.player.position.x > _bounds(sofa_wall).end.x, "Player passed through sofa wall")
	await _place(Vector3(0, 0.02, -5.3))
	await _move(["walk_up"], 30)
	_check(scene.player.position.z > -5.58, "Player left through balcony boundary")

	# Q/E and zoom keep their original interaction contract.
	await _place(start)
	_press_key(KEY_Q)
	_press_key(KEY_E)
	await _frames(24)
	var q_turn: Dictionary = scene.snapshot()
	_check(q_turn.camera_yaw_degrees > 80.0 and q_turn.camera_yaw_degrees < 100.0, "Q did not rotate counterclockwise toward +X")
	_check(not q_turn.rotation_in_progress, "Q rotation did not settle in 0.3s")
	_press_key(KEY_E)
	await _frames(24)
	_check(abs(scene.snapshot().camera_yaw_degrees) < 0.1, "E did not return camera yaw")
	_press_key(KEY_Q)
	_press_key(KEY_Q, true)
	await _frames(24)
	_check(abs(scene.snapshot().camera_yaw_degrees - 90.0) < 0.1, "Echo Q generated an extra turn")
	_press_key(KEY_E)
	await _frames(24)
	for i in range(10):
		_wheel(true)
	await _frames(40)
	_check(abs(scene.snapshot().target_zoom - 0.85) < 0.001 and abs(scene.snapshot().zoom - 0.85) < 0.01, "Wheel zoom-in did not clamp at .85")
	_check(abs(scene.snapshot().camera_pitch_degrees - 29.0) < 0.2, "Near zoom changed camera pitch")
	for i in range(20):
		_wheel(false)
	await _frames(70)
	_check(abs(scene.snapshot().target_zoom - 1.15) < 0.001 and abs(scene.snapshot().zoom - 1.15) < 0.01, "Wheel zoom-out did not clamp at 1.15")
	_check(abs(scene.snapshot().camera_pitch_degrees - 29.0) < 0.2, "Far zoom changed camera pitch")

	# Runtime wall/roof cutaway remains view-only; colliders are untouched.
	scene.zoom = 1.0
	scene.target_zoom = 1.0
	scene.camera_yaw = 0.0
	scene.target_camera_yaw = 0.0
	scene._snap_exploration_camera()
	_press_key(KEY_Q)
	await _frames(24)
	_check(_has_group("right_wall"), "Right wall group did not hide when camera crossed +X wall")
	_press_key(KEY_E)
	await _frames(24)
	_press_key(KEY_E)
	await _frames(24)
	_check(_has_group("left_wall"), "Left wall group did not hide when camera crossed -X wall")
	await _place(Vector3(0, 0.02, -3.0))
	_press_key(KEY_E)
	await _frames(24)
	_check(_has_group("rear_window"), "Rear window group did not hide when camera crossed back boundary")

	# Each interaction relies on line of sight as well as distance.  Use a
	# temporary layer-1 blocker, then remove it before the close-up checks.
	var los_cases: Array[Dictionary] = [
		{"target": "stool_view", "position": Vector3(scene.stool_target_point.x + 0.80, 0.02, scene.stool_target_point.z + 0.16)},
		{"target": "sofa_middle_sit", "position": Vector3(scene.sofa_middle_target_point.x + 1.10, 0.02, scene.sofa_middle_target_point.z)},
		{"target": "window_cushion_sit", "position": Vector3(scene.window_cushion_target_point.x + 1.10, 0.02, scene.window_cushion_target_point.z)}
	]
	for los_case in los_cases:
		var los_target: String = str(los_case["target"])
		var approach: Vector3 = los_case["position"]
		var target_point: Vector3 = scene._target_point_for(los_target)
		await _place(approach)
		_check(scene._nearest_interaction_target() == los_target, "LOS setup did not expose " + los_target)
		var blocker_position: Vector3 = (scene.player.position + target_point) / 2.0
		blocker_position.y = 0.65
		var blocker: StaticBody3D = scene._collision_box("VerifyTargetBlocker", blocker_position, Vector3(0.12, 1.3, 0.12))
		await _frames(2)
		_check(scene._nearest_interaction_target().is_empty(), "LOS blocker did not hide " + los_target)
		_press_f()
		_check(scene.mode == scene.MODE_EXPLORE, "F entered an action through LOS blocker for " + los_target)
		blocker.queue_free()
		await _frames(2)
		_check(scene._nearest_interaction_target() == los_target, "Removing LOS blocker did not restore " + los_target)

	# Soft ottoman view close-up.
	scene.camera_yaw = 0.0
	scene.target_camera_yaw = 0.0
	scene.zoom = 1.0
	scene.target_zoom = 1.0
	scene._snap_exploration_camera()
	await _place(Vector3(scene.stool_target_point.x + 0.35, 0.02, scene.stool_target_point.z + 0.16))
	_check(scene._stool_reachable(), "Soft ottoman entry target is not reachable")
	var before_view: Dictionary = scene.snapshot()
	_press_f()
	await _frames(36)
	var view_state: Dictionary = scene.snapshot()
	_check(view_state.mode == scene.MODE_CLOSE_UP and view_state.closeup_target == "stool_view", "F did not enter the soft ottoman view")
	_check(view_state.input_locked and not view_state.avatar_visible and not view_state.contact_shadow_visible, "Soft ottoman view did not lock input and hide avatar/contact shadow")
	_press_key(KEY_Q)
	_press_f()
	_wheel(true)
	await _frames(4)
	var view_locked: Dictionary = scene.snapshot()
	_check(abs(view_locked.camera_yaw - view_state.camera_yaw) < 0.001 and abs(view_locked.zoom - view_state.zoom) < 0.001, "Soft ottoman view accepted camera or F input")
	_press_key(KEY_ESCAPE)
	await _frames(36)
	var view_return: Dictionary = scene.snapshot()
	_check(view_return.mode == scene.MODE_EXPLORE and view_return.closeup_target.is_empty(), "Esc did not return from soft ottoman view")
	_check(abs(view_return.x - before_view.x) < 0.01 and abs(view_return.z - before_view.z) < 0.01, "Soft ottoman view return drifted player position")
	_check(view_return.avatar_visible and view_return.contact_shadow_visible, "Soft ottoman view did not restore avatar/contact shadow")

	# Both sofa targets produce the seated visual and restore a standing avatar.
	for target in ["sofa_middle_sit", "window_cushion_sit"]:
		var point: Vector3 = scene._target_point_for(target)
		await _place(Vector3(point.x + 0.35, 0.02, point.z + 0.16))
		_check(scene._nearest_interaction_target() == target, "Nearest target was not " + target)
		var player_before: Vector3 = scene.player.position
		_press_f()
		await _frames(36)
		var seated: Dictionary = scene.snapshot()
		_check(seated.mode == scene.MODE_CLOSE_UP and seated.closeup_target == target and seated.seated_target == target, "F did not enter seated target " + target)
		_check(seated.avatar_visible and not seated.contact_shadow_visible, "Seated target avatar/contact state is wrong for " + target)
		_check(seated.input_locked, "Seated target did not lock input for " + target)
		var seated_yaw: float = seated.camera_yaw
		var seated_zoom: float = seated.zoom
		_press_key(KEY_Q)
		_press_key(KEY_F)
		_wheel(true)
		await _frames(4)
		var seated_locked: Dictionary = scene.snapshot()
		_check(abs(seated_locked.camera_yaw - seated_yaw) < 0.001 and abs(seated_locked.zoom - seated_zoom) < 0.001, "Seated close-up accepted locked input for " + target)
		_press_key(KEY_ESCAPE)
		await _frames(36)
		var standing: Dictionary = scene.snapshot()
		_check(standing.mode == scene.MODE_EXPLORE and standing.seated_target.is_empty(), "Esc did not leave seated target " + target)
		_check(standing.avatar_visible and standing.contact_shadow_visible, "Esc did not restore standing avatar for " + target)
		_check(abs(standing.x - player_before.x) < 0.01 and abs(standing.z - player_before.z) < 0.01, "Seated target return drifted player for " + target)

	if failures.is_empty():
		print("LIVING_PLAY_VERIFY_OK Blender_asset, wide_room_5.8m, soft_ottoman, no_chairs, static_lamp, movement, furniture, boundaries, camera_29, rotation, zoom, visibility, three_targets, seated_avatar, closeup_restore")
	else:
		for failure in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)
