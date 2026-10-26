extends Node3D
## Scene v2 runtime. Asset metadata owns furniture semantics and seat transforms.
const EnvironmentFactory = preload("res://scene_environment.gd")
var room: Node3D
var house_layout: Dictionary
var scene_data: Dictionary
var character_data: Dictionary
var seats: Dictionary = {}
var room_meshes: Array[MeshInstance3D] = []
var visibility_groups: Dictionary = {}
var mesh_visibility_group: Dictionary = {}
var mesh_collision_rids: Dictionary = {}
var test_mesh_faces: Dictionary = {}
var occlusion_hidden_groups: Array[String] = []
var player: CharacterBody3D
var avatar: Node3D
var character_skeleton: Skeleton3D
var sight_bones: Array[int] = []
var animation_player: AnimationPlayer
var animations: Dictionary = {}
var animation := ""
var camera: Camera3D
var prompt: Label
var mode := "EXPLORE"
var seat_id := ""
var interaction_target := ""
var camera_yaw := 0.0
var target_camera_yaw := 0.0
var zoom := 1.0
var target_zoom := 1.0
var camera_focus := Vector3.ZERO
var help_panel: PanelContainer
var edge_hint: Label
var pointer_position := Vector2.ZERO
var pointer_inside := false
var edge_armed := false
var app_focused := true
var edge_direction := 0
var edge_elapsed := 0.0
var edge_turn_rate := 0.0
var camera_seated := false
var camera_blend_elapsed := 0.45
var camera_blend_from := Transform3D.IDENTITY
var web_input_callback: JavaScriptObject
var awaiting_movement_release := false
var test_mode := false
var diag_disable_history := false
var diag_history_usec := 0
signal auto_walk_finished
var auto_moving := false
var auto_goal := Vector3.ZERO
var auto_elapsed := 0.0
var auto_failed := false
var auto_history: Array[Vector3] = []
var remember_auto_path := true
var notice := ""
var notice_time := 0.0
var furniture_bodies: Dictionary = {}
var seat_exceptions: Array[PhysicsBody3D] = []
var transition_collisions: Array[String] = []
var last_frame_usec := 0
var frame_ms: Array[float] = []
var sample_clock := 0.0
var transition_clock := 0.0
var approach_stage := ""
var saved_yaw := 0.0
var saved_zoom := 1.0
var completed_cycles: Dictionary = {}

func vec(value: Array) -> Vector3:
	return Vector3(value[0], value[1], value[2])

