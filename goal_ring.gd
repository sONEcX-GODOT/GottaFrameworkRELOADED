extends Area3D
class_name GoalRing
var results_scene_path: String = "res://Levels/ResultsScene.tscn"
@onready var anim = get_tree().get_first_node_in_group("Goal")
func _ready() -> void:
	body_entered.connect(_on_body_entered)
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player") or body.name == "Player":
		set_deferred("monitoring", false)
		Audio.play("goal")
		anim.play("main")
		if GameManager.stage:
			GameManager.stage.finish_stage()
		if body.has_method("set_physics_process"):
			body.set_physics_process(false)
		await get_tree().create_timer(1.5).timeout
		get_tree().call_deferred("change_scene_to_file", results_scene_path)
