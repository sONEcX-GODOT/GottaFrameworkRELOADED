extends MeshInstance3D
@export var base_marker: Marker3D
@export var tip_marker: Marker3D
@export var lifetime: float = 0.18
@export var emit: bool = true
var points: Array = []
func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
func _process(delta: float) -> void:
	var i = points.size() - 1
	while i >= 0:
		points[i][2] += delta
		if points[i][2] >= lifetime:
			points.remove_at(i)
		i -= 1
	if emit and base_marker and tip_marker:
		points.insert(0, [
			base_marker.global_position,
			tip_marker.global_position,
			0.0
		])
	_render_trail()
func _render_trail() -> void:
	var im_mesh := mesh as ImmediateMesh
	if not im_mesh:
		return
	im_mesh.clear_surfaces()
	if points.size() < 2:
		return
	im_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for p in points:
		var progress: float = clamp(p[2] / lifetime, 0.0, 1.0)
		im_mesh.surface_set_uv(Vector2(progress, 0.0))
		im_mesh.surface_add_vertex(p[0])
		im_mesh.surface_set_uv(Vector2(progress, 1.0))
		im_mesh.surface_add_vertex(p[1])
	im_mesh.surface_end()
