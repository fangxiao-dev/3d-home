extends SceneTree
var failures:Array[String]=[]
func check(ok:bool,message:String)->void:
	if not ok:failures.append(message);push_error(message)
func run()->void:
	var scene=load("res://playroom.tscn").instantiate();root.add_child(scene);await process_frame;await physics_frame
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/food-world/placement.json"))
	check(data.props.size()==6,"exactly six outer world props")
	var regions:Dictionary={};var bounds:Dictionary={}
	for item in data.props:
		regions[item.region]=int(regions.get(item.region,0))+1
		var prop:Node3D=scene.get_node("FoodProp_"+str(item.id));var combined:=AABB();var first:=true
		for mesh in prop.find_children("*","MeshInstance3D",true,false):
			var box:AABB=mesh.global_transform*mesh.get_aabb()
			combined=box if first else combined.merge(box);first=false
		check(not first and combined.size.x>.05 and combined.size.y>.05 and combined.size.z>.05,"volumetric mesh "+item.id)
		check(absf(combined.position.y-float(item.support_height))<.006,"base contacts measured surface "+item.id)
		var point:Vector3=prop.position
		var query:=PhysicsRayQueryParameters3D.create(Vector3(point.x,1.32,point.z),Vector3(point.x,0,point.z),1)
		var hit:Dictionary=scene.get_world_3d().direct_space_state.intersect_ray(query)
		check(not hit.is_empty() and absf(hit.position.y-float(item.support_height))<.007,"placement matches actual collision surface "+item.id)
		bounds[item.id]=combined
	check(regions=={"coffee":2,"kitchen":2,"cabinet":2},"two per approved region")
	check(not bounds["mcspicy-burger"].intersects(bounds["coconut-latte"]),"coffee props do not overlap")
	check(not bounds["hot-dry-noodles"].intersects(bounds["pad-krapao"]),"kitchen dishes do not overlap")
	var phone:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/phone/placement.json"))
	var phone_rect:=Rect2(Vector2(phone.position[0]-.065,phone.position[2]-.115),Vector2(.13,.23))
	for id in ["mcspicy-burger","coconut-latte"]:
		var box:AABB=bounds[id];check(not phone_rect.intersects(Rect2(Vector2(box.position.x,box.position.z),Vector2(box.size.x,box.size.z))),"phone space retained "+id)
	check(absf(float(phone.position[1])-.533)<.002,"phone rests on actual tabletop, not tissue bounding box")
	scene.queue_free();await process_frame
	print("FOOD_WORLD_PROPS_VERIFY ",JSON.stringify({"failures":failures,"evidence":"engine geometry/contact; readability requires browser"}));quit(0 if failures.is_empty() else 1)
func _initialize()->void:call_deferred("run")

