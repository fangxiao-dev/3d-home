extends Control
signal item_selected(id:String)
const FONT=preload("res://assets/NotoSansSC-Reading.ttf")
var items:Dictionary={}
var placements:Array=[]
var textures:Dictionary={}
var buttons:Dictionary={}
var selected_id:=""
var hovered_id:=""
var interactive:=true
var found:Dictionary={}
var silhouettes:Dictionary={}

func setup(catalog:Array,layout:Array)->void:
	placements=layout
	for item in catalog:
		items[item.id]=item
		textures[item.id]=load("res://content/food-collection/images/"+item.image)
		var silhouette:Image=textures[item.id].get_image()
		if silhouette.is_compressed():silhouette.decompress()
		silhouette.resize(256, maxi(1,int(256.0*silhouette.get_height()/silhouette.get_width())), Image.INTERPOLATE_LANCZOS)
		for y in silhouette.get_height():
			for x in silhouette.get_width():
				var alpha:=silhouette.get_pixel(x,y).a
				silhouette.set_pixel(x,y,Color(.72,.65,.55,alpha*.19))
		silhouettes[item.id]=ImageTexture.create_from_image(silhouette)
	for placement in placements:
		var id:String=placement.id
		var button:=Button.new()
		button.flat=true;button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
		button.position=Vector2(placement.x-placement.w/2,placement.y-placement.h/2)
		button.size=Vector2(placement.w,placement.h)
		button.focus_mode=Control.FOCUS_ALL
		for state in ["normal","hover","pressed","focus","disabled"]:button.add_theme_stylebox_override(state,StyleBoxEmpty.new())
		button.mouse_entered.connect(func():hovered_id=id;queue_redraw())
		button.mouse_exited.connect(func():hovered_id="";queue_redraw())
		button.focus_entered.connect(func():selected_id=id;queue_redraw())
		button.focus_exited.connect(queue_redraw)
		button.pressed.connect(func():selected_id=id;item_selected.emit(id))
		add_child(button);buttons[id]=button
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func set_interactive(value:bool)->void:
	interactive=value;hovered_id=""
	for button in buttons.values():button.disabled=not value or not found.has(buttons.find_key(button))
	queue_redraw()

func set_found(ids:Dictionary)->void:
	found=ids;set_interactive(interactive)

func focus_item(id:String)->void:
	if buttons.has(id) and found.has(id):selected_id=id;buttons[id].grab_focus();queue_redraw()

func cycle_focus(step:int)->void:
	var ids:Array=placements.filter(func(p):return found.has(p.id)).map(func(p):return p.id)
	if ids.is_empty():return
	var current:int=ids.find(selected_id)
	if current<0 and step<0:current=0
	focus_item(ids[posmod(current+step,ids.size())])

func active_label()->String:
	if not interactive:return ""
	if not hovered_id.is_empty():return hovered_id
	if buttons.has(selected_id) and buttons[selected_id].has_focus():return selected_id
	return ""

func _draw()->void:
	var paper:=StyleBoxFlat.new();paper.bg_color=Color("fff8e9");paper.set_corner_radius_all(18)
	draw_style_box(paper,Rect2(Vector2.ZERO,Vector2(1000,620)))
	for i in 1200:
		draw_circle(Vector2(fmod(i*71.13,1000),fmod(i*131.71,620)),.6,Color(.65,.47,.24,.045))
	for p in placements:
		var bounds:Array=p.bounds
		var factor:float=float(p.w)/float(bounds[2])
		draw_set_transform(Vector2(p.x,p.y),deg_to_rad(float(p.angle)))
		var corner:=Vector2(-float(p.w)/2,-float(p.h)/2)-Vector2(bounds[0],bounds[1])*factor
		draw_texture_rect(textures[p.id] if found.has(p.id) else silhouettes[p.id],Rect2(corner,Vector2(p.imageWidth,p.imageHeight)*factor),false)
	draw_set_transform(Vector2.ZERO)
	var id:=active_label()
	if not id.is_empty() and found.has(id):
		for p in placements:
			if p.id!=id:continue
			var text:String=items[id].name
			var width:float=FONT.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,15).x+24
			var y:float=p.y-p.h/2-36
			if p.band in ["top","bottom"]:y=p.y+p.h/2+9
			var x:float=clampf(p.x-width/2,8,992-width)
			y=clampf(y,72,581)
			draw_style_box(_label_style(),Rect2(x,y,width,28))
			draw_string(FONT,Vector2(x+12,y+20),text,HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("fff8ed"))

func _label_style()->StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=Color("5b4639");style.set_corner_radius_all(7);return style
