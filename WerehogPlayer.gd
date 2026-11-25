extends CharacterBody3D
class_name WerehogPlayer
enum State { IDLE, RUN, BOOST, JUMP, DASH_JUMP, LANDING, HIT, ATTACK }
@export_category("Werehog Movement")
@export var max_speed: float = 15.0
@export_category("Camera Control")
@export var mouse_sensitivity: float = 0.005
@export var auto_align_speed: float = 1.5
@export_category("Dynamic Camera")
@export var base_distance: float = 6.0
@export var boost_distance: float = 6.8
@export var base_fov: float = 70.0
@export var boost_fov: float = 73.0
@export var camera_follow_speed: float = 14.0
@export var vertical_follow_speed: float = 8.0
@export var max_tilt_angle: float = 0.03
@export var camera_offset: Vector3 = Vector3(0, 2.5, 0)
@export_category("Gamepad Control")
@export var gamepad_sensitivity: float = 2.0
@export_category("Attack")
@export var attack_damage: int = 1
@export var hit_delay: float = 0.15
const STOMP_COMBO := [
	"werehog_animations/evilsonic_attackNCA",
	"werehog_animations/evilsonic_attackNCB",
	"werehog_animations/evilsonic_attackNCC",
]
const HOMING_COMBO := [
	"werehog_animations/evilsonic_attackNSA",
	"werehog_animations/evilsonic_attackNSB",
	"werehog_animations/evilsonic_attackNSC",
]
var attack_combo: Array = STOMP_COMBO
var attack_step: int = 0
var attack_id: int = 0
var attack_area: Area3D
var current_state: State = State.IDLE
var jump_count: int = 0
var max_jumps: int = 2
var target_yaw: float = 0.0
var target_pitch: float = -0.22
var is_intro: bool = false
var manual_camera_timer: float = 0.0
@onready var visual_node: Node3D = $werehog_root
@onready var anim_player: AnimationPlayer = $werehog_root/EvilRoot/AnimationPlayer
@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	attack_area = find_child("AttackArea", true, false) as Area3D
	if attack_area == null:
		push_warning("AttackArea (Area3D) не найден внутри игрока!")
	anim_player.animation_finished.connect(_on_anim_finished)
	if camera_pivot:
		camera_pivot.top_level = true
		camera_pivot.global_position = global_position + camera_offset
		camera_pivot.rotation.x = target_pitch
	if spring_arm:
		spring_arm.spring_length = base_distance
	elif camera:
		camera.position.z = base_distance
	if camera:
		camera.fov = base_fov
func _process(_delta: float) -> void:
	$CrawTrail.visible = current_state == State.HIT or current_state == State.ATTACK
	if current_state == State.HIT or is_intro:
		return
	if manual_camera_timer > 0.0:
		manual_camera_timer -= _delta
	var gamepad_vector = Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	if gamepad_vector.length() > 0.15:
		target_yaw -= gamepad_vector.x * gamepad_sensitivity * _delta
		target_pitch -= gamepad_vector.y * gamepad_sensitivity * _delta
		target_pitch = clamp(target_pitch, -0.75, 0.45)
		manual_camera_timer = 1.0
	var buttons = _find_all_texture_buttons(get_tree().root)
	for button in buttons:
		if button.shortcut and not button.shortcut.events.is_empty():
			for event in button.shortcut.events:
				if event is InputEventAction:
					var action = event.action
					if Input.is_action_just_pressed(action):
						button.button_pressed = true
					elif Input.is_action_just_released(action):
						button.button_pressed = false
var touch_owner: Dictionary = {}
func _send_action(action: StringName, pressed: bool) -> void:
	var ev = InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	Input.parse_input_event(ev)
func _input(event: InputEvent) -> void:
	if is_intro:
		return
	if event is InputEventScreenTouch:
		var buttons = _find_all_texture_buttons(get_tree().root)
		for button in buttons:
			if not button.shortcut or button.shortcut.events.is_empty():
				continue
			for shortcut_event in button.shortcut.events:
				if not (shortcut_event is InputEventAction):
					continue
				var action = shortcut_event.action
				if event.pressed:
					if button.get_global_rect().has_point(event.position) and not touch_owner.has(button):
						touch_owner[button] = event.index
						button.button_pressed = true
						_send_action(action, true)
				elif touch_owner.get(button, -1) == event.index:
					touch_owner.erase(button)
					button.button_pressed = false
					_send_action(action, false)
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or event is InputEventScreenDrag:
			target_yaw -= event.relative.x * mouse_sensitivity
			target_pitch -= event.relative.y * mouse_sensitivity
			target_pitch = clamp(target_pitch, -0.75, 0.45)
			manual_camera_timer = 1.0
