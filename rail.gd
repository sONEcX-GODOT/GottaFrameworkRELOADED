extends Area3D
@onready var path_3d: Path3D = $Path3D
@export var trigger_radius: float = 0.8
@export var step_length: float = 1.5
func _ready() -> void:
	add_to_group("Rail")
	generate_spline_collision()
	area_entered.connect(_on_area_entered)
func generate_spline_collision() -> void:
	var curve: Curve3D = path_3d.curve
	var total_length = curve.get_baked_length()
	var current_offset = 0.0
	while current_offset < total_length:
		var pos_transform = curve.sample_baked_with_rotation(current_offset, true)
		var collision_shape = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(trigger_radius * 2, trigger_radius * 2, step_length)
		collision_shape.shape = box
		collision_shape.transform = path_3d.transform * pos_transform
		collision_shape.translate_object_local(Vector3(0, 0, -step_length / 2))
		add_child(collision_shape)
		current_offset += step_length
func _on_area_entered(incoming_area: Area3D) -> void:
	var player = incoming_area.get_parent()
	if player and player.has_method("start_grinding"):
		var local_pos = path_3d.to_local(player.global_position)
		var offset = path_3d.curve.get_closest_offset(local_pos)
		player.start_grinding(path_3d, offset)
