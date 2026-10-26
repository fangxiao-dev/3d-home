extends SceneTree
func _initialize() -> void:
	call_deferred("prepare")
func prepare() -> void:
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/house-layout.json"))
	var house: Node3D = load("res://scene_environment.gd").create(layout)
	root.add_child(house)
	var lightmap := LightmapGI.new()
	lightmap.name = "LightmapGI"
	lightmap.quality = LightmapGI.BAKE_QUALITY_MEDIUM
	lightmap.bounces = 3
	lightmap.directional = false
	lightmap.shadowmask_mode = LightmapGIData.SHADOWMASK_MODE_OVERLAY
	lightmap.generate_probes_subdiv = LightmapGI.GENERATE_PROBES_SUBDIV_8
	lightmap.environment_mode = LightmapGI.ENVIRONMENT_MODE_CUSTOM_COLOR
	lightmap.environment_custom_color = Color("fffaf2")
	lightmap.environment_custom_energy = 0.27
	lightmap.light_data = LightmapGIData.new()
	ResourceSaver.save(lightmap.light_data, "res://baked/house.lmbake")
	lightmap.light_data.take_over_path("res://baked/house.lmbake")
	house.add_child(lightmap)
	for child in house.find_children("*", "", true, false):
		child.scene_file_path = ""
		child.owner = house
	var packed := PackedScene.new()
	packed.pack(house)
	var result := ResourceSaver.save(packed, "res://baked/house.scn")
	print("BAKE_SCENE_PREPARED ", result)
	quit(result)