func _physics_process(delta: float) -> void:

	var stomp_pressed := Input.is_action_just_pressed("stomp")
	var homing_pressed := Input.is_action_just_pressed("homing")
	if stomp_pressed or homing_pressed:
		var combo: Array = STOMP_COMBO if stomp_pressed else HOMING_COMBO
		if current_state == State.ATTACK:
			if combo == attack_combo:
				if attack_step < combo.size() - 1:
					_start_attack(combo, attack_step + 1) 
			else:
				_start_attack(combo, 0)
		elif is_on_floor() and current_state in [State.IDLE, State.RUN, State.BOOST, State.LANDING]:
			_start_attack(combo, 0)
	if current_state == State.ATTACK:
		if not is_on_floor():
			velocity.y -= 22.0 * delta
		velocity.x = move_toward(velocity.x, 0, 40.0 * delta)
		velocity.z = move_toward(velocity.z, 0, 40.0 * delta)
		_update_dynamic_camera(delta, Vector2.ZERO, Vector3.ZERO, false)
		move_and_slide()
		return

	if not is_on_floor():
		velocity.y -= 22.0 * delta
		if current_state != State.JUMP and current_state != State.DASH_JUMP and jump_count == 0:
			jump_count = 1
			switch_state(State.DASH_JUMP if Input.is_action_pressed("boost") else State.JUMP)
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var is_boosting = Input.is_action_pressed("boost")
	var direction := Vector3.ZERO
	if camera_pivot:
		var forward := -camera_pivot.global_transform.basis.z
		var right := camera_pivot.global_transform.basis.x
		forward.y = 0
		right.y = 0
		direction = (forward * input_dir.y + right * input_dir.x).normalized()
	if direction != Vector3.ZERO:
		var current_speed = max_speed * 1.5 if is_boosting else max_speed
		var target_velocity = direction * current_speed
		velocity.x = move_toward(velocity.x, target_velocity.x, 25.0 * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, 25.0 * delta)
		var target_angle = atan2(-direction.x, -direction.z) + PI
		visual_node.rotation.y = rotate_toward(visual_node.rotation.y, target_angle, 10.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, 20.0 * delta)
		velocity.z = move_toward(velocity.z, 0, 20.0 * delta)
	_update_dynamic_camera(delta, input_dir, direction, is_boosting)
	if Input.is_action_just_pressed("jump") and jump_count < max_jumps:
		jump_count += 1
		velocity.y = 8.5 if jump_count == 1 else 7.5
		switch_state(State.DASH_JUMP if is_boosting else State.JUMP)
	match current_state:
		State.IDLE:
			if direction != Vector3.ZERO:
				switch_state(State.BOOST if is_boosting else State.RUN)
		State.RUN:
			if direction == Vector3.ZERO:
				anim_player.play("werehog_animations/evilsonic_runE", 0.1)
				anim_player.queue("werehog_animations/evilsonic_idleA")
				switch_state(State.IDLE)
			elif is_boosting:
				switch_state(State.BOOST)
		State.BOOST:
			if direction == Vector3.ZERO:
				switch_state(State.IDLE)
			elif not is_boosting:
				switch_state(State.RUN)
			else:
				if input_dir.x < -0.3:
					anim_player.play("werehog_animations/evilsonic_dashR", 0.2)
				elif input_dir.x > 0.3:
					anim_player.play("werehog_animations/evilsonic_dashL", 0.2)
				else:
					anim_player.play("werehog_animations/evilsonic_dash", 0.15)
		State.JUMP:
			if velocity.y < 0 and anim_player.current_animation != "werehog_animations/evilsonic_jumpD":
				anim_player.play("werehog_animations/evilsonic_jumpD", 0.15)
			if is_on_floor():
				jump_count = 0
				switch_state(State.BOOST if is_boosting else (State.RUN if direction != Vector3.ZERO else State.IDLE))
		State.DASH_JUMP:
			if is_on_floor():
				jump_count = 0
				switch_state(State.BOOST if is_boosting else (State.RUN if direction != Vector3.ZERO else State.IDLE))
		State.LANDING:
			if is_boosting or direction != Vector3.ZERO:
				switch_state(State.BOOST if is_boosting else State.RUN)
			elif not anim_player.is_playing():
				switch_state(State.IDLE)
	move_and_slide()
