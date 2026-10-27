extends Node3D
## One birthday preparation, kept for this visit. Scene and ceremony share it.
signal close_requested
signal replay_requested
const DURATION := 8.0
var cake_state := "in_fridge"
var ceremony_active := false
var ceremony_paused := false
var ceremony_phase := "idle"
var elapsed := 0.0
var placement: Dictionary
var furniture: Dictionary={}
var cake: Node3D
var fridge_cake: Node3D
var flames: Node3D
var candle_light: OmniLight3D
var hinges: Array[Node3D]=[]
var overlay: Control
var heading: Label
var subtitle: Label
var end_actions: HBoxContainer
var continue_button: Button
var ceremony_camera := Transform3D.IDENTITY
var door_tween: Tween
var close_button: Button

func _ready() -> void:
	placement=JSON.parse_string(FileAccess.get_file_as_string("res://assets/stage2/placement.json"))
	cake=load("res://assets/stage2/cake.glb").instantiate();add_child(cake);cake.position=vec(placement.table_position);cake.hide()
	fridge_cake=load("res://assets/stage2/cake.glb").instantiate();add_child(fridge_cake);fridge_cake.position=vec(placement.fridge_position)
	for prop in [cake,fridge_cake]:
		for mesh in prop.find_children("*","GeometryInstance3D",true,false):mesh.gi_mode=GeometryInstance3D.GI_MODE_DYNAMIC
	flames=Node3D.new();cake.add_child(flames)
	for point in placement.candles:
		var flame:=MeshInstance3D.new();flame.position=vec(point)
		var shape:=SphereMesh.new();shape.radius=.012;shape.height=.05;shape.radial_segments=12;shape.rings=8;flame.mesh=shape
		var material:=StandardMaterial3D.new();material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.albedo_color=Color("ffcf73");material.emission_enabled=true;material.emission=Color("ffad42");material.emission_energy_multiplier=2.0;flame.material_override=material
		flames.add_child(flame)
	flames.hide()
	candle_light=OmniLight3D.new();cake.add_child(candle_light);candle_light.position=Vector3(0,.38,0);candle_light.light_color=Color("ffbd70");candle_light.light_energy=.7;candle_light.omni_range=1.6;candle_light.shadow_enabled=false;candle_light.hide()

func vec(value: Array) -> Vector3:return Vector3(value[0],value[1],value[2])

func setup(data: Dictionary, room: Node3D) -> void:
	for item in data.furniture:
		if item.id in ["dining_table","refrigerator"]:furniture[item.id]=item
	for node in room.find_children("*","Node3D",true,false):
		if node.get_meta("extras",{}).has("hinge_axis"):hinges.append(node)
	# Opening the visual cavity never turns the appliance into a walkable room.
	var bounds:Dictionary=furniture.refrigerator
	var low:=vec(bounds.bounds_min);var high:=vec(bounds.bounds_max)
	var barrier:=StaticBody3D.new();barrier.name="FridgeAccessBoundary";barrier.collision_layer=4;add_child(barrier)
	var shape:=BoxShape3D.new();shape.size=high-low
	var collision:=CollisionShape3D.new();collision.shape=shape;collision.position=(low+high)*.5;barrier.add_child(collision)
	_build_overlay()

func target_at(position_: Vector3, room_id: String) -> Dictionary:
	if room_id!="dining":return {}
	var best:Dictionary={}
	for id in ["refrigerator","dining_table"]:
		var bounds:Dictionary=furniture[id]
		var low:=vec(bounds.bounds_min);var high:=vec(bounds.bounds_max)
		if id=="refrigerator" and position_.x>low.x+.1:continue
		var nearest:=Vector2(clampf(position_.x,low.x,high.x),clampf(position_.z,low.z,high.z))
		var distance:=Vector2(position_.x,position_.z).distance_to(nearest)
		if distance<.95 and (best.is_empty() or distance<float(best.distance)):
			best={"id":"cake_fridge" if id=="refrigerator" else "cake_table","distance":distance}
	return best

func take_cake() -> bool:
	if cake_state!="in_fridge":return false
	cake_state="carried"
	if door_tween:door_tween.kill()
	door_tween=create_tween()
	for i in hinges.size():door_tween.parallel().tween_property(hinges[i],"rotation:y",1.15 if i==0 else -1.15,.4)
	door_tween.chain().tween_interval(.7)
	door_tween.tween_callback(fridge_cake.hide)
	door_tween.tween_interval(.4)
	for hinge in hinges:door_tween.parallel().tween_property(hinge,"rotation:y",0.0,.4)
	return true

func place_cake() -> bool:
	if cake_state!="carried":return false
	cake_state="placed";cake.show();fridge_cake.hide();return true

func light_candles() -> bool:
	if cake_state!="placed":return false
	cake_state="lit";flames.show();candle_light.show();return true

func missing_conditions(crown_owned: bool, crown_worn: bool) -> Array[String]:
	var missing:Array[String]=[]
	if not crown_owned:missing.append("crown_missing")
	elif not crown_worn:missing.append("crown_unworn")
	if cake_state not in ["placed","lit"]:missing.append("cake_unplaced")
	if cake_state!="lit":missing.append("candles_unlit")
	return missing

func condition_message(owned: bool, worn: bool) -> String:
	var messages={"crown_missing":"去书房翻开情书，领取你的王冠。","crown_unworn":"按 B 打开珍藏，先戴上王冠。","cake_unplaced":"先把冰箱里的蛋糕摆到餐桌上。","candles_unlit":"先点燃蛋糕上的蜡烛。"}
	var missing:=missing_conditions(owned,worn)
	return messages[missing[0]] if not missing.is_empty() else "一切准备好了 · F 开始庆祝"

