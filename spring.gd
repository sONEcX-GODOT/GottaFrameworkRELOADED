extends Base_Object
class_name Spring
@export var dash_speed: float = 120.0
@export var jump_force: float = 120.0
@export var noncon_mode: bool = false
@export_group("Facing")
@export var face_spring_direction: bool = true
@export var invert_facing: bool = false
@export var camera_turn_time: float = 0.7
var _launching: bool = false
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		if _launching:
			return
		_launching = true
		if "is_homing_tracking" in body:
			body.is_homing_tracking = false
		if "homing_target_node" in body:
			body.homing_target_node = null
		Audio.stop_loop("drift")
		Audio.play("spring")
		if "is_boosting" in body:
			body.is_boosting = false
		if body.has_method("stop_boost"):
			body.stop_boost()
		body.custom_velocity = Vector3.ZERO
		body.velocity = Vector3.ZERO
		var launch_dir = global_transform.basis.y.normalized()
		body.custom_velocity = launch_dir * dash_speed
		body.velocity = launch_dir * dash_speed
		if "current_state" in body:
			body.current_state = body.State.JUMP
			body.perform_spring()
			body.flag.spring = true
			body.boost.visible = false
		if face_spring_direction and body.has_method("face_direction_with_camera"):
			body.face_direction_with_camera(_get_face_direction(launch_dir), camera_turn_time)
		if noncon_mode and "can_move" in body:
			body.can_move = false
		var old_jump = body.jump_force
		body.jump_force = jump_force * 2.5
		body.wall_jump_control_lock = 0.2
		body.set_physics_process(false)
		await get_tree().physics_frame
		body.set_physics_process(true)
		_monitor_fall(body, launch_dir)
		await get_tree().create_timer(0.2).timeout
		if is_instance_valid(body):
			body.jump_force = old_jump
		_launching = false
func _monitor_fall(body: Node3D, launch_dir: Vector3) -> void:
	await get_tree().create_timer(0.05).timeout
	
	var t: float = 0.0
	while is_instance_valid(body) and is_inside_tree() and body.velocity.dot(launch_dir) > 0.0 and t < 3.0:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		
	if is_instance_valid(body):
		body.flag.spring = false
		if noncon_mode and "can_move" in body:
			body.can_move = true
func _get_face_direction(launch_dir: Vector3) -> Vector3:
	var d: Vector3 = launch_dir.slide(Vector3.UP)
	if d.length() < 0.15:
		d = global_transform.basis.z.slide(Vector3.UP)
	return -d if invert_facing else d
