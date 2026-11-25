@tool
extends EditorImportPlugin
const HkxReader := preload("hkx_reader.gd")

var _bones_cache := {}  
func _get_importer_name() -> String:
	return "he1.hkx_animation"

func _get_visible_name() -> String:
	return "HE1 Animation (hkx)"
func _get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray(["hkx"])
func _get_save_extension() -> String:
	return "res"

func _get_resource_type() -> String:
	return "AnimationLibrary"

func _get_priority() -> float:
	return 1.0

func _get_import_order() -> int:
	return 0

func _get_preset_count() -> int:
	return 1

func _get_preset_name(i: int) -> String:
	return "Default"

func _get_import_options(path: String, preset_index: int) -> Array[Dictionary]:
	return [{
		"name": "skeleton_hkx",
		"default_value": "",
		"property_hint": PROPERTY_HINT_FILE,
		"hint_string": "*.hkx",
	}]

func _get_option_visibility(path: String, option_name: StringName, options: Dictionary) -> bool:
	return true


func _is_skl(fname: String) -> bool:
	return fname.ends_with(".skl.hkx") or fname.ends_with("_skl.hkx")


func _bone_names_for(source_file: String, explicit: String) -> PackedStringArray:
	var skl := explicit
	if skl == "":
		var dir := source_file.get_base_dir()
		var files := DirAccess.get_files_at(dir)
		files.sort()
		for n in files:
			if _is_skl(n):
				skl = dir + "/" + n
				break
	if skl == "":
		return PackedStringArray()
	if _bones_cache.has(skl):
		return _bones_cache[skl]
	var r := HkxReader.new()
	var names := PackedStringArray()
	if r.open(skl):
		names = r.read_bone_names()
	_bones_cache[skl] = names
	return names


func _import(source_file: String, save_path: String, options: Dictionary,
		platform_variants: Array[String], gen_files: Array[String]) -> Error:
	var lib := AnimationLibrary.new()
	var fname := source_file.get_file()
	if not _is_skl(fname):
		var names := _bone_names_for(source_file, str(options.get("skeleton_hkx", "")))
		if names.is_empty():
			push_warning("HE1: нет skl.hkx для " + source_file + " (укажи skeleton_hkx в опциях импорта)")
		else:
			var r := HkxReader.new()
			r.verbose = false
			if r.open(source_file):
				var anims := r.read_animations(names)
				var base := fname.replace(".anm.hkx", "").replace("_anm.hkx", "")
				if base.ends_with(".hkx"):
					base = base.get_basename()
				for key in anims:
					var id := base if anims.size() == 1 else "%s_%d" % [base, key]
					lib.add_animation(id, anims[key])
				if anims.is_empty():
					push_warning("HE1: анимации не прочитаны из " + source_file)
			else:
				push_warning("HE1: не удалось открыть " + source_file)
	return ResourceSaver.save(lib, "%s.%s" % [save_path, _get_save_extension()])
