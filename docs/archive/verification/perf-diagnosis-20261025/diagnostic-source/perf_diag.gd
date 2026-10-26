extends "res://playroom.gd"
# Isolated diagnostic subclass; never copied into the retained project.
var command_callback: JavaScriptObject
var measuring := false
var wanted_frames := 300
var rows: Array = []
var serial := 0
var last_tick := 0
var camera_us := 0
var visibility_us := 0
var edge_us := 0
var snapshot_us := 0
var render_check_us := 0
var physics_us := 0
var skip_process := false
var skip_visibility := false
var skip_physics := false
var sun: DirectionalLight3D
var original_materials: Dictionary = {}
var flat_material: StandardMaterial3D
var config: Dictionary = {}

func _ready() -> void:
	super._ready()
	sun = room.find_children("*", "DirectionalLight3D", true, false)[0]
	for mesh in avatar.find_children("*", "MeshInstance3D", true, false): mesh.layers = 2
	for mesh in room_meshes: original_materials[mesh] = mesh.material_override
	flat_material = StandardMaterial3D.new()
	flat_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flat_material.albedo_color = Color(0.7, 0.7, 0.7)
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	if OS.has_feature("web"):
		command_callback = JavaScriptBridge.create_callback(_command)
		JavaScriptBridge.eval("window.installPerfCommand = cb => {window.perfCommand = x => cb(JSON.stringify(x));window.perfReady=true;};", true)
		JavaScriptBridge.get_interface("window").installPerfCommand(command_callback)

func _command(args: Array) -> void:
	var request: Dictionary = JSON.parse_string(str(args[0]))
	if request.action == "configure":
		measuring = false
		config = request.duplicate()
		test_mode = request.get("test", false)
		skip_process = request.get("skip_process", false)
		skip_visibility = request.get("skip_visibility", false)
		skip_physics = request.get("skip_physics", false)
		diag_disable_history = request.get("skip_history", false)
		get_viewport().scaling_3d_scale = float(request.get("scale", 1.0))
		get_viewport().msaa_3d = int(request.get("msaa", 1))
		sun.shadow_enabled = request.get("shadows", true)
		camera.cull_mask = 2 if request.get("hide_environment", false) else 0xfffff
		for mesh in room_meshes: mesh.material_override = flat_material if request.get("flat", false) else original_materials[mesh]
		player.position = Vector3(6.9025, 0.001, 3.7776) if request.get("pose", "study") == "study" else Vector3(0, 0.001, -0.65)
		player.velocity = Vector3.ZERO
		target_camera_yaw = 0.0
		zoom = 1.0
		target_zoom = 1.0
		_pointer_exited()
		super._update_camera(1, true)
		JavaScriptBridge.eval("window.perfAck=" + JSON.stringify(request.get("id", "")) + ";", true)
	elif request.action == "measure":
		rows.clear()
		wanted_frames = int(request.get("frames", 300))
		serial = int(request.id)
		last_tick = 0
		measuring = true
	elif request.action == "state":
		JavaScriptBridge.eval("window.perfState=" + JSON.stringify(_state()) + ";", true)

func _process(delta: float) -> void:
	var started := Time.get_ticks_usec()
	camera_us = 0
	visibility_us = 0
	edge_us = 0
	snapshot_us = 0
	render_check_us = 0
	diag_history_usec = 0
	if not skip_process: super._process(delta)
	var process_us := Time.get_ticks_usec() - started
	if measuring:
		if last_tick > 0: rows.append([float(started - last_tick) / 1000.0, process_us, camera_us, visibility_us, edge_us, snapshot_us, render_check_us, diag_history_usec, physics_us])
		last_tick = started
		if rows.size() >= wanted_frames:
			measuring = false
			var result := {"id": serial, "config": config, "columns": ["frame_wall_ms", "process_inclusive_us", "camera_inclusive_us", "visibility_us", "edge_us", "snapshot_inclusive_us", "render_check_us", "history_us", "physics_accumulated_us"], "rows": rows, "state": _state()}
			JavaScriptBridge.eval("window.perfResultReceivedAt=performance.now();window.perfResult=" + JSON.stringify(result) + ";", true)
	physics_us = 0

func _physics_process(delta: float) -> void:
	var started := Time.get_ticks_usec()
	if not skip_physics: super._physics_process(delta)
	physics_us += Time.get_ticks_usec() - started

func _update_camera(delta: float, snap := false) -> void:
	var started := Time.get_ticks_usec()
	super._update_camera(delta, snap)
	camera_us += Time.get_ticks_usec() - started

func _update_visibility() -> void:
	var started := Time.get_ticks_usec()
	if not skip_visibility: super._update_visibility()
	visibility_us += Time.get_ticks_usec() - started

func _update_edge(delta: float) -> void:
	var started := Time.get_ticks_usec()
	super._update_edge(delta)
	edge_us += Time.get_ticks_usec() - started

func snapshot() -> Dictionary:
	var started := Time.get_ticks_usec()
	var result := super.snapshot()
	snapshot_us += Time.get_ticks_usec() - started
	return result

func _visible_rendered_body_obstructions() -> Array[String]:
	var started := Time.get_ticks_usec()
	var result := super._visible_rendered_body_obstructions()
	render_check_us += Time.get_ticks_usec() - started
	return result

func _state() -> Dictionary:
	var viewport := get_viewport()
	var passes := {}
	for type in range(3):
		passes[str(type)] = {"draw_calls": RenderingServer.viewport_get_render_info(viewport.get_viewport_rid(), type, 2), "render_primitives": RenderingServer.viewport_get_render_info(viewport.get_viewport_rid(), type, 1)}
	var visible_names: Array[String] = []
	for mesh in room_meshes:
		if mesh.is_visible_in_tree(): visible_names.append(str(mesh.name))
	return {"player": [player.position.x, player.position.y, player.position.z], "camera": [camera.position.x, camera.position.y, camera.position.z], "yaw": camera_yaw, "zoom": zoom, "logical_size": [viewport.get_visible_rect().size.x, viewport.get_visible_rect().size.y], "viewport_texture": [viewport.get_texture().get_width(), viewport.get_texture().get_height()], "scale": viewport.scaling_3d_scale, "msaa": viewport.msaa_3d, "shadows": sun.shadow_enabled, "test": test_mode, "draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), "render_primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME), "passes": passes, "server_cpu_ms": RenderingServer.viewport_get_measured_render_time_cpu(viewport.get_viewport_rid()), "server_gpu_ms": RenderingServer.viewport_get_measured_render_time_gpu(viewport.get_viewport_rid()), "visible_names": visible_names}
