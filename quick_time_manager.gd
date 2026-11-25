class_name QuickTimeManager
extends CanvasLayer
signal started(sequence: Array)
signal step_correct(index: int, button_name: String)
signal step_wrong(index: int)
signal finished(success: bool, score: int)
enum Platform { PC, ANDROID }
@export_group("Platform")
@export var platform: Platform = Platform.PC
@export var auto_detect_platform: bool = false
@export var handle_touch_buttons: bool = true
@export_group("Actions (PC)")
@export var action_jump: StringName = &"jump"
@export var action_spin: StringName = &"roll"
@export var action_boost: StringName = &"boost"
@export var action_left: StringName = &"quick_step_left"
@export var action_right: StringName = &"quick_step_right"
@export_group("Timing")
@export var time_limit: float = 1.2
@export var time_bonus_per_press: float = 0.0
@export var result_show_time: float = 0.5
@export_group("Score")
@export var score_per_press: int = 100
@export var score_per_second_left: int = 200
@export var success_bonus: int = 500
@export var use_combo: bool = true
@export var score_label: Label
@export_group("Visuals")
@export var pending_color: Color = Color(1, 1, 1, 0.4)
@export var active_color: Color = Color(1, 1, 1, 1)
@export_group("Sounds")
@export var sound_correct: String = ""
@export var sound_wrong: String = ""
@export var sound_success: String = ""
@export var sound_fail: String = ""
@export_group("Test")
@export var test_auto_start: bool = true
@export_group("Debug")
@export var debug_print: bool = false
var active: bool = false
var _kb: Array = []
var _mb: Array = []
var _base_off: Dictionary = {}
var _tweens: Dictionary = {}
var _seq: Array = []
var _index: int = 0
var _time_left: float = 0.0
var _time_total: float = 1.0
var _score: int = 0
var _combo: int = 0
var _bar: ProgressBar = null
var _touch_buttons: Array = []
var _player_handles_touch: bool = false
var _starting: bool = false
func _ready() -> void:
	add_to_group("QuickTimeManager")
	if auto_detect_platform:
		platform = Platform.ANDROID if OS.has_feature("android") else Platform.PC
	_bar = get_node_or_null("EventBar") as ProgressBar
	if _bar:
		_bar.layout_direction = Control.LAYOUT_DIRECTION_LTR
		_bar.fill_mode = ProgressBar.FILL_END_TO_BEGIN
	_kb = _collect("KeyboardButton")
	_mb = _collect("MobileButton")
	for b in _kb + _mb:
		b.layout_direction = Control.LAYOUT_DIRECTION_LTR
		_base_off[b] = _get_offsets(b)
	_hide_all()
	if test_auto_start and get_tree().current_scene == self:
		_run_test()
func _collect(group: String) -> Array:
	var result: Array = []
	for n in get_tree().get_nodes_in_group(group):
		if n is TextureRect and is_ancestor_of(n):
			result.append(n)
	return result
