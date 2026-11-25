extends Base_Object
class_name JumpSelector
signal launched(dir: int)
signal missed
enum Dir { UP, FORWARD, BACK }
@onready var anim = $JumpSelector/AnimationPlayer
@export_group("Selection")
@export var launch_dir: Dir = Dir.UP
@export var select_time: float = 1.5
@export var hold_offset: Vector3 = Vector3.ZERO
@export_group("Launch")
@export var fly_time: float = 2.0
@export var side_speed: float = 55.0
@export var up_speed: float = 65.0
@export_range(0.0, 1.0) var exit_keep: float = 0.35
@export_range(0.0, 1.0) var up_exit_keep: float = 1.0
@export_group("Rotate")
@export var rotate_time: float = 0.35
@export var flip_fb: bool = false
@export var aim_axis: Vector3 = Vector3.FORWARD
@export_group("Miss")
@export var miss_throw_speed: float = 40.0
@export var miss_lock_time: float = 0.8
@export var main_anim: StringName = &"main"
@export_group("Reuse")
@export var rearm_time: float = 1.5
@onready var model: Node3D = $JumpSelector
@onready var rest_basis: Basis = $JumpSelector.basis
var rot_tween: Tween
var busy: bool = false
func is_available() -> bool:
	return not busy
func claim() -> void:
	busy = true
func release() -> void:
	if rearm_time < 0.0:
		return
	await get_tree().create_timer(rearm_time).timeout
	_tween_model(rest_basis)
	busy = false
func local_dir(dir: int) -> Vector3:
	if dir == Dir.UP:
		return Vector3.UP
	var z: float = -1.0 if dir == Dir.FORWARD else 1.0
	if flip_fb:
		z = -z
	return Vector3(0.0, 0.0, z)
func direction_vector(dir: int) -> Vector3:
	return (global_transform.basis.orthonormalized() * local_dir(dir)).normalized()
func speed_for(dir: int) -> float:
	return up_speed if dir == Dir.UP else side_speed
func hold_position() -> Vector3:
	return global_transform * hold_offset
func _tween_model(target: Basis) -> void:
	if anim:
		anim.pause()
	if rot_tween and rot_tween.is_valid():
		rot_tween.kill()
	var sc: Vector3 = rest_basis.get_scale()
	var from: Quaternion = model.basis.get_rotation_quaternion()
	var to: Quaternion = target.get_rotation_quaternion()
	rot_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	rot_tween.tween_method(func(t: float): model.basis = Basis(from.slerp(to, t)) * Basis.from_scale(sc), 0.0, 1.0, rotate_time)
func rotate_to(dir: int) -> float:
	var from_v: Vector3 = (rest_basis * aim_axis.normalized()).normalized()
	_tween_model(Basis(Quaternion(from_v, -local_dir(dir))) * rest_basis)
	return rotate_time
func play_main() -> float:
	if anim and anim.has_animation(main_anim):
		anim.play(main_anim)
		return anim.get_animation(main_anim).length
	return rotate_time
