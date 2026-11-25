extends Base_Object
class_name DashRamp
@export var dash_speed: float = 50.0
@export var jump_force: float = 80.0
@export_group("QTE")
@export var use_qte: bool = false          # включить QTE на этом рампе (или добавить его в группу QTE)
@export var qte_start_delay: float = 0.1   # пауза после отрыва от рампы до начала QTE (если рамп в группе QTE)
@export var qte_at_apex: bool = true     # запускать QTE в верхней точке полёта (когда он перестал подниматься)
@export var qte_apex_max_wait: float = 2.5  # страховка: максимум секунд ожидания верхней точки
@export var qte_time: float = -1.0       # -1 = время из QuickTimeManager
@export_group("Ramp")
@export var max_lock_time: float = 6.0   # страховка: максимум секунд блокировки в полёте
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		Audio.stop_loop("drift")
		Audio.play("panel")
		if "is_boosting" in body:
			body.is_boosting = false
		if body.has_method("stop_boost"):
			body.stop_boost()
		var up: Vector3 = body.local_up if "local_up" in body else Vector3.UP
		# направление рампа, спроецированное на горизонт игрока (наклон меша рампа не влияет)
		var dash_dir: Vector3 = global_transform.basis.z.slide(up).normalized()
		if dash_dir.length() < 0.001:
			dash_dir = global_transform.basis.z.normalized()
		var target_angle = atan2(dash_dir.x, dash_dir.z) + PI
		body.global_transform.basis = Basis(Vector3.UP, target_angle)
		body.model.rotation.y = PI
		var launch_vel: Vector3 = dash_dir * dash_speed + up * jump_force
		body.custom_velocity = launch_vel
		body.velocity = launch_vel
		if "current_state" in body:
			body.current_state = body.State.JUMP
			body.flag.dash = true
			body.boost.visible = false 
			if body.has_method("start_ramp_anim"):
				body.start_ramp_anim()
		# базовая сила прыжка запоминается ОДИН раз и никогда не перезаписывается уже усиленным значением
		if not body.has_meta("base_jump_force"):
			body.set_meta("base_jump_force", body.jump_force)
		var base_jump: float = body.get_meta("base_jump_force")
		var token: int = Time.get_ticks_usec()
		body.set_meta("ramp_token", token)
		body.jump_force = jump_force * 2.5
		var cam_basis = Basis.from_euler(Vector3(body.cam_pitch, body.cam_yaw, 0.0))
		var cam_right = cam_basis.x.normalized().slide(body.local_up).normalized()
		var cam_forward = body.local_up.cross(cam_right).normalized()
		var local_x = dash_dir.dot(cam_right)
		var local_y = dash_dir.dot(cam_forward)
		body.wall_jump_control_lock = 0.2
		var was_movable: bool = body.can_move
		if body.has_meta("ramp_was_movable"):
			was_movable = body.get_meta("ramp_was_movable")
		else:
			body.set_meta("ramp_was_movable", was_movable)
		body.can_move = false   # блокируем управление на весь полёт
		_hold_direction(body, token, dash_dir, up)   # постоянно возвращаем скорость по направлению рампа
		body.set_physics_process(false)
		await get_tree().physics_frame
		body.set_physics_process(true)
		await get_tree().create_timer(0.2).timeout
		if is_instance_valid(body) and body.get_meta("ramp_token", 0) == token:
			body.jump_force = base_jump
		print("[QTE-DBG] ramp: use_qte=", use_qte, " in_group_QTE=", is_in_group("QTE"), " groups=", get_groups(), " body_valid=", is_instance_valid(body), " has_start=", is_instance_valid(body) and body.has_method("_start_qte"))
		# если рамп в группе QTE - в полёте запускаем QTE
		if (use_qte or is_in_group("QTE")) and is_instance_valid(body) and body.has_method("_start_qte") and body.get_meta("ramp_token", 0) == token:
			if qte_start_delay > 0.0:
				await get_tree().create_timer(qte_start_delay).timeout
			if qte_at_apex:
				var apex_start_ms := Time.get_ticks_msec()
				while is_instance_valid(body) and body.get_meta("ramp_token", 0) == token \
						and not body.grounded \
						and body.custom_velocity.dot(body.local_up) > 0.5 \
						and (Time.get_ticks_msec() - apex_start_ms) < int(qte_apex_max_wait * 1000.0):
					await get_tree().physics_frame
			if is_instance_valid(body) and body.get_meta("ramp_token", 0) == token and not body.grounded:
				if has_meta("qte_used"):
					remove_meta("qte_used")
				if qte_time > 0.0:
					set_meta("qte_time", qte_time)
				print("[QTE-DBG] ramp: calling _start_qte")
				body._start_qte(self)
		# ждём приземления (с небольшой задержкой, чтобы успеть оторваться от земли)
		var start_ms := Time.get_ticks_msec()
		await get_tree().create_timer(0.15).timeout
		# сначала ждём, пока он реально оторвётся от меша рампа (grounded на рампе != приземление)
		while is_instance_valid(body) and body.grounded and (Time.get_ticks_msec() - start_ms) < 500:
			await get_tree().physics_frame
		while is_instance_valid(body) and not body.grounded and (Time.get_ticks_msec() - start_ms) < int(max_lock_time * 1000.0):
			await get_tree().physics_frame
		if not is_instance_valid(body):
			return
		# если за это время игрок въехал на другой рамп, он сам разблокирует управление
		if body.get_meta("ramp_token", 0) != token:
			return
		body.jump_force = base_jump
		body.remove_meta("ramp_was_movable")
		if was_movable and body.current_state != body.State.HIT and not body.get("qte_fail_locked") and not body.get("qte_input_lock"):
			body.can_move = true


# Каждый физ-кадр заменяет горизонтальную скорость игрока на направление рампа,
# чтобы статичный меш не мог его "скатить" в сторону. Вертикаль (прыжок/гравитация) не трогаем.
func _hold_direction(body: Node3D, token: int, dir: Vector3, up: Vector3) -> void:
	var start_ms := Time.get_ticks_msec()
	var airborne := false
	var yaw: float = atan2(dir.x, dir.z) + PI
	while is_instance_valid(body) and body.get_meta("ramp_token", 0) == token:
		var elapsed := Time.get_ticks_msec() - start_ms
		if elapsed > int(max_lock_time * 1000.0):
			break
		if not body.grounded:
			airborne = true
		# приземлились после полёта (или так и не оторвались за 0.5 с) - отпускаем
		if body.grounded and (airborne or elapsed > 500):
			break
		var cv: Vector3 = body.custom_velocity
		var horiz_speed: float = maxf(dash_speed, cv.slide(up).length())
		var up_speed: float = cv.dot(up)
		if not airborne:
			# ещё на меше рампа: инерция/слоуп-физика тянет вниз и назад, поэтому
			# каждый кадр возвращаем полный стартовый импульс
			up_speed = maxf(up_speed, jump_force)
		var new_v: Vector3 = up * up_speed + dir * horiz_speed
		body.custom_velocity = new_v
		body.velocity = new_v
		body.global_transform.basis = Basis(Vector3.UP, yaw)
		await get_tree().physics_frame
