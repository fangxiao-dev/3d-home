extends RefCounted
## Session-only collection; discoveries use stable content IDs, never image filenames.
var content:Dictionary={}
var catalog:Array=[]
var found:Dictionary={}

func _init()->void:
	content=JSON.parse_string(FileAccess.get_file_as_string("res://content/food-collection/content.json"))
	catalog=content.items

func discover(id:String)->bool:
	if found.has(id):return false
	for item in catalog:
		if item.id==id:
			found[id]=true
			return true
	return false

func preview_complete()->void:
	for item in catalog:discover(item.id)

func active()->bool:
	return not found.is_empty()
