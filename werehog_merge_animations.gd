@tool
extends EditorScript
## Склеивает все импортированные *.anm.hkx из папки в ОДНУ библиотеку анимаций
## и (по желанию) ставит её в AnimationPlayer открытой сцены.
## Запуск: открыть этот скрипт -> Файл -> Запустить (Ctrl+Shift+X).

const SRC_DIR := "res://models/EvilSonic"                  # где лежат *.anm.hkx (ищет рекурсивно)
const OUT_PATH := "res://models/EvilSonic/werehog_animations.res"  # куда сохранить общую библиотеку
const ATTACH_TO_PLAYER := true       # поставить библиотеку в AnimationPlayer текущей сцены
const CLEAR_OLD_LIBRARIES := true    # убрать из плеера старые библиотеки (по одной на файл)

# Сжатие: убирает лишние ключи (главная причина 66 МБ — ключ на каждый кадр у каждой кости)
const OPTIMIZE := true
const VELOCITY_ERR := 0.01   # больше значение -> меньше файл, но грубее анимация (0.01–0.05)
const ANGULAR_ERR := 0.01
const PRECISION := 3


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
			var anim := lib.get_animation(n).duplicate() as Animation
			if OPTIMIZE:
				anim.optimize(VELOCITY_ERR, ANGULAR_ERR, PRECISION)
			merged.add_animation(final_id, anim)
			count += 1
	var err := ResourceSaver.save(merged, OUT_PATH, ResourceSaver.FLAG_CHANGE_PATH)
	if err != OK:
		push_error("Не удалось сохранить %s (код %d)" % [OUT_PATH, err])
		return
	var f := FileAccess.open(OUT_PATH, FileAccess.READ)
	var mb := (f.get_length() / 1048576.0) if f != null else 0.0
	print("Собрано анимаций: %d из %d файлов -> %s (%.1f МБ)" % [count, files.size(), OUT_PATH, mb])
	if not ATTACH_TO_PLAYER:
		return
	var root := EditorInterface.get_edited_scene_root()
	if root == null:
		return
	var ap := _find_player(root)
	if ap == null:
		push_warning("AnimationPlayer в сцене не найден")
		return
	if CLEAR_OLD_LIBRARIES:
		for lib_name in ap.get_animation_library_list():
			ap.remove_animation_library(lib_name)
	elif ap.has_animation_library(""):
		ap.remove_animation_library("")
	# merged уже привязан к OUT_PATH (FLAG_CHANGE_PATH) — повторно с диска не грузим, экономим память
	ap.add_animation_library("", merged)
	print("Библиотека подключена к ", ap.name, ". Сохрани сцену (Ctrl+S).")


## Ищет AnimationPlayer по классу (имя узла не важно).
## Приоритет: выделенный -> принадлежащий сцене с именем "AnimationPlayer" -> первый найденный.
func _find_player(root: Node) -> AnimationPlayer:
	for n in EditorInterface.get_selection().get_selected_nodes():
		if n is AnimationPlayer:
			return n as AnimationPlayer
	var list: Array[AnimationPlayer] = []
	if root is AnimationPlayer:
		list.append(root as AnimationPlayer)
	for n in root.find_children("*", "AnimationPlayer", true, false):
		list.append(n as AnimationPlayer)
	if list.is_empty():
		return null
	for p in list:
		if String(p.name) == "AnimationPlayer" and (p == root or p.owner == root):
			return p
	for p in list:
		if p == root or p.owner == root:
			return p
	return list[0]
