extends Node
@export var player: CharacterBody3D
var is_tracking: bool = false
var start_y: float = 0.0
var max_y: float = 0.0
var label: Label
func _ready() -> void:
	label = Label.new()
	label.position = Vector2(20, 150)
	label.add_theme_font_size_override("font_size", 24)
	add_child(label)
func _process(_delta: float) -> void:
	if not player:
		return
	var current_y = player.global_position.y
	if player.current_state == player.State.JUMP:
		if not is_tracking:
			is_tracking = true
			start_y = current_y
			max_y = current_y
		if current_y > max_y:
			max_y = current_y
		var current_height = max_y - start_y
		label.text = "Высота прыжка: %.2f м" % current_height
	else:
		is_tracking = false
