extends Node3D
## Keyboard controls integrated with the existing Blender living-room asset.

const ROOM = preload("res://assets/living-room.glb")
const ROOM_WIDTH := 5.8
const ROOM_DEPTH := 5.8
const ROOM_HEIGHT := 3.3
const SPEED := 2.2
const CAMERA_DISTANCE := 3.6
const CAMERA_LOOK_HEIGHT := 0.82
const CAMERA_FOV := 62.0
const CAMERA_PITCH_DEGREES := 29.0
const CLOSEUP_FOV := 48.0
const CAMERA_SMOOTH := 10.0
const ZOOM_SMOOTH := 10.0
const SOFA_INTERACT_DISTANCE := 1.25

const MODE_EXPLORE := "EXPLORE"
const MODE_TRANSITION := "TRANSITION"
const MODE_CLOSE_UP := "CLOSE_UP"

var room: Node3D
var room_meshes: Array[MeshInstance3D] = []
var colliders: Dictionary = {}
var visibility_groups: Dictionary = {
	"left_wall": [],
	"right_wall": [],
	"rear_window": [],
	"ceiling_top": []
}
var stool_target_point := Vector3(-0.74, 0.62, -1.67)
var sofa_middle_target_point := Vector3(-1.26, 0.62, -3.35)
var window_cushion_target_point := Vector3(-1.26, 0.62, -4.21)
var sofa_middle_sit_point := Vector3(-1.55, 0.02, -3.35)
var window_cushion_sit_point := Vector3(-1.55, 0.02, -4.21)
var player: CharacterBody3D
var avatar: Node3D
var avatar_torso: MeshInstance3D
var avatar_head: MeshInstance3D
var avatar_eyes: Array[MeshInstance3D] = []
var avatar_feet: Array[MeshInstance3D] = []
var avatar_seated_parts: Array[MeshInstance3D] = []
var contact_shadow: MeshInstance3D
var camera: Camera3D
var prompt: Label
var help_labels: Array[Label] = []
var target_markers: Dictionary = {}
var fade_rect: ColorRect
var interaction_target := ""
var test_mode := false
var layout_features: Dictionary = {}

var mode := MODE_EXPLORE
var camera_yaw := 0.0
var target_camera_yaw := 0.0
var zoom := 1.0
var target_zoom := 1.0
var camera_turning := false
var awaiting_movement_release := false
var transition_busy := false
var closeup_target := ""
var seated_target := ""
var active_closeup_preset: Dictionary = {}
var closeup_presets: Dictionary = {}
var camera_turn_elapsed := 0.0
var camera_turn_start := 0.0

var saved_player_position := Vector3.ZERO
var saved_avatar_heading := 0.0
var saved_camera_yaw := 0.0
var saved_target_camera_yaw := 0.0
var saved_zoom := 1.0
var saved_target_zoom := 1.0
var saved_room_visibility: Dictionary = {}
var saved_avatar_visible := true
var saved_shadow_visible := true
var saved_avatar_position := Vector3.ZERO
var saved_avatar_rotation := Vector3.ZERO
var saved_avatar_scale := Vector3.ONE

func _ready() -> void:
	for pair in [["walk_left", KEY_LEFT], ["walk_right", KEY_RIGHT], ["walk_up", KEY_UP], ["walk_down", KEY_DOWN]]:
		if not InputMap.has_action(pair[0]):
			InputMap.add_action(pair[0])
			var key := InputEventKey.new()
			key.physical_keycode = pair[1]
			InputMap.action_add_event(pair[0], key)
	_build_room()
	layout_features = _layout_features()
	_build_player()
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = CAMERA_FOV
	camera.near = 0.1
	add_child(camera)
	_snap_exploration_camera()
	camera.make_current()
	_build_ui()
	if OS.has_feature("web"):
		test_mode = bool(JavaScriptBridge.eval("window.location.search.includes('test')", true))
		print("PLAYROOM_TEST_MODE ", test_mode)
	print("PLAYROOM_READY")

func _material(color: String) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = Color(color)
	result.roughness = 0.85
	return result

