@tool
extends EditorPlugin
var baking := false
func _enter_tree() -> void:
	if "--bake-house" in OS.get_cmdline_user_args():
		call_deferred("start_bake")
func start_bake() -> void:
	await get_tree().create_timer(3).timeout
	EditorInterface.open_scene_from_path("res://baked/house.scn")
	await get_tree().create_timer(3).timeout
	var house := EditorInterface.get_edited_scene_root()
	var lightmap := house.get_node("LightmapGI")
	EditorInterface.edit_node(lightmap)
	EditorInterface.get_selection().clear()
	EditorInterface.get_selection().add_node(lightmap)
	await get_tree().create_timer(2).timeout
	var button: Button = null
	for node in EditorInterface.get_base_control().find_children("*", "Button", true, false):
		if "Bake Lightmaps" in node.text or ("烘焙" in node.text and "光" in node.text):
			button = node
			break
	if button == null:
		push_error("BAKE_BUTTON_NOT_FOUND")
		get_tree().quit(2)
		return
	_schedule(invoke_native_bake.bind(button, lightmap))

func invoke_native_bake(button: Button, lightmap: LightmapGI) -> void:
	# Native progress dialogs pump the editor loop; use a one-shot Timer node, not SceneTree timers or deferred calls.
	print("BAKE_NATIVE_ACTION_START")
	printerr("BAKE_PHASE begin_native_action")
	button.pressed.emit()
	_schedule(finish_bake.bind(lightmap))

func finish_bake(lightmap: LightmapGI) -> void:
	if lightmap.light_data != null and lightmap.light_data.get_user_count() > 0:
		EditorInterface.save_scene()
		while EditorInterface.get_resource_filesystem().is_scanning():
			await get_tree().process_frame
		await get_tree().create_timer(2).timeout
		print("BAKE_NATIVE_ACTION_OK users=", lightmap.light_data.get_user_count())
		printerr("BAKE_PHASE saved_and_verified_before_editor_shutdown")
		get_tree().quit(0)
	else:
		push_error("BAKE_NATIVE_ACTION_NO_DATA")
		get_tree().quit(3)

func _schedule(action: Callable) -> void:
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = 0.1
	add_child(timer)
	timer.timeout.connect(action)
	timer.timeout.connect(timer.queue_free)
	timer.start()
