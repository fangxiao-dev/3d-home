extends CanvasLayer
signal close_requested
const Game = preload("res://game_2048.gd")
var game = Game.new()
var overlay: Control
var panel: PanelContainer
var score_label: Label
var status_label: Label
var tiles: Array[Label]=[]
var restart_button: Button
var confirmation: VBoxContainer
var cancel_button: Button
var continue_button: Button
var active:=false
var paused:=false
var busy:=false
var tile_tween: Tween
var moving_layer: Control
var result_panel: PanelContainer
var result_title: Label
var result_scores: Label
var result_restart: Button
var result_continue: Button
var win_acknowledged:=false
var record_message:=""

func style(color: String, padding:=0) -> StyleBoxFlat:
	var box:=StyleBoxFlat.new();box.bg_color=Color(color);box.set_corner_radius_all(10)
	box.content_margin_left=padding;box.content_margin_right=padding;box.content_margin_top=padding;box.content_margin_bottom=padding
	return box

func label(text_: String, size_: int, parent: Node) -> Label:
	var node:=Label.new();node.text=text_;node.add_theme_font_size_override("font_size",size_);node.add_theme_color_override("font_color",Color("564b40"));parent.add_child(node);return node

func button(text_: String, parent: Node, action: Callable) -> Button:
	var node:=Button.new();node.text=text_;node.custom_minimum_size.y=42;node.add_theme_font_size_override("font_size",18)
	node.add_theme_stylebox_override("normal",style("e6dac5",8));node.add_theme_stylebox_override("hover",style("f2e7d6",8))
	node.add_theme_color_override("font_color",Color("564b40"));node.add_theme_color_override("font_hover_color",Color("564b40"));node.add_theme_color_override("font_focus_color",Color("564b40"));node.add_theme_color_override("font_pressed_color",Color("564b40"));node.pressed.connect(action);parent.add_child(node);return node

func _ready() -> void:
	layer=10
	overlay=Control.new();overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(overlay)
	var theme:=Theme.new();theme.default_font=load("res://assets/NotoSansSC-Reading.ttf");overlay.theme=theme
	var center:=CenterContainer.new();center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);overlay.add_child(center)
	panel=PanelContainer.new();panel.custom_minimum_size=Vector2(460,0);panel.add_theme_stylebox_override("panel",style("f6f0e4",24));center.add_child(panel)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",12);panel.add_child(column)
	var header:=HBoxContainer.new();column.add_child(header)
	var title:=label("2048",40,header);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	score_label=label("分数  0",22,header);score_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	var board:=Control.new();board.custom_minimum_size=Vector2(408,368);column.add_child(board)
	var grid:=GridContainer.new();grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);grid.columns=4;grid.add_theme_constant_override("h_separation",8);grid.add_theme_constant_override("v_separation",8);board.add_child(grid)
	for i in 16:
		var tile:=label("",30,grid);tile.custom_minimum_size=Vector2(96,86);tile.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;tile.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;tiles.append(tile)
	moving_layer=Control.new();moving_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);moving_layer.mouse_filter=Control.MOUSE_FILTER_IGNORE;board.add_child(moving_layer)
	result_panel=PanelContainer.new();result_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);board.add_child(result_panel)
	var result_center:=CenterContainer.new();result_panel.add_child(result_center)
	var result_column:=VBoxContainer.new();result_column.add_theme_constant_override("separation",14);result_center.add_child(result_column)
	result_title=label("",36,result_column);result_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	result_scores=label("",20,result_column);result_scores.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	result_restart=button("",result_column,restart)
	result_restart.custom_minimum_size.x=220
	result_restart.add_theme_stylebox_override("normal",style("897561",10))
	result_restart.add_theme_stylebox_override("hover",style("a28b70",10))
	for state in ["font_color","font_hover_color","font_focus_color","font_pressed_color"]:result_restart.add_theme_color_override(state,Color("fff9ed"))
	result_continue=button("继续挑战",result_column,continue_after_win)
	result_panel.hide()
	status_label=label("",18,column);status_label.custom_minimum_size.y=28
	var hint:=label("方向键 / WASD · Enter 确认 · Esc 返回",16,column);hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	restart_button=button("重新开始",column,request_restart)
	confirmation=VBoxContainer.new();confirmation.add_theme_constant_override("separation",8);column.add_child(confirmation)
	label("重新开始？当前棋局将清空。",18,confirmation)
	var actions:=HBoxContainer.new();actions.add_theme_constant_override("separation",12);confirmation.add_child(actions)
	cancel_button=button("继续这局 · Esc",actions,cancel_restart);cancel_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var confirm:=button("重新开始",actions,restart);confirm.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	continue_button=button("继续游戏",column,resume_game)
	overlay.hide();confirmation.hide();continue_button.hide();refresh()

func show_game() -> void:
	_settle_animation()
	active=true;paused=false;overlay.show();confirmation.hide();continue_button.hide();refresh();_focus_action()

func hide_game() -> void:
	_settle_animation()
	active=false;overlay.hide()

func request_restart() -> void:
	if paused:return
	_settle_animation()
	if game.moves==0:restart();return
	confirmation.show();refresh();cancel_button.grab_focus()

func cancel_restart() -> void:
	confirmation.hide();refresh();_focus_action()

func restart() -> void:
	_settle_animation()
	game.restart();win_acknowledged=false;record_message="";confirmation.hide();refresh();restart_button.grab_focus()

