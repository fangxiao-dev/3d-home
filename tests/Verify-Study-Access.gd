extends SceneTree
var failures: Array[String]=[]

func _initialize() -> void:call_deferred("verify")

func check(ok: bool, message: String) -> void:
	if not ok:failures.append(message);push_error(message)

func key(scene: Node, code: int) -> void:
	var event:=InputEventKey.new();event.physical_keycode=code;event.pressed=true;scene._input(event)
	event.pressed=false;scene._input(event)

func frames(count: int) -> void:
	for i in count:await physics_frame

func verify() -> void:
	# Engine collision/input regression. Positions model legal desk-side approaches;
	# these are not claimed as observations of the user's exact browser coordinates.
	var cases={"book_gap":[Vector3(8.255,.01,4.55),"letters"],"book_south_edge":[Vector3(8.255,.01,4.95),"letters"],"chair_entry":[Vector3(8.16,.01,4.0),"study_chair"],"chair_west":[Vector3(7.15,.01,4.7),"study_chair"],"chair_south":[Vector3(7.78,.01,5.6),"study_chair"],"chair_close_back":[Vector3(7.60,.01,5.26),"study_chair"]}
	for label in cases:
		var scene=load("res://playroom.tscn").instantiate();root.add_child(scene);await frames(3)
		scene.player.position=cases[label][0]
		var collider:CollisionShape3D=scene.player.get_child(0)
		var query:=PhysicsShapeQueryParameters3D.new();query.shape=collider.shape
		query.transform=Transform3D(Basis.IDENTITY,scene.player.position+collider.position);query.collision_mask=1
		check(scene.get_world_3d().direct_space_state.intersect_shape(query).is_empty(),label+" fixture overlaps furniture")
		scene.capture_requested=true;scene._pointer_lock_changed(true);scene.awaiting_movement_release=false
		var target:String=scene._nearest_interaction()
		check(target==cases[label][1],label+" expected "+cases[label][1]+" got "+target)
		if target!=cases[label][1]:scene.queue_free();await process_frame;continue
		key(scene,KEY_F)
		var expected:String="READING" if target=="letters" else "SEATED"
		for tick in 500:
			await physics_frame
			if scene.mode==expected:break
		check(scene.mode==expected,label+" F ended in "+scene.mode+" "+scene.notice)
		key(scene,KEY_ESCAPE)
		for tick in 500:
			await physics_frame
			if scene.mode=="EXPLORE":break
		await frames(35)
		check(scene.mode=="EXPLORE",label+" could not return to exploration")
		# Simulate the native grant boundary only; browser permission is separate.
		scene.capture_requested=true;scene._pointer_lock_changed(true);await frames(2)
		key(scene,KEY_B);check(scene.mode=="INVENTORY",label+" B failed")
		key(scene,KEY_B);await frames(35)
		scene.capture_requested=true;scene._pointer_lock_changed(true);await frames(2)
		check(scene.mode=="EXPLORE" and scene.navigation_active,label+" B exit did not restore engine navigation")
		scene.queue_free();await process_frame
	print("STUDY_ACCESS_VERIFY ",JSON.stringify({"failures":failures,"cases":cases.keys()}))
	quit(0 if failures.is_empty() else 1)
