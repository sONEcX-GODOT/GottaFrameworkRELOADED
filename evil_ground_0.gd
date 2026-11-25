@tool
extends MeshInstance3D

@export var albedo: Texture2D
@export var shells := 12
@export var fur_length := 0.03
@export var density := 60.0
@export var gravity := Vector3(0, -0.1, 0)
@export var root_darkness := 0.32
@export var rebuild := false:
	set(v):
		rebuild = false
		if is_inside_tree():
			_build()

func _ready() -> void:
	_build()

func _build() -> void:
	var shader := load("res://models/fur.gdshader") as Shader
	if shader == null:
		push_error("fur.gdshader не найден по пути res://models/fur.gdshader")
		return
	var first: ShaderMaterial = null
	var prev: ShaderMaterial = null
	for i in shells:
		var m := ShaderMaterial.new()
		m.shader = shader
		m.set_shader_parameter("albedo_tex", albedo)
		m.set_shader_parameter("layer", float(i) / (shells - 1))
		m.set_shader_parameter("fur_length", fur_length)
		m.set_shader_parameter("density", density)
		m.set_shader_parameter("gravity", gravity)
		m.set_shader_parameter("root_darkness", root_darkness)
		if prev:
			prev.next_pass = m
		else:
			first = m
		prev = m
	material_override = first
