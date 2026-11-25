extends CharacterBody3D
class_name SonicPlayer
enum os {ANDROID, PC}
enum State {GROUND, ROLL, JUMP, WALL_CLING, STOMP, DRIFT, BOOST, BOUNCE, QUICK_STEP, LIGHT_SPEED_DASH, HIT, DASH, LAUNCH, GRINDING, CRAWL, SQUAT_KICK, HOMING, BRAKE, QTE_ACTIVE, SELECT_JUMP, SKYDIVE}
enum SelPhase {WAIT, AIM, FLY, MISS_WAIT, MISS}
const BASE_GRIND_SPEED = 35.0
const GRIND_ACCELERATION = 20.0
const IDLE_VARIANTS: Array[String] = ["sonic_idle_A", "sonic_idle_B", "sonic_idle_C"]
const TRACKED_ACTIONS: Array[StringName] = [&"boost", &"stomp"]
@export_category("movements")
@export_group("General")
@export var can_move: bool = true
@export var current_os = os.PC
@export var max_speed: float = 75.0
@export var acceleration: float = 35.0
@export var friction: float = 50.0
@export var roll_friction: float = 16.0
@export var gravity_force: float = 70.0
@export var snap_length: float = 3.5
@export var target_floor_dist: float = 0.1
@export var coyote_time: float = 0.08
@export var nocon_time: float = 1.0
@export var lean_amount: float = 0.4
@export var lean_speed: float = 8.0
@export_group("Steering")
@export var steer_deadzone_deg: float = 5.0
@export var steer_deadzone_min_speed: float = 70.0
@export var turn_rate_deg: float = 300.0
@export var turn_rate_top_factor: float = 0.3
@export var boost_turn_mult: float = 0.5
@export var air_turn_rate_deg: float = 720.0
@export var accel_top_factor: float = 0.4
@export var friction_mult_slow: float = 1.5
@export var friction_mult_fast: float = 0.6
@export var air_friction_mult: float = 0.0
@export var skid_angle_deg: float = 140.0
@export var skid_decel: float = 90.0
@export var model_turn_speed: float = 18.0
@export_group("Jump")
@export var jump_force: float = 40.0
@export var max_jump_up_speed: float = 60.0
@export var air_drag: float = 35.0
@export var double_jump_force: float = 40.0
@export var double_jump_enabled: bool = false 
@export var hurdle_phase_fraction: float = 0.4
@export_group("Jump Land")
@export var jump_land_max_speed: float = 3.0
@export var jump_land_cancel_speed: float = 12.0
@export_group("Stomp & Bounce")
@export var stomp_spd: float = 260.0
@export var bounce_velocity: float = 65.0
@export_group("Homing")
@export var homing_force: float = 90.0
@export var homing_range: float = 65.0
@export var homing_hit_distance: float = 2.5
@export var homing_bounce_force: float = 30.0
@export var homing_max_time: float = 1.5
@export var debug_homing: bool = false
@export_group("Wall")
@export var wall_jump_horizontal_force: float = 45.0
@export var wall_jump_vertical_force: float = 40.0
@export var max_wall_cling_time: float = 0.6
@export var wall_slide_gravity_mult: float = 0.10
@export_group("Quick Step")
@export var quick_step_distance: float = 3.5
@export var quick_step_duration: float = 0.2
@export var quick_step_anim_speed: float = 0.7
@export_group("Boost")
@export var boost_max_speed: float = 225.0
@export var boost_acceleration: float = 110.0
@export var boost_fade_in_time: float = 0.35
@export var boost_cam_kick_distance: float = 3.0
@export var boost_cam_return_time: float = 2.0
@export_group("Air Boost")
@export var air_boost_speed: float = 120.0
@export var air_boost_acceleration: float = 200.0
@export var air_boost_energy_cost: float = 20.0
@export var air_boost_steer: float = 3.0
@export_group("Drift")
@export var drift_min_speed: float = 15.0
@export var drift_steer_speed: float = 3.5
@export var drift_lean_amount: float = 0.6
@export var drift_friction_reduction: float = 0.2
@export_group("Brake")
@export var brake_min_speed: float = 1.0
@export var brake_input_threshold: float = 0.6
@export var brake_back_dot: float = 0.6
@export var brake_deceleration: float = 260.0
@export var boost_brake_deceleration: float = 480.0
@export var brake_anim_speed: float = 0.5
@export var boost_brake_anim_speed: float = 1.0
@export var brake_lock_time: float = 0.7
@export var brake_window: float = 0.2
@export_group("Crawl")
@export var crawl_speed: float = 10.0
@export var crawl_check_ceiling: bool = true
@export var standup_after_crawl: bool = false
@export var double_tap_window: float = 0.3
@export var squat_kick_speed: float = 2.5
@export_group("Damage")
@export var hit_stun_time: float = 1.0
@export var hit_invincibility: float = 3.0
@export var invincible_blink: bool = true
@export var stumble_time: float = 1.0
@export var hit_total_time: float = 3.5
@export var hit_standup_time: float = 1.0
@export var stumble_anim_speed: float = 0.8
@export_group("Loop Assist")
@export var loop_min_speed: float = 20.0
@export var loop_assist_angle: float = 45.0
@export var loop_half_width: float = 8.0
@export var loop_scan_step: float = 1.0
@export var loop_center_speed: float = 6.0
@export_group("Auto Zone")
@export var autozone_enabled: bool = true
@export var autozone_group: StringName = &"AutoZone"
@export var autozone_min_speed: float = 20.0
@export var autozone_release_angle_deg: float = 35.0
@export var autozone_turn_rate_deg: float = 160.0
@export var autozone_half_width: float = 14.0
@export var autozone_scan_step: float = 1.0
@export var autozone_look_time: float = 0.2
@export var autozone_look_min: float = 4.0
@export var autozone_look_max: float = 30.0
@export var autozone_quick_step_pause: float = 0.5
@export_group("Light Speed Dash")
@export var lsd_speed: float = 45.0
@export var lsd_scan_radius: float = 6.0
@export_group("Grind")
@export var base_grind_speed: float = 35.0
@export var grind_acceleration: float = 20.0
@export var grind_jump_anim_speed: float = 1.5
@export var grind_jump_hold_time: float = 0.15
@export var rail_quick_step_duration: float = 1
@export var rail_quick_step_anim_speed: float = 0.7
@export var grind_auto_center: bool = true
@export var grind_foot_bone_l: String = "Foot_L"
@export var grind_foot_bone_r: String = "Foot_R"
@export_group("Camera")
@export var camera_distance: float = 5.5
@export var camera_height: float = 3.5
@export var mouse_sensitivity: float = 0.008
@export var gamepad_sensitivity: float = 2.0
@export var camera_inertia: float = 28.0
@export var camera_manual_enabled: bool = true
@export_group("Camera Follow")
@export var camera_auto_follow: bool = true
@export var camera_follow_speed: float = 1.4
@export var camera_follow_max_turn: float = 2.2
@export var camera_return_speed: float = 1.4
@export var camera_follow_min_speed: float = 4.0
@export var camera_manual_timeout: float = 1.2
@export var camera_pitch_return: float = 0.8
@export var camera_slope_max_angle: float = 45.0
@export var camera_slope_follow_speed: float = 2.5
@export var camera_follow_deadzone: float = 40.0
@export var camera_fast_deadzone: float = 3.0
@export var camera_fast_follow_mult: float = 2.5
@export var camera_slope_min_angle: float = 5.0
@export var camera_default_pitch: float = -0.06
@export var camera_recenter_speed: float = 6.0
@export var camera_idle_pitch: float = -0.02
@export var camera_idle_height_mult: float = 0.35
@export var camera_idle_distance_mult: float = 0.7
@export var camera_close_speed_min: float = 2.0
@export var camera_close_speed_max: float = 25.0
@export var camera_framing_speed: float = 6.0
@export var camera_drift_follow_speed: float = 8.0
@export var camera_drift_max_turn: float = 6.0
@export var camera_snap_smooth: float = 25.0
@export_group("Skydive")
@export var skydive_fall_speed: float = 20.0
@export var skydive_boost_fall_speed: float = 60.0
@export var skydive_gravity: float = 30.0
@export var skydive_boost_gravity: float = 90.0
@export var skydive_air_resistance: float = 40.0
@export var skydive_move_speed: float = 14.0
@export var skydive_boost_move_speed: float = 32.0
@export var skydive_acceleration: float = 22.0
@export var skydive_drag: float = 10.0
@export var skydive_overspeed_drag: float = 80.0
@export var skydive_turn_speed: float = 6.0
@export var skydive_min_height: float = 6.0
@export var skydive_land_check: float = 1.5
@export var skydive_anim: String = "sonic_skydiving_loop"
@export var skydive_boost_anim: String = "sonic_skydiving_loop_D"
@export var skydive_anim_blend: float = 0.25
@export var skydive_cam_pitch: float = -0.75
@export var skydive_cam_yaw_speed: float = 2.5
@export var skydive_cam_max_turn: float = 2.0
@export var skydive_cam_pitch_speed: float = 2.0
@export_group("Idle")
@export var idle_variant_delay: float = 3.0
@export_group("Anim")
@export var ramp_jump_anim: String = "sonic_jump_A_start_delux"
@export var jog_to_run_speed: float = 10.0
@export var jet_anim_speed_min: float = 3.0
@export var jet_anim_speed_max: float = 4.5
@export_group("QTE")
@export var qte_hold_anim: String = "sonic_select_springjump_S"
@export var qte_trick_anims: Array[String] = ["sonic_trick_A", "sonic_trick_B", "sonic_trick_C", "sonic_trick_D", "sonic_trick_E", "sonic_trick_F", "sonic_trick_G"]
@export var qte_trick_max_time: float = 1.5
@export var qte_fail_anim: String = "global/sn_jump_d"
@export var qte_fail_kills: bool = true
@export var qte_fail_die_delay: float = 2.0
@export var qte_slowmo_scale: float = 0.3
@export var qte_slowmo_exit_time: float = 0.2
@export var qte_gravity_scale: float = 0.5
@export var qte_success_boost: float = 22.0
@export var qte_hover: bool = true
@export var qte_lock_camera: bool = true
@export var qte_cam_orbit: bool = true
@export var qte_cam_orbit_speed: float = 300.0
@export var qte_cam_return_time: float = 0.35
@export_group("QTE Landing")
@export var qte_land_on_platform: bool = true
@export var qte_land_group: StringName = &"QTE_target"
@export var qte_land_min_distance: float = 3.0
@export var qte_land_max_distance: float = 120.0
@export var qte_land_forward_dot: float = 0.0
@export var qte_land_max_rise: float = 4.0
@export var qte_land_edge_margin: float = 1.5
@export var qte_land_apex_clearance: float = 2.0
@export var qte_fly_speed: float = 45.0
@export var qte_fly_min_time: float = 0.6
@export var qte_fly_max_time: float = 2.0
@export var qte_fly_gravity_scale: float = 1.0
@export_group("Select Jump")
@export var select_ball_anim: String = "sonic_ball"
@export var select_miss_anim: String = "sonic_selectjump_missloop"
@export var select_side_anim: String = "sonic_selectjumpS_floor"
@export var select_up_anim: String = "sonic_selectjumpS_UE"
@export var select_snap_speed: float = 25.0
@onready var boost_camera: Camera3D = get_viewport().get_camera_3d()
@onready var shockwave_rect: ColorRect = get_node("../HUD/shockwave")
@onready var model = $Sonic_root
@onready var boost = $Sonic_root/SonicRoot/Skeleton/Boost
@onready var area = $Area3D
@onready var spin = $Sonic_root/SonicRoot/Skeleton/spin
@onready var anim = $Sonic_root/SonicRoot/AnimationPlayer
@onready var stomp = $Sonic_root/SonicRoot/Skeleton/Stomp/AnimationPlayer
@onready var pivot = $CameraPivot
@onready var sparkle = $Sonic_root/SonicRoot/Skeleton/Sparkle
@onready var camera = $CameraPivot/SpringArm3D/Camera3D
@onready var path_follow: PathFollow3D = $PathFollow3D
@onready var trail: GPUTrail3D = $GPUTrail3D
@onready var head_col = $CollisionShape3D2
var current_state = State.GROUND
var flag: Dictionary = {"fall": false, "dash": false, "stomp": false, "spring": false, "trick": false}
var grounded: bool = false
var coyote_timer: float = 0.0
var local_up: Vector3 = Vector3.UP
var custom_velocity: Vector3 = Vector3.ZERO
var current_lean: float = 0.0
var is_dead: bool = false
var current_rings = RingCount.rings
var is_intro: bool = true
var intro_anim_started: bool = false
var _t_start := Time.get_ticks_msec()
var can_double_jump: bool = false
var can_homing_dash: bool = false
var is_jumping: bool = false
var jump_fall_phase: bool = false
var in_hurdle: bool = false
var jump_start_y: float = 0.0
var jump_land_active: bool = false
var jump_track_active: bool = false
var jump_was_cut: bool = false
var should_bounce: bool = false
var is_doing_trick: bool = false
var trick_token: int = 0
var after_homing: bool = false
var is_homing_tracking: bool = false
var homing_target_node: Node3D = null
var homing_area: Area3D = null
var homing_timer: float = 0.0
var ignored_homing_targets: Array = []
var _ex_frame: int = -1
var _ex_cache: Array[RID] = []
var _enemy_ignored: Dictionary = {}
var wall_jump_control_lock: float = 0.0
var wall_cling_timer: float = 0.0
var current_wall_normal: Vector3 = Vector3.ZERO
var is_quick_stepping: bool = false
var quick_step_dir: float = 0.0
var quick_step_keep_velocity: Vector3 = Vector3.ZERO
var quick_step_tween: Tween = null
var is_boosting: bool = false
var is_air_boosting: bool = false
var boost_duration: float = 6.0
var boost_regen_time: float = 12.0
var boost_energy: float = 400.0
var max_boost_energy: float = 400.0
var drift_direction: Vector3 = Vector3.ZERO
var drift_visual_angle: float = 0.0
var brake_timer: float = 0.0
var brake_from_boost: bool = false
var brake_hist: Array = []
var crawl_col: CollisionShape3D = null
var _crawl_col_on: bool = false
var _roll_hold_active: bool = false
var _roll_hold_time: float = 0.0
var stand_col: CollisionShape3D = null
var last_roll_tap_ms: int = -100000
var kick_timer: float = 0.0
var idle_timer: float = 0.0
var idle_bag: Array[String] = []
var idle_last: String = ""
var invincible_timer: float = 0.0
var hit_standing_up: bool = false
var hit_is_stumble: bool = false
var _hit_speed: float = 1.0
var _standup_speed: float = 1.0
var loop_assist_active: bool = false
var _autozone_pause: float = 0.0
var _act_down: Dictionary = {}
var bounce_rise: bool = false
var _ui_buttons: Array = []
var _ui_buttons_time: int = -100000
var _touch_buttons: Dictionary = {}
var is_lsd_active: bool = false
var lsd_last_dir: Vector3 = Vector3.ZERO
var lsd_target_ring: Node3D = null
var lsd_tween: Tween = null
var target_yaw: float = 0.0
var target_pitch: float = 0.0
var cam_yaw: float = 0.0
var cam_pitch: float = 0.0
var _cam_snap_offset: Vector3 = Vector3.ZERO
var cam_recentering: bool = false
var cam_base_rot_x: float = 0.0
var cam_manual_timer: float = 0.0
var normal_fov: float = 75.0
var boost_fov: float = 80.0
var camera_transition_speed: float = 0.5
var camera_tween: Tween
var _spring_cam_tween: Tween = null
var boost_cam_offset: float = 0.0
var _boost_cam_tween: Tween = null
var _boost_fade_tween: Tween = null
var _boost_geoms: Array = []
var _boost_want: bool = false
var _boost_wall_lock: bool = false
var dashring_anim_active: bool = false
var launch_hold_timer: float = 0.0
var launch_hold_velocity: Vector3 = Vector3.ZERO
var _dashring_anim_name: String = ""
var _boost_fade_k: float = 0.0
var current_rail: Area3D = null
var current_pole_node: Node3D = null
var rail_control_lock: float = 0.0
var grind_speed: float = 0.0
var grind_direction: float = 1.0
var grind_jump_timer: float = -1.0
var grind_jump_quick: bool = false
var grind_switch_active: bool = false
var grind_center_x: float = 0.0
var is_rail_quick_stepping: bool = false
var _grind_skel: Skeleton3D = null
var _grind_center_warned: bool = false
var qte_fail_locked: bool = false
var qte_input_lock: bool = false
var qte_saved_velocity: Vector3 = Vector3.ZERO
var qte_fail_timer: float = 0.0
var qte_flying: bool = false
var ramp_anim_active: bool = false
var _qte_time_tween: Tween = null
var _qte_cam_tween: Tween = null
var _qf_p0: Vector3 = Vector3.ZERO
var _qf_v0: Vector3 = Vector3.ZERO
var _qf_g: float = 70.0
var _qf_t: float = 0.0
var _qf_dur: float = 1.0
var _qf_target: Vector3 = Vector3.ZERO
var select_node: JumpSelector = null
var select_phase: int = SelPhase.WAIT
var select_timer: float = 0.0
var select_dir: Vector3 = Vector3.ZERO
var select_speed: float = 0.0
var select_rise: bool = false
var skydive_zones: Array = []
var skydive_boosting: bool = false
var skydive_face: Vector3 = Vector3.FORWARD
var _skydive_anims_ready: bool = false
func _ready():
	print("Sonic _ready: ", Time.get_ticks_msec() - _t_start, " мс")
	for a in TRACKED_ACTIONS:
		_act_down[a] = Input.is_action_pressed(a)
	add_to_group("Player")
	target_pitch = camera_idle_pitch
	cam_pitch = camera_idle_pitch
	_setup_crawl_collision()
	var button = get_tree().get_nodes_in_group("Buttons")
	if current_os == os.PC:
		for btn in button:
			btn.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	area.area_entered.connect(touch_player)
	_cache_boost_geoms(boost)
	_set_boost_fade(0.0)
	boost.visible = false
	if pivot:
		pivot.top_level = true
	if camera:
		camera.position = Vector3(0, camera_height, camera_distance)
		cam_base_rot_x = camera.rotation.x
		_update_camera_framing(0.0, true)
	_setup_homing_area()
	_disable_root_tracks("sonic_ball")
	can_move = false
	$CanvasLayer.visible = true
	await get_tree().create_timer(1.5).timeout
	$CanvasLayer/AnimationPlayer.play("start")
	_intro_camera_swing(2.0)
	await get_tree().create_timer(2.5).timeout
	is_intro = false
	can_move = true
