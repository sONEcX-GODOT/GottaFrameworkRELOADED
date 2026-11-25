@tool
class_name TrackPiece
extends Path3D
## Кусок трассы: кривая (Path3D) + CSGPolygon3D "Surface" (профиль вдоль пути).
## Ничего не мешает добавлять CSGBox3D/CSGSphere3D с Operation=Subtraction
## ВНУТРЬ узла Surface - это вырезает дыры/пропасти.
## Для мобилок: Bake -> статичный меш + trimesh-коллизия, CSG удаляется в рантайме.

signal rebuilt

enum Shape { STRAIGHT, CURVE, S_CURVE, LOOP, RAMP, CUSTOM }
enum Profile { ROAD, CURBED, HALFPIPE, TUBE, RAIL }

@export var shape: Shape = Shape.STRAIGHT:
	set(v):
		shape = v
		_queue()
@export var profile: Profile = Profile.ROAD:
	set(v):
		profile = v
		_queue()
@export_group("Size")
@export var width := 10.0:
	set(v):
		width = v
		_queue()
@export var thickness := 0.8:
	set(v):
		thickness = v
		_queue()
@export var length := 40.0:
	set(v):
		length = v
		_queue()
@export var radius := 20.0:
	set(v):
		radius = v
		_queue()
## CURVE: градусы (+ влево, - вправо, до 720 = спираль)
@export var angle := 90.0:
	set(v):
		angle = v
		_queue()
@export var height := 0.0:
	set(v):
		height = v
		_queue()
## S_CURVE: боковой сдвиг. LOOP: шаг в сторону, чтобы петля не пересекала себя
@export var offset := 10.0:
	set(v):
		offset = v
		_queue()
## Крен на повороте (градусы). Если наклон в обратную сторону - поменяй знак.
@export var bank := 0.0:
	set(v):
		bank = v
		_queue()
@export_group("Look & perf")
@export var color_a := Color(0.1, 0.35, 0.95):
	set(v):
		color_a = v
		_queue()
@export var color_b := Color(0.95, 0.85, 0.25):
	set(v):
		color_b = v
		_queue()
## Свой материал (StandardMaterial3D, ShaderMaterial и т.д.). Пусто = встроенная шахматка.
@export var custom_material: Material:
	set(v):
		custom_material = v
		_queue()
## Длина повтора текстуры вдоль пути (UV.y), в метрах
@export var uv_distance := 4.0:
	set(v):
		uv_distance = maxf(v, 0.1)
		_queue()
@export var tiles := 4.0:
	set(v):
		tiles = v
		_queue()
## Шаг сегментов CSG (больше = легче)
@export var interval := 2.5:
	set(v):
		interval = v
		_queue()
@export var solid_collision := true
@export_group("Player integration")
## Пол попадает в группу AutoZone (авто-руление твоего SonicPlayer)
@export var autozone := true
## Любые другие группы для коллизии (например LoopRail, jump_wall, Hit)
@export var extra_groups: PackedStringArray = []
@export var collision_bits := 1
## Сцена рельса (Area3D со свойством path_3d). Ему подставится этот Path3D.
@export var rail_scene: PackedScene:
	set(v):
		rail_scene = v
		_queue()
@export_tool_button("Rebuild") var _b1 = rebuild
@export_tool_button("Bake (mobile)") var _b2 = bake
@export_tool_button("Unbake") var _b3 = unbake

static var _shader: Shader
const SHADER := """
shader_type spatial;
render_mode specular_disabled;
uniform vec4 color_a : source_color;
uniform vec4 color_b : source_color;
uniform float tiles = 4.0;
void fragment() {
	float c = mod(floor(UV.x * tiles) + floor(UV.y * tiles), 2.0);
	ALBEDO = mix(color_a.rgb, color_b.rgb, c);
	ROUGHNESS = 1.0;
}
"""

var _pending := false

func _ready() -> void:
	add_to_group("track")
	rebuild()

func _queue() -> void:
	if _pending or not is_inside_tree():
		return
	_pending = true
	rebuild.call_deferred()

