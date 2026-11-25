@tool
extends RefCounted
## Читатель Havok packfile (.hkx, Havok 5.5.0-r1, 32-bit указатели, big-endian, Sonic Unleashed).
## Раскладки сверены с реальными SonicRoot.skl.hkx / sonic_ball.anm.hkx.
## Умеет: имена костей из hkaSkeleton и анимации hkaSplineSkeletalAnimation.
## ВАЖНО: блок данных сплайн-анимации лежит в little-endian, даже в big-endian файле.

const MAGIC0 := 0x57E0E057
const MAGIC1 := 0x10C0C010

# Размер/выравнивание квантованного кватерниона по типу (RotationQuantization)
const QSIZE := {0: 4, 1: 5, 2: 6, 3: 3, 4: 2, 5: 16}
const QALIGN := {0: 4, 1: 1, 2: 2, 3: 1, 4: 2, 5: 4}

var verbose := true

class Sec:
	var name := ""
	var start := 0
	var local := {}   # src -> dst (внутри секции)
	var glob := {}    # src -> Vector2i(секция, смещение)

var f: FileAccess
var secs: Array[Sec] = []
var class_at := {}   # Vector2i(секция, смещение) -> имя класса
var objects := {}    # имя класса -> Array[Vector2i]
var _base := 0
var _blob := PackedByteArray()   # данные сплайн-анимации (little-endian)
var _warned := {}


# ---------------------------------------------------------------- низкий уровень
func _u8(p: int) -> int:
	f.seek(p)
	return f.get_8()

func _u16(p: int) -> int:
	f.seek(p)
	return f.get_16()

func _i16(p: int) -> int:
	var v := _u16(p)
	return v - 65536 if v >= 32768 else v

func _u32(p: int) -> int:
	f.seek(p)
	return f.get_32()

func _f32(p: int) -> float:
	f.seek(p)
	return f.get_float()

func _cstr(p: int) -> String:
	f.seek(p)
	var bytes := PackedByteArray()
	while not f.eof_reached() and bytes.size() < 256:
		var c := f.get_8()
		if c == 0:
			break
		bytes.append(c)
	return bytes.get_string_from_ascii()

func _align(p: int, a: int) -> int:
	var rel := p - _base + a - 1
	return _base + rel - rel % a

func _warn_once(key: String, msg: String) -> void:
	if not _warned.has(key):
		_warned[key] = true
		push_warning("HKX: " + msg)


# ---------------------------------------------------------------- packfile
func open(path: String) -> bool:
	f = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	if f.get_length() < 0x80 or _u32(0) != MAGIC0 or _u32(4) != MAGIC1:
		f = null
		return false
	f.big_endian = (_u8(0x11) == 0)
	if _u8(0x10) != 4:
		push_warning("HKX: нужны 32-битные указатели: " + path)
		f = null
		return false
	var nsec := _u32(0x14)
	var sh := 0x40
	if _cstr(sh) != "__classnames__":
		sh = 0x50
	if nsec < 1 or nsec > 16 or _cstr(sh) != "__classnames__":
		push_warning("HKX: не найден заголовок секций: " + path)
		f = null
		return false
	var virt: Array = []
	for i in nsec:
		var h := sh + 0x30 * i
		var s := Sec.new()
		s.name = _cstr(h)
		s.start = _u32(h + 20)
		var lf := _u32(h + 24)
		var gf := _u32(h + 28)
		var vf := _u32(h + 32)
		var ex := _u32(h + 36)
		secs.append(s)
		var p := s.start + lf
		while p + 8 <= s.start + gf:
			var src := _u32(p)
			if src == 0xFFFFFFFF:
				break
			s.local[src] = _u32(p + 4)
			p += 8
		p = s.start + gf
		while p + 12 <= s.start + vf:
			var gsrc := _u32(p)
			if gsrc == 0xFFFFFFFF:
				break
			s.glob[gsrc] = Vector2i(_u32(p + 4), _u32(p + 8))
			p += 12
		p = s.start + vf
		while p + 12 <= s.start + ex:
			var vsrc := _u32(p)
			if vsrc == 0xFFFFFFFF:
				break
			virt.append([i, vsrc, _u32(p + 4), _u32(p + 8)])
			p += 12
	for v in virt:
		var cn_sec: int = v[2]
		if cn_sec < 0 or cn_sec >= secs.size():
			continue
		var cname := _cstr(secs[cn_sec].start + int(v[3]))
		var addr := Vector2i(v[0], v[1])
		class_at[addr] = cname
		if not objects.has(cname):
			objects[cname] = []
		objects[cname].append(addr)
	return true


