class_name BatteryPickup
extends "res://scripts/interactables/interactable.gd"

const BatteryDataClass = preload("res://resources/data/battery_data.gd")

@export var battery_data: Resource

@onready var anim_player: AnimationPlayer = find_child("AnimationPlayer", true, false) as AnimationPlayer
@onready var core_mesh: MeshInstance3D = find_child("Battery_001", true, false) as MeshInstance3D

var _thrower_node: Node = null

func _ready() -> void:
	if battery_data == null:
		battery_data = BatteryDataClass.new(100.0)

	if highlight_mesh == null:
		var casing = find_child("Battery", true, false)
		if casing is MeshInstance3D:
			highlight_mesh = casing as MeshInstance3D

	if core_mesh == null:
		core_mesh = find_child("Battery.001", true, false) as MeshInstance3D

	assert(anim_player != null and anim_player.has_animation("Battery_Charges"), "CRITICAL: Animation 'Battery_Charges' not found on battery model!")

	update_visual_indicator()

func get_interaction_prompt(_player: Node = null) -> String:
	return "E - Pick up Battery"

func interact(player: Node) -> void:
	if player == null or not player.has_node("Inventory"):
		return

	var inv = player.get_node("Inventory")
	if inv != null and inv.has_method("add_item"):
		if inv.add_item(battery_data):
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

func update_visual_indicator() -> void:
	if battery_data == null:
		return

	var blocks_lit: int = battery_data.get_blocks_lit()

	# This was according to the blender fbx file
	const CHARGE_KEYFRAME_TIMES: Array[float] = [0.0417, 0.0833, 0.1250, 0.1667, 0.2083]

	if blocks_lit <= 0:
		if core_mesh != null:
			core_mesh.visible = false
	else:
		if core_mesh != null:
			core_mesh.visible = true
		var target_index: int = clampi(blocks_lit, 0, CHARGE_KEYFRAME_TIMES.size() - 1)
		var target_time: float = CHARGE_KEYFRAME_TIMES[target_index]
		anim_player.play("Battery_Charges")
		anim_player.seek(target_time, true)
		anim_player.pause()