func has_baked() -> bool:
	return has_node("Baked")

func rebuild() -> void:
	_pending = false
	if not is_inside_tree():
		return
	if curve == null:
		curve = Curve3D.new()
	_generate()
	_sync_rail()
	if has_baked() and not Engine.is_editor_hint():
		var old := get_node_or_null("Surface")
		if old: old.queue_free()
		rebuilt.emit()
		return
	var s := _surface()
	s.mode = CSGPolygon3D.MODE_PATH
	s.polygon = _profile()
	s.path_node = ^".."
	s.path_interval_type = CSGPolygon3D.PATH_INTERVAL_DISTANCE
	s.path_interval = interval
	s.path_rotation = CSGPolygon3D.PATH_ROTATION_PATH_FOLLOW
	s.path_local = true
	s.path_continuous_u = true
	s.path_u_distance = uv_distance
	s.smooth_faces = profile == Profile.HALFPIPE or profile == Profile.TUBE
	s.material = custom_material if custom_material else _make_material()
	s.use_collision = solid_collision and not has_baked()
	s.collision_layer = collision_bits
	_apply_groups(s)
	s.visible = not has_baked()
	rebuilt.emit()

func _surface() -> CSGPolygon3D:
	var s := get_node_or_null("Surface") as CSGPolygon3D
	if s == null:
		s = CSGPolygon3D.new()
		s.name = "Surface"
		add_child(s)
		if Engine.is_editor_hint():
			s.owner = get_tree().edited_scene_root
	return s

func _make_material() -> ShaderMaterial:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER
	var m := ShaderMaterial.new()
	m.shader = _shader
	m.set_shader_parameter("color_a", color_a)
	m.set_shader_parameter("color_b", color_b)
	m.set_shader_parameter("tiles", tiles)
	return m

# ---------------------------------------------------------------- curve
func _generate() -> void:
	var pts: Array[Vector3] = []
	var tilts: Array[float] = []
	match shape:
		Shape.CUSTOM:
			return
		Shape.STRAIGHT:
			var n := maxi(2, int(length / 20.0) + 1)
			for i in n:
				var t := float(i) / (n - 1)
				pts.append(Vector3(0, height * t, -length * t))
				tilts.append(0.0)
		Shape.CURVE:
			var n := maxi(3, int(absf(angle) / 15.0) + 1)
			var sgn := 1.0 if angle >= 0.0 else -1.0
			for i in n:
				var t := float(i) / (n - 1)
				var a := deg_to_rad(absf(angle)) * t
				pts.append(Vector3(sgn * radius * (cos(a) - 1.0), height * t, -radius * sin(a)))
				tilts.append(deg_to_rad(bank) * sgn * sin(PI * t))
		Shape.S_CURVE:
			for i in 11:
				var t := i / 10.0
				var s := t * t * (3.0 - 2.0 * t)
				pts.append(Vector3(offset * s, height * t, -length * t))
				tilts.append(0.0)
		Shape.LOOP:
			for i in 25:
				var t := i / 24.0
				var a := TAU * t
				pts.append(Vector3(offset * t, radius * (1.0 - cos(a)), -radius * sin(a)))
				tilts.append(0.0)
		Shape.RAMP:
			for i in 9:
				var t := i / 8.0
				pts.append(Vector3(0, height * t * t, -length * t))
				tilts.append(0.0)
	_apply(pts, tilts)

func _apply(pts: Array[Vector3], tilts: Array[float]) -> void:
	curve.clear_points()
	curve.bake_interval = 1.0
	curve.up_vector_enabled = true
	var n := pts.size()
	for i in n:
		var a := pts[maxi(i - 1, 0)]
		var b := pts[mini(i + 1, n - 1)]
		var k := 3.0 if (i == 0 or i == n - 1) else 6.0
		var h := (b - a) / k
		curve.add_point(pts[i], -h, h)
		curve.set_point_tilt(i, tilts[i])