func start(time: float = -1.0) -> void:
	if active or _starting:
		return
	var is_mobile := platform == Platform.ANDROID
	var group: Array = _mb if is_mobile else _kb
	var other: Array = _kb if is_mobile else _mb
	for b in other:
		b.visible = false
	var pool: Array = []
	var target_words: Array = ["Jump", "Spin", "Boost", "Left", "Right"]
	for b in group:
		var n := String(b.name)
		for word in target_words:
			if n.contains(word):
				pool.append(b)
				break
	if pool.is_empty():
		push_warning("QuickTimeManager: no buttons found matching targets")
		return
	pool.shuffle()
	var static_positions: Array = [-120.0, -60.0, 0.0, 60.0, 120.0]
	_seq.clear()
	for i in pool.size():
		var b: TextureRect = pool[i]
		_kill_tween(b)
		var custom_x: float = static_positions[i]
		var current_offset = _base_off[b]
		var size_w: float = current_offset.z - current_offset.x
		var half_w: float = size_w * 0.5
		var new_left: float = custom_x - half_w
		var new_right: float = custom_x + half_w
		_set_offsets(b, Vector4(new_left, current_offset.y, new_right, current_offset.w))
		b.modulate = pending_color
		b.visible = true
		_seq.append(b)
	_starting = true
	visible = true
	await get_tree().process_frame
	_starting = false
	_seq.sort_custom(func(a, b): return a.get_global_rect().get_center().x < b.get_global_rect().get_center().x)
	if debug_print:
		for b in _seq:
			print("Random QTE Position: ", b.name, " global x=", b.get_global_rect().get_center().x)
	var player := get_tree().get_first_node_in_group("Player")
	_player_handles_touch = player != null and player.has_method("_find_all_texture_buttons")
	_touch_buttons = _find_all_texture_buttons(get_tree().root) if is_mobile else []
	_index = 0
	_score = 0
	_combo = 0
	_time_total = maxf(time if time > 0.0 else time_limit, 0.01)
	_time_left = _time_total
	active = true
	visible = true
	if _bar:
		_bar.max_value = 1.0
		_bar.value = 1.0
		_bar.modulate = Color.WHITE
		_bar.visible = true
	_update_score_label()
	if not _seq.is_empty():
		_set_active_visual(_seq[0])
	started.emit(_seq.map(func(n): return str(n.name)))
func is_running() -> bool:
	return active or _starting
func cancel() -> void:
	if not active:
		return
	active = false
	_hide_all()
func get_score() -> int:
	return _score
func _process(delta: float) -> void:
	if not active:
		return
	_sync_touch_buttons()
	_poll_input()
	if not active:
		return
	_time_left -= delta / maxf(Engine.time_scale, 0.01)
	if _time_left <= 0.0:
		_time_left = 0.0
		_update_bar()
		_finish(false)
		return
	_update_bar()
func _poll_input() -> void:
	if _seq.is_empty() or _index >= _seq.size():
		return
	var act := _action_of(_seq[_index])
	if act != &"" and InputMap.has_action(act) and Input.is_action_just_pressed(act):
		_on_correct()
		return
	for i in range(_seq.size()):
		if i == _index:
			continue
		var wrong_act := _action_of(_seq[i])
		if wrong_act != &"" and InputMap.has_action(wrong_act) and Input.is_action_just_pressed(wrong_act):
			_on_wrong()
			return
func _touch_enabled() -> bool:
	return platform == Platform.ANDROID and handle_touch_buttons and not _player_handles_touch
func _find_all_texture_buttons(node: Node) -> Array:
	var result: Array = []
	if node is TextureButton:
		result.append(node)
	for child in node.get_children():
		result.append_array(_find_all_texture_buttons(child))
	return result
