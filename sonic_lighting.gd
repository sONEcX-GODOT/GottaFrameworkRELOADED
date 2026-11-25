@tool
extends Node3D

enum ZonePreset {
	CUSTOM,
	APOTOS_DAY,
	SPAGONIA_SUNSET,
	HOLOSKA_DAY,
	WEREHOG_NIGHT
}

@export var zone_preset: ZonePreset = ZonePreset.APOTOS_DAY:
	set(value):
		zone_preset = value
		_apply_preset(value)

@export_group("Shaders & Textures")
@export var sky_shader: Shader = preload("res://materials/sonic_sky.gdshader"):
	set(v): sky_shader = v; _rebuild_environment()
@export var sky_texture: Texture2D:
	set(v): sky_texture = v; _update_shader_params()
@export_range(0.0, 1.0) var sky_texture_mix: float = 0.6:
	set(v): sky_texture_mix = v; _update_shader_params()
@export var cloud_texture: Texture2D:
	set(v): cloud_texture = v; _update_shader_params()

@export_group("Sky Colors")
@export var zenith_color: Color = Color(0.05, 0.25, 0.88):
	set(v): zenith_color = v; _update_shader_params()
@export var mid_color: Color = Color(0.16, 0.50, 0.98):
	set(v): mid_color = v; _update_shader_params()
@export var horizon_color: Color = Color(0.45, 0.80, 1.0):
	set(v): horizon_color = v; _update_shader_params()
@export var haze_color: Color = Color(0.30, 0.62, 0.98):
	set(v): haze_color = v; _update_shader_params()

@export_group("Clouds & Sun")
@export_range(0.0, 1.0) var cloud_coverage: float = 0.56:
	set(v): cloud_coverage = v; _update_shader_params()
@export var sun_color: Color = Color(1.0, 0.93, 0.72):
	set(v): sun_color = v; _update_shader_params()
@export var sun_rotation: Vector3 = Vector3(-48.0, -35.0, 0.0):
	set(v):
		sun_rotation = v
		if is_instance_valid(_sun):
			_sun.rotation_degrees = sun_rotation

@export_group("Fog & Ambient")
@export var fog_color: Color = Color(0.65, 0.85, 1.0):
	set(v):
		fog_color = v
		if is_instance_valid(_env):
			_env.fog_light_color = fog_color
@export_range(0.0, 0.01, 0.0001) var fog_density: float = 0.0006:
	set(v):
		fog_density = v
		if is_instance_valid(_env):
			_env.fog_density = fog_density
@export var ambient_color: Color = Color(0.817, 0.879, 1.0, 0.549):
	set(v):
		ambient_color = v
		if is_instance_valid(_env):
			_env.ambient_light_color = ambient_color

var _we: WorldEnvironment
var _sun: DirectionalLight3D
var _env: Environment
var _mat: ShaderMaterial

func _ready() -> void:
	_rebuild_environment()

func _rebuild_environment() -> void:
	if is_instance_valid(_we):
		_we.queue_free()
	if is_instance_valid(_sun):
		_sun.queue_free()
	var sky := Sky.new()
	_mat = ShaderMaterial.new()
	_mat.shader = sky_shader
	sky.sky_material = _mat
	sky.radiance_size = Sky.RADIANCE_SIZE_32
	sky.process_mode = Sky.PROCESS_MODE_QUALITY
	_env = Environment.new()
	_env.background_mode = Environment.BG_SKY
	_env.sky = sky
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = ambient_color
	_env.ambient_light_energy = 0.55
	_env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	_env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	_env.tonemap_exposure = 1.0
	_env.adjustment_enabled = true
	_env.adjustment_saturation = 1.2
	_env.adjustment_contrast = 1.08
	_env.glow_enabled = true
	_env.glow_intensity = 0.35
	_env.glow_bloom = 0.15
	_env.glow_hdr_threshold = 0.9
	_env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	_env.fog_enabled = true
	_env.fog_light_color = fog_color
	_env.fog_density = fog_density
	_env.fog_sky_affect = 0.0
	_env.fog_sun_scatter = 0.0
	_we = WorldEnvironment.new()
	_we.environment = _env
	add_child(_we)
	_sun = DirectionalLight3D.new()
	_sun.rotation_degrees = sun_rotation
	_sun.light_color = Color(1.0, 0.94, 0.80)
	_sun.light_energy = 1.0
	_sun.shadow_enabled = true
	_sun.shadow_blur = 1.6
	_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	_sun.directional_shadow_max_distance = 120.0
	_sun.directional_shadow_blend_splits = true
	_sun.shadow_bias = 0.05
	_sun.shadow_normal_bias = 1.5
	add_child(_sun)
	_update_shader_params()