func continue_after_win() -> void:
	win_acknowledged=true;refresh();_focus_action()

func _focus_action() -> void:
	if paused:continue_button.grab_focus()
	elif result_panel.visible:result_restart.grab_focus()
	else:restart_button.grab_focus()

func pause_game() -> void:
	if not active:return
	_settle_animation()
	paused=true;confirmation.hide();refresh();continue_button.grab_focus()

func resume_game() -> void:
	paused=false;refresh();_focus_action()

func handle_key(code: int) -> bool:
	if code==KEY_ESCAPE:
		if confirmation.visible:cancel_restart()
		else:close_requested.emit()
		return true
	if code in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN,KEY_A,KEY_D,KEY_W,KEY_S]:
		if busy or paused:return true
		record_message="";refresh()
		if result_panel.visible:
			if result_continue.visible:
				if result_restart.has_focus():result_continue.grab_focus()
				else:result_restart.grab_focus()
			else:result_restart.grab_focus()
		elif not confirmation.visible:
			var directions={KEY_LEFT:Vector2i.LEFT,KEY_A:Vector2i.LEFT,KEY_RIGHT:Vector2i.RIGHT,KEY_D:Vector2i.RIGHT,KEY_UP:Vector2i.UP,KEY_W:Vector2i.UP,KEY_DOWN:Vector2i.DOWN,KEY_S:Vector2i.DOWN}
			var before:Array[int]=game.cells.duplicate()
			var score_before:int=game.score
			if game.move(directions[code]):
				var messages:Array[String]=[]
				if score_before<=6000 and game.score>6000:messages.append("哇，超过老公的记录啦")
				if score_before<=13000 and game.score>13000:messages.append("哇，超过老婆的记录啦")
				record_message="\n".join(messages)
				_animate_move(before)
		return true
	return code in [KEY_F,KEY_B]

func _clear_moving_tiles() -> void:
	for tile in moving_layer.get_children():tile.free()

func _settle_animation() -> void:
	if tile_tween:tile_tween.kill()
	busy=false
	_clear_moving_tiles()
	for tile in tiles:tile.scale=Vector2.ONE
	refresh()

func _animate_move(before: Array[int]) -> void:
	busy=true
	for tile in tiles:_paint_tile(tile,0)
	tile_tween=create_tween().set_parallel(true)
	for slide in game.slides:
		var tile:=label("",30,moving_layer)
		tile.position=tiles[slide.x].position;tile.size=tiles[slide.x].size
		tile.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;tile.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		_paint_tile(tile,before[slide.x])
		tile_tween.tween_property(tile,"position",tiles[slide.y].position,.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tile_tween.chain().tween_callback(_land_tiles)
	tile_tween.chain().tween_interval(.10)
	for index in game.merged+[game.spawned_index]:
		tile_tween.parallel().tween_property(tiles[index],"scale",Vector2.ONE,.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tile_tween.chain().tween_callback(func():busy=false;refresh())

func _land_tiles() -> void:
	_clear_moving_tiles();refresh()
	# Merge and spawn feedback stays local to the tiles; the house and panel stay still.
	for index in game.merged+[game.spawned_index]:
		var tile:=tiles[index];tile.pivot_offset=tile.size*.5
		tile.scale=Vector2(.65,.65) if index==game.spawned_index else Vector2(1.08,1.08)

func _paint_tile(tile: Label, value: int) -> void:
	var palette={0:"ddd5c7",2:"eee5d5",4:"e9dab9",8:"e6b075",16:"e99462",32:"df795c",64:"d85c45",128:"d1ac52",256:"c69b3c",512:"b78b2f",1024:"a87b28",2048:"966d25"}
	tile.text=str(value) if value else ""
	tile.add_theme_stylebox_override("normal",style(palette.get(value,"775c45")))
	tile.add_theme_color_override("font_color",Color("fff9ed" if value>=8 else "564b40"))
	tile.add_theme_font_size_override("font_size",30 if value<10000 else 24)

func refresh() -> void:
	score_label.text="分数  %d"%game.score
	status_label.text="游戏已暂停 · 点击继续游戏" if paused else "没有可移动的方块了" if game.game_over() else "已达成 2048 · 继续挑战吧" if game.won else "合并相同数字"
	if not record_message.is_empty():status_label.text=record_message
	var was_result_visible:=result_panel.visible
	var show_win:bool=game.won and not win_acknowledged
	result_panel.visible=not paused and not busy and not confirmation.visible and (show_win or game.game_over())
	result_panel.add_theme_stylebox_override("panel",style("edc850c9" if show_win else "eee5d5df"))
	result_title.text="You win!" if show_win else "Game over!"
	result_title.add_theme_color_override("font_color",Color("fff9ed" if show_win else "564b40"))
	result_scores.text="当前分数  %d\n老公记录  6000\n老婆记录  13000"%game.score
	result_scores.visible=not show_win
	result_restart.text="Start new" if show_win else "Try again"
	result_continue.visible=show_win
	if result_panel.visible and not was_result_visible:result_restart.grab_focus()
	continue_button.visible=paused
	restart_button.visible=not paused and not confirmation.visible and not result_panel.visible
	for i in 16:_paint_tile(tiles[i],game.cells[i])

func snapshot() -> Dictionary:
	return {"cells":game.cells,"score":game.score,"moves":game.moves,"won":game.won,"over":game.game_over(),"active":active,"paused":paused,"confirm":confirmation.visible,"busy":busy}
