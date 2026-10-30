extends CanvasLayer
signal close_requested
const Timeline=preload("res://album_timeline.gd")
const INK=Color("594737")
var data:Dictionary
var page_index:=0
var root:Control
var book:Panel
var page_area:HBoxContainer
var timeline:Control
var title:Label
var footer:Label
var previous:Button
var next:Button
var FONT:Font=preload("res://assets/NotoSansSC-Reading.ttf")

func _ready()->void:
	data=JSON.parse_string(FileAccess.get_file_as_string("res://content/album/album.json"))
	root=Control.new();add_child(root)
	var theme:=Theme.new();theme.default_font=FONT;theme.default_font_size=16;root.theme=theme
	book=Panel.new();root.add_child(book)
	book.size=Vector2(1120,640);_layout()
	get_viewport().size_changed.connect(_layout)
	book.add_theme_stylebox_override("panel",style(Color("e5d1b3"),Color("a58b6b"),10))
	title=label("我们的时间",24,book);title.position=Vector2(35,18)
	var close:=button("合上相册  Esc",book,func():close_requested.emit());close.position=Vector2(930,14);close.size=Vector2(160,38)
	page_area=HBoxContainer.new();page_area.position=Vector2(20,62);page_area.size=Vector2(1080,400);page_area.add_theme_constant_override("separation",8);book.add_child(page_area)
	timeline=Timeline.new();timeline.position=Vector2(28,470);timeline.size=Vector2(1064,120);book.add_child(timeline);timeline.setup(data);timeline.selected.connect(open_page)
	previous=button("← 上一页",book,turn.bind(-1));previous.position=Vector2(32,590);previous.size=Vector2(140,36)
	next=button("下一页 →",book,turn.bind(1));next.position=Vector2(948,590);next.size=Vector2(140,36)
	footer=label("",16,book);footer.position=Vector2(182,598);footer.size=Vector2(750,24);footer.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	root.hide()

func _layout()->void:
	root.size=get_viewport().get_visible_rect().size
	book.position=(root.size-book.size)/2

func style(color:Color,border:=Color.TRANSPARENT,radius:=2)->StyleBoxFlat:
	var s:=StyleBoxFlat.new();s.bg_color=color;s.border_color=border;s.set_border_width_all(1);s.set_corner_radius_all(radius)
	return s

func label(text:String,font_size:int,parent:Node)->Label:
	var l:=Label.new();l.text=text;l.add_theme_font_size_override("font_size",font_size);l.add_theme_color_override("font_color",INK);parent.add_child(l);return l

func button(text:String,parent:Node,action:Callable)->Button:
	var b:=Button.new();b.text=text;b.add_theme_color_override("font_color",INK)
	b.add_theme_stylebox_override("normal",style(Color("f8efdf"),Color("c5ac89"),5))
	b.add_theme_stylebox_override("hover",style(Color("fff9ed"),Color("a47a4f"),5))
	b.pressed.connect(action);parent.add_child(b);return b

func show_reader()->void:
	root.show();open_page(page_index,false)

func hide_reader()->void:
	timeline.stop();root.hide()

func turn(direction:int)->void:
	open_page(clampi(page_index+direction,0,data.pages.size()-1))

func open_page(index:int,animate:=true)->void:
	page_index=clampi(index,0,data.pages.size()-1)
	var page:Dictionary=data.pages[page_index]
	for child in page_area.get_children():page_area.remove_child(child);child.queue_free()
	for side in 2:_spread(page.spreads[side],str(page.kind),side)
	title.text="我们的时间  ·  "+str(page.short)
	footer.text=str(page.date)+"    ·    "+str(page_index+1)+" / "+str(data.pages.size())+("    ·    年份待核实" if page.get("draft",false) else "")
	previous.disabled=page_index==0;next.disabled=page_index==data.pages.size()-1
	timeline.show_page(page_index,animate)