func _update_shader_params() -> void:
	if not is_instance_valid(_mat):
		return
	_mat.set_shader_parameter("zenith_color", zenith_color)
	_mat.set_shader_parameter("mid_color", mid_color)
	_mat.set_shader_parameter("horizon_color", horizon_color)
	_mat.set_shader_parameter("haze_color", haze_color)
	_mat.set_shader_parameter("cloud_coverage", cloud_coverage)
	_mat.set_shader_parameter("sun_color", sun_color)
	if sky_texture:
		_mat.set_shader_parameter("sky_texture", sky_texture)
		_mat.set_shader_parameter("sky_texture_mix", sky_texture_mix)
	else:
		_mat.set_shader_parameter("sky_texture_mix", 0.0)
	if cloud_texture:
		_mat.set_shader_parameter("cloud_texture", cloud_texture)
		_mat.set_shader_parameter("use_cloud_texture", true)
	else:
		_mat.set_shader_parameter("use_cloud_texture", false)

func _apply_preset(preset: ZonePreset) -> void:
	match preset:
		ZonePreset.APOTOS_DAY:
			zenith_color = Color(0.05, 0.25, 0.88)
			mid_color = Color(0.16, 0.50, 0.98)
			horizon_color = Color(0.45, 0.80, 1.0)
			haze_color = Color(0.30, 0.62, 0.98)
			sun_color = Color(1.0, 0.93, 0.72)
			fog_color = Color(0.65, 0.85, 1.0)
			ambient_color = Color(0.817, 0.879, 1.0, 0.549)
			sun_rotation = Vector3(-48.0, -35.0, 0.0)
			cloud_coverage = 0.56
		ZonePreset.SPAGONIA_SUNSET:
			zenith_color = Color(0.15, 0.22, 0.55)
			mid_color = Color(0.55, 0.35, 0.58)
			horizon_color = Color(1.0, 0.62, 0.28)
			haze_color = Color(0.95, 0.55, 0.30)
			sun_color = Color(1.0, 0.75, 0.40)
			fog_color = Color(0.95, 0.68, 0.45)
			ambient_color = Color(0.95, 0.78, 0.68, 0.6)
			sun_rotation = Vector3(-16.0, -60.0, 0.0)
			cloud_coverage = 0.48
		ZonePreset.HOLOSKA_DAY:
			zenith_color = Color(0.12, 0.45, 0.85)
			mid_color = Color(0.38, 0.72, 0.96)
			horizon_color = Color(0.78, 0.93, 1.0)
			haze_color = Color(0.70, 0.88, 0.98)
			sun_color = Color(0.95, 0.98, 1.0)
			fog_color = Color(0.82, 0.93, 1.0)
			ambient_color = Color(0.85, 0.94, 1.0, 0.7)
			sun_rotation = Vector3(-35.0, 25.0, 0.0)
			cloud_coverage = 0.40
		ZonePreset.WEREHOG_NIGHT:
			zenith_color = Color(0.02, 0.03, 0.12)
			mid_color = Color(0.06, 0.09, 0.28)
			horizon_color = Color(0.18, 0.22, 0.48)
			haze_color = Color(0.12, 0.15, 0.35)
			sun_color = Color(0.75, 0.85, 1.0)
			fog_color = Color(0.12, 0.16, 0.36)
			ambient_color = Color(0.35, 0.42, 0.75, 0.65)
			sun_rotation = Vector3(-40.0, 120.0, 0.0)
			cloud_coverage = 0.35
