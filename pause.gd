extends Control
@export var labels: Array[Label] = []
@onready var focus = get_tree().get_nodes_in_group("Focus")
var idx: int = 0
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	labels.resize(min(labels.size(), 10))
	for i in labels.size():
		if labels[i]:
			labels[i].mouse_filter = MOUSE_FILTER_STOP
			labels[i].gui_input.connect(func(e): if (e is InputEventScreenTouch or e is InputEventMouseButton) and e.pressed: _to(i))
	if not labels.is_empty() and labels.front() and focus.size() >= 2:
		await get_tree().process_frame
		focus[0].global_position = labels.front().global_position
		focus[1].global_position = labels.front().global_position
func _process(_delta: float) -> void:
	var on_pause = get_tree().paused
	visible = on_pause
	for l in labels:
		if l:
			l.visible = on_pause
	if focus.size() >= 2:
		focus[0].visible = on_pause
		focus[1].visible = on_pause and focus[0].global_position.distance_to(focus[1].global_position) > 2.0
func _input(e: InputEvent) -> void:
	if not get_tree().paused or labels.is_empty():
		return
	if e.is_action_pressed("ui_down") or e.is_action_pressed("ui_right"):
		_to(wrapi(idx + 1, 0, labels.size()))
	elif e.is_action_pressed("ui_up") or e.is_action_pressed("ui_left"):
		_to(wrapi(idx - 1, 0, labels.size()))
func _to(i: int) -> void:
	if not get_tree().paused or focus.size() < 2 or not labels[i]:
		return
	idx = i
	focus[1].global_position = labels[i].global_position
	create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).tween_property(focus[0], "global_position", labels[i].global_position, 0.2)