func _ptr(sec: int, off: int) -> Vector2i:
	var s: Sec = secs[sec]
	if s.local.has(off):
		return Vector2i(sec, s.local[off])
	if s.glob.has(off):
		return s.glob[off]
	return Vector2i(-1, -1)

func _abs(a: Vector2i) -> int:
	return secs[a.x].start + a.y

func _str_at(sec: int, off: int) -> String:
	var p := _ptr(sec, off)
	if p.x < 0:
		return ""
	return _cstr(_abs(p))

## hkArray: [ptr: Vector2i, count: int]
func _arr(sec: int, off: int) -> Array:
	return [_ptr(sec, off), _u32(secs[sec].start + off + 4)]


# ---------------------------------------------------------------- скелет
## hkaSkeleton (5.5, без заголовка объекта; массивы = ptr + count):
## +0 name, +4/+8 parentIndices, +12/+16 bones (массив указателей на hkaBone), +20/+24 referencePose
## hkaBone: +0 name (ptr)
func read_bone_names() -> PackedStringArray:
	var names := PackedStringArray()
	for obj in objects.get("hkaSkeleton", []):
		var bp := _ptr(obj.x, obj.y + 12)
		var cnt := _u32(_abs(obj) + 16)
		if bp.x < 0 or cnt <= 0 or cnt > 4096:
			continue
		for i in cnt:
			var bone := _ptr(bp.x, bp.y + 4 * i)
			names.append("" if bone.x < 0 else _str_at(bone.x, bone.y))
		break
	return names


# ---------------------------------------------------------------- анимации
## Возвращает { индекс_binding: Animation }. bone_names — порядок костей hkaSkeleton.
## hkaAnimationBinding (5.5): +0 animation (ptr), +4/+8 transformTrackToBoneIndices (ptr+count, int16)
func read_animations(bone_names: PackedStringArray) -> Dictionary:
	var result := {}
	var bindings: Array = objects.get("hkaAnimationBinding", [])
	for bi in bindings.size():
		var b: Vector2i = bindings[bi]
		var ap := _ptr(b.x, b.y)
		if ap.x < 0:
			continue
		var mp := _ptr(b.x, b.y + 4)
		var mcnt := _u32(_abs(b) + 8)
		var map := PackedInt32Array()
		if mp.x >= 0 and mcnt > 0 and mcnt < 4096:
			for i in mcnt:
				map.append(_i16(_abs(mp) + 2 * i))
		var cls: String = class_at.get(ap, "")
		var anim: Animation = null
		match cls:
			"hkaSplineSkeletalAnimation", "hkaSplineCompressedAnimation":
				anim = _build_spline(ap, map, bone_names)
			"hkaInterleavedSkeletalAnimation", "hkaInterleavedUncompressedAnimation":
				anim = _build_interleaved(ap, map, bone_names)
			_:
				push_warning("HKX: неподдерживаемый тип анимации: " + cls)
		if anim:
			result[bi] = anim
	return result


func _build_interleaved(a: Vector2i, map: PackedInt32Array, names: PackedStringArray) -> Animation:
	var o := _abs(a)
	var duration := _f32(o + 0x0C)
	var n_tracks := _u32(o + 0x10)
	var tr := _arr(a.x, a.y + 0x24)  # не проверено на реальных файлах
	var tp: Vector2i = tr[0]
	if n_tracks <= 0 or tp.x < 0:
		return null
	var num_frames := int(tr[1]) / n_tracks
	var base := _abs(tp)
	var P: Array = []
	var R: Array = []
	var S: Array = []
	for t in n_tracks:
		var ps := PackedVector3Array()
		var rs: Array[Quaternion] = []
		var ss := PackedVector3Array()
		for i in num_frames:
			var q := base + (i * n_tracks + t) * 48
			ps.append(Vector3(_f32(q), _f32(q + 4), _f32(q + 8)))
			rs.append(Quaternion(_f32(q + 16), _f32(q + 20), _f32(q + 24), _f32(q + 28)).normalized())
			ss.append(Vector3(_f32(q + 32), _f32(q + 36), _f32(q + 40)))
		P.append(ps)
		R.append(rs)
		S.append(ss)
	var dt := duration / maxf(1.0, float(num_frames - 1))
	return _assemble(map, names, P, R, S, num_frames, dt, duration)


