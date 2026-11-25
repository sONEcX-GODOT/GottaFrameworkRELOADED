extends Base_Object
class_name Badnik
@onready var score = $CanvasLayer/TextureRect
@onready var player = get_tree().get_first_node_in_group("Player")
var is_dead: bool = false
func _physics_process(delta: float) -> void:
	if is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= 5 and player.current_state == player.State.JUMP:
			die()
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		if body.current_state == body.State.GROUND:
			body._on_hit()
		if body.current_state == body.State.JUMP or body.current_state == body.State.STOMP:
			die()
func on_homing_hit(player_node = null) -> void:
	die()
func die():
	if is_dead:
		return
	is_dead = true
	set_physics_process(false)
	$CollisionShape3D.set_deferred("disabled", true)
	if has_method("set_monitoring"):
		set_deferred("monitoring", false)
		set_deferred("monitorable", false)
	GameManager.add_enemy_score(500)
	Audio.play("exp")
	for part in [$Blades, $Body, $Bottom, $Eyes, $Waist]:
		if part:
			part.visible = false
	spawn_explosion()
	spawn_scattered_scores()
	queue_free()
func spawn_explosion():
	var anim = $AnimatedSprite3D
	if not anim:
		return
	var pos = anim.global_position
	remove_child(anim)
	get_tree().current_scene.add_child(anim)
	anim.global_position = pos
	anim.visible = true
	anim.modulate.a = 1.0
	anim.stop()
	anim.frame = 0
	anim.play("default")
	var tween = anim.create_tween()
	tween.tween_property(anim, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	anim.animation_finished.connect(anim.queue_free)
func spawn_scattered_scores():
	var camera = get_viewport().get_camera_3d()
	if not camera or not score:
		return
	var root_canvas = get_tree().root.get_node_or_null("CanvasLayer")
	var target_parent = root_canvas if root_canvas else get_tree().root
	var start_screen_pos = camera.unproject_position(global_position)
	var hud_score_node = get_tree().get_first_node_in_group("Score") as Control
	var target_pos = hud_score_node.global_position if hud_score_node else Vector2(20, 20)
	for i in range(5):
		var score_clone = score.duplicate() as Control
		target_parent.add_child(score_clone)
		score_clone.visible = true
		score_clone.scale = Vector2.ZERO
		score_clone.global_position = start_screen_pos
		animate_score_lifecycle(score_clone, start_screen_pos, target_pos)
func animate_score_lifecycle(score_node: Control, start_pos: Vector2, target_pos: Vector2):
	var random_offset = Vector2(randf_range(-100, 100), randf_range(-100, 100))
	var scatter_pos = start_pos + random_offset
	var tween = score_node.create_tween()
	var pop_tween = tween.set_parallel(true)
	pop_tween.tween_property(score_node, "scale", Vector2(2.0, 2.0), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop_tween.tween_property(score_node, "global_position", scatter_pos, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.chain().tween_interval(0.3 + randf_range(0.1, 0.3))
	var fly_tween = tween.chain().set_parallel(true)
	fly_tween.tween_property(score_node, "global_position", target_pos, 1.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	fly_tween.tween_property(score_node, "scale", Vector2(1.0, 1.0), 1.2).set_trans(Tween.TRANS_SINE)
	var fade_tween = tween.chain().set_parallel(true)
	fade_tween.tween_property(score_node, "scale", Vector2.ZERO, 0.25).set_trans(Tween.TRANS_SINE)
	fade_tween.tween_property(score_node, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_SINE)
	tween.chain().tween_callback(score_node.queue_free)
