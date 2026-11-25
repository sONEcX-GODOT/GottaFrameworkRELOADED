extends Area3D
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	for child in get_children():
		if child is RigidBody3D:
			child.freeze = true
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		_shatter()
func _shatter() -> void:
	monitoring = false
	monitorable = false
	GameManager.score += 100
	var scene_root = get_tree().current_scene
	for child in get_children():
		if child is RigidBody3D:
			var global_pos = child.global_transform
			remove_child(child)
			scene_root.add_child(child)
			child.global_transform = global_pos
			child.visible = true
			child.freeze = false
			var random_direction = Vector3(randf_range(-1.0, 1.0), randf_range(0.5, 2.0), randf_range(-1.0, 1.0)).normalized()
			child.apply_central_impulse(random_direction * 2.0)
	queue_free()
