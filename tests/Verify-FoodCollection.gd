extends SceneTree
var failures:Array[String]=[]
func check(ok:bool,message:String)->void:
	if not ok:failures.append(message);push_error(message)
func key(scene:Node,code:int)->void:
	var event:=InputEventKey.new();event.physical_keycode=code;event.pressed=true;scene._input(event);event.pressed=false;scene._input(event)
func verify()->void:
	var state=load("res://food_collection_state.gd").new()
	check(state.catalog.size()==18 and not state.active(),"18 entries and zero discoveries inactive")
	for item in state.catalog:
		state.found.clear();check(state.discover(item.id) and state.active(),"any stable id activates")
		check(not state.discover(item.id) and state.found.size()==1,"repeat id idempotent")
		check(not state.discover(item.image),"image filename is not a discovery id")
	var scene=load("res://playroom.tscn").instantiate();scene.food_collection_preview_complete=true;root.add_child(scene);await process_frame;await process_frame
	var ui=scene.food_ui
	check(scene.food_state.found.size()==18 and scene.food_button.visible,"preview 18/icon")
	key(scene,KEY_G);await process_frame
	check(scene.mode=="FOOD_COLLECTION" and ui.root.visible,"G opens")
	check(root.get_visible_rect().encloses(ui.book.get_global_rect()),"one-screen board fits viewport")
	check(ui.sheet.buttons.size()==18 and ui.find_children("*","ScrollContainer",true,false).is_empty(),"18 buttons no scroll")
	check(is_equal_approx(ui.book.size.x/ui.book.size.y,1000.0/620),"layout aspect preserved")
	for placement in ui.layout:
		check(ui.sheet.items.has(placement.id) and ui.sheet.textures.get(placement.id)!=null,"id join and texture")
		check(Rect2(Vector2.ZERO,Vector2(1000,620)).encloses(ui.sheet.buttons[placement.id].get_rect()),"every sticker hit region inside board")
	check(ui.sheet.active_label()=="","initial only stickers")
	key(scene,KEY_TAB);check(ui.sheet.selected_id=="pad-krapao" and ui.sheet.active_label()=="pad-krapao","keyboard name focus")
	key(scene,KEY_ENTER);check(ui.detail.visible and ui.detail_id=="pad-krapao" and ui.blur.visible,"Enter opens detail and actual blur")
	check(ui.draft_label.visible and ui.draft_note.visible,"draft marker true")
	var pos:Vector3=scene.player.position;var zoom:float=scene.target_zoom
	key(scene,KEY_W);key(scene,KEY_B);key(scene,KEY_F)
	var wheel:=InputEventMouseButton.new();wheel.button_index=MOUSE_BUTTON_WHEEL_DOWN;wheel.pressed=true;scene._input(wheel);await physics_frame
	check(scene.mode=="FOOD_COLLECTION" and scene.player.position.distance_to(pos)<.001 and scene.target_zoom==zoom,"detail input isolated")
	key(scene,KEY_ESCAPE);check(ui.detail_id=="" and scene.mode=="FOOD_COLLECTION" and ui.sheet.buttons["pad-krapao"].has_focus(),"first Esc restores sticker focus")
	var rect:Rect2=ui.sheet.buttons["pad-krapao"].get_rect()
	var item:Dictionary=ui.sheet.items["pad-krapao"]
	var old_name:String=item.name;item.name="测试改名";item.description="测试介绍";item.draft=false
	ui.sheet.buttons["pad-krapao"].pressed.emit()
	check(ui.detail_title.text=="测试改名" and ui.description.text=="测试介绍" and not ui.draft_label.visible and not ui.draft_note.visible,"content name/description/draft false")
	check(ui.sheet.buttons["pad-krapao"].get_rect()==rect,"rename leaves placement unchanged")
	ui.backdrop.pressed.emit();check(ui.detail_id=="" and ui.sheet.selected_id=="pad-krapao","backdrop returns selection")
	item.name=old_name
	ui.show_detail("pocky");ui.detail_close.pressed.emit();check(ui.detail_id=="" and ui.sheet.buttons["pocky"].has_focus(),"detail close restores selection")
	key(scene,KEY_ESCAPE);check(scene.mode=="EXPLORE" and not ui.root.visible,"second Esc closes board")
	key(scene,KEY_G);check(ui.sheet.selected_id=="pocky" and ui.detail_id=="","reopen board selection retained, detail closed")
	ui.close_button.pressed.emit();check(scene.mode=="EXPLORE","board close button")
	scene.mode="SEATED";scene.seat_id="entry_stool";scene.camera_seated=true;scene.interaction_restore_allowed=true
	key(scene,KEY_G);check(scene.mode=="FOOD_COLLECTION","seated opens")
	ui.show_detail("iced-cola");key(scene,KEY_ESCAPE);check(scene.mode=="FOOD_COLLECTION","detail Esc does not stand")
	key(scene,KEY_ESCAPE);check(scene.mode=="SEATED" and scene.interaction_restore_allowed,"seated restored")
	scene.mode="EXPLORE";scene.camera_blend_elapsed=.45;scene.capture_requested=true;scene._pointer_lock_changed(true)
	key(scene,KEY_G);check(not scene.pointer_locked,"open releases capture")
	scene._notification(NOTIFICATION_APPLICATION_FOCUS_OUT);key(scene,KEY_ESCAPE)
	check(not scene.capture_requested and not scene.pointer_locked,"unfocused exit does not capture")
	scene.app_focused=true;scene.camera_blend_elapsed=.45;key(scene,KEY_B);check(scene.mode=="INVENTORY","backpack neighbor")
	key(scene,KEY_G);check(scene.mode=="INVENTORY","mutual exclusion")
	scene.queue_free();await process_frame
	print("FOOD_COLLECTION_V2_VERIFY ",JSON.stringify({"failures":failures,"evidence":"engine-only; 18 ids, one screen, two-level detail"}));quit(0 if failures.is_empty() else 1)
func _initialize()->void:call_deferred("verify")
