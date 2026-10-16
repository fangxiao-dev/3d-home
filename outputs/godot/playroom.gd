extends Node3D
## Keyboard controls integrated with the existing Blender living-room asset.

const ROOM = preload("res://assets/living-room.glb")
const SPEED := 2.2
const CAMERA_OFFSET := Vector3(0, 0.7, 5.0)
var room: Node3D
var room_meshes: Array[MeshInstance3D] = []
var colliders: Dictionary = {}
var lamp_position := Vector3.ZERO
var lamp_off_color: Color
var player: CharacterBody3D
var avatar: Node3D
var camera: Camera3D
var lamp_body: StaticBody3D
var lamp_light: OmniLight3D
var lamp_material: StandardMaterial3D
var prompt: Label
var lamp_on := false
var interaction_count := 0
var near_lamp := false
var test_mode := false

func _ready() -> void:
	for pair in [["walk_left", KEY_LEFT], ["walk_right", KEY_RIGHT], ["walk_up", KEY_UP], ["walk_down", KEY_DOWN]]:
		if not InputMap.has_action(pair[0]):
			InputMap.add_action(pair[0])
			var key := InputEventKey.new()
			key.physical_keycode = pair[1]
			InputMap.action_add_event(pair[0], key)
	_build_room()
	_build_player()
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 62.0
	camera.near = 0.1
	add_child(camera)
	camera.position = _camera_target() + CAMERA_OFFSET
	camera.look_at(_camera_target())
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

func _build_room() -> void:
	room = ROOM.instantiate()
	add_child(room)
	var groups: Dictionary = {}
	for node in room.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		room_meshes.append(mesh)
		var category: String = mesh.get_meta("extras", {}).get("category", "")
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
		if str(mesh.name).begins_with("Chair seat"):
			var seat: AABB = mesh.global_transform * mesh.get_aabb()
			_collision_box(str(mesh.name), Vector3(seat.get_center().x,0.6,seat.get_center().z), Vector3(seat.size.x+0.03,1.2,seat.size.z+0.03))
	for group in groups:
		_solid_furniture(group, groups[group])
	_collision_box("Floor", Vector3(0,-0.1,-2.9), Vector3(4.3,0.2,5.8))
	_collision_box("HallBoundary", Vector3(0,1,0.1), Vector3(4.3,2,0.2))
	_collision_box("BalconyBoundary", Vector3(0,1,-5.9), Vector3(4.3,2,0.2))
	var shade := room.find_child("Floor lampshade",true,false) as MeshInstance3D
	var foot := room.find_child("Floor lamp foot",true,false) as MeshInstance3D
	assert(shade != null and foot != null, "Existing floor lamp missing from Blender asset")
	lamp_position = foot.global_position
	lamp_position.y = 0
	lamp_body = _collision_box("FloorLamp", lamp_position+Vector3(0,0.9,0), Vector3(0.3,1.8,0.3))
	# The imported shade shares its ivory material with room trim. Override only it.
	lamp_material = shade.mesh.surface_get_material(0).duplicate() as StandardMaterial3D
	shade.material_override = lamp_material
	lamp_off_color = lamp_material.albedo_color
	lamp_material.emission_enabled = true
	lamp_material.emission = Color("ffc469")
	lamp_material.emission_energy_multiplier = 0.0
	lamp_light = OmniLight3D.new()
	lamp_light.position = shade.global_position+Vector3(0,0.1,0)
	lamp_light.light_color = Color("ffce82")
	lamp_light.light_energy = 1.6
	lamp_light.omni_range = 2.6
	lamp_light.visible = false
	add_child(lamp_light)
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
	for z in [-1.0,-3.0,-5.1]:
		var fill := OmniLight3D.new()
		fill.position = Vector3(0,2.4,z)
		fill.light_color = Color("fff0d8")
		fill.light_energy = 0.34
		fill.omni_range = 5.0
		fill.shadow_enabled = false
		add_child(fill)

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0,0.02,-0.65)
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
	_mesh(avatar, torso, Vector3(0,0.48,0), _material("367b8b"))
	var head := SphereMesh.new()
	head.radius = 0.19
	head.height = 0.38
	_mesh(avatar, head, Vector3(0,0.99,0), _material("e8bd8b"))
	for x in [-0.065,0.065]:
		var eye := SphereMesh.new()
		eye.radius = 0.025
		eye.height = 0.05
		_mesh(avatar, eye, Vector3(x,1.02,-0.174), _material("253539"))
	for x in [-0.12,0.12]:
		var foot := BoxMesh.new()
		foot.size = Vector3(0.17,0.16,0.29)
		_mesh(avatar, foot, Vector3(x,0.08,-0.04), _material("37494c"))
	# A soft contact mark grounds the character without room-wide shadow maps.
	var shadow_image := Image.create(64,64,false,Image.FORMAT_RGBA8)
	for y in range(64):
		for x in range(64):
			var radius := (Vector2(x,y)-Vector2(31.5,31.5)).length()/31.5
			shadow_image.set_pixel(x,y,Color(0.12,0.10,0.08,0.45*pow(maxf(0,1-radius),1.5)))
	var shadow_material := StandardMaterial3D.new()
	shadow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_material.albedo_texture = ImageTexture.create_from_image(shadow_image)
	var shadow_shape := QuadMesh.new()
	shadow_shape.size = Vector2(1.0,0.85)
	var shadow := _mesh(player,shadow_shape,Vector3(0,0.012,0),shadow_material)
	shadow.name = "ContactShadow"
	shadow.rotation.x = -PI/2
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(22,22)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10,0.18,0.20,0.93)
	style.set_corner_radius_all(12)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel",style)
	var theme := Theme.new()
	theme.default_font = load("res://assets/NotoSansSC-Play.ttf")
	theme.default_font_size = 18
	panel.theme = theme
	layer.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",8)
	panel.add_child(column)
	for text_ in ["我们的家 · 客厅", "↑ ↓ ← → 移动 · E 互动", "走到窗边落地灯旁，按 E 开关。"]:
		var label := Label.new()
		label.text = text_
		column.add_child(label)
	prompt = Label.new()
	prompt.add_theme_color_override("font_color",Color("ffd689"))
	column.add_child(prompt)

