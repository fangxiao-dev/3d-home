extends SceneTree

var failures: Array[String] = []

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func new_scene() -> Node:
	var scene: Node = load("res://playroom.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	return scene

func close_scene(scene: Node) -> void:
	scene.queue_free()
	await process_frame

func key(scene: Node, code: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	scene.call("_input", event)
	event.pressed = false
	scene.call("_input", event)

func key_echo(scene: Node, code: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	event.echo = true
	scene.call("_input", event)
	event.pressed = false
	scene.call("_input", event)

func mouse_motion(scene: Node) -> void:
	var event := InputEventMouseMotion.new()
	event.screen_relative = Vector2(120, 80)
	scene.call("_input", event)

func prepare_navigation(scene: Node) -> void:
	scene.set("capture_requested", true)
	scene.call("_pointer_lock_changed", true) # Engine simulation of the external pointer-capture grant.
	scene.set("awaiting_movement_release", false)
	for frame in 35:
		await physics_frame

func check_legal_target(scene: Node3D, point: Vector3, target_id: String) -> void:
	var birthday: Node = scene.get("birthday")
	var result: Dictionary = birthday.call("target_at", point, "dining")
	check(result.get("id", "") == target_id, "target_at " + str(point) + " expected " + target_id + " got " + str(result))
	check(float(result.get("distance", 10.0)) < 0.95, "Target outside interaction range at " + str(point))
	var player: CharacterBody3D = scene.get("player")
	var collider: CollisionShape3D = player.get_child(0)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = collider.shape
	query.transform = Transform3D(Basis.IDENTITY, point + collider.position)
	query.collision_mask = player.collision_mask
	check(scene.get_world_3d().direct_space_state.intersect_shape(query).is_empty(), "Interaction point overlaps furniture: " + str(point))
	player.position = point
	check(scene.call("_nearest_interaction") == ("closeup_fridge" if target_id=="cake_fridge" else target_id), "F target mismatch at " + str(point))

func verify_targets_and_f_preparation() -> void:
	var scene: Node3D = await new_scene()
	await prepare_navigation(scene)
	for point in [Vector3(0.75, 0.01, 5.5), Vector3(0.75, 0.01, 5.0), Vector3(0.75, 0.01, 6.05)]:
		check_legal_target(scene, point, "cake_fridge")
	for point in [Vector3(0, 0.01, 4.18), Vector3(-1.05, 0.01, 3.2), Vector3(-1.05, 0.01, 5.2), Vector3(-1.98, 0.01, 4.18)]:
		check_legal_target(scene, point, "cake_table")
	var chair_point := Vector3(-1.98, 0.01, 3.4)
	var player: CharacterBody3D = scene.get("player")
	var player_shape: CollisionShape3D = player.get_child(0)
	var chair_query := PhysicsShapeQueryParameters3D.new()
	chair_query.shape = player_shape.shape
	chair_query.transform = Transform3D(Basis.IDENTITY, chair_point + player_shape.position)
	chair_query.collision_mask = player.collision_mask
	check(scene.get_world_3d().direct_space_state.intersect_shape(chair_query).is_empty(), "Dining-chair F point overlaps furniture")
	player.position = chair_point
	check(scene.call("_nearest_interaction") == "dining_chair", "Dining chair lost its F target")
	check(scene.get("birthday").call("target_at", Vector3.ZERO, "kitchen").is_empty(), "Cake target leaked outside dining room")

	player.position = Vector3(0.75, 0.01, 5.5)
	check(scene.call("_nearest_interaction") == "closeup_fridge", "Fridge F affordance was not discoverable")
	key(scene, KEY_F)
	check(scene.mode=="CLOSEUP","Fridge opens Close-up")
	key(scene,KEY_ENTER)
	check(scene.get("birthday").get("cake_state") == "carried", "F did not take cake from fridge")
	key(scene, KEY_ENTER)
	check(scene.get("birthday").get("cake_state") == "carried", "Repeated cake button reset cake progress")
	key(scene,KEY_ESCAPE);await prepare_navigation(scene)
	player.position = Vector3(0, 0.01, 4.18)
	check(scene.call("_nearest_interaction") == "cake_table", "Table F affordance was not discoverable")
	key(scene, KEY_F)
	check(scene.get("birthday").get("cake_state") == "placed", "F did not place cake on table")
	key_echo(scene, KEY_F)
	check(scene.get("birthday").get("cake_state") == "placed", "Held F echo advanced more than one preparation step")
	key(scene, KEY_F)
	check(scene.get("birthday").get("cake_state") == "lit", "F did not light candles")
	check(not scene.get("birthday").get("ceremony_active"), "Preparation F auto-started ceremony")
	key_echo(scene, KEY_F)
	check(not scene.get("birthday").get("ceremony_active"), "Held F echo started ceremony")

	var birthday: Node = scene.get("birthday")
	var letters = scene.get("letters_ui")
	letters.open_crown_article()
	letters.claim_crown()
	check(letters.crown_owned and letters.crown_worn, "Crown fixture could not claim and wear crown")
	player.position = Vector3(0, 0.01, 4.18)
	check(scene.call("_nearest_interaction") == "cake_table", "Ready cake lost the table F target")
	key(scene, KEY_F)
	check(birthday.get("ceremony_active") and birthday.get("ceremony_phase") == "playing" and scene.get("mode") == "CEREMONY", "F with all requirements did not enter ceremony")

	var position_before: Vector3 = player.position
	var yaw_before: float = scene.get("target_camera_yaw")
	Input.action_press("walk_up")
	mouse_motion(scene)
	key(scene, KEY_B)
	key(scene, KEY_F)
	for frame in 12:
		await physics_frame
	Input.action_release("walk_up")
	check(player.position.is_equal_approx(position_before), "Ceremony leaked movement input")
	check(is_equal_approx(float(scene.get("target_camera_yaw")), yaw_before), "Ceremony leaked camera input")
	check(scene.get("mode") == "CEREMONY", "B/F escaped ceremony input isolation")

	scene.call("_notification", NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(birthday.get("ceremony_paused") and not scene.get("app_focused"), "Focus loss did not pause ceremony")
	var paused_elapsed: float = birthday.get("elapsed")
	for frame in 12:
		await physics_frame
	check(is_equal_approx(float(birthday.get("elapsed")), paused_elapsed), "Ceremony advanced while focus was lost")
	scene.call("_notification", NOTIFICATION_APPLICATION_FOCUS_IN)
	check(scene.get("app_focused") and birthday.get("ceremony_paused"), "Focus regain auto-resumed ceremony")
	var continue_button: Button = birthday.get("continue_button")
	check(continue_button.visible, "Focus recovery did not show explicit continue control")
	continue_button.emit_signal("pressed") # Engine-side control activation, not browser mouse evidence.
	check(not birthday.get("ceremony_paused") and not continue_button.visible, "Continue control did not resume ceremony")
	key(scene, KEY_ESCAPE)
	check(scene.get("mode") == "EXPLORE" and not birthday.get("ceremony_active"), "Esc did not exit ceremony")
	check(birthday.get("cake_state") == "lit", "Esc exit discarded cake preparation")

	await prepare_navigation(scene) # Simulated OS grant after interaction; not browser pointer-lock evidence.
	check(scene.get("navigation_active"), "Navigation did not return after ceremony")
	var returned_position: Vector3 = player.position
	var returned_yaw: float = scene.get("target_camera_yaw")
	Input.action_press("walk_up")
	mouse_motion(scene)
	for frame in 12:
		await physics_frame
	Input.action_release("walk_up")
	check(player.position.distance_to(returned_position) > 0.01, "Movement did not resume after ceremony")
	check(not is_equal_approx(float(scene.get("target_camera_yaw")), returned_yaw), "Camera input did not resume after ceremony")
	player.position = Vector3(0, 0.01, 4.18)
	key(scene, KEY_B)
	check(scene.get("mode") == "INVENTORY", "B did not open inventory after ceremony")
	key(scene, KEY_ESCAPE)
	check(scene.get("mode") == "EXPLORE", "Esc did not close inventory after ceremony")
	await prepare_navigation(scene)
	letters.toggle_crown()
	player.position = Vector3(0, 0.01, 4.18)
	for frame in 35:
		await physics_frame
	key(scene, KEY_F)
	check(not birthday.get("ceremony_active") and scene.get("mode") == "EXPLORE", "Replay started with crown unworn")
	check(str(scene.get("notice")).contains("先戴上王冠"), "Unworn-crown F attempt did not show its next-step instruction")
	letters.toggle_crown()
	key(scene, KEY_F)
	check(birthday.get("ceremony_active") and birthday.get("ceremony_phase") == "playing", "Replay failed after crown was worn again")
	var replay_elapsed: float = birthday.get("elapsed")
	key(scene, KEY_F)
	check(birthday.get("ceremony_active") and is_equal_approx(float(birthday.get("elapsed")), replay_elapsed), "Repeated F restarted the ceremony")
	for frame in 510:
		if birthday.get("ceremony_phase") == "finished":
			break
		await physics_frame
	check(birthday.get("ceremony_phase") == "finished", "Live ceremony did not finish after eight seconds")
	var end_actions: HBoxContainer = birthday.get("end_actions")
	check(end_actions.visible and end_actions.get_child_count() == 2, "Finished ceremony did not show return and replay actions")
	var replay_button: Button
	for child in end_actions.get_children():
		if child is Button and child.text == "再庆祝一次":
			replay_button = child
	check(replay_button != null, "Finished ceremony has no replay button")
	if replay_button:
		replay_button.emit_signal("pressed") # Engine-side control activation, not browser mouse evidence.
		check(birthday.get("ceremony_phase") == "playing" and birthday.get("ceremony_active") and is_zero_approx(float(birthday.get("elapsed"))), "Replay button did not start a fresh ceremony")
	key(scene, KEY_ESCAPE)
	check(birthday.get("cake_state") == "lit" and not birthday.get("ceremony_active"), "Replay exit did not preserve preparation")
	await close_scene(scene)

func verify_state_machine() -> void:
	var scene: Node = await new_scene()
	var birthday: Node = scene.get("birthday")
	check(birthday != null, "playroom.birthday is missing")
	if birthday == null:
		await close_scene(scene)
		return

	check(birthday.get("cake_state") == "in_fridge", "Cake must start in the fridge")
	var none_owned: Array[String] = birthday.call("missing_conditions", false, false)
	check(none_owned == ["crown_missing", "cake_unplaced", "candles_unlit"], "Missing-crown conditions are incorrect or unstable: " + str(none_owned))
	var owned_unworn: Array[String] = birthday.call("missing_conditions", true, false)
	check(owned_unworn == ["crown_unworn", "cake_unplaced", "candles_unlit"], "Unworn-crown conditions are incorrect or unstable: " + str(owned_unworn))
	check(not birthday.call("place_cake"), "Cake placed before pickup")
	check(not birthday.call("light_candles"), "Candles lit before placement")
	check(not birthday.call("start_ceremony", false, false), "Ceremony started without requirements")
	check(birthday.get("cake_state") == "in_fridge" and birthday.get("ceremony_phase") == "idle" and not birthday.get("ceremony_active"), "Failed start changed state")

	check(birthday.call("take_cake"), "Could not take cake from fridge")
	check(birthday.get("cake_state") == "carried", "Pickup did not set carried state")
	check(not birthday.call("take_cake") and birthday.get("cake_state") == "carried", "Repeated pickup changed cake state")
	check(birthday.call("place_cake"), "Could not place cake")
	check(birthday.get("cake_state") == "placed", "Placement did not set placed state")
	check(not birthday.call("place_cake") and birthday.get("cake_state") == "placed", "Repeated placement changed cake state")
	check(birthday.call("missing_conditions", true, true) == ["candles_unlit"], "Unlit-candles-only condition is incorrect")
	check(not birthday.call("start_ceremony", true, true) and birthday.get("cake_state") == "placed" and birthday.get("ceremony_phase") == "idle", "Candles-unlit failure changed state")
	check(birthday.call("light_candles"), "Could not light candles")
	check(birthday.get("cake_state") == "lit", "Lighting did not set lit state")
	check(not birthday.call("light_candles") and birthday.get("cake_state") == "lit", "Repeated lighting changed cake state")
	check(birthday.call("missing_conditions", true, true).is_empty(), "All requirements satisfied but still reported missing conditions")
	check(not birthday.get("ceremony_active") and birthday.get("ceremony_phase") == "idle", "Ceremony started automatically when conditions became ready")
	check(birthday.call("missing_conditions", false, false) == ["crown_missing"], "Crown-missing-only condition is incorrect")
	check(not birthday.call("start_ceremony", false, false) and birthday.get("cake_state") == "lit" and birthday.get("ceremony_phase") == "idle", "Crown-missing failure changed state")
	check(not birthday.call("start_ceremony", true, false), "Ceremony started with owned but unworn crown")
	check(birthday.get("cake_state") == "lit" and birthday.get("ceremony_phase") == "idle", "Unworn-crown failure changed prepared state")

	check(birthday.call("start_ceremony", true, true), "Could not start ceremony after preparation")
	check(birthday.get("ceremony_active") and not birthday.get("ceremony_paused") and birthday.get("ceremony_phase") == "playing", "Start did not enter playing state")
	check(not birthday.call("start_ceremony", true, true), "Repeated start restarted an active ceremony")
	birthday.call("advance", 2.5)
	var elapsed_before_pause: float = birthday.get("elapsed")
	check(not birthday.call("start_ceremony", true, true) and is_equal_approx(float(birthday.get("elapsed")), elapsed_before_pause), "Repeated start reset ceremony elapsed time")
	if float(birthday.get("elapsed")) < 2.5:
		birthday.call("advance", 2.5 - float(birthday.get("elapsed")))
	elapsed_before_pause = birthday.get("elapsed")
	birthday.call("pause_ceremony")
	check(birthday.get("ceremony_paused"), "Pause did not set paused state")
	birthday.call("advance", 5.0)
	check(is_equal_approx(float(birthday.get("elapsed")), elapsed_before_pause), "Elapsed time advanced while paused")
	birthday.call("resume_ceremony")
	check(not birthday.get("ceremony_paused"), "Resume did not clear paused state")
	birthday.call("advance", 5.5)
	check(birthday.get("ceremony_phase") == "finished", "Eight seconds did not finish the ceremony")
	check(is_equal_approx(float(birthday.get("elapsed")), 8.0), "Ceremony elapsed time did not stop at eight seconds")

	birthday.call("exit_ceremony")
	check(not birthday.get("ceremony_active") and not birthday.get("ceremony_paused"), "Exit left ceremony active or paused")
	check(birthday.get("cake_state") == "lit", "Exit discarded cake preparation")
	check(not birthday.call("start_ceremony", true, false), "Replay started after crown was removed")
	check(birthday.call("start_ceremony", true, true), "Replay failed after crown was worn again")
	birthday.call("advance", 1.25)
	birthday.call("exit_ceremony")
	check(birthday.get("cake_state") == "lit" and birthday.get("ceremony_phase") == "idle" and not birthday.get("ceremony_active"), "Mid-replay exit discarded preparation or left ceremony active")
	await close_scene(scene)

func verify_reverse_preparation_order() -> void:
	var scene: Node = await new_scene()
	var birthday: Node = scene.get("birthday")
	check(birthday != null, "playroom.birthday is missing in reverse-order fixture")
	if birthday != null:
		check(birthday.call("missing_conditions", true, true) == ["cake_unplaced", "candles_unlit"], "Crown-first preparation conditions are incorrect")
		check(not birthday.call("start_ceremony", true, true) and birthday.get("cake_state") == "in_fridge" and birthday.get("ceremony_phase") == "idle", "Unplaced-cake failure changed state")
		check(birthday.call("take_cake"), "Crown-first order could not take cake")
		check(birthday.call("place_cake"), "Crown-first order could not place cake")
		check(birthday.call("light_candles"), "Crown-first order could not light candles")
		check(birthday.call("start_ceremony", true, true), "Crown-first preparation order could not start ceremony")
	await close_scene(scene)

func verify() -> void:
	await verify_state_machine()
	await verify_reverse_preparation_order()
	await verify_targets_and_f_preparation()
	print("BIRTHDAY_STATE_VERIFY ", JSON.stringify({"failures": failures, "scenarios": ["cake-first", "crown-first", "missing-conditions", "idempotent-steps", "pause-finish-exit-replay", "finished-ui-replay", "target-competition", "legal-dining-points", "real-F-preparation"]}))
	quit(0 if failures.is_empty() else 1)

func _initialize() -> void:
	call_deferred("verify")
