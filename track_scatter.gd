@tool
class_name TrackScatter
extends MultiMeshInstance3D
## Расстановка вдоль родительского TrackPiece.
## RING  - кольца одним MultiMesh (если scene пуст), иначе - твоя сцена кольца (Area3D, LsdRings и т.д.); при сборе зовётся player.add_ring() (группа "Player").
## SCENE - инстансы ТВОЕЙ сцены (Spring, DashRamp, враг, JumpSelector, ...) по кривой.

enum Kind { RING, SCENE }
enum Pattern { LINE, ZIGZAG, ARC }

@export var kind: Kind = Kind.RING:
	set(v):
		kind = v
		_queue()
@export var scene: PackedScene:
	set(v):
		scene = v
		_queue()
@export var pattern: Pattern = Pattern.LINE:
	set(v):
		pattern = v
		_queue()
@export var count := 20:
	set(v):
		count = maxi(v, 1)
		_queue()
@export_range(0.0, 1.0) var start_t := 0.1:
	set(v):
		start_t = v
		_queue()
@export_range(0.0, 1.0) var end_t := 0.9:
	set(v):
		end_t = v
		_queue()
@export var lateral := 0.0:
	set(v):
		lateral = v
		_queue()
@export var lift := 1.0:
	set(v):
		lift = v
		_queue()
@export var amplitude := 2.0:
	set(v):
		amplitude = v
		_queue()
## SCENE: довернуть объект вокруг Y (180 если модель смотрит в +Z)
@export var yaw_deg := 0.0:
	set(v):
		yaw_deg = v
		_queue()
## Множитель размера объектов (масштаб родителя компенсируется автоматически)
@export var item_scale := 1.0:
	set(v):
		item_scale = v
		_queue()
@export var collect_radius := 2.0
@export var ring_color := Color(1.0, 0.85, 0.1):
	set(v):
		ring_color = v
		_queue()

var _pos: Array[Vector3] = []
var _alive: Array[bool] = []
var _dirty := false
var _player: Node3D
var _last_scale := Vector3.ONE

func _ready() -> void:
	set_notify_transform(true)
	var tp := get_parent() as TrackPiece
	if tp:
		tp.rebuilt.connect(_queue)
	place()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		if not global_transform.basis.get_scale().is_equal_approx(_last_scale):
			_queue()

func _queue() -> void:
	if _dirty or not is_inside_tree():
		return
	_dirty = true
	place.call_deferred()

func place() -> void:
	_dirty = false
	var tp := get_parent() as Path3D
	if tp == null or tp.curve == null:
		return
	var c := tp.curve
	var l := c.get_baked_length()
	if l < 0.1:
		return
	if not c.changed.is_connected(_queue):
		c.changed.connect(_queue)
	_clear_scene_children()
	_pos.clear(); _alive.clear()
	var mm: MultiMesh = null
	if kind == Kind.RING and scene == null:
		mm = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = _ring_mesh()
		mm.instance_count = count
	var gs := global_transform.basis.get_scale()
	_last_scale = gs
	var inv := Basis.from_scale(Vector3(
		item_scale / maxf(gs.x, 0.0001), item_scale / maxf(gs.y, 0.0001), item_scale / maxf(gs.z, 0.0001)))
	var ring_rot := Basis(Vector3.RIGHT, PI * 0.5)
	var yaw := Basis(Vector3.UP, deg_to_rad(yaw_deg))
	for i in count:
		var f := 0.5 if count == 1 else float(i) / (count - 1)
		var off := lerpf(start_t, end_t, f) * l
		var p := c.sample_baked(off, true)
		var p1 := c.sample_baked(clampf(off - 0.3, 0.0, l), true)
		var p2 := c.sample_baked(clampf(off + 0.3, 0.0, l), true)
		var fwd := (p2 - p1).normalized()
		var right := fwd.cross(c.sample_baked_up_vector(off, true)).normalized()
		var up := right.cross(fwd)
		var lat := lateral
		var ly := lift
		match pattern:
			Pattern.ZIGZAG: lat += amplitude * (1.0 if i % 2 == 0 else -1.0)
			Pattern.ARC: ly += amplitude * sin(PI * f)
		var pos := p + right * lat + up * ly
		var b := Basis(right, up, -fwd)
		if mm != null:
			mm.set_instance_transform(i, Transform3D(inv * b * ring_rot, pos))
			_pos.append(pos); _alive.append(true)
		elif scene:
			var inst := scene.instantiate()
			inst.set_meta(&"sb_scatter", true)
			add_child(inst, false, Node.INTERNAL_MODE_BACK)
			if inst is Node3D:
				inst.transform = Transform3D(inv * b * yaw, pos)
	multimesh = mm

func _clear_scene_children() -> void:
	for ch in get_children(true):
		if ch.has_meta(&"sb_scatter"):
			remove_child(ch)
			ch.queue_free()

func _ring_mesh() -> Mesh:
	var t := TorusMesh.new()
	t.inner_radius = 0.3; t.outer_radius = 0.6
	t.rings = 12; t.ring_segments = 5
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = ring_color
	t.material = m
	return t

func _physics_process(_d: float) -> void:
	if Engine.is_editor_hint() or kind != Kind.RING or _pos.is_empty():
		return
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("Player") as Node3D
		if _player == null:
			return
	var n := check(_player.global_position, collect_radius)
	for i in n:
		if _player.has_method("add_ring"):
			_player.call("add_ring")

## Сколько колец собрано вокруг точки (мировые координаты); собранные скрываются.
func check(world_pos: Vector3, r: float) -> int:
	var lp := to_local(world_pos)
	var rr := r * r
	var n := 0
	for i in _pos.size():
		if _alive[i] and _pos[i].distance_squared_to(lp) < rr:
			n += 1
			_alive[i] = false
			multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ZERO), _pos[i]))
	return n
