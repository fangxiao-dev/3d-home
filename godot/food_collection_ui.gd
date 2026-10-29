extends CanvasLayer
signal close_requested
const Sheet=preload("res://food_collection_sheet.gd")
const FONT=preload("res://assets/NotoSansSC-Reading.ttf")
var root:Control
var book:Panel
var sheet:Control
var close_button:Button
var title:Label
var subtitle:Label
var blur:ColorRect
var backdrop:Button
var detail:Panel
var detail_image:TextureRect
var detail_title:Label
var description:Label
var draft_label:Label
var draft_note:Label
var detail_close:Button
var content:Dictionary={}
var layout:Array=[]
var detail_id:=""

func _ready()->void:
	layer=10;root=Control.new();add_child(root)
	var dim:=ColorRect.new();dim.color=Color(.08,.06,.03,.22);dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.add_child(dim)
	book=Panel.new();book.size=Vector2(1000,620);book.add_theme_stylebox_override("panel",paper());root.add_child(book)
	sheet=Sheet.new();sheet.size=Vector2(1000,620);book.add_child(sheet);sheet.item_selected.connect(show_detail)
	title=label(26,book);title.position=Vector2(40,20);title.size=Vector2(740,36)
	subtitle=label(12,book);subtitle.position=Vector2(42,57);subtitle.add_theme_color_override("font_color",Color("a18a70"))
	close_button=button("合上图鉴 Esc",book);close_button.position=Vector2(842,20);close_button.size=Vector2(136,36);close_button.pressed.connect(func():close_requested.emit())
	blur=ColorRect.new();blur.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var material:=ShaderMaterial.new();material.shader=preload("res://food_collection_blur.gdshader");blur.material=material;root.add_child(blur);blur.hide()
	backdrop=Button.new();backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);backdrop.focus_mode=Control.FOCUS_NONE
	for state in ["normal","hover","pressed","focus"]:backdrop.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	root.add_child(backdrop);backdrop.pressed.connect(hide_detail);backdrop.hide()
	detail=Panel.new();detail.add_theme_stylebox_override("panel",paper());detail.mouse_filter=Control.MOUSE_FILTER_STOP;root.add_child(detail);detail.hide()
	detail_image=TextureRect.new();detail_image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;detail_image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;detail_image.mouse_filter=Control.MOUSE_FILTER_IGNORE;detail.add_child(detail_image)
	draft_label=label(12,detail);draft_label.text="示意文案";draft_label.add_theme_color_override("font_color",Color("a0805e"))
	detail_title=label(28,detail);detail_title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	description=label(17,detail);description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	draft_note=label(12,detail);draft_note.text="游戏式介绍示意，不是聊天原话。";draft_note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;draft_note.add_theme_color_override("font_color",Color("a28d76"))
	detail_close=button("关闭 ×",detail);detail_close.pressed.connect(hide_detail)
	get_viewport().size_changed.connect(_layout);_layout();root.hide()

func paper()->StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=Color("fff8eb");style.border_color=Color("d4bfa3");style.set_border_width_all(1);style.set_corner_radius_all(18);return style

func label(font_size:int,parent:Node)->Label:
	var value:=Label.new();value.add_theme_font_override("font",FONT);value.add_theme_font_size_override("font_size",font_size);value.add_theme_color_override("font_color",Color("49372a"));value.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(value);return value

func button(text:String,parent:Node)->Button:
	var value:=Button.new();value.text=text;value.add_theme_font_override("font",FONT);value.add_theme_font_size_override("font_size",16);value.focus_mode=Control.FOCUS_ALL;parent.add_child(value);return value

func setup(data:Dictionary)->void:
	content=data;layout=JSON.parse_string(FileAccess.get_file_as_string("res://content/food-collection/layout-single-page.json"))
	title.text=content.title;subtitle.text=content.subtitle
	sheet.setup(content.items,layout);_layout()

func _layout()->void:
	if not book:return
	var viewport:=get_viewport().get_visible_rect().size;root.size=viewport
	var factor:float=minf(viewport.x*.88/1000,viewport.y*.84/620)
	book.scale=Vector2.ONE*factor;book.position=(viewport-Vector2(1000,620)*factor)/2
	blur.position=book.position;blur.size=Vector2(1000,620)*factor
	var narrow:=viewport.x<650
	detail.size=Vector2(minf(780,viewport.x*.88),minf(410 if not narrow else 570,viewport.y*.86))
	detail.position=(viewport-detail.size)/2
	detail_close.position=Vector2(detail.size.x-102,12);detail_close.size=Vector2(88,36)
	var text_x:float=detail.size.x*.46 if not narrow else 24.0
	var text_width:float=detail.size.x-text_x-32
	detail_image.position=Vector2(24,62);detail_image.size=Vector2(detail.size.x*.39,detail.size.y-98) if not narrow else Vector2(detail.size.x-48,160)
	var text_y:float=72 if not narrow else 228
	draft_label.position=Vector2(text_x,text_y);draft_label.size=Vector2(text_width,20)
	detail_title.position=Vector2(text_x,text_y+25);detail_title.size=Vector2(text_width,77)
	description.position=Vector2(text_x,text_y+112);description.size=Vector2(text_width,112)
	draft_note.position=Vector2(text_x,text_y+238);draft_note.size=Vector2(text_width,44)

func show_collection()->void:
	root.show();_layout()
	# Reopening preserves the chosen sticker, but an initial open shows only artwork.
	if not sheet.selected_id.is_empty():sheet.focus_item(sheet.selected_id)

func hide_collection()->void:
	if not detail_id.is_empty():hide_detail()
	root.hide()

func show_detail(id:String)->void:
	if not sheet.items.has(id):return
	detail_id=id;sheet.selected_id=id
	var item:Dictionary=sheet.items[id]
	detail_image.texture=sheet.textures[id];detail_title.text=item.name;description.text=item.description
	draft_label.visible=bool(item.draft);draft_note.visible=bool(item.draft)
	sheet.set_interactive(false);close_button.disabled=true
	blur.show();backdrop.show();detail.show();detail_close.grab_focus();_layout()

func hide_detail()->void:
	if detail_id.is_empty():return
	var id:=detail_id;detail_id="";detail.hide();blur.hide();backdrop.hide()
	close_button.disabled=false;sheet.set_interactive(true);sheet.focus_item(id)

func handle_key(code:int,shift:bool=false)->void:
	if not detail_id.is_empty():
		if code==KEY_ESCAPE or code==KEY_ENTER or code==KEY_KP_ENTER:hide_detail()
		return
	if code==KEY_ESCAPE:close_requested.emit()
	elif code in [KEY_TAB,KEY_RIGHT,KEY_DOWN]:sheet.cycle_focus(-1 if shift else 1)
	elif code in [KEY_LEFT,KEY_UP]:sheet.cycle_focus(-1)
	elif code in [KEY_ENTER,KEY_KP_ENTER] and not sheet.selected_id.is_empty():show_detail(sheet.selected_id)
