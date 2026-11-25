extends Area3D
class_name SuperRing
var is_collected: bool = false
var rotation_speed: float = 9.0
func _physics_process(delta: float) -> void:
	rotate_y(deg_to_rad(rotation_speed))
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player") and not is_collected:
		is_collected = true
		RingCount.add_rings(10)
		body.boost_energy += 30
		animate_pickup()
func animate_pickup() -> void:
	monitoring = false
	Audio.play("10ring")
	
	monitorable = false
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "global_position:y", global_position.y + 1.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation_speed", 50.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.6)
	tween.chain().tween_callback(queue_free)
