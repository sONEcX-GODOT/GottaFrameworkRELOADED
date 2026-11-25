extends Base_Object
class_name FakeSpring
@export var dash_speed: float = 120.0
@export var jump_force: float = 120.0
@export var noncon_mode: bool = false
var _spring_token: int = 0
func _ready():
	body_entered.connect(_on_body_entered)
func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("Player"):
		return
	_spring_token += 1
	var current_token = _spring_token
	Audio.stop_loop("drift")
	Audio.play("fake")
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
	if noncon_mode and "can_move" in body:
		body.can_move = false
	if not body.has_meta("base_jump_force"):
		body.set_meta("base_jump_force", body.jump_force)
	body.jump_force = jump_force * 2.5
	body.wall_jump_control_lock = 0.2
	body.set_physics_process(false)
	await get_tree().physics_frame
	if not is_instance_valid(body) or _spring_token != current_token:
		return
	body.set_physics_process(true)
	_monitor_fall(body, launch_dir, current_token)
	await get_tree().create_timer(0.2).timeout
	if is_instance_valid(body) and _spring_token == current_token:
		if body.has_meta("base_jump_force"):
			body.jump_force = body.get_meta("base_jump_force")
			body.remove_meta("base_jump_force")
func _monitor_fall(body: Node3D, launch_dir: Vector3, token: int) -> void:
	await get_tree().create_timer(0.05).timeout
	while is_instance_valid(body) and _spring_token == token:
		var stopped_moving = body.velocity.dot(launch_dir) <= 0.0
		var hit_surface = body is CharacterBody3D and (body.is_on_wall() or body.is_on_floor())
		if stopped_moving or hit_surface:
			break
		await get_tree().physics_frame
	if is_instance_valid(body) and _spring_token == token:
		body.flag.spring = false
		if noncon_mode and "can_move" in body:
			body.can_move = true
		if body.has_meta("base_jump_force"):
			body.jump_force = body.get_meta("base_jump_force")
			body.remove_meta("base_jump_force")