func _ready() -> void:
	house_layout = JSON.parse_string(FileAccess.get_file_as_string("res://assets/house-layout.json"))
	scene_data = JSON.parse_string(FileAccess.get_file_as_string("res://assets/scene-v2-data.json"))
	character_data = JSON.parse_string(FileAccess.get_file_as_string("res://assets/character-contract.json"))
	for seat in scene_data.seats:
		seats[seat.id] = seat
		completed_cycles[seat.id] = 0
	for item in [["left", KEY_A, KEY_LEFT], ["right", KEY_D, KEY_RIGHT], ["up", KEY_W, KEY_UP], ["down", KEY_S, KEY_DOWN]]:
		var action: String = "walk_" + item[0]
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			for code in item.slice(1):
				var event := InputEventKey.new()
				event.physical_keycode = code
				InputMap.action_add_event(action, event)
	if ResourceLoader.exists("res://baked/house.scn"):
		room = load("res://baked/house.scn").instantiate()
	else:
		room = EnvironmentFactory.create(house_layout)
	add_child(room)
	# Fill lights exist to bake the environment and probes; they are not seven runtime shadow maps.
	for light in room.find_children("*", "OmniLight3D", true, false):
		light.visible = false
	for light in room.find_children("*", "DirectionalLight3D", true, false):
		light.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
		light.directional_shadow_max_distance = 15.0
	for node in room.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		room_meshes.append(mesh)
		mesh_collision_rids[mesh] = []
		var group := _visibility_group(mesh.get_meta("extras", {}))
		if not group.is_empty():
			mesh_visibility_group[mesh] = group
			if not visibility_groups.has(group): visibility_groups[group] = []
			visibility_groups[group].append(mesh)
		var extras: Dictionary = mesh.get_meta("extras", {})
		var side: String = extras.get("cutaway", "")
		if not side.is_empty():
			var wall_group: String = str(extras.room_id) + "/wall/" + side
			if wall_group != group:
				if not visibility_groups.has(wall_group): visibility_groups[wall_group] = []
				visibility_groups[wall_group].append(mesh)
		if not extras.get("camera_occluder", false):
			mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if bool(mesh.get_meta("extras", {}).get("collision", false)):
			mesh.create_trimesh_collision()
			var furniture_id: String = mesh.get_meta("extras", {}).get("furniture_id", "")
			if not furniture_bodies.has(furniture_id):
				furniture_bodies[furniture_id] = []
			for body in mesh.get_children():
				if body is StaticBody3D:
					furniture_bodies[furniture_id].append(body)
					mesh_collision_rids[mesh].append(body.get_rid())
	_build_player()
	camera = Camera3D.new()
	camera.fov = 35.0
	camera.near = 0.08
	add_child(camera)
	camera.make_current()
	camera_focus = _explore_target()
	_update_camera(1.0, true)
	_build_ui()
	get_window().mouse_exited.connect(_pointer_exited)
	get_viewport().size_changed.connect(_pointer_exited)
	if OS.has_feature("web"):
		test_mode = bool(JavaScriptBridge.eval("new URLSearchParams(location.search).has('test')", true))
		web_input_callback = JavaScriptBridge.create_callback(_web_pointer_event)
		_install_web_pointer_events()
	print("SCENE_V2_READY seats=", seats.size(), " animations=", animations.keys())

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0, 0.02, -0.65)
	player.collision_layer = 2
	player.collision_mask = 1
	player.floor_snap_length = 0.12
	add_child(player)
	var collider := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.22
	shape.height = float(character_data.height)
	collider.shape = shape
	collider.position.y = shape.height / 2
	player.add_child(collider)
	avatar = load("res://assets/character.glb").instantiate()
	player.add_child(avatar)
	character_skeleton = avatar.find_children("*", "Skeleton3D", true, false)[0]
	for bone in ["Head", "Spine", "Hips"]:
		sight_bones.append(character_skeleton.find_bone(bone))
	animation_player = avatar.find_children("*", "AnimationPlayer", true, false)[0]
	for key in animation_player.get_animation_list():
		var short_name := str(key).get_slice("/", str(key).get_slice_count("/") - 1)
		animations[short_name] = key
		animation_player.get_animation(key).loop_mode = Animation.LOOP_LINEAR if short_name in ["Idle", "Walk", "SitIdle"] else Animation.LOOP_NONE
	for node in avatar.find_children("*", "GeometryInstance3D", true, false):
		node.gi_mode = GeometryInstance3D.GI_MODE_DYNAMIC
	_play("Idle")

func _play(key: String) -> void:
	if animation == key:
		return
	animation = key
	animation_player.play(animations[key], 0.12)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	help_panel = panel
	panel.position = Vector2(24, 24)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.19, 0.18, 0.88)
	style.set_corner_radius_all(12)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	var theme := Theme.new()
	theme.default_font = load("res://assets/NotoSansSC-Play.ttf")
	theme.default_font_size = 16
	panel.theme = theme
	layer.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var title := Label.new()
	title.text = "我们的家"
	title.add_theme_font_size_override("font_size", 24)
	column.add_child(title)
	var help := Label.new()
	help.text = "WASD / 方向键移动   鼠标靠近左右边缘转向   滚轮缩放"
	column.add_child(help)
	prompt = Label.new()
	prompt.add_theme_color_override("font_color", Color("f3d6a0"))
	column.add_child(prompt)
	edge_hint = Label.new()
	edge_hint.theme = theme
	edge_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	edge_hint.add_theme_font_size_override("font_size", 32)
	edge_hint.add_theme_color_override("font_color", Color(0.95, 0.91, 0.78, 0.8))
	layer.add_child(edge_hint)
	edge_hint.hide()

func _movement() -> Vector2:
	return Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")

