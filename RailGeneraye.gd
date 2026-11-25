@tool
extends Path3D
enum PresetType { LOOP, CIRCLE, SPIRAL }
@export var preset: PresetType = PresetType.CIRCLE
@export var radius: float = 10.0
@export var spiral_turns: int = 5
@export var spiral_height: float = 20.0
@export var points_per_turn: int = 24
@export var generate_preset: bool:
	set(val):
		build_preset()
func build_preset() -> void:
	var new_curve = Curve3D.new()
	match preset:
		PresetType.CIRCLE:
			create_circle(new_curve)
		PresetType.LOOP:
			create_loop(new_curve)
		PresetType.SPIRAL:
			create_spiral(new_curve)
	curve = new_curve
	update_configuration_warnings()
	if is_inside_tree() and Engine.is_editor_hint():
		var parent = get_parent()
		if parent and parent.has_method("generate_spline_collision"):
			parent.generate_spline_collision()
func create_circle(c: Curve3D) -> void:
	for i in range(points_per_turn + 1):
		var angle = (i * TAU) / points_per_turn
		var pos = Vector3(cos(angle) * radius, 0, sin(angle) * radius)
		c.add_point(pos)
func create_loop(c: Curve3D) -> void:
	for i in range(points_per_turn + 1):
		var t = float(i) / points_per_turn
		var angle = t * TAU
		var x = sin(angle) * radius
		var y = (1.0 - cos(angle)) * radius
		var z = t * (radius * 1.5)
		c.add_point(Vector3(x, y, z))
func create_spiral(c: Curve3D) -> void:
	var total_points = points_per_turn * spiral_turns
	for i in range(total_points + 1):
		var t = float(i) / total_points
		var angle = t * TAU * spiral_turns
		var x = cos(angle) * radius
		var y = t * spiral_height
		var z = sin(angle) * radius
		c.add_point(Vector3(x, y, z))
