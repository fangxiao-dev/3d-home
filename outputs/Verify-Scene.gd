extends SceneTree
## Checks the actual imported GLB metadata and view transitions, without a GPU.

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var ceilings: Array[Node3D] = []
	for node in scene.room.find_children("*", "MeshInstance3D", true, false):
		if node.get_meta("extras", {}).get("category", "") == "Ceiling":
			ceilings.append(node)
	var failures: Array[String] = []
	if ceilings.is_empty():
		failures.append("Imported GLB lost ceiling metadata")
	scene._set_view(3)
	for node in ceilings:
		if node.visible:
			failures.append("Overview roof still visible: " + str(node.name))
	if scene.camera.projection != Camera3D.PROJECTION_ORTHOGONAL:
		failures.append("Overview camera must be orthographic")
	scene._set_view(0)
	for node in ceilings:
		if not node.visible:
			failures.append("Interior roof was not restored: " + str(node.name))
	for index in [1, 2]:
		scene._set_view(index)
		if not scene.camera.position.is_finite():
			failures.append("Invalid camera position")
	if failures.is_empty():
		print("SCENE_VERIFY_OK ceiling_meshes=", ceilings.size())
	else:
		for failure in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)
