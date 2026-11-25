@tool
extends EditorScript
## Склеивает все импортированные *.anm.hkx из папки в ОДНУ библиотеку анимаций
## и (по желанию) ставит её в AnimationPlayer открытой сцены.
## Запуск: открыть этот скрипт -> Файл -> Запустить (Ctrl+Shift+X).

const SRC_DIR := "res://models/Sonic"                      # где лежат *.anm.hkx (ищет рекурсивно)
const OUT_PATH := "res://models/Sonic/sonic_animations.res"  # куда сохранить общую библиотеку
const ATTACH_TO_PLAYER := true       # поставить библиотеку в AnimationPlayer текущей сцены
const CLEAR_OLD_LIBRARIES := true    # убрать из плеера старые библиотеки (по одной на файл)


func _collect(dir: String, out: Array[String]) -> void:
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".anm.hkx") or f.ends_with("_anm.hkx"):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		_collect(dir.path_join(d), out)


func _run() -> void:
	var files: Array[String] = []
	_collect(SRC_DIR, files)
	files.sort()
	if files.is_empty():
		push_error("Не найдено *.anm.hkx в " + SRC_DIR)
		return
	var merged := AnimationLibrary.new()
	var count := 0
	for path in files:
		var lib := load(path) as AnimationLibrary
		if lib == null:
			push_warning("Не загрузилась библиотека: " + path)
			continue
		for n in lib.get_animation_list():
			var id := String(n)
			var final_id := id
			var k := 2
			while merged.has_animation(final_id):
				final_id = "%s_%d" % [id, k]
				k += 1
			merged.add_animation(final_id, lib.get_animation(n).duplicate())
			count += 1
	var err := ResourceSaver.save(merged, OUT_PATH)
	if err != OK:
		push_error("Не удалось сохранить %s (код %d)" % [OUT_PATH, err])
		return
	print("Собрано анимаций: %d из %d файлов -> %s" % [count, files.size(), OUT_PATH])
	if not ATTACH_TO_PLAYER:
		return
	var root := EditorInterface.get_edited_scene_root()
	if root == null:
		return
	var ap := root.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap == null:
		push_warning("AnimationPlayer в сцене не найден")
		return
	if CLEAR_OLD_LIBRARIES:
		for lib_name in ap.get_animation_library_list():
			ap.remove_animation_library(lib_name)
	elif ap.has_animation_library(""):
		ap.remove_animation_library("")
	var saved := ResourceLoader.load(OUT_PATH, "", ResourceLoader.CACHE_MODE_REPLACE) as AnimationLibrary
	ap.add_animation_library("", saved)
	print("Библиотека подключена к ", ap.name, ". Сохрани сцену (Ctrl+S).")
