@tool
extends EditorSceneFormatImporter
const HkxReader := preload("hkx_reader.gd")
func _get_extensions() -> PackedStringArray:
	return PackedStringArray(["model", "terrain-model"])
func _get_import_flags() -> int:
	return IMPORT_SCENE
func _get_import_options(path: String) -> void:
	add_import_option("rest_pose", true)
	add_import_option("skinning", true)
	add_import_option("embed_animations", false)
func _get_option_visibility(path: String, for_animation: bool, option: String) -> Variant:
	return true
func _import_scene(path: String, flags: int, options: Dictionary) -> Object:
	return Parser.new().run(path, options)
class Parser:
	const B := 0x18
	const VERBOSE := false
	var f: FileAccess
	var opt_rest := true
	var opt_skin := true
	var opt_anim := false
	func _u32(pos: int) -> int:
		f.seek(pos)
		return f.get_32()
	func _cstr(pos: int) -> String:
		f.seek(pos)
		var bytes := PackedByteArray()
		while not f.eof_reached():
			var c := f.get_8()
			if c == 0:
				break
			bytes.append(c)
		return bytes.get_string_from_ascii()
	 
	func _empty_scene(path: String) -> Node3D:
		f = null
		var n := Node3D.new()
		n.name = path.get_file().get_basename()
		return n
	func run(path: String, options: Dictionary) -> Object:
		f = FileAccess.open(path, FileAccess.READ)
		if f == null:
			push_warning("HE1: cannot open " + path)
			return _empty_scene(path)
		f.big_endian = true
		var flen := f.get_length()
		if flen < 0x100 or _u32(0) != flen:
			push_warning("HE1: skipped (not a big-endian Unleashed .model): " + path)
			return _empty_scene(path)
		opt_rest = bool(options.get("rest_pose", true))
		opt_skin = bool(options.get("skinning", true))
		opt_anim = bool(options.get("embed_animations", false))
		var root := Node3D.new()
		root.name = path.get_file().get_basename()
		var nd := _find_nodes(flen)
		var node_cnt: int = nd[0]
		var node_tbl: int = nd[1]
		var ibm_ptr: int = nd[2]
		if node_cnt < 0:
			push_warning("HE1: bad node table, skipped: " + path)
			return _empty_scene(path)
	
		var skel: Skeleton3D = null
		var common_skin: Skin = null
		var mesh_parent: Node3D = root
		if node_cnt > 0:
			skel = Skeleton3D.new()
			skel.name = "Skeleton"
			root.add_child(skel)
			skel.owner = root
			mesh_parent = skel
			var parents: Array[int] = []
			for i in node_cnt:
				var p := _u32(node_tbl + 4 * i) + B
				var parent := _u32(p)
				parents.append(-1 if parent == 0xFFFFFFFF else parent)
				skel.add_bone(_cstr(_u32(p + 4) + B))
			for i in node_cnt:
				if parents[i] >= 0:
					skel.set_bone_parent(i, parents[i])
			var ibms: Array[Transform3D] = []
			for i in node_cnt:
				f.seek(ibm_ptr + 64 * i)
				var m: Array[float] = []
				for k in 16:
					m.append(f.get_float())
				var m00 := m.pop_front()
				var m01 := m.pop_front()
				var m02 := m.pop_front()
				var m03 := m.pop_front()
				var m10 := m.pop_front()
				var m11 := m.pop_front()
				var m12 := m.pop_front()
				var m13 := m.pop_front()
				var m20 := m.pop_front()
				var m21 := m.pop_front()
				var m22 := m.pop_front()
				var m23 := m.pop_front()
				var basis := Basis(Vector3(m00, m10, m20), Vector3(m01, m11, m21), Vector3(m02, m12, m22))
				ibms.append(Transform3D(basis, Vector3(m03, m13, m23)))
			if opt_rest:
				for i in node_cnt:
					var world := ibms[i].affine_inverse()
					var local := world if parents[i] < 0 else ibms[parents[i]] * world
					skel.set_bone_rest(i, local)
				skel.reset_bone_poses()
			common_skin = Skin.new()
			for bi in node_cnt:
				common_skin.add_named_bind(skel.get_bone_name(bi), ibms[bi])
		var tables := _find_mesh_tables(flen)
		if VERBOSE:
			print("HE1: %s nodes=%d mesh tables=%s flen=%d" % [path.get_file(), node_cnt, str(tables), flen])
		if tables.is_empty():
			push_warning("HE1: no valid mesh table found: " + path)
		var m_idx := 0
		for t in tables:
			var mesh_cnt: int = t[0]
			var mesh_tbl: int = t[1]
			for i in mesh_cnt:
				var cur := m_idx
				m_idx += 1
				var mp := _u32(mesh_tbl + 4 * i) + B
				if mp <= 0 or mp + 40 > flen:
					push_warning("HE1: mesh %d: bad pointer 0x%x" % [cur, mp])
					continue
				var mi := _build_mesh(mp, common_skin)
				if mi == null:
					push_warning("HE1: mesh %d at 0x%x rejected (bad counts/stride/pointers)" % [cur, mp])
					continue
				mi.name = "%s_%d" % [mi.name, cur]
				mesh_parent.add_child(mi)
				mi.owner = root
		f = null
		if opt_anim and skel != null:
			_load_folder_animations(path, root)
		return root
	
	const SCAN_WORDS := 16

	func _cstr_ok(pos: int, flen: int) -> bool:
		if pos <= 0 or pos >= flen:
			return false
		f.seek(pos)
		var n := 0
		while n < 80:
			var c := f.get_8()
			if c == 0:
				return n > 0
			if c < 32 or c > 126:
				return false
			n += 1
		return false

	func _mesh_table_ok(cnt: int, tbl: int, flen: int) -> bool:
		if cnt < 0 or cnt > 1024 or tbl < 0 or tbl + 4 * cnt > flen:
			return false
		for i in cnt:
			var mp := _u32(tbl + 4 * i) + B
			if mp <= 0 or mp + 40 > flen:
				return false
		return true

	func _mesh_ok(mp: int, flen: int) -> bool:
		if mp <= 0 or mp + 40 > flen:
			return false
		var ic := _u32(mp + 4)
		var ip := _u32(mp + 8) + B
		var vc := _u32(mp + 12)
		var st := _u32(mp + 16)
		var vp := _u32(mp + 20) + B
		var ep := _u32(mp + 24) + B
		var pc := _u32(mp + 28)
		var pp := _u32(mp + 32) + B
		if vc == 0 or ic == 0 or vc > 500000 or ic > 3000000:
			return false
		if st < 12 or st > 256 or pc > 256:
			return false
		if vp + vc * st > flen or ip + ic * 2 > flen or ep >= flen or pp >= flen:
			return false
		return _cstr_ok(_u32(mp) + B, flen)

	func _mesh_table_strict(cnt: int, tbl: int, flen: int) -> bool:
		if cnt < 1 or cnt > 1024 or tbl < 0 or tbl + 4 * cnt > flen:
			return false
		for i in cnt:
			if not _mesh_ok(_u32(tbl + 4 * i) + B, flen):
				return false
		return true

	func _find_mesh_tables(flen: int) -> Array:

		var grp := _u32(B + 4) + B
		if grp >= 0 and grp + 12 <= flen:
			var cnt_a := _u32(grp + 4)
			var tbl_a := _u32(grp + 8) + B
			if _mesh_table_ok(cnt_a, tbl_a, flen):
				return [[cnt_a, tbl_a]]

		var res: Array = []
		var seen := {}
		for k in SCAN_WORDS:
			var pos := B + 4 * k
			if pos + 8 > flen:
				break
			var cnt := _u32(pos)
			var tbl := _u32(pos + 4) + B
			if seen.has(tbl):
				continue
			if _mesh_table_strict(cnt, tbl, flen):
				seen[tbl] = true
				res.append([cnt, tbl])
		return res

	func _nodes_strict(cnt: int, tbl: int, ibm: int, flen: int) -> bool:
		if cnt < 1 or cnt > 1024 or tbl < 0 or tbl + 4 * cnt > flen:
			return false
		if ibm <= 0 or ibm + 64 * cnt > flen:
			return false
		for i in cnt:
			var p := _u32(tbl + 4 * i) + B
			if p <= 0 or p + 8 > flen:
				return false
			var parent := _u32(p)
			if parent != 0xFFFFFFFF and parent >= cnt:
				return false
			if not _cstr_ok(_u32(p + 4) + B, flen):
				return false
		return true

	func _find_nodes(flen: int) -> Array:

		var tbl := _u32(B + 0x0c) + B
		var cnt := _u32(B + 0x10)
		var ibm := _u32(B + 0x18) + B
		if _nodes_strict(cnt, tbl, ibm, flen):
			return [cnt, tbl, ibm]
	
		for k in SCAN_WORDS:
			var pos := B + 4 * k
			if pos + 12 > flen:
				break
			var c := _u32(pos)
			var t := _u32(pos + 4) + B
			var m := _u32(pos + 8) + B
			if _nodes_strict(c, t, m, flen):
				return [c, t, m]
	
		if cnt > 0:
			if cnt <= 1024 and tbl + 4 * cnt <= flen:
				return [cnt, tbl, ibm]
			return [-1, 0, 0]
		return [0, 0, 0]

	func _build_mesh(mp: int, shared_skin: Skin) -> MeshInstance3D:
		var mesh_name := _cstr(_u32(mp) + B)
		var idx_cnt := _u32(mp + 4)
		var idx_ptr := _u32(mp + 8) + B
		var v_cnt := _u32(mp + 12)
		var stride := _u32(mp + 16)
		var v_ptr := _u32(mp + 20) + B
		var el_ptr := _u32(mp + 24) + B
		var pal_cnt := _u32(mp + 28)
		var pal_ptr := _u32(mp + 32) + B
		var flen := f.get_length()
		if v_cnt == 0 or idx_cnt == 0 or v_cnt > 500000 or idx_cnt > 3000000:
			return null
		if stride < 12 or stride > 256 or pal_cnt > 256:
			return null
		if v_ptr + v_cnt * stride > flen or idx_ptr + idx_cnt * 2 > flen:
			return null
		if el_ptr >= flen or pal_ptr >= flen:
			return null
		var pal := PackedInt32Array()
		f.seek(pal_ptr)
		for i in pal_cnt:
			pal.append(f.get_8())
		var elems: Array[Dictionary] = []
		var p := el_ptr
		while true:
			var fmt := _u32(p + 4)
			if fmt == 0xFFFFFFFF:
				break
			var usage := _u32(p + 8)
			elems.append({"off": _u32(p), "type": usage >> 16, "idx": usage & 0xFFFF})
			p += 12
			if elems.size() > 32:
				break
		var verts := PackedVector3Array()
		var norms := PackedVector3Array()
		var uvs := PackedVector2Array()
		var cols := PackedColorArray()
		var bones := PackedInt32Array()
		var weights := PackedFloat32Array()
		for v in v_cnt:
			var base := v_ptr + v * stride
			for e in elems:
				f.seek(base + int(e.off))
				match int(e.type):
					0:
						verts.append(Vector3(f.get_float(), f.get_float(), f.get_float()))
					3:
						norms.append(Vector3(f.get_float(), f.get_float(), f.get_float()))
					5:
						if int(e.idx) == 0:
							uvs.append(Vector2(f.get_float(), f.get_float()))
					10:
						cols.append(Color(f.get_float(), f.get_float(), f.get_float(), f.get_float()))
					1:
						for k in 4:
							weights.append(f.get_8() / 255.0)
					2:
						for k in 4:
							var local_bone_idx := f.get_8()
							var global_bone_idx := pal[local_bone_idx] if local_bone_idx < pal.size() else 0
							bones.append(global_bone_idx)
		f.seek(idx_ptr)
		var idx := PackedInt32Array()
		for i in idx_cnt:
			idx.append(f.get_16())
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = verts
		if norms.size() == v_cnt:
			arr[Mesh.ARRAY_NORMAL] = norms
		if uvs.size() == v_cnt:
			arr[Mesh.ARRAY_TEX_UV] = uvs
		if cols.size() == v_cnt:
			arr[Mesh.ARRAY_COLOR] = cols
		if shared_skin != null and bones.size() == v_cnt * 4 and weights.size() == v_cnt * 4:
			arr[Mesh.ARRAY_BONES] = bones
			arr[Mesh.ARRAY_WEIGHTS] = weights
		arr[Mesh.ARRAY_INDEX] = _strip_to_tris(idx)
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		var mi := MeshInstance3D.new()
		mi.name = mesh_name
		mi.mesh = mesh
		if shared_skin != null and arr[Mesh.ARRAY_BONES] != null:
			mi.skin = shared_skin
			mi.skeleton = NodePath("..")
		return mi
	func _strip_to_tris(idx: PackedInt32Array) -> PackedInt32Array:
		var out := PackedInt32Array()
		var a := 0
		var b := 0
		var n := 0
		for i in idx:
			if i == 0xFFFF:
				n = 0
				continue
			if n >= 2 and a != b and b != i and a != i:
				if n % 2 == 0:
					out.append_array([a, b, i])
				else:
					out.append_array([b, a, i])
			a = b
			b = i
			n += 1
		return out
	func _load_folder_animations(model_path: String, root_node: Node3D) -> void:
		var folder := model_path.get_base_dir()
		var anm_files: Array[String] = []
		var skl_file := ""
		var files := DirAccess.get_files_at(folder)
		files.sort()
		for f_name in files:
			if f_name.ends_with(".anm.hkx") or f_name.ends_with("_anm.hkx"):
				anm_files.append(folder + "/" + f_name)
			elif (f_name.ends_with(".skl.hkx") or f_name.ends_with("_skl.hkx")) and skl_file == "":
				skl_file = folder + "/" + f_name
		if anm_files.is_empty():
			return
		var skel := root_node.get_node("Skeleton") as Skeleton3D
	
		var names := PackedStringArray()
		for i in skel.get_bone_count():
			names.append(skel.get_bone_name(i))
		if skl_file != "":
			var sr := HkxReader.new()
			if sr.open(skl_file):
				var sn := sr.read_bone_names()
				if sn.size() > 0:
					names = sn
		var missing := 0
		for n in names:
			if skel.find_bone(n) < 0:
				missing += 1
		if missing > 0:
			push_warning("HE1: %d костей из skl.hkx нет в модели, их треки будут пропущены" % missing)
		var anim_library := AnimationLibrary.new()
		for path in anm_files:
			var reader := HkxReader.new()
			if not reader.open(path):
				push_warning("HE1: не удалось открыть " + path)
				continue
			var anims := reader.read_animations(names)
			var base_id := path.get_file().replace(".anm.hkx", "").replace("_anm.hkx", "")
			for key in anims:
				var id := base_id if anims.size() == 1 else "%s_%d" % [base_id, key]
				anim_library.add_animation(id, anims[key])
		if anim_library.get_animation_list().size() == 0:
			return
		var anim_player := AnimationPlayer.new()
		anim_player.name = "AnimationPlayer"
		root_node.add_child(anim_player)
		anim_player.owner = root_node
		anim_player.add_animation_library("", anim_library)