func _mesh(parent: Node3D, shape: Mesh, position_: Vector3, material_: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = shape
	node.material_override = material_
	node.position = position_
	parent.add_child(node)
	return node

func _collision_box(name_: String, position_: Vector3, size_: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = name_
	body.position = position_
	add_child(body)
	var shape := BoxShape3D.new()
	shape.size = size_
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)
	colliders[name_] = body
	return body

func _bounds(nodes: Array[MeshInstance3D]) -> AABB:
	assert(not nodes.is_empty(), "Missing living-room collision geometry")
	var bounds: AABB = nodes[0].global_transform * nodes[0].get_aabb()
	for node in nodes.slice(1):
		bounds = bounds.merge(node.global_transform * node.get_aabb())
	return bounds

func _solid_furniture(name_: String, nodes: Array[MeshInstance3D]) -> void:
	var bounds := _bounds(nodes)
	# A simple solid footprint stops the avatar squeezing beneath tabletops.
	var top := bounds.end.y
	bounds.position.y = 0
	bounds.size.y = top
	_collision_box(name_, bounds.get_center(), bounds.size)

func _add_visibility_node(group: String, mesh: MeshInstance3D) -> void:
	var nodes: Array = visibility_groups.get(group, [])
	nodes.append(mesh)
	visibility_groups[group] = nodes

func _visibility_group_for(mesh: MeshInstance3D, category: String) -> String:
	var node_name := str(mesh.name)
	var x := mesh.global_position.x
	if category == "Wall_Sofa":
		return "left_wall"
	if category == "Wall_TV":
		return "right_wall"
	if category == "Ceiling":
		return "ceiling_top"
	if node_name.begins_with("Chandelier"):
		return "ceiling_top"
	if node_name.begins_with("Window") or node_name.begins_with("Curtain") or node_name.begins_with("Balcony opening") or node_name.begins_with("Balcony lintel") or node_name.begins_with("Balcony threshold"):
		return "rear_window"
	if node_name.begins_with("Entrance door") or node_name.begins_with("Door casing") or node_name.begins_with("Door centre seam") or node_name.begins_with("Door handle"):
		return "left_wall"
	if node_name.begins_with("Baseboard") or node_name.begins_with("Crown moulding") or node_name.begins_with("Wall panel"):
		return "left_wall" if x < 0.0 else "right_wall"
	if node_name.begins_with("Sconce"):
		return "right_wall"
	if category == "TV":
		return "right_wall"
	return ""

func _build_room() -> void:
	room = ROOM.instantiate()
	add_child(room)
	var groups: Dictionary = {}
	for node in room.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		room_meshes.append(mesh)
		var category: String = mesh.get_meta("extras", {}).get("category", "")
		var visibility_group := _visibility_group_for(mesh, category)
		if not visibility_group.is_empty():
			_add_visibility_node(visibility_group, mesh)
		var group := ""
		if category == "Sofa":
			group = "SofaReturn" if str(mesh.name).begins_with("Sofa return") else "SofaMain"
		elif category in ["TeaTable", "TVConsole", "Dresser", "PetBed"]:
			group = category
		elif category == "SideTables":
			group = "BalconyCabinet" if str(mesh.name).begins_with("Balcony") else "EntranceTable"
		if not group.is_empty():
			if not groups.has(group):
				groups[group] = [] as Array[MeshInstance3D]
			groups[group].append(mesh)
		if category in ["Wall_Sofa", "Wall_TV"]:
			var bounds: AABB = mesh.global_transform * mesh.get_aabb()
			_collision_box(category, bounds.get_center(), bounds.size)
	for group in groups:
		_solid_furniture(group, groups[group])
	if groups.has("SofaReturn"):
		var stool_bounds := _bounds(groups["SofaReturn"])
		stool_target_point = Vector3(stool_bounds.end.x - 0.10, clampf(stool_bounds.position.y + 0.58, 0.55, 0.90), stool_bounds.end.z - 0.12)
	if groups.has("SofaMain"):
		var sofa_bounds := _bounds(groups["SofaMain"])
		sofa_middle_target_point = Vector3(sofa_bounds.end.x - 0.10, 0.62, -3.35)
		window_cushion_target_point = Vector3(sofa_bounds.end.x - 0.10, 0.62, -4.21)
		sofa_middle_sit_point = Vector3(sofa_bounds.get_center().x, 0.40, -3.35)
		window_cushion_sit_point = Vector3(sofa_bounds.get_center().x, 0.40, -4.21)
	_register_closeup_presets()
	_collision_box("Floor", Vector3(0, -0.1, -ROOM_DEPTH / 2.0), Vector3(ROOM_WIDTH, 0.2, ROOM_DEPTH))
	_collision_box("HallBoundary", Vector3(0, 1, 0.1), Vector3(ROOM_WIDTH, 2, 0.2))
	_collision_box("BalconyBoundary", Vector3(0, 1, -ROOM_DEPTH - 0.1), Vector3(ROOM_WIDTH, 2, 0.2))
	var shade := room.find_child("Floor lampshade", true, false) as MeshInstance3D
	var foot := room.find_child("Floor lamp foot", true, false) as MeshInstance3D
	assert(shade != null and foot != null, "Existing floor lamp decoration missing from Blender asset")
	var floor_lamp_position := foot.global_position
	floor_lamp_position.y = 0
	_collision_box("FloorLamp", floor_lamp_position + Vector3(0, 0.9, 0), Vector3(0.3, 1.8, 0.3))
	_build_target_markers()
	# Keep the floor lamp as warm static decoration; it has no interaction action.
	var decor_material := shade.mesh.surface_get_material(0).duplicate() as StandardMaterial3D
	shade.material_override = decor_material
	decor_material.emission_enabled = true
	decor_material.emission = Color("ffc469")
	decor_material.emission_energy_multiplier = 0.65
	var decor_light := OmniLight3D.new()
	decor_light.position = shade.global_position + Vector3(0, 0.1, 0)
	decor_light.light_color = Color("ffce82")
	decor_light.light_energy = 0.65
	decor_light.omni_range = 2.6
	decor_light.visible = true
	add_child(decor_light)
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("263c42")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("fff0da")
	env.ambient_light_energy = 1.00
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = 1.60
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, -30, 0)
	sun.light_color = Color("ffe9c9")
	sun.light_energy = 0.45
	sun.shadow_enabled = false
	add_child(sun)
	for z in [-1.0, -3.0, -5.1]:
		var fill := OmniLight3D.new()
		fill.position = Vector3(0, 2.85, z)
		fill.light_color = Color("fff0d8")
		fill.light_energy = 0.34
		fill.omni_range = 5.0
		fill.shadow_enabled = false
		add_child(fill)