func _physics_process(delta: float) -> void:
	if mode == "EXPLORE" and camera_blend_elapsed < 0.45:
		awaiting_movement_release = true
	elif awaiting_movement_release and _movement().is_zero_approx():
		awaiting_movement_release = false
	if auto_moving:
		auto_elapsed += delta
		var direction := auto_goal - player.position
		direction.y = 0
		if direction.length() < 0.035 or auto_elapsed > 5:
			auto_failed = direction.length() >= 0.035
			auto_moving = false
			player.velocity = Vector3.ZERO
			auto_walk_finished.emit()
		else:
			player.velocity = direction.normalized() * minf(float(character_data.walk_reference_speed), direction.length() / delta)
			player.velocity.y = -2
			player.move_and_slide()
			if remember_auto_path and (auto_history.is_empty() or auto_history.back().distance_to(player.position) > 0.02):
				auto_history.append(player.position)
	elif mode == "EXPLORE":
		var input := Vector2.ZERO if awaiting_movement_release else _movement()
		var motion := Vector3(input.x, 0, input.y).rotated(Vector3.UP, camera_yaw)
		player.velocity = motion * float(character_data.get("walk_reference_speed", 1.65))
		player.velocity.y = -2.0
		player.move_and_slide()
		if motion.length_squared() > 0.01:
			avatar.rotation.y = lerp_angle(avatar.rotation.y, atan2(motion.x, motion.z), minf(1, delta * 15))
			_play("Walk")
		else:
			_play("Idle")
		interaction_target = _nearest_seat()
	elif mode == "APPROACH":
		transition_clock += delta
		var seat: Dictionary = seats[seat_id]
		var point := vec(seat.approach)
		point.y = player.position.y
		var difference := point - player.position
		if difference.length() > 0.05:
			player.velocity = difference.normalized() * minf(float(character_data.walk_reference_speed), difference.length() / delta)
			player.velocity.y = -2
			player.move_and_slide()
			avatar.rotation.y = lerp_angle(avatar.rotation.y, atan2(difference.x, difference.z), minf(1, delta * 12))
			_play("Walk")
		else:
			_align_and_sit()
			return
		if transition_clock > 4.0:
			_cancel_explore("暂时走不过去，请换个位置再试。")

func _stand_point(seat: Dictionary) -> Vector3:
	var foot: Array = character_data.measurements.SitIdle.godot_bone_heads["Foot.L"]
	return vec(seat.root) + Vector3(0, 0, float(foot[2])).rotated(Vector3.UP, float(seat.yaw))

func _walk_stage(point: Vector3, remember_path := true) -> bool:
	var delta := point - player.position
	delta.y = 0
	if delta.length() < 0.035:
		return true
	_play("Walk")
	avatar.rotation.y = atan2(delta.x, delta.z)
	remember_auto_path = remember_path
	if remember_path:
		auto_history = [player.position]
	auto_goal = point
	auto_elapsed = 0
	auto_failed = false
	auto_moving = true
	await auto_walk_finished
	return not auto_failed

func _rollback_walk() -> void:
	var path := auto_history.duplicate()
	path.reverse()
	for point in path:
		await _walk_stage(point, false)

func _cancel_explore(message: String) -> void:
	_set_seat_exceptions(false)
	player.velocity = Vector3.ZERO
	mode = "EXPLORE"
	_suspend_edge()
	seat_id = ""
	awaiting_movement_release = true
	notice = message
	notice_time = 4.0
	_play("Idle")

func _set_seat_exceptions(enabled: bool) -> void:
	for body in seat_exceptions:
		player.remove_collision_exception_with(body)
	seat_exceptions.clear()
	if enabled:
		for body in furniture_bodies.get(seats[seat_id].furniture_id, []):
			player.add_collision_exception_with(body)
			seat_exceptions.append(body)

func _sample_transition_collision() -> void:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.20
	shape.height = float(character_data.height) - 0.04
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform.origin = player.position + Vector3(0, float(character_data.height) / 2 + 0.02, 0)
	query.collision_mask = 1
	var excluded: Array[RID] = [player.get_rid()]
	for body in seat_exceptions:
		excluded.append(body.get_rid())
	query.exclude = excluded
	for hit in get_world_3d().direct_space_state.intersect_shape(query):
		var label: String = str(hit.collider.get_parent().name)
		if not transition_collisions.has(seat_id + "/" + label):
			transition_collisions.append(seat_id + "/" + label)