func _send_action(action: StringName, pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	Input.parse_input_event(ev)
func _sync_touch_buttons() -> void:
	if not _touch_enabled():
		return
	for button in _touch_buttons:
		if button.shortcut == null or button.shortcut.events.is_empty():
			continue
		for e in button.shortcut.events:
			if e is InputEventAction:
				if Input.is_action_just_pressed(e.action):
					button.button_pressed = true
				elif Input.is_action_just_released(e.action):
					button.button_pressed = false
func _input(event: InputEvent) -> void:
	if not active or not _touch_enabled():
		return
	if not (event is InputEventScreenTouch):
		return
	for button in _touch_buttons:
		if button.shortcut == null or button.shortcut.events.is_empty():
			continue
		for shortcut_event in button.shortcut.events:
			if shortcut_event is InputEventAction:
				var action: StringName = shortcut_event.action
				if button.get_global_rect().has_point(event.position):
					button.button_pressed = event.pressed
					_send_action(action, event.pressed)
				elif not event.pressed and button.button_pressed:
					_send_action(action, false)
					button.button_pressed = false
func _on_correct() -> void:
	var b: TextureRect = _seq[_index]
	_combo += 1
	var mult := 1.0
	var combo_step: float = 0.25
	var combo_max_multiplier: float = 3.0
	if use_combo:
		mult = minf(1.0 + combo_step * float(_combo - 1), combo_max_multiplier)
	_score += int(round(float(score_per_press) * mult))
	_time_left += time_bonus_per_press
	_time_total = maxf(_time_total, _time_left)
	_play(sound_correct)
	_set_done_visual(b)
	var done_index := _index
	_index += 1
	step_correct.emit(done_index, str(b.name))
	_update_score_label()
	if _index >= _seq.size():
		_finish(true)
	else:
		_set_active_visual(_seq[_index])
func _on_wrong() -> void:
	_combo = 0
	_play(sound_wrong)
	_flash_wrong(_seq[_index])
	step_wrong.emit(_index)
	_finish(false, true)
func _finish(success: bool, by_wrong: bool = false) -> void:
	if not active:
		return
	active = false
	if success:
		_score += int(round(maxf(_time_left, 0.0) * float(score_per_second_left)))
		_score += success_bonus
		var success_min_score: int = 0
		success = _score >= success_min_score
	else:
		for i in range(_index, _seq.size()):
			_flash_wrong(_seq[i])
	if success:
		_play(sound_success)
	elif not by_wrong:
		_play(sound_fail)
	_update_score_label()
	finished.emit(success, _score)
	var result_show_timer := get_tree().create_timer(result_show_time, true, false, true)
	await result_show_timer.timeout
	if not active:
		_hide_all()
func _action_of(b: Node) -> StringName:
	var n := String(b.name).to_lower()
	if n.contains("jump"): return action_jump
	if n.contains("spin"): return action_spin
	if n.contains("boost"): return action_boost
	if n.contains("left"): return action_left
	if n.contains("right"): return action_right
	return &""
func _get_offsets(b: Control) -> Vector4:
	return Vector4(b.offset_left, b.offset_top, b.offset_right, b.offset_bottom)
func _set_offsets(b: Control, v: Vector4) -> void:
	b.offset_left = v.x
	b.offset_top = v.y
	b.offset_right = v.z
	b.offset_bottom = v.w
func _update_bar() -> void:
	if _bar == null:
		return
	var ratio := clampf(_time_left / _time_total, 0.0, 1.0)
	_bar.value = ratio
	var low_time_ratio: float = 0.3
	var low_time_color: Color = Color(1, 0.45, 0.45, 1)
	_bar.modulate = low_time_color if ratio < low_time_ratio else Color.WHITE
func _update_score_label() -> void:
	if score_label != null:
		score_label.text = "SCORE %d" % _score
func _play(sound: String) -> void:
	if sound != "":
		Audio.play(sound)
func _hide_all() -> void:
	visible = false
	for b in _kb + _mb:
		_kill_tween(b)
		b.visible = false
		_set_offsets(b, _base_off[b])
		b.modulate = Color.WHITE
	if _bar:
		_bar.visible = false
func _kill_tween(b: Object) -> void:
	if _tweens.has(b) and _tweens[b] != null and _tweens[b].is_valid():
		_tweens[b].kill()
	_tweens.erase(b)
func _tween_for(b: Object) -> Tween:
	_kill_tween(b)
	var t := create_tween().set_parallel(true).set_ignore_time_scale(true)
	_tweens[b] = t
	return t
func _set_active_visual(b: TextureRect) -> void:
	var t := _tween_for(b)
	t.tween_property(b, "modulate", active_color, 0.08)
func _set_done_visual(b: TextureRect) -> void:
	var t := _tween_for(b)
	var done_color: Color = Color(0.4, 1.0, 0.4, 0.2)
	t.tween_property(b, "modulate", done_color, 0.12)
func _flash_wrong(b: TextureRect) -> void:
	var is_current: bool = _seq.size() > _index and _seq[_index] == b
	var t := _tween_for(b)
	var wrong_color: Color = Color(1, 0.25, 0.25, 1)
	b.modulate = wrong_color
	t.tween_property(b, "modulate", active_color if is_current else pending_color, 0.25)
func _run_test() -> void:
	while is_inside_tree():
		var delay_timer := get_tree().create_timer(1.0)
		await delay_timer.timeout
		start()
		var res = await finished
		print("[QTE test] success=%s score=%d" % [str(res), _score])
		var loop_timer := get_tree().create_timer(3.0)
		await loop_timer.timeout
