extends Node3D
class_name StageData

signal stage_started
signal stage_finished
signal time_over

enum StageStyle { ACTION_STAGE, BOSS, HUB }

@export_group("Stage")
@export var stage_zone_name: String = "New Level"
@export var stage_act_name: String = "Act 1"
@export var style: StageStyle = StageStyle.ACTION_STAGE
@export var stage_unique_id: String = "level_1"
@export var stage_music: AudioStream

@export_group("Time")
@export var count_time: bool = true
@export var max_time: float = -1.0

@export_group("Rank")
@export var s_rank_time: float = 120.0
@export var s_rank_rings: int = 50
@export var rank_weight_time: float = 1.0
@export var rank_weight_rings: float = 0.0
@export var rank_weight_death: float = 0.2
@export_range(0.0, 1.0) var threshold_s: float = 0.9
@export_range(0.0, 1.0) var threshold_a: float = 0.75
@export_range(0.0, 1.0) var threshold_b: float = 0.55
@export_range(0.0, 1.0) var threshold_c: float = 0.35
@export_range(0.0, 1.0) var threshold_d: float = 0.15

@export_group("Culling")
@export var enemy_culling: bool = false
@export var enemy_cull_distance: float = 200.0
@export var enemy_culled_visibility: bool = false

var finished: bool = false
var _time_over_sent: bool = false
var _music_player: AudioStreamPlayer
var _cull_timer: float = 0.0

func _ready() -> void:
	add_to_group("StageData")
	GameManager.stage = self
	GameManager.begin_stage(stage_unique_id)   
	GameManager.count_time = count_time
	if stage_music:
		_music_player = AudioStreamPlayer.new()
		_music_player.stream = stage_music
		add_child(_music_player)
		_music_player.play()
	stage_started.emit()

func _exit_tree() -> void:
	if GameManager.stage == self:
		GameManager.stage = null

func _process(delta: float) -> void:
	if finished:
		return
	if max_time > 0.0 and not _time_over_sent and GameManager.level_time >= max_time:
		_time_over_sent = true
		time_over.emit()
	if enemy_culling:
		_cull_timer -= delta
		if _cull_timer <= 0.0:
			_cull_timer = 0.25
			_cull_enemies()

func finish_stage() -> void:
	if finished:
		return
	finished = true
	stop_music()
	stage_finished.emit()

func stop_music() -> void:
	if _music_player:
		_music_player.stop()

func get_display_name() -> String:
	return "%s %s" % [stage_zone_name, stage_act_name]

func calculate_rank(time: float, rings: int, deaths: int) -> String:
	var time_score: float = 1.0 if time <= s_rank_time else clampf(s_rank_time / maxf(time, 0.001), 0.0, 1.0)
	var rings_score: float = clampf(float(rings) / float(maxi(s_rank_rings, 1)), 0.0, 1.0)
	var death_score: float = 1.0 / (1.0 + deaths)
	var total_w: float = rank_weight_time + rank_weight_rings + rank_weight_death
	if total_w <= 0.0:
		return "S"
	var score: float = (time_score * rank_weight_time + rings_score * rank_weight_rings + death_score * rank_weight_death) / total_w
	if score >= threshold_s:
		return "S"
	if score >= threshold_a:
		return "A"
	if score >= threshold_b:
		return "B"
	if score >= threshold_c:
		return "C"
	if score >= threshold_d:
		return "D"
	return "E"

func _cull_enemies() -> void:
	var player := get_tree().get_first_node_in_group("Player") as Node3D
	if player == null:
		return
	for e in get_tree().get_nodes_in_group("enemies"):
		var n := e as Node3D
		if n == null or not is_instance_valid(n):
			continue
		var far: bool = n.global_position.distance_to(player.global_position) > enemy_cull_distance
		n.process_mode = Node.PROCESS_MODE_DISABLED if far else Node.PROCESS_MODE_INHERIT
		n.visible = enemy_culled_visibility or not far
