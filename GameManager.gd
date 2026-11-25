extends Node

const TIME_BONUS_MAX: int = 100000
const TIME_BONUS_LOSS_PER_SEC: int = 1000

var rings: int = 0
var total_rings: int = 0   
var level_time: float = 0.0
var score: float = 0.0
var is_active: bool = true
var count_time: bool = true
var deaths: int = 0
var defeated_enemies: int = 0
var tricks_performed: int = 0
var current_level_name: String = "level_1"
var run_in_progress: bool = false
var respawning: bool = false  
var stage: StageData = null

func _process(delta: float) -> void:
	
	if is_active and count_time and stage != null and not stage.finished:
		level_time += delta

func begin_stage(level_id: String) -> void:
	if respawning and run_in_progress and current_level_name == level_id:
	
		reset_attempt()
	else:

		reset_run()
	respawning = false
	current_level_name = level_id
	run_in_progress = true
	is_active = true

func add_rings(amount: int) -> void:
	if is_active:
		rings += amount
		total_rings += amount

func lose_rings() -> void:
	rings = 0

func add_enemy_score(amount: int = 500) -> void:
	if is_active:
		score += amount
		defeated_enemies += 1

func add_trick_score(tier: int) -> void:
	if is_active:
		score += tier * 1000
		tricks_performed += 1

func register_death() -> void:
	deaths += 1
	respawning = true

func reset_attempt() -> void:
	rings = 0
	total_rings = 0
	level_time = 0.0
	score = 0.0
	defeated_enemies = 0
	tricks_performed = 0
	is_active = true
	if has_node("/root/RingCount"):
		get_node("/root/RingCount").reset()

func reset_run() -> void:
	reset_attempt()
	deaths = 0
	respawning = false
	run_in_progress = false

func get_final_results() -> Dictionary:
	is_active = false
	run_in_progress = false
	if stage:
		stage.finish_stage()

	var target_time: float = stage.s_rank_time if stage else 60.0
	var time_bonus: int = TIME_BONUS_MAX
	if level_time > target_time:
		var extra_time: float = level_time - target_time
		time_bonus = max(0, TIME_BONUS_MAX - int(extra_time) * TIME_BONUS_LOSS_PER_SEC)

	var actual_rings: int = total_rings
	var ring_bonus: int = actual_rings * 100

	if score == 0 and actual_rings == 0:
		time_bonus = 0

	var enemy_bonus: int = defeated_enemies * 20
	var trick_bonus: int = tricks_performed * 50
	var final_score: float = score + time_bonus + ring_bonus + enemy_bonus + trick_bonus

	var rank: String = "E"
	if final_score >= 150000:
		rank = "S"
	elif final_score >= 100000:
		rank = "A"
	elif final_score >= 70000:
		rank = "B"
	elif final_score >= 40000:
		rank = "C"
	elif final_score >= 10000:
		rank = "D"

	return {
		"base_score": int(score),
		"time_bonus": time_bonus,
		"ring_bonus": ring_bonus,
		"enemy_bonus": enemy_bonus,
		"trick_bonus": trick_bonus,
		"final_score": int(final_score),
		"rank": rank,
		"rings_count": actual_rings,
		"deaths": deaths,
		"time": level_time
	}