func _find_room_mesh(prefix: String) -> MeshInstance3D:
	for node in room.find_children("*", "MeshInstance3D", true, false):
		if str(node.name).begins_with(prefix):
			return node as MeshInstance3D
	return null

func _layout_features() -> Dictionary:
	var base := _find_room_mesh("Sofa return base")
	var wall := _find_room_mesh("Sofa side wall")
	var window_back := _find_room_mesh("Window daylight backing")
	var tv_bezel := _find_room_mesh("Television bezel")
	var tea_top := _find_room_mesh("Tea table top")
	var result := {
		"entrance_table": colliders.has("EntranceTable") or _find_room_mesh("Entrance side table") != null,
		"sofa_return_width": -1.0,
		"sofa_return_left": 0.0,
		"sofa_return_right": 0.0,
		"room_width": ROOM_WIDTH,
		"room_depth": ROOM_DEPTH,
		"room_height": -1.0,
		"window_top": -1.0,
		"tv_bezel_x": 0.0,
		"tea_table_right": -1.0
	}
	if base != null:
		var base_bounds: AABB = base.global_transform * base.get_aabb()
		result["sofa_return_width"] = base_bounds.size.x
		result["sofa_return_left"] = base_bounds.position.x
		result["sofa_return_right"] = base_bounds.end.x
	if wall != null:
		result["room_height"] = (wall.global_transform * wall.get_aabb()).size.y
	if window_back != null:
		result["window_top"] = (window_back.global_transform * window_back.get_aabb()).end.y
	if tv_bezel != null:
		result["tv_bezel_x"] = tv_bezel.global_position.x
	if tea_top != null:
		result["tea_table_right"] = (tea_top.global_transform * tea_top.get_aabb()).end.x
	return result

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0, 0.02, -0.65)
	player.collision_layer = 2
	player.collision_mask = 1
	add_child(player)
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.23
	shape.height = 1.1
	collision.shape = shape
	collision.position.y = 0.55
	player.add_child(collision)
	avatar = Node3D.new()
	player.add_child(avatar)
	var torso := CapsuleMesh.new()
	torso.radius = 0.23
	torso.height = 0.67
	avatar_torso = _mesh(avatar, torso, Vector3(0, 0.48, 0), _material("367b8b"))
	avatar_torso.name = "AvatarTorso"
	var head := SphereMesh.new()
	head.radius = 0.19
	head.height = 0.38
	avatar_head = _mesh(avatar, head, Vector3(0, 0.99, 0), _material("e8bd8b"))
	avatar_head.name = "AvatarHead"
	for x in [-0.065, 0.065]:
		var eye := SphereMesh.new()
		eye.radius = 0.025
		eye.height = 0.05
		var eye_node := _mesh(avatar, eye, Vector3(x, 1.02, -0.174), _material("253539"))
		eye_node.name = "AvatarEye"
		avatar_eyes.append(eye_node)
	for x in [-0.12, 0.12]:
		var foot := BoxMesh.new()
		foot.size = Vector3(0.17, 0.16, 0.29)
		var foot_node := _mesh(avatar, foot, Vector3(x, 0.08, -0.04), _material("37494c"))
		foot_node.name = "AvatarFoot"
		avatar_feet.append(foot_node)
		var thigh_mesh := BoxMesh.new()
		thigh_mesh.size = Vector3(0.15, 0.14, 0.36)
		var thigh := _mesh(avatar, thigh_mesh, Vector3(x, 0.32, -0.16), _material("367b8b"))
		thigh.name = "AvatarThigh"
		avatar_seated_parts.append(thigh)
		var shin_mesh := BoxMesh.new()
		shin_mesh.size = Vector3(0.14, 0.26, 0.14)
		var shin := _mesh(avatar, shin_mesh, Vector3(x, 0.14, -0.28), _material("367b8b"))
		shin.name = "AvatarShin"
		avatar_seated_parts.append(shin)
	# A soft contact mark grounds the character without room-wide shadow maps.
	var shadow_image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in range(64):
		for x in range(64):
			var radius := (Vector2(x, y) - Vector2(31.5, 31.5)).length() / 31.5
			shadow_image.set_pixel(x, y, Color(0.12, 0.10, 0.08, 0.45 * pow(maxf(0, 1 - radius), 1.5)))
	var shadow_material := StandardMaterial3D.new()
	shadow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_material.albedo_texture = ImageTexture.create_from_image(shadow_image)
	var shadow_shape := QuadMesh.new()
	shadow_shape.size = Vector2(1.0, 0.85)
	contact_shadow = _mesh(player, shadow_shape, Vector3(0, 0.012, 0), shadow_material)
	contact_shadow.name = "ContactShadow"
	contact_shadow.rotation.x = -PI / 2
	contact_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_apply_standing_pose()