func _spread(spread:Dictionary,kind:String,side:int)->void:
	var panel:=PanelContainer.new();panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var paper:=style(Color("fbf4e6"),Color("dac8ae"),2)
	paper.content_margin_left=25;paper.content_margin_right=25;paper.content_margin_top=15;paper.content_margin_bottom=15
	panel.add_theme_stylebox_override("panel",paper);page_area.add_child(panel)
	var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;panel.add_child(scroll)
	var column:=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",9);scroll.add_child(column)
	var eyebrow:=label(str(spread.get("eyebrow","")),12,column);eyebrow.add_theme_color_override("font_color",Color("a38b70"))
	var photos:=0
	for block in spread.blocks:
		if block.type=="photo":photos+=1
	if kind=="marriage" and side==0:
		var red:=PanelContainer.new();red.add_theme_stylebox_override("panel",style(Color("a33c42"),Color("bc7365"),4));column.add_child(red)
		var xi:=label("囍",64,red);xi.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;xi.add_theme_color_override("font_color",Color("fff0ce"))
	var collage:Control
	var photo_index:=0
	var chip_row:HFlowContainer
	var tile_row:HBoxContainer
	for block in spread.blocks:
		var block_class:=str(block.get("class_name",""))
		if block_class=="chip":
			if not chip_row:chip_row=HFlowContainer.new();column.add_child(chip_row);chip_row.add_theme_constant_override("h_separation",12)
			label(str(block.text),16,chip_row);continue
		if block_class=="tile":
			if not tile_row:tile_row=HBoxContainer.new();column.add_child(tile_row);tile_row.add_theme_constant_override("separation",10)
			var tile:=PanelContainer.new();tile.custom_minimum_size=Vector2(44,40);tile.add_theme_stylebox_override("panel",style(Color("e5cba4"),Color("c3a279"),4));tile_row.add_child(tile)
			var value:=label(str(block.text),20,tile);value.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;continue
		match str(block.type):
			"photo":
				var frame:=PanelContainer.new();frame.add_theme_stylebox_override("panel",style(Color("fffaf0"),Color("d8c6ae"),2))
				if photos>1:
					if not collage:collage=Control.new();collage.custom_minimum_size.y=250;column.add_child(collage)
					collage.add_child(frame);frame.position=Vector2(8,8) if photo_index==0 else Vector2(208,65);frame.size=Vector2(250,175);frame.rotation=deg_to_rad(-3 if photo_index==0 else 3)
				else:column.add_child(frame)
				photo_index+=1
				var inner:=VBoxContainer.new();frame.add_child(inner)
				var image:=TextureRect.new();image.texture=load(str(data.assets[block.asset]));image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;image.custom_minimum_size=Vector2(0,110 if kind=="proposal" else 160 if photos<2 else 145);inner.add_child(image)
				var caption:=label(str(block.get("caption","")),13,inner);caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			"blank":
				var variant:=str(block.get("variant","polaroid"))
				var center:=CenterContainer.new();column.add_child(center)
				var frame:=PanelContainer.new();frame.custom_minimum_size=Vector2(160 if variant=="phone" else 330,215 if variant=="phone" else 180)
				var frame_style:=style(Color("deddd5") if variant=="film" else Color("f8f3e8"),Color("77746b") if variant=="phone" else Color("d6c6ae"),22 if variant=="phone" else 2)
				frame_style.set_border_width_all(5 if variant=="phone" else 9)
				if variant=="polaroid":frame_style.border_width_bottom=28
				frame.add_theme_stylebox_override("panel",frame_style);center.add_child(frame)
				var words:=label(str(block.get("text","这一刻没有照片")),16,frame);words.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;words.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;words.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			_:
				var text:=str(block.get("text","")).replace("❜❜ ","")
				if text.is_empty():continue
				if kind=="travel" and block.type=="text":text=text.replace("开玩笑。","开玩笑。\n")
				var parent:Node=column
				if block.type=="quote" or (block.type=="note" and str(block.get("class_name","")) in ["memo","private-note","steps-memo"]):
					var memo:=PanelContainer.new();var memo_style:=style(Color("f0e5d2"),Color.TRANSPARENT,3);memo_style.content_margin_left=12;memo_style.content_margin_right=12;memo_style.content_margin_top=8;memo_style.content_margin_bottom=8;memo.add_theme_stylebox_override("panel",memo_style);column.add_child(memo);parent=memo
				var words:=label(text,60 if text=="2016." else 25 if block.type=="heading" else 16,parent);words.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
				if str(block.get("class_name","")) in ["footnote","date-tag"]:words.add_theme_color_override("font_color",Color("9c8064"))

func snapshot()->Dictionary:
	return {"visible":root.visible,"index":page_index,"id":data.pages[page_index].id,"pages":data.pages.size(),"zoom":timeline.zoom,"cursor":timeline.cursor,"timeline":timeline.snapshot()}
