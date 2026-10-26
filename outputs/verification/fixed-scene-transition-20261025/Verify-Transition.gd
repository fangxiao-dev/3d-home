extends SceneTree
var scene: Node3D
var failures: Array[String] = []
var cases: Array = []
func _initialize() -> void: call_deferred("verify")
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
func key(code: int, pressed := true, echo := false) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.pressed = pressed
	e.echo = echo
	scene._input(e)
func frames(n: int) -> void:
	for i in range(n): await process_frame
func grant() -> void:
	# External-state simulation for engine tests only.
	scene.capture_requested = true
	scene._pointer_lock_changed(true)
func wait_mode(value: String) -> void:
	for i in range(1200):
		if scene.mode == value: return
		await process_frame
	check(false, "Timeout " + value + " actual " + scene.mode)
func verify() -> void:
	scene = load("res://playroom.tscn").instantiate()
	root.add_child(scene)
	await frames(3)
	for id in scene.seats:
		var seat: Dictionary = scene.seats[id]
		var expected := Transform3D(Basis.IDENTITY, scene.vec(seat.camera_position)).looking_at(scene.vec(seat.camera_target), Vector3.UP)
		for yaw in [0.0, 120.0, 240.0]:
			for amount in [0.85, 1.15]:
				scene.player.position = scene.vec(seat.approach)
				scene.target_camera_yaw = deg_to_rad(yaw)
				scene.target_zoom = amount
				scene._update_camera(0, true)
				grant()
				await frames(3)
				key(KEY_F)
				key(KEY_F, false)
				var cut_seen := false
				var sit_seen := false
				var fade_seen := false
				var previous_fixed := false
				var sample_count := 0
				for i in range(1200):
					await process_frame
					sample_count += 1
					if scene.transition_phase != "none":
						fade_seen = true
						check(scene.animation == "Idle", "Animation during fade " + id)
						check(not scene.navigation_active, "Navigation during fade " + id)
						var motion := InputEventMouseMotion.new()
						motion.screen_relative = Vector2(100, 100)
						scene._input(motion)
						key(KEY_F)
						key(KEY_F, false)
					if scene.camera_seated and not previous_fixed:
						cut_seen = true
						check(is_equal_approx(scene.scene_fade.color.a, 1.0), "Camera cut was not covered " + id)
						check(scene.camera.transform.is_equal_approx(expected), "Cut composition differs " + id)
						check(scene._visible_body_obstructions().is_empty(), "Cut did not update body visibility " + id)
					previous_fixed = scene.camera_seated
					if scene.mode == "SIT_DOWN":
						sit_seen = true
						check(scene.transition_phase == "none" and is_zero_approx(scene.scene_fade.color.a) and not scene.scene_fade.visible, "SitDown before reveal " + id)
						check(scene.camera.transform.is_equal_approx(expected), "SitDown camera varies by entry " + id)
					if scene.mode == "SEATED": break
				check(fade_seen and cut_seen and sit_seen and scene.mode == "SEATED", "Incomplete transition " + id)
				key(KEY_ESCAPE)
				grant()
				key(KEY_ESCAPE, true, true)
				key(KEY_ESCAPE) # Deliberate duplicate non-echo engine boundary event, not a browser claim.
				await wait_mode("EXPLORE")
				await frames(40)
				key(KEY_ESCAPE)
				check(scene.pointer_locked and scene.navigation_active and not scene.resume_button.visible, "Same Escape crossed to outer pause " + id)
				check(absf(scene.target_camera_yaw - deg_to_rad(yaw)) < 0.0001 and absf(scene.target_zoom-amount)<0.0001, "Return lost saved orbit " + id)
				key(KEY_ESCAPE, false)
				key(KEY_ESCAPE)
				check(not scene.pointer_locked and not scene.navigation_active, "Fresh Escape did not pause " + id)
				key(KEY_ESCAPE, false)
				cases.append({"seat":id,"yaw":yaw,"zoom":amount,"samples":sample_count,"covered_cut":cut_seen,"revealed_sit":sit_seen})
	print("FIXED_SCENE_TRANSITION_VERIFY ", JSON.stringify({"cases":cases,"failures":failures,"scope":"engine state/permission boundary simulation"}))
	quit(0 if failures.is_empty() else 1)
