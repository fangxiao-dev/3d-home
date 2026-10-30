extends SceneTree
var failures:Array[String]=[]
func check(ok:bool,message:String)->void:
	if not ok:failures.append(message);push_error(message)
func key(scene:Node,code:int)->void:
	var e:=InputEventKey.new();e.physical_keycode=code;e.pressed=true;scene._input(e);e.pressed=false;scene._input(e)
func capture(scene:Node)->void:
	scene.capture_requested=true;scene._pointer_lock_changed(true);scene.awaiting_movement_release=false
func verify()->void:
	var State=load("res://food_collection_state.gd")
	var state=State.new();state.save_path="user://closeup-test.json";state.persistent=true;state.reset()
	check(state.discover("pocky") and not state.discover("pocky"),"first discovery and idempotence")
	var restored=State.new();restored.save_path=state.save_path;restored.start()
	check(restored.found.keys()==["pocky"],"save reload stable id")
	restored.preview_complete();restored.discover("iced-cola")
	var after=State.new();after.save_path=state.save_path;after.start();check(after.found.keys()==["pocky"],"preview isolated")
	check(after.reset(),"reset writes");state.save_path="user://missing-folder/cannot-save.json";check(not state.reset() and not state.save_error.is_empty(),"failed reset keeps found and reports failure")
	var scene=load("res://playroom.tscn").instantiate();root.add_child(scene);await process_frame;await physics_frame
	scene.food_state.persistent=false;scene.food_state.found.clear();scene.food_ui.sheet.set_found(scene.food_state.found)
	check(not scene.food_collection_preview_complete,"normal preview off")
	var ids:Array=[]
	for region in scene.closeup.regions:
		for item in region.items:
			if item.id not in ["phone","cake"]:ids.append(item.id)
		capture(scene);scene._open_closeup(region.id)
		var reached:Dictionary={0:true};var pending:Array=[0]
		while not pending.is_empty():
			var current:int=pending.pop_front()
			for direction in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
				scene.closeup.selected=current;scene.closeup.move_focus(direction)
				if not reached.has(scene.closeup.selected):reached[scene.closeup.selected]=true;pending.append(scene.closeup.selected)
		check(reached.size()==region.items.filter(func(item):return item.id!="cake").size(),"all selectable objects direction reachable "+region.id)
		check(scene.food_state.found.is_empty(),"focus never discovers")
		key(scene,KEY_ESCAPE)
	var unique:Dictionary={}
	for id in ids:unique[id]=true
	check(ids.size()==18 and unique.size()==18,"18 unique ids")
	for id in ids:check(scene.food_state.valid_id(id),"valid "+id)
	scene.player.position=Vector3(-.15,.01,-2.65);capture(scene)
	check(scene._nearest_interaction()=="closeup_coffee","natural coffee target")
	key(scene,KEY_F);check(scene.mode=="CLOSEUP","F opens closeup")
	scene.closeup.selected=0;scene.closeup.refresh();key(scene,KEY_F)
	check(scene.mode=="FOOD_DETAIL" and scene.food_state.found.size()==1,"F detail discovers")
	key(scene,KEY_G);check(scene.mode=="FOOD_DETAIL","G does not penetrate detail")
	scene._process(6.0)
	check(scene.notice_time>0,"first collection feedback survives six seconds reading")
	key(scene,KEY_ESCAPE);check(scene.mode=="CLOSEUP" and scene.closeup.selected==0,"detail returns focus")
	check(scene.closeup.status.text=="已开启美食图鉴 · G 查看","first collection feedback visible after long read")
	key(scene,KEY_F);check(scene.food_state.found.size()==1,"repeat detail idempotent");key(scene,KEY_ESCAPE)
	scene.food_state.persistent=true;scene.food_state.save_path="user://missing-folder/cannot-save.json"
	scene.closeup.selected=1;scene.closeup.refresh();key(scene,KEY_F);scene._process(9.0)
	check(not scene.food_state.save_error.is_empty() and scene.notice_time>0,"save failure feedback survives nine seconds reading")
	key(scene,KEY_ESCAPE);check(scene.closeup.status.text==scene.food_state.save_error,"save failure visible after long read")
	scene.food_state.persistent=false;scene.food_state.save_error=""
	scene.closeup.selected=5;scene.closeup.refresh();key(scene,KEY_F);check(scene.mode=="PHONE_2048","phone action")
	key(scene,KEY_ESCAPE);check(scene.mode=="CLOSEUP" and scene.closeup.selected==5,"phone returns focus")
	key(scene,KEY_ESCAPE);check(scene.mode=="EXPLORE","outer exit")
	capture(scene);scene._open_closeup("fridge");scene._closeup_action("lava-cake")
	check(scene.birthday.cake_state=="in_fridge","lava cake independent");key(scene,KEY_ESCAPE)
	scene._closeup_action("cake");check(scene.birthday.cake_state=="carried" and scene.mode=="CLOSEUP","cake action returns")
	scene._closeup_action("cake");check(scene.birthday.cake_state=="carried","no duplicate cake")
	check(not scene.closeup.sprites[4].visible,"taken cake model disappears immediately")
	key(scene,KEY_ESCAPE);capture(scene);scene._open_closeup("fridge")
	check(not scene.closeup.sprites[4].visible and scene.closeup.cake_button.disabled,"taken cake stays absent on reentry")
	key(scene,KEY_ESCAPE);key(scene,KEY_G);check(scene.mode=="FOOD_COLLECTION","G activated")
	scene.food_ui.show_detail("bullfrog");check(scene.food_ui.detail_id=="","unfound detail blocked")
	scene.food_ui.show_detail("lava-cake");key(scene,KEY_ESCAPE);check(scene.mode=="FOOD_COLLECTION","atlas detail hierarchy");key(scene,KEY_ESCAPE)
	scene._open_food_reset();check(scene.mode=="FOOD_RESET","settings accessible");scene.reset_dialog.canceled.emit();check(scene.food_state.active(),"cancel keeps collection")
	scene._open_food_reset();scene.reset_dialog.confirmed.emit();check(not scene.food_state.active() and scene.birthday.cake_state=="carried","reset only collection")
	capture(scene);scene._open_closeup("coffee");scene._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	key(scene,KEY_F);check(scene.mode=="CLOSEUP","unfocused closeup cannot activate")
	scene._notification(NOTIFICATION_APPLICATION_FOCUS_IN);key(scene,KEY_ESCAPE)
	check(scene.mode=="EXPLORE" and not scene.pointer_locked and not scene.capture_requested,"focus return requires explicit resume")
	for id in ["sofa_middle","window_seat","entry_stool"]:
		scene.player.position=scene.vec(scene.seats[id].approach);check(scene._nearest_interaction()==id,"seat owns entry "+id)
	scene.queue_free();await process_frame
	print("FOOD_CLOSEUP_VERIFY ",JSON.stringify({"failures":failures,"evidence":"engine-only state/geometry; native capture simulated"}));quit(0 if failures.is_empty() else 1)
func _initialize()->void:call_deferred("verify")
