@tool
class_name LightBulb
extends Node3D

signal light_toggled(is_on: bool)

@export var is_on: bool = true:
	set(value):
		is_on = value
		_update_state()

@export_group("Light Settings")
@export var light_color: Color = Color(0.517647, 0.815686, 0.682353, 1.0):
	set(value):
		light_color = value
		_apply_light_settings()

@export var light_energy: float = 0.5:
	set(value):
		light_energy = value
		_apply_light_settings()

@export var omni_range: float = 8.0:
	set(value):
		omni_range = value
		_apply_light_settings()

@export var omni_attenuation: float = 0.5:
	set(value):
		omni_attenuation = value
		_apply_light_settings()

@export var shadow_enabled: bool = true:
	set(value):
		shadow_enabled = value
		_apply_light_settings()

@export var shadow_blur: float = 2.0:
	set(value):
		shadow_blur = value
		_apply_light_settings()

@export_group("Material Overrides")
@export var bulb_material_override: Material = null:
	set(value):
		bulb_material_override = value
		_apply_materials()

@export var pole_material_override: Material = null:
	set(value):
		pole_material_override = value
		_apply_materials()

@onready var omni_light: OmniLight3D = find_child("OmniLight3D", true, false) as OmniLight3D
@onready var bulb_mesh: MeshInstance3D = find_child("light_bulb_bulb_0", true, false) as MeshInstance3D
@onready var pole_mesh: MeshInstance3D = find_child("light_pole_light_bulb_0", true, false) as MeshInstance3D

var _bulb_material: StandardMaterial3D = null

func _ready() -> void:
	_init_nodes()
	_apply_materials()
	_apply_light_settings()
	_update_state()

func _init_nodes() -> void:
	if omni_light == null:
		omni_light = find_child("OmniLight3D", true, false) as OmniLight3D
		if omni_light == null:
			var lights = find_children("*", "OmniLight3D", true, false)
			if lights.size() > 0:
				omni_light = lights[0] as OmniLight3D

	if bulb_mesh == null:
		bulb_mesh = find_child("light_bulb_bulb_0", true, false) as MeshInstance3D
		if bulb_mesh == null:
			bulb_mesh = find_child("*bulb*", true, false) as MeshInstance3D

	if pole_mesh == null:
		pole_mesh = find_child("light_pole_light_bulb_0", true, false) as MeshInstance3D
		if pole_mesh == null:
			pole_mesh = find_child("*pole*", true, false) as MeshInstance3D

	if bulb_mesh != null and bulb_material_override == null:
		var mat = bulb_mesh.get_surface_override_material(0)
		if mat is StandardMaterial3D:
			if not Engine.is_editor_hint():
				_bulb_material = mat.duplicate() as StandardMaterial3D
				bulb_mesh.set_surface_override_material(0, _bulb_material)
			else:
				_bulb_material = mat
		elif bulb_mesh.material_override is StandardMaterial3D:
			if not Engine.is_editor_hint():
				_bulb_material = bulb_mesh.material_override.duplicate() as StandardMaterial3D
				bulb_mesh.material_override = _bulb_material
			else:
				_bulb_material = bulb_mesh.material_override

func _apply_light_settings() -> void:
	if not is_inside_tree():
		return
	_init_nodes()

	if omni_light != null:
		omni_light.light_color = light_color
		omni_light.light_energy = light_energy if is_on else 0.0
		omni_light.omni_range = omni_range
		omni_light.omni_attenuation = omni_attenuation
		omni_light.shadow_enabled = shadow_enabled
		omni_light.shadow_blur = shadow_blur

	var mat = bulb_material_override as StandardMaterial3D if bulb_material_override is StandardMaterial3D else _bulb_material
	if mat != null:
		mat.emission = light_color

func _apply_materials() -> void:
	if not is_inside_tree():
		return
	_init_nodes()

	if bulb_mesh != null:
		if bulb_material_override != null:
			bulb_mesh.set_surface_override_material(0, bulb_material_override)
		elif _bulb_material != null:
			bulb_mesh.set_surface_override_material(0, _bulb_material)

	if pole_mesh != null:
		pole_mesh.set_surface_override_material(0, pole_material_override)

	_apply_light_settings()

func turn_on() -> void:
	is_on = true

func turn_off() -> void:
	is_on = false

func toggle() -> void:
	is_on = not is_on

func set_is_on(value: bool) -> void:
	is_on = value

func _update_state() -> void:
	if not is_inside_tree():
		return

	if omni_light != null:
		omni_light.visible = is_on
		omni_light.light_energy = light_energy if is_on else 0.0

	var mat = bulb_material_override as StandardMaterial3D if bulb_material_override is StandardMaterial3D else _bulb_material
	if mat != null:
		mat.emission_enabled = is_on

	light_toggled.emit(is_on)