func _apply_standing_pose() -> void:
	if not is_instance_valid(avatar_torso):
		return
	avatar_torso.position = Vector3(0, 0.48, 0)
	avatar_torso.rotation = Vector3.ZERO
	avatar_torso.scale = Vector3.ONE
	avatar_head.position = Vector3(0, 0.99, 0)
	avatar_head.rotation = Vector3.ZERO
	avatar_head.scale = Vector3.ONE
	for i in avatar_eyes.size():
		var x := -0.065 if i == 0 else 0.065
		avatar_eyes[i].position = Vector3(x, 1.02, -0.174)
		avatar_eyes[i].rotation = Vector3.ZERO
		avatar_eyes[i].scale = Vector3.ONE
	for i in avatar_feet.size():
		var x := -0.12 if i == 0 else 0.12
		avatar_feet[i].position = Vector3(x, 0.08, -0.04)
		avatar_feet[i].rotation = Vector3.ZERO
		avatar_feet[i].scale = Vector3.ONE
	for part in avatar_seated_parts:
		part.visible = false

func _apply_seated_pose() -> void:
	if not is_instance_valid(avatar_torso):
		return
	avatar_torso.position = Vector3(0, 0.40, 0)
	avatar_torso.rotation = Vector3.ZERO
	avatar_torso.scale = Vector3(1, 0.72, 1)
	avatar_head.position = Vector3(0, 0.84, -0.02)
	avatar_head.rotation = Vector3.ZERO
	avatar_head.scale = Vector3(1, 0.90, 1)
	for i in avatar_eyes.size():
		var x := -0.065 if i == 0 else 0.065
		avatar_eyes[i].position = Vector3(x, 0.91, -0.194)
		avatar_eyes[i].rotation = Vector3.ZERO
		avatar_eyes[i].scale = Vector3.ONE
	for i in avatar_feet.size():
		var x := -0.13 if i == 0 else 0.13
		avatar_feet[i].position = Vector3(x, 0.09, -0.42)
		avatar_feet[i].rotation = Vector3(0.85, 0, 0)
		avatar_feet[i].scale = Vector3.ONE
	for i in avatar_seated_parts.size():
		var x := -0.13 if i < 2 else 0.13
		var is_thigh := i % 2 == 0
		avatar_seated_parts[i].visible = true
		avatar_seated_parts[i].position = Vector3(x, 0.32 if is_thigh else 0.15, -0.16 if is_thigh else -0.34)
		avatar_seated_parts[i].rotation = Vector3(-0.10 if is_thigh else 0.10, 0, 0)
		avatar_seated_parts[i].scale = Vector3.ONE

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(22, 22)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.18, 0.20, 0.93)
	style.set_corner_radius_all(12)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	var theme := Theme.new()
	theme.default_font = load("res://assets/NotoSansSC-Play.ttf")
	theme.default_font_size = 18
	panel.theme = theme
	layer.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	for text_ in ["我们的家 · 客厅", "↑ ↓ ← → 移动 · Q/E 旋转 · 滚轮缩放", "软墩：F 查看 · 沙发中部/窗边坐垫：F 坐下"]:
		var label := Label.new()
		label.text = text_
		column.add_child(label)
		help_labels.append(label)
	prompt = Label.new()
	prompt.add_theme_color_override("font_color", Color("ffd689"))
	column.add_child(prompt)
	fade_rect = ColorRect.new()
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.z_index = 100
	layer.add_child(fade_rect)

