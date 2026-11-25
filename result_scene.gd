extends CanvasLayer
@onready var rank_label: Label = $RankLabel
@onready var time_label: Label = $TimeLabel
@onready var score_label: Label = $ScoreLabel
@onready var ring_label: Label = $RingLabel
@onready var total_label: Label = $TotalLabel
@onready var s: TextureRect = $S
@onready var a: TextureRect = $A
@onready var b: TextureRect = $B
@onready var c: TextureRect = $C
@onready var d: TextureRect = $D
@onready var e: TextureRect = $E
@onready var title_label: Label = get_node_or_null("TitleLabel") as Label
@onready var anim: AnimationPlayer = $"../Sonic_root/SonicRoot/AnimationPlayer"
var tween: Tween
var is_finished: bool = false
var results: Dictionary
func _ready() -> void:
	if GameManager.stage:
		GameManager.stage.finish_stage()
		if title_label:
			title_label.text = GameManager.stage.get_display_name()
	Audio.play("result")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var ranks = [s, a, b, c, d, e]
	for r in ranks:
		r.visible = false
		r.modulate.a = 0.0
	score_label.text = ""
	time_label.text = ""
	ring_label.text = ""
	total_label.text = ""
	rank_label.text = ""
	anim.play("look")
	results = GameManager.get_final_results()
	start_counting_animation()
func start_counting_animation() -> void:
	tween = create_tween().set_parallel(false)
	var base = results["base_score"]
	var t_bonus = results["time_bonus"]
	var rings_collected = results["rings_count"]
	var f_score = results["final_score"]
	tween.tween_method(func(v): score_label.text = "Score: " + str(v), 0, base, 0.4)
	tween.tween_interval(0.2)
	tween.tween_method(func(v): time_label.text = "TIME BONUS: " + str(v), 0, t_bonus, 0.4)
	tween.tween_interval(0.2)
	tween.tween_method(func(v): ring_label.text = "Rings: " + str(v), 0, rings_collected, 0.4)
	tween.tween_interval(0.2)
	tween.tween_method(func(v): total_label.text = "TOTAL: " + str(v), 0, f_score, 0.4)
	var stream = Audio.loaded_sounds.get("result")
	if stream:
		var total_tween_time = 0.4 + 0.2 + 0.4 + 0.2 + 0.4 + 0.2 + 0.4
		var remaining_time = max(0.0, (stream.get_length() - 1.0) - total_tween_time)
		if remaining_time > 0.0:
			tween.tween_interval(remaining_time)
	tween.tween_callback(show_final_rank)
func show_final_rank() -> void:
	is_finished = true
	rank_label.text = "RANK"
	var rank: String = results["rank"]
	var active_rect: TextureRect
	match rank:
		"S": active_rect = s
		"A": active_rect = a
		"B": active_rect = b
		"C": active_rect = c
		"D": active_rect = d
		"E": active_rect = e
	if active_rect:
		active_rect.visible = true
		var fade_tween = create_tween()
		fade_tween.tween_property(active_rect, "modulate:a", 1.0, 0.5)
	anim.play(rank, 0.5)
	Audio.play(rank)
	Audio.play("total")
func skip_animation() -> void:
	if tween and tween.is_valid():
		tween.kill()
	score_label.text = "Score: " + str(results["base_score"])
	time_label.text = "BONUS: " + str(results["time_bonus"])
	ring_label.text = "Rings: " + str(results["rings_count"])
	total_label.text = "TOTAL: " + str(results["final_score"])
	show_final_rank()
func _input(event: InputEvent) -> void:
	var is_action = event.is_action_pressed("ui_accept")
	var is_click = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if is_action or is_click:
		if not is_finished:
			skip_animation()
			Audio.stop("result")
		else:
			if has_node("/root/RingCount"):
				get_node("/root/RingCount").lose_rings()
				get_node("/root/RingCount").is_active = true
			GameManager.reset_run()
