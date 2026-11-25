extends CharacterBody3D
class_name EggFighter
@export_group("Egg Fighter")
@export var is_active: bool = true
@onready var anim = $egg/AnimationPlayer
@onready var attack_zone = $egg/%GeneralSkeleton/BoneAttachment3D/AttackArea
@onready var visual = $egg
@onready var collision = $CollisionShape3D
@onready var area = $Area3D
@onready var effect = $AnimatedSprite3D
@onready var jump_area: Area3D = find_child("JumpArea", true, false) as Area3D
@export var gravity: float = 70
@export_group("Knockback Settings")
@export var fly_speed: float = 45.0
@export var upward_force: float = 2.0
@export var target_search_radius: float = 25.0
@export var Homing: bool = false
@export_group("Sonic Interaction")
@export var kick_range: float = 4.0
@export var homing_point_height: float = 1.5
@export_group("Fly Modes")
@export var homing_fly_max_time: float = 2.0
@export var homing_hit_radius: float = 1.5
@export var boost_chain_fly_time: float = 0.5
enum FlyMode { NONE, HOMING, BOOST_CHAIN }
var is_flying: bool = false
var fly_direction: Vector3 = Vector3.ZERO
var _exploded: bool = false
var _fly_mode: FlyMode = FlyMode.NONE
var _launch_dir: Vector3 = Vector3.ZERO
var _fly_timer: float = 0.0
var _fly_stopped: bool = false
var _chain_id: int = -1
static var _chain_deadlines: Dictionary = {}
static var _next_chain_id: int = 0
static var _current_boost_chain: int = -1
static var _homing_grace_until: float = 0.0
static func _now() -> float:
	return Time.get_ticks_msec() / 1000.0
func _ready() -> void:
	add_to_group("enemies")
	add_to_group("EggFighter")
	if area:
		area.area_entered.connect(_on_area_entered)
	if attack_zone:
		attack_zone.body_entered.connect(_on_attack_zone_body_entered)
func _physics_process(delta: float) -> void:
	if _exploded:
		return
	if is_active:
		velocity.y -= gravity * delta
		anim.play("wait")
		_check_player_attack()
	elif is_flying:
		_fly_timer += delta
		if _fly_mode == FlyMode.BOOST_CHAIN:
			if _now() >= _chain_deadlines.get(_chain_id, 0.0):
				_explode_chain(_chain_id)
				return
		elif _fly_timer >= homing_fly_max_time:
			explode()
			return
		if _fly_stopped:
			velocity = Vector3.ZERO
		else:
			velocity = fly_direction * fly_speed
			velocity.y = upward_force
			if _wall_ahead(velocity * delta):
				_on_fly_wall_hit()
				if _exploded:
					return
				velocity = Vector3.ZERO
	else:
		velocity = Vector3.ZERO
	move_and_slide()
	if is_flying:
		_check_fly_collisions()
func can_be_homed() -> bool:
	return not _exploded and not is_flying
func get_homing_point() -> Vector3:
	if collision:
		return collision.global_position
	return global_position + Vector3(0, homing_point_height, 0)
func on_homing_hit(player: Node3D) -> void:
	if _exploded or is_flying:
		return
	var dir: Vector3 = global_position - player.global_position
	dir.y = 0
	if dir.length_squared() > 0.001:
		dir = dir.normalized()
	else:
		dir = _get_player_facing(player)
	_homing_grace_until = _now() + 0.3
	_start_flying(dir, FlyMode.HOMING)
func destroy() -> void:
	explode()
func _get_player_facing(player: Node3D) -> Vector3:
	var dir: Vector3 = -player.global_transform.basis.z
	dir.y = 0
	if dir.length_squared() < 0.001:
		return Vector3.FORWARD
	return dir.normalized()
func _uses_jump_area(sonic: SonicPlayer) -> bool:
	if jump_area == null or sonic.is_homing_tracking:
		return false
	var st = sonic.current_state
	return st == SonicPlayer.State.JUMP or st == SonicPlayer.State.STOMP or st == SonicPlayer.State.SQUAT_KICK