func prompt_for(id: String) -> String:
	if id=="cake_fridge":return "F 从冰箱取出蛋糕" if cake_state=="in_fridge" else "F 查看冰箱 · 蛋糕已取出"
	match cake_state:
		"in_fridge":return "F 准备生日蛋糕"
		"carried":return "F 把蛋糕摆到餐桌"
		"placed":return "F 点燃蜡烛"
	return "F 开始庆祝"

func start_ceremony(owned: bool, worn: bool) -> bool:
	if ceremony_active and ceremony_phase=="playing":return false
	if not missing_conditions(owned,worn).is_empty():return false
	ceremony_active=true;ceremony_paused=false;ceremony_phase="playing";elapsed=0
	if overlay:overlay.show();_refresh_overlay()
	return true

func advance(delta: float) -> void:
	if not ceremony_active or ceremony_paused or ceremony_phase!="playing":return
	elapsed=minf(DURATION,elapsed+delta)
	if elapsed>=DURATION:ceremony_phase="finished"
	_refresh_overlay()

func pause_ceremony() -> void:
	if ceremony_active:ceremony_paused=true
	_refresh_overlay()

func resume_ceremony() -> void:
	if ceremony_active:ceremony_paused=false
	_refresh_overlay()

func exit_ceremony() -> void:
	ceremony_active=false;ceremony_paused=false;ceremony_phase="idle"
	if overlay:overlay.hide()

func _process(delta: float) -> void:
	advance(delta)
	if cake_state=="lit":
		var time:=Time.get_ticks_msec()*.001
		candle_light.light_energy=.70+.05*sin(time*7)
		for i in flames.get_child_count():flames.get_child(i).scale.y=1+.08*sin(time*6+i*2)

func frame_actor(position_: Vector3) -> void:
	var focus:Vector3=(position_+cake.position)*.5+Vector3(0,.48,0)
	ceremony_camera=Transform3D(Basis.IDENTITY,focus+Vector3(2.8,2.4,3.5)).looking_at(focus,Vector3.UP)

func _button(text_: String, parent: Node, callback: Callable) -> Button:
	var button:=Button.new();button.text=text_;button.custom_minimum_size=Vector2(190,48)
	button.add_theme_font_size_override("font_size",20)
	var style:=StyleBoxFlat.new();style.bg_color=Color("f5ead5");style.border_color=Color("baa477");style.set_border_width_all(1);style.set_corner_radius_all(6)
	style.content_margin_left=16;style.content_margin_right=16
	button.add_theme_stylebox_override("normal",style)
	button.add_theme_stylebox_override("hover",style.duplicate())
	button.add_theme_color_override("font_color",Color("4a3625"));button.add_theme_color_override("font_hover_color",Color("80502d"));button.add_theme_color_override("font_focus_color",Color("4a3625"))
	button.pressed.connect(callback);parent.add_child(button);return button

func _build_overlay() -> void:
	var layer:=CanvasLayer.new();layer.layer=5;add_child(layer)
	overlay=Control.new();overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(overlay)
	var theme:=Theme.new();theme.default_font=load("res://assets/NotoSansSC-Reading.ttf");overlay.theme=theme
	var banner:=VBoxContainer.new();overlay.add_child(banner)
	banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP);banner.offset_left=-330;banner.offset_right=330;banner.offset_top=26;banner.offset_bottom=140
	heading=Label.new();heading.text="生日快乐";heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;heading.add_theme_font_size_override("font_size",48)
	heading.add_theme_color_override("font_color",Color("fff0c5"));heading.add_theme_color_override("font_shadow_color",Color("4e3623"));heading.add_theme_constant_override("shadow_offset_x",2);heading.add_theme_constant_override("shadow_offset_y",3);heading.add_theme_constant_override("shadow_outline_size",4);banner.add_child(heading)
	subtitle=Label.new();subtitle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;subtitle.add_theme_font_size_override("font_size",19);subtitle.add_theme_color_override("font_color",Color("463825"));banner.add_child(subtitle)
	close_button=_button("返回小屋 · Esc",overlay,func():close_requested.emit())
	close_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT);close_button.offset_left=-220;close_button.offset_right=-24;close_button.offset_top=24;close_button.offset_bottom=72
	end_actions=HBoxContainer.new();end_actions.add_theme_constant_override("separation",20);overlay.add_child(end_actions)
	end_actions.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM);end_actions.offset_left=-210;end_actions.offset_right=210;end_actions.offset_top=-88;end_actions.offset_bottom=-40
	_button("返回游览",end_actions,func():close_requested.emit())
	_button("再庆祝一次",end_actions,func():replay_requested.emit())
	continue_button=_button("继续庆祝",overlay,resume_ceremony)
	continue_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER);continue_button.offset_left=-110;continue_button.offset_right=110;continue_button.offset_top=-24;continue_button.offset_bottom=24
	overlay.hide()

func _refresh_overlay() -> void:
	if not overlay or not ceremony_active:return
	heading.text="庆祝已暂停" if ceremony_paused else "生日快乐"
	heading.modulate.a=1.0 if ceremony_paused else clampf(elapsed/.7,0,1)
	subtitle.text="准备都还在 · 点击继续庆祝" if ceremony_paused else "继续逛逛小屋，或再庆祝一次" if ceremony_phase=="finished" else ""
	continue_button.visible=ceremony_paused
	end_actions.visible=ceremony_phase=="finished" and not ceremony_paused

func snapshot() -> Dictionary:
	return {"cake":cake_state,"active":ceremony_active,"paused":ceremony_paused,"phase":ceremony_phase,"elapsed":elapsed,"cake_visible":cake.visible,"flames_visible":flames.visible,"hinges":hinges.size()}
