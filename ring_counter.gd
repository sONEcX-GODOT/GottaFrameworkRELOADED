extends Label
@export var prefix_text: String = ""
func _ready() -> void:
	RingCount.rings_changed.connect(_update_text)
	_update_text(RingCount.rings)
func _update_text(count: int) -> void:
	text = prefix_text + str(count).pad_zeros(4)
