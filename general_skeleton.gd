@tool
extends Skeleton3D
## Пересборка скина по текущему rest скелета.
## Работает ТОЛЬКО если rest-поза костей корректна (иначе бинды станут единичными).

@export var rebuild_skins: bool:
	set(value):
		if value:
			_do_rebuild()

## Восстановить rest костей из биндов уже существующего (корректного) скина первого меша.
@export var restore_rest_from_skin: bool:
	set(value):
		if value:
			_do_restore_rest()


func _rest_is_wiped() -> bool:
	for i in get_bone_count():
		if get_bone_rest(i).origin.length() > 0.0001:
			return false
	return true


func _do_rebuild() -> void:
	var root := get_tree().edited_scene_root if is_inside_tree() else get_parent()
	if not root:
		return
	var bone_cnt := get_bone_count()
	if bone_cnt <= 0:
		return
	if _rest_is_wiped():
		push_error("GeneralSkeleton: rest всех костей нулевой — пересборка скина сломает меш. Сначала восстанови rest (restore_rest_from_skin или реимпорт .model).")
		return
	var common_skin := Skin.new()
	for i in bone_cnt:
		# bind = инверсия ГЛОБАЛЬНОГО rest (а не локального)
		common_skin.add_named_bind(get_bone_name(i), get_bone_global_rest(i).affine_inverse())
	for child in get_children():
		if child is MeshInstance3D:
			var mi := child as MeshInstance3D
			mi.skin = common_skin
			mi.skeleton = mi.get_path_to(self)
			mi.owner = root


func _do_restore_rest() -> void:
	var skin: Skin = null
	for c in get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).skin:
			skin = (c as MeshInstance3D).skin
			break
	if skin == null:
		push_error("GeneralSkeleton: у мешей нет скина")
		return
	var world := {}
	var informative := false
	for i in skin.get_bind_count():
		var t := skin.get_bind_pose(i)
		if not t.is_equal_approx(Transform3D.IDENTITY):
			informative = true
		world[String(skin.get_bind_name(i))] = t.affine_inverse()
	if not informative:
		push_error("GeneralSkeleton: бинды единичные — восстанавливать не из чего. Сделай реимпорт .model.")
		return
	for i in get_bone_count():
		var nm := String(get_bone_name(i))
		if not world.has(nm):
			continue
		var w: Transform3D = world[nm]
		var p := get_bone_parent(i)
		var local := w
		if p >= 0:
			var pn := String(get_bone_name(p))
			if world.has(pn):
				local = (world[pn] as Transform3D).affine_inverse() * w
		set_bone_rest(i, local)
	reset_bone_poses()
