extends RefCounted
## Original local implementation of the standard 2048 rules; no network or saved state.
var cells: Array[int] = []
var score := 0
var moves := 0
var won := false
var slides: Array[Vector2i] = []
var merged: Array[int] = []
var spawned_index := -1
var rng := RandomNumberGenerator.new()

func _init() -> void:
	rng.randomize()
	restart()

func restart() -> void:
	cells.assign([0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0])
	score=0; moves=0; won=false
	slides.clear();merged.clear()
	spawn_tile(); spawn_tile()

func spawn_tile() -> void:
	spawned_index=-1
	var empty: Array[int]=[]
	for i in 16:
		if cells[i]==0:empty.append(i)
	if not empty.is_empty():
		var value:=2 if rng.randf()<0.9 else 4
		spawned_index=empty[rng.randi_range(0,empty.size()-1)]
		cells[spawned_index]=value

func move(direction: Vector2i) -> bool:
	slides.clear();merged.clear();spawned_index=-1
	var previous:=cells.duplicate()
	for line in 4:
		var indices: Array[int]=[]
		for offset in 4:
			if direction==Vector2i.LEFT:indices.append(line*4+offset)
			elif direction==Vector2i.RIGHT:indices.append(line*4+3-offset)
			elif direction==Vector2i.UP:indices.append(offset*4+line)
			else:indices.append((3-offset)*4+line)
		var values: Array[int]=[]
		var sources: Array[int]=[]
		for index in indices:
			if cells[index]!=0:values.append(cells[index]);sources.append(index)
		var result: Array[int]=[]
		var i:=0
		while i<values.size():
			var value:=values[i]
			var destination:=indices[result.size()]
			slides.append(Vector2i(sources[i],destination))
			if i+1<values.size() and value==values[i+1]:
				slides.append(Vector2i(sources[i+1],destination));merged.append(destination)
				value*=2; score+=value; i+=1
				if value>=2048:won=true
			result.append(value); i+=1
		for j in 4:cells[indices[j]]=result[j] if j<result.size() else 0
	if previous==cells:return false
	moves+=1
	spawn_tile()
	return true

func game_over() -> bool:
	for i in 16:
		if cells[i]==0:return false
		if i%4<3 and cells[i]==cells[i+1]:return false
		if i<12 and cells[i]==cells[i+4]:return false
	return true