func _build_target_markers() -> void:
	target_markers["stool_view"] = _make_target_marker("软墩", stool_target_point + Vector3(0, 0.90, 0))
	target_markers["sofa_middle_sit"] = _make_target_marker("沙发中部", sofa_middle_target_point + Vector3(0, 0.90, 0))
	target_markers["window_cushion_sit"] = _make_target_marker("窗边坐垫", window_cushion_target_point + Vector3(0, 0.90, 0))

func _make_target_marker(text_: String, position_: Vector3) -> Label3D:
	var marker := Label3D.new()
	marker.text = text_
	marker.position = position_
	marker.font = load("res://assets/NotoSansSC-Play.ttf")
	marker.font_size = 48
	marker.pixel_size = 0.0035
	marker.modulate = Color(1.0, 0.84, 0.48, 0.92)
	marker.outline_size = 7
	marker.outline_modulate = Color(0.08, 0.12, 0.13, 0.95)
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.no_depth_test = false
	add_child(marker)
	return marker

func _movement_vector() -> Vector3:
	var strafe := Input.get_axis("walk_left", "walk_right")
	var forward_input := Input.get_axis("walk_down", "walk_up")
	var input := Vector2(strafe, forward_input)
	if input.length_squared() > 1.0:
		input = input.normalized()
	var forward := Vector3(-sin(camera_yaw), 0, -cos(camera_yaw))
	var right := Vector3(cos(camera_yaw), 0, -sin(camera_yaw))
	return right * input.x + forward * input.y

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	if mode == MODE_EXPLORE:
		if transition_busy:
			player.velocity = Vector3.ZERO
		else:
			if awaiting_movement_release:
				if not _movement_input_pressed():
					awaiting_movement_release = false
				else:
					player.velocity = Vector3.ZERO
			if not awaiting_movement_release:
				var movement := _movement_vector()
				player.velocity.x = movement.x * SPEED
				player.velocity.z = movement.z * SPEED
				player.velocity.y = 0.0 if player.is_on_floor() else player.velocity.y - 18.0 * delta
				player.move_and_slide()
				if movement.length_squared() > 0.01:
					avatar.rotation.y = lerp_angle(avatar.rotation.y, atan2(-movement.x, -movement.z), 1 - exp(-14 * delta))
	_update_prompt()
	if mode == MODE_EXPLORE:
		_update_exploration_camera(delta)
		_update_wall_visibility()
	elif mode == MODE_CLOSE_UP:
		player.velocity = Vector3.ZERO
		_apply_closeup_preset()
	else:
		player.velocity = Vector3.ZERO
	if test_mode:
		JavaScriptBridge.eval("window.__playroom = " + JSON.stringify(snapshot()), true)

func _movement_input_pressed() -> bool:
	for action in ["walk_left", "walk_right", "walk_up", "walk_down"]:
		if Input.is_action_pressed(action):
			return true
	return false

func _camera_target() -> Vector3:
	return player.position + Vector3(0, CAMERA_LOOK_HEIGHT, 0)

func _camera_position_for(yaw: float, zoom_: float) -> Vector3:
	var offset := Vector3(sin(yaw), 0, cos(yaw)) * CAMERA_DISTANCE * zoom_
	var look_target := _camera_target()
	var vertical_distance := CAMERA_DISTANCE * zoom_ * tan(deg_to_rad(CAMERA_PITCH_DEGREES))
	return look_target + Vector3(0, vertical_distance, 0) + offset

func _update_exploration_camera(delta: float) -> void:
	if camera_turning:
		camera_turn_elapsed = minf(camera_turn_elapsed + delta, 0.30)
		var progress := camera_turn_elapsed / 0.30
		var eased := progress * progress * (3.0 - 2.0 * progress)
		camera_yaw = lerp_angle(camera_turn_start, target_camera_yaw, eased)
		if progress >= 1.0:
			camera_yaw = target_camera_yaw
			camera_turning = false
	else:
		camera_yaw = target_camera_yaw
		camera_turning = false
	zoom = lerpf(zoom, target_zoom, 1 - exp(-ZOOM_SMOOTH * delta))
	if absf(zoom - target_zoom) < 0.001:
		zoom = target_zoom
	var aim := _camera_target()
	camera.position = camera.position.lerp(_camera_position_for(camera_yaw, zoom), 1 - exp(-CAMERA_SMOOTH * delta))
	camera.fov = CAMERA_FOV
	camera.look_at(aim)

