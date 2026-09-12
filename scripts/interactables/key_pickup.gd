class_name KeyPickup
extends "res://scripts/interactables/interactable.gd"

@export var key_data: KeyData = null
@export var model_scale: Vector3 = Vector3(2.0, 2.0, 2.0)

var _thrower_node: Node = null
var _model_instance: Node3D = null

func _ready() -> void:
	_update_model()

func set_key_data(data: KeyData) -> void:
	key_data = data
	_update_model()

func _update_model() -> void:
	if _model_instance != null:
		_model_instance.queue_free()
		_model_instance = null

	if key_data != null and key_data.model_scene != null:
		_model_instance = key_data.model_scene.instantiate()
		_model_instance.scale = model_scale
		add_child(_model_instance)
		var mesh_inst = _find_mesh_instance(_model_instance)
		if mesh_inst != null:
			highlight_mesh = mesh_inst

func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var found = _find_mesh_instance(child)
		if found != null:
			return found
	return null

func get_interaction_prompt(_player: Node = null) -> String:
	var key_name: String = key_data.display_name if key_data != null and not key_data.display_name.is_empty() else "Key"
	return "E - Pick up " + key_name

func interact(player: Node) -> void:
	if player == null or not player.has_node("Inventory"):
		return

	var inv = player.get_node("Inventory")
	if inv != null and inv.has_method("add_item"):
		if inv.add_item(key_data):
			queue_free()

func throw(impulse: Vector3, torque: Vector3, thrower: Node = null) -> void:
	if thrower is CollisionObject3D:
		_thrower_node = thrower
		call("add_collision_exception_with", thrower)
		if not is_connected("body_entered", _on_body_entered_after_throw):
			connect("body_entered", _on_body_entered_after_throw)

	call("apply_central_impulse", impulse)
	call("apply_torque_impulse", torque)

func _on_body_entered_after_throw(body: Node) -> void:
	if body != _thrower_node:
		if _thrower_node is CollisionObject3D and is_instance_valid(_thrower_node):
			call("remove_collision_exception_with", _thrower_node)
		_thrower_node = null
		if is_connected("body_entered", _on_body_entered_after_throw):
			disconnect("body_entered", _on_body_entered_after_throw)
