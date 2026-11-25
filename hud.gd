extends CanvasLayer
class_name HUD
enum mode {Werehog, Sonic}
@onready var pause_bg: TextureRect = $Pause
@onready var label_restart: Label = $Label2
@onready var label_quit: Label = $Label3
@onready var current_mode = mode.Sonic
var items: Array[Label] = []
var normal_styles: Array[StyleBox] = []
var focus_styles: Array[StyleBox] = []
var current_index: int = 0
var stick_moved: bool = false
func _ready() -> void:
	items = [label_restart, label_quit]
	for item in items:
		normal_styles.append(item.get_theme_stylebox("normal"))
		focus_styles.append(item.get_theme_stylebox("focus"))
	_update_selection()
func _process(_delta: float) -> void:
	if not label_restart.is_visible_in_tree():
		return
	var buttons = _find_all_texture_buttons(get_tree().root)
	for button in buttons:
		if button.shortcut and not button.shortcut.events.is_empty():
			for event in button.shortcut.events:
				if event is InputEventAction:
					var action = event.action
					if Input.is_action_just_pressed(action):
						button.button_pressed = true
					elif Input.is_action_just_released(action):
						button.button_pressed = false
	var axis_y: float = Input.get_axis("ui_up", "ui_down")
	if axis_y > 0.5 and not stick_moved:
		stick_moved = true
		current_index = wrapi(current_index + 1, 0, items.size())
		_update_selection()
	elif axis_y < -0.5 and not stick_moved:
		stick_moved = true
		current_index = wrapi(current_index - 1, 0, items.size())
		_update_selection()
	elif abs(axis_y) < 0.2:
		stick_moved = false
	if Input.is_action_just_pressed("jump"):
		_confirm_selection()
func _input(event: InputEvent) -> void:
	if not label_restart.is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		var buttons = _find_all_texture_buttons(get_tree().root)
		for button in buttons:
			if button.shortcut and not button.shortcut.events.is_empty():
				for shortcut_event in button.shortcut.events:
					if shortcut_event is InputEventAction:
						var action = shortcut_event.action
						if button.get_global_rect().has_point(event.position):
							if event.pressed:
								button.button_pressed = true
								Input.action_press(action)
							else:
								button.button_pressed = false
								Input.action_release(action)
						elif not event.pressed and button.button_pressed:
							Input.action_release(action)
							button.button_pressed = false
func _update_selection() -> void:
	for i in items.size():
		if i == current_index:
			items[i].add_theme_stylebox_override("normal", focus_styles[i])
		else:
			items[i].add_theme_stylebox_override("normal", normal_styles[i])
func _confirm_selection() -> void:
	get_tree().paused = false
	if current_index == 0:
		GameManager.register_death()
		get_tree().reload_current_scene()
	elif current_index == 1:
		
		get_tree().change_scene_to_file("res://Levels/main_menu.tscn")
func _find_all_texture_buttons(node: Node) -> Array:
	var result = []
	if node is TextureButton:
		result.append(node)
	for child in node.get_children():
		result.append_array(_find_all_texture_buttons(child))
	return result
