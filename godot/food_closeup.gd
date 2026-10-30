extends Node3D
## One configured tabletop diorama. Selection coordinates also own keyboard adjacency.
signal activated(id:String)
signal closed
const FONT=preload("res://assets/NotoSansSC-Reading.ttf")
var regions:Array=[]
var current:Dictionary={}
var remembered:Dictionary={}
var selected:=0
var state:RefCounted
var catalog:Dictionary={}
var layouts:Dictionary={}
var stage:Node3D
var sprites:Array[Node3D]=[]
var shadows:Array[MeshInstance3D]=[]
var focus_glows:Array[MeshInstance3D]=[]
var ui:CanvasLayer
var root:Control
var heading:Label
var description:Label
var status:Label
var action:Button
var cake_button:Button
var cake_taken:=false
var source_room:Node3D
var camera_transform:Transform3D

func setup(collection:RefCounted,environment_:Node3D)->void:
	state=collection;source_room=environment_
	regions=JSON.parse_string(FileAccess.get_file_as_string("res://content/food-collection/closeup-regions.json"))
	for item in state.catalog:catalog[item.id]=item
	for item in JSON.parse_string(FileAccess.get_file_as_string("res://content/food-collection/layout-single-page.json")):layouts[item.id]=item
	position=Vector3(0,100,0)
	camera_transform=Transform3D(Basis.IDENTITY,position+Vector3(0,4.7,9.5)).looking_at(position+Vector3(0,.5,.6),Vector3.UP)
	ui=CanvasLayer.new();ui.layer=7;add_child(ui)
	root=Control.new();root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.add_child(root)
	var panel:=PanelContainer.new();panel.position=Vector2(28,24);panel.custom_minimum_size=Vector2(340,0);root.add_child(panel)
	var style:=StyleBoxFlat.new();style.bg_color=Color(.99,.96,.89,.95);style.set_corner_radius_all(14);style.content_margin_left=20;style.content_margin_right=20;style.content_margin_top=14;style.content_margin_bottom=14;panel.add_theme_stylebox_override("panel",style)
	var column:=VBoxContainer.new();panel.add_child(column)
	heading=_label(column,23);description=_label(column,15);description.custom_minimum_size.x=310;description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;status=_label(column,14);status.custom_minimum_size.x=310;status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	action=_button("F 查看",column,func():activated.emit(selected_id()))
	var close:=_button("返回小屋 · Esc",root,func():closed.emit());close.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT);close.offset_left=-210;close.offset_right=-28;close.offset_top=24;close.offset_bottom=70
	var hint:=_label(root,18);hint.text="方向键 / WASD / 点击选择 · F 互动 · Esc 返回";hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM);hint.offset_left=-340;hint.offset_right=340;hint.offset_top=-36;hint.offset_bottom=-8;hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;hint.add_theme_color_override("font_color",Color("574839"))
	cake_button=_button("取出生日蛋糕 · Enter",root,func():
		if not cake_taken:activated.emit("cake"))
	cake_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT);cake_button.offset_left=-275;cake_button.offset_right=-28;cake_button.offset_top=-110;cake_button.offset_bottom=-64
	root.hide();hide()

func _label(parent:Node,size_:int)->Label:
	var label:=Label.new();parent.add_child(label);label.add_theme_font_override("font",FONT);label.add_theme_font_size_override("font_size",size_);label.add_theme_color_override("font_color",Color("49372a"));return label

func _button(text_:String,parent:Node,callback:Callable)->Button:
	var button:=Button.new();button.text=text_;button.add_theme_font_override("font",FONT);button.add_theme_font_size_override("font_size",17);button.focus_mode=Control.FOCUS_NONE;button.custom_minimum_size.y=38;button.pressed.connect(callback);parent.add_child(button);return button

func region(id:String)->Dictionary:
	for value in regions:
		if value.id==id:return value
	return {}

