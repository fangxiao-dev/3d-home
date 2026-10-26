extends SceneTree
var scene: Node3D
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("verify")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
func frames(count: int) -> void:
	for i in range(count): await process_frame
func mouse(relative: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.screen_relative = relative
	event.relative = relative * 0.5
	scene._input(event)
	await process_frame
func key(code: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	scene._input(event)
	event.pressed = false
	scene._input(event)

func visible_body_blockers() -> Array[String]:
	var blockers: Array[String] = []
	for height in [0.87, 1.14, 1.52]:
		var query := PhysicsRayQueryParameters3D.create(scene.camera.position, scene.player.position + Vector3(0, height, 0), 1)
		var excluded: Array[RID] = []
		for step in range(scene.room_meshes.size()):
			query.exclude = excluded
			var hit: Dictionary = scene.get_world_3d().direct_space_state.intersect_ray(query)
			if hit.is_empty(): break
			var mesh: MeshInstance3D = hit.collider.get_parent()
			if mesh.is_visible_in_tree():
				blockers.append(str(mesh.name))
				break
			excluded.append(hit.collider.get_rid())
	return blockers
func rendered_body_blockers() -> Array[String]:
	var blockers: Array[String] = []
	for mesh in scene.room_meshes:
		if not mesh.is_visible_in_tree(): continue
		var from: Vector3 = mesh.to_local(scene.camera.global_position)
		for height in [0.87, 1.14, 1.52]:
			var to: Vector3 = mesh.to_local(scene.player.global_position + Vector3(0, height, 0))
			if mesh.get_aabb().intersects_segment(from, to) == null: continue
			var faces := PackedVector3Array()
			for surface in range(mesh.mesh.get_surface_count()):
				var material := mesh.get_active_material(surface) as BaseMaterial3D
				if material != null and material.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA and material.albedo_color.a < 1.0: continue
				var arrays: Array = mesh.mesh.surface_get_arrays(surface)
				var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
				if indices.is_empty(): faces.append_array(vertices)
				else:
					for index in indices: faces.append(vertices[index])
			for index in range(0, faces.size(), 3):
				if Geometry3D.segment_intersects_triangle(from, to, faces[index], faces[index + 1], faces[index + 2]) != null:
					blockers.append(str(mesh.name))
					break
			if str(mesh.name) in blockers: break
	return blockers
func verify() -> void:
	scene = load("res://playroom.tscn").instantiate()
	root.add_child(scene)
	await frames(3)
	for group in scene.visibility_groups:
		if "/wall/" in group: continue
		var parts: Array = scene.visibility_groups[group]
		var eligible: bool = parts.any(func(mesh): return mesh.get_meta("extras", {}).get("collision", false))
		for mesh in parts:
			var extras: Dictionary = mesh.get_meta("extras", {})
			check(bool(extras.get("camera_occluder", false)) == eligible, "Assembly camera flag differs: " + str(mesh.name))
			if eligible:
				check(not extras.get("bake_static", false), "Hideable assembly still baked: " + str(mesh.name))
				check(mesh.gi_mode == GeometryInstance3D.GI_MODE_DYNAMIC, "Hideable assembly missing probe lighting")
				var casts: bool = extras.get("collision", false) and extras.get("cutaway", "").is_empty()
				check((mesh.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_ON) == casts, "Assembly shadow policy differs: " + str(mesh.name))
	scene._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	var initial: Vector3 = scene.player.position
	await mouse(Vector2(100, 500))
	key(KEY_F)
	Input.action_press("walk_right")
	await frames(10)
	Input.action_release("walk_right")
	check(scene.mode == "EXPLORE" and absf(scene.player.position.x - initial.x) < 0.001, "Inactive navigation accepted movement/F")
	check(is_zero_approx(scene.target_camera_yaw), "Inactive mouse rotated camera")
	scene.capture_requested = true
	key(KEY_ESCAPE)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED # Simulated external late grant.
	scene._pointer_lock_changed(true)
	check(not scene.pointer_locked and not scene.navigation_active and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Late grant after Escape reactivated navigation")
	scene.capture_requested = true
	scene._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED # Simulated external late grant.
	scene._pointer_lock_changed(true)
	check(not scene.pointer_locked and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Late grant while blurred did not release native mode")
	scene._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	scene._pointer_lock_changed(true)
	check(not scene.pointer_locked and not scene.navigation_active and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Late grant after focus return reactivated navigation")
	# Pure-engine simulation of actual pointerlockchange. Browser permission is tested separately.
	scene.capture_requested = true # Simulated pending native request; no browser permission claim.
	scene._pointer_lock_changed(true)
	await mouse(Vector2(1000, 0))
	check(is_zero_approx(scene.target_camera_yaw), "Capture transition leaked stale motion")
	await frames(3)
	await mouse(Vector2(100, 0))
	check(absf(scene.target_camera_yaw + deg_to_rad(12.0)) < 0.00001, "screen_relative sensitivity/sign incorrect")
	var stopped: float = scene.target_camera_yaw
	await frames(30)
	check(is_equal_approx(scene.target_camera_yaw, stopped), "Stopped mouse left inertia")
	await mouse(Vector2(0, 600))
	check(is_equal_approx(scene.target_camera_yaw, stopped), "Vertical mouse changed yaw")
	for i in range(10): await mouse(Vector2(10, 0))
	check(absf(scene.target_camera_yaw - stopped + deg_to_rad(12.0)) < 0.00001, "Equivalent pixel displacement depended on event count")
	key(KEY_ESCAPE)
	check(not scene.pointer_locked and not scene.navigation_active, "Explore Escape failed to release")
	stopped = scene.target_camera_yaw
	await mouse(Vector2(100, 0))
	check(is_equal_approx(scene.target_camera_yaw, stopped), "Unlocked pointer rotated camera")
	scene.capture_requested = true # Simulated pending native request; no browser permission claim.
	scene._pointer_lock_changed(true)
	scene._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	scene._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	await frames(3)
	await mouse(Vector2(100, 0))
	check(not scene.navigation_active and is_equal_approx(scene.target_camera_yaw, stopped), "Focus return resumed without click")
	scene.capture_requested = true # Simulated pending native request; no browser permission claim.
	scene._pointer_lock_changed(true)
	await frames(3)
	scene.set_physics_process(false)
	scene.mode = "APPROACH"
	await mouse(Vector2(100, 100))
	check(is_equal_approx(scene.target_camera_yaw, stopped), "Interaction leaked mouse movement")
	scene.mode = "EXPLORE"
	scene.awaiting_movement_release = false
	# A direct placement tests target continuity at the exact old room seam; browser tests walk this route.
	scene.target_camera_yaw = 0.0
	for boundary in [0.0, 2.0]:
		scene.player.position = Vector3(0, 0, boundary - 0.001)
		var before: Vector3 = scene._explore_target()
		scene.player.position.z = boundary + 0.001
		var after: Vector3 = scene._explore_target()
		check(absf(before.distance_to(after) - 0.002) < 0.0001, "Room boundary changed camera target")
	for angle in range(0, 360, 45):
		scene.target_camera_yaw = deg_to_rad(float(angle))
		scene._update_camera(1, true)
		check(absf(scene.snapshot().camera_pitch_degrees - 40.0) < 0.01, "Orbit pitch drift")
		check(absf(scene.camera.position.distance_to(scene.camera_focus) - 10.5) < 0.001, "Orbit distance drift")
		check(scene.snapshot().camera_facing_dot > 0.9999, "Orbit lost target")
	for angle in [30.0, 135.0, 270.0]:
		scene.player.position = Vector3(0, 0, -2)
		scene.target_camera_yaw = deg_to_rad(angle)
		scene._update_camera(1, true)
		var before: Vector3 = scene.player.position
		Input.action_press("walk_right")
		scene._physics_process(1.0 / 60.0)
		Input.action_release("walk_right")
		var motion: Vector3 = scene.player.position - before
		check(motion.dot(scene.camera.global_basis.x) > 0.01, "Screen-relative right failed at " + str(angle))
	# Return interpolation must finish before fresh movement can use the restored yaw.
	scene.player.position = Vector3(0, 0, -2)
	scene.camera_blend_elapsed = 0.0
	scene.awaiting_movement_release = false
	var return_position: Vector3 = scene.player.position
	Input.action_press("walk_right")
	scene._physics_process(1.0 / 60.0)
	check(scene.player.position.distance_to(return_position) < 0.001, "Movement leaked during camera return")
	scene.camera_blend_elapsed = 0.45
	scene._physics_process(1.0 / 60.0)
	check(scene.player.position.distance_to(return_position) < 0.001, "Held return input resumed without release")
	Input.action_release("walk_right")
	scene._physics_process(1.0 / 60.0)
	check(not scene.awaiting_movement_release, "Return input did not unlock after release")
	scene.player.position = Vector3(0.584885, 0.000023, 6.348564)
	scene.target_camera_yaw = deg_to_rad(45.54)
	for amount in [0.85, 1.15]:
		scene.zoom = amount
		scene.target_zoom = amount
		scene._update_camera(1, true)
		check(visible_body_blockers().is_empty(), "Kitchen head/chest occluded at " + str(amount) + ": " + str(visible_body_blockers()))
		for part in scene.visibility_groups["kitchen/kitchen_east_upper_cabinet"]:
			check(not part.visible, "Occlusion left installed attachment visible: " + str(part.name))
		for body in scene.furniture_bodies["kitchen_cabinet"]:
			check(body.collision_layer == 1, "Hidden cabinet lost collision")
			check(body.get_parent().visible, "Lower cabinet disappeared with upper cabinet")
	scene.target_camera_yaw = deg_to_rad(225.0)
	scene._update_camera(1, true)
	check(scene.furniture_bodies["kitchen_cabinet"][0].get_parent().visible, "Cabinet did not return in unobstructed view")
	check(visible_body_blockers().is_empty(), "Reverse view body occluded")
	scene.player.position = Vector3(-0.005095, 0.000845, -6.794866)
	scene.target_camera_yaw = 23.584518
	for amount in [0.85, 1.15]:
		scene.zoom = amount
		scene.target_zoom = amount
		scene._update_camera(1, true)
		check(rendered_body_blockers().is_empty(), "Balcony rendered head/chest obstruction " + str(amount) + ": " + str(rendered_body_blockers()))
	print("NAVIGATION_V2_CAMERA_VERIFY ", JSON.stringify({"failures": failures}))
	quit(0 if failures.is_empty() else 1)
