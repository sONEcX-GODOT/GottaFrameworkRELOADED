extends Label

var update_timer: float = 0.0
const UPDATE_INTERVAL: float = 0.3 

func _process(delta: float) -> void:
	update_timer += delta
	
	if update_timer >= UPDATE_INTERVAL:
		update_timer = 0.0
		var fps = Engine.get_frames_per_second()
		text = "FPS: " + str(fps)
		if fps >= 55:
			modulate = Color.GREEN
		elif fps >= 30:
			modulate = Color.YELLOW
		else:
			modulate = Color.RED