func open(id:String,taken:bool)->void:
	current=region(id);selected=int(remembered.get(id,0));cake_taken=taken
	if stage:stage.free()
	stage=Node3D.new();add_child(stage);sprites.clear();shadows.clear();focus_glows.clear()
	camera_transform=Transform3D(Basis.IDENTITY,position+Vector3(current.camera_position[0],current.camera_position[1],current.camera_position[2])).looking_at(position+Vector3(current.camera_target[0],current.camera_target[1],current.camera_target[2]),Vector3.UP)
	var colors={"coffee":"cfaf8c","kitchen":"e4ded3","cabinet":"d9c6aa","fridge":"d4e1dc"}
	if id not in ["coffee","fridge"]:_box(Vector3(0,-.12,.6),Vector3(7,.24,5),Color(colors[id]))
	if id=="coffee":
		_copy_furniture("coffee_table",Vector3(-.92,.58,-2.65),Vector3(0,0,.4),Vector3(7.4,3.0,5.2),0)
		_copy_furniture("sofa",Vector3(-2.2,0,-3.35),Vector3(0,-.65,-3.2),Vector3.ONE*1.5,-PI/2)
	elif id=="fridge":
		_build_fridge()
	else:
		_box(Vector3(0,1,-2.1),Vector3(7,2.3,.14),Color("efe5d5") if id!="fridge" else Color("e6f1ec"))
		if id=="kitchen":
			for x in [-2.6,-1.3,0,1.3,2.6]:_box(Vector3(x,1.1,-1.99),Vector3(.025,2.1,.02),Color("d1c6b7"))
			_box(Vector3(0,1.15,-1.98),Vector3(7,.025,.02),Color("d1c6b7"))
		else:
			for x in [-3.4,3.4]:_box(Vector3(x,.85,0),Vector3(.12,1.8,4.2),Color("f3ebdd"))
			_box(Vector3(0,.08,-1.35),Vector3(6.7,.06,1.25),Color("f6f0e5"))
	for i in current.items.size():
		var entry:Dictionary=current.items[i]
		var node:=Node3D.new();stage.add_child(node);node.position=Vector3(entry.position[0],.62,entry.position[1]-.5);sprites.append(node)
		var shadow:=MeshInstance3D.new();var disk:=CylinderMesh.new();disk.top_radius=.65;disk.bottom_radius=.65;disk.height=.012;shadow.mesh=disk;shadow.position=Vector3(node.position.x,.015,node.position.z);shadow.scale=Vector3(.85,1,.45);stage.add_child(shadow);shadows.append(shadow)
		var mat:=StandardMaterial3D.new();mat.albedo_color=Color(.18,.12,.06,.16);mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;shadow.material_override=mat
		if catalog.has(entry.id):
			var p:Dictionary=layouts[entry.id];var texture:=AtlasTexture.new();texture.atlas=load("res://content/food-collection/images/"+catalog[entry.id].image);texture.region=Rect2(p.bounds[0],p.bounds[1],p.bounds[2],p.bounds[3])
			var height_limit:float=1.30 if id=="fridge" and entry.id=="iced-cola" else 1.65
			var width:float=minf(float(entry.width),height_limit*float(p.bounds[2])/float(p.bounds[3]))
			var sprite:=Sprite3D.new();sprite.texture=texture;sprite.pixel_size=width/float(p.bounds[2]);node.position.y=width*float(p.bounds[3])/float(p.bounds[2])*.5+.04
			shadow.scale.x=width*.55
			sprite.billboard=BaseMaterial3D.BILLBOARD_ENABLED;sprite.no_depth_test=false;sprite.shaded=false;sprite.set_meta("pick_image",texture.get_image());node.add_child(sprite)
		else:
			var asset:Node3D=load("res://assets/phone/phone.glb" if entry.id=="phone" else "res://assets/stage2/cake.glb").instantiate();node.add_child(asset);asset.scale=Vector3.ONE*(7.0 if entry.id=="phone" else 2.5);asset.position.y=-.52
			if entry.id=="phone":
				node.position.y=-.142;asset.position.y=0;shadow.position.y=-.14
				for mesh in asset.find_children("*","MeshInstance3D",true,false):
					for surface in mesh.mesh.get_surface_count():
						var original:Material=mesh.get_active_material(surface)
						if original is StandardMaterial3D:
							var material:StandardMaterial3D=original.duplicate();material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mesh.set_surface_override_material(surface,material)
		if id=="fridge":
			var shelf:float=float(entry.get("shelf",0.0))
			node.position.y+=shelf;shadow.position.y+=shelf
			node.set_meta("rest_position",node.position)
			var glow:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(1.8,1.1);glow.mesh=plane;glow.position=shadow.position+Vector3(0,.012,0);stage.add_child(glow)
			var glow_shader:=Shader.new();glow_shader.code="shader_type spatial; render_mode unshaded, cull_disabled; void fragment(){float r=length((UV-vec2(0.5))*2.0); ALBEDO=vec3(0.70,0.94,1.0); ALPHA=(1.0-smoothstep(0.15,1.0,r))*0.65;}"
			var glow_material:=ShaderMaterial.new();glow_material.shader=glow_shader;glow.material_override=glow_material;focus_glows.append(glow)
	show();root.show();refresh()

func _copy_furniture(id:String,center:Vector3,destination:Vector3,scale_:Vector3,yaw:float)->void:
	var basis:=Basis(Vector3.UP,yaw).scaled(scale_)
	var transform_:=Transform3D(basis,destination-basis*center)
	for source in source_room.find_children("*","MeshInstance3D",true,false):
		if source.get_meta("extras",{}).get("furniture_id","")!=id:continue
		if id=="coffee_table" and source.name!="Tea table top":continue
		var copy:=MeshInstance3D.new();copy.mesh=source.mesh;copy.transform=transform_*source.global_transform;stage.add_child(copy)
		for surface in source.mesh.get_surface_count():
			copy.set_surface_override_material(surface,source.get_active_material(surface))