func _snap_exploration_camera() -> void:
	if not is_instance_valid(camera) or not is_instance_valid(player):
		return
	camera.position = _camera_position_for(camera_yaw, zoom)
	camera.fov = CAMERA_FOV
	camera.look_at(_camera_target())
	_update_visibility_for_camera(camera.global_position)

func _register_closeup_presets() -> void:
	closeup_presets["stool_view"] = {
		"position": stool_target_point + Vector3(0.23, 0.84, 0.17),
		"look_at": stool_target_point + Vector3(0, 0.08, 0),
		"fov": CLOSEUP_FOV,
		"player_visible": false,
		"action": "view"
	}
	closeup_presets["sofa_middle_sit"] = {
		"position": sofa_middle_target_point + Vector3(1.76, 0.72, 0),
		"look_at": sofa_middle_sit_point + Vector3(0, 0.58, 0),
		"fov": 50.0,
		"player_visible": true,
		"action": "sit",
		"sit_position": sofa_middle_sit_point,
		"sit_heading": -PI / 2.0
	}
	closeup_presets["window_cushion_sit"] = {
		"position": window_cushion_target_point + Vector3(1.76, 0.72, 0),
		"look_at": window_cushion_sit_point + Vector3(0, 0.58, 0),
		"fov": 50.0,
		"player_visible": true,
		"action": "sit",
		"sit_position": window_cushion_sit_point,
		"sit_heading": -PI / 2.0
	}

func _apply_closeup_preset() -> void:
	if active_closeup_preset.is_empty():
		return
	camera.position = active_closeup_preset["position"]
	camera.fov = active_closeup_preset["fov"]
	camera.look_at(active_closeup_preset["look_at"])
	_update_visibility_for_camera(camera.global_position)
	var is_sitting: bool = active_closeup_preset.get("action", "view") == "sit"
	avatar.visible = active_closeup_preset["player_visible"]
	if is_sitting:
		avatar.position = active_closeup_preset["sit_position"] - player.position
		avatar.rotation = Vector3(0, active_closeup_preset["sit_heading"], 0)
		_apply_seated_pose()
		contact_shadow.visible = false
	else:
		_apply_standing_pose()
		contact_shadow.visible = false

func _update_wall_visibility() -> void:
	_update_visibility_for_camera(camera.global_position)

func _update_visibility_for_camera(camera_position: Vector3) -> void:
	var wall_edge := ROOM_WIDTH / 2.0 - 0.03
	var left_near := camera_position.x < -wall_edge
	var right_near := camera_position.x > wall_edge
	var rear_near := camera_position.z < -ROOM_DEPTH + 0.08
	var ceiling_near := camera_position.y > ROOM_HEIGHT
	_set_visibility_group("left_wall", not left_near)
	_set_visibility_group("right_wall", not right_near)
	_set_visibility_group("rear_window", not rear_near)
	_set_visibility_group("ceiling_top", not ceiling_near)

func _set_visibility_group(group: String, visible: bool) -> void:
	for node in visibility_groups.get(group, []):
		if is_instance_valid(node):
			node.visible = visible

func _hidden_group_names() -> Array:
	var result: Array = []
	for group in visibility_groups.keys():
		var hidden := false
		for node in visibility_groups[group]:
			if is_instance_valid(node) and not node.visible:
				hidden = true
				break
		if hidden:
			result.append(group)
	return result