func _build_spline(a: Vector2i, map: PackedInt32Array, names: PackedStringArray) -> Animation:
	var o := _abs(a)
	var duration := _f32(o + 0x0C)
	var n_tracks := _u32(o + 0x10)
	var num_frames := _u32(o + 0x24)
	var num_blocks := _u32(o + 0x28)
	var max_fpb := _u32(o + 0x2C)
	var mask_size := _u32(o + 0x30)
	var frame_dur := _f32(o + 0x3C)
	var blk := _arr(a.x, a.y + 0x40)
	var tro := _arr(a.x, a.y + 0x58)
	var dat := _arr(a.x, a.y + 0x70)
	var dp: Vector2i = dat[0]
	var bp: Vector2i = blk[0]
	var tp: Vector2i = tro[0]
	var n_tro: int = tro[1]
	if dp.x < 0 or bp.x < 0 or num_frames <= 0 or n_tracks <= 0 or max_fpb < 2:
		push_warning("HKX: битая hkaSplineSkeletalAnimation")
		return null
	if num_blocks > 4096 or n_tracks > 1024 or num_frames > 100000:
		return null
	if frame_dur <= 0.0:
		frame_dur = duration / maxf(1.0, float(num_frames - 1))
	# блок данных — little-endian
	f.seek(_abs(dp))
	_blob = f.get_buffer(int(dat[1]))
	var stride := max_fpb - 1
	var P: Array = []
	var R: Array = []
	var S: Array = []
	for t in n_tracks:
		var ps := PackedVector3Array()
		ps.resize(num_frames)
		ps.fill(Vector3.ZERO)
		var rs: Array[Quaternion] = []
		rs.resize(num_frames)
		rs.fill(Quaternion.IDENTITY)
		var ss := PackedVector3Array()
		ss.resize(num_frames)
		ss.fill(Vector3.ONE)
		P.append(ps)
		R.append(rs)
		S.append(ss)
	for b in num_blocks:
		var bstart := _u32(_abs(bp) + 4 * b)
		# В 5.5 transformOffsets пуст: данные треков идут сразу за масками.
		var p := bstart + mask_size
		if n_tro > b and tp.x >= 0:
			p = bstart + _u32(_abs(tp) + 4 * b)
		_base = bstart
		var nf := mini(max_fpb, num_frames - b * stride)
		if nf <= 0:
			break
		for t in n_tracks:
			var m := bstart + 4 * t
			if m + 4 > _blob.size():
				break
			var qv := _blob[m]
			var pt := _blob[m + 1]
			var rt := _blob[m + 2]
			var st := _blob[m + 3]
			var r := _read_vec3(p, pt, qv & 3, Vector3.ZERO, nf)
			p = r[0]
			var pos: PackedVector3Array = r[1]
			r = _read_quat(p, rt, (qv >> 2) & 0xF, nf)
			p = r[0]
			var rot: Array = r[1]
			r = _read_vec3(p, st, (qv >> 6) & 3, Vector3.ONE, nf)
			p = r[0]
			var scl: PackedVector3Array = r[1]
			for i in nf:
				var gi := b * stride + i
				P[t][gi] = pos[i]
				R[t][gi] = rot[i]
				S[t][gi] = scl[i]
	if verbose:
		print("HKX: spline anim tracks=%d frames=%d blocks=%d dur=%.3f" % [n_tracks, num_frames, num_blocks, duration])
	return _assemble(map, names, P, R, S, num_frames, frame_dur, duration)


# ---------------------------------------------------------------- B-сплайны
func _basis(knots: PackedByteArray, deg: int, n: int, t: float) -> Array:
	var tt := minf(t, float(knots[n + 1]))
	var i := deg
	while i < n and tt >= float(knots[i + 1]):
		i += 1
	var nn: Array[float] = []
	var left: Array[float] = []
	var right: Array[float] = []
	nn.resize(deg + 1)
	left.resize(deg + 1)
	right.resize(deg + 1)
	nn[0] = 1.0
	for j in range(1, deg + 1):
		left[j] = tt - float(knots[i + 1 - j])
		right[j] = float(knots[i + j]) - tt
		var saved := 0.0
		for r in j:
			var denom := right[r + 1] + left[j - r]
			var temp := 0.0 if denom == 0.0 else nn[r] / denom
			nn[r] = saved + right[r + 1] * temp
			saved = left[j - r] * temp
		nn[j] = saved
	return [i, nn]