func _update_dynamic_camera(delta: float, input_dir: Vector2, direction: Vector3, is_boosting: bool) -> void:
	if not camera_pivot:
		return
	var target_pos = global_position + camera_offset
	camera_pivot.global_position.x = lerp(camera_pivot.global_position.x, target_pos.x, camera_follow_speed * delta)
	camera_pivot.global_position.z = lerp(camera_pivot.global_position.z, target_pos.z, camera_follow_speed * delta)
	camera_pivot.global_position.y = lerp(camera_pivot.global_position.y, target_pos.y, vertical_follow_speed * delta)
	if direction != Vector3.ZERO and manual_camera_timer <= 0.0:
		var align_factor = abs(input_dir.x) * (1.5 if is_boosting else 1.0)
		target_yaw -= input_dir.x * auto_align_speed * align_factor * delta
	camera_pivot.rotation.y = lerp_angle(camera_pivot.rotation.y, target_yaw, 18.0 * delta)
	camera_pivot.rotation.x = lerp(camera_pivot.rotation.x, target_pitch, 18.0 * delta)
	var target_roll: float = 0.0
	if is_boosting and direction != Vector3.ZERO:
		target_roll = -input_dir.x * max_tilt_angle
	camera_pivot.rotation.z = lerp(camera_pivot.rotation.z, target_roll, 8.0 * delta)
	var horizontal_speed = Vector2(velocity.x, velocity.z).length()
	var is_actually_boosting = is_boosting and horizontal_speed > max_speed * 0.8
	var target_dist = boost_distance if is_actually_boosting else base_distance
	if spring_arm:
		spring_arm.spring_length = lerp(spring_arm.spring_length, target_dist, 6.0 * delta)
	elif camera:
		camera.position.z = lerp(camera.position.z, target_dist, 6.0 * delta)
	if camera:
		var target_fov = boost_fov if is_actually_boosting else base_fov
		camera.fov = lerp(camera.fov, target_fov, 6.0 * delta)
func switch_state(new_state: State) -> void:
	var old_state = current_state
	current_state = new_state
	anim_player.speed_scale = 1.0
	match current_state:
		State.IDLE:
			if anim_player.current_animation != "werehog_animations/evilsonic_runE":
				anim_player.play("werehog_animations/evilsonic_idleA", 0.2)
		State.RUN:
			anim_player.speed_scale = 4.0
			if old_state == State.JUMP or old_state == State.LANDING:
				anim_player.play("werehog_animations/evilsonic_run", 0.15)
			elif anim_player.current_animation != "werehog_animations/evilsonic_dash" and anim_player.current_animation != "werehog_animations/evilsonic_dashL" and anim_player.current_animation != "werehog_animations/evilsonic_dashR":
				anim_player.play("werehog_animations/evilsonic_runS", 0.15)
				anim_player.queue("werehog_animations/evilsonic_run")
			else:
				anim_player.play("werehog_animations/evilsonic_run", 0.2)
		State.BOOST:
			if old_state == State.DASH_JUMP or old_state == State.LANDING or old_state == State.JUMP:
				anim_player.play("werehog_animations/evilsonic_dash", 0.15)
			elif anim_player.current_animation != "werehog_animations/evilsonic_run":
				anim_player.play("werehog_animations/evilsonic_dashS", 0.15)
				anim_player.queue("werehog_animations/evilsonic_dash")
			else:
				anim_player.play("werehog_animations/evilsonic_dash", 0.2)
		State.JUMP:
			if jump_count == 2:
				anim_player.play("werehog_animations/evilsonic_jumpVS2", 0.1)
			else:
				anim_player.play("werehog_animations/evilsonic_jumpVS", 0.1)
		State.DASH_JUMP:
			anim_player.play("werehog_animations/evilsonic_dash_jumpS", 0.1)
			anim_player.queue("werehog_animations/evilsonic_dash_jump")
		State.LANDING:
			anim_player.play("werehog_animations/evilsonic_dash_jumpE", 0.05)

func _start_attack(combo: Array, step: int) -> void:
	current_state = State.ATTACK
	attack_combo = combo
	Audio.play("punch")
	if attack_step == 1 or attack_step == 2:
		Audio.play("hit")

	attack_step = step
	attack_id += 1
	anim_player.speed_scale = 1.0
	anim_player.play(combo[step], 0.05)
	_do_hit(attack_id)
func _do_hit(id: int) -> void:
	await get_tree().create_timer(hit_delay).timeout
	if current_state != State.ATTACK or attack_id != id or attack_area == null:
		return
	for body in attack_area.get_overlapping_bodies():
		if body != self and body.has_method("take_damage"):
			body.take_damage(attack_damage)
func _on_anim_finished(anim_name: StringName) -> void:
	if current_state != State.ATTACK or String(anim_name) != attack_combo[attack_step]:
		return
	_end_attack()
func _end_attack() -> void:
	var moving := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") != Vector2.ZERO
	var boosting := Input.is_action_pressed("boost")
	if moving:
		switch_state(State.BOOST if boosting else State.RUN)
	else:
		switch_state(State.IDLE)

func _find_all_texture_buttons(node: Node) -> Array:
	var result: Array = []
	if node is TextureButton:
		result.append(node)
	for child in node.get_children():
		result.append_array(_find_all_texture_buttons(child))
	return result