func _physics_process(delta: float) -> void:
	_update_spin()
	_update_enemy_collision()
	if select_rise and (current_state != State.JUMP or custom_velocity.y <= 0.0):
		select_rise = false
	if bounce_rise and (current_state != State.JUMP or custom_velocity.dot(local_up) <= 0.0):
		bounce_rise = false
	if is_homing_tracking and current_state != State.HOMING:
		is_homing_tracking = false
		homing_target_node = null
	if invincible_timer > 0.0:
		invincible_timer = maxf(invincible_timer - delta, 0.0)
		if invincible_blink and model:
			model.visible = invincible_timer <= 0.0 or int(invincible_timer * 12.0) % 2 == 0
	if qte_fail_locked or current_state == State.QTE_ACTIVE:
		_qte_physics(delta)
		return
	if qte_flying:
		if is_dead:
			qte_flying = false
		else:
			_qte_fly_physics(delta)
			return
	if current_state == State.SELECT_JUMP:
		_select_jump_physics(delta)
		return
	if current_state != State.SKYDIVE:
		_try_start_skydive()
	if current_state == State.SKYDIVE:
		_skydive_physics(delta)
		return
	if can_move == true and Input.is_action_just_pressed("quick_step_right"):
		perform_quick_step(1.0)
	if can_move == true and Input.is_action_just_pressed("quick_step_left"):
		perform_quick_step(-1.0)
	if current_state == State.GRINDING:
		handle_grind_movement(delta)
		if pivot:
			pivot.global_position = _smooth_cam_pos()
		return
	if current_state == State.LIGHT_SPEED_DASH:
		_lsd_physics(delta)
		return
	if current_state == State.HOMING:
		_homing_physics(delta)
		return
	if grounded:
		coyote_timer = coyote_time
	else:
		coyote_timer = max(coyote_timer - delta, 0.0)
	if rail_control_lock > 0.0:
		rail_control_lock -= delta
	if (is_boosting or _boost_want) and not is_air_boosting and (not _held(&"boost") or current_state == State.GROUND):
		_end_boost()
	elif current_state == State.BOOST and (custom_velocity - custom_velocity.project(local_up)).length() <= 0.1:
		is_boosting = false
		_boost_hide()
	if wall_jump_control_lock > 0.0:
		wall_jump_control_lock -= delta
	if wall_jump_control_lock <= 0.0:
		if can_move and Input.is_action_just_pressed("homing"):
			if current_state != State.JUMP or not _find_homing_target():
				perform_light_speed_dash()
				if is_lsd_active:
					return
		if current_state == State.JUMP and Input.is_action_just_pressed("stomp"):
			should_bounce = false
			_change_state(State.STOMP)
	_update_air_boost(delta)
	if current_state == State.BOUNCE and custom_velocity.dot(local_up) <= 0.0:
		_change_state(State.JUMP)
	if velocity.y <= 0.0 and current_state != State.JUMP and current_state != State.STOMP and current_state != State.BOUNCE:
		flag.fall = true
	_update_auto_camera(delta)
	cam_yaw = lerp_angle(cam_yaw, target_yaw, camera_inertia * delta)
	cam_pitch = lerp(cam_pitch, target_pitch, camera_inertia * delta)
	if can_move and Input.is_action_just_pressed("roll"):
		var now_ms := Time.get_ticks_msec()
		var is_double := (now_ms - last_roll_tap_ms) <= int(double_tap_window * 1000.0)
		last_roll_tap_ms = now_ms
		var ground_like := current_state == State.GROUND or current_state == State.CRAWL or current_state == State.ROLL
		if is_double and grounded and ground_like and crawl_col != null and anim.has_animation("sonic_squat_kick"):
			last_roll_tap_ms = -100000
			_enter_squat_kick()
		elif current_state == State.GROUND and grounded:
			var flat_speed := (custom_velocity - custom_velocity.project(local_up)).length()
			if flat_speed < 1.0 and crawl_col != null:
				_enter_crawl()
			else:
				_enter_roll()
	if current_state == State.ROLL and custom_velocity.length() <= 0.1:
		if crawl_col != null and not _can_stand():
			_enter_crawl()
		else:
			_exit_roll()
	_sync_crawl_collision(delta)
	if jump_track_active and current_state != State.JUMP and current_state != State.GROUND and current_state != State.ROLL:
		jump_track_active = false
	if current_state == State.JUMP:
		if not flag.spring:
			var air_vertical = custom_velocity.project(local_up)
			var air_horizontal = custom_velocity - air_vertical
			air_horizontal = air_horizontal.move_toward(Vector3.ZERO, air_drag * delta)
			custom_velocity = air_horizontal + air_vertical
		if flag.dash:
			var upward_speed = custom_velocity.dot(local_up)
			if upward_speed > 120.0:
				custom_velocity -= local_up * (upward_speed - 120.0)
		elif not Input.is_action_pressed("jump") and not flag.spring and not select_rise and not bounce_rise:
			var upward_speed = custom_velocity.dot(local_up)
			if upward_speed > jump_force * 0.4:
				custom_velocity -= local_up * (upward_speed - (jump_force * 0.4))
				jump_was_cut = true
	var input_dir = Vector2.ZERO
	if wall_jump_control_lock <= 0.0 and can_move:
		input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if current_state == State.CRAWL:
		var wants_crawl: bool = can_move and (Input.is_action_pressed("roll") or input_dir.length() > 0.1)
		if not grounded and coyote_timer <= 0.0:
			_exit_crawl(false)
		elif not wants_crawl and _can_stand():
			_exit_crawl(true)
	if current_state == State.SQUAT_KICK:
		input_dir = Vector2.ZERO
		kick_timer -= delta
		if kick_timer <= 0.0:
			_end_squat_kick()
	var cam_basis = Basis.from_euler(Vector3(cam_pitch, cam_yaw, 0.0))
	var cam_forward_3d = -cam_basis.z.normalized()
	var cam_right_3d = cam_basis.x.normalized()
	var cam_right_on_sphere = cam_right_3d.slide(local_up).normalized()
	var cam_forward_on_sphere = local_up.cross(cam_right_on_sphere).normalized()
	var move_direction = (cam_right_on_sphere * input_dir.x + cam_forward_on_sphere * input_dir.y).normalized()
	loop_assist_active = grounded and local_up.dot(Vector3.UP) < cos(deg_to_rad(loop_assist_angle)) and custom_velocity.length() >= loop_min_speed
	if loop_assist_active:
		var along_surface = custom_velocity.slide(local_up)
		if along_surface.length() > 0.1:
			move_direction = along_surface.normalized()
	var horizontal_speed = (custom_velocity - custom_velocity.project(local_up)).length()
	if grounded and can_move and not loop_assist_active and (current_state == State.GROUND or current_state == State.BOOST):
		var brake_now_ms := Time.get_ticks_msec()
		var wish := input_dir.normalized() if input_dir.length() >= brake_input_threshold else Vector2.ZERO
		if Input.is_action_pressed("ui_up") and Input.is_action_pressed("ui_down"):
			wish = Vector2(Input.get_axis("ui_left", "ui_right"), 1.0).normalized()
		while brake_hist.size() > 0 and brake_now_ms - int(brake_hist[0][0]) > int(brake_window * 1000.0):
			brake_hist.pop_front()
		var brake_hit: Array = []
		if wish != Vector2.ZERO and horizontal_speed >= brake_min_speed:
			for h in brake_hist:
				if (h[1] as Vector2).dot(wish) <= -brake_back_dot:
					brake_hit = h
					break
		if not brake_hit.is_empty():
			brake_hist.clear()
			_start_brake(current_state == State.BOOST, brake_hit[2], maxf(brake_hit[3], horizontal_speed))
		elif wish != Vector2.ZERO:
			var cur_run := (custom_velocity - custom_velocity.project(local_up)).normalized()
			brake_hist.append([brake_now_ms, wish, cur_run, horizontal_speed])
	else:
		brake_hist.clear()
	if grounded and can_move and not loop_assist_active and (current_state == State.GROUND or current_state == State.BOOST) and _held(&"stomp") and horizontal_speed >= drift_min_speed and abs(input_dir.x) > 0.1:
		if current_state != State.DRIFT:
			drift_direction = custom_velocity.slide(local_up).normalized()
			flag.stomp = false
			_change_state(State.DRIFT)
	if current_state == State.DRIFT:
		if not grounded or not _held(&"stomp") or horizontal_speed < 5.0 or abs(input_dir.x) <= 0.1:
			var vertical_vel = custom_velocity.project(local_up)
			custom_velocity = drift_direction * horizontal_speed + vertical_vel
			flag.stomp = false
			set_physics_process(true)
			_change_state(State.GROUND)
		else:
			_on_drift(delta, input_dir)
	if current_state == State.BRAKE:
		var br_vertical = custom_velocity.project(local_up)
		var br_horizontal = custom_velocity - br_vertical
		var br_decel = boost_brake_deceleration if brake_from_boost else brake_deceleration
		var br_speed = move_toward(br_horizontal.length(), 0.0, br_decel * delta)
		var br_dir = br_horizontal.normalized() if br_horizontal.length() > 0.01 else Vector3.ZERO
		custom_velocity = br_dir * br_speed + br_vertical
		current_lean = move_toward(current_lean, 0.0, lean_speed * 2.0 * delta)
		model.rotation.z = current_lean
		brake_timer -= delta
		if brake_timer <= 0.0:
			_change_state(State.GROUND)
	if is_air_boosting:
		var ab_vertical = custom_velocity.project(local_up)
		var ab_horizontal = custom_velocity - ab_vertical
		var ab_dir = ab_horizontal.normalized()
		if ab_horizontal.length() < 1.0:
			var ab_angle = model.rotation.y
			ab_dir = (transform.basis * Vector3(sin(ab_angle), 0.0, cos(ab_angle))).slide(local_up).normalized()
		if move_direction.length() > 0.0:
			ab_dir = ab_dir.lerp(move_direction, air_boost_steer * delta).normalized()
		var ab_speed = move_toward(ab_horizontal.length(), air_boost_speed, air_boost_acceleration * delta)
		custom_velocity = ab_dir * ab_speed + ab_vertical
		var ab_local = transform.basis.inverse() * ab_dir
		model.rotation.y = lerp_angle(model.rotation.y, atan2(ab_local.x, ab_local.z), 8.0 * delta)
		current_lean = move_toward(current_lean, 0.0, lean_speed * delta)
		model.rotation.z = current_lean
	var autozone_active: bool = false
	if _autozone_pause > 0.0:
		_autozone_pause -= delta
	else:
		var az_dir: Vector3 = _autozone_steer(delta, input_dir, move_direction)
		if az_dir != Vector3.ZERO:
			move_direction = az_dir
			autozone_active = true
	var is_on_slope = local_up.dot(Vector3.UP) < 0.98
	var slope_pull = Vector3.ZERO
	if is_on_slope and current_state != State.JUMP and current_state != State.BOUNCE and current_state != State.WALL_CLING and current_state != State.DRIFT:
		var slope_dir = Vector3.DOWN.slide(local_up).normalized()
		var slope_steepness = local_up.cross(Vector3.UP).length()
		slope_pull = slope_dir * slope_steepness * gravity_force * 1.5
	if current_state != State.WALL_CLING and current_state != State.DRIFT and current_state != State.BRAKE and not is_air_boosting:
		if move_direction.length() > 0 and not is_homing_tracking:
			var local_move_dir = move_direction
			var vertical_vel = custom_velocity.project(local_up)
			var horizontal_vel = custom_velocity - vertical_vel
			var current_speed = horizontal_vel.length()
			if current_state == State.BOOST and not autozone_active:
				var current_dir = horizontal_vel.normalized()
				local_move_dir = current_dir.lerp(move_direction, 3.0 * delta).normalized()
			var is_air_move: bool = current_state == State.JUMP or current_state == State.BOUNCE
			var steer_top: float = boost_max_speed if current_state == State.BOOST else max_speed
			var steer_speed_ratio: float = clampf(current_speed / maxf(steer_top, 0.01), 0.0, 1.0)
			var skid_active: bool = false
			if (current_state == State.GROUND or current_state == State.BOOST or is_air_move) and not loop_assist_active and current_speed >= steer_deadzone_min_speed:
				var run_dir: Vector3 = horizontal_vel.normalized()
				var steer_angle: float = run_dir.signed_angle_to(move_direction, local_up)
				var dz: float = 0.0 if (is_air_move or autozone_active) else deg_to_rad(steer_deadzone_deg)
				var excess: float = maxf(absf(steer_angle) - dz, 0.0)
				var turn_factor: float = lerpf(1.0, turn_rate_top_factor, smoothstep(0.0, 1.0, steer_speed_ratio))
				var max_step: float = deg_to_rad(turn_rate_deg) * turn_factor * delta
				if is_air_move:
					max_step = deg_to_rad(air_turn_rate_deg) * delta
				elif current_state == State.BOOST:
					max_step *= boost_turn_mult
				if autozone_active:
					max_step = maxf(max_step, deg_to_rad(autozone_turn_rate_deg) * delta)
				var step: float = minf(excess, max_step)
				if current_state == State.GROUND and absf(steer_angle) > deg_to_rad(skid_angle_deg):
					skid_active = true
					step = 0.0
				local_move_dir = run_dir.rotated(local_up, signf(steer_angle) * step)
			if is_on_slope and current_state != State.JUMP and current_state != State.BOUNCE:
				var gravity_influence = slope_pull.dot(local_move_dir)
				current_speed += gravity_influence * delta
			if current_state == State.ROLL:
				current_speed = move_toward(current_speed, 0.0, roll_friction * delta)
			elif current_state == State.CRAWL:
				current_speed = move_toward(current_speed, crawl_speed, acceleration * delta)
			elif current_state == State.BOOST:
				current_speed = move_toward(current_speed, boost_max_speed, boost_acceleration * delta)
			else:
				if skid_active:
					current_speed = move_toward(current_speed, 0.0, skid_decel * delta)
				elif current_speed > max_speed:
					current_speed = move_toward(current_speed, max_speed, boost_acceleration * delta)
				else:
					var accel_factor: float = lerpf(1.0, accel_top_factor, steer_speed_ratio)
					current_speed = move_toward(current_speed, max_speed, acceleration * accel_factor * delta)
			custom_velocity = local_move_dir * current_speed + vertical_vel
			var local_forward = transform.basis.inverse() * local_move_dir
			var target_angle = atan2(local_forward.x, local_forward.z)
			var angle_diff = angle_difference(model.rotation.y, target_angle)
			if current_state == State.BOOST:
				model.rotation.y = lerp_angle(model.rotation.y, target_angle, 4.0 * delta)
			elif current_state == State.GROUND:
				model.rotation.y = lerp_angle(model.rotation.y, target_angle, minf(model_turn_speed * delta, 1.0))
			else:
				model.rotation.y = lerp_angle(model.rotation.y, target_angle, minf(model_turn_speed * delta, 1.0))
			if current_state == State.GROUND or current_state == State.BOOST:
				var active_max_speed = boost_max_speed if current_state == State.BOOST else max_speed
				var lean_mult = 2.5 if current_state == State.BOOST else 0.4
				var target_lean = angle_diff * lean_amount * lean_mult * clamp(current_speed / active_max_speed, 0.0, 1.0)
				current_lean = move_toward(current_lean, target_lean, lean_speed * delta)
			else:
				current_lean = move_toward(current_lean, 0.0, lean_speed * delta)
			model.rotation.z = current_lean
		elif not is_homing_tracking and wall_jump_control_lock <= 0.0:
			if is_on_slope and current_state != State.JUMP and current_state != State.BOUNCE:
				custom_velocity += slope_pull * delta
				if custom_velocity.length() > 0.1 and custom_velocity.normalized().dot(slope_pull.normalized()) < 0.0:
					var active_friction = roll_friction if (current_state == State.ROLL or current_state == State.SQUAT_KICK) else friction
					custom_velocity = custom_velocity.move_toward(Vector3.ZERO, active_friction * delta)
			else:
				var is_roll_like: bool = current_state == State.ROLL or current_state == State.SQUAT_KICK
				var active_friction = roll_friction if is_roll_like else friction
				var is_in_air: bool = not grounded or current_state in [State.JUMP, State.BOUNCE, State.LAUNCH]
				if not is_roll_like:
					var fr_ratio: float = clampf((custom_velocity - custom_velocity.project(local_up)).length() / maxf(max_speed, 0.01), 0.0, 1.0)
					active_friction *= lerpf(friction_mult_slow, friction_mult_fast, fr_ratio)
				if is_in_air:
					var coast_v: Vector3 = custom_velocity.project(local_up)
					var coast_h: Vector3 = custom_velocity - coast_v
					var air_fric = active_friction * (air_friction_mult if current_state in [State.JUMP, State.BOUNCE, State.LAUNCH] else 1.0)
					coast_h = coast_h.move_toward(Vector3.ZERO, air_fric * delta)
					custom_velocity = coast_h + coast_v
				else:
					var speed_before = custom_velocity.length()
					var speed_after = move_toward(speed_before, 0.0, active_friction * delta)
					if speed_before > 0.001:
						custom_velocity = custom_velocity.normalized() * speed_after
					else:
						custom_velocity = Vector3.ZERO
			current_lean = move_toward(current_lean, 0.0, lean_speed * delta)
			model.rotation.z = current_lean
	if current_state == State.WALL_CLING:
		custom_velocity += Vector3.DOWN * (gravity_force * wall_slide_gravity_mult) * delta
		custom_velocity.y = max(custom_velocity.y, -12.0)
		wall_cling_timer -= delta
		if wall_cling_timer <= 0.0:
			_change_state(State.JUMP)
	elif current_state == State.STOMP:
		custom_velocity = -local_up * stomp_spd
	elif current_state == State.BOUNCE:
		if custom_velocity.dot(local_up) > 0.0:
			custom_velocity += Vector3.DOWN * gravity_force * delta
	elif current_state != State.DRIFT:
		if current_state == State.LAUNCH and launch_hold_timer > 0.0:
			launch_hold_timer -= delta
			custom_velocity = launch_hold_velocity
		elif (current_state == State.JUMP or current_state == State.LAUNCH) and not is_homing_tracking:
			custom_velocity += Vector3.DOWN * gravity_force * delta
		elif current_state != State.JUMP:
			custom_velocity -= local_up * gravity_force * delta
	if current_state == State.QUICK_STEP:
		custom_velocity = quick_step_keep_velocity + custom_velocity.project(local_up)
	if current_state == State.HIT and not hit_is_stumble:
		custom_velocity = custom_velocity.project(local_up)
	var _pre_flat_speed: float = (custom_velocity - custom_velocity.project(local_up)).length()
	velocity = custom_velocity
	up_direction = local_up
	if local_up.dot(Vector3.UP) < 0.7 and current_state != State.JUMP and current_state != State.BOUNCE:
		motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	else:
		motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	move_and_slide()
	custom_velocity = velocity
	if current_state == State.BOOST and _pre_flat_speed > 5.0 and get_slide_collision_count() > 0:
		var _post_flat_speed: float = (custom_velocity - custom_velocity.project(local_up)).length()
		if _post_flat_speed <= 0.5:
			var _wc := get_last_slide_collision()
			if absf(_wc.get_normal().dot(local_up)) < 0.3:
				_boost_wall_lock = true
				_end_boost()
				current_state = State.GROUND
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(global_position, global_position - local_up * snap_length)
	query.exclude = _ray_excludes()
	var result = space_state.intersect_ray(query)
	var current_speed = custom_velocity.length()
	var is_fast_enough = current_speed >= loop_min_speed
	var was_grounded: bool = grounded
	grounded = false
	var ceiling_snap: bool = not result.is_empty() and result.normal.dot(Vector3.UP) < 0.0 and not was_grounded and coyote_timer <= 0.0
	if result and not ceiling_snap and not _is_rising():
		if is_fast_enough or result.normal.dot(Vector3.UP) > 0.5 or (current_state != State.JUMP and current_state != State.BOUNCE):
			var current_dist = global_position.distance_to(result.position)
			var snap_vector = -local_up * (current_dist - target_floor_dist)
			var _pos_before_snap: Vector3 = global_position
			move_and_collide(snap_vector)
			_cam_snap_offset -= global_position - _pos_before_snap
			grounded = true
			handle_surface(result.normal)
			_handle_landing()
		else:
			_apply_air_state(delta)
	elif get_slide_collision_count() > 0 and not _is_rising():
		var collision = get_last_slide_collision()
		var wall_normal = collision.get_normal()
		var is_wall = abs(wall_normal.dot(local_up)) < 0.3
		var hit_body = collision.get_collider()
		if hit_body and hit_body.is_in_group("LoopRail"):
			custom_velocity = custom_velocity.slide(wall_normal)
			_apply_air_state(delta)
		elif hit_body and hit_body.is_in_group("enemies"):
			custom_velocity = custom_velocity.slide(wall_normal)
			_apply_air_state(delta)
		elif is_wall:
			var in_air_state: bool = current_state in [State.JUMP, State.BOUNCE, State.STOMP, State.LAUNCH, State.DASH, State.HIT]
			var can_wall_run: bool = is_fast_enough and was_grounded and not in_air_state
			var is_jump_wall: bool = hit_body != null and hit_body.is_in_group("jump_wall")
			if current_state == State.JUMP and not can_double_jump and is_jump_wall:
				_enter_wall_cling(wall_normal)
			elif can_wall_run:
				grounded = true
				handle_surface(wall_normal)
				_handle_landing()
			elif current_state != State.WALL_CLING:
				custom_velocity = custom_velocity.slide(wall_normal)
				_apply_air_state(delta)
		elif wall_normal.dot(local_up) > 0.0:
			grounded = true
			handle_surface(wall_normal)
			_handle_landing()
		else:
			custom_velocity = custom_velocity.slide(wall_normal)
			_apply_air_state(delta)
	else:
		_apply_air_state(delta)
	if current_state != State.JUMP and current_state != State.BOUNCE and current_state != State.WALL_CLING and not is_fast_enough and local_up.dot(Vector3.UP) < 0.5:
		_change_state(State.JUMP)
		is_jumping = true
	if loop_assist_active and grounded:
		_apply_loop_assist(delta)
	update_camera()
	if has_node("CanvasLayer/ProgressBar"):
		$CanvasLayer/ProgressBar.max_value = max_boost_energy
		$CanvasLayer/ProgressBar.value = boost_energy
	perform_boost(delta)
	if current_state == State.HIT:
		input_dir = Vector2.ZERO
		velocity = Vector3.ZERO
		current_speed = Vector3.ZERO