func _eval_v3(knots: PackedByteArray, deg: int, n: int, cps: Array[Vector3], t: float) -> Vector3:
	var bs := _basis(knots, deg, n, t)
	var span: int = bs[0]
	var w: Array = bs[1]
	var res := Vector3.ZERO
	for j in deg + 1:
		res += cps[span - deg + j] * float(w[j])
	return res


func _eval_q(knots: PackedByteArray, deg: int, n: int, cps: Array[Quaternion], t: float) -> Quaternion:
	var bs := _basis(knots, deg, n, t)
	var span: int = bs[0]
	var w: Array = bs[1]
	var x := 0.0
	var y := 0.0
	var z := 0.0
	var ww := 0.0
	for j in deg + 1:
		var c: Quaternion = cps[span - deg + j]
		var k := float(w[j])
		x += c.x * k
		y += c.y * k
		z += c.z * k
		ww += c.w * k
	var q := Quaternion(x, y, z, ww)
	if q.length_squared() < 1e-12:
		return Quaternion.IDENTITY
	return q.normalized()


# ---------------------------------------------------------------- треки блока
## Позиция / масштаб. Возвращает [новый_p, PackedVector3Array(nf)]
func _read_vec3(p: int, types: int, quant: int, defv: Vector3, nf: int) -> Array:
	var smask := (types >> 4) & 7
	var tmask := types & 7
	var out := PackedVector3Array()
	out.resize(nf)
	var n := 0
	var deg := 0
	var knots := PackedByteArray()
	if smask != 0:
		n = _blob.decode_u16(p)
		deg = _blob[p + 2]
		p += 3
		knots = _blob.slice(p, p + n + deg + 2)
		p += n + deg + 2
		p = _align(p, 4)
	var mn := Vector3.ZERO
	var mx := Vector3.ZERO
	var base := defv
	for ax in 3:
		if smask & (1 << ax):
			mn[ax] = _blob.decode_float(p)
			mx[ax] = _blob.decode_float(p + 4)
			p += 8
		elif tmask & (1 << ax):
			base[ax] = _blob.decode_float(p)
			p += 4
	if smask == 0:
		out.fill(base)
		return [p, out]
	var wide := quant == 1
	if wide:
		p = _align(p, 2)
	var cps: Array[Vector3] = []
	for c in n + 1:
		var v := Vector3.ZERO
		for ax in 3:
			if smask & (1 << ax):
				var q := 0.0
				if wide:
					q = _blob.decode_u16(p) / 65535.0
					p += 2
				else:
					q = _blob[p] / 255.0
					p += 1
				v[ax] = mn[ax] + (mx[ax] - mn[ax]) * q
		cps.append(v)
	p = _align(p, 4)
	for i in nf:
		var sv := _eval_v3(knots, deg, n, cps, float(i))
		var r := base
		for ax in 3:
			if smask & (1 << ax):
				r[ax] = sv[ax]
		out[i] = r
	return [p, out]


## Вращение. Возвращает [новый_p, Array[Quaternion](nf)]
func _read_quat(p: int, types: int, quant: int, nf: int) -> Array:
	var out: Array[Quaternion] = []
	out.resize(nf)
	out.fill(Quaternion.IDENTITY)
	var is_spline := (types & 0xF0) != 0
	var is_static := (types & 0x0F) != 0
	var qsize: int = QSIZE.get(quant, 16)
	var qalign: int = QALIGN.get(quant, 4)
	if is_spline:
		var n := _blob.decode_u16(p)
		var deg := _blob[p + 2]
		p += 3
		var knots := _blob.slice(p, p + n + deg + 2)
		p += n + deg + 2
		p = _align(p, qalign)
		var cps: Array[Quaternion] = []
		for c in n + 1:
			cps.append(_decode_quat(quant, p))
			p += qsize
		for i in nf:
			out[i] = _eval_q(knots, deg, n, cps, float(i))
	elif is_static:
		p = _align(p, qalign)
		out.fill(_decode_quat(quant, p))
		p += qsize
	p = _align(p, 4)
	return [p, out]


