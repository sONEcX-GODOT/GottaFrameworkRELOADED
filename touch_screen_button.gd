extends TouchScreenButton
var offset_from_right: float
var offset_from_bottom: float
func _ready() -> void:
	var canvas_transform = get_canvas_transform()
	var size = get_viewport_rect().size / canvas_transform.get_scale()
	offset_from_right = size.x - position.x
	offset_from_bottom = size.y - position.y
	get_viewport().size_changed.connect(_on_screen_resized)
func _on_screen_resized() -> void:
	var canvas_transform = get_canvas_transform()
	var size = get_viewport_rect().size / canvas_transform.get_scale()
	position.x = size.x - offset_from_right
	position.y = size.y - offset_from_bottom
