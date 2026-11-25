extends Area3D
class_name Ring
@export var rotation_speed: float = 2.0
@export var base_magnet_speed: float = 2.0
@export var max_magnet_speed: float = 60.0
@export var magnet_acceleration: float = 45.0
@export var attraction_radius: float = 6.0
var target_player: Node3D = null
var is_collected: bool = false
var current_magnet_speed: float = 0.0
func _ready() -> void:
	if is_in_group("LsdRings"):
		return
	var magnet_area = Area3D.new()
	var collision_shape = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = attraction_radius
	collision_shape.shape = sphere
	magnet_area.add_child(collision_shape)
	add_child(magnet_area)
	magnet_area.body_entered.connect(_on_magnet_body_entered)
func _process(delta: float) -> void:
	rotate_y(rotation_speed * delta)
	if target_player and not is_collected:
		current_magnet_speed = move_toward(current_magnet_speed, max_magnet_speed, magnet_acceleration * delta)
		global_position = global_position.move_toward(target_player.global_position + Vector3.UP * 0.5, current_magnet_speed * delta)
func _on_magnet_body_entered(body: Node) -> void:
	if target_player != null:
		return
	if body.has_method("add_ring") and not is_collected:
		target_player = body
		current_magnet_speed = base_magnet_speed
func _on_body_entered(body: Node) -> void:
	if body.has_method("add_ring") and not is_collected:
		is_collected = true
		Audio.play("ring")
		body.add_ring()
		$MeshInstance3D.visible = false 
		$GPUParticles3D.emitting = true
		$CollisionShape3D.set_deferred("disabled", true)
		await get_tree().create_timer(0.5).timeout
		queue_free()
