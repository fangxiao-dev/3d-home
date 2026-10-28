extends Control
## Two scales of the same life tracks, with deterministic quarterly constellations.
signal selected(index: int)
const GOLD = Color("be9569")
const ROSE = Color("c7858f")
var data: Dictionary
var current := 0
var zoom := 0.0
var cursor := 2016.12
var month := 1.0
var motion: Tween
var nodes: Array[Dictionary] = []
var star_hits: Array[Dictionary] = []
var from_time := 2016.12
var travel := 1.0
var font: Font = preload("res://assets/NotoSansSC-Reading.ttf")

func setup(value: Dictionary) -> void:
	data=value
	mouse_filter=Control.MOUSE_FILTER_STOP
	queue_redraw()

func show_page(index: int, animate := true) -> void:
	if motion:motion.kill()
	current=index
	var page:Dictionary=data.pages[index]
	from_time=cursor;travel=0.0
	if not animate:
		cursor=float(page.time);month=float(page.get("month",1));zoom=1.0 if cursor>=2026 else 0.0;travel=1.0;queue_redraw();return
	motion=create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	motion.tween_property(self,"cursor",float(page.time),.75)
	motion.tween_property(self,"month",float(page.get("month",1)),.75)
	motion.tween_property(self,"zoom",1.0 if float(page.time)>=2026 else 0.0,.75)
	motion.tween_property(self,"travel",1.0,.75)

func stop() -> void:
	if motion:motion.kill()
	show_page(current,false)

func _process(_delta: float) -> void:
	if is_visible_in_tree():queue_redraw()

func x_year(t: float) -> float:
	return 36.0+(clampf(t,2016,2027.5)-2016)/11.5*(size.x-72)

func x_month(t: float) -> float:
	return 36.0+(clampf(t,1,13)-1)/12*(size.x-72)

func _track_y(m: float, values: Array) -> float:
	for i in range(values.size()-1):
		if m<=float(values[i+1][0]):
			var t:=clampf((m-float(values[i][0]))/(float(values[i+1][0])-float(values[i][0])),0,1)
			t=t*t*(3-2*t)
			return lerpf(float(values[i][1]),float(values[i+1][1]),t)
	return float(values[-1][1])

func _star(point: Vector2, radius: float, color: Color) -> void:
	var pts:=PackedVector2Array()
	for i in 8:
		var angle:=float(i)*PI/4-PI/2
		pts.append(point+Vector2(cos(angle),sin(angle))*(radius if i%2==0 else radius*.3))
	draw_colored_polygon(pts,color)

func track_active(side: int) -> bool:
	var owner:=str(data.pages[current].get("side","both"))
	return owner=="both" or owner==("fang" if side==0 else "ying")

func overview_node_y(page: Dictionary) -> float:
	var owner:=str(page.get("side","both"))
	return 31.0 if owner=="fang" else 83.0 if owner=="ying" else 57.0

