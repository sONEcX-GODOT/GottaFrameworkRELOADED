extends Node

signal rings_changed(new_count: int)

var rings: int = 0
var level_time: float = 0.0
var is_active: bool = true

func _process(delta: float) -> void:
	if is_active:
		level_time += delta
func add_rings(amount: int = 1) -> void:
	print("add_rings: ", amount)
	print_stack()
	if not GameManager.is_active:
		return
	rings += amount
	GameManager.add_rings(amount)
	rings_changed.emit(rings)
func lose_rings() -> void:
	rings = 0
	rings_changed.emit(rings)

func reset() -> void:
	rings = 0
	is_active = true
	rings_changed.emit(rings)
