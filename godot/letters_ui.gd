extends CanvasLayer
## A book-shaped reading surface. Content stays in original paragraph order.
signal close_requested
signal crown_changed
var FONT: Font = preload("res://assets/NotoSansSC-Reading.ttf")
const INK = Color("403b32")
var catalog: Dictionary
var articles: Array
var pages: Dictionary = {}
var article_index := 0
var page_index := 0
var crown_available := false
var crown_owned := false
var crown_worn := false
var current_view := ""
var root: Control
var book: Panel
var left: VBoxContainer
var right: VBoxContainer
var title: Label
var footer: Label
var claim: Button
var back: Button
var next: Button
var inventory: Panel
var wear_button: Button
var state_label: Label
var portrait_crown: Node3D
var index_visible := true

func _ready() -> void:
	FONT.fallbacks=[load("res://assets/NotoEmoji-Reading.ttf")]
	catalog = JSON.parse_string(FileAccess.get_file_as_string("res://content/letters/catalog.json"))
	articles = catalog.articles
	for article in articles:
		pages[article.id] = _paginate(article.blocks)
	_build()
	root.hide()

func _style(color: Color, border := Color.TRANSPARENT, radius := 3) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = border
	s.set_border_width_all(1 if border.a > 0 else 0)
	s.set_corner_radius_all(radius)
	return s

func _button(text_: String, parent: Node, action: Callable) -> Button:
	var b := Button.new()
	b.text = text_
	b.custom_minimum_size.y = 38
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", Color("7b442d"))
	b.add_theme_color_override("font_focus_color", INK)
	b.add_theme_stylebox_override("normal", _style(Color("ece1c9"),Color("cbbd9e")))
	b.add_theme_stylebox_override("hover", _style(Color("fff5de"),Color("a78c57")))
	b.add_theme_stylebox_override("focus", _style(Color("f6ead1"),Color("9b6d36")))
	b.pressed.connect(action)
	parent.add_child(b)
	return b

func _label(text_: String, size_: int, parent: Node) -> Label:
	var l := Label.new()
	l.text = text_
	l.add_theme_font_size_override("font_size", size_)
	l.add_theme_color_override("font_color",INK)
	parent.add_child(l)
	return l

func _build() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var theme := Theme.new()
	theme.default_font = FONT
	theme.default_font_size = 18
	root.theme = theme
	add_child(root)
	book = Panel.new()
	book.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	book.position = Vector2(-480,-255)
	book.size = Vector2(960,540)
	var cover := _style(Color("263e35"),Color("b6a174"),7)
	cover.shadow_color=Color(0,0,0,.35);cover.shadow_size=18;cover.shadow_offset=Vector2(0,12)
	book.add_theme_stylebox_override("panel",cover)
	root.add_child(book)
	for pos in [Vector2(12,12),Vector2(482,12)]:
		var paper := Panel.new()
		paper.position=pos;paper.size=Vector2(466,516)
		paper.add_theme_stylebox_override("panel",_style(Color("f6efdc"),Color("d4c7aa")))
		book.add_child(paper)
	var seam := ColorRect.new()
	seam.color=Color("d0c2a4");seam.position=Vector2(477,14);seam.size=Vector2(6,510);seam.mouse_filter=Control.MOUSE_FILTER_IGNORE
	book.add_child(seam)
	title=_label("情书收藏",23,book);title.position=Vector2(40,28);title.size=Vector2(610,32);title.clip_text=true
	left=VBoxContainer.new();left.position=Vector2(40,82);left.size=Vector2(410,370);left.add_theme_constant_override("separation",5);book.add_child(left)
	right=VBoxContainer.new();right.position=Vector2(510,82);right.size=Vector2(410,370);right.add_theme_constant_override("separation",5);book.add_child(right)
	var index_button := _button("目录",book,show_index);index_button.position=Vector2(40,478);index_button.size.x=80
	back=_button("← 上一页",book,turn.bind(-1));back.position=Vector2(135,478);back.size.x=130
	next=_button("下一页 →",book,turn.bind(1));next.position=Vector2(775,478);next.size.x=145
	footer=_label("",14,book);footer.position=Vector2(280,489);footer.size=Vector2(470,22);footer.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var bookmark := _button("王冠\n书签",book,open_crown_article)
	bookmark.position=Vector2(946,52);bookmark.size=Vector2(72,100)
	bookmark.add_theme_stylebox_override("normal",_style(Color("793b45"),Color("ac7e61"),2))
	bookmark.add_theme_color_override("font_color",Color("fff0d0"))
	claim=_button("领取王冠",book,claim_crown);claim.position=Vector2(675,28);claim.size=Vector2(215,38)
	var close := _button("返回小屋  Esc",root,func(): close_requested.emit())
	close.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	close.offset_left=-85;close.offset_top=22;close.offset_right=85;close.offset_bottom=60
	_build_inventory()