func _draw() -> void:
	if data.is_empty():return
	nodes.clear();star_hits.clear()
	var overview:=1.0-zoom
	# Draw both scales while interpolating; fixed height never steals page space.
	for side in 2:
		var pts:=PackedVector2Array()
		for i in 121:
			var t:=float(i)/120
			var old_y:=lerpf(57.0,31.0 if side==0 else 83.0,minf(t*10,1))
			if t>.78:old_y=lerpf(old_y,49.0 if side==0 else 72.0,(t-.78)/.22)
			var track:Array=data.tracks.top if side==0 else data.tracks.bottom
			pts.append(Vector2(36+t*(size.x-72),lerpf(old_y,_track_y(1+t*12,track),zoom)))
		var track_color:=GOLD if side==0 else ROSE
		track_color.a=1.0 if track_active(side) else .35
		draw_polyline(pts,track_color,3.5 if track_active(side) else 2.0,true)
	for q in data.quarters:
		var count:int=int(q.count)
		if count==0:continue
		var n:=1 if count<5 else 2 if count<15 else 3 if count<30 else 4 if count<50 else 5
		var t:=float(q.year)+(float(q.quarter)-.5)/4
		var glow:=0.0
		if travel<1 and t>=minf(from_time,cursor)-.2 and t<=maxf(from_time,cursor)+.2:
			glow=maxf(0,1-absf(t-cursor)/.8)
		var center:=Vector2(x_year(t),56)
		draw_circle(center,9,Color(1,.77,.39,.06*overview+glow*.16*overview))
		for j in n:
			var seed_value:=int(q.year)*17+int(q.quarter)*11+j*23
			var offset:=Vector2(float(seed_value%17)-8,float((seed_value*7)%21)-10)
			_star(center+offset,2.2+glow*1.4,Color(.76,.60,.36,(.38+glow*.62)*overview))
	for s in data.real_stars:
		var point:=Vector2(x_year(float(s.t)),17)
		_star(point,6,Color(.75,.48,.23,overview))
		if overview>.5:star_hits.append({"point":point,"label":str(s.label)})
	for key in data.call_hours:
		var m:=float(key)
		var n:=int(ceil(float(data.call_hours[key])/12))
		for i in n:
			var moment:=m+float(i+1)/float(n+1)
			var y1:=_track_y(moment,data.tracks.top)
			var y2:=_track_y(moment,data.tracks.bottom)
			if absf(y2-y1)<8:continue
			draw_line(Vector2(x_month(moment)-2,y1+4),Vector2(x_month(moment)+2,y2-4),Color(.68,.59,.48,.22*zoom),1,true)
	for step in data.footsteps:
		var is_detail:=float(step.time)>=2026
		var alpha:=zoom if is_detail else overview
		var x:=x_month(float(step.get("month",1))) if is_detail else x_year(float(step.time))
		var y:=94.0 if str(step.who)=="ying" else 10.0
		var c:=ROSE if str(step.who)=="ying" else GOLD;c.a=.4*alpha
		draw_circle(Vector2(x-2,y+2),1.8,c);draw_circle(Vector2(x+3,y-2),1.8,c)
	for i in data.pages.size():
		var p:Dictionary=data.pages[i]
		var detail:=float(p.time)>=2026
		var alpha:=zoom if detail else overview
		var point:=Vector2(x_month(float(p.get("month",1))) if detail else x_year(float(p.time)),57)
		if not detail:point.y=overview_node_y(p)
		var c:=Color("765c47");c.a=alpha
		draw_circle(point,7 if current==i else 5,c)
		draw_circle(point,3,Color(1,.96,.86,alpha))
		if alpha>.5:nodes.append({"index":i,"point":point})
	# A doorway node makes 2026 reachable from the overview and 2025 from detail.
	var bridge:=Vector2(size.x-25,57) if zoom<.5 else Vector2(16,57)
	var bridge_index:=6 if zoom<.5 else 5
	draw_circle(bridge,8,Color("aa8660"));nodes.append({"index":bridge_index,"point":bridge})
	for year in [2016,2017,2018,2020,2022,2024,2025,2026]:
		draw_string(font,Vector2(x_year(year)-18,115),str(year),HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color(.52,.45,.38,overview))
	for m in [1,2,3,5,7,9,10,12]:
		draw_string(font,Vector2(x_month(m)-10,115),str(m)+"月",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color(.52,.45,.38,zoom))
	var px:=lerpf(x_year(cursor),x_month(month),zoom)
	draw_line(Vector2(px,5),Vector2(px,96),Color("b58a53"),1,true)
	draw_circle(Vector2(px,57),3,Color("b58a53"))

func _get_tooltip(at_position: Vector2) -> String:
	for s in star_hits:
		if at_position.distance_to(s.point)<12:return s.label
	for n in nodes:
		if at_position.distance_to(n.point)<12:return str(data.pages[n.index].date)+" · "+str(data.pages[n.index].short)
	return ""

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		for n in nodes:
			if event.position.distance_to(n.point)<13:selected.emit(n.index);accept_event();return
