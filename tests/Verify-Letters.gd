extends SceneTree
var failures: Array[String] = []

func check(ok: bool, message := "Stage 1 assertion failed") -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func key(scene: Node, code: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode=code;event.pressed=true;scene._input(event)
	event.pressed=false;scene._input(event)

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	var scene=load("res://playroom.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var ui=scene.letters_ui
	check(ui.articles.size()==15)
	var page_total:=0
	var image_total:=0
	for i in ui.articles.size():
		var article=ui.articles[i]
		var joined:=""
		var original:=""
		for block in article.blocks:
			if block.type=="text":original+=block.text
		for page in ui.pages[article.id]:
			page_total+=1
			if page.type=="text":joined+=page.text
			else:image_total+=1;check(ResourceLoader.exists(page.path))
		check(joined.replace("\n","")==original.replace("\n",""),"Pagination lost original text: "+article.id)
		for p in range(0,ui.pages[article.id].size(),2):
			ui.open_article(i,p)
			await process_frame
			for column in [ui.left,ui.right]:
				for child in column.get_children():
					if child is Label:
						check(child.get_minimum_size().y<=370,"Page overflow: "+article.id+" "+str(p)+" "+str(child.get_minimum_size()))
	check(image_total==7)
	ui.crown_available=false;ui.crown_owned=false;ui.crown_worn=false
	# First discovery may be a backwards page turn from the following article.
	for i in ui.articles.size():
		if ui.articles[i].id==ui.catalog.crown_article_id:
			ui.open_article(i+1)
			ui.turn(-1)
			check(ui.crown_available and ui.claim.visible,"Backwards entry did not unlock crown")
			ui.claim_crown()
			check(ui.crown_owned and ui.crown_worn,"Backwards-entry claim did not equip crown")
			break
	ui.crown_available=false;ui.crown_owned=false;ui.crown_worn=false
	ui.claim_crown();check(not ui.crown_owned)
	ui.open_crown_article();check(ui.crown_available and not ui.crown_owned)
	ui.show_index();ui.open_crown_article();ui.claim_crown();check(ui.crown_owned and ui.crown_worn)
	ui.toggle_crown();check(ui.crown_owned and not ui.crown_worn)
	ui.open_crown_article();ui.claim_crown();check(not ui.crown_worn,"Repeated grant must not equip again")
	ui.toggle_crown();check(ui.crown_worn)
	ui.turn(1);var remembered=ui.page_index;ui.hide_all();ui.show_reader();check(ui.page_index==remembered)
	# Simulated engine input boundary; not evidence of browser pointer permission.
	scene.player.position=scene.vec(scene.prop_data.approach)
	scene.capture_requested=true;scene._pointer_lock_changed(true)
	scene.awaiting_movement_release=false
	check(scene._nearest_interaction()=="letters","Book affordance not selected")
	key(scene,KEY_F);check(scene.mode=="READING","F did not open reading")
	var position_before:Vector3=scene.player.position
	var yaw_before:float=scene.target_camera_yaw
	var motion:=InputEventMouseMotion.new();motion.screen_relative=Vector2(80,0);scene._input(motion)
	Input.action_press("walk_right")
	for tick in 6:await physics_frame
	Input.action_release("walk_right")
	check(scene.player.position.is_equal_approx(position_before),"Reading moved player")
	check(is_equal_approx(scene.target_camera_yaw,yaw_before),"Reading rotated camera")
	key(scene,KEY_ESCAPE);check(scene.mode=="EXPLORE","Esc did not close reading")
	for tick in 35:await physics_frame
	key(scene,KEY_B);check(scene.mode=="INVENTORY","B did not open inventory")
	key(scene,KEY_ENTER);check(not ui.crown_worn and not scene.worn_crown.visible,"Inventory state not synchronized")
	key(scene,KEY_ENTER);check(ui.crown_worn and scene.worn_crown.visible,"Rewear not synchronized")
	key(scene,KEY_ESCAPE);check(scene.mode=="EXPLORE","Esc did not close inventory")
	scene.player.position=scene.vec(scene.seats.study_chair.approach)
	check(scene._nearest_interaction()=="study_chair","Book steals chair affordance")
	for article in ui.articles:
		for block in article.blocks:
			if block.type!="text":continue
			for character in block.text:
				var code:int=character.unicode_at(0)
				if code in [9,10,13,65039]:continue
				check(ui.FONT.has_char(code),"Missing glyph U+%04X" % code)
	print("LETTERS_VERIFY_", "OK" if failures.is_empty() else "FAIL", " articles=15 images=7 pages=",page_total," failures=",failures)
	quit(0 if failures.is_empty() else 1)
