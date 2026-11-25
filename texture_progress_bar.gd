extends TextureProgressBar

var max_boost_energy: float = 100.0
var boost_energy: float = 100.0
var is_boosting: bool = false

func _physics_process(delta: float) -> void:
	max_value = max_boost_energy
	value = boost_energy
