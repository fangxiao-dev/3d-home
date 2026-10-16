extends SceneTree
var failures: Array[String] = []
var scene: Node3D

func _initialize() -> void:
	call_deferred("_verify")

func _move(actions: Array, frames: int) -> void:
	for action in actions:
		Input.action_press(action)
	for i in range(frames):
		await physics_frame
	for action in actions:
		Input.action_release(action)
	await physics_frame

func _place(position_: Vector3) -> void:
	scene.player.position = position_
	scene.player.velocity = Vector3.ZERO
	await physics_frame
	await physics_frame

func _press_e(echo_: bool = false) -> void:
	var key := InputEventKey.new()
	key.physical_keycode = KEY_E
	key.pressed = true
	key.echo = echo_
	scene._unhandled_key_input(key)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _verify() -> void:
	var script = load("res://playroom.gd")
	if script == null or not script.can_instantiate():
		push_error("Playroom script cannot instantiate")
		quit(1)
		return
	scene = load("res://playroom.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	_check(scene.room_meshes.size()==296,"Existing Blender room was not loaded")
	_check(scene.colliders.size()>=16,"Furniture collisions are incomplete")
	for mesh in scene.room_meshes:
		if mesh.get_meta("extras",{}).get("category","")=="Ceiling" or str(mesh.name).begins_with("Chandelier"):
			_check(mesh.visible,"Interior ceiling or chandelier missing")
	_check(scene.camera.projection==Camera3D.PROJECTION_PERSPECTIVE,"Interior depth requires perspective camera")
	_check(scene.camera.position.y<2.2,"Camera drifted back to overhead view")
	for light in scene.find_children("*","Light3D",true,false):
		_check(not light.shadow_enabled,"Room shadow maps should remain disabled")
	_check(scene.player.get_node_or_null("ContactShadow")!=null,"Character contact shadow missing")
	await _place(Vector3(0,0.02,-0.65))
	_press_e()
	_check(scene.interaction_count==0,"E triggered from far away")
	var start: Vector3 = scene.player.position
	await _move(["walk_up"],20)
	_check(scene.player.position.z<start.z-0.5,"ArrowUp did not move forward")
	var straight_distance: float = (scene.player.position-start).length()
	await _place(start)
	await _move(["walk_up","walk_right"],20)
	_check((scene.player.position-start).length()<straight_distance*1.12,"Diagonal speed is too high")
	await _place(Vector3(0.6,0.02,-2.65))
	await _move(["walk_left"],45)
	_check(scene.player.position.x>0.05 and scene.player.position.x<0.2,"Player passed through real tea table")
	await _place(Vector3(-1,0.02,-0.65))
	await _move(["walk_up"],30)
	_check(scene.player.position.z> -1.0,"Player passed through sofa return")
	await _place(Vector3(0.4,0.02,-2.8))
	await _move(["walk_right"],45)
	_check(scene.player.position.x<1.3,"Player passed through TV console")
	await _place(Vector3(0.4,0.02,-4.9))
	await _move(["walk_right"],45)
	_check(scene.player.position.x<1.3,"Player passed through dresser")
	await _place(Vector3(0,0.02,-3.56))
	await _move(["walk_left"],45)
	_check(scene.player.position.x> -0.46,"Player passed through first chair")
	await _place(Vector3(0,0.02,-4.26))
	await _move(["walk_left"],45)
	_check(scene.player.position.x> -0.46,"Player passed through second chair")
	await _place(Vector3(0,0.02,-0.4))
	await _move(["walk_down"],30)
	_check(scene.player.position.z< -0.22,"Player left through hallway boundary")
	await _place(Vector3(-1.7,0.02,-0.4))
	await _move(["walk_left"],30)
	_check(scene.player.position.x> -1.93,"Player passed through sofa wall")
	await _place(Vector3(0,0.02,-5.3))
	await _move(["walk_up"],30)
	_check(scene.player.position.z> -5.58,"Player left through balcony boundary")
	# Follow the actual connected route from the entrance, without teleporting.
	await _place(start)
	await _move(["walk_right"],16)
	await _move(["walk_up"],125)
	await _move(["walk_left"],32)
	print("LAMP_ROUTE_END ", scene.player.position)
	_check(scene.can_interact(),"Existing floor lamp unreachable along aisle")
	var shade = scene.room.find_child("Floor lampshade",true,false)
	var shared_material: Material = shade.mesh.surface_get_material(0)
	var original_color: Color = shared_material.albedo_color
	_check(shade.material_override!=shared_material,"Lamp material is not isolated")
	_press_e()
	_check(scene.lamp_on and scene.interaction_count==1,"E did not turn lamp on")
	_press_e(true)
	_check(scene.interaction_count==1,"Held E repeated interaction")
	_press_e()
	_check(not scene.lamp_on and scene.interaction_count==2,"E did not turn lamp off")
	_check(shared_material.albedo_color==original_color,"Other room materials changed with lamp")
	var block_position: Vector3 = (scene.player.position+scene.lamp_position)/2
	block_position.y = 0.6
	var blocker = scene._collision_box("TestBlocker",block_position,Vector3(0.1,1.2,1))
	await physics_frame
	await physics_frame
	_check(not scene.can_interact(),"Interaction passed through blocker")
	blocker.queue_free()
	_check(scene.camera.position.is_finite(),"Invalid camera position")
	if failures.is_empty():
		print("LIVING_PLAY_VERIFY_OK Blender_asset, movement, diagonal, furniture, boundaries, lamp_route, material_isolation, occlusion, toggle, held_key, camera")
	else:
		for failure in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)