func _box(pos:Vector3,size_:Vector3,color:Color)->void:
	var mesh:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=size_;mesh.mesh=box;mesh.position=pos;stage.add_child(mesh)
	var material:=StandardMaterial3D.new();material.albedo_color=color;material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.roughness=.85;mesh.material_override=material

func selected_id()->String:return str(current.items[selected].id) if not current.is_empty() else ""

func refresh()->void:
	var id:=selected_id()
	cake_button.visible=current.id=="fridge"
	cake_button.disabled=cake_taken
	cake_button.text="蛋糕已取出" if cake_taken else "取出生日蛋糕 · Enter"
	for i in sprites.size():
		sprites[i].scale=Vector3.ONE*(1.08 if i==selected else 1.0)
		if current.id=="fridge":
			var is_cake:bool=current.items[i].id=="cake"
			sprites[i].visible=not (is_cake and cake_taken)
			shadows[i].visible=sprites[i].visible
			focus_glows[i].visible=i==selected and not is_cake
			var rest:Vector3=sprites[i].get_meta("rest_position",sprites[i].position)
			sprites[i].position=rest+Vector3(0,.045,.22) if i==selected else rest
			sprites[i].scale=Vector3.ONE*(1.10 if i==selected else 1.0)
			for sprite in sprites[i].get_children():
				if sprite is Sprite3D:sprite.modulate=Color.WHITE if i==selected else Color(.86,.90,.91)
		shadows[i].material_override.albedo_color=(Color(.16,.30,.34,.45) if i==selected else Color(.18,.25,.27,.13)) if current.id=="fridge" else (Color(.75,.43,.12,.40) if i==selected else Color(.18,.12,.06,.13))
	heading.text=current.name+" · "+(str(catalog[id].name) if catalog.has(id) else "手机 · 2048" if id=="phone" else "生日蛋糕")
	description.text=str(catalog[id].description) if catalog.has(id) else "接着玩一局，棋盘会保留在这次游览里。" if id=="phone" else "蛋糕已取出，可到餐桌继续准备。" if cake_taken else "取出生日蛋糕，带到餐桌准备。"
	status.text=("已收录" if state.found.has(id) else "尚未收录 · F 查看后收录") if catalog.has(id) else "独立互动"
	if catalog.has(id) and bool(catalog[id].draft):status.text+=" · 示意文案"
	status.text+="  %d / %d"%[selected+1,current.items.size()-(1 if current.id=="fridge" else 0)]
	action.text="F 查看详情" if catalog.has(id) else "F 玩手机" if id=="phone" else "蛋糕已取出" if cake_taken else "F 取出蛋糕"
	action.disabled=id=="cake" and cake_taken

func move_focus(direction:Vector2)->void:
	var origin:Vector2=Vector2(current.items[selected].position[0],current.items[selected].position[1]);var best:=selected;var score:=INF
	for i in current.items.size():
		if current.id=="fridge" and current.items[i].id=="cake":continue
		var point:=Vector2(current.items[i].position[0],current.items[i].position[1]);var delta:=point-origin;var along:=delta.dot(direction)
		if along<.1:continue
		var across:=absf(delta.cross(direction));var candidate:=delta.length()+across*2.0
		if candidate<score:score=candidate;best=i
	selected=best;remembered[current.id]=selected;refresh()

func handle_key(code:int)->void:
	if code==KEY_ESCAPE:closed.emit()
	elif code in [KEY_ENTER,KEY_KP_ENTER] and current.id=="fridge" and not cake_taken:activated.emit("cake")
	elif code==KEY_F:activated.emit(selected_id())
	elif code in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN,KEY_A,KEY_D,KEY_W,KEY_S]:move_focus({KEY_LEFT:Vector2.LEFT,KEY_A:Vector2.LEFT,KEY_RIGHT:Vector2.RIGHT,KEY_D:Vector2.RIGHT,KEY_UP:Vector2.UP,KEY_W:Vector2.UP,KEY_DOWN:Vector2.DOWN,KEY_S:Vector2.DOWN}[code])

func close()->void:hide();root.hide()