func _process(_delta):
	_update_camera_follow(_delta)
	_update_camera_framing(_delta)
	if qte_cam_orbit and current_state == State.QTE_ACTIVE and not qte_fail_locked:
		target_yaw += deg_to_rad(qte_cam_orbit_speed) * _delta / maxf(Engine.time_scale, 0.01)
		cam_yaw = target_yaw
		update_camera()
	if current_state == State.HIT or is_intro:
		return
	var gamepad_vector = Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	if gamepad_vector.length() > 0.15 and not _camera_input_locked():
		cam_manual_timer = camera_manual_timeout
		target_yaw -= gamepad_vector.x * gamepad_sensitivity * _delta
		target_pitch -= gamepad_vector.y * gamepad_sensitivity * _delta
		target_pitch = clamp(target_pitch, -0.6, 0.6)
	var buttons = _get_ui_buttons()
	for button in buttons:
		if button.shortcut and not button.shortcut.events.is_empty():
			for event in button.shortcut.events:
				if event is InputEventAction:
					var action = event.action
					if Input.is_action_just_pressed(action):
						button.button_pressed = true
					elif Input.is_action_just_released(action):
						button.button_pressed = false
func _input(event):
	for a in TRACKED_ACTIONS:
		if event.is_action_pressed(a):
			_act_down[a] = true
		elif event.is_action_released(a):
			_act_down[a] = false
	if event.is_action_released(&"boost"):
		_boost_wall_lock = false
	if is_intro:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			var pressed_buttons: Array = []
			for button in _get_ui_buttons():
				var actions: Array = _button_actions(button)
				if actions.is_empty() or not button.get_global_rect().has_point(event.position):
					continue
				button.button_pressed = true
				pressed_buttons.append(button)
				for action in actions:
					_send_action(action, true)
			if not pressed_buttons.is_empty():
				_touch_buttons[event.index] = pressed_buttons
		else:
			var released_buttons: Array = _touch_buttons.get(event.index, [])
			_touch_buttons.erase(event.index)
			for button in released_buttons:
				if not is_instance_valid(button):
					continue
				button.button_pressed = false
				for action in _button_actions(button):
					_send_action(action, false)
func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if current_state == State.HIT or is_intro:
		return
	if _qte_blocked() and (qte_lock_camera or not (event is InputEventMouseMotion or event is InputEventScreenDrag)):
		return
	if (event is InputEventMouseMotion or event is InputEventScreenDrag) and _camera_input_locked():
		return
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			if event.relative.length() > 0.5:
				cam_manual_timer = camera_manual_timeout
			target_yaw -= event.relative.x * mouse_sensitivity
			target_pitch -= event.relative.y * mouse_sensitivity
			target_pitch = clamp(target_pitch, -0.6, 0.6)
	elif event is InputEventScreenDrag:
		cam_manual_timer = camera_manual_timeout
		target_yaw -= event.relative.x * mouse_sensitivity
		target_pitch -= event.relative.y * mouse_sensitivity
		target_pitch = clamp(target_pitch, -0.6, 0.6)
	if event.is_action_pressed("jump") and not event.is_echo():
		if event is InputEventMouseButton and event.device == -1:
			return
		_perform_jump_logic()
	if event.is_action_pressed("homing") and not event.is_echo() and current_state != State.SELECT_JUMP:
		if not is_on_floor():
			_perform_homing_logic()
		if homing_target_node != null:
			Audio.play("boost_1")
		if is_on_floor():
			perform_light_speed_dash()
func _exit_tree() -> void:
	Engine.time_scale = 1.0
func _intro_camera_swing(duration: float) -> void:
	var f: Vector3 = model.global_transform.basis.z
	f.y = 0.0
	if f.length() < 0.01:
		return
	f = f.normalized()
	var behind_yaw := atan2(-f.x, -f.z)
	var end_yaw := target_yaw + angle_difference(target_yaw, behind_yaw)
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "target_yaw", end_yaw, duration)
func _disable_root_tracks(anim_name: String) -> void:
	if not anim or not anim.has_animation(anim_name):
		return
	var a: Animation = anim.get_animation(anim_name)
	for i in a.get_track_count():
		var path = str(a.track_get_path(i))
		var parts = path.split(":")
		var node_part = parts[0]
		var prop = parts[1] if parts.size() > 1 else ""
		if node_part in [".", "", "..", "Sonic"] and prop in ["rotation", "position", "scale", "quaternion", "rotation_degrees", "transform"]:
			a.track_set_enabled(i, false)
			print("sn_jump: disabled track ", path)
func _setup_homing_area():
	homing_area = Area3D.new()
	var collision_shape = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = homing_range
	collision_shape.shape = sphere
	homing_area.add_child(collision_shape)
	add_child(homing_area)
	homing_area.monitorable = false
	homing_area.monitoring = true
func _setup_crawl_collision() -> void:
	crawl_col = get_node_or_null("CrawlCollision") as CollisionShape3D
	if crawl_col == null:
		crawl_col = find_child("CrawlCollision", true, false) as CollisionShape3D
	if crawl_col == null:
		push_warning("CrawlCollision не найден — ползание отключено")
		return
	for c in get_children():
		if c is CollisionShape3D and c != crawl_col:
			stand_col = c
			break
	if stand_col == null:
		push_warning("Обычный CollisionShape3D не найден среди детей игрока")
	crawl_col.disabled = true
	if anim and anim.has_animation("sonic_crawl_loop"):
		anim.get_animation("sonic_crawl_loop").loop_mode = Animation.LOOP_LINEAR
func _change_state(new_state: State):
	if current_state == State.HOMING and new_state != State.HOMING:
		is_homing_tracking = false
		homing_target_node = null
	if current_state == State.DRIFT and new_state != State.DRIFT:
		Audio.stop_loop("drift")
		_align_camera_to_direction(drift_direction)
	if new_state == State.DRIFT and current_state != State.DRIFT:
		Audio.play_loop("drift")
	var was_low := _is_low_state(current_state)
	var now_low := _is_low_state(new_state)
	var from_roll := current_state == State.ROLL and new_state == State.GROUND
	_roll_hold_active = from_roll
	_roll_hold_time = _roll_anim_remaining() if from_roll else 0.0
	if was_low and not now_low:
		if not _roll_hold_active:
			_set_crawl_collision(false)
	elif now_low and not was_low:
		_set_crawl_collision(true)
	if current_state == State.SQUAT_KICK and new_state != State.SQUAT_KICK and anim:
		anim.speed_scale = 1.0
	if current_state == State.BRAKE and new_state != State.BRAKE and anim:
		anim.speed_scale = 1.0
	current_state = new_state
	idle_timer = 0.0
	if new_state != State.LAUNCH:
		launch_hold_timer = 0.0
	if new_state != State.JUMP:
		ramp_anim_active = false
		after_homing = false
	if new_state != State.JUMP and is_air_boosting:
		_stop_air_boost()
	if new_state != State.JUMP and spin:
		spin.visible = false
func _update_spin() -> void:
	if in_hurdle:
		var full_height := (jump_force * jump_force) / (2.0 * gravity_force)
		var gained := global_position.y - jump_start_y
		if current_state != State.JUMP or custom_velocity.y <= 0.0 or gained >= hurdle_phase_fraction * full_height:
			in_hurdle = false
	if not double_jump_enabled:
		if current_state != State.JUMP or not is_jumping or is_homing_tracking or flag.dash or is_air_boosting:
			jump_fall_phase = false
		elif not jump_fall_phase and custom_velocity.y < 0.0:
			var full_h := (jump_force * jump_force) / (2.0 * gravity_force)
			var gained_h := global_position.y - jump_start_y
			if gained_h <= hurdle_phase_fraction * full_h:
				jump_fall_phase = true
	else:
		jump_fall_phase = false
	if not spin:
		return
	spin.visible = current_state == State.JUMP and is_jumping and can_double_jump and not after_homing and not jump_fall_phase and not is_air_boosting and not is_homing_tracking and not is_doing_trick and not flag.trick and not _is_homing_trick_playing() and not flag.dash and not in_hurdle
func _is_rising() -> bool:
	if current_state != State.JUMP and current_state != State.BOUNCE:
		return false
	return custom_velocity.dot(local_up) > 0.0 or (ramp_anim_active and custom_velocity.y > 0.0)
func _enter_roll():
	_change_state(State.ROLL)
func _exit_roll():
	_change_state(State.GROUND)
func _perform_jump_logic() -> void:
	if current_state == State.LAUNCH or current_state == State.SELECT_JUMP:
		return
	if current_state == State.WALL_CLING:
		_perform_wall_jump()
	elif (current_state == State.GROUND or current_state == State.ROLL or current_state == State.CRAWL) and (grounded or coyote_timer > 0.0):
		if current_state == State.CRAWL:
			if not _can_stand():
				return
			_exit_crawl(false)
		elif current_state == State.ROLL:
			_exit_roll()
		coyote_timer = 0.0
		var horizontal_vel = custom_velocity - custom_velocity.project(local_up)
		custom_velocity = horizontal_vel + local_up * jump_force
		custom_velocity.y = minf(custom_velocity.y, max_jump_up_speed)
		in_hurdle = true
		jump_start_y = global_position.y
		jump_track_active = true
		jump_was_cut = false
		is_jumping = true
		after_homing = false
		Audio.play("jump")
		Audio.play(["jumpM", "jumpL"].pick_random())
		can_double_jump = true
		jump_fall_phase = false
		can_homing_dash = true
		spin.visible = true
		flag.fall = false
		_change_state(State.JUMP)
	elif current_state == State.JUMP and can_double_jump and not is_homing_tracking:
		if double_jump_enabled:
			var horizontal_vel = custom_velocity - custom_velocity.project(Vector3.UP)
			custom_velocity = horizontal_vel + Vector3.UP * double_jump_force
		can_double_jump = false
		in_hurdle = false
		if anim.current_animation == "sonic_grindsquatjump":
			anim.play("sonic_ball", 0.0)
		spin.visible = false
func _perform_wall_jump():
	var flat_normal = current_wall_normal
	flat_normal.y = 0.0
	flat_normal = flat_normal.normalized()
	custom_velocity = (flat_normal * wall_jump_horizontal_force * 1.8) + (Vector3.UP * wall_jump_vertical_force * 1.6)
	local_up = Vector3.UP
	if flat_normal.length_squared() > 0.001:
		var local_forward = transform.basis.inverse() * flat_normal
		model.rotation.y = atan2(local_forward.x, local_forward.z)
	flag["dash"] = true
	wall_jump_control_lock = 0.4
	can_double_jump = false
	can_homing_dash = true
	is_jumping = true
	_change_state(State.JUMP)
func _enter_wall_cling(wall_normal: Vector3):
	_change_state(State.WALL_CLING)
	current_wall_normal = wall_normal
	wall_cling_timer = max_wall_cling_time
	custom_velocity = Vector3(0, custom_velocity.y * 0.1, 0)
	var local_forward = transform.basis.inverse() * wall_normal
	model.rotation.y = atan2(local_forward.x, local_forward.z)
func _on_stomp():
	anim.play("global/sn_stomp")
	_change_state(State.STOMP)
	custom_velocity = -local_up * stomp_spd
	flag.stomp = true
	is_jumping = false
	flag.fall = false
func bounce_off_enemy(force: float = -1.0) -> void:
	flag.stomp = false
	should_bounce = false
	is_jumping = true
	after_homing = false
	can_homing_dash = true
	can_double_jump = true
	jump_start_y = global_position.y
	_change_state(State.JUMP)
	custom_velocity = local_up * (homing_bounce_force if force < 0.0 else force)
	velocity = custom_velocity
	bounce_rise = true
	flag.dash = false
	flag.fall = false
func perform_bounce() -> void:
	_change_state(State.BOUNCE)
	custom_velocity = local_up * bounce_velocity
func _perform_homing_logic():
	if current_state != State.JUMP:
		return
	in_hurdle = false
	var target = _find_homing_target()
	if target:
		if current_state == State.ROLL:
			_exit_roll()
		_change_state(State.HOMING)
		is_jumping = true
		homing_target_node = target
		jump_track_active = false
		homing_timer = homing_max_time
		is_homing_tracking = true
		can_homing_dash = false
		can_double_jump = false
		grounded = false
		custom_velocity = Vector3.ZERO
		velocity = Vector3.ZERO
func _homing_physics(delta: float) -> void:
	homing_timer -= delta
	var target_ok: bool = is_instance_valid(homing_target_node) and not (homing_target_node.has_method("can_be_homed") and not homing_target_node.call("can_be_homed"))
	if not target_ok or homing_timer <= 0.0:
		_end_homing()
		return
	cam_yaw = lerp_angle(cam_yaw, target_yaw, camera_inertia * delta)
	cam_pitch = lerp(cam_pitch, target_pitch, camera_inertia * delta)
	var to_target: Vector3 = _homing_point(homing_target_node) - global_position
	var dist: float = to_target.length()
	if dist <= maxf(homing_hit_distance, homing_force * delta):
		_homing_hit()
		update_camera()
		return
	var dir: Vector3 = to_target / dist
	custom_velocity = dir * homing_force
	velocity = custom_velocity
	var col: KinematicCollision3D = move_and_collide(dir * minf(homing_force * delta, dist))
	if col:
		var hit_obj := col.get_collider() as Node
		if hit_obj != null and (hit_obj == homing_target_node or _resolve_enemy(hit_obj) == homing_target_node):
			_homing_hit()
			update_camera()
			return
		if col.get_normal().dot(Vector3.UP) > 0.7:
			move_and_collide(col.get_remainder().slide(col.get_normal()))
		else:
			_end_homing()
			update_camera()
			return
	grounded = false
	var flat: Vector3 = dir.slide(local_up)
	if flat.length() > 0.01:
		var local_forward: Vector3 = transform.basis.inverse() * flat.normalized()
		model.rotation.y = atan2(local_forward.x, local_forward.z)
	is_doing_trick = false
	flag.trick = false
	anim.speed_scale = 1.0
	if anim.current_animation != "sonic_ball":
		anim.play("sonic_ball", 0.0)
	update_camera()
func _end_homing() -> void:
	is_homing_tracking = false
	homing_target_node = null
	can_homing_dash = true
	custom_velocity = Vector3.ZERO
	velocity = Vector3.ZERO
	_change_state(State.JUMP)
func _homing_hit_spring(spring: Node) -> void:
	is_homing_tracking = false
	homing_target_node = null
	homing_timer = 0.0
	can_homing_dash = true
	if spring.has_method("_on_body_entered"):
		spring.call("_on_body_entered", self)
	else:
		perform_spring()
func _homing_hit() -> void:
	var old_target = homing_target_node
	if old_target != null and is_instance_valid(old_target) and (old_target is Spring or old_target.is_in_group("Spring")):
		_homing_hit_spring(old_target)
		return
	_change_state(State.JUMP)
	is_jumping = true
	after_homing = true
	if spin:
		spin.visible = false
	custom_velocity = local_up * homing_bounce_force
	velocity = custom_velocity
	bounce_rise = true
	flag.dash = false
	flag.fall = false
	is_homing_tracking = false
	homing_target_node = null
	can_homing_dash = true
	can_double_jump = true
	jump_start_y = global_position.y
	_play_homing_trick()
	if old_target:
		if old_target.has_method("on_homing_hit"):
			old_target.on_homing_hit(self)
		elif "Homing" in old_target and old_target.Homing == true:
			old_target.destroy()
		elif old_target.has_method("die"):
			old_target.die()
		ignored_homing_targets.append(old_target)
		get_tree().create_timer(1.0).timeout.connect(func(): ignored_homing_targets.erase(old_target))