func _paginate(blocks: Array) -> Array:
	var result: Array = []
	var buffer := ""
	for block in blocks:
		if block.type == "image":
			if not buffer.is_empty(): result.append({"type":"text","text":buffer});buffer=""
			result.append(block)
			continue
		var remaining: String = block.text
		if not buffer.is_empty(): remaining="\n\n"+remaining
		while not remaining.is_empty():
			var low:=0
			var high:=remaining.length()
			while low < high:
				var mid:=int((low+high+1)/2)
				var height:=FONT.get_multiline_string_size(buffer+remaining.left(mid),HORIZONTAL_ALIGNMENT_LEFT,410,20,-1,TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE).y
				if height <= 350: low=mid
				else: high=mid-1
			if low==0:
				result.append({"type":"text","text":buffer});buffer=""
				continue
			buffer+=remaining.left(low);remaining=remaining.substr(low)
			if not remaining.is_empty():result.append({"type":"text","text":buffer});buffer=""
	if not buffer.is_empty():result.append({"type":"text","text":buffer})
	return result

func _clear_pages() -> void:
	for column in [left,right]:
		for child in column.get_children(): column.remove_child(child);child.queue_free()

func show_reader() -> void:
	current_view="reading";root.show();book.show();inventory.hide()
	if index_visible: show_index()
	else: _render_article()

func hide_all() -> void:
	current_view="";root.hide()

func show_index() -> void:
	index_visible=true;_clear_pages();title.text="情书收藏 · 目录";claim.hide();back.hide();next.hide()
	footer.text="%d 篇来信 · 点击篇名翻开" % articles.size()
	for i in articles.size():
		var marker := "  · 王冠" if articles[i].id==catalog.crown_article_id else ""
		var b:=_button("%02d  %s%s" % [i+1,articles[i].title,marker],left if i<8 else right,open_article.bind(i,0))
		b.alignment=HORIZONTAL_ALIGNMENT_LEFT;b.clip_text=true;b.tooltip_text=articles[i].title
		b.add_theme_font_size_override("font_size",17)

func open_article(index_: int, page_: int = 0) -> void:
	article_index=index_;page_index=page_;index_visible=false
	if articles[index_].id==catalog.crown_article_id: crown_available=true
	_render_article()

func open_crown_article() -> void:
	for i in articles.size():
		if articles[i].id==catalog.crown_article_id:open_article(i);return

func _render_page(page: Dictionary, column: VBoxContainer) -> void:
	if page.type=="image":
		var image:=TextureRect.new();image.texture=load(page.path);image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;image.custom_minimum_size=Vector2(410,350);column.add_child(image)
	else:
		var body:=_label(page.text,20,column);body.custom_minimum_size=Vector2(410,350)
		body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		body.add_theme_constant_override("line_spacing",0)

func _render_article() -> void:
	_clear_pages()
	var article: Dictionary=articles[article_index]
	var article_pages: Array=pages[article.id]
	title.text=article.title;title.add_theme_font_size_override("font_size",20)
	_render_page(article_pages[page_index],left)
	if page_index+1<article_pages.size():_render_page(article_pages[page_index+1],right)
	footer.text="%d / %d 篇 · 第 %d–%d / %d 页" % [article_index+1,articles.size(),page_index+1,mini(page_index+2,article_pages.size()),article_pages.size()]
	back.show();next.show();back.disabled=article_index==0 and page_index==0
	next.disabled=article_index==articles.size()-1 and page_index+2>=article_pages.size()
	claim.visible=article.id==catalog.crown_article_id and not crown_owned

