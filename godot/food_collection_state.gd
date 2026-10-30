extends RefCounted
## Stable-ID collection. Web localStorage is synchronous and reports failed writes.
const SAVE_KEY="little-home.food.v1"
var content:Dictionary={}
var catalog:Array=[]
var found:Dictionary={}
var preview:=false
var persistent:=false
var save_error:=""
var save_path:="user://food-collection.json"

func _init()->void:
	content=JSON.parse_string(FileAccess.get_file_as_string("res://content/food-collection/content.json"))
	catalog=content.items

func start(preview_mode:bool=false)->void:
	preview=preview_mode;persistent=not preview
	if preview:
		preview_complete();return
	var raw:String=""
	if OS.has_feature("web"):
		var result=JavaScriptBridge.eval("(()=>{try{return localStorage.getItem('"+SAVE_KEY+"')||'[]'}catch(e){return null}})()",true)
		if result==null:save_error="无法读取本机收藏，请检查浏览器存储设置。";return
		raw=str(result)
	elif FileAccess.file_exists(save_path):raw=FileAccess.get_file_as_string(save_path)
	else:return
	var ids=JSON.parse_string(raw)
	if not ids is Array:save_error="本机收藏记录无法读取。";return
	for id in ids:
		if valid_id(str(id)):found[str(id)]=true

func valid_id(id:String)->bool:
	for item in catalog:
		if item.id==id:return true
	return false

func discover(id:String)->bool:
	if found.has(id):
		if not save_error.is_empty():_save()
		return false
	if not valid_id(id):return false
	found[id]=true
	_save()
	return true

func _save()->bool:
	if not persistent or preview:return true
	var raw:=JSON.stringify(found.keys())
	var ok:=false
	if OS.has_feature("web"):
		ok=bool(JavaScriptBridge.eval("(()=>{try{localStorage.setItem('"+SAVE_KEY+"',"+JSON.stringify(raw)+");return true}catch(e){return false}})()",true))
	else:
		var file:=FileAccess.open(save_path,FileAccess.WRITE)
		if file:file.store_string(raw);file.flush();ok=file.get_error()==OK
	save_error="" if ok else "收藏尚未保存到本机，请检查浏览器存储设置后重试。"
	return ok

func reset()->bool:
	var previous:=found.duplicate();found.clear()
	if not _save():found=previous;return false
	return true

func preview_complete()->void:
	preview=true;persistent=false
	for item in catalog:found[item.id]=true

func active()->bool:return not found.is_empty()
