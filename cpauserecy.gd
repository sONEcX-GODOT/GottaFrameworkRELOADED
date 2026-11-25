extends ColorRect
func _physics_process(delta: float) -> void:
	visible = get_tree().paused == true 
