class_name KeyData
extends Resource

@export var key_id: StringName = &""
@export var display_name: String = ""
@export var icon: Texture2D = null
@export var model_scene: PackedScene = null

func _init(p_id: StringName = &"", p_name: String = "", p_icon: Texture2D = null, p_model: PackedScene = null) -> void:
	key_id = p_id
	display_name = p_name
	icon = p_icon
	model_scene = p_model

