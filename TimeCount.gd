extends Label

func _process(_delta):
	var total = GameManager.level_time
	var minutes = int(total) / 60
	var seconds = int(total) % 60
	var milliseconds = int((total - int(total)) * 100)
	
	text = "%02d:%02d.%02d" % [minutes, seconds, milliseconds]