func _root_motion(progress: float, from: Vector3, to: Vector3) -> void:
	player.position = from.lerp(to, progress * progress * (3.0 - 2.0 * progress))
	_sample_transition_collision()

func _align_and_sit() -> void:
	mode = "ALIGNING"
	player.velocity = Vector3.ZERO
	var seat: Dictionary = seats[seat_id]
	_set_seat_exceptions(true)
	if not await _walk_stage(_stand_point(seat)):
		await _rollback_walk()
		_cancel_explore("暂时走不过去，请换个位置再试。")
		return
	_play("Idle")
	var tween := create_tween()
	tween.tween_property(avatar, "rotation:y", avatar.rotation.y + angle_difference(avatar.rotation.y, float(seat.yaw)), 0.25)
	await tween.finished
	await _perform_sit(seat)

func _perform_sit(seat: Dictionary) -> void:
	if absf(angle_difference(avatar.rotation.y, float(seat.yaw))) > 0.02:
		mode = "ALIGNING"
		_play("Idle")
		var turn := create_tween()
		turn.tween_property(avatar, "rotation:y", avatar.rotation.y + angle_difference(avatar.rotation.y, float(seat.yaw)), 0.25)
		await turn.finished
	mode = "SIT_DOWN"
	_play("SitDown")
	var sit_motion := create_tween()
	sit_motion.tween_method(_root_motion.bind(player.position, vec(seat.root)), 0.0, 1.0, float(character_data.clips.SitDown.duration))
	await animation_player.animation_finished
	if sit_motion.is_running():
		await sit_motion.finished
	_play("SitIdle")
	mode = "SEATED"
func _enter_target_action(id: String) -> void:
	if mode != "EXPLORE" or id.is_empty() or id != _nearest_seat():
		return
	saved_yaw = target_camera_yaw
	saved_zoom = target_zoom
	seat_id = id
	mode = "APPROACH"
	_suspend_edge()
	transition_clock = 0
	interaction_target = ""

func _exit_target_action() -> void:
	if mode != "SEATED":
		return
	mode = "STAND_UP"
	var seat: Dictionary = seats[seat_id]
	_play("StandUp")
	var motion := create_tween()
	motion.tween_method(_root_motion.bind(player.position, _stand_point(seat)), 0.0, 1.0, float(character_data.clips.StandUp.duration))
	await animation_player.animation_finished
	if motion.is_running():
		await motion.finished
	mode = "EXITING"
	if not await _walk_stage(vec(seat.exit)):
		await _rollback_walk()
		await _perform_sit(seat)
		notice = "出口受阻 · Esc 再试"
		notice_time = 4.0
		return
	_set_seat_exceptions(false)
	completed_cycles[seat_id] += 1
	seat_id = ""
	mode = "EXPLORE"
	_suspend_edge()
	awaiting_movement_release = true
	target_camera_yaw = saved_yaw
	target_zoom = saved_zoom
	_play("Idle")
func _nearest_seat() -> String:
	var nearest := ""
	var distance := 1.1
	for id in seats:
		var point := vec(seats[id].approach)
		var d := Vector2(player.position.x - point.x, player.position.z - point.z).length()
		if d >= distance or _room_at(player.position) != seats[id].room_id:
			continue
		var ray := PhysicsRayQueryParameters3D.create(player.position + Vector3(0, 0.9, 0), point + Vector3(0, 0.9, 0), 1)
		if get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
			nearest = id
			distance = d
	return nearest

func _room_at(point: Vector3) -> String:
	for id in house_layout:
		var bounds: Array = house_layout[id]
		if point.x >= bounds[0] and point.x <= bounds[1] and -point.z >= bounds[2] and -point.z <= bounds[3]:
			return id
	return "outside"

func _explore_target() -> Vector3:
	return player.position + Vector3(0, 0.8, 0)

func _suspend_edge() -> void:
	edge_armed = false
	edge_direction = 0
	edge_elapsed = 0.0
	edge_turn_rate = 0.0

func _pointer_exited() -> void:
	pointer_inside = false
	_suspend_edge()

