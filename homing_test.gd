class_name Base_Object
extends Area3D
enum mode {Ballon, DashPad, DashRamp, DashRing, Spring, FakeSpring, Badnik, JumpSelector}
@export_group("Base")
@export var Destroy:bool = false
@export var Homing:bool = false
@export var Current_mode = mode.Ballon
@onready var effect = get_node_or_null("effect/AnimationPlayer")

func _ready():
	if Homing == true:
		add_to_group("enemies")
func destroy():
	if Destroy == true and Current_mode == mode.Ballon:
		$"scene 24".visible = false
		Audio.play("ballon")
		GameManager.score += 50
		$CollisionShape3D.disabled = true
		if is_instance_valid(effect):
			effect.play("Main")
