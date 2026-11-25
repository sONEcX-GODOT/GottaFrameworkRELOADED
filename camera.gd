extends Node3D
@export var target_path: NodePath = "../../Sonic"
@export var follow_speed = 4.0
@export var rotation_speed = 3.0
@export var base_offset = Vector3(0.0, 3.5, 7.5)
var target: Node3D
func _ready():
	target = get_node(target_path)
func _physics_process(delta):
	if not target: return
	
	var velocity_vector = target.get("custom_velocity")
	var target_basis = global_transform.basis
	if velocity_vector and velocity_vector.length() > 1.0:
		var target_forward = velocity_vector.normalized()
		var target_right = target_forward.cross(Vector3.UP).normalized()
		if target_right.length() > 0.01:
			var real_forward = Vector3.UP.cross(target_right).normalized()
			target_basis = Basis(target_right, Vector3.UP, -real_forward).orthonormalized()
	global_transform.basis = global_transform.basis.slerp(target_basis, rotation_speed * delta)
	var target_pos = target.global_position + global_transform.basis * base_offset
	global_position = global_position.lerp(target_pos, follow_speed * delta)
