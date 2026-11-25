extends Node3D
var warmup_camera: Camera3D
var disabled_nodes: Array = []
func _ready() -> void:
	setup_warmup_camera()
	disable_logic_only(self)
	var particles = []
	gather_particles(self, particles)
	for p in particles:
		if p is GPUParticles3D or p is CPUParticles3D:
			p.restart()
	var steps = 8
	for s in range(steps):
		warmup_camera.rotate_y(deg_to_rad(360.0 / steps))
		await get_tree().process_frame
	await get_tree().create_timer(2.0).timeout
	for node in disabled_nodes:
		if is_instance_valid(node):
			node.process_mode = PROCESS_MODE_INHERIT
	warmup_camera.queue_free()
	start_game_logic()
func disable_logic_only(current_node: Node) -> void:
	for child in current_node.get_children():
		if child != warmup_camera and child.process_mode != PROCESS_MODE_DISABLED:
			if not (child is VisualInstance3D or child is Light3D):
				child.process_mode = PROCESS_MODE_DISABLED
				disabled_nodes.append(child)
		disable_logic_only(child)
func gather_particles(current_node: Node, result_list: Array) -> void:
	for child in current_node.get_children():
		if child is GPUParticles3D or child is CPUParticles3D:
			result_list.append(child)
		gather_particles(child, result_list)
func setup_warmup_camera() -> void:
	warmup_camera = Camera3D.new()
	add_child(warmup_camera)
	warmup_camera.process_mode = PROCESS_MODE_ALWAYS
	warmup_camera.global_position = Vector3(0, 5, 0)
	warmup_camera.make_current()
func start_game_logic() -> void:
	pass
