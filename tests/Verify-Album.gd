extends SceneTree
var failures:Array[String]=[]
func check(ok:bool,message:String)->void:
	if not ok:failures.append(message);push_error(message)
func key(scene:Node,code:int)->void:
	var event:=InputEventKey.new();event.physical_keycode=code;event.pressed=true;scene._input(event)
	event.pressed=false;scene._input(event)
func verify()->void:
	var scene:Node3D=load("res://playroom.tscn").instantiate();root.add_child(scene);await process_frame;await physics_frame
	var album=scene.album_ui
	check(root.get_visible_rect().encloses(album.book.get_global_rect()),"book fits viewport")
	check(album.data.pages.size()==13,"13 units")
	for sample in [[1,true,false,31.0],[3,true,true,57.0],[4,false,true,83.0]]:
		album.timeline.current=sample[0]
		check(album.timeline.track_active(0)==sample[1] and album.timeline.track_active(1)==sample[2],"track ownership "+str(sample[0]))
		check(album.timeline.overview_node_y(album.data.pages[sample[0]])==sample[3],"node ownership "+str(sample[0]))
	album.timeline.current=0
	var total:=0;var nonempty:=0
	for q in album.data.quarters:total+=int(q.count);nonempty+=1 if int(q.count)>0 else 0
	check(total==778 and nonempty==39 and album.data.quarters.size()==40,"quarter contract")
	check(float(scene.album_placement.position[1])<.75,"album rests on cabinet surface, not cactus bounds")
	for point in [Vector3(1.82,.01,-2.97),Vector3(1.82,.01,-2.55),Vector3(1.82,.01,-3.38)]:
		var collider:CollisionShape3D=scene.player.get_child(0);var query:=PhysicsShapeQueryParameters3D.new();query.shape=collider.shape;query.transform.origin=point+collider.position;query.collision_mask=scene.player.collision_mask
		check(scene.get_world_3d().direct_space_state.intersect_shape(query).is_empty(),"legal cabinet approach "+str(point))
		scene.player.position=point;check(scene._nearest_interaction()=="album","cabinet approach finds album")
	scene.capture_requested=true;scene._pointer_lock_changed(true);scene.awaiting_movement_release=false
	# Engine fixture only: this is not evidence of actual browser pointer capture.
	key(scene,KEY_F);check(scene.mode=="ALBUM" and album.root.visible and not scene.pointer_locked,"F opens album")
	var position:Vector3=scene.player.position;var yaw:float=scene.target_camera_yaw
	for i in 13:
		album.open_page(i,false);await process_frame
		check(album.page_index==i and album.page_area.get_child_count()==2,"render unit "+str(i))
		for item in album.page_area.find_children("*","TextureRect",true,false):check(item.texture!=null,"image loaded")
	album.open_page(5,false);key(scene,KEY_RIGHT);album.timeline.motion.pause();album.timeline.motion.custom_step(.35)
	check(album.timeline.zoom>0 and album.timeline.zoom<1,"2026 intermediate zoom")
	key(scene,KEY_LEFT);album.timeline.motion.pause();album.timeline.motion.custom_step(1)
	check(album.page_index==5 and is_zero_approx(album.timeline.zoom),"reverse cancels previous animation")
	album.open_page(12,false);key(scene,KEY_RIGHT);check(album.page_index==12,"last page bounded")
	album.open_page(0,false);key(scene,KEY_LEFT);check(album.page_index==0,"first page bounded")
	album.open_page(8,false);key(scene,KEY_B);key(scene,KEY_F)
	var motion:=InputEventMouseMotion.new();motion.screen_relative=Vector2(120,0);scene._input(motion)
	check(scene.mode=="ALBUM" and scene.player.position==position and scene.target_camera_yaw==yaw,"input isolation")
	key(scene,KEY_ESCAPE);check(scene.mode=="EXPLORE" and not album.root.visible,"exit")
	scene.capture_requested=true;scene._pointer_lock_changed(true);scene.awaiting_movement_release=false;key(scene,KEY_F)
	check(album.page_index==8 and album.root.visible,"session reading memory")
	scene._notification(NOTIFICATION_APPLICATION_FOCUS_OUT);key(scene,KEY_ESCAPE)
	check(scene.mode=="EXPLORE" and not scene.pointer_locked and not scene.capture_requested,"unfocused exit does not recapture")
	for id in ["sofa_middle","window_seat","entry_stool"]:
		scene.player.position=scene.vec(scene.seats[id].approach);check(scene._nearest_interaction()==id,"neighbor seat "+id)
	scene.player.position=Vector3(-.15,.01,-2.65);check(scene._nearest_interaction()=="phone_2048","phone remains reachable")
	var fresh=load("res://album_ui.gd").new();root.add_child(fresh);check(fresh.page_index==0,"new session resets")
	fresh.queue_free();scene.queue_free();await process_frame
	print("ALBUM_VERIFY ",JSON.stringify({"failures":failures,"evidence":"engine only; browser path checked separately"}));quit(0 if failures.is_empty() else 1)
func _initialize()->void:call_deferred("verify")
