extends Base_Object
class_name DashPad
@export var dash_speed:float = 120.0
@export var lock_time: float = 0.5   # сколько секунд Соник заблокирован (can_move = false) на панели
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		Audio.stop_loop("drift")
		Audio.play("panel")
		var dash_dir = global_transform.basis.z.normalized()
		var target_angle = atan2(dash_dir.x, dash_dir.z)
		body.global_transform.basis = Basis(Vector3.UP, target_angle)
		body.model.rotation.y = PI
		body.custom_velocity = Vector3.ZERO
		body.velocity = Vector3.ZERO
		body.custom_velocity.x = -dash_dir.x * dash_speed
		body.custom_velocity.z = -dash_dir.z * dash_speed
		var cam_basis = Basis.from_euler(Vector3(body.cam_pitch, body.cam_yaw, 0.0))
		var cam_right = cam_basis.x.normalized().slide(body.local_up).normalized()
		var cam_forward = body.local_up.cross(cam_right).normalized()
		var local_x = dash_dir.dot(cam_right)
		var local_y = dash_dir.dot(cam_forward)
		body.wall_jump_control_lock = 0.05
		var was_movable: bool = body.can_move
		body.can_move = false   # блокируем управление: нельзя ни ускориться, ни свернуть, ни остановиться
		body.set_physics_process(false)
		await get_tree().physics_frame
		body.set_physics_process(true)
		await get_tree().create_timer(lock_time).timeout
		if is_instance_valid(body) and was_movable and body.current_state != body.State.HIT:
			body.can_move = true
