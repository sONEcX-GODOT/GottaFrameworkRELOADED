extends Area3D
class_name SkydiveZone

func _ready() -> void:
	monitoring = true
	body_entered.connect(_on_zone_body_entered)
	body_exited.connect(_on_zone_body_exited)

func _on_zone_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player") and body.has_method("enter_skydive_zone"):
		body.enter_skydive_zone(self)

func _on_zone_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player") and body.has_method("exit_skydive_zone"):
		body.exit_skydive_zone(self)
