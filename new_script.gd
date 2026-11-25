@tool
extends EditorScript
func _run() -> void:
	var root := EditorInterface.get_edited_scene_root()
	var sk := root.find_child("Skeleton", true, false) as Skeleton3D
	var ap := root.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if sk == null or ap == null:
		print("НЕ НАЙДЕНЫ: skeleton=", sk, " player=", ap)
		return
	print("анимации: ", ap.get_animation_list())
	for a in ap.get_animation_list():
		if "ball" in a:
			ap.play(a)
			ap.pause()
			ap.seek(0.0, true)
			ap.advance(0.0)
			break
	print("текущая: ", ap.current_animation)
	for b in ["Hips", "Head", "Hand_L", "Foot_L"]:
		var i := sk.find_bone(b)
		if i < 0:
			print(b, " — кости нет")
		else:
			print(b, " pose=", sk.get_bone_global_pose(i).origin, " rest=", sk.get_bone_global_rest(i).origin)