func _build_fridge()->void:
	# Three display zones, bounded by a warm shell and a cool recessed liner.
	_box(Vector3(0,1.15,-2.05),Vector3(6.8,4.7,.22),Color("ccd9d8"))
	for y in [.55,2.2]:
		_box(Vector3(0,y,-1.91),Vector3(6.35,1.65,.04),Color("e6eeee") if y>2 else Color("dae5e4"))
	for x in [-3.4,3.4]:
		_box(Vector3(x,1.15,-.15),Vector3(.22,4.7,3.9),Color("f2eee3"))
	_box(Vector3(0,3.52,-.15),Vector3(7,.18,3.9),Color("f7f3e8"))
	_box(Vector3(0,-1.15,-.15),Vector3(7,.18,3.9),Color("ede9dc"))
	for y in [1.35]:
		_box(Vector3(0,y,-.55),Vector3(6.55,.10,2.7),Color("b8cdcf"))
		_box(Vector3(0,y+.055,.81),Vector3(6.55,.045,.075),Color("effbfa"))
		_box(Vector3(0,y-.10,-1.86),Vector3(6.45,.045,.035),Color("b4c6c6"))
	# Bottom drawer and cake zone. The translucent face is intentionally below the cake.
	_box(Vector3(0,-1.0,.1),Vector3(6.3,.10,2.9),Color("c4d5d4"))
	_box(Vector3(0,-.22,.1),Vector3(6.3,.08,2.9),Color("e3edeb"))
	var drawer:=MeshInstance3D.new();var face:=BoxMesh.new();face.size=Vector3(6.1,.72,.06);drawer.mesh=face;drawer.position=Vector3(0,-.61,1.58);stage.add_child(drawer)
	var glass:=StandardMaterial3D.new();glass.albedo_color=Color(.57,.72,.75,.42);glass.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;glass.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;drawer.material_override=glass
	for x in [-3.12,3.12]:_box(Vector3(x,-.60,1.58),Vector3(.10,.88,.12),Color("f0f4ee"))
	_box(Vector3(0,-1.03,1.59),Vector3(6.35,.08,.10),Color("f0f4ee"))
	_box(Vector3(0,-.19,1.59),Vector3(6.35,.06,.10),Color("f0f4ee"))
	_box(Vector3(0,-.38,1.65),Vector3(1.0,.07,.08),Color("a0b8b9"))
	# A narrow open door rack gives a recognizable silhouette without competing with food.
	for y in [.2,1.65]:
		_box(Vector3(3.62,y,.9),Vector3(.46,.10,1.4),Color("d3e1de"))
		_box(Vector3(3.86,y+.20,.9),Vector3(.05,.40,1.4),Color("e8efeb"))
	_box(Vector3(0,3.38,-1.48),Vector3(4.8,.065,.16),Color("f4ffff"))
	var light:=OmniLight3D.new();light.position=Vector3(0,3.2,.1);light.light_color=Color("e1f3f5");light.light_energy=.6;light.omni_range=6;stage.add_child(light)

func _unhandled_input(event:InputEvent)->void:
	# GUI consumes panel/button clicks first. Only the active scene may pick food.
	if not visible or not root.visible or get_parent().mode!="CLOSEUP":return
	if event is not InputEventMouseButton or not event.pressed or event.button_index!=MOUSE_BUTTON_LEFT:return
	var camera:=get_viewport().get_camera_3d()
	var origin:=camera.project_ray_origin(event.position)
	var direction:=camera.project_ray_normal(event.position)
	var best:=-1
	var distance:=INF
	for i in sprites.size():
		if current.id=="fridge" and current.items[i].id=="cake":continue
		for item in sprites[i].find_children("*","GeometryInstance3D",true,false):
			var hit:Variant=null
			if item is Sprite3D:
				var normal:Vector3=camera.global_basis.z.normalized()
				hit=Plane(normal,item.global_position).intersects_ray(origin,direction)
				if hit==null:continue
				var offset:Vector3=hit-item.global_position
				var width:float=item.texture.get_width()*item.pixel_size*sprites[i].scale.x
				var height:float=item.texture.get_height()*item.pixel_size*sprites[i].scale.y
				var u:float=offset.dot(camera.global_basis.x.normalized())/width+.5
				var v:float=.5-offset.dot(camera.global_basis.y.normalized())/height
				if u<0 or u>=1 or v<0 or v>=1:continue
				var mask:Image=item.get_meta("pick_image")
				if mask.get_pixel(int(u*mask.get_width()),int(v*mask.get_height())).a<.15:continue
			elif item is MeshInstance3D:
				var inverse:Transform3D=item.global_transform.affine_inverse()
				var local_hit:Variant=item.mesh.get_aabb().intersects_ray(inverse*origin,inverse.basis*direction)
				if local_hit!=null:hit=item.global_transform*local_hit
			if hit!=null and origin.distance_to(hit)<distance:
				distance=origin.distance_to(hit);best=i
	if best>=0:
		selected=best;remembered[current.id]=selected;refresh()
		get_viewport().set_input_as_handled()