func _install_web_pointer_events() -> void:
	JavaScriptBridge.eval("window.set_navigation_pointer_callback = function(cb) { const canvas = document.getElementById('canvas'); canvas.addEventListener('pointerleave', () => cb('leave')); canvas.addEventListener('blur', () => cb('leave')); window.addEventListener('blur', () => cb('blur')); window.addEventListener('focus', () => cb('focus')); document.addEventListener('visibilitychange', () => cb(document.hidden ? 'blur' : 'focus')); };", true)
	JavaScriptBridge.get_interface("window").set_navigation_pointer_callback(web_input_callback)

func _web_pointer_event(args: Array) -> void:
	if str(args[0]) == "focus":
		app_focused = true
	elif str(args[0]) == "blur":
		_notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	else:
		_pointer_exited()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		pointer_position = event.position
		pointer_inside = get_viewport().get_visible_rect().has_point(pointer_position)
		var width := get_viewport().get_visible_rect().size.x
		var band := clampf(width * 0.08, 48.0, 120.0)
		if app_focused and mode == "EXPLORE" and camera_blend_elapsed >= 0.45 and pointer_inside and pointer_position.x >= band and pointer_position.x <= width - band:
			edge_armed = true

func _update_edge(delta: float) -> void:
	var size := get_viewport().get_visible_rect().size
	var band := clampf(size.x * 0.08, 48.0, 120.0)
	var strength := 0.0
	if edge_armed and pointer_inside and app_focused and mode == "EXPLORE" and camera_blend_elapsed >= 0.45 and not help_panel.get_global_rect().has_point(pointer_position):
		if pointer_position.x < band:
			strength = 1.0 - pointer_position.x / band
		elif pointer_position.x > size.x - band:
			strength = -(pointer_position.x - size.x + band) / band
	var direction := int(signf(strength))
	if direction != edge_direction:
		edge_elapsed = 0.0
	edge_direction = direction
	edge_turn_rate = 0.0
	if direction != 0:
		edge_elapsed += delta
		edge_turn_rate = deg_to_rad(45.0) * clampf(strength, -1.0, 1.0) * clampf((edge_elapsed - 0.15) / 0.15, 0.0, 1.0)
		target_camera_yaw += edge_turn_rate * delta
	edge_hint.visible = direction != 0
	edge_hint.text = "<" if direction > 0 else ">"
	edge_hint.position = Vector2(18 if direction > 0 else size.x - 38, size.y * 0.5 - 20)

func _process(delta: float) -> void:
	notice_time = maxf(0, notice_time - delta)
	var history_started := Time.get_ticks_usec()
	if not diag_disable_history:
		var now := Time.get_ticks_usec()
		if last_frame_usec > 0:
			frame_ms.append(float(now - last_frame_usec) / 1000.0)
		last_frame_usec = now
		if frame_ms.size() > 600:
			frame_ms.pop_front()
	diag_history_usec = Time.get_ticks_usec() - history_started
	_update_edge(delta)
	_update_camera(delta)
	if mode == "SEATED":
		prompt.text = str(seats[seat_id].label) + " · Esc 起身"
	elif mode == "EXPLORE" and not interaction_target.is_empty():
		prompt.text = "F 坐下 · " + str(seats[interaction_target].label)
	else:
		prompt.text = ""
	if notice_time > 0:
		prompt.text = notice
	if test_mode:
		var sample := {"t": Time.get_ticks_msec(), "player": [player.position.x, player.position.y, player.position.z], "focus": [camera_focus.x, camera_focus.y, camera_focus.z], "camera": [camera.position.x, camera.position.y, camera.position.z], "yaw": camera_yaw, "zoom": zoom, "room": _room_at(player.position), "mode": mode, "edge": edge_turn_rate}
		JavaScriptBridge.eval("window.__navigation_frames = window.__navigation_frames || []; window.__navigation_frames.push(" + JSON.stringify(sample) + "); if(window.__navigation_frames.length > 1800) window.__navigation_frames.shift();", true)
	sample_clock += delta
	if test_mode and sample_clock >= 0.1:
		sample_clock = 0
		JavaScriptBridge.eval("window.__playroom = " + JSON.stringify(snapshot()) + "; document.documentElement.dataset.playroom = JSON.stringify(window.__playroom); var stateNode=document.getElementById('playroom-state'); if(!stateNode){stateNode=document.createElement('pre'); stateNode.id='playroom-state'; stateNode.hidden=true; document.body.appendChild(stateNode);} stateNode.textContent=JSON.stringify(window.__playroom);", true)

