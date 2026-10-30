extends Control
## One continuous paper timeline: historical river, dock, and woven shared path.
signal selected(index: int)
const FUTURE_U = {"dayone":.05,"firstmeet":.19,"skies":.35,"travel":.53,"proposal":.655,"marriage":.79,"future":.94}
const PAST_START = 2016.12
const PAST_END = 2025.87
const STEP_DETAILS = [
	{"time":2017.5671232876712,"who":"ying","label":"2017.07.27 · 她先开口：「在不」"},
	{"time":2025.8657534246574,"who":"ying","label":"2025.11.13 · 她先开口：「又是一个时差党」"},
	{"time":2026.0,"who":"ying","page":"dayone","label":"2026.01.01 · 她先开口：「是的吧？」"},
	{"time":2026.15,"who":"fang","page":"firstmeet","label":"2026.02.23 · 飞回宜昌"},
	{"time":2026.72,"who":"fang","page":"travel","label":"2026.09.19 · 回国"},
	{"time":2026.755,"who":"fang","page":"proposal","label":"2026.10.03 · 求婚"},
	{"time":2026.8,"who":"fang","page":"marriage","label":"2026.10.19 · 领证"}
]
var data: Dictionary
var current := 0
# zoom/cursor remain readable by the existing album snapshot.
var zoom := 0.0
var cursor := PAST_START
var motion: Tween
var from_time := PAST_START
var travel := 1.0
var signal_from := ""
var signal_target := ""
var signal_progress := 1.0
var signal_delay := 0.0
var clock := 0.0
var signal_active := false
var yearly: Array[Dictionary] = []
var steps: Array[Dictionary] = []
var seen_steps: Dictionary = {}
var nodes: Array[Dictionary] = []
var decorations: Array[Dictionary] = []
var wash: ColorRect
var paper_texture: ImageTexture
var font: Font = preload("res://assets/NotoSansSC-Reading.ttf")

func setup(value: Dictionary) -> void:
	data=value
	mouse_filter=Control.MOUSE_FILTER_STOP
	for year in range(2016,2026):
		var count:=0
		for q in data.quarters:
			if int(q.year)==year:count+=int(q.count)
		yearly.append({"time":year+.5,"count":count})
	# Enrich confirmed annotations in the view only; do not mutate the content file.
	for detail in STEP_DETAILS:
		for source in data.footsteps:
			if str(source.who)==detail.who and absf(float(source.time)-float(detail.time))<.001:
				steps.append(detail.duplicate());break
	_make_paper()
	resized.connect(_resize_wash)
	mouse_exited.connect(queue_redraw)
	_update_seen()
	queue_redraw()

func _make_paper() -> void:
	var paper:=Image.create(192,128,false,Image.FORMAT_RGBA8)
	var rng:=RandomNumberGenerator.new();rng.seed=1403
	for y in 128:
		for x in 192:
			var v:=rng.randf_range(.15,.85);paper.set_pixel(x,y,Color(v,v,v,1))
	paper_texture=ImageTexture.create_from_image(paper)
	wash=ColorRect.new();wash.mouse_filter=Control.MOUSE_FILTER_IGNORE;wash.show_behind_parent=true
	var material:=ShaderMaterial.new();material.shader=preload("res://album_watercolor.gdshader");material.set_shader_parameter("paper",paper_texture)
	wash.material=material;add_child(wash);_resize_wash()

func _resize_wash() -> void:
	if not wash:return
	wash.size=size
	wash.material.set_shader_parameter("canvas_size",size)
	queue_redraw()

func focus_for(index: int) -> float:
	var p:Dictionary=data.pages[index]
	return 1.0 if float(p.time)>=2026 else .12 if p.id=="reconnect" else 0.0

