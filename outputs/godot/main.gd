extends Node3D
## Inspection preview only: no story, player character or furniture interactions yet.

const ROOM = preload("res://assets/living-room.glb")
const UI_FONT = preload("res://assets/NotoSansSC-Preview.ttf")
var room: Node3D
var camera: Camera3D
var target := Vector3(0, 1.2, -2.9)
var radius := 4.5
var yaw := 0.0
var pitch := 0.1
var dragging := false
var current_view := 0
var buttons: Array[Button] = []
var view_label: Label
const VIEW_NAMES = ["入口", "沙发", "电视", "俯瞰"]

func _ready() -> void:
	room = ROOM.instantiate()
	add_child(room)
	camera = Camera3D.new()
	camera.fov = 74
	camera.near = 0.05
	add_child(camera)
	camera.make_current()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("252b2c")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("ede5d6")
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world := WorldEnvironment.new()
	world.environment = env
	add_child(world)
	var sunlight := DirectionalLight3D.new()
	sunlight.rotation_degrees = Vector3(-38, -30, 0)
	sunlight.light_color = Color("fff0d8")
	sunlight.light_energy = 0.4
	sunlight.shadow_enabled = true
	sunlight.directional_shadow_max_distance = 25
	add_child(sunlight)
	for z in [-1.0, -3.0, -5.1]:
		var light := OmniLight3D.new()
		light.position = Vector3(0, 2.4, z)
		light.light_color = Color("ffe1b0")
		light.light_energy = 0.35
		light.omni_range = 5.0
		add_child(light)
	_build_ui()
	_set_view(0)
	print("ROOM_PREVIEW_READY meshes=", _count_meshes(room))

func _count_meshes(node: Node) -> int:
	var count := 1 if node is MeshInstance3D else 0
	for child in node.get_children():
		count += _count_meshes(child)
	return count

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var top := PanelContainer.new()
	top.position = Vector2(24, 24)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.15, 0.15, 0.93)
	style.set_corner_radius_all(12)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	top.add_theme_stylebox_override("panel", style)
	var theme := Theme.new()
	theme.default_font = UI_FONT
	theme.default_font_size = 18
	top.theme = theme
	layer.add_child(top)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	top.add_child(column)
	var title := Label.new()
	title.text = "我们的家 · 客厅"
	title.add_theme_font_size_override("font_size", 26)
	column.add_child(title)
	view_label = Label.new()
	view_label.add_theme_color_override("font_color", Color("c3c9bd"))
	column.add_child(view_label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	column.add_child(row)
	for i in range(4):
		var button := Button.new()
		button.text = str(i + 1) + " " + VIEW_NAMES[i]
		button.custom_minimum_size = Vector2(82, 40)
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_set_view.bind(i))
		row.add_child(button)
		buttons.append(button)
	var help := Label.new()
	help.text = "拖动旋转 · 滚轮缩放 · 按 1—4 切换视角"
	help.add_theme_font_size_override("font_size", 15)
	help.add_theme_color_override("font_color", Color("d4c9b4"))
	column.add_child(help)

func _set_view(index: int) -> void:
	current_view = index
	dragging = false
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL if index == 3 else Camera3D.PROJECTION_PERSPECTIVE
	camera.size = 8.0
	var positions := [Vector3(0,1.82,0.6), Vector3(1.45,1.7,-3.3),
		Vector3(-1.45,1.65,-3.0), Vector3(0,8.6,6.0)]
	var targets := [Vector3(0,1.2,-3.4), Vector3(-1.55,1,-3.2),
		Vector3(1.8,1.1,-3.0), Vector3(0,0.6,-2.9)]
	target = targets[index]
	var offset: Vector3 = positions[index] - target
	radius = offset.length()
	yaw = atan2(offset.x, offset.z)
	pitch = asin(offset.y / radius)
	_set_ceiling_visible(room, index != 3)
	for i in range(buttons.size()):
		buttons[i].set_pressed_no_signal(i == index)
	view_label.text = "基础场景 · 按照片估算 · " + VIEW_NAMES[index]
	_update_camera()
	print("ROOM_VIEW ", index + 1)

func _set_ceiling_visible(node: Node, value: bool) -> void:
	# Godot imports glTF custom properties inside the extras metadata dictionary.
	var extras: Dictionary = node.get_meta("extras", {})
	if node is Node3D and extras.get("category", "") == "Ceiling":
		node.visible = value
	for child in node.get_children():
		_set_ceiling_visible(child, value)

func _update_camera() -> void:
	camera.position = target + Vector3(sin(yaw)*cos(pitch), sin(pitch), cos(yaw)*cos(pitch))*radius
	camera.look_at(target)

func _input(event: InputEvent) -> void:
	# Release outside the canvas/UI must also stop an existing drag.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		dragging = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_4:
			_set_view(event.keycode - KEY_1)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			var zoom := 0.9 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.1
			if camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
				camera.size = clampf(camera.size * zoom, 2.0, 14.0)
			else:
				radius = clampf(radius * zoom, 0.6, 16)
			_update_camera()
	if event is InputEventMouseMotion and dragging:
		yaw -= event.relative.x * 0.005
		pitch = clampf(pitch + event.relative.y * 0.005, -0.25, 1.45)
		_update_camera()