func _ray_reaches(point: Vector3, allowed: Object) -> bool:
	var from := player.position + Vector3(0, 0.65, 0)
	var to := point + Vector3(0, 0.55, 0)
	var ray := PhysicsRayQueryParameters3D.create(from, to, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	return hit.is_empty() or (allowed != null and hit.collider == allowed)

func _target_reachable(point: Vector3, max_distance: float, allowed: Object) -> bool:
	var flat := player.position - point
	flat.y = 0
	if flat.length() > max_distance:
		return false
	return _ray_reaches(point, allowed)

func _stool_reachable() -> bool:
	return _target_reachable(stool_target_point, SOFA_INTERACT_DISTANCE, colliders.get("SofaReturn"))

func _sofa_middle_reachable() -> bool:
	return _target_reachable(sofa_middle_target_point, SOFA_INTERACT_DISTANCE, colliders.get("SofaMain"))

func _window_cushion_reachable() -> bool:
	return _target_reachable(window_cushion_target_point, SOFA_INTERACT_DISTANCE, colliders.get("SofaMain"))

func _nearest_interaction_target() -> String:
	var candidates: Array[String] = []
	if _stool_reachable():
		candidates.append("stool_view")
	if _sofa_middle_reachable():
		candidates.append("sofa_middle_sit")
	if _window_cushion_reachable():
		candidates.append("window_cushion_sit")
	var nearest := ""
	var nearest_distance := INF
	for target in candidates:
		var point: Vector3 = _target_point_for(target)
		var distance := player.position.distance_squared_to(point)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = target
	return nearest

func _target_point_for(target: String) -> Vector3:
	match target:
		"stool_view":
			return stool_target_point
		"sofa_middle_sit":
			return sofa_middle_target_point
		"window_cushion_sit":
			return window_cushion_target_point
	return Vector3.ZERO

func _update_prompt() -> void:
	for label in help_labels:
		label.visible = mode == MODE_EXPLORE
	for marker in target_markers.values():
		marker.visible = mode == MODE_EXPLORE and not transition_busy
	if mode == MODE_TRANSITION:
		prompt.text = ""
		return
	if mode == MODE_CLOSE_UP:
		match closeup_target:
			"stool_view":
				prompt.text = "查看软墩 · Esc 返回"
			"sofa_middle_sit":
				prompt.text = "沙发中部 · Esc 返回"
			"window_cushion_sit":
				prompt.text = "窗边坐垫 · Esc 返回"
			_:
				prompt.text = "Esc 返回"
		return
	interaction_target = _nearest_interaction_target()
	match interaction_target:
		"stool_view":
			prompt.text = "F 查看软墩"
		"sofa_middle_sit":
			prompt.text = "F 坐下：沙发中部"
		"window_cushion_sit":
			prompt.text = "F 坐下：窗边坐垫"
		_:
			prompt.text = "沿标记寻找软墩和两个坐垫。"

func _save_exploration_state() -> void:
	saved_player_position = player.position
	saved_avatar_heading = avatar.rotation.y
	# Capture the currently displayed interpolation state. A pending Q/E or
	# wheel target must not resume after the close-up restores exploration.
	saved_camera_yaw = camera_yaw
	saved_target_camera_yaw = camera_yaw
	saved_zoom = zoom
	saved_target_zoom = zoom
	camera_turning = false
	camera_turn_elapsed = 0.0
	camera_turn_start = camera_yaw
	target_camera_yaw = camera_yaw
	target_zoom = zoom
	saved_room_visibility.clear()
	for mesh in room_meshes:
		saved_room_visibility[str(mesh.get_path())] = mesh.visible
	saved_avatar_visible = avatar.visible
	saved_shadow_visible = contact_shadow.visible
	saved_avatar_position = avatar.position
	saved_avatar_rotation = avatar.rotation
	saved_avatar_scale = avatar.scale

func _restore_exploration_state() -> void:
	player.position = saved_player_position
	player.velocity = Vector3.ZERO
	avatar.rotation.y = saved_avatar_heading
	camera_yaw = saved_camera_yaw
	target_camera_yaw = saved_target_camera_yaw
	zoom = saved_zoom
	target_zoom = saved_target_zoom
	camera_turning = false
	camera_turn_elapsed = 0.0
	camera_turn_start = camera_yaw
	for mesh in room_meshes:
		var key := str(mesh.get_path())
		if saved_room_visibility.has(key):
			mesh.visible = saved_room_visibility[key]
	_apply_standing_pose()
	avatar.position = saved_avatar_position
	avatar.rotation = saved_avatar_rotation
	avatar.scale = saved_avatar_scale
	avatar.visible = saved_avatar_visible
	contact_shadow.visible = saved_shadow_visible
	seated_target = ""
	_snap_exploration_camera()

func _fade_to(alpha: float) -> void:
	fade_rect.visible = true
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fade_rect, "color:a", alpha, 0.18)
	await tween.finished
	if is_zero_approx(alpha):
		fade_rect.visible = false

func _enter_target_action(target: String) -> void:
	if mode != MODE_EXPLORE or transition_busy:
		return
	_save_exploration_state()
	closeup_target = target
	active_closeup_preset = closeup_presets.get(closeup_target, {})
	if active_closeup_preset.is_empty():
		return
	seated_target = target if active_closeup_preset.get("action", "view") == "sit" else ""
	transition_busy = true
	mode = MODE_TRANSITION
	await _fade_to(1.0)
	mode = MODE_CLOSE_UP
	_apply_closeup_preset()
	await _fade_to(0.0)
	transition_busy = false