func show_page(index: int, animate := true) -> void:
	if motion:motion.kill()
	var previous:Dictionary=data.pages[current]
	current=clampi(index,0,data.pages.size()-1)
	var page:Dictionary=data.pages[current]
	from_time=cursor;travel=0.0;clock=0.0
	signal_from=str(previous.id) if float(previous.time)>=2026 else ""
	signal_target=str(page.id) if float(page.time)>=2026 else ""
	signal_active=not signal_target.is_empty() and animate
	signal_delay=1.0 if signal_from.is_empty() else 0.0
	signal_progress=0.0 if signal_active else 1.0
	var boat_to:=2026.01 if float(page.time)>=2026 else float(page.time)
	if not animate:
		cursor=boat_to;zoom=focus_for(current);travel=1.0;_update_seen();queue_redraw();return
	motion=create_tween().set_parallel(true)
	motion.tween_property(self,"zoom",focus_for(current),1.17).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	motion.tween_property(self,"cursor",boat_to,1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	motion.tween_property(self,"travel",1.0,1.0)
	var duration:=signal_delay+1.65 if signal_active else 1.17
	motion.tween_property(self,"clock",duration,duration)

func stop() -> void:
	if motion:motion.kill()
	signal_active=false;signal_progress=1.0;travel=1.0
	cursor=2026.01 if float(data.pages[current].time)>=2026 else float(data.pages[current].time)
	zoom=focus_for(current);_update_seen();queue_redraw()

func _process(_delta: float) -> void:
	if not is_visible_in_tree():return
	if motion and motion.is_running():
		_update_seen();queue_redraw()

func geometry() -> Dictionary:
	var margin:=22.0
	var boundary:=margin+(size.x-2*margin)*(.60-.40*zoom)
	return {"margin":margin,"boundary":boundary,"start":boundary-39,"end":boundary+42,"y":size.y*.50}

func hist_x(time: float, g: Dictionary) -> float:
	return lerpf(g.margin,g.start,clampf((time-PAST_START)/(PAST_END-PAST_START),0,1))

func future_x(id: String, g: Dictionary) -> float:
	return lerpf(g.end,size.x-g.margin,float(FUTURE_U[id]))

func history_y(x: float, side: int, g: Dictionary) -> float:
	var t:=clampf((x-float(g.margin))/(float(g.start)-float(g.margin)),0,1)
	var spread:=smoothstep(0,.10,t)
	var wave:=sin(t*11+side*.5)*2.8+sin(t*23)*1.2
	return float(g.y)+side*(23+wave)*spread

func ribbon_y(x: float, g: Dictionary) -> float:
	var u:float=(x-float(g.end))/(size.x-float(g.end))
	return float(g.y)+sin(u*7.8)*4.3+sin(u*15)*1.5

func boat_position(g: Dictionary) -> Vector2:
	if cursor>=2026:return Vector2(g.end+12,g.y+7)
	if cursor>PAST_END:
		return Vector2(lerpf(g.start,g.end+12,(cursor-PAST_END)/(2026.01-PAST_END)),g.y+7)
	return Vector2(hist_x(cursor,g),g.y+7)

func track_active(side: int) -> bool:
	var owner:=str(data.pages[current].get("side","both"))
	return owner=="both" or owner==("fang" if side==0 else "ying")

func event_nodes() -> Array[Dictionary]:
	var hits:Array[Dictionary]=[]
	var g:=geometry()
	var future_index:=0
	for i in data.pages.size():
		var p:Dictionary=data.pages[i]
		if float(p.time)<2026:
			var x:=hist_x(float(p.time),g)
			var sides:Array=[-1] if p.get("side","both")=="fang" else [1] if p.get("side","both")=="ying" else [-1,1]
			for side in sides:hits.append({"index":i,"point":Vector2(x,history_y(x,side,g)),"radius":9.0,"kind":"history"})
		else:
			hits.append({"index":i,"point":Vector2(future_x(p.id,g),float(g.y)+(-25 if future_index%2==0 else 25)),"radius":13.0,"kind":"future"})
			future_index+=1
	return hits

func _rand(i: int) -> float:
	return fposmod(sin((i+1)*127.1)*43758.5453,1.0)

func _glow(p: Vector2, radius: float, color: Color, strength: float) -> void:
	for i in range(8,0,-1):
		var c:=color;c.a=strength*.10*(1-float(i)/10)
		draw_circle(p,radius*float(i)/8,c)

func _path(points: Array, origin: Vector2, color: Color, width:=1.5) -> void:
	var poly:=PackedVector2Array()
	for p in points:poly.append(origin+Vector2(p[0],p[1]))
	draw_polyline(poly,color,width,true)

func _star(p: Vector2, radius: float, color: Color, diamond:=false) -> void:
	var points:=PackedVector2Array()
	for i in (4 if diamond else 8):
		var angle:=i*TAU/(4 if diamond else 8)-PI/2
		points.append(p+Vector2(cos(angle),sin(angle))*(radius if diamond or i%2==0 else radius*.35))
	draw_colored_polygon(points,color)

func _draw() -> void:
	if data.is_empty():return
	var g:=geometry()
	wash.material.set_shader_parameter("boundary",float(g.boundary)/size.x)
	nodes=event_nodes();decorations.clear()
	_draw_river(g)
	_draw_tracks(g)
	_draw_ribbon(g)
	_draw_nodes(g)
	_draw_steps(g)
	_draw_boat(g)
	_draw_labels(g)

func _draw_tracks(g: Dictionary) -> void:
	for side in [-1,1]:
		var points:=PackedVector2Array()
		for i in 91:
			var x:float=lerpf(g.margin,g.start,float(i)/90);points.append(Vector2(x,history_y(x,side,g)))
		for i in range(1,29):
			var t:=float(i)/28
			points.append(Vector2(lerpf(g.start,g.end,t),lerpf(history_y(g.start,side,g),g.y,smoothstep(0,1,t))))
		var active:=track_active(0 if side<0 else 1)
		var c:=Color("bed5eb") if side<0 else Color("daadcc");c.a=.76 if active else .32
		draw_polyline(points,Color(c,.06),5,true);draw_polyline(points,c,1.8 if active else 1.3,true)

func _draw_river(g: Dictionary) -> void:
	for k in 5:
		var points:=PackedVector2Array()
		for i in 76:points.append(Vector2(lerpf(g.margin,g.end,float(i)/75),float(g.y)+(k-2)*4.3+sin(i*.22+k)*2))
		draw_polyline(points,Color(.69,.80,.88,.025+(k%2)*.015),1.8,true)
	for i in 130:
		var u:=_rand(i*4+27);var band:=(_rand(i*17+2)-.5)*35
		draw_circle(Vector2(lerpf(g.margin,g.start,u),float(g.y)+band+sin(u*8)*3),.35+_rand(i*31)*.5,Color(.85,.92,.98,.04+.14*(1-absf(band)/19)))
	var blend:=smoothstep(.18,.82,zoom)
	var boat:=boat_position(g)
	for q in data.quarters:
		if int(q.count)==0:continue
		_draw_cluster(float(q.get("time",float(q.year)+(float(q.quarter)-.5)/4)),int(q.count),int(q.year)*4+int(q.quarter),1-blend,g,boat,false)
	for year in yearly:_draw_cluster(year.time,year.count,int(year.time),blend,g,boat,true)
	for i in data.real_stars.size():
		var s:Dictionary=data.real_stars[i]
		var p:=Vector2(hist_x(float(s.t),g),float(g.y)+(-9 if i==0 else 9))
		_star(p,4.5,Color("f4e3bc"),i==1)
		decorations.append({"point":p,"radius":7.0,"label":str(s.label),"kind":"star"})

func _draw_cluster(time: float,count: int,seed_value: int,alpha: float,g: Dictionary,boat: Vector2,annual: bool) -> void:
	if alpha<=.001:return
	var n:=1 if count<5 else 2 if count<15 else 3 if count<30 else 4 if count<50 else 5
	if annual:n=mini(7,1+roundi(sqrt(count)/3))
	var x:=hist_x(time,g)
	var near:=exp(-pow((x-boat.x)/24,2))*sin(travel*PI) if cursor<2026 else 0.0
	if near>.02:_glow(Vector2(x,g.y),13,Color(.64,.88,1),near*.32*alpha)
	for j in n:
		var offset:=Vector2((_rand(seed_value*37+j*17)-.5)*9,(_rand(seed_value*29+j*23)-.5)*11)
		draw_circle(Vector2(x,g.y)+offset,.7+_rand(seed_value*43+j)*.55,Color(.87,.95,.99,(.40+near*.55)*alpha))

func strand_y(x: float, side: int, g: Dictionary) -> float:
	# A 64px weave stays quiet at either zoom; both 1.05px threads stay inside the 5.4px silhouette.
	return ribbon_y(x,g)+side*1.3*cos((x-float(g.end))*TAU/64.0)

func _draw_ribbon(g: Dictionary) -> void:
	var points:=PackedVector2Array();var upper:=PackedVector2Array();var lower:=PackedVector2Array();var colors:=PackedColorArray()
	for i in 91:
		var t:=float(i)/90;var x:=lerpf(g.end,size.x-g.margin,t);var y:=ribbon_y(x,g)
		points.append(Vector2(x,y))
		colors.append(Color("c693ab").lerp(Color("edb68f"),sin(t*PI)*.8))
	var samples:=ceili((size.x-float(g.margin)-float(g.end))/3.0)
	for i in range(samples+1):
		var x:=lerpf(g.end,size.x-g.margin,float(i)/samples)
		upper.append(Vector2(x,strand_y(x,-1,g)));lower.append(Vector2(x,strand_y(x,1,g)))
	draw_polyline(points,Color(.98,.90,.80,.12),12,true)
	draw_polyline_colors(points,colors,5.4,true)
	draw_polyline(upper,Color(.99,.93,.88,.7),1.05,true);draw_polyline(lower,Color(.58,.38,.44,.48),1.05,true)
	_path([[0,0],[25,0]],Vector2(g.end+3,g.y+15),Color(.42,.33,.35,.5),1.4)
	_path([[0,-8],[0,5]],Vector2(g.end+12,g.y+10),Color(.42,.33,.35,.45),1.2)
	if not signal_active or clock<signal_delay:return
	var t:=clampf((clock-signal_delay)/1.1,0,1)
	signal_progress=1-pow(1-t,3)
	if t<1:
		var start:float=g.end if signal_from.is_empty() else future_x(signal_from,g)
		var end:=future_x(signal_target,g)
		for j in 4:
			var delayed:=maxf(0,t-j*.065);var x:=lerpf(start,end,1-pow(1-delayed,3));var p:=Vector2(x,ribbon_y(x,g))
			_glow(p,18 if j==0 else 10,Color(1,.92,.73),.55-j*.09)
			draw_circle(p,2.4-j*.35,Color(1,.96,.80,.95-j*.16))

func _draw_nodes(g: Dictionary) -> void:
	for hit in nodes:
		var p:Vector2=hit.point;var chosen:int=int(hit.index);var selected_now:=chosen==current
		if hit.kind=="history":
			draw_circle(p,4.6,Color("e9e6e3") if selected_now else Color("253348"))
			draw_arc(p,4.6,0,TAU,24,Color("c6ddef") if p.y<float(g.y) else Color("e0b9d6"),1.6,true)
		else:
			var end:=Vector2(p.x,p.y+12 if p.y<float(g.y) else p.y-12)
			draw_line(Vector2(p.x,ribbon_y(p.x,g)),end,Color(.46,.29,.31,.38),1.1,true)
			var arrival:=maxf(0,1-(clock-signal_delay-1.1)/.55) if signal_active and clock>=signal_delay+1.1 else 0.0
			if selected_now and arrival>0:_glow(p,19,Color(1,.96,.85),arrival*.7)
			draw_circle(p,11.5,Color("fff0de") if selected_now else Color("eedbcc"))
			draw_arc(p,11.5,0,TAU,32,Color("986575") if selected_now else Color("a78182"),1.8 if selected_now else 1.2,true)
			_draw_icon(str(data.pages[chosen].id),p)

func _draw_icon(id: String,p: Vector2) -> void:
	var c:=Color("77535b")
	match id:
		"dayone":
			_path([[-6,-5],[2,-5],[2,5],[-6,5],[-6,-5]],p,c)
			_path([[3,-2],[7,-5],[7,5],[3,2]],p,c)
		"firstmeet":
			var points:=PackedVector2Array()
			for i in 49:
				var t:=i*TAU/48;points.append(p+Vector2(16*pow(sin(t),3),-(13*cos(t)-5*cos(2*t)-2*cos(3*t)-cos(4*t)))*.46)
			draw_polyline(points,c,1.4,true)
		"skies":
			draw_arc(p,3.5,0,TAU,24,c,1.4,true)
			for i in 8:
				var d:=Vector2.from_angle(i*PI/4);draw_line(p+d*5.4,p+d*7.7,c,1.4,true)
		"travel":_path([[-8,2],[8,-2],[-7,-5],[-3,-1],[-1,4],[2,6]],p,c)
		"proposal":
			draw_arc(p+Vector2(0,2),4.6,0,TAU,24,c,1.4,true)
			_path([[-3,-5],[0,-8],[3,-5],[0,-2],[-3,-5]],p,c)
		"marriage":
			_path([[-6,-6],[6,-6],[6,6],[-6,6],[-6,-6]],p,c)
			_path([[-3,-2],[3,-2]],p,c);_path([[-3,2],[1,2]],p,c)
		"future":
			_path([[0,-8],[2,-2],[7,0],[2,2],[0,8],[-2,2],[-7,0],[-2,-2],[0,-8]],p,c)

func _update_seen() -> void:
	if data.is_empty():return
	var start_u:=0.0 if signal_from.is_empty() else float(FUTURE_U[signal_from])
	var target_u:=float(FUTURE_U.get(signal_target,0.0))
	var t:=clampf((clock-signal_delay)/1.1,0,1)
	signal_progress=1-pow(1-t,3) if signal_active else 1.0
	var u:=lerpf(start_u,target_u,signal_progress)
	for i in steps.size():
		var step:Dictionary=steps[i]
		if float(step.time)<2026 and float(step.time)>=minf(from_time,cursor) and float(step.time)<=maxf(from_time,cursor):seen_steps[i]=true
		elif step.get("page","")=="dayone" and cursor>=2026:seen_steps[i]=true
		elif signal_active and clock>=signal_delay and step.who=="fang":
			var step_u:=float(FUTURE_U[step.page])
			if step_u>=minf(start_u,u)-.00001 and step_u<=maxf(start_u,u)+.00001:seen_steps[i]=true

func _draw_steps(g: Dictionary) -> void:
	for i in steps.size():
		if not seen_steps.has(i):continue
		var step:Dictionary=steps[i];var historical:=float(step.time)<2026
		var x:=hist_x(float(step.time),g)-7 if historical else future_x(step.page,g)-9
		var y:=history_y(x,1,g) if historical else ribbon_y(x,g)+(-2 if step.who=="fang" else 2)
		var c:=Color(1,.84,.64,.75) if historical else Color(.44,.26,.21,.65)
		for offset in [Vector2(-2,1),Vector2(2,-2)]:
			var center:Vector2=Vector2(x,y)+offset
			draw_set_transform(center,-.4,Vector2(.65,1));draw_circle(Vector2.ZERO,2.6,c);draw_set_transform(Vector2.ZERO)
			draw_circle(center+Vector2(-1.4,-3.8),.9,c)
		decorations.append({"point":Vector2(x,y),"radius":6.0,"label":str(step.label),"kind":"footstep"})

func _draw_boat(g: Dictionary) -> void:
	var p:=boat_position(g)
	if cursor<2026:
		var direction:=signf(cursor-from_time)
		var pulse:=sin(travel*PI)
		_glow(p+Vector2(0,4),26,Color(.45,.87,.97),.15+pulse*.32)
		for i in 12:
			var offset:=Vector2(-direction*(5+_rand(i)*26),(_rand(i*7)-.5)*12)
			draw_circle(p+offset,.6+_rand(i*3),Color(.76,.95,1,pulse*(.22+_rand(i)*.4)))
	var hull:=PackedVector2Array([p+Vector2(-11,-1),p+Vector2(0,1),p+Vector2(11,-1),p+Vector2(7,5),p+Vector2(0,7),p+Vector2(-7,5)])
	draw_colored_polygon(hull,Color("263444") if cursor<2026 else Color("73565a"))
	hull.append(hull[0]);draw_polyline(hull,Color(.86,.93,.96,.9),1.0,true)
	_path([[-1,-2],[-1,-10],[5,-3],[-1,-2]],p,Color("eadac5"),1.1)

func _draw_labels(g: Dictionary) -> void:
	var ink:=Color(.95,.93,.89,.9)
	var reserve:float=g.start-font.get_string_size("2025 · 11",HORIZONTAL_ALIGNMENT_LEFT,-1,11).x
	var right:=-100.0
	for year in [2016,2018,2020,2022,2024]:
		var x:=hist_x(year+.12,g)-8
		if x<right+10 or x+27>reserve-10:continue
		draw_string(font,Vector2(x,size.y-7),str(year),HORIZONTAL_ALIGNMENT_LEFT,-1,11,ink);right=x+27
	draw_string(font,Vector2(reserve,size.y-7),"2025 · 11",HORIZONTAL_ALIGNMENT_LEFT,-1,11,ink)
	draw_string(font,Vector2(g.end+3,size.y-7),"2026",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("62484a"))
	if float(data.pages[current].time)>=2026:
		var text:=str(data.pages[current].date)
		var width:=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x
		var x:=clampf(future_x(data.pages[current].id,g)-width/2,g.end+40,size.x-width-4)
		draw_string(font,Vector2(x,14),text,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("62484a"))

func decoration_hits() -> Array[Dictionary]:
	var hits:Array[Dictionary]=[]
	var g:=geometry()
	for i in data.real_stars.size():
		var star:Dictionary=data.real_stars[i]
		hits.append({"point":Vector2(hist_x(float(star.t),g),float(g.y)+(-9 if i==0 else 9)),"radius":7.0,"label":str(star.label),"kind":"star"})
	for i in steps.size():
		if not seen_steps.has(i):continue
		var step:Dictionary=steps[i];var historical:=float(step.time)<2026
		var x:=hist_x(float(step.time),g)-7 if historical else future_x(step.page,g)-9
		var y:=history_y(x,1,g) if historical else ribbon_y(x,g)+(-2 if step.who=="fang" else 2)
		hits.append({"point":Vector2(x,y),"radius":6.0,"label":str(step.label),"kind":"footstep"})
	return hits

func hit_at(at_position: Vector2) -> Dictionary:
	# Fresh geometry also covers input arriving before the next draw after a tween step.
	var nearest:Dictionary={};var distance:=INF
	for hit in event_nodes():
		var d:=at_position.distance_to(hit.point)
		if d<=float(hit.radius) and d<distance:nearest=hit;distance=d
	for hit in decoration_hits():
		var d:=at_position.distance_to(hit.point)
		if d<=float(hit.radius) and d<distance:nearest=hit;distance=d
	return nearest

func _get_tooltip(at_position: Vector2) -> String:
	var hit:=hit_at(at_position)
	if hit.is_empty():return ""
	if hit.has("label"):return hit.label
	var page:Dictionary=data.pages[hit.index]
	return str(page.date)+" · "+str(page.short)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		var hit:=hit_at(event.position)
		if hit.has("index"):selected.emit(int(hit.index));accept_event()

func snapshot() -> Dictionary:
	var g:=geometry()
	var hits:Array=[]
	for hit in event_nodes():hits.append({"index":hit.index,"point":[hit.point.x,hit.point.y]})
	return {"focus":zoom,"history_ratio":.6-.4*zoom,"boat":[boat_position(g).x,boat_position(g).y],"docked":cursor>=2026,"signal_from":signal_from,"signal_target":signal_target,"signal_progress":signal_progress,"signal_active":signal_active and clock>=signal_delay and clock<signal_delay+1.1,"seen_steps":seen_steps.keys(),"nodes":hits}
