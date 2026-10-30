extends SceneTree
const Game=preload("res://game_2048.gd")
var failures:Array[String]=[]

func check(ok:bool,message:String)->void:
	if not ok:failures.append(message);push_error(message)

func board(values:Array)->RefCounted:
	var game=Game.new();game.cells.assign(values);game.score=0;game.moves=0;game.won=false;game.rng.seed=42;return game

func occupied(game:RefCounted)->int:
	return game.cells.filter(func(v):return v!=0).size()

func settle(phone:Node)->void:
	if phone.busy:
		phone.tile_tween.pause();phone.tile_tween.custom_step(1.0)

func verify_results()->void:
	var phone=load("res://phone_2048.gd").new();root.add_child(phone);phone.show_game()
	for sample in [[KEY_A,4],[KEY_D,7],[KEY_W,1],[KEY_S,13]]:
		phone.game=board([0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0]);phone.refresh()
		phone.handle_key(sample[0]);settle(phone)
		check(phone.game.cells[sample[1]]==2 and phone.game.moves==1,"WASD moves board "+str(sample[0]))
	phone.game=board([1024,1024,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);phone.refresh()
	phone.handle_key(KEY_A);check(not phone.result_panel.visible,"win waits for animation");settle(phone)
	check(phone.result_panel.visible and phone.result_title.text=="You win!" and phone.result_restart.text=="Start new","win overlay")
	var saved=phone.game.cells.duplicate()
	phone.handle_key(KEY_S);check(phone.result_continue.has_focus() and phone.game.cells==saved,"WASD navigates win without moving board")
	var enter:=InputEventKey.new();enter.keycode=KEY_ENTER;enter.pressed=true;root.push_input(enter,true);await process_frame
	enter=InputEventKey.new();enter.keycode=KEY_ENTER;enter.pressed=false;root.push_input(enter,true);await process_frame
	check(phone.win_acknowledged and not phone.result_panel.visible and phone.game.cells==saved,"continue keeps winning game")
	phone.handle_key(KEY_DOWN);settle(phone);check(not phone.result_panel.visible,"win appears once per game")
	phone.hide_game();phone.show_game();check(not phone.result_panel.visible,"win acknowledgement survives reentry")
	phone.game=board([2,4,2,4,4,2,4,2,2,4,2,4,4,2,4,2]);phone.game.score=1568;phone.refresh()
	check(phone.result_panel.visible and phone.result_title.text=="Game over!" and phone.result_restart.text=="Try again","game over overlay")
	check(phone.result_scores.text.contains("1568") and phone.result_scores.text.contains("6000") and phone.result_scores.text.contains("13000"),"game over shows all scores")
	phone.handle_key(KEY_LEFT);check(phone.result_restart.has_focus(),"direction focuses retry")
	phone.pause_game();check(not phone.result_panel.visible and phone.continue_button.visible,"pause hides result actions")
	phone.resume_game();check(phone.result_panel.visible and phone.result_restart.has_focus(),"resume restores result action")
	for i in 3:await process_frame
	# Actual GUI mouse dispatch verifies the overlay does not intercept its button.
	var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.position=phone.result_restart.get_global_rect().get_center();click.pressed=true
	root.push_input(click,true);await process_frame
	click=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.position=phone.result_restart.get_global_rect().get_center();click.pressed=false
	root.push_input(click,true);await process_frame
	check(phone.game.score==0 and occupied(phone.game)==2 and not phone.result_panel.visible and not phone.confirmation.visible,"mouse retry directly starts new game")
	for threshold in [6000,13000]:
		phone.game=board([2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);phone.game.score=threshold-4;phone.refresh()
		phone.handle_key(KEY_A);settle(phone);check(phone.record_message.is_empty(),"equal threshold does not celebrate")
		phone.game.cells.assign([2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);phone.handle_key(KEY_A)
		phone.handle_key(KEY_D);check(not phone.record_message.is_empty(),"busy input preserves record message")
		settle(phone);check(phone.status_label.text==("哇，超过老公的记录啦" if threshold==6000 else "哇，超过老婆的记录啦"),"crossing celebrates correct record")
		phone.hide_game();phone.show_game();check(not phone.record_message.is_empty(),"record message survives reentry")
		phone.game.cells.assign([2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);phone.handle_key(KEY_A)
		check(phone.record_message.is_empty() and not phone.busy,"invalid next move clears record message")
		phone.game.cells.assign([2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);phone.handle_key(KEY_A);settle(phone)
		check(phone.record_message.is_empty(),"record does not repeat above threshold")
	phone.game=board([4096,4096,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);phone.game.score=5996;phone.refresh();phone.handle_key(KEY_A);settle(phone)
	check(phone.record_message.split("\n").size()==2,"single move celebrates both records")
	phone.handle_key(KEY_DOWN);phone.handle_key(KEY_UP);check(phone.result_restart.has_focus(),"arrows navigate win actions")
	enter=InputEventKey.new();enter.keycode=KEY_ENTER;enter.pressed=true;root.push_input(enter,true);await process_frame
	enter=InputEventKey.new();enter.keycode=KEY_ENTER;enter.pressed=false;root.push_input(enter,true);await process_frame
	check(phone.game.score==0 and not phone.win_acknowledged and phone.record_message.is_empty(),"new game resets win and record state")
	phone.game=board([1024,1024,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);phone.refresh();phone.handle_key(KEY_A)
	phone.request_restart()
	check(phone.confirmation.visible and not phone.result_panel.visible and phone.cancel_button.has_focus(),"restart during win animation shows only confirmation")
	phone.handle_key(KEY_ESCAPE)
	check(not phone.confirmation.visible and phone.result_panel.visible and phone.result_restart.has_focus(),"cancel interrupted restart restores win action focus")
	phone.queue_free();await process_frame

func key(scene:Node,code:int,echo:=false)->void:
	var event:=InputEventKey.new();event.physical_keycode=code;event.pressed=true;event.echo=echo;scene._input(event)
	event.pressed=false;event.echo=false;scene._input(event)

func verify_animation()->void:
	var phone=load("res://phone_2048.gd").new();root.add_child(phone);phone.show_game()
	phone.game=board([0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0]);phone.refresh()
	for i in 3:await process_frame
	var start:Vector2=phone.tiles[3].global_position;var end:Vector2=phone.tiles[0].global_position
	phone.handle_key(KEY_LEFT);phone.tile_tween.pause();phone.tile_tween.custom_step(.06)
	check(phone.panel.modulate.is_equal_approx(Color.WHITE),"animation must not flash the entire panel")
	var between:=false
	for label in phone.panel.find_children("*","Label",true,false):
		if label.text=="2" and label.is_visible_in_tree() and label.modulate.a>0 and label.self_modulate.a>0:
			var point:Vector2=label.global_position
			if point.x>end.x+1 and point.x<start.x-1 and absf(point.y-start.y)<1:between=true
	check(between,"effective move has a visible tile between source and destination")
	check(phone.tiles[0].text=="","destination not revealed before arrival")
	phone.handle_key(KEY_DOWN);check(phone.game.moves==1,"animated move does not queue another key")
	phone.tile_tween.custom_step(1.0)
	check(not phone.busy and phone.moving_layer.get_child_count()==0 and phone.tiles[0].text=="2","slide settles to destination")
	for sample in [[KEY_RIGHT,7],[KEY_UP,1],[KEY_DOWN,13]]:
		phone.game=board([0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0]);phone.refresh()
		start=phone.tiles[5].global_position;end=phone.tiles[sample[1]].global_position
		phone.handle_key(sample[0]);phone.tile_tween.pause();phone.tile_tween.custom_step(.06)
		var point:Vector2=phone.moving_layer.get_child(0).global_position
		var progress:float=(point-start).dot(end-start)/(end-start).length_squared()
		check(progress>0 and progress<1,"directional intermediate frame "+str(sample[0]))
		phone.tile_tween.custom_step(1.0)
		check(phone.tiles[sample[1]].text=="2","directional landing "+str(sample[0]))
	phone.game=board([2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0]);phone.refresh();phone.handle_key(KEY_LEFT)
	phone.tile_tween.pause();phone.tile_tween.custom_step(.06)
	check(phone.game.slides==[Vector2i(0,0),Vector2i(1,0),Vector2i(2,1),Vector2i(3,1)] and phone.game.merged==[0,1],"merge animation follows rule destinations")
	check(phone.moving_layer.get_child_count()==4 and phone.tiles[0].text=="","merge sources remain visible until arrival")
	phone.tile_tween.custom_step(.11)
	check(phone.tiles[0].text=="4" and phone.tiles[1].text=="4" and phone.tiles[phone.game.spawned_index].scale.x<1,"merge lands before new tile finishes appearing")
	phone.tile_tween.custom_step(1.0)
	for interrupt in ["hide_game","restart","pause_game","request_restart"]:
		phone.show_game();phone.game=board([0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0]);phone.refresh();phone.handle_key(KEY_LEFT)
		phone.tile_tween.pause();phone.tile_tween.custom_step(.06);var settled=phone.game.cells.duplicate()
		phone.call(interrupt)
		check(not phone.busy and phone.moving_layer.get_child_count()==0,"interruption clears animation "+interrupt)
		if interrupt!="restart":check(phone.game.cells==settled,"interruption preserves committed move "+interrupt)
		for i in 16:check(phone.tiles[i].scale==Vector2.ONE and phone.tiles[i].text==(str(phone.game.cells[i]) if phone.game.cells[i] else ""),"interruption renders final state "+interrupt)
		phone.show_game();check(not phone.busy and not phone.paused,"reentry ready after interruption")
	phone.game=board([2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);phone.refresh();phone.handle_key(KEY_LEFT)
	check(not phone.busy and phone.moving_layer.get_child_count()==0 and phone.tiles[0].text=="2" and phone.panel.modulate==Color.WHITE,"invalid move has no motion or flash")
	phone.queue_free();await process_frame

func verify()->void:
	await verify_results()
	await verify_animation()
	for values in [[2,2,2,2],[2,2,4,0]]:
		var game=board(values+[0,0,0,0,0,0,0,0,0,0,0,0])
		game.move(Vector2i.LEFT)
		check(game.cells[0]==4 and game.cells[1]==4,"single merge order "+str(values))
		check(game.score==(8 if values[2]==2 else 4),"merge score")
		check(occupied(game)==3,"one spawn after merge")
	for direction in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
		var game=board([0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0]);var sum_before=2
		check(game.move(direction),"four direction movement")
		var destination=4 if direction==Vector2i.LEFT else 7 if direction==Vector2i.RIGHT else 1 if direction==Vector2i.UP else 13
		check(game.cells[destination]==2 and occupied(game)==2 and game.score==0,"direction destination and one spawn")
	var no_move=board([2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);var before=no_move.cells.duplicate();var rng_state=no_move.rng.state
	check(not no_move.move(Vector2i.LEFT) and no_move.cells==before and no_move.score==0 and no_move.rng.state==rng_state,"invalid move does not spawn or score")
	var win=board([1024,1024,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);win.move(Vector2i.LEFT)
	check(win.won and win.score==2048 and win.move(Vector2i.DOWN),"2048 continues")
	var over=board([2,4,2,4,4,2,4,2,2,4,2,4,4,2,4,2]);check(over.game_over(),"full blocked board ends")
	over.cells[1]=2;check(not over.game_over(),"full mergeable board continues")
	var random=Game.new();random.rng.seed=28;var twos:=0;var fours:=0
	for i in 10000:
		random.cells.fill(0);random.spawn_tile()
		check(occupied(random)==1,"exactly one random tile")
		for value in random.cells:
			if value==2:twos+=1
			elif value==4:fours+=1
	check(twos>8800 and twos<9200 and twos+fours==10000,"90/10 random distribution")
	var scene:Node3D=load("res://playroom.tscn").instantiate();root.add_child(scene);await process_frame;await physics_frame
	var phone=scene.phone_ui;check(occupied(phone.game)==2 and phone.game.score==0,"initial two tiles")
	var points=[Vector3(-.15,.01,-2.65),Vector3(-.7,.01,-3.4),Vector3(-1.62,.01,-2.65)]
	for point in points:
		var collider:CollisionShape3D=scene.player.get_child(0);var query:=PhysicsShapeQueryParameters3D.new();query.shape=collider.shape;query.transform.origin=point+collider.position;query.collision_mask=scene.player.collision_mask
		check(scene.get_world_3d().direct_space_state.intersect_shape(query).is_empty(),"legal phone approach "+str(point))
		scene.player.position=point;check(scene._nearest_interaction()=="closeup_coffee","phone target "+str(point))
	for id in ["sofa_middle","window_seat","entry_stool"]:
		scene.player.position=scene.vec(scene.seats[id].approach);check(scene._nearest_interaction()==id,"neighbor seat retained "+id)
	scene.player.position=points[0];scene.capture_requested=true;scene._pointer_lock_changed(true);scene.awaiting_movement_release=false
	# The external capture grant above is an engine fixture, not browser authorization evidence.
	key(scene,KEY_F);scene.closeup.selected=5;scene.closeup.refresh();key(scene,KEY_F);check(scene.mode=="PHONE_2048" and not scene.pointer_locked,"F opens and releases")
	var position_before:Vector3=scene.player.position;var yaw_before:float=scene.target_camera_yaw
	var birthday_before=scene.birthday.snapshot();var crown_before=[scene.letters_ui.crown_owned,scene.letters_ui.crown_worn]
	phone.game=board([2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);phone.refresh()
	key(scene,KEY_LEFT);check(phone.game.moves==1 and phone.game.score==4,"real input route")
	key(scene,KEY_DOWN);check(phone.game.moves==1,"busy input discarded")
	for i in 12:await physics_frame
	key(scene,KEY_DOWN,true);check(phone.game.moves==1,"echo ignored")
	key(scene,KEY_B);key(scene,KEY_F);Input.action_press("walk_up")
	var motion:=InputEventMouseMotion.new();motion.screen_relative=Vector2(120,0);scene._input(motion)
	for i in 12:await physics_frame
	Input.action_release("walk_up")
	check(scene.mode=="PHONE_2048" and scene.player.position.is_equal_approx(position_before) and is_equal_approx(scene.target_camera_yaw,yaw_before),"movement camera F B isolated")
	phone.request_restart();check(phone.confirmation.visible,"progress restart confirms");key(scene,KEY_ESCAPE);check(not phone.confirmation.visible and scene.mode=="PHONE_2048" and phone.game.score==4,"Esc cancels only confirmation")
	var saved=phone.game.cells.duplicate();key(scene,KEY_ESCAPE);check(scene.mode=="CLOSEUP","Esc exits phone into closeup")
	key(scene,KEY_F)
	check(phone.game.cells==saved and phone.game.score==4,"reentry preserves game")
	scene._notification(NOTIFICATION_APPLICATION_FOCUS_OUT);check(phone.paused and not scene.pointer_locked,"focus pauses")
	scene._notification(NOTIFICATION_APPLICATION_FOCUS_IN);key(scene,KEY_DOWN);check(phone.game.cells==saved and phone.continue_button.visible,"focus regain needs continue")
	phone.continue_button.emit_signal("pressed");check(not phone.paused,"explicit continue")
	phone.request_restart();phone.restart();check(phone.game.score==0 and phone.game.moves==0 and occupied(phone.game)==2,"restart clears")
	phone.game.moves=1;phone.restart_button.grab_focus()
	var enter:=InputEventKey.new();enter.keycode=KEY_ENTER;enter.pressed=true;Input.parse_input_event(enter);await process_frame
	enter=InputEventKey.new();enter.keycode=KEY_ENTER;enter.pressed=false;Input.parse_input_event(enter);await process_frame
	check(phone.confirmation.visible,"GUI Enter activates restart")
	var tab:=InputEventKey.new();tab.keycode=KEY_TAB;tab.pressed=true;Input.parse_input_event(tab);await process_frame
	check(root.gui_get_focus_owner()!=phone.cancel_button,"GUI Tab reaches confirm")
	enter=InputEventKey.new();enter.keycode=KEY_ENTER;enter.pressed=true;Input.parse_input_event(enter);await process_frame
	enter=InputEventKey.new();enter.keycode=KEY_ENTER;enter.pressed=false;Input.parse_input_event(enter);await process_frame
	check(not phone.confirmation.visible and phone.game.moves==0,"GUI Enter confirms restart")
	check(scene.birthday.snapshot()==birthday_before and [scene.letters_ui.crown_owned,scene.letters_ui.crown_worn]==crown_before,"birthday crown independent")
	key(scene,KEY_ESCAPE);key(scene,KEY_ESCAPE);key(scene,KEY_B);check(scene.mode=="INVENTORY","inventory after phone");key(scene,KEY_ESCAPE);check(scene.mode=="EXPLORE","inventory returns")
	print("PHONE_2048_VERIFY ",JSON.stringify({"failures":failures,"random_twos":twos,"random_fours":fours,"evidence":"engine fixtures; no browser capture proof"}))
	scene.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)

func _initialize()->void:call_deferred("verify")
