extends Base_Object
class_name DashRing
@export var dash_speed: float = 120.0
@export var noncon_mode: bool = false
@export var hold_time: float = 0.5
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		Audio.stop_loop("drift")
		Audio.play("ringD")
		GameManager.score += 100
		body.spin.visible = false 
		if body.has_method("stop_boost"):
			body.stop_boost()
		if body.has_method("stop_stomp"):
			body.stop_stomp()
		if "is_boosting" in body:
			body.is_boosting = false
		if "is_stomping" in body:
			body.is_stomping = false
		if "current_state" in body:
			body._change_state(body.State.LAUNCH)
			body.current_state = body.State.LAUNCH
		body.custom_velocity = Vector3.ZERO
		body.velocity = Vector3.ZERO
		if "snap_vector" in body:
			body.snap_vector = Vector3.ZERO
		var launch_dir = global_transform.basis.y.normalized()
		var final_velocity = launch_dir * dash_speed
		body.custom_velocity = final_velocity
		body.velocity = final_velocity
		if "launch_hold_timer" in body:
			body.launch_hold_velocity = final_velocity
			body.launch_hold_timer = hold_time
		if body.has_method("_start_dashring_anim"):
			body._start_dashring_anim()
		if "current_state" in body:
			body.flag.dash = true
			if body.has_node("Boost"):
				body.get_node("Boost").visible = false
		if "can_move" in body:
			body.can_move = not noncon_mode
		var token: int = randi()
		body.set_meta("dashring_token", token)
		body.set_physics_process(false)
		await get_tree().physics_frame
		body.set_physics_process(true)
		if is_instance_valid(body) and "current_state" in body and body.current_state == body.State.LAUNCH:
			body.custom_velocity = final_velocity
			body.velocity = final_velocity
		_monitor_fall(body, token)
func _flight_active(body: Node3D, token: int) -> bool:
	return is_instance_valid(body) and "current_state" in body and body.current_state == body.State.LAUNCH and body.get_meta("dashring_token", -1) == token
func _monitor_fall(body: Node3D, token: int) -> void:
	while _flight_active(body, token) and body.launch_hold_timer > 0.0:
		await get_tree().physics_frame
	while _flight_active(body, token) and body.custom_velocity.y >= 0.0:
		await get_tree().physics_frame
	if not is_instance_valid(body) or body.get_meta("dashring_token", -1) != token:
		return
	body.flag.dash = false
	if body.current_state == body.State.LAUNCH:
		body._change_state(body.State.JUMP)
		body.current_state = body.State.JUMP
	if "can_move" in body and body.current_state != body.State.HIT:
		body.can_move = true
