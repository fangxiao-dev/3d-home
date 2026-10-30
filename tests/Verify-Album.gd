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
	var timeline=album.timeline
	var content_before:=JSON.stringify(album.data)
	for sample in [[1,true,false,1],[3,true,true,2],[4,false,true,1],[2,true,true,2]]:
		timeline.current=sample[0]
		check(timeline.track_active(0)==sample[1] and timeline.track_active(1)==sample[2],"track ownership "+str(sample[0]))
		var points=timeline.event_nodes().filter(func(hit):return hit.index==sample[0])
		check(points.size()==sample[3],"historical single/double node count "+str(sample[0]))
		for hit in points:
			check(timeline.hit_at(hit.point).get("index",-1)==sample[0],"both track nodes target same unit")
			if points.size()==2:check(absf(hit.point.y-timeline.geometry().y)>15,"both nodes stay on separate rails")
	timeline.current=0
	timeline.show_page(0,false)
	check(is_equal_approx((timeline.geometry().boundary-22)/(timeline.size.x-44),.6),"history owns 60 percent")
	timeline.show_page(6,false)
	check(is_equal_approx((timeline.geometry().boundary-22)/(timeline.size.x-44),.2),"history contracts to 20 percent")
	var dock:Vector2=timeline.boat_position(timeline.geometry())
	timeline.show_page(10,false)
	check(timeline.boat_position(timeline.geometry()).is_equal_approx(dock),"2026 boat remains docked")
	for focus in [0.0,1.0]:
		timeline.zoom=focus
		var geometry:Dictionary=timeline.geometry()
		var crossing_count:=0;var last_order:=0.0
		for sample in 201:
			var x:=lerpf(geometry.end,timeline.size.x-geometry.margin,float(sample)/200)
			var first:float=timeline.strand_y(x,-1,geometry);var second:float=timeline.strand_y(x,1,geometry)
			var center:float=timeline.ribbon_y(x,geometry)
			check(maxf(absf(first-center),absf(second-center))+.525<2.7,"woven threads inside ribbon outline")
			var order:=signf(first-second)
			if last_order!=0 and order!=0 and order!=last_order:crossing_count+=1
			if order!=0:last_order=order
		check(crossing_count>=4,"threads alternate upper/lower at both scales")
	timeline.zoom=1.0
	var annual_sum:=0
	for year in timeline.yearly:annual_sum+=int(year.count)
	check(annual_sum==778 and timeline.yearly.size()==10,"annual rendering aggregates original quarters")
	check(timeline.steps.size()==7,"seven confirmed paired footsteps")
	for hit in timeline.decoration_hits():
		if hit.kind=="star":check(absf(hit.point.y-timeline.geometry().y)<15,"chat stars stay inside river")
	timeline.show_page(5,false);timeline.show_page(6)
	check(timeline.signal_from=="" and timeline.signal_target=="dayone","history starts signal from dock")
	timeline.motion.pause();timeline.motion.custom_step(.5)
	for hit in timeline.event_nodes():check(timeline.hit_at(hit.point).get("index",-1)==hit.index,"animated hit matches visible geometry")
	timeline.show_page(8);check(timeline.signal_from=="dayone" and timeline.signal_target=="skies","signal starts from previous selected 2026 node")
	timeline.show_page(10);check(timeline.signal_from=="skies" and timeline.signal_target=="proposal","rapid selection uses previous target, not dock")
	timeline.motion.pause();timeline.motion.custom_step(.4);timeline._update_seen()
	check(timeline.signal_progress>0 and timeline.signal_progress<1,"signal midflight")
	timeline.show_page(9);check(timeline.signal_from=="proposal" and timeline.signal_target=="travel","reverse signal retains previous node")
	timeline.motion.pause();timeline.motion.custom_step(2);timeline._update_seen()
	timeline.show_page(0,false);timeline.show_page(12);timeline.motion.pause();timeline.motion.custom_step(3);timeline._update_seen()
	check(timeline.seen_steps.size()==7,"paired footsteps persist after full journey")
	for hit in timeline.decoration_hits():
		if hit.kind=="footstep":check(not timeline.hit_at(hit.point).has("index"),"footsteps never jump")
	timeline.show_page(2);check(not timeline.signal_active,"return to history cancels warm signal")
	timeline.stop();check(not timeline.motion.is_running(),"close stops motion")
	check(JSON.stringify(album.data)==content_before,"timeline never mutates content")
	timeline.show_page(0,false)
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
	key(scene,KEY_LEFT);album.timeline.motion.pause();album.timeline.motion.custom_step(2)
	check(album.page_index==5 and is_equal_approx(album.timeline.zoom,.12),"reverse cancels previous animation")
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
	scene.player.position=Vector3(-.15,.01,-2.65);check(scene._nearest_interaction()=="closeup_coffee","coffee table remains reachable")
	var fresh=load("res://album_ui.gd").new();root.add_child(fresh);check(fresh.page_index==0,"new session resets")
	fresh.queue_free();scene.queue_free();await process_frame
	print("ALBUM_VERIFY ",JSON.stringify({"failures":failures,"evidence":"engine only; browser path checked separately"}));quit(0 if failures.is_empty() else 1)
func _initialize()->void:call_deferred("verify")
