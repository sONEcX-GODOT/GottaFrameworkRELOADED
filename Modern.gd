extends TextureRect
enum mode_G {Werehog, Sonic}
@export var mode_C = mode_G.Sonic
func _ready():
	visible = mode_C == mode_G.Sonic