func _exit_target_action() -> void:
	if mode != MODE_CLOSE_UP or transition_busy:
		return
	transition_busy = true
	mode = MODE_TRANSITION
	await _fade_to(1.0)
	_restore_exploration_state()
	closeup_target = ""
	active_closeup_preset = {}
	seated_target = ""
	mode = MODE_EXPLORE
	awaiting_movement_release = true
	await _fade_to(0.0)
	transition_busy = false

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed or mode != MODE_EXPLORE or transition_busy:
		return
	if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
		target_zoom = clampf(target_zoom - 0.05, 0.85, 1.15)
		get_viewport().set_input_as_handled()
	elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		target_zoom = clampf(target_zoom + 0.05, 0.85, 1.15)
		get_viewport().set_input_as_handled()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	var code := key.physical_keycode if key.physical_keycode != 0 else key.keycode
	if mode == MODE_CLOSE_UP and code == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_exit_target_action()
		return
	if mode != MODE_EXPLORE or transition_busy:
		return
	if code == KEY_Q:
		if not camera_turning:
			camera_turn_start = camera_yaw
			camera_turn_elapsed = 0.0
			target_camera_yaw = wrapf(target_camera_yaw + PI / 2.0, -PI, PI)
			camera_turning = true
		get_viewport().set_input_as_handled()
	elif code == KEY_E:
		if not camera_turning:
			camera_turn_start = camera_yaw
			camera_turn_elapsed = 0.0
			target_camera_yaw = wrapf(target_camera_yaw - PI / 2.0, -PI, PI)
			camera_turning = true
		get_viewport().set_input_as_handled()
	elif code == KEY_F:
		interaction_target = _nearest_interaction_target()
		if not interaction_target.is_empty():
			_enter_target_action(interaction_target)
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		for action in ["walk_left", "walk_right", "walk_up", "walk_down"]:
			Input.action_release(action)
		if is_instance_valid(player):
			player.velocity = Vector3.ZERO

func snapshot() -> Dictionary:
	var shadow_visible := is_instance_valid(contact_shadow) and contact_shadow.visible
	var camera_delta := camera.position - _camera_target()
	var camera_horizontal_distance := Vector2(camera_delta.x, camera_delta.z).length()
	var marker_state: Dictionary = {}
	for target in target_markers.keys():
		marker_state[target] = target_markers[target].visible
	return {
		"x": player.position.x,
		"y": player.position.y,
		"z": player.position.z,
		"camera": [camera.position.x, camera.position.y, camera.position.z],
		"camera_fov": camera.fov,
		"camera_pitch_degrees": rad_to_deg(atan2(camera_delta.y, camera_horizontal_distance)),
		"camera_yaw": camera_yaw,
		"camera_yaw_degrees": rad_to_deg(camera_yaw),
		"target_camera_yaw": target_camera_yaw,
		"target_camera_yaw_degrees": rad_to_deg(target_camera_yaw),
		"zoom": zoom,
		"target_zoom": target_zoom,
		"rotation_in_progress": camera_turning,
		"mode": mode,
		"closeup_target": closeup_target,
		"seated_target": seated_target,
		"input_locked": mode != MODE_EXPLORE or transition_busy or awaiting_movement_release,
		"player_visible": avatar.visible,
		"avatar_visible": avatar.visible,
		"avatar_position": [avatar.global_position.x, avatar.global_position.y, avatar.global_position.z],
		"avatar_rotation_y": avatar.global_rotation.y,
		"contact_shadow_visible": shadow_visible,
		"hidden_groups": _hidden_group_names(),
		"target": interaction_target,
		"near": not interaction_target.is_empty(),
		"target_points": {
			"stool_view": [stool_target_point.x, stool_target_point.y, stool_target_point.z],
			"sofa_middle_sit": [sofa_middle_target_point.x, sofa_middle_target_point.y, sofa_middle_target_point.z],
			"window_cushion_sit": [window_cushion_target_point.x, window_cushion_target_point.y, window_cushion_target_point.z]
		},
		"sit_points": {
			"sofa_middle_sit": [sofa_middle_sit_point.x, sofa_middle_sit_point.y, sofa_middle_sit_point.z],
			"window_cushion_sit": [window_cushion_sit_point.x, window_cushion_sit_point.y, window_cushion_sit_point.z]
		},
		"marker_visible": marker_state,
		"room_meshes": room_meshes.size(),
		"colliders": colliders.size(),
		"layout": layout_features
	}