func _is_air_attack(sonic: SonicPlayer) -> bool:
	var st = sonic.current_state
	return st == SonicPlayer.State.JUMP or st == SonicPlayer.State.STOMP or st == SonicPlayer.State.BOUNCE
func _handle_player_touch(sonic: SonicPlayer) -> void:
	if not is_active or _exploded:
		return
	if sonic.current_state == SonicPlayer.State.BOOST:
		launch_fighter(sonic)
	elif sonic.current_state == SonicPlayer.State.SQUAT_KICK:
		if _uses_jump_area(sonic) and not jump_area.overlaps_body(sonic):
			return
		_shake_camera()
		explode()
	elif _is_air_attack(sonic) and not sonic.is_homing_tracking:
		if _uses_jump_area(sonic) and not jump_area.overlaps_body(sonic):
			return
		if _now() < _homing_grace_until:
			return
		_shake_camera()
		explode()
		sonic.bounce_off_enemy()
func _touching(sonic: SonicPlayer) -> bool:
	if _uses_jump_area(sonic):
		return jump_area.overlaps_body(sonic)
	return area != null and area.overlaps_body(sonic)
func _check_player_attack() -> void:
	for p in get_tree().get_nodes_in_group("Player"):
		var sonic := p as SonicPlayer
		if sonic == null:
			continue
		if sonic.current_state == SonicPlayer.State.SQUAT_KICK:
			if jump_area:
				if jump_area.overlaps_body(sonic):
					_handle_player_touch(sonic)
					return
			else:
				var d: Vector3 = sonic.global_position - global_position
				if absf(d.y) <= 3.0 and Vector2(d.x, d.z).length() <= kick_range:
					_handle_player_touch(sonic)
					return
		elif _touching(sonic):
			_handle_player_touch(sonic)
			if not is_active:
				return
func _on_area_3d_body_entered(body: Node3D) -> void:
	var sonic := body as SonicPlayer
	if sonic:
		_handle_player_touch(sonic)
func _on_attack_zone_body_entered(body: Node3D) -> void:
	if not is_active:
		return
	var sonic := body as SonicPlayer
	if sonic == null:
		return
	if sonic.current_state == SonicPlayer.State.BOOST \
			or sonic.current_state == SonicPlayer.State.SQUAT_KICK \
			or sonic.is_homing_tracking \
			or _is_air_attack(sonic):
		return
	is_active = false
	sonic._on_hit()
	anim.play("punch")
	await get_tree().create_timer(0.5).timeout
	sonic._change_state(SonicPlayer.State.GROUND)
	sonic.can_move = true
	RingCount.lose_rings()
func launch_fighter(player: Node3D) -> void:
	var dir: Vector3
	var target_egg = _find_closest_egg()
	if target_egg:
		var to_target = target_egg.global_position - global_position
		to_target.y = 0
		dir = to_target.normalized()
	else:
		var move_dir = player.velocity
		move_dir.y = 0
		if move_dir.length_squared() > 0.001:
			dir = move_dir.normalized()
		else:
			dir = _get_player_facing(player)
	if _current_boost_chain == -1 or not _chain_deadlines.has(_current_boost_chain):
		_current_boost_chain = _next_chain_id
		_next_chain_id += 1
	join_chain(_current_boost_chain, dir)
func join_chain(chain_id: int, dir: Vector3) -> void:
	if _exploded or is_flying:
		return
	_chain_id = chain_id
	_chain_deadlines[chain_id] = _now() + boost_chain_fly_time
	_start_flying(dir, FlyMode.BOOST_CHAIN)
func _start_flying(dir: Vector3, mode: FlyMode) -> void:
	is_active = false
	is_flying = true
	_fly_mode = mode
	_fly_timer = 0.0
	_fly_stopped = false
	_launch_dir = dir
	fly_direction = dir
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	if attack_zone:
		attack_zone.set_deferred("monitoring", false)
func _find_closest_egg() -> EggFighter:
	var closest_egg: EggFighter = null
	var min_distance: float = target_search_radius
	for node in get_tree().get_nodes_in_group("EggFighter"):
		if node is EggFighter and node != self and node.is_active and not node.is_flying:
			var dist = global_position.distance_to(node.global_position)
			if dist < min_distance:
				min_distance = dist
				closest_egg = node
	return closest_egg