func turn(direction: int) -> void:
	if index_visible:
		if direction>0:open_article(0)
		return
	var count: int=pages[articles[article_index].id].size()
	if direction>0:
		if page_index+2<count:page_index+=2
		elif article_index+1<articles.size():open_article(article_index+1);return
	else:
		if page_index>=2:page_index-=2
		elif article_index>0:
			var previous:=article_index-1
			open_article(previous,int((pages[articles[previous].id].size()-1)/2)*2)
			return
	_render_article()

func claim_crown() -> void:
	if not crown_available or crown_owned:return
	crown_owned=true;crown_worn=true;claim.hide();crown_changed.emit()
	footer.text="王冠已戴上 · 合上书，看看现在的自己"

func _build_inventory() -> void:
	inventory=Panel.new();inventory.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	inventory.position=Vector2(-320,-235);inventory.size=Vector2(640,470)
	inventory.add_theme_stylebox_override("panel",_style(Color("f4ecd8"),Color("b5a27b"),8));root.add_child(inventory)
	_label("随身珍藏",28,inventory).position=Vector2(35,28)
	_label("王冠",24,inventory).position=Vector2(330,130)
	state_label=_label("",18,inventory);state_label.position=Vector2(330,178);state_label.size=Vector2(280,90)
	state_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	wear_button=_button("",inventory,toggle_crown);wear_button.position=Vector2(330,292);wear_button.size=Vector2(220,48)
	_label("B / Esc 返回小屋",16,inventory).position=Vector2(35,420)
	var container:=SubViewportContainer.new();container.position=Vector2(25,85);container.size=Vector2(275,320);container.stretch=true;inventory.add_child(container)
	var viewport:=SubViewport.new();viewport.size=Vector2i(275,320);viewport.transparent_bg=true;viewport.own_world_3d=true;container.add_child(viewport)
	var model:Node3D=load("res://assets/character.glb").instantiate();viewport.add_child(model);model.rotation.y=.35
	var skeleton:Skeleton3D=model.find_children("*","Skeleton3D",true,false)[0]
	var attachment:=BoneAttachment3D.new();attachment.bone_name="Head";skeleton.add_child(attachment)
	portrait_crown=load("res://assets/stage1/crown.glb").instantiate();attachment.add_child(portrait_crown);portrait_crown.position=Vector3(0,.19,0)
	var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-35,-30,0);light.light_energy=1.8;viewport.add_child(light)
	var environment:=WorldEnvironment.new();environment.environment=Environment.new();environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.environment.ambient_light_color=Color("fff0dc");environment.environment.ambient_light_energy=.7;viewport.add_child(environment)
	var camera:=Camera3D.new();viewport.add_child(camera);camera.position=Vector3(0,1.0,3);camera.look_at(Vector3(0,.85,0));camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=2.0

func show_inventory() -> void:
	current_view="inventory";root.show();book.hide();inventory.show();_refresh_inventory()

func _refresh_inventory() -> void:
	state_label.text="已佩戴 · 它就在你头上" if crown_worn else "已珍藏 · 随时可以戴上" if crown_owned else "还有一份礼物，藏在书房的情书里。"
	wear_button.visible=crown_owned;wear_button.text="取下王冠" if crown_worn else "佩戴王冠";portrait_crown.visible=crown_worn

func toggle_crown() -> void:
	if not crown_owned:return
	crown_worn=not crown_worn;_refresh_inventory();crown_changed.emit()

func snapshot() -> Dictionary:
	return {"view":current_view,"index":index_visible,"article":articles[article_index].id,"page":page_index,"articles":articles.size(),"crown_available":crown_available,"crown_owned":crown_owned,"crown_worn":crown_worn,"page_counts":pages.keys().map(func(id):return pages[id].size())}