func _play_homing_trick() -> void:
	flag.trick = false
	is_doing_trick = true
	trick_token += 1
	var token: int = trick_token
	if spin:
		spin.visible = false
	var trick_name: String = "sonic_homing_act0" + str(randi() % 6)
	if not anim.has_animation(trick_name):
		trick_name = "global/sn_homing_act00"
	if anim.has_animation(trick_name):
		anim.speed_scale = 1.0
		anim.play(trick_name)
	get_tree().create_timer(0.8).timeout.connect(func():
		if token == trick_token:
			is_doing_trick = false
	)
func _is_homing_trick_playing() -> bool:
	if anim == null or not anim.is_playing():
		return false
	return "homing_act" in String(anim.current_animation)
func _on_trick_anim_finished(anim_name: String) -> void:
	if anim_name == "global/sn_homing_act00":
		flag.trick = false
func _update_enemy_collision() -> void:
	var phase_through: bool = is_homing_tracking or is_air_boosting or current_state == State.BOOST or current_state == State.SQUAT_KICK or current_state == State.JUMP or current_state == State.STOMP or current_state == State.BOUNCE
	for e in get_tree().get_nodes_in_group("enemies"):
		var body := e as PhysicsBody3D
		if body == null or not body.has_method("on_homing_hit"):
			continue
		var ignore: bool = phase_through or ("is_flying" in body and body.is_flying)
		var id: int = body.get_instance_id()
		if _enemy_ignored.get(id, false) == ignore:
			continue
		_enemy_ignored[id] = ignore
		if ignore:
			add_collision_exception_with(body)
			body.add_collision_exception_with(self)
		else:
			remove_collision_exception_with(body)
			body.remove_collision_exception_with(self)
func _ray_excludes() -> Array[RID]:
	var f: int = Engine.get_physics_frames()
	if f != _ex_frame:
		_ex_frame = f
		_ex_cache = [get_rid()]
		for e in get_tree().get_nodes_in_group("enemies"):
			if e is CollisionObject3D:
				_ex_cache.append(e.get_rid())
	return _ex_cache
func _resolve_enemy(obj: Node) -> Node3D:
	var n: Node = obj
	for i in 10:
		if n == null:
			break
		if n.has_method("on_homing_hit"):
			return n as Node3D
		n = n.get_parent()
	return obj as Node3D
func _homing_point(obj: Node3D) -> Vector3:
	if obj.has_method("get_homing_point"):
		return obj.call("get_homing_point")
	if obj is CharacterBody3D or obj is StaticBody3D:
		return obj.global_position + Vector3(0, 0.5, 0)
	return obj.global_position
func _find_homing_target() -> Node3D:
	var best_target: Node3D = null
	var min_dist: float = INF
	var space_state = get_world_3d().direct_space_state
	var origin: Vector3 = global_position + Vector3(0, 0.5, 0)
	for raw in get_tree().get_nodes_in_group("enemies"):
		var obj = _resolve_enemy(raw)
		if obj == null or obj == self or not is_instance_valid(obj) or not obj.is_inside_tree():
			continue
		if obj in ignored_homing_targets:
			continue
		if obj.has_method("can_be_homed") and not obj.call("can_be_homed"):
			if debug_homing: print("[homing] ", obj.name, " пропущен: can_be_homed() = false")
			continue
		var dist: float = global_position.distance_to(_homing_point(obj))
		if dist > homing_range or dist >= min_dist:
			if debug_homing: print("[homing] ", obj.name, " пропущен: dist=", dist)
			continue
		var target_pos: Vector3 = _homing_point(obj)
		var ray_query = PhysicsRayQueryParameters3D.create(origin, target_pos)
		ray_query.exclude = _ray_excludes()
		var ray_hit: Dictionary = space_state.intersect_ray(ray_query)
		var is_egg: bool = obj.has_method("on_homing_hit")
		var tolerance: float = 0.5 if is_egg else 1.5
		if not ray_hit.is_empty() and ray_hit.position.distance_to(target_pos) > tolerance:
			continue
		min_dist = dist
		best_target = obj as Node3D
	return best_target
func _set_crawl_collision(on: bool) -> void:
	if crawl_col == null:
		return
	_crawl_col_on = on
	crawl_col.set_deferred("disabled", not on)
	if stand_col != null:
		stand_col.set_deferred("disabled", on)
	if head_col != null:
		head_col.set_deferred("disabled", on)
func _roll_anim_remaining() -> float:
	if anim == null:
		return 0.0
	var n: String = String(anim.assigned_animation)
	if n != "sonic_sliding" or not anim.has_animation(n):
		return 0.0
	var a: Animation = anim.get_animation(n)
	if a == null or a.loop_mode != Animation.LOOP_NONE:
		return 0.0
	return maxf(a.length - anim.current_animation_position, 0.0) / maxf(absf(anim.speed_scale), 0.01)
func _sync_crawl_collision(delta: float) -> void:
	if crawl_col == null:
		return
	var want_low: bool = _is_low_state(current_state)
	if want_low:
		_roll_hold_active = false
	elif _roll_hold_active:
		if current_state != State.GROUND:
			_roll_hold_active = false
		else:
			_roll_hold_time = maxf(_roll_hold_time - delta, 0.0)
			if _roll_hold_time > 0.0 or not _can_stand():
				want_low = true
			else:
				_roll_hold_active = false
	if want_low != _crawl_col_on:
		_set_crawl_collision(want_low)
func _can_stand() -> bool:
	if not crawl_check_ceiling or stand_col == null or stand_col.shape == null:
		return true
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = stand_col.shape
	var t := stand_col.global_transform
	t.origin += local_up * 0.08
	q.transform = t
	q.collision_mask = collision_mask
	q.exclude = _ray_excludes()
	q.collide_with_areas = false
	return get_world_3d().direct_space_state.intersect_shape(q, 1).is_empty()
func _is_low_state(st: State) -> bool:
	return st == State.CRAWL or st == State.SQUAT_KICK or st == State.ROLL
func _enter_crawl() -> void:
	_change_state(State.CRAWL)
	if anim and anim.has_animation("sonic_stand_squat"):
		anim.speed_scale = 1.0
		anim.play("sonic_stand_squat", 0.1)
func _exit_crawl(play_standup: bool = true) -> void:
	_change_state(State.GROUND)
	if play_standup and standup_after_crawl:
		_play_standup()
func _enter_squat_kick() -> void:
	_change_state(State.SQUAT_KICK)
	var a = anim.get_animation("sonic_squat_kick")
	kick_timer = (a.length / squat_kick_speed) if a != null else 0.4
	anim.speed_scale = squat_kick_speed
	Audio.play("boost_3")
	anim.play("sonic_squat_kick", 0.05)
func _end_squat_kick() -> void:
	anim.speed_scale = 1.0
	var raw_input := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var still_held: bool = can_move and (Input.is_action_pressed("roll") or raw_input.length() > 0.1)
	if still_held or not _can_stand():
		_change_state(State.CRAWL)
		if anim.has_animation("sonic_stand_squat"):
			anim.play("sonic_stand_squat", 0.1)
	else:
		_exit_crawl(false)
func _play_standup() -> void:
	if anim and anim.has_animation("sonic_standup_B"):
		anim.speed_scale = 1.0
		anim.play("sonic_standup_B", 0.1)
func _start_brake(from_boost: bool, run_dir: Vector3 = Vector3.ZERO, run_speed: float = 0.0) -> void:
	brake_from_boost = from_boost
	if run_dir != Vector3.ZERO:
		custom_velocity = run_dir * run_speed + custom_velocity.project(local_up)
		var run_local := transform.basis.inverse() * run_dir
		model.rotation.y = atan2(run_local.x, run_local.z)
	if from_boost:
		is_boosting = false
		_boost_hide()
		Audio.stop("boost")
	_change_state(State.BRAKE)
	Audio.play("brake")
	var anim_name := "sonic_brake_L_ME" if from_boost else "sonic_brake_E_L"
	if not anim.has_animation(anim_name) and anim.has_animation("global/" + anim_name):
		anim_name = "global/" + anim_name
	var brake_speed := boost_brake_anim_speed if from_boost else brake_anim_speed
	brake_speed = maxf(brake_speed, 0.01)
	var t := brake_lock_time
	if anim.has_animation(anim_name):
		anim.speed_scale = brake_speed
		anim.play(anim_name, 0.05)
		t = maxf(t, anim.get_animation(anim_name).length / brake_speed)
	brake_timer = t
func _apply_loop_assist(delta: float) -> void:
	var along = custom_velocity.slide(local_up)
	if along.length() < 0.1:
		return
	var right = along.normalized().cross(local_up).normalized()
	var space = get_world_3d().direct_space_state
	var extents = [0.0, 0.0]
	for i in 2:
		var side = -1.0 if i == 0 else 1.0
		var off = loop_scan_step
		while off <= loop_half_width:
			var origin = global_position + right * side * off + local_up * 0.6
			var q = PhysicsRayQueryParameters3D.create(origin, origin - local_up * 2.0)
			q.exclude = _ray_excludes()
			var hit = space.intersect_ray(q)
			var is_floor = hit and hit.normal.dot(local_up) > 0.6
			if is_floor and hit.collider and hit.collider.is_in_group("LoopRail"):
				is_floor = false
			if not is_floor:
				break
			extents[i] = off
			off += loop_scan_step
	var center_off = (extents[1] - extents[0]) * 0.5
	if abs(center_off) > 0.05:
		move_and_collide(right * center_off * min(loop_center_speed * delta, 1.0))
func _cache_boost_geoms(node: Node) -> void:
	if node is SpriteBase3D:
		_boost_geoms.append({"t": "sprite", "n": node, "a": node.modulate.a})
	elif node is GeometryInstance3D:
		var found := false
		if node.material_override is BaseMaterial3D:
			var m: BaseMaterial3D = node.material_override.duplicate()
			node.material_override = m
			_boost_add_mat(m)
			found = true
		elif node is MeshInstance3D and node.mesh:
			for i in node.mesh.get_surface_count():
				var sm = node.get_active_material(i)
				if sm is BaseMaterial3D:
					var m2: BaseMaterial3D = sm.duplicate()
					node.set_surface_override_material(i, m2)
					_boost_add_mat(m2)
					found = true
		elif node is GPUParticles3D:
			for i in node.draw_passes:
				var pm: Mesh = node.get_draw_pass_mesh(i)
				if pm == null:
					continue
				pm = pm.duplicate()
				node.set_draw_pass_mesh(i, pm)
				for si in pm.get_surface_count():
					var pmat = pm.surface_get_material(si)
					if pmat is BaseMaterial3D:
						var m3: BaseMaterial3D = pmat.duplicate()
						pm.surface_set_material(si, m3)
						_boost_add_mat(m3)
						found = true
		if not found:
			_boost_geoms.append({"t": "geom", "n": node, "o": node.transparency})
	for c in node.get_children():
		_cache_boost_geoms(c)
func _boost_add_mat(m: BaseMaterial3D) -> void:
	_boost_geoms.append({"t": "mat", "m": m, "a": m.albedo_color.a, "mode": m.transparency})
func _set_boost_fade(k: float) -> void:
	_boost_fade_k = k
	for e in _boost_geoms:
		match e["t"]:
			"mat":
				var m: BaseMaterial3D = e["m"]
				var c: Color = m.albedo_color
				c.a = e["a"] * k
				m.albedo_color = c
				if k >= 1.0:
					m.transparency = e["mode"]
				elif e["mode"] == BaseMaterial3D.TRANSPARENCY_DISABLED:
					m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			"sprite":
				if is_instance_valid(e["n"]):
					var sc: Color = e["n"].modulate
					sc.a = e["a"] * k
					e["n"].modulate = sc
			"geom":
				if is_instance_valid(e["n"]):
					e["n"].transparency = lerpf(1.0, e["o"], k)