func _decode_quat(quant: int, p: int) -> Quaternion:
	match quant:
		1:  # THREECOMP40 (проверено: little-endian)
			var v := 0
			for k in 5:
				v |= _blob[p + k] << (8 * k)
			var x := float((v & 0xFFF) - 2047)
			var y := float(((v >> 12) & 0xFFF) - 2047)
			var z := float(((v >> 24) & 0xFFF) - 2047)
			var shift := (v >> 36) & 3
			var inv := ((v >> 38) & 1) == 1
			return _assemble_q(x * 0.000345436, y * 0.000345436, z * 0.000345436, shift, inv)
		2:  # THREECOMP48 (не проверено на файлах)
			var r0 := _blob.decode_u16(p)
			var r1 := _blob.decode_u16(p + 2)
			var r2 := _blob.decode_u16(p + 4)
			var shift := ((r0 >> 15) & 1) | (((r1 >> 15) & 1) << 1)
			var inv := ((r2 >> 15) & 1) == 1
			var fx := float((r0 & 0x7FFF) - 16383) * 0.000043161
			var fy := float((r1 & 0x7FFF) - 16383) * 0.000043161
			var fz := float((r2 & 0x7FFF) - 16383) * 0.000043161
			return _assemble_q(fx, fy, fz, shift, inv)
		5:  # UNCOMPRESSED
			return Quaternion(_blob.decode_float(p), _blob.decode_float(p + 4), _blob.decode_float(p + 8), _blob.decode_float(p + 12)).normalized()
		_:
			_warn_once("q%d" % quant, "тип квантования вращения %d не реализован (POLAR32=0, THREECOMP24=3, STRAIGHT16=4)" % quant)
			return Quaternion.IDENTITY


func _assemble_q(a: float, b: float, c: float, shift: int, inv: bool) -> Quaternion:
	var w := sqrt(maxf(0.0, 1.0 - a * a - b * b - c * c))
	if inv:
		w = -w
	var comp: Array[float] = [0.0, 0.0, 0.0, 0.0]
	var src: Array[float] = [a, b, c]
	var si := 0
	for k in 4:
		if k == shift:
			comp[k] = w
		else:
			comp[k] = src[si]
			si += 1
	return Quaternion(comp[0], comp[1], comp[2], comp[3]).normalized()


# ---------------------------------------------------------------- Animation
func _assemble(map: PackedInt32Array, names: PackedStringArray, P: Array, R: Array, S: Array,
		num_frames: int, dt: float, duration: float) -> Animation:
	var anim := Animation.new()
	anim.length = maxf(duration, dt * float(num_frames - 1))
	var used := 0
	for t in P.size():
		var bi := t if map.is_empty() else (map[t] if t < map.size() else -1)
		if bi < 0 or bi >= names.size() or names[bi] == "":
			continue
		var path := NodePath("Skeleton:" + names[bi])
		var ps: PackedVector3Array = P[t]
		var rs: Array = R[t]
		var ss: PackedVector3Array = S[t]
		var ti := anim.add_track(Animation.TYPE_POSITION_3D)
		anim.track_set_path(ti, path)
		var const_p := true
		for i in range(1, num_frames):
			if not ps[i].is_equal_approx(ps[0]):
				const_p = false
				break
		if const_p:
			anim.position_track_insert_key(ti, 0.0, ps[0])
		else:
			for i in num_frames:
				anim.position_track_insert_key(ti, i * dt, ps[i])
		ti = anim.add_track(Animation.TYPE_ROTATION_3D)
		anim.track_set_path(ti, path)
		var const_r := true
		for i in range(1, num_frames):
			if not (rs[i] as Quaternion).is_equal_approx(rs[0]):
				const_r = false
				break
		if const_r:
			anim.rotation_track_insert_key(ti, 0.0, rs[0])
		else:
			for i in num_frames:
				anim.rotation_track_insert_key(ti, i * dt, rs[i])
		var const_s := true
		for i in num_frames:
			if not ss[i].is_equal_approx(Vector3.ONE):
				const_s = false
				break
		if not const_s:
			ti = anim.add_track(Animation.TYPE_SCALE_3D)
			anim.track_set_path(ti, path)
			for i in num_frames:
				anim.scale_track_insert_key(ti, i * dt, ss[i])
		used += 1
	if used == 0:
		return null
	return anim
