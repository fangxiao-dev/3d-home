extends SceneTree
var scene: Node3D
var failures: Array[String] = []
var cases: Array = []
func _initialize() -> void: call_deferred("verify")
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
func key(pressed: bool, echo := false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_ESCAPE
	event.pressed = pressed
	event.echo = echo
	scene._input(event)
func wait_mode(value: String) -> void:
	for i in range(1200):
		if scene.mode == value: return
		await process_frame
	check(false, "Mode timeout " + value)
func verify() -> void:
	scene = load("res://playroom.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	for phase in ["fade_out", "black", "fade_in"]:
		scene.player.position = scene.vec(scene.seats.entry_stool.approach)
		scene.capture_requested = true
		scene._pointer_lock_changed(true)
		await physics_frame
		await physics_frame
		scene._enter_target_action("entry_stool")
		var found := false
		for i in range(1200):
			await process_frame
			if scene.transition_phase == phase and (phase == "black" or (scene.scene_fade.color.a > 0.05 and scene.scene_fade.color.a < 0.95)):
				found = true
				break
		check(found, "Missed phase " + phase)
		var interrupted_alpha: float = scene.scene_fade.color.a
		key(true) # Press during isolated transition; deliberately lose this key-up on blur.
		check(scene.escape_held, "Held Escape not tracked")
		scene._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		check(not scene.escape_held and not scene.interaction_restore_allowed and not scene.pointer_locked, "Blur did not clear held/restore intent " + phase)
		await wait_mode("SEATED")
		scene._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
		check(scene.transition_phase == "none" and is_zero_approx(scene.scene_fade.color.a) and not scene.scene_fade.visible, "Mask remained after interrupted " + phase)
		key(true, true)
		check(scene.mode == "SEATED", "Old Escape repeat exited after focus " + phase)
		key(true)
		await wait_mode("EXPLORE")
		for i in range(40): await process_frame
		check(not scene.navigation_active and not scene.pointer_locked and scene.resume_button.visible, "Interrupted exit did not remain manual " + phase)
		key(false)
		scene.capture_requested = true # Explicit manual-resume grant boundary, not browser permission proof.
		scene._pointer_lock_changed(true)
		for i in range(3): await process_frame
		check(scene.navigation_active, "Manual resume unavailable " + phase)
		key(true)
		key(false)
		check(not scene.navigation_active, "Fresh Escape unavailable after lost keyup " + phase)
		cases.append({"phase":phase,"interrupted_alpha":interrupted_alpha,"mask_cleared":true,"manual_resume":true,"lost_keyup_recovered":true})
	print("FIXED_SCENE_INTERRUPTION_VERIFY ",JSON.stringify({"cases":cases,"failures":failures,"scope":"explicit engine blur and external capture simulation"}))
	quit(0 if failures.is_empty() else 1)