func _boost_show() -> void:
	if not is_instance_valid(boost) or _boost_want:
		return
	_boost_want = true
	if _boost_fade_tween and _boost_fade_tween.is_valid():
		_boost_fade_tween.kill()
	_set_boost_fade(0.0)
	boost.show()
	_boost_fade_tween = create_tween()
	_boost_fade_tween.tween_method(_set_boost_fade, 0.0, 1.0, maxf(boost_fade_in_time, 0.01)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
func _boost_hide() -> void:
	if not is_instance_valid(boost) or not _boost_want:
		return
	_boost_want = false
	if _boost_fade_tween and _boost_fade_tween.is_valid():
		_boost_fade_tween.kill()
	_set_boost_fade(0.0)
	boost.hide()
func _boost_camera_kick() -> void:
	if _boost_cam_tween and _boost_cam_tween.is_valid():
		_boost_cam_tween.kill()
	boost_cam_offset = boost_cam_kick_distance
	_boost_cam_tween = create_tween()
	_boost_cam_tween.tween_property(self, "boost_cam_offset", 0.0, maxf(boost_cam_return_time, 0.01)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
func perform_boost(delta: float) -> void:
	if _boost_wall_lock and not Input.is_action_pressed(&"boost"):
		_boost_wall_lock = false
	if current_state == State.BOOST and boost_energy <= 0.0:
		_end_boost()
		current_state = State.GROUND
	var boost_flat_speed: float = (custom_velocity - custom_velocity.project(local_up)).length()
	if can_move and Input.is_action_just_pressed("boost") and boost_energy > 5.0 and current_state == State.GROUND and boost_flat_speed > 0.1:
		if current_state != State.BOOST:
			current_state = State.BOOST
			var random_boost_sound = ["boost_1", "boost_2", "boost_3"].pick_random()
			Audio.play(random_boost_sound)
			Audio.play("boost")
			_boost_camera_kick()
			var anim_player = get_tree().get_first_node_in_group("BoostBar") as AnimationPlayer
			if anim_player:
				anim_player.stop()
				if shockwave_rect:
					shockwave_rect.visible = true
				anim_player.play("Main")
			if custom_velocity.length() > 0.1:
				_boost_show()
	if shockwave_rect and boost_camera:
		var anim_player = get_tree().get_first_node_in_group("BoostBar") as AnimationPlayer
		if anim_player and anim_player.is_playing() and anim_player.current_animation == "Main":
			var screen_pos = boost_camera.unproject_position(global_position)
			var screen_size = get_viewport().get_visible_rect().size
			var mat = shockwave_rect.material as ShaderMaterial
			if mat:
				mat.set_shader_parameter("center", screen_pos / screen_size)
		else:
			if shockwave_rect.visible:
				shockwave_rect.visible = false
	if current_state == State.BOOST:
		if _held(&"boost") and boost_energy > 0.0:
			if boost_flat_speed > 0.1:
				boost_energy -= 20.0 * delta
			is_boosting = true
			if custom_velocity.length() > 0.1:
				_boost_show()
			else:
				_boost_hide()
		else:
			_end_boost()
			current_state = State.GROUND
		if boost_energy <= 0.0:
			boost_energy = 0.0
			_end_boost()
			current_state = State.GROUND
		boost_energy = clamp(boost_energy, 0.0, max_boost_energy)
func _start_air_boost() -> void:
	is_air_boosting = true
	is_boosting = true
	in_hurdle = false
	var random_boost_sound = ["boost_1", "boost_2", "boost_3"].pick_random()
	Audio.play(random_boost_sound)
	Audio.play("boost")
	_boost_camera_kick()
	var anim_player = get_tree().get_first_node_in_group("BoostBar") as AnimationPlayer
	if anim_player:
		anim_player.stop()
		if shockwave_rect:
			shockwave_rect.visible = true
		anim_player.play("Main")
	_boost_show()
func _stop_air_boost() -> void:
	if not is_air_boosting:
		return
	is_air_boosting = false
	is_boosting = false
	Audio.stop("boost")
	_boost_hide()
func _update_air_boost(delta: float) -> void:
	if not is_air_boosting:
		if can_move and wall_jump_control_lock <= 0.0 and current_state == State.JUMP and not is_homing_tracking \
				and Input.is_action_just_pressed("boost") and boost_energy > 5.0:
			_start_air_boost()
		else:
			return
	if current_state != State.JUMP or is_homing_tracking or not can_move \
			or not _held(&"boost") or boost_energy <= 0.0:
		_stop_air_boost()
		return
	boost_energy = maxf(boost_energy - air_boost_energy_cost * delta, 0.0)
	_boost_show()
func perform_quick_step(direction: float) -> void:
	if is_quick_stepping or not grounded or loop_assist_active:
		return
	if current_state != State.GROUND and current_state != State.BOOST and current_state != State.ROLL:
		return
	is_quick_stepping = true
	_autozone_pause = autozone_quick_step_pause
	Audio.play("step")
	if randf() < 0.5:
		Audio.play("sonic_stepL")
	else:
		Audio.play("sonic_stepR")
	quick_step_dir = direction
	var previous_state = current_state
	current_state = State.QUICK_STEP
	var cam_basis = Basis.from_euler(Vector3(cam_pitch, cam_yaw, 0.0))
	var cam_right_3d = cam_basis.x.normalized()
	var cam_right_on_sphere = cam_right_3d.slide(local_up).normalized()
	var side_dir = cam_right_on_sphere * direction
	quick_step_keep_velocity = custom_velocity - custom_velocity.project(local_up)
	var side_dist: float = quick_step_distance
	var side_motion: Vector3 = side_dir * side_dist
	var wall_hit = move_and_collide(side_motion, true)
	if wall_hit and wall_hit.get_normal().dot(local_up) < 0.9:
		side_dist = wall_hit.get_travel().length()
	var st: Dictionary = {"last": 0.0}
	var tween = create_tween()
	quick_step_tween = tween
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_method(_quick_step_slide.bind(st, side_dir), 0.0, side_dist, quick_step_duration)
	tween.tween_callback(func():
		is_quick_stepping = false
		if current_state != State.QUICK_STEP:
			return
		current_state = previous_state
	)
	if has_node("CanvasLayer") and OS.has_feature("android"):
		Input.vibrate_handheld(50)
func _quick_step_slide(v: float, st: Dictionary, side_dir: Vector3) -> void:
	var d: float = v - st["last"]
	st["last"] = v
	move_and_collide(side_dir * d)
func _cancel_quick_step() -> void:
	if quick_step_tween and quick_step_tween.is_valid():
		quick_step_tween.kill()
	quick_step_tween = null
	is_quick_stepping = false
func _on_texture_button_left_pressed() -> void:
	if can_move == true:
		perform_quick_step(-1.0)
		Audio.play("step")
func _on_texture_button_right_pressed() -> void:
	if can_move == true:
		perform_quick_step(1.0)
		Audio.play("step")
func _on_drift(delta, input_dir):
	var vertical_vel = custom_velocity.project(local_up)
	var current_speed = (custom_velocity - vertical_vel).length()
	var rotation_angle = -input_dir.x * drift_steer_speed * delta
	drift_direction = drift_direction.rotated(local_up, rotation_angle).normalized()
	var target_drift_speed = boost_max_speed if _held(&"boost") else max_speed
	current_speed = move_toward(current_speed, target_drift_speed, boost_acceleration * drift_friction_reduction * delta)
	custom_velocity = drift_direction * current_speed + vertical_vel
	velocity = custom_velocity
	var local_forward = transform.basis.inverse() * drift_direction
	var target_facing_angle = atan2(local_forward.x, local_forward.z)
	drift_visual_angle = lerp_angle(drift_visual_angle, target_facing_angle, 15.0 * delta)
	model.rotation.y = drift_visual_angle
	current_lean = move_toward(current_lean, -input_dir.x * drift_lean_amount, lean_speed * 1.5 * delta)
	model.rotation.z = current_lean
	anim.speed_scale = 1.5
	Audio.play_loop("drift")
func handle_surface(surface_normal: Vector3):
	local_up = surface_normal
	custom_velocity = custom_velocity.slide(surface_normal)
	align_to_surface(surface_normal)
func align_to_surface(normal: Vector3):
	var forward_reference = -transform.basis.z
	var planar_vel = custom_velocity.slide(normal)
	if planar_vel.length() > 0.1:
		var move_dir = planar_vel.normalized()
		if move_dir.dot(forward_reference) > 0.0:
			forward_reference = move_dir
		else:
			forward_reference = -move_dir
	forward_reference = forward_reference.slide(normal)
	if forward_reference.length() < 0.01:
		forward_reference = transform.basis.x.cross(normal)
	forward_reference = forward_reference.normalized()
	var new_right = forward_reference.cross(normal).normalized()
	var new_forward = normal.cross(new_right).normalized()
	var target_basis = Basis(new_right, normal, -new_forward).orthonormalized()
	var blend_speed = 15.0 * get_physics_process_delta_time()
	transform.basis = transform.basis.orthonormalized().slerp(target_basis, clamp(blend_speed, 0.0, 1.0))
func _apply_air_state(delta):
	if is_doing_trick:
		return
	if current_state != State.WALL_CLING:
		if not is_homing_tracking:
			local_up = local_up.move_toward(Vector3.UP, 2.0 * delta)
		align_to_surface(local_up)
	if is_homing_tracking:
		return
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") if wall_jump_control_lock <= 0.0 else Vector2.ZERO
	update_animations(current_state == State.JUMP, input_dir)
func _handle_landing():
	ramp_anim_active = false
	dashring_anim_active = false
	_stop_air_boost()
	spin.visible = false
	jump_fall_phase = false
	in_hurdle = false
	var was_stomp = current_state == State.STOMP
	var was_jump: bool = current_state == State.JUMP
	var land_h_speed: float = (custom_velocity - custom_velocity.project(local_up)).length()
	var land_full_jump: bool = jump_track_active and not jump_was_cut
	jump_track_active = false
	after_homing = false
	flag.dash = false
	flag.trick = false
	flag.spring = false
	Audio.stop("rail")
	is_jumping = false
	is_doing_trick = false
	can_double_jump = false
	can_homing_dash = false
	is_homing_tracking = false
	homing_target_node = null
	flag["fall"] = false
	flag.stomp = false
	if was_stomp and should_bounce:
		should_bounce = false
		perform_bounce()
		return
	if current_state == State.JUMP or current_state == State.WALL_CLING or current_state == State.STOMP:
		_change_state(State.GROUND)
	if was_stomp:
		Audio.play("land")
		stomp.play("stomp")
		anim.play("sonic_squat_loop", 0.3, 2.0)
		if current_state != State.GRINDING and current_rail == null:
			var squat_time := 0.5
			if anim.has_animation("sonic_squat_loop"):
				squat_time = anim.get_animation("sonic_squat_loop").length / 2.0 + 0.1
			set_physics_process(false)
			await get_tree().create_timer(squat_time).timeout
			set_physics_process(true)
	if was_jump and land_full_jump and not was_stomp and land_h_speed < jump_land_max_speed and current_state == State.GROUND:
		var land_name := _jump_land_anim_name()
		if land_name != "":
			anim.get_animation(land_name).loop_mode = Animation.LOOP_NONE
			anim.speed_scale = 1.0
			anim.play(land_name, 0.1)
			jump_land_active = true
			return
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") if wall_jump_control_lock <= 0.0 else Vector2.ZERO
	update_animations(false, input_dir)
func _jump_land_anim_name() -> String:
	if anim.has_animation("sonic_jump_E_L"):
		$smoke/GPUParticles3D.emitting = true 
		return "sonic_jump_E_L"
	if anim.has_animation("global/sonic_jump_E_L"):
		return "global/sonic_jump_E_L"
	return ""
func update_animations(in_air: bool, input_dir: Vector2 = Vector2.ZERO):
	if is_intro and grounded and current_state == State.GROUND:
		anim.speed_scale = 1.0
		if not intro_anim_started and anim.has_animation("sonic_startI"):
			intro_anim_started = true
			anim.play("sonic_startI")
		return
	if flag.spring == true:
		anim.speed_scale = 1.0
		if anim.current_animation != "sonic_jump_spring":
			anim.play("sonic_jump_spring", 0.1, 1.0)
		return
	if dashring_anim_active:
		if current_state != State.LAUNCH or anim.current_animation != _dashring_anim_name:
			dashring_anim_active = false
		else:
			return
	if current_state == State.GRINDING:
		if is_rail_quick_stepping:
			return
		anim.play("sonic_grind_stand")
		return
	if flag.trick == true:
		_play_homing_trick()
		return
	if current_state == State.HIT:
		if hit_standing_up:
			return
		var hit_anim: String = "sonic_stumble_runC" if hit_is_stumble else "Sonic_damage_B"
		if anim.has_animation(hit_anim) and anim.assigned_animation != hit_anim:
			anim.speed_scale = stumble_anim_speed if hit_is_stumble else _hit_speed
			anim.play(hit_anim, 0.1)
		return
	if current_state == State.CRAWL:
		anim.speed_scale = 1.0
		if input_dir.length() > 0.1:
			if anim.has_animation("sonic_crawl_loop") and anim.assigned_animation != "sonic_crawl_loop":
				anim.play("sonic_crawl_loop", 0.15)
		elif anim.has_animation("sonic_stand_squat") and anim.assigned_animation != "sonic_stand_squat":
			anim.play("sonic_stand_squat", 0.15)
		return
	if current_state == State.SQUAT_KICK:
		return
	if current_state == State.BRAKE:
		return
	if jump_land_active:
		var land_name := _jump_land_anim_name()
		if current_state == State.GROUND and land_name != "" and anim.current_animation == land_name and anim.is_playing() and custom_velocity.length() < jump_land_cancel_speed:
			return
		jump_land_active = false
	if current_state == State.JUMP and anim.current_animation == "sonic_grindsquatjump" and anim.is_playing() and custom_velocity.y > 0.0:
		return
	if anim.current_animation == "sonic_standup_B" and anim.is_playing() and not in_air and input_dir.length() < 0.1 and custom_velocity.length() < 0.5:
		return
	if current_state == State.LIGHT_SPEED_DASH:
		anim.speed_scale = 2.0
		if anim.has_animation("sonic_wall_jump_loop_A") and anim.current_animation != "sonic_wall_jump_loop_A":
			anim.play("sonic_wall_jump_loop_A", 0.05)
		return
	if not anim: return
	if anim.current_animation == "sonic_squat_loop" and anim.is_playing():
		return
	if current_state == State.STOMP:
		anim.speed_scale = 1.0
		if anim.current_animation != "sonic_stomping_loop":
			anim.play("sonic_stomping_loop", 0.1)
		return
	if current_state == State.BOUNCE:
		anim.speed_scale = 1.0
		if custom_velocity.dot(local_up) <= 0.0:
			if anim.current_animation != "sonic_stomping_loop":
				anim.play("sonic_stomping_loop", 0.1)
		else:
			if anim.current_animation != "sonic_ball":
				anim.play("sonic_ball", 0.0)
		return
	if current_state == State.WALL_CLING:
		anim.speed_scale = 0.8
		if anim.current_animation != "sonic_wall_stick_D_loop":
			anim.play("sonic_wall_stick_D_loop", 0.0)
		return
	if is_air_boosting and current_state == State.JUMP:
		anim.speed_scale = 1.0
		var ab_anim := "sonic_airboost" if anim.has_animation("sonic_airboost") else "global/sonic_airboost"
		if anim.has_animation(ab_anim) and anim.current_animation != ab_anim:
			anim.play(ab_anim, 0.1)
		return
	if ramp_anim_active and current_state == State.JUMP:
		var ramp_name: String = _ramp_anim_name()
		if ramp_name != "":
			if anim.assigned_animation != ramp_name:
				anim.get_animation(ramp_name).loop_mode = Animation.LOOP_NONE
				anim.speed_scale = 1.0
				anim.play(ramp_name, 0.1)
			return
	if flag.get("dash", false) or wall_jump_control_lock > 0.0:
		if anim.current_animation != "sonic_wall_jump_loop_A":
			anim.play("sonic_wall_jump_loop_A", 0.1)
		return
	if flag["fall"]:
		anim.speed_scale = 1.0
		if anim.current_animation != "sonic_jump_D_loop": anim.play("sonic_jump_D_loop", 0.2)
		return
	if jump_fall_phase and current_state == State.JUMP:
		anim.speed_scale = 1.0
		var fall_anim := "sonic_jump_D_loop" if anim.has_animation("sonic_jump_D_loop") else "sonic_jump_D"
		if anim.has_animation(fall_anim) and anim.current_animation != fall_anim:
			anim.play(fall_anim, 0.2)
		return
	if in_hurdle:
		if current_state != State.JUMP or custom_velocity.y <= 0.0:
			in_hurdle = false
		elif anim.has_animation("sonic_hurdleL"):
			anim.speed_scale = 1.0
			if anim.current_animation != "sonic_hurdleL":
				anim.play("sonic_hurdleL", 0.05)
			return
	if current_state == State.ROLL:
		anim.speed_scale = 1.0
		if anim.has_animation("sonic_sliding"):
			if anim.assigned_animation != "sonic_sliding":
				anim.play("sonic_sliding", 0.1)
				Audio.play("slide")
				Audio.play("slide_rep")
		elif anim.current_animation != "sonic_ball":
			anim.play("sonic_ball", 0.0)
		return
	if in_air or current_state == State.JUMP:
		anim.speed_scale = 1.0
		if anim.current_animation != "sonic_ball": anim.play("sonic_ball", 0.15 if qte_flying else 0.0)
		return
	if current_state == State.DRIFT and input_dir.x < -0.1:
		anim.speed_scale = 1.5
		if anim.has_animation("sonic_drift_L") and anim.current_animation != "sonic_drift_L":
			anim.play("sonic_drift_L", 0.2)
		return
	if current_state == State.DRIFT and input_dir.x > 0.1:
		anim.speed_scale = 1.5
		if anim.has_animation("sonic_drift_R") and anim.current_animation != "sonic_drift_R":
			anim.play("sonic_drift_R", 0.2)
		return
	if current_state == State.DRIFT:
		anim.speed_scale = 1.5
		if anim.has_animation("sonic_drift_L") and anim.current_animation != "sonic_drift_L":
			anim.play("sonic_drift_L", 0.2)
		return
	if current_state == State.QUICK_STEP:
		anim.speed_scale = 1.0
		var is_running = custom_velocity.length() > 0.5
		var anim_name = ""
		if is_running:
			anim_name = "sonic_run_quickstep_L" if quick_step_dir < 0.0 else "sonic_run_quickstep_R"
		else:
			anim_name = "sonic_quickstep_L" if quick_step_dir < 0.0 else "sonic_quickstep_R"
		if anim.has_animation(anim_name) and anim.current_animation != anim_name:
			anim.play(anim_name, 0.05)
		return
	var speed = custom_velocity.length()
	var blend = 0.0 if anim.current_animation == "sonic_ball" else 0.3
	var side := ""
	if input_dir.x > 0.3:
		side = "_R"
	elif input_dir.x < -0.3:
		side = "_L"
	if current_state == State.BOOST and speed >= 12.0 and anim.has_animation("sonic_jet"):
		anim.speed_scale = lerpf(jet_anim_speed_min, jet_anim_speed_max, clampf((speed - 12.0) / (boost_max_speed - 12.0), 0.0, 1.0))
		_play_run_variant("sonic_jet", side, blend)
		return
	if speed >= 0.5:
		idle_timer = 0.0
	if speed < 0.5:
		anim.speed_scale = 1.0
		if anim.current_animation in IDLE_VARIANTS and anim.is_playing():
			return
		idle_timer += get_physics_process_delta_time()
		if idle_timer >= idle_variant_delay:
			if idle_bag.is_empty():
				var variants: Array[String] = []
				for v in IDLE_VARIANTS:
					if anim.has_animation(v):
						variants.append(v)
				variants.shuffle()
				if variants.size() > 1 and variants[variants.size() - 1] == idle_last:
					var swap_i := randi() % (variants.size() - 1)
					var tmp := variants[swap_i]
					variants[swap_i] = variants[variants.size() - 1]
					variants[variants.size() - 1] = tmp
				idle_bag = variants
			if not idle_bag.is_empty():
				idle_timer = 0.0
				var picked: String = idle_bag.pop_back()
				idle_last = picked
				anim.get_animation(picked).loop_mode = Animation.LOOP_NONE
				anim.play(picked, 0.3)
				return
		if anim.current_animation != "sonic_idle": anim.play("sonic_idle", blend)
	elif speed < 12.0:
		var walk_multiplier = 1.0
		anim.speed_scale = 1.0 + (speed / 12.0) * walk_multiplier
		if anim.current_animation != "sonic_walk": anim.play("sonic_walk", blend)
	elif speed < jog_to_run_speed and anim.has_animation("sonic_jog"):
		anim.speed_scale = 1.0 + ((speed - 12.0) / maxf(jog_to_run_speed - 12.0, 0.1)) * 0.8
		_play_run_variant("sonic_jog", side.trim_prefix("_"), blend)
	elif speed < 28.0:
		var jog_multiplier = 1.7
		var run_start: float = jog_to_run_speed if anim.has_animation("sonic_jog") else 12.0
		anim.speed_scale = 1.0 + ((speed - run_start) / maxf(28.0 - run_start, 0.1)) * jog_multiplier
		_play_run_variant("sonic_run", side, blend)
	else:
		var jet_multiplier = 2.5
		anim.speed_scale = 1.0 + clamp((speed - 28.0) / (max_speed - 28.0), 0.0, 1.0) * jet_multiplier
		_play_run_variant("sonic_dash", side, blend)
func _play_run_variant(base: String, side: String, blend: float) -> void:
	var target := base + side
	if side != "" and not anim.has_animation(target):
		target = base
	if anim.current_animation == target:
		return
	var keep_phase: bool = anim.current_animation.begins_with(base) and anim.current_animation_length > 0.0
	var ratio: float = anim.current_animation_position / anim.current_animation_length if keep_phase else 0.0
	anim.play(target, blend)
	if keep_phase and anim.current_animation_length > 0.0:
		anim.seek(ratio * anim.current_animation_length, false)
func _ramp_anim_name() -> String:
	if anim == null:
		return ""
	if anim.has_animation(ramp_jump_anim):
		return ramp_jump_anim
	if anim.has_animation("global/" + ramp_jump_anim):
		return "global/" + ramp_jump_anim
	return ""
func start_ramp_anim() -> void:
	var n: String = _ramp_anim_name()
	if n == "":
		ramp_anim_active = false
		return
	ramp_anim_active = true
	anim.get_animation(n).loop_mode = Animation.LOOP_NONE
	anim.speed_scale = 1.0
	anim.play(n, 0.1)
func _update_auto_camera(delta: float) -> void:
	if not camera_auto_follow or is_intro or is_lsd_active:
		return
	if (_qte_cam_tween and _qte_cam_tween.is_valid()) or (_spring_cam_tween and _spring_cam_tween.is_valid()):
		return
	if cam_manual_timer > 0.0:
		cam_manual_timer -= delta
		cam_recentering = true
		return
	match current_state:
		State.HIT, State.GRINDING, State.LIGHT_SPEED_DASH, State.WALL_CLING, State.QUICK_STEP, State.STOMP:
			return
	var slope_angle: float = rad_to_deg(acos(clampf(local_up.dot(Vector3.UP), -1.0, 1.0)))
	if slope_angle > camera_slope_max_angle:
		return
	var flat: Vector3 = Vector3(custom_velocity.x, 0.0, custom_velocity.z)
	var speed: float = flat.length()
	var base_pitch: float = lerpf(camera_idle_pitch, camera_default_pitch, _camera_speed_t())
	var goal_pitch: float = base_pitch
	var pitch_rate: float = camera_pitch_return
	if grounded and slope_angle > camera_slope_min_angle:
		var look_dir: Vector3 = Vector3(-sin(target_yaw), 0.0, -cos(target_yaw))
		var along_slope: Vector3 = look_dir.slide(local_up)
		if along_slope.length() > 0.001:
			goal_pitch = clampf(base_pitch + asin(clampf(along_slope.normalized().y, -1.0, 1.0)), -0.8, 0.8)
			pitch_rate = camera_slope_follow_speed
	if current_state == State.DRIFT:
		var drift_diff: float = angle_difference(target_yaw, atan2(-drift_direction.x, -drift_direction.z))
		target_yaw += clampf(drift_diff * camera_drift_follow_speed, -camera_drift_max_turn, camera_drift_max_turn) * delta
		target_pitch = lerp(target_pitch, goal_pitch, pitch_rate * delta)
		return
	if cam_recentering:
		var yaw_diff: float = 0.0
		if speed >= camera_follow_min_speed:
			yaw_diff = angle_difference(target_yaw, atan2(-flat.x, -flat.z))
			target_yaw += clampf(yaw_diff * camera_recenter_speed, -camera_follow_max_turn * 2.0, camera_follow_max_turn * 2.0) * delta
		target_pitch = lerp(target_pitch, goal_pitch, camera_recenter_speed * delta)
		if absf(yaw_diff) < 0.02 and absf(target_pitch - goal_pitch) < 0.02:
			cam_recentering = false
		return
	target_pitch = lerp(target_pitch, goal_pitch, pitch_rate * delta)
	if speed >= camera_follow_min_speed:
		var goal_yaw: float = atan2(-flat.x, -flat.z)
		var diff: float = angle_difference(target_yaw, goal_yaw)
		var fast_t: float = clampf((speed - 20.0) / (max_speed - 20.0), 0.0, 1.0)
		var dz: float = deg_to_rad(lerpf(camera_follow_deadzone, camera_fast_deadzone, fast_t))
		diff = signf(diff) * maxf(absf(diff) - dz, 0.0)
		var weight: float = 1.0 - smoothstep(deg_to_rad(90.0), deg_to_rad(140.0), absf(diff))
		var speed_factor: float = clampf(speed / max_speed, 0.4, 1.5)
		var fast_mult: float = lerpf(1.0, camera_fast_follow_mult, fast_t)
		var max_turn: float = camera_follow_max_turn * fast_mult
		var omega: float = clampf(diff * camera_follow_speed * speed_factor * fast_mult * weight, -max_turn, max_turn)
		target_yaw += omega * delta
func _camera_speed_t() -> float:
	if current_state == State.LIGHT_SPEED_DASH:
		return 1.0
	return smoothstep(camera_close_speed_min, camera_close_speed_max, custom_velocity.slide(local_up).length())
func _update_camera_framing(delta: float, snap: bool = false) -> void:
	if not camera or current_state == State.GRINDING or is_rail_quick_stepping:
		return
	var t: float = _camera_speed_t()
	var h: float = camera_height * lerpf(camera_idle_height_mult, 1.0, t)
	var d: float = camera_distance * lerpf(camera_idle_distance_mult, 1.0, t) + boost_cam_offset
	var rot_x: float = cam_base_rot_x + atan2(camera_height, camera_distance) - atan2(h, d)
	var w: float = 1.0 if snap else 1.0 - exp(-camera_framing_speed * delta)
	camera.position = camera.position.lerp(Vector3(camera.position.x, h, d), w)
	camera.rotation.x = lerpf(camera.rotation.x, rot_x, w)
func _align_camera_to_direction(dir: Vector3) -> void:
	var flat: Vector3 = Vector3(dir.x, 0.0, dir.z)
	if flat.length() < 0.01:
		return
	target_yaw = atan2(-flat.x, -flat.z)
	cam_yaw = target_yaw
	cam_manual_timer = 0.0
	cam_recentering = false
func _smooth_cam_pos() -> Vector3:
	return global_position + _cam_snap_offset
func _update_camera_follow(delta: float) -> void:
	if not pivot or not camera:
		return
	if _cam_snap_offset != Vector3.ZERO:
		_cam_snap_offset = _cam_snap_offset.lerp(Vector3.ZERO, 1.0 - exp(-camera_snap_smooth * delta))
		if _cam_snap_offset.length_squared() < 0.00001:
			_cam_snap_offset = Vector3.ZERO
	pivot.global_position = _smooth_cam_pos()
func update_camera():
	if not pivot or not camera: return
	pivot.global_position = _smooth_cam_pos()
	pivot.rotation = Vector3(cam_pitch, cam_yaw, 0)
	_update_ui_reticle()
func _update_ui_reticle():
	var reticle = get_tree().get_first_node_in_group("Hom")
	if not reticle or not camera: return
	if _qte_blocked():
		reticle.visible = false
		return
	var current_target = homing_target_node
	if not current_target:
		current_target = _find_homing_target()
	if current_target and is_instance_valid(current_target):
		if camera.is_position_behind(_homing_point(current_target)):
			reticle.visible = false
		else:
			reticle.visible = true
			reticle.global_position = camera.unproject_position(_homing_point(current_target))
	else:
		reticle.visible = false
func _camera_input_locked() -> bool:
	return not camera_manual_enabled or current_state == State.SKYDIVE or (qte_lock_camera and _qte_blocked())
func face_direction_with_camera(dir: Vector3, cam_time: float = 0.7) -> void:
	var flat: Vector3 = dir.slide(Vector3.UP)
	if flat.length() < 0.01:
		return
	flat = flat.normalized()
	_face_direction(flat)
	var goal: float = atan2(-flat.x, -flat.z)
	var end_yaw: float = target_yaw + angle_difference(target_yaw, goal)
	cam_manual_timer = 0.0
	cam_recentering = false
	if _spring_cam_tween and _spring_cam_tween.is_valid():
		_spring_cam_tween.kill()
	_spring_cam_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_spring_cam_tween.tween_property(self, "target_yaw", end_yaw, maxf(cam_time, 0.01))
func _face_direction(dir: Vector3) -> void:
	var flat := dir.slide(local_up)
	if flat.length() < 0.01:
		return
	var local_forward := transform.basis.inverse() * flat.normalized()
	model.rotation.y = atan2(local_forward.x, local_forward.z)
func add_ring() -> void:
	if RingCount and RingCount.has_method("add_rings"):
		RingCount.add_rings(1)
		boost_energy = minf(boost_energy + 5.0, max_boost_energy)
func perform_light_speed_dash() -> void:
	if is_lsd_active:
		Audio.play("lsd")
		Audio.play("ring")
		return
	var closest_ring: Node3D = null
	var min_dist = lsd_scan_radius
	for ring in get_tree().get_nodes_in_group("LsdRings"):
		if is_instance_valid(ring) and ring.visible:
			var dist = global_position.distance_to(ring.global_position)
			if dist < min_dist:
				min_dist = dist
				closest_ring = ring
	if closest_ring:
		is_lsd_active = true
		current_state = State.LIGHT_SPEED_DASH
		custom_velocity = Vector3.ZERO
		velocity = Vector3.ZERO
		lsd_last_dir = Vector3.ZERO
		is_boosting = false
		_boost_hide()
		Audio.stop("boost")
		_lsd_run(_lsd_build_chain(closest_ring))
func _lsd_build_chain(first: Node3D) -> Array:
	var chain: Array = [first]
	var pool: Array = get_tree().get_nodes_in_group("LsdRings").filter(func(r): return is_instance_valid(r) and r.visible and r != first)
	var cur: Node3D = first
	while true:
		var best: Node3D = null
		var best_d: float = lsd_scan_radius
		for r in pool:
			if r in chain:
				continue
			var d: float = cur.global_position.distance_to(r.global_position)
			if d < best_d:
				best_d = d
				best = r
		if best == null:
			break
		chain.append(best)
		cur = best
	return chain
func _lsd_run(chain: Array) -> void:
	if lsd_tween and lsd_tween.is_valid():
		lsd_tween.kill()
	lsd_tween = create_tween()
	lsd_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	lsd_tween.set_trans(Tween.TRANS_LINEAR)
	var from: Vector3 = global_position
	for ring in chain:
		var to: Vector3 = ring.global_position
		var dist: float = from.distance_to(to)
		lsd_tween.tween_callback(_lsd_leg_begin.bind(ring, to - from))
		if dist > 0.01:
			lsd_tween.tween_property(self, "global_position", to, dist / lsd_speed)
		lsd_tween.tween_callback(_lsd_collect.bind(ring))
		from = to
	lsd_tween.tween_callback(_end_lsd)
func _lsd_leg_begin(ring, d: Vector3) -> void:
	if not is_lsd_active:
		return
	if is_instance_valid(ring):
		lsd_target_ring = ring
	Audio.play("ring")
	if d.length() > 0.01:
		lsd_last_dir = d.normalized()
		_face_direction(lsd_last_dir)
func _lsd_collect(ring) -> void:
	if not is_lsd_active or not is_instance_valid(ring) or ring.is_queued_for_deletion():
		return
	if ring.has_method("_on_sonic_collected"):
		ring._on_sonic_collected()
	else:
		add_ring()
		ring.queue_free()
func _lsd_physics(_delta: float) -> void:
	custom_velocity = Vector3.ZERO
	velocity = Vector3.ZERO
	grounded = false
	cam_yaw = lerp_angle(cam_yaw, target_yaw, camera_inertia * _delta)
	cam_pitch = lerp(cam_pitch, target_pitch, camera_inertia * _delta)
	update_animations(false, Vector2.ZERO)
	update_camera()
func _end_lsd() -> void:
	if lsd_tween and lsd_tween.is_valid():
		lsd_tween.kill()
	lsd_tween = null
	is_lsd_active = false
	var dir: Vector3 = lsd_last_dir.slide(local_up)
	if dir.length() < 0.01:
		dir = model.global_transform.basis.z.slide(local_up)
	if dir.length() < 0.01:
		dir = -transform.basis.z.slide(local_up)
	dir = dir.normalized()
	var q := PhysicsRayQueryParameters3D.create(global_position, global_position - local_up * snap_length)
	q.exclude = _ray_excludes()
	var on_ground: bool = not get_world_3d().direct_space_state.intersect_ray(q).is_empty()
	current_state = State.GROUND if on_ground else State.JUMP
	custom_velocity = dir * (max_speed if on_ground else max_speed * 0.8)
	velocity = custom_velocity
	_face_direction(dir)
func touch_player(body: Area3D):
	if qte_fail_locked or current_state == State.QTE_ACTIVE:
		return
	if body is JumpSelector:
		_start_select_jump(body)
		return
	if current_state == State.SELECT_JUMP:
		return
	if body.is_in_group("Spring"):
		perform_spring()
	if body.is_in_group("Hit"):
		if invincible_timer > 0.0 or current_state == State.HIT:
			return
		_on_hit()
		Audio.play("spread")
func _start_dashring_anim() -> void:
	var n: String = ""
	if anim.has_animation("sonic_dashringL"):
		n = "sonic_dashringL"
	elif anim.has_animation("global/sonic_dashringL"):
		n = "global/sonic_dashringL"
	if n == "":
		dashring_anim_active = false
		return
	_dashring_anim_name = n
	dashring_anim_active = true
	anim.get_animation(n).loop_mode = Animation.LOOP_NONE
	anim.speed_scale = 1.0
	anim.play(n, 0.1)
func perform_spring() -> void:
	if qte_fail_locked or current_state == State.QTE_ACTIVE:
		return
	qte_flying = false
	ramp_anim_active = false
	is_homing_tracking = false
	homing_target_node = null
	homing_timer = 0.0
	can_homing_dash = true
	is_doing_trick = false
	flag.trick = false
	in_hurdle = false
	is_jumping = true
	after_homing = false
	if current_state != State.JUMP:
		_change_state(State.JUMP)
func _perform_hit():
	_on_hit()
func _on_hit():
	if qte_fail_locked or qte_flying or current_state == State.QTE_ACTIVE:
		return
	if current_state == State.HIT or invincible_timer > 0.0:
		return
	Audio.play("spread")
	if RingCount.rings == 0:
		Die()
		return
	var was_boosting: bool = current_state == State.BOOST
	_cancel_quick_step()
	_stop_air_boost()
	_change_state(State.HIT)
	hit_is_stumble = was_boosting
	hit_standing_up = false
	can_move = false
	is_boosting = false
	_boost_hide()
	Audio.stop("boost")
	is_doing_trick = false
	is_homing_tracking = false
	homing_target_node = null
	in_hurdle = false
	wall_jump_control_lock = 0.0
	flag.trick = false
	flag.spring = false
	flag.dash = false
	if not was_boosting:
		custom_velocity = custom_velocity.project(local_up)
		velocity = custom_velocity
	RingCount.lose_rings()
	if was_boosting:
		var stumble_anim := "sonic_stumble_runC"
		if anim.has_animation(stumble_anim):
			anim.speed_scale = stumble_anim_speed
			anim.play(stumble_anim, 0.1)
		await get_tree().create_timer(stumble_time).timeout
		if not is_inside_tree():
			return
	else:
		var dmg_anim := "Sonic_damage_B"
		var up_anim := "sonic_standup_B"
		var dmg_len: float = anim.get_animation(dmg_anim).length if anim.has_animation(dmg_anim) else 0.0
		var up_len: float = anim.get_animation(up_anim).length if anim.has_animation(up_anim) else 0.0
		var up_time: float = minf(hit_standup_time, hit_total_time * 0.8) if up_len > 0.0 else 0.0
		var dmg_time: float = maxf(hit_total_time - up_time, 0.01)
		_hit_speed = dmg_len / dmg_time if dmg_len > 0.0 else 1.0
		_standup_speed = up_len / up_time if up_len > 0.0 else 1.0
		if dmg_len > 0.0:
			anim.speed_scale = _hit_speed
			anim.play(dmg_anim, 0.1)
		await get_tree().create_timer(dmg_time).timeout
		if not is_inside_tree():
			return
		if current_state == State.HIT and up_len > 0.0:
			hit_standing_up = true
			anim.speed_scale = _standup_speed
			anim.play(up_anim, 0.1)
			await get_tree().create_timer(up_time).timeout
			if not is_inside_tree():
				return
	hit_standing_up = false
	hit_is_stumble = false
	anim.speed_scale = 1.0
	can_move = true
	if current_state == State.HIT:
		_change_state(State.GROUND)
	invincible_timer = hit_invincibility
func Die():
	if is_dead:
		return
	is_dead = true
	GameManager.register_death()
	await get_tree().create_timer(1.0).timeout
	get_tree().reload_current_scene()
func _start_select_jump(sel: JumpSelector) -> void:
	if sel == null or not sel.is_available():
		return
	if qte_fail_locked or is_dead:
		return
	if current_state == State.SELECT_JUMP:
		if select_phase != SelPhase.FLY or sel == select_node:
			return
		if select_node and is_instance_valid(select_node):
			select_node.release()
	elif current_state in [State.QTE_ACTIVE, State.GRINDING, State.HIT, State.LIGHT_SPEED_DASH]:
		return
	sel.claim()
	select_node = sel
	select_rise = false
	_cancel_quick_step()
	_stop_air_boost()
	is_boosting = false
	_boost_hide()
	Audio.stop("boost")
	is_homing_tracking = false
	homing_target_node = null
	is_doing_trick = false
	in_hurdle = false
	qte_flying = false
	ramp_anim_active = false
	wall_jump_control_lock = 0.0
	flag.trick = false
	flag.spring = false
	flag.dash = false
	flag.fall = false
	can_move = false
	is_jumping = false
	grounded = false
	custom_velocity = Vector3.ZERO
	velocity = Vector3.ZERO
	select_phase = SelPhase.WAIT
	select_timer = sel.select_time
	_change_state(State.SELECT_JUMP)
	if anim and anim.has_animation(select_ball_anim):
		anim.speed_scale = 1.0
		anim.play(select_ball_anim, 0.1)
func _select_jump_physics(delta: float) -> void:
	if select_node == null or not is_instance_valid(select_node):
		_end_select_jump(false)
		return
	grounded = false
	match select_phase:
		SelPhase.WAIT:
			_select_wait(delta)
		SelPhase.AIM:
			_select_hold(delta)
			if select_timer <= 0.0:
				_select_launch()
		SelPhase.FLY:
			_select_fly(delta)
		SelPhase.MISS_WAIT:
			_select_hold(delta)
			if select_timer <= 0.0:
				_select_miss_throw()
		SelPhase.MISS:
			_select_miss(delta)
	cam_yaw = lerp_angle(cam_yaw, target_yaw, camera_inertia * delta)
	cam_pitch = lerp(cam_pitch, target_pitch, camera_inertia * delta)
	_update_auto_camera(delta)
	update_camera()
func _select_hold(delta: float) -> void:
	custom_velocity = Vector3.ZERO
	velocity = Vector3.ZERO
	global_position = global_position.lerp(select_node.hold_position(), clampf(select_snap_speed * delta, 0.0, 1.0))
	select_timer -= delta
func _select_wait(delta: float) -> void:
	Audio.play_loop("select_jump")
	_select_hold(delta)
	if Input.is_action_just_pressed("jump"):
		_select_aim(select_node.launch_dir)
	elif select_timer <= 0.0:
		_select_miss_begin()
func _select_aim(dir: int) -> void:
	var sel := select_node
	select_dir = sel.direction_vector(dir)
	select_speed = sel.speed_for(dir)
	select_phase = SelPhase.AIM
	select_timer = sel.rotate_to(dir)
	if dir != JumpSelector.Dir.UP:
		_face_direction(select_dir)
func _select_launch() -> void:
	var sel := select_node
	select_timer = sel.fly_time
	select_phase = SelPhase.FLY
	var a: String = select_up_anim if sel.launch_dir == JumpSelector.Dir.UP else select_side_anim
	if anim and anim.has_animation(a):
		anim.speed_scale = 1.0
		anim.play(a, 0.05)
	Audio.play("select")
	sel.launched.emit(sel.launch_dir)
func _select_fly(delta: float) -> void:
	select_timer -= delta
	custom_velocity = select_dir * select_speed
	velocity = custom_velocity
	var col: KinematicCollision3D = move_and_collide(custom_velocity * delta)
	if col:
		if col.get_normal().dot(select_dir) < -0.3:
			_end_select_jump(true)
			return
		move_and_collide(col.get_remainder().slide(col.get_normal()))
	if select_timer <= 0.0:
		_end_select_jump(true)
func _select_miss_begin() -> void:
	select_phase = SelPhase.MISS_WAIT
	select_timer = select_node.play_main()
func _select_miss_throw() -> void:
	var sel := select_node
	select_phase = SelPhase.MISS
	select_timer = sel.miss_lock_time
	custom_velocity = Vector3.DOWN * sel.miss_throw_speed
	velocity = custom_velocity
	sel.missed.emit()
	if anim and anim.has_animation(select_miss_anim):
		anim.speed_scale = 1.0
		anim.play(select_miss_anim, 0.05)
func _select_miss(delta: float) -> void:
	custom_velocity += Vector3.DOWN * gravity_force * delta
	Audio.play("jumpF")
	velocity = custom_velocity
	up_direction = local_up
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	move_and_slide()
	custom_velocity = velocity
	select_timer -= delta
	var min_t: float = select_node.miss_lock_time - 0.15
	if select_timer <= 0.0 or (is_on_floor() and select_timer < min_t):
		_end_select_jump(false)
func _end_select_jump(from_flight: bool) -> void:
	Audio.stop_loop("select_jump")
	var sel := select_node
	select_node = null
	select_phase = SelPhase.WAIT
	if from_flight:
		var is_up: bool = select_dir.dot(Vector3.UP) > 0.9
		var keep: float = 0.35
		if sel and is_instance_valid(sel):
			keep = sel.up_exit_keep if is_up else sel.exit_keep
		custom_velocity = select_dir * select_speed * keep
		select_rise = is_up
	velocity = custom_velocity
	_change_state(State.JUMP)
	is_jumping = true
	can_homing_dash = true
	can_double_jump = false
	if anim:
		anim.speed_scale = 1.0
	if current_state != State.HIT:
		can_move = true
	if sel and is_instance_valid(sel):
		sel.release()
func _qte_blocked() -> bool:
	return qte_fail_locked or qte_input_lock or current_state == State.QTE_ACTIVE
func _start_qte(area: Node) -> void:
	print("[QTE-DBG] player: _start_qte state=", current_state, " fail_locked=", qte_fail_locked, " dead=", is_dead)
	if current_state == State.QTE_ACTIVE or qte_fail_locked or is_dead:
		print("[QTE-DBG] player: blocked (already active/failed/dead)")
		return
	if current_state == State.GRINDING or current_state == State.HIT:
		print("[QTE-DBG] player: blocked (grinding/hit)")
		return
	if area.has_meta("qte_used"):
		print("[QTE-DBG] player: blocked (qte_used)")
		return
	var manager := get_tree().get_first_node_in_group("QuickTimeManager") as QuickTimeManager
	if manager == null:
		push_error("[QTE-DBG] QuickTimeManager не найден в группе QuickTimeManager (нет узла в сцене?)")
		return
	area.set_meta("qte_used", true)
	qte_saved_velocity = custom_velocity
	_cancel_quick_step()
	_stop_air_boost()
	is_boosting = false
	_boost_hide()
	Audio.stop("boost")
	is_homing_tracking = false
	homing_target_node = null
	is_doing_trick = false
	in_hurdle = false
	wall_jump_control_lock = 0.0
	flag.trick = false
	flag.spring = false
	flag.dash = false
	flag.fall = false
	can_move = false
	_change_state(State.QTE_ACTIVE)
	qte_input_lock = true
	_qte_slowmo_begin()
	if anim and anim.has_animation(qte_hold_anim):
		anim.speed_scale = 1.0
		anim.play(qte_hold_anim, 0.1)
	manager.finished.connect(_on_qte_finished, CONNECT_ONE_SHOT)
	var qte_time: float = float(area.get_meta("qte_time")) if area.has_meta("qte_time") else -1.0
	manager.start(qte_time)
	print("[QTE-DBG] player: manager.start called, running=", manager.is_running())
	if not manager.is_running():
		push_error("[QTE-DBG] менеджер не запустился: нет TextureRect-кнопок в группах KeyboardButton/MobileButton с именами Jump/Spin/Boost/Left/Right")
		manager.finished.disconnect(_on_qte_finished)
		_qte_slowmo_end()
		qte_input_lock = false
		_qte_resume()
func _qte_resume() -> void:
	_change_state(State.JUMP)
	is_jumping = true
	custom_velocity = qte_saved_velocity
	velocity = custom_velocity
	if current_state != State.HIT:
		can_move = true
func _on_qte_finished(success: bool, _score: int) -> void:
	if current_state != State.QTE_ACTIVE or qte_fail_locked:
		return
	_qte_slowmo_end()
	if success:
		_qte_success()
		_qte_cam_return()
	else:
		_qte_cam_return()
		_qte_fail()
func _qte_success() -> void:
	var trick_name: String = ""
	if not qte_trick_anims.is_empty():
		trick_name = qte_trick_anims.pick_random()
	_change_state(State.JUMP)
	is_jumping = true
	can_homing_dash = true
	Audio.play("OK_qte")
	custom_velocity.y = maxf(custom_velocity.y, 0.0) + qte_success_boost
	velocity = custom_velocity
	flag.spring = true
	is_doing_trick = true
	if qte_land_on_platform:
		_qte_try_start_flight()
	var trick_len: float = 0.5
	if anim and anim.has_animation(trick_name):
		anim.speed_scale = 1.0
		anim.play(trick_name, 0.1)
		trick_len = anim.get_animation(trick_name).length
	await get_tree().create_timer(minf(trick_len, qte_trick_max_time)).timeout
	if not is_inside_tree() or qte_fail_locked or is_dead:
		return
	is_doing_trick = false
	flag.spring = false
	qte_input_lock = false
	if current_state != State.HIT and not qte_flying:
		can_move = true
func _qte_fail() -> void:
	qte_fail_locked = true
	can_move = false
	is_doing_trick = false
	is_homing_tracking = false
	homing_target_node = null
	flag.trick = false
	flag.spring = false
	flag.dash = false
	custom_velocity = Vector3.ZERO
	velocity = Vector3.ZERO
	qte_fail_timer = qte_fail_die_delay
	if spin:
		spin.visible = false
	if anim:
		var fail_anim: String = qte_fail_anim
		if not anim.has_animation(fail_anim):
			fail_anim = "sonic_jump_D_loop"
		if anim.has_animation(fail_anim):
			anim.speed_scale = 1.0
			anim.play(fail_anim, 0.1)
func _qte_physics(delta: float) -> void:
	if qte_fail_locked:
		var fall_y: float = minf(custom_velocity.y, 0.0) - gravity_force * delta
		custom_velocity = Vector3(0.0, fall_y, 0.0)
		velocity = custom_velocity
		motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
		move_and_slide()
		custom_velocity = velocity
		if qte_fail_kills and not is_dead:
			qte_fail_timer -= delta
			if qte_fail_timer <= 0.0:
				Die()
	elif qte_hover:
		custom_velocity = Vector3.ZERO
		velocity = Vector3.ZERO
	else:
		custom_velocity += Vector3.DOWN * gravity_force * qte_gravity_scale * delta
		velocity = custom_velocity
		motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
		move_and_slide()
		custom_velocity = velocity
	update_camera()
func _qte_slowmo_begin() -> void:
	if _qte_time_tween and _qte_time_tween.is_valid():
		_qte_time_tween.kill()
	Engine.time_scale = qte_slowmo_scale
func _qte_slowmo_end() -> void:
	if _qte_time_tween and _qte_time_tween.is_valid():
		_qte_time_tween.kill()
	if Engine.time_scale >= 0.999:
		return
	_qte_time_tween = create_tween().set_ignore_time_scale(true)
	_qte_time_tween.tween_method(func(v: float): Engine.time_scale = v, Engine.time_scale, 1.0, qte_slowmo_exit_time)
func _qte_cam_return() -> void:
	if not qte_cam_orbit:
		return
	var heading: Vector3 = Vector3(qte_saved_velocity.x, 0.0, qte_saved_velocity.z)
	if heading.length() < 0.1 and model:
		heading = Vector3(model.global_transform.basis.z.x, 0.0, model.global_transform.basis.z.z)
	if heading.length() < 0.01:
		return
	var goal: float = atan2(-heading.x, -heading.z)
	var start: float = cam_yaw
	var diff: float = wrapf(goal - start, -PI, PI)
	cam_manual_timer = 0.0
	cam_recentering = false
	if _qte_cam_tween and _qte_cam_tween.is_valid():
		_qte_cam_tween.kill()
	_qte_cam_tween = create_tween().set_ignore_time_scale(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_qte_cam_tween.tween_method(func(t: float):
		cam_yaw = start + diff * t
		target_yaw = cam_yaw
		update_camera(), 0.0, 1.0, qte_cam_return_time)
func _qte_collect_bodies(node: Node, out: Array) -> void:
	if node == self:
		return
	if node is StaticBody3D:
		out.append(node)
	for c in node.get_children():
		_qte_collect_bodies(c, out)
func _qte_body_is_excluded(b: Node) -> bool:
	var n: Node = b
	while n != null:
		if n == self or n is DashRamp or n is Spring or n.is_in_group("Player") or n.is_in_group("QTE") or n.is_in_group("Spring"):
			return true
		n = n.get_parent()
	return false
func _qte_body_aabb(b: StaticBody3D) -> AABB:
	var out: AABB = AABB()
	var has: bool = false
	for c in b.find_children("*", "CollisionShape3D", true, false):
		var cs := c as CollisionShape3D
		if cs.disabled or cs.shape == null or cs.shape is WorldBoundaryShape3D:
			continue
		var mesh: Mesh = cs.shape.get_debug_mesh()
		if mesh == null:
			continue
		var wb: AABB = cs.global_transform * mesh.get_aabb()
		out = wb if not has else out.merge(wb)
		has = true
	return out if has else AABB()
func _qte_inset_clamp(v: float, lo: float, hi: float, m: float) -> float:
	if hi - lo <= m * 2.0:
		return (lo + hi) * 0.5
	return clampf(v, lo + m, hi - m)
func _qte_top_point(b: StaticBody3D, box: AABB, from: Vector3) -> Vector3:
	var space := get_world_3d().direct_space_state
	var xz_list: Array[Vector2] = [
		Vector2(_qte_inset_clamp(from.x, box.position.x, box.end.x, qte_land_edge_margin),
				_qte_inset_clamp(from.z, box.position.z, box.end.z, qte_land_edge_margin)),
		Vector2(box.get_center().x, box.get_center().z)]
	for xz in xz_list:
		var q := PhysicsRayQueryParameters3D.create(
			Vector3(xz.x, box.end.y + 1.0, xz.y), Vector3(xz.x, box.position.y - 1.0, xz.y))
		q.exclude = [get_rid()]
		var r: Dictionary = space.intersect_ray(q)
		if not r.is_empty() and r.collider == b and (r.normal as Vector3).dot(Vector3.UP) >= 0.7:
			return r.position
	return Vector3.INF
func _qte_find_landing() -> Vector3:
	var root: Node = get_tree().current_scene
	if root == null:
		return Vector3.INF
	var fwd: Vector3 = Vector3(qte_saved_velocity.x, 0.0, qte_saved_velocity.z)
	if fwd.length() < 0.1 and model:
		fwd = Vector3(model.global_transform.basis.z.x, 0.0, model.global_transform.basis.z.z)
	fwd = fwd.normalized()
	var pos: Vector3 = global_position
	var bodies: Array = []
	if qte_land_group != &"":
		for n in get_tree().get_nodes_in_group(qte_land_group):
			if n is StaticBody3D:
				bodies.append(n)
	else:
		_qte_collect_bodies(root, bodies)
	var cands: Array = []
	for b in bodies:
		if b.collision_layer == 0 or _qte_body_is_excluded(b):
			continue
		var box: AABB = _qte_body_aabb(b)
		if box.size == Vector3.ZERO:
			continue
		var dx: float = maxf(maxf(box.position.x - pos.x, pos.x - box.end.x), 0.0)
		var dz: float = maxf(maxf(box.position.z - pos.z, pos.z - box.end.z), 0.0)
		var d: float = Vector2(dx, dz).length()
		if d < qte_land_min_distance or d > qte_land_max_distance:
			continue
		if box.end.y > pos.y + qte_land_max_rise:
			continue
		var near := Vector3(clampf(pos.x, box.position.x, box.end.x), 0.0, clampf(pos.z, box.position.z, box.end.z))
		var to_near := Vector3(near.x - pos.x, 0.0, near.z - pos.z)
		if to_near.length() > 0.01 and fwd.length() > 0.01 and fwd.dot(to_near.normalized()) < qte_land_forward_dot:
			continue
		cands.append({"body": b, "box": box, "d": d})
	cands.sort_custom(func(a, c): return a.d < c.d)
	for c in cands:
		var p: Vector3 = _qte_top_point(c.body, c.box, pos)
		if p != Vector3.INF:
			return p
	return Vector3.INF
func _qte_try_start_flight() -> void:
	var point: Vector3 = _qte_find_landing()
	if point == Vector3.INF:
		return
	var g: float = gravity_force * qte_fly_gravity_scale
	var p0: Vector3 = global_position
	var tgt: Vector3 = point + Vector3.UP * (target_floor_dist + 0.05)
	var to: Vector3 = tgt - p0
	var d: float = Vector2(to.x, to.z).length()
	var t: float = clampf(d / maxf(qte_fly_speed, 1.0), qte_fly_min_time, qte_fly_max_time)
	var t_cap: float = qte_fly_max_time * 3.0
	var vy: float = 0.0
	for i in 40:
		vy = to.y / t + 0.5 * g * t
		var apex: float = maxf(vy, 0.0) * maxf(vy, 0.0) / (2.0 * g)
		var descending: bool = vy - g * t < 0.0
		if descending and apex - maxf(to.y, 0.0) >= qte_land_apex_clearance:
			break
		if t >= t_cap:
			break
		t *= 1.1
	_qf_p0 = p0
	_qf_v0 = Vector3(to.x / t, vy, to.z / t)
	_qf_g = g
	_qf_t = 0.0
	_qf_dur = t
	_qf_target = tgt
	qte_flying = true
	can_move = false
	grounded = false
	qte_saved_velocity = Vector3(_qf_v0.x, 0.0, _qf_v0.z)
	_face_direction(Vector3(_qf_v0.x, 0.0, _qf_v0.z))
func _qte_fly_physics(delta: float) -> void:
	_qf_t = minf(_qf_t + delta, _qf_dur)
	var tt: float = _qf_t
	var want: Vector3 = _qf_p0 + _qf_v0 * tt + Vector3(0.0, -0.5 * _qf_g * tt * tt, 0.0)
	if tt >= _qf_dur:
		want = _qf_target
	var cur_v: Vector3 = _qf_v0 + Vector3(0.0, -_qf_g * tt, 0.0)
	custom_velocity = cur_v
	velocity = cur_v
	grounded = false
	var col: KinematicCollision3D = move_and_collide(want - global_position)
	if col:
		var top_hit: bool = col.get_normal().dot(Vector3.UP) > 0.7
		_qte_end_flight(top_hit)
	elif tt >= _qf_dur:
		_qte_end_flight(true)
	else:
		if not is_doing_trick:
			update_animations(true, Vector2.ZERO)
		_update_auto_camera(delta)
	cam_yaw = lerp_angle(cam_yaw, target_yaw, camera_inertia * delta)
	cam_pitch = lerp(cam_pitch, target_pitch, camera_inertia * delta)
	update_camera()
func _qte_end_flight(landed_on_top: bool) -> void:
	qte_flying = false
	flag.spring = false
	flag.dash = false
	custom_velocity = Vector3(0.0, -2.0 if landed_on_top else minf(custom_velocity.y, 0.0), 0.0)
	velocity = custom_velocity
	if current_state != State.JUMP:
		_change_state(State.JUMP)
	is_jumping = true
	if current_state != State.HIT and not is_doing_trick:
		can_move = true
func start_grinding(target_path: Path3D, start_offset: float, rail_ref: Area3D = null) -> void:
	if current_state == State.GRINDING or current_state == State.HIT or current_state == State.STOMP:
		return
	var entry_dir: Vector3 = custom_velocity - custom_velocity.project(Vector3.UP)
	if entry_dir.length() < 2.0:
		entry_dir = model.global_transform.basis.z
	entry_dir = entry_dir.normalized()
	_change_state(State.GRINDING)
	grind_jump_timer = -1.0
	grind_center_x = 0.0
	grounded = false
	is_jumping = false
	flag.fall = false
	Audio.play("start_rail")
	set_physics_process(true)
	sparkle.emitting = true
	spin.visible = false
	if has_node("Area3D"): $Area3D.monitoring = true
	if not is_rail_quick_stepping and anim.has_animation("global/sn_grind_long_l_loop_anm"):
		anim.play("global/sn_grind_long_l_loop_anm")
	model.reparent(path_follow)
	model.position = Vector3(-0.3, 0.4, 0)
	model.rotation = Vector3(deg_to_rad(90), 0, 0)
	path_follow.reparent(target_path)
	path_follow.progress = start_offset
	if not is_rail_quick_stepping:
		var rail_forward = -path_follow.global_transform.basis.z.normalized()
		var sonic_forward = entry_dir
		if sonic_forward.dot(rail_forward) < 0:
			grind_direction = -1.0
		else:
			grind_direction = 1.0
	grind_speed = max(custom_velocity.length(), base_grind_speed)
func handle_grind_movement(delta: float) -> void:
	var forward_vector = -path_follow.global_transform.basis.z * grind_direction
	var gravity_influence = forward_vector.dot(Vector3.DOWN)
	Audio.play_loop("rail")
	var target_max_grind = boost_max_speed if _held(&"boost") else max_speed
	var boosting_now: bool = _held(&"boost") and boost_energy > 0.0
	if boosting_now:
		grind_speed = move_toward(grind_speed, target_max_grind, boost_acceleration * delta)
		boost_energy -= 20.0 * delta
		_boost_show()
		if camera and (camera_tween == null or not camera_tween.is_running()) and camera.fov != boost_fov:
			if camera_tween: camera_tween.kill()
			camera_tween = create_tween()
			camera_tween.tween_property(camera, "fov", boost_fov, camera_transition_speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		grind_speed += gravity_influence * grind_acceleration * delta
		if _boost_want:
			Audio.stop("boost")
		_boost_hide()
		if camera and (camera_tween == null or not camera_tween.is_running()) and camera.fov != normal_fov:
			if camera_tween: camera_tween.kill()
			camera_tween = create_tween()
			camera_tween.tween_property(camera, "fov", normal_fov, camera_transition_speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	grind_speed = clamp(grind_speed, 15.0, target_max_grind)
	path_follow.progress += grind_speed * grind_direction * delta
	if not is_rail_quick_stepping:
		global_position = path_follow.global_position
	if pivot:
		pivot.global_position = _smooth_cam_pos()
	model.position = Vector3(grind_center_x, 0.2, 0)
	if grind_direction < 0:
		model.rotation = Vector3(deg_to_rad(0), 0, 0)
	else:
		model.rotation = Vector3(deg_to_rad(0), PI, 0)
	if grind_auto_center and not is_rail_quick_stepping:
		_center_model_on_rail()
	if not is_rail_quick_stepping:
		_update_grind_animation(boosting_now)
	path_follow.rotation.z = lerp_angle(path_follow.rotation.z, 0.0, 10.0 * delta)
	global_transform = path_follow.global_transform
	if grind_direction > 0:
		global_rotate(Vector3.UP, PI)
	if camera and not is_rail_quick_stepping:
		var back_direction = path_follow.global_transform.basis.z * grind_direction
		var target_cam_pos = global_position + (back_direction * 5.0) + (Vector3.UP * 1.2)
		camera.global_position = camera.global_position.lerp(target_cam_pos, 8.0 * delta)
		var target_transform = camera.global_transform.looking_at(global_position + Vector3.UP * 0.3, Vector3.UP)
		camera.global_transform.basis = camera.global_transform.basis.slerp(target_transform.basis, 4.0 * delta)
	if Input.is_action_just_pressed("quick_step_left"):
		try_rail_quick_step(-1.0)
	elif Input.is_action_just_pressed("quick_step_right"):
		try_rail_quick_step(1.0)
	if Input.is_action_just_pressed("jump") and grind_jump_timer < 0.0:
		grind_jump_timer = 0.0
	if grind_jump_timer >= 0.0:
		grind_jump_timer += delta
		var jump_released: bool = not Input.is_action_pressed("jump")
		if jump_released or grind_jump_timer >= grind_jump_hold_time:
			_grind_jump(forward_vector, grind_jump_timer < grind_jump_hold_time)
			return
	if path_follow.progress_ratio >= 0.99 or path_follow.progress_ratio <= 0.01:
		var exit_dir = -path_follow.global_transform.basis.z * grind_direction
		stop_grinding(exit_dir * grind_speed, false)
func _grind_jump(forward_vector: Vector3, quick: bool) -> void:
	grind_jump_timer = -1.0
	grind_jump_quick = quick
	stop_grinding(Vector3.UP * jump_force + forward_vector * grind_speed, true)
	_change_state(State.JUMP)
func _center_model_on_rail() -> void:
	if _grind_skel == null or not is_instance_valid(_grind_skel):
		var found := model.find_children("*", "Skeleton3D", true, false)
		_grind_skel = found[0] as Skeleton3D if not found.is_empty() else null
	if _grind_skel == null:
		return
	var bl := _grind_skel.find_bone(grind_foot_bone_l)
	var br := _grind_skel.find_bone(grind_foot_bone_r)
	if bl < 0 or br < 0:
		if not _grind_center_warned:
			_grind_center_warned = true
			push_warning("Grind: кости ступней '%s'/'%s' не найдены — центровка по рельсу отключена" % [grind_foot_bone_l, grind_foot_bone_r])
		return
	var pl := _grind_skel.to_global(_grind_skel.get_bone_global_pose(bl).origin)
	var pr := _grind_skel.to_global(_grind_skel.get_bone_global_pose(br).origin)
	var lateral := path_follow.to_local((pl + pr) * 0.5).x
	grind_center_x = clampf(grind_center_x - lateral * 0.35, -1.5, 1.5)
func _update_grind_animation(boosting: bool) -> void:
	if Input.is_action_just_pressed("stomp") and anim.has_animation("sonic_grindswitchAL"):
		anim.speed_scale = 1.0
		anim.play("sonic_grindswitchAL", 0.1)
		grind_switch_active = true
	if grind_switch_active:
		if anim.assigned_animation == "sonic_grindswitchAL" and anim.is_playing():
			return
		grind_switch_active = false
	var lean := Input.get_axis("ui_right", "ui_left")
	var target := "sonic_grind_squat" if boosting else "sonic_grind_stand_long"
	var blend := 0.6 if boosting else 0.1
	if lean > 0.3 and anim.has_animation("sonic_grind_L"):
		target = "sonic_grind_L"
		blend = 0.15
	elif lean < -0.3 and anim.has_animation("sonic_grind_R"):
		target = "sonic_grind_R"
		blend = 0.15
	if not anim.has_animation(target):
		return
	if anim.assigned_animation != target:
		anim.speed_scale = 1.0
		anim.play(target, blend)
func stop_grinding(exit_velocity: Vector3, is_jumping_exit: bool = false) -> void:
	Audio.stop_loop("rail")
	if camera and not is_rail_quick_stepping:
		if camera_tween: camera_tween.kill()
		camera_tween = create_tween()
		camera_tween.tween_property(camera, "fov", normal_fov, 0.1).set_trans(Tween.TRANS_SINE)
		camera.position = Vector3(0.0, -2.4, 6.872)
		camera.rotation = Vector3(deg_to_rad(-30.2), 0.0, 0.0)
	_change_state(State.GROUND if is_on_floor() else State.JUMP)
	var saved_model_global_transform = model.global_transform
	path_follow.rotation.z = 0.0
	path_follow.reparent(self)
	model.reparent(self)
	sparkle.emitting = false
	var current_yaw = saved_model_global_transform.basis.get_euler().y
	global_transform.basis = Basis.from_euler(Vector3(0, current_yaw, 0))
	model.position = Vector3(0, -0.065, 0)
	model.rotation = Vector3(deg_to_rad(0), PI, 0)
	local_up = Vector3.UP
	if is_jumping_exit:
		global_position.y += 0.5
	else:
		var floor_test = move_and_collide(Vector3.DOWN * 0.5, true)
		if floor_test:
			global_position = floor_test.get_position()
			_change_state(State.GROUND)
	if has_node("Area3D"):
		$Area3D.monitoring = false
		get_tree().create_timer(0.4).timeout.connect(func():
			if has_node("Area3D") and current_state != State.GRINDING:
				$Area3D.monitoring = true
		)
	if exit_velocity != Vector3.ZERO:
		if is_jumping_exit:
			var flat_exit = exit_velocity
			flat_exit.y = 0.0
			custom_velocity = flat_exit + Vector3.UP * jump_force
			is_jumping = true
			can_double_jump = true
			jump_start_y = global_position.y
			can_homing_dash = true
			var quick_jump: bool = grind_jump_quick and anim.has_animation("sonic_grindsquatjump")
			var jump_anim: String = "sonic_grindsquatjump" if quick_jump else "global/sn_jump_d"
			if not is_rail_quick_stepping and anim.has_animation(jump_anim):
				anim.speed_scale = grind_jump_anim_speed if quick_jump else 1.0
				anim.play(jump_anim, 0.05 if quick_jump else 0.1)
		else:
			if is_on_floor() or not is_jumping_exit:
				var floor_test = move_and_collide(Vector3.DOWN * 0.5, true)
				if floor_test:
					var floor_normal = floor_test.get_normal()
					var slide_velocity = exit_velocity - floor_normal * exit_velocity.dot(floor_normal)
					custom_velocity = slide_velocity
				else:
					custom_velocity = exit_velocity
			else:
				custom_velocity = exit_velocity
			is_jumping = false
	else:
		custom_velocity = exit_velocity
	velocity = custom_velocity
func _grind_step_anim(left: bool) -> String:
	var names: Array = ["sonic_grindmoveL", "global/sn_grind_move_L_l"] if left else ["sonic_grindmoveR", "global/sn_grind_move_r_l"]
	for n in names:
		if anim.has_animation(n):
			return n
	return ""
func _find_side_rail(side_dir: Vector3) -> Node:
	var current_path: Node = path_follow.get_parent()
	var max_side: float = quick_step_distance * 1.5
	var best: Node = null
	var best_dist: float = INF
	for r in get_tree().get_nodes_in_group("Rail"):
		if not is_instance_valid(r) or not ("path_3d" in r):
			continue
		var p := r.path_3d as Path3D
		if p == null or p == current_path or p.curve == null:
			continue
		var off: float = p.curve.get_closest_offset(p.to_local(global_position))
		var to_pt: Vector3 = p.to_global(p.curve.sample_baked(off)) - global_position
		var side: float = to_pt.dot(side_dir)
		if side < 0.5 or side > max_side:
			continue
		var dist: float = to_pt.length()
		if dist < best_dist:
			best_dist = dist
			best = r
	return best
func try_rail_quick_step(direction: float) -> void:
	if is_rail_quick_stepping:
		return
	var travel: Vector3 = -path_follow.global_transform.basis.z * grind_direction
	var side_dir: Vector3 = travel.cross(Vector3.UP)
	if side_dir.length() < 0.01:
		side_dir = path_follow.global_transform.basis.x
	side_dir = side_dir.normalized() * direction
	var hit_rail: Node = _find_side_rail(side_dir)
	if hit_rail == null:
		return
	var new_path: Path3D = hit_rail.path_3d
	var new_offset: float = new_path.curve.get_closest_offset(new_path.to_local(global_position))
	var old_global_pos: Vector3 = global_position
	var keep_speed: float = grind_speed
	if has_node("Area3D"): $Area3D.monitoring = false
	is_rail_quick_stepping = true
	stop_grinding(Vector3.ZERO, false)
	is_rail_quick_stepping = false
	start_grinding(new_path, new_offset)
	is_rail_quick_stepping = true
	grind_speed = keep_speed
	var new_rail_forward: Vector3 = -path_follow.global_transform.basis.z.normalized()
	grind_direction = -1.0 if travel.dot(new_rail_forward) < 0.0 else 1.0
	var step_anim: String = _grind_step_anim(direction < 0.0)
	anim.speed_scale = rail_quick_step_anim_speed
	if step_anim != "":
		anim.play(step_anim, 0.1)
	global_position = old_global_pos
	var target_visual_pos = model.position
	model.global_position = old_global_pos
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "global_position", path_follow.global_position, rail_quick_step_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(model, "position", target_visual_pos, rail_quick_step_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.chain().tween_callback(func():
		is_rail_quick_stepping = false
		anim.speed_scale = 1.0
	)
	Audio.play("step")
func enter_skydive_zone(zone: Node) -> void:
	if not skydive_zones.has(zone):
		skydive_zones.append(zone)
func exit_skydive_zone(zone: Node) -> void:
	skydive_zones.erase(zone)
func _try_start_skydive() -> void:
	skydive_zones = skydive_zones.filter(func(z): return is_instance_valid(z))
	if skydive_zones.is_empty() or not can_move or is_dead or is_intro:
		return
	if qte_flying or qte_fail_locked or is_homing_tracking or is_lsd_active:
		return
	if not (current_state in [State.JUMP, State.BOUNCE, State.GROUND, State.BOOST]):
		return
	if grounded or custom_velocity.y > 0.0:
		return
	var q := PhysicsRayQueryParameters3D.create(global_position, global_position + Vector3.DOWN * skydive_min_height)
	q.exclude = _ray_excludes()
	if not get_world_3d().direct_space_state.intersect_ray(q).is_empty():
		return
	_start_skydive()
func _start_skydive() -> void:
	if not _skydive_anims_ready:
		_skydive_anims_ready = true
		for n in [skydive_anim, skydive_boost_anim]:
			if anim.has_animation(n):
				anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
	if current_state == State.BOOST or is_boosting:
		is_boosting = false
		_boost_hide()
		Audio.stop("boost")
	_cancel_quick_step()
	flag.spring = false
	flag.dash = false
	flag.trick = false
	flag.stomp = false
	flag["fall"] = false
	is_doing_trick = false
	in_hurdle = false
	jump_track_active = false
	after_homing = false
	ramp_anim_active = false
	wall_jump_control_lock = 0.0
	skydive_boosting = false
	var flat := Vector3(custom_velocity.x, 0.0, custom_velocity.z)
	skydive_face = flat.normalized() if flat.length() > 1.0 else model.global_transform.basis.z.slide(Vector3.UP).normalized()
	if skydive_face.length() < 0.01:
		skydive_face = -transform.basis.z.slide(Vector3.UP).normalized()
	local_up = Vector3.UP
	_change_state(State.SKYDIVE)
	anim.speed_scale = 1.0
	_update_skydive_animation()
func _skydive_physics(delta: float) -> void:
	skydive_zones = skydive_zones.filter(func(z): return is_instance_valid(z))
	if skydive_zones.is_empty():
		_end_skydive(false)
		return
	skydive_boosting = can_move and _held(&"boost")
	var input_dir := Vector2.ZERO
	if can_move:
		input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var cam_basis := Basis.from_euler(Vector3(cam_pitch, cam_yaw, 0.0))
	var cam_right: Vector3 = cam_basis.x.slide(Vector3.UP).normalized()
	var cam_fwd: Vector3 = Vector3.UP.cross(cam_right).normalized()
	var move_dir: Vector3 = (cam_right * input_dir.x + cam_fwd * input_dir.y)
	if move_dir.length() > 0.01:
		move_dir = move_dir.normalized()
	elif skydive_boosting:
		move_dir = skydive_face
	else:
		move_dir = Vector3.ZERO
	var max_h: float = skydive_boost_move_speed if skydive_boosting else skydive_move_speed
	var h := Vector3(custom_velocity.x, 0.0, custom_velocity.z)
	var h_speed: float = h.length()
	if h_speed > max_h:
		h_speed = move_toward(h_speed, max_h, skydive_overspeed_drag * delta)
		h = h.normalized() * h_speed
	if move_dir != Vector3.ZERO:
		h = h.move_toward(move_dir * max_h, skydive_acceleration * delta)
	else:
		h = h.move_toward(Vector3.ZERO, skydive_drag * delta)
	if h.length() > 1.0:
		skydive_face = h.normalized()
	var target_fall: float = skydive_boost_fall_speed if skydive_boosting else skydive_fall_speed
	var vy: float = custom_velocity.y
	var rate: float
	if vy > -target_fall:
		rate = skydive_boost_gravity if skydive_boosting else skydive_gravity
	else:
		rate = skydive_air_resistance
	vy = move_toward(vy, -target_fall, rate * delta)
	custom_velocity = Vector3(h.x, vy, h.z)
	var local_face: Vector3 = transform.basis.inverse() * skydive_face
	var target_angle: float = atan2(local_face.x, local_face.z)
	model.rotation.y = lerp_angle(model.rotation.y, target_angle, minf(skydive_turn_speed * delta, 1.0))
	current_lean = move_toward(current_lean, 0.0, lean_speed * delta)
	model.rotation.z = current_lean
	align_to_surface(Vector3.UP)
	up_direction = Vector3.UP
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	velocity = custom_velocity
	move_and_slide()
	custom_velocity = velocity
	grounded = false
	var look: float = maxf(skydive_land_check, -custom_velocity.y * delta * 2.0)
	var q := PhysicsRayQueryParameters3D.create(global_position, global_position + Vector3.DOWN * look)
	q.exclude = _ray_excludes()
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty() and custom_velocity.y <= 0.0:
		var d: float = global_position.distance_to(hit.position)
		move_and_collide(Vector3.DOWN * maxf(d - target_floor_dist, 0.0))
		_end_skydive(true, hit.normal)
		return
	if is_on_floor():
		_end_skydive(true, get_floor_normal())
		return
	_update_skydive_animation()
	_update_skydive_camera(delta)
func _update_skydive_camera(delta: float) -> void:
	cam_manual_timer = 0.0
	cam_recentering = false
	var goal_yaw: float = atan2(-skydive_face.x, -skydive_face.z)
	var diff: float = angle_difference(target_yaw, goal_yaw)
	target_yaw += clampf(diff * skydive_cam_yaw_speed, -skydive_cam_max_turn, skydive_cam_max_turn) * delta
	target_pitch = lerpf(target_pitch, skydive_cam_pitch, minf(skydive_cam_pitch_speed * delta, 1.0))
	cam_yaw = lerp_angle(cam_yaw, target_yaw, minf(camera_inertia * delta, 1.0))
	cam_pitch = lerpf(cam_pitch, target_pitch, minf(camera_inertia * delta, 1.0))
	update_camera()
func _update_skydive_animation() -> void:
	var n: String = skydive_boost_anim if skydive_boosting else skydive_anim
	if not anim.has_animation(n):
		return
	anim.speed_scale = 1.0
	if anim.current_animation != n or not anim.is_playing():
		anim.play(n, skydive_anim_blend)
func _end_skydive(landed: bool, normal: Vector3 = Vector3.UP) -> void:
	skydive_boosting = false
	_stop_air_boost()
	anim.speed_scale = 1.0
	if landed:
		_change_state(State.GROUND)
		grounded = true
		handle_surface(normal)
		_handle_landing()
	else:
		_change_state(State.JUMP)
		is_jumping = true
		can_double_jump = false
		can_homing_dash = true
		jump_start_y = global_position.y
		flag["fall"] = true
func _find_all_texture_buttons(node: Node) -> Array:
	var result = []
	if node is TextureButton:
		result.append(node)
	for child in node.get_children():
		result.append_array(_find_all_texture_buttons(child))
	return result
func _held(action: StringName) -> bool:
	if action == &"boost" and _boost_wall_lock:
		if not Input.is_action_pressed(action):
			_boost_wall_lock = false
		return false
	return Input.is_action_pressed(action) and _act_down.get(action, true)
func _end_boost() -> void:
	is_boosting = false
	_boost_hide()
	Audio.stop("boost")
func _get_ui_buttons() -> Array:
	var now: int = Time.get_ticks_msec()
	var stale: bool = now - _ui_buttons_time > 1000
	if not stale:
		for b in _ui_buttons:
			if not is_instance_valid(b):
				stale = true
				break
	if stale:
		_ui_buttons = _find_all_texture_buttons(get_tree().root)
		_ui_buttons_time = now
	return _ui_buttons
func _button_actions(button) -> Array:
	var result: Array = []
	if button.shortcut == null:
		return result
	for shortcut_event in button.shortcut.events:
		if shortcut_event is InputEventAction:
			result.append(shortcut_event.action)
	return result
func _send_action(action: StringName, pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	Input.parse_input_event(ev)
func _autozone_floor_at(space: PhysicsDirectSpaceState3D, p: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(p + local_up * 1.5, p - local_up * 3.0)
	q.exclude = _ray_excludes()
	var hit: Dictionary = space.intersect_ray(q)
	if hit.is_empty():
		return false
	var c: Node = hit.collider as Node
	return c != null and c.is_in_group(autozone_group) and (hit.normal as Vector3).dot(local_up) > 0.6
func _autozone_scan(space: PhysicsDirectSpaceState3D, p: Vector3, right: Vector3) -> Dictionary:
	if not _autozone_floor_at(space, p):
		return {}
	var ext: Array[float] = [0.0, 0.0]
	for i in 2:
		var side: float = -1.0 if i == 0 else 1.0
		var good: float = 0.0
		var off: float = autozone_scan_step
		var capped: bool = true
		while off <= autozone_half_width:
			if _autozone_floor_at(space, p + right * side * off):
				good = off
				off += autozone_scan_step
			else:
				var lo: float = good
				var hi: float = off
				for k in 3:
					var mid: float = (lo + hi) * 0.5
					if _autozone_floor_at(space, p + right * side * mid):
						lo = mid
					else:
						hi = mid
				good = lo
				capped = false
				break
		if capped:
			return {}
		ext[i] = good
	return {"offset": (ext[1] - ext[0]) * 0.5, "width": ext[0] + ext[1]}
func _autozone_steer(delta: float, input_dir: Vector2, move_direction: Vector3) -> Vector3:
	if not autozone_enabled or not grounded or not can_move or loop_assist_active or is_quick_stepping:
		return Vector3.ZERO
	if current_state != State.GROUND and current_state != State.BOOST:
		return Vector3.ZERO
	if input_dir.length() < 0.1 or move_direction.length() < 0.01:
		return Vector3.ZERO
	var along: Vector3 = custom_velocity.slide(local_up)
	var speed: float = along.length()
	var min_speed: float = 5.0 if current_state == State.BOOST else autozone_min_speed
	if speed < min_speed:
		return Vector3.ZERO
	var run_dir: Vector3 = along / speed
	if absf(run_dir.signed_angle_to(move_direction, local_up)) > deg_to_rad(autozone_release_angle_deg):
		return Vector3.ZERO
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var right: Vector3 = run_dir.cross(local_up).normalized()
	var here: Dictionary = _autozone_scan(space, global_position, right)
	if here.is_empty():
		return Vector3.ZERO
	var look: float = clampf(speed * autozone_look_time, autozone_look_min, autozone_look_max)
	var target: Vector3 = global_position + run_dir * look + right * float(here.offset)
	for f in [1.0, 0.5]:
		var ahead: Vector3 = global_position + run_dir * look * f
		var info: Dictionary = _autozone_scan(space, ahead, right)
		if not info.is_empty():
			target = ahead + right * float(info.offset)
			break
	var desired: Vector3 = (target - global_position).slide(local_up)
	if desired.length() < 0.01:
		return Vector3.ZERO
	desired = desired.normalized()
	var a: float = run_dir.signed_angle_to(desired, local_up)
	var step: float = minf(absf(a), deg_to_rad(autozone_turn_rate_deg) * delta)
	return run_dir.rotated(local_up, signf(a) * step)