func _update_camera(delta: float, snap := false) -> void:
	var alpha := 1.0 if snap else 1.0 - exp(-delta * 8.0)
	camera_yaw = target_camera_yaw
	zoom = lerpf(zoom, target_zoom, alpha)
	var target := _explore_target()
	camera_focus = camera_focus.lerp(target, alpha)
	var offset := Vector3(0, sin(deg_to_rad(40.0)), cos(deg_to_rad(40.0))).rotated(Vector3.UP, camera_yaw) * 10.5 * zoom
	var position_ := camera_focus + offset
	var seated := mode in ["SIT_DOWN", "SEATED", "STAND_UP"]
	if seated != camera_seated:
		camera_seated = seated
		camera_blend_from = camera.transform
		camera_blend_elapsed = 0.0
	if seated:
		position_ = vec(seats[seat_id].camera_position)
		target = vec(seats[seat_id].camera_target)
	else:
		target = camera_focus
	var desired := Transform3D(Basis.IDENTITY, position_).looking_at(target, Vector3.UP)
	camera_blend_elapsed = 0.45 if snap else minf(0.45, camera_blend_elapsed + delta)
	var blend := smoothstep(0.0, 0.45, camera_blend_elapsed)
	camera.transform = camera_blend_from.interpolate_with(desired, blend) if blend < 1.0 else desired
	_update_visibility()

func _visibility_group(extras: Dictionary) -> String:
	var furniture_id: String = extras.get("furniture_id", "")
	var room_id: String = extras.get("room_id", "")
	if not furniture_id.is_empty():
		return room_id + "/" + furniture_id
	var side: String = extras.get("cutaway", "")
	return room_id + "/wall/" + side if not side.is_empty() else ""

func _body_sight_points() -> Array[Vector3]:
	var points: Array[Vector3] = []
	for index in range(sight_bones.size()):
		var point := character_skeleton.global_transform * character_skeleton.get_bone_global_pose(sight_bones[index]).origin
		points.append(point + Vector3(0, 0.15 if index < 2 else 0.0, 0))
	return points

func _sight_exclusions(visibility: Dictionary = {}) -> Array[RID]:
	var excluded: Array[RID] = []
	for mesh in room_meshes:
		var extras: Dictionary = mesh.get_meta("extras", {})
		var supporting_seat: bool = mode != "EXPLORE" and not seat_id.is_empty() and extras.get("furniture_id", "") == seats[seat_id].furniture_id
		var visible_: bool = mesh.is_visible_in_tree() if visibility.is_empty() else visibility[mesh]
		if not visible_ or supporting_seat:
			excluded.append_array(mesh_collision_rids[mesh])
	return excluded

func _hide_body_obstructions(visibility: Dictionary) -> void:
	occlusion_hidden_groups.clear()
	var excluded := _sight_exclusions(visibility)
	for point in _body_sight_points():
		var query := PhysicsRayQueryParameters3D.create(camera.position, point, 1)
		for step in range(room_meshes.size()):
			query.exclude = excluded
			var hit := get_world_3d().direct_space_state.intersect_ray(query)
			if hit.is_empty(): break
			var mesh := hit.collider.get_parent() as MeshInstance3D
			if mesh_visibility_group.has(mesh):
				var group: String = mesh_visibility_group[mesh]
				occlusion_hidden_groups.append(group)
				for part in visibility_groups[group]:
					visibility[part] = false
					excluded.append_array(mesh_collision_rids[part])
			else:
				excluded.append(hit.collider.get_rid())

func _visible_body_obstructions() -> Array[String]:
	var blockers: Array[String] = []
	var excluded := _sight_exclusions()
	for point in _body_sight_points():
		var query := PhysicsRayQueryParameters3D.create(camera.position, point, 1)
		for step in range(room_meshes.size()):
			query.exclude = excluded
			var hit := get_world_3d().direct_space_state.intersect_ray(query)
			if hit.is_empty(): break
			var mesh := hit.collider.get_parent() as MeshInstance3D
			if mesh != null:
				blockers.append(str(mesh.name))
				break
			excluded.append(hit.collider.get_rid())
	return blockers