func get_end_transform() -> Transform3D:
	var l := curve.get_baked_length()
	var p := curve.sample_baked(l, true)
	var p0 := curve.sample_baked(maxf(l - 0.5, 0.0), true)
	var z := -(p - p0).normalized()
	var up := curve.sample_baked_up_vector(l, true)
	var x := up.cross(z).normalized()
	var y := z.cross(x)
	return global_transform * Transform3D(Basis(x, y, z), p)

# -------------------------------------------------------------- profile
func _profile() -> PackedVector2Array:
	var w := width * 0.5
	var t := thickness
	var p := PackedVector2Array()
	match profile:
		Profile.ROAD:
			p = PackedVector2Array([Vector2(-w, 0), Vector2(w, 0), Vector2(w, -t), Vector2(-w, -t)])
		Profile.CURBED:
			var c := 0.4
			var ch := 0.9
			p = PackedVector2Array([
				Vector2(-w - c, -t), Vector2(w + c, -t), Vector2(w + c, ch), Vector2(w, ch),
				Vector2(w, 0), Vector2(-w, 0), Vector2(-w, ch), Vector2(-w - c, ch)])
		Profile.HALFPIPE:
			var d := width * 0.3
			var top: Array[Vector2] = []
			for i in 11:
				var a := PI * i / 10.0
				top.append(Vector2(-cos(a) * w, d * (1.0 - sin(a))))
			for v in top:
				p.append(v)
			for i in range(top.size() - 1, -1, -1):
				p.append(Vector2(top[i].x, top[i].y - t))
		Profile.TUBE:
			var outer: Array[Vector2] = []
			var inner: Array[Vector2] = []
			for i in 17:
				var a := lerpf(PI - 0.35, TAU + 0.35, i / 16.0)
				outer.append(Vector2(cos(a) * (w + t), sin(a) * (w + t) + w))
				inner.append(Vector2(cos(a) * w, sin(a) * w + w))
			for v in outer:
				p.append(v)
			for i in range(inner.size() - 1, -1, -1):
				p.append(inner[i])
		Profile.RAIL:
			p = PackedVector2Array([Vector2(-0.35, 0), Vector2(0.35, 0), Vector2(0.35, -0.5), Vector2(-0.35, -0.5)])
	return p

# ---------------------------------------------------- player integration
func _apply_groups(n: Node) -> void:
	if autozone:
		n.add_to_group(&"AutoZone")
	for g in extra_groups:
		n.add_to_group(StringName(g))

func _sync_rail() -> void:
	var old := get_node_or_null("RailArea")
	if rail_scene == null:
		if old:
			remove_child(old)
			old.queue_free()
		return
	if old:
		return
	var r := rail_scene.instantiate()
	r.name = "RailArea"
	add_child(r)
	if Engine.is_editor_hint():
		r.owner = get_tree().edited_scene_root
	for pr in r.get_property_list():
		if pr.name == "path_3d":
			if pr.type == TYPE_NODE_PATH:
				r.set("path_3d", r.get_path_to(self))
			else:
				r.set("path_3d", self)

# ----------------------------------------------------------------- bake
func bake() -> void:
	unbake(false)
	rebuild()
	await get_tree().process_frame
	await get_tree().process_frame
	var s := _surface()
	var r := s.get_meshes()
	if r.size() < 2 or r[1] == null:
		push_warning("TrackPiece: nothing to bake")
		return
	var mesh: Mesh = (r[1] as Mesh).duplicate()
	var mi := MeshInstance3D.new()
	mi.name = "Baked"
	mi.mesh = mesh
	var body := StaticBody3D.new()
	body.name = "Body"
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	cs.shape = mesh.create_trimesh_shape()
	body.collision_layer = collision_bits
	_apply_groups(body)
	add_child(mi)
	mi.add_child(body)
	body.add_child(cs)
	if Engine.is_editor_hint():
		var root := get_tree().edited_scene_root
		mi.owner = root
		body.owner = root
		cs.owner = root
	s.use_collision = false
	s.visible = false
	if not Engine.is_editor_hint():
		s.queue_free()

func unbake(do_rebuild := true) -> void:
	var b := get_node_or_null("Baked")
	if b:
		remove_child(b)
		b.queue_free()
	if do_rebuild:
		rebuild()
