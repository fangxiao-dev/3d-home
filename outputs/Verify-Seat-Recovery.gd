extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("verify")

func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)

func settle(scene: Node) -> void:
	for i in range(1000):
		await physics_frame
		if scene.mode in ["EXPLORE", "SEATED"]: return
	check(false, "Interaction did not finish")

func blocked_case(alignment: bool, lose_focus := false) -> void:
	var scene = load("res://playroom.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	var blocker := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.05, 0.5, 0.5) if alignment else Vector3(0.60, 0.5, 0.10)
	collision.shape = shape
	blocker.add_child(collision)
	if alignment:
		scene.player.position = scene.vec(scene.seats.entry_stool.approach)
		blocker.position = scene._stand_point(scene.seats.entry_stool) + Vector3(0, 0.25, 0)
	else:
		blocker.position = Vector3(-0.325, 0.25, -1.075)
	scene.add_child(blocker)
	await physics_frame
	# Engine-only external capture grant; browser permission is checked separately.
	scene.capture_requested = true
	scene._pointer_lock_changed(true)
	for i in range(3): await physics_frame
	check(scene._nearest_seat() == "entry_stool", "Fixture must offer the seat")
	scene._enter_target_action("entry_stool")
	if lose_focus: scene._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	await settle(scene)
	for i in range(3): await physics_frame
	check(scene.mode == "EXPLORE" and not scene.auto_moving, "Blocked entry did not return to explore")
	check(scene.seat_id.is_empty() and scene.seat_exceptions.is_empty(), "Blocked entry retained seat state")
	if lose_focus:
		check(not scene.navigation_active and not scene.pointer_locked, "Blurred entry grabbed navigation back")
	else:
		check(scene.navigation_active and not scene.resume_button.visible, "Blocked entry paused navigation")
		blocker.queue_free()
		await physics_frame
		var before: Vector3 = scene.player.position
		Input.action_press("walk_right")
		for i in range(12): await physics_frame
		Input.action_release("walk_right")
		check(scene.player.position.x - before.x > 0.1, "Cannot walk away after blocked entry")
		for i in range(3): await physics_frame
		scene._enter_target_action("entry_stool")
		check(scene.notice.is_empty(), "Retry retained the old failure message")
		await settle(scene)
		check(scene.mode == "SEATED" and not scene.pointer_locked, "Retry did not seat and release cursor")
	print("SEAT_RECOVERY_CASE ", JSON.stringify({"alignment": alignment, "blur": lose_focus, "mode": scene.mode}))
	scene.queue_free()
	await process_frame

func verify() -> void:
	await blocked_case(false)
	await blocked_case(true)
	await blocked_case(false, true)
	print("SEAT_RECOVERY_VERIFY ", JSON.stringify({"failures": failures}))
	quit(0 if failures.is_empty() else 1)
