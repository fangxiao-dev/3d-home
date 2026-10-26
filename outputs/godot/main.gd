extends "res://playroom.gd"
## Asset inspection uses the same baked lighting and model as the playable scene.
func _ready() -> void:
	super._ready()
	player.visible = false
	set_physics_process(false)
	_set_view(0)
func _set_view(index: int) -> void:
	var ids := house_layout.keys()
	var id: String = ids[index % ids.size()]
	player.position = vec(scene_data.room_targets[id])
	camera_focus = _explore_target()
	_update_camera(1, true)
