extends Area3D
const WATER_SURFACE_LAYER_BIT = 2
func _ready() -> void:
	body_entered.connect(_on_body_entered)
func _on_body_entered(body: Node3D) -> void:
	if body.has_method("_change_state") and "current_state" in body:
		if body.current_state != body.State.BOOST and not body.is_boosting:
			if body.current_state != body.State.JUMP:
				body._change_state(body.State.JUMP)
				body.is_jumping = true
			body.custom_velocity.y = min(body.custom_velocity.y, -2.0)
			body.set_collision_mask_value(WATER_SURFACE_LAYER_BIT + 1, false)
