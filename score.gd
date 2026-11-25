extends Label
func _process(_delta: float) -> void:
	text = "%07d" % int(GameManager.score)
