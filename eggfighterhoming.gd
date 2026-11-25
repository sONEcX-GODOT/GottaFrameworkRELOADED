extends Base_Object
class_name HomingEggFighter
@onready var effect_sprite: AnimatedSprite3D = find_child("AnimatedSprite3D", true, false)
func _ready() -> void:
	if effect_sprite:
		effect_sprite.visible = false
	body_entered.connect(_on_body_entered)
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		if body.current_state == body.State.JUMP or body.current_state == body.State.STOMP:
			monitoring = false
			monitorable = false
			if effect_sprite and effect_sprite.sprite_frames.has_animation("default"):
				effect_sprite.visible = true
				effect_sprite.play("default")
				await effect_sprite.animation_finished
			queue_free()
		elif body.current_state == body.State.GROUND:
			if body.has_method("_on_hit"):
				body._on_hit()
