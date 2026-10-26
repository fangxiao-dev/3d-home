extends SceneTree
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("verify")
func verify() -> void:
	var scene = load("res://playroom.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	if scene.seats.size() != 5: failures.append("Expected five seat contracts")
	if scene.house_layout.size() != 7: failures.append("Expected seven rooms")
	for key in ["Idle", "Walk", "SitDown", "SitIdle", "StandUp"]:
		if not scene.animations.has(key): failures.append("Missing animation " + key)
	var counts := {}
	for mesh in scene.room_meshes:
		var extra: Dictionary = mesh.get_meta("extras", {})
		for key in ["room_id", "collision", "cutaway", "bake_static"]:
			if not extra.has(key): failures.append("Missing " + key + " on " + str(mesh.name))
		counts[extra.get("room_id", "")] = counts.get(extra.get("room_id", ""), 0) + 1
	for id in scene.house_layout:
		if counts.get(id, 0) < 5: failures.append("Missing room geometry " + id)
	for id in scene.seats:
		var seat: Dictionary = scene.seats[id]
		if not is_equal_approx(float(seat.surface_height), 0.45): failures.append("Seat scale mismatch " + id)
		for key in ["approach", "root", "exit", "camera_position", "camera_target"]:
			if not scene.vec(seat[key]).is_finite(): failures.append("Invalid seat point " + id + "/" + key)
	var skeleton: Skeleton3D = scene.avatar.find_children("*", "Skeleton3D", true, false)[0]
	if skeleton.get_bone_count() < 10: failures.append("Character is not fully rigged")
	if scene.avatar.scale != Vector3.ONE: failures.append("Character scale changed")
	for failure in failures: push_error(failure)
	print("SCENE_V2_ASSET_VERIFY ", JSON.stringify({"failures": failures, "rooms": counts, "bones": skeleton.get_bone_count()}))
	quit(0 if failures.is_empty() else 1)
