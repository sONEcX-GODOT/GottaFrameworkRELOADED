extends Node

var preloaded_resources = []

# load all synchronously
func _enter_tree():
	print("Preloading all resources...")
	_preload_dir("res://ui")
	_preload_dir("res://models")
	_preload_dir("res://Objects")
	_preload_dir("res://materials")
	print("Preloading finished!")

# prewarm objects to compile shaders and particles
func _ready():
	var prewarm_node = Node3D.new()
	prewarm_node.position = Vector3(0, -9999, 0)
	add_child(prewarm_node)
	
	for res in preloaded_resources:
		if res is PackedScene:
			var inst = res.instantiate()
			if inst.has_method("touch_player") or inst.has_method("touch") or "manager" in res.resource_path.to_lower():
				inst.queue_free()
				continue
				
			if inst is Node3D or inst is Node2D or inst is Control:
				inst.set_meta("prewarm", true)
				prewarm_node.add_child(inst)
				_activate_particles(inst)
				
	await get_tree().process_frame
	await get_tree().process_frame
	prewarm_node.queue_free()

func _activate_particles(node: Node):
	if node is CPUParticles3D or node is GPUParticles3D:
		node.emitting = true
		node.one_shot = true
	elif node is CPUParticles2D or node is GPUParticles2D:
		node.emitting = true
		node.one_shot = true
		
	for child in node.get_children():
		_activate_particles(child)

# preload directory recursively
func _preload_dir(path: String):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name != "." and file_name != "..":
				if dir.current_is_dir():
					_preload_dir(path + "/" + file_name)
				else:
					if "object_manager" in file_name:
						file_name = dir.get_next()
						continue
						
					if file_name.ends_with(".gd") or file_name.ends_with(".tscn") or file_name.ends_with(".gdshader") or file_name.ends_with(".tres") or file_name.ends_with(".png"):
						var res_path = path + "/" + file_name
						if not res_path.ends_with(".import"):
							preloaded_resources.append(ResourceLoader.load(res_path))
			file_name = dir.get_next()
