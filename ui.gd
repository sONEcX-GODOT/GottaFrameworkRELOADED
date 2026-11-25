extends CanvasLayer
var buttons: Array = []
var offsets: Array = []
func _ready() -> void:
	var button = get_tree().get_nodes_in_group("Buttons")
	if OS.get_name() == "windows":
		button.visible = false 
	for child in get_children():
		if child is TouchScreenButton:
			buttons.append(child)
			offsets.append(child.position)
	get_viewport().size_changed.connect(_on_screen_resized)
	_on_screen_resized()
func _on_screen_resized() -> void:
	var vp = get_viewport()
	var transform = vp.get_screen_transform()
	var scale = transform.get_scale()
	var black_bars_offset = transform.origin / scale
	for i in range(buttons.size()):
		buttons[i].position.x = offsets[i].x - (black_bars_offset.x * scale.x)
		buttons[i].position.y = offsets[i].y - (black_bars_offset.y * scale.y)