func _physics_process(delta: float) -> void:
	var movement := Input.get_vector("walk_left","walk_right","walk_up","walk_down")
	player.velocity.x = movement.x*SPEED
	player.velocity.z = movement.y*SPEED
	player.velocity.y = 0.0 if player.is_on_floor() else player.velocity.y-18.0*delta
	player.move_and_slide()
	if movement.length_squared()>0.01:
		avatar.rotation.y = lerp_angle(avatar.rotation.y,atan2(-movement.x,-movement.y),1-exp(-14*delta))
	near_lamp = can_interact()
	prompt.text = ("E 关灯 · 灯亮了" if lamp_on else "E 开灯") if near_lamp else ("落地灯已点亮，可以继续走动。" if lamp_on else "靠近落地灯后，按 E 开灯。")
	var aim := _camera_target()
	camera.position = camera.position.lerp(aim+CAMERA_OFFSET,1-exp(-7*delta))
	# Keep the camera orientation fixed so screen-up always matches ArrowUp.
	if test_mode:
		JavaScriptBridge.eval("window.__playroom = "+JSON.stringify(snapshot()), true)

func _camera_target() -> Vector3:
	# Eye-level perspective restores depth; fixed heading keeps arrow directions stable.
	return Vector3(clampf(player.position.x*0.5,-0.65,0.65),1.2,player.position.z-2.0)

func can_interact() -> bool:
	var flat := player.position-lamp_position
	flat.y = 0
	if flat.length()>1.35:
		return false
	var ray := PhysicsRayQueryParameters3D.create(player.position+Vector3(0,0.65,0),lamp_position+Vector3(0,0.65,0),1)
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	return hit.is_empty() or hit.collider==lamp_body

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_E:
		get_viewport().set_input_as_handled()
		if can_interact():
			lamp_on = not lamp_on
			interaction_count += 1
			lamp_light.visible = lamp_on
			lamp_material.albedo_color = Color("ffd071") if lamp_on else lamp_off_color
			lamp_material.emission_energy_multiplier = 1.4 if lamp_on else 0.0
			print("LAMP_TOGGLE ", lamp_on)

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
		for action in ["walk_left","walk_right","walk_up","walk_down"]:
			Input.action_release(action)
		if is_instance_valid(player):
			player.velocity = Vector3.ZERO

func snapshot() -> Dictionary:
	return {"x":player.position.x,"y":player.position.y,"z":player.position.z,
		"camera":[camera.position.x,camera.position.y,camera.position.z],
		"near":can_interact(),"lamp_on":lamp_on,"interactions":interaction_count,
		"room_meshes":room_meshes.size(),"colliders":colliders.size()}