func _visible_rendered_body_obstructions() -> Array[String]:
	# Test observation only: visual attachments need not have gameplay collision.
	var blockers: Array[String] = []
	var points := _body_sight_points()
	for mesh in room_meshes:
		if not mesh.is_visible_in_tree(): continue
		var extras: Dictionary = mesh.get_meta("extras", {})
		if mode != "EXPLORE" and not seat_id.is_empty() and extras.get("furniture_id", "") == seats[seat_id].furniture_id: continue
		var from: Vector3 = mesh.to_local(camera.global_position)
		for point in points:
			var to: Vector3 = mesh.to_local(point)
			if mesh.get_aabb().intersects_segment(from, to) == null: continue
			if not test_mesh_faces.has(mesh):
				var opaque_faces := PackedVector3Array()
				for surface in range(mesh.mesh.get_surface_count()):
					var material := mesh.get_active_material(surface) as BaseMaterial3D
					if material != null and material.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA and material.albedo_color.a < 1.0: continue
					var arrays: Array = mesh.mesh.surface_get_arrays(surface)
					var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
					var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
					if indices.is_empty(): opaque_faces.append_array(vertices)
					else:
						for index in indices: opaque_faces.append(vertices[index])
				test_mesh_faces[mesh] = opaque_faces
			var faces: PackedVector3Array = test_mesh_faces[mesh]
			for index in range(0, faces.size(), 3):
				if Geometry3D.segment_intersects_triangle(from, to, faces[index], faces[index + 1], faces[index + 2]) != null:
					blockers.append(str(mesh.name))
					break
			if str(mesh.name) in blockers: break
	return blockers

func _update_visibility() -> void:
	var hidden_furniture: Dictionary = {}
	var visibility: Dictionary = {}
	for mesh in room_meshes:
		visibility[mesh] = true
		var extras: Dictionary = mesh.get_meta("extras", {})
		var side: String = extras.get("cutaway", "")
		if side.is_empty():
			continue
		var bounds: Array = house_layout[extras.room_id]
		var visible_ := true
		match side:
			"west": visible_ = camera.position.x > bounds[0]
			"east": visible_ = camera.position.x < bounds[1]
			"north": visible_ = camera.position.z > -bounds[3]
			"south": visible_ = camera.position.z < -bounds[2]
			"top", "ceiling": visible_ = false
		if visible_ and side not in ["top", "ceiling"]:
			var along_x := side in ["west", "east"]
			var plane: float = bounds[0] if side == "west" else bounds[1] if side == "east" else -bounds[3] if side == "north" else -bounds[2]
			var from_axis: float = camera.position.x if along_x else camera.position.z
			var to_axis: float = player.position.x if along_x else player.position.z
			if (from_axis - plane) * (to_axis - plane) < 0:
				var point := camera.position.lerp(player.position, (plane - from_axis) / (to_axis - from_axis))
				var within: bool = -point.z >= bounds[2] and -point.z <= bounds[3] if along_x else point.x >= bounds[0] and point.x <= bounds[1]
				if within:
					visible_ = false
		if visible_:
			var aabb: AABB = mesh.global_transform * mesh.get_aabb()
			visible_ = aabb.grow(0.08).intersects_segment(camera.position, player.position + Vector3(0, 0.8, 0)) == null
		visibility[mesh] = visible_
		var furniture_id: String = extras.get("furniture_id", "")
		if not visible_ and not furniture_id.is_empty(): hidden_furniture[furniture_id] = true
	for mesh in room_meshes:
		if hidden_furniture.has(mesh.get_meta("extras", {}).get("furniture_id", "")):
			visibility[mesh] = false
	_hide_body_obstructions(visibility)
	for mesh in room_meshes:
		mesh.visible = visibility[mesh]

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var code: int = event.physical_keycode if event.physical_keycode else event.keycode
		if code == KEY_ESCAPE and mode == "SEATED":
			_exit_target_action()
		elif mode == "EXPLORE" and camera_blend_elapsed >= 0.45:
			if code == KEY_F:
				_enter_target_action(_nearest_seat())
	if event is InputEventMouseButton and event.pressed and mode == "EXPLORE" and camera_blend_elapsed >= 0.45:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom = maxf(0.85, target_zoom - 0.05)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom = minf(1.15, target_zoom + 0.05)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		app_focused = false
		_pointer_exited()
		for action in ["walk_left", "walk_right", "walk_up", "walk_down"]:
			Input.action_release(action)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		app_focused = true