func _check_fly_collisions() -> void:
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		if c.get_normal().y > 0.7:
			continue
		var other = c.get_collider()
		if other is SonicPlayer:
			continue
		if other is EggFighter:
			_on_egg_contact(other)
			if _exploded:
				return
			continue
		_on_fly_wall_hit()
		return
func _on_fly_wall_hit() -> void:
	if _fly_mode == FlyMode.BOOST_CHAIN:
		_fly_stopped = true
		velocity = Vector3.ZERO
		return
	_shake_camera()
	explode()

func _body_radius() -> float:
	if collision and collision.shape is CapsuleShape3D:
		return (collision.shape as CapsuleShape3D).radius
	if collision and collision.shape is SphereShape3D:
		return (collision.shape as SphereShape3D).radius
	return 0.5

func _fly_excludes() -> Array[RID]:
	var ex: Array[RID] = [get_rid()]
	for n in get_tree().get_nodes_in_group("Player"):
		if n is CollisionObject3D:
			ex.append(n.get_rid())
	for n in get_tree().get_nodes_in_group("EggFighter"):
		if n is CollisionObject3D and n != self:
			ex.append(n.get_rid())
	return ex

func _wall_ahead(motion: Vector3) -> bool:
	var h := Vector3(motion.x, 0.0, motion.z)
	var len := h.length()
	if len < 0.0001:
		return false
	var from: Vector3 = collision.global_position if collision else global_position
	var to: Vector3 = from + h / len * (len + _body_radius())
	var q := PhysicsRayQueryParameters3D.create(from, to, collision_mask)
	q.exclude = _fly_excludes()
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(q)
	return not hit.is_empty() and hit.normal.y < 0.7

func _on_area_entered(other_area: Area3D) -> void:
	if not is_flying or not (other_area.owner is EggFighter):
		return
	var other := other_area.owner as EggFighter
	if _fly_mode == FlyMode.HOMING:
		var d: Vector3 = other.global_position - global_position
		d.y = 0
		if d.length() > homing_hit_radius:
			return
	_on_egg_contact(other)
func _on_egg_contact(other: EggFighter) -> void:
	if _exploded or other == self:
		return
	if other._exploded or not other.is_active:
		return
	if _fly_mode == FlyMode.HOMING:
		_shake_camera()
		other.explode()
		explode()
	elif _fly_mode == FlyMode.BOOST_CHAIN:
		other.join_chain(_chain_id, _launch_dir)
func _explode_chain(chain_id: int) -> void:
	_chain_deadlines.erase(chain_id)
	if _current_boost_chain == chain_id:
		_current_boost_chain = -1
	var members: Array = []
	for node in get_tree().get_nodes_in_group("EggFighter"):
		if node is EggFighter and node._chain_id == chain_id and not node._exploded:
			members.append(node)
	if members.size() > 0:
		_shake_camera()
	for m in members:
		m.explode()
func _shake_camera() -> void:
	var camera = get_tree().get_first_node_in_group("Camera")
	if camera and camera.has_method("shake"):
		camera.shake()
func explode() -> void:
	if _exploded:
		return
	_exploded = true
	Audio.play("exp")

	GameManager.score += 500
	is_active = false
	is_flying = false
	velocity = Vector3.ZERO
	collision.set_deferred("disabled", true)
	if attack_zone:
		attack_zone.set_deferred("monitoring", false)
	if area:
		area.set_deferred("monitoring", false)
		area.set_deferred("monitorable", false)
	visual.visible = false
	effect.play("default")
	effect.visible = true
	var mat = effect.material_override as StandardMaterial3D
	if mat:
		mat.albedo_color = Color(1, 1, 1, 1)
		var tween = create_tween()
		tween.tween_interval(0.2)
		tween.tween_property(mat, "albedo_color:a", 0.0, 0.5).set_trans(Tween.TRANS_LINEAR)
		await tween.finished
	else:
		await effect.animation_finished
	queue_free()
