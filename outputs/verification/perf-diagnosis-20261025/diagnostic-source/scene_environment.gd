extends RefCounted
## Shared by the offline lightmap scene and runtime; no object-name heuristics.
static func create(layout: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = "House"
	var model: Node3D = load("res://assets/living-room.glb").instantiate()
	model.name = "Model"
	root.add_child(model)
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var extras: Dictionary = node.get_meta("extras", {})
		var bake_static: bool = extras.get("bake_static", false)
		var camera_occluder: bool = extras.get("camera_occluder", false)
		node.gi_mode = GeometryInstance3D.GI_MODE_DYNAMIC if camera_occluder else GeometryInstance3D.GI_MODE_STATIC if bake_static else GeometryInstance3D.GI_MODE_DISABLED
		# Keep contact shadows on solid furniture, while wall-mounted cutaways
		# and thin decorative attachments retain their shadow-free treatment.
		if not bake_static and not (camera_occluder and extras.get("collision", false) and extras.get("cutaway", "").is_empty()):
			node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var world := WorldEnvironment.new()
	world.name = "WarmEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("d9d3bf")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("fffaf2")
	env.ambient_light_energy = 0.26
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = env
	root.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.name = "WarmSun"
	sun.rotation_degrees = Vector3(-55, -28, 0)
	sun.light_color = Color("fff8ee")
	sun.light_energy = 0.22
	sun.light_bake_mode = Light3D.BAKE_DYNAMIC
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 30
	sun.shadow_blur = 2.0
	sun.shadow_opacity = 0.65
	root.add_child(sun)
	for id in layout:
		var bounds: Array = layout[id]
		var fill := OmniLight3D.new()
		fill.name = "Fill_" + id
		fill.position = Vector3((bounds[0] + bounds[1]) / 2, 2.5, -(bounds[2] + bounds[3]) / 2)
		fill.light_color = Color("fff8ee")
		fill.light_energy = 0.12
		fill.omni_range = 5
		fill.omni_attenuation = 0.7
		fill.light_bake_mode = Light3D.BAKE_STATIC
		fill.shadow_enabled = true
		root.add_child(fill)
	return root