func _bone_points() -> Dictionary:
	var points := {}
	var skeleton: Skeleton3D = avatar.find_children("*", "Skeleton3D", true, false)[0]
	for name_ in ["Hips", "Foot.L", "Foot.R", "Shin.L", "Shin.R", "Hand.L", "Hand.R"]:
		var index := skeleton.find_bone(name_)
		if index >= 0:
			var point := skeleton.global_transform * skeleton.get_bone_global_pose(index).origin
			points[name_] = [point.x, point.y, point.z]
	return points

func _lightmap_state() -> Dictionary:
	var lightmap := room.find_child("LightmapGI", true, false) as LightmapGI
	if lightmap == null or lightmap.light_data == null:
		return {"users": 0, "textures": 0}
	return {"users": lightmap.light_data.get_user_count(), "textures": lightmap.light_data.get_lightmap_textures().size(), "shadowmasks": lightmap.light_data.get_shadowmask_textures().size(), "probe_points": lightmap.light_data.get("probe_data").points.size()}

func snapshot() -> Dictionary:
	var screen_point := camera.unproject_position(player.position + Vector3(0, 0.8, 0))
	var sorted := frame_ms.duplicate()
	sorted.sort()
	var mean := 0.0
	for value in frame_ms:
		mean += value / maxf(1, frame_ms.size())
	return {"version": 2, "bones": _bone_points(), "frame_samples": frame_ms.size(), "draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), "objects": Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME), "triangles": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME), "process_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000, "physics_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000, "active_room": _room_at(player.position), "house_rooms": house_layout.keys(),
		"x": player.position.x, "y": player.position.y, "z": player.position.z,
		"mode": mode, "seat_id": seat_id, "target": interaction_target, "animation": animation, "clip": animation_player.current_animation,
		"avatar_scale": [avatar.scale.x, avatar.scale.y, avatar.scale.z], "avatar_yaw": avatar.rotation.y,
		"input_locked": mode != "EXPLORE" or awaiting_movement_release,
		"camera": [camera.position.x, camera.position.y, camera.position.z], "camera_yaw": camera_yaw,
		"camera_focus": [camera_focus.x, camera_focus.y, camera_focus.z], "explore_target": [_explore_target().x, _explore_target().y, _explore_target().z],
		"pointer_inside": pointer_inside, "edge_armed": edge_armed, "edge_direction": edge_direction, "edge_turn_rate": edge_turn_rate, "app_focused": app_focused,
		"pointer": [pointer_position.x, pointer_position.y], "edge_band": clampf(get_viewport().get_visible_rect().size.x * 0.08, 48.0, 120.0), "camera_blending": camera_blend_elapsed < 0.45,
		"body_obstructions": _visible_body_obstructions(), "rendered_body_obstructions": _visible_rendered_body_obstructions(), "occlusion_hidden_groups": occlusion_hidden_groups,
		"player_screen": [screen_point.x, screen_point.y], "viewport": [get_viewport().get_visible_rect().size.x, get_viewport().get_visible_rect().size.y], "camera_facing_dot": (-camera.global_basis.z).normalized().dot((camera_focus - camera.global_position).normalized()),
		"target_camera_yaw": target_camera_yaw, "camera_pitch_degrees": -camera.rotation_degrees.x,
		"camera_fov": camera.fov, "zoom": zoom, "target_zoom": target_zoom,
		"seats": scene_data.seats, "cycles": completed_cycles, "transition_collisions": transition_collisions, "frame_mean_ms": mean,
		"frame_p95_ms": sorted[int(sorted.size() * 0.95)] if not sorted.is_empty() else 0,
		"room_meshes": room_meshes.size(), "lightmap": _lightmap_state()}

















