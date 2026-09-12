class_name Door
extends Node3D

signal door_opened
signal door_closed
signal key_inserted(key_data: KeyData)
signal key_removed(key_data: KeyData)

const KeyPickupClass = preload("res://scripts/interactables/key_pickup.gd")

@export var required_keys: Array[KeyData] = []
@export var open_angle_deg: float = 90.0
@export var open_duration: float = 0.8
@export var is_open: bool = false

@onready var hinge_pivot: Node3D = find_child("HingePivot", true, false)

var slotted_keys: Dictionary[StringName, KeyData] = {}
var slotted_key_sides: Dictionary[StringName, bool] = {}
var _tween: Tween = null
var _key_visual_instances: Array[Node] = []

func _ready() -> void:
	if is_open:
		if hinge_pivot == null:
			push_error("no pivot provided")
		else:
			hinge_pivot.rotation.y = deg_to_rad(open_angle_deg)
	_update_key_visuals()

func _is_key_needed(key: KeyData) -> bool:
	if key == null:
		return false
	if slotted_keys.has(key.key_id):
		return false
	for req in required_keys:
		if req != null and req.key_id == key.key_id:
			return true
	return false

func _are_all_required_keys_slotted() -> bool:
	if required_keys.is_empty():
		return true
	for req in required_keys:
		if req != null and not slotted_keys.has(req.key_id):
			return false
	return true

func get_interaction_prompt(player: Node = null) -> String:
	if not slotted_keys.is_empty():
		if player != null and player.has_node("Inventory"):
			var inv = player.get_node("Inventory")
			if inv != null and inv.has_method("is_full") and inv.is_full():
				return "" 
		var first_key: KeyData = slotted_keys.values()[0]
		return "E - Take " + first_key.display_name

	if not is_open:
		if player != null and player.has_node("Inventory"):
			var inv = player.get_node("Inventory")
			if inv != null and inv.has_method("get_active_item"):
				var active = inv.get_active_item()
				if active is KeyData:
					var key_candidate = active as KeyData
					if _is_key_needed(key_candidate):
						return "E - Unlock with " + key_candidate.display_name
		return "Locked. A key is needed"

	return ""

func get_knob_interaction_prompt(player: Node, _knob: Node) -> String:
	return get_interaction_prompt(player)

func interact_from_side(player: Node, is_front: bool) -> void:
	if player == null or not player.has_node("Inventory"):
		return
	var inv = player.get_node("Inventory")
	if inv == null:
		return

	if not slotted_keys.is_empty():
		if inv.has_method("is_full") and inv.is_full():
			return
		var key_to_take: KeyData = slotted_keys.values()[0]
		if inv.has_method("add_item") and inv.add_item(key_to_take):
			_unslot_key(key_to_take.key_id)
		return

	if not is_open:
		if inv.has_method("get_active_item"):
			var active = inv.get_active_item()
			if active is KeyData:
				var key_candidate = active as KeyData
				if _is_key_needed(key_candidate):
					if inv.has_method("remove_active_item"):
						inv.remove_active_item()
					slot_key(key_candidate, is_front)

func interact_with_knob(player: Node, knob: Node) -> void:
	var is_front = true
	if knob != null and knob.name.to_lower().contains("back"):
		is_front = false
	interact_from_side(player, is_front)

func on_door_body_entered(body: Node, is_front: bool) -> void:
	if body is KeyPickupClass:
		var pickup = body as KeyPickupClass
		if pickup.key_data != null and _is_key_needed(pickup.key_data):
			var key = pickup.key_data
			pickup.queue_free()
			slot_key(key, is_front)

func on_knob_body_entered(body: Node, knob: Node) -> void:
	var is_front = true
	if knob != null and knob.name.to_lower().contains("back"):
		is_front = false
	on_door_body_entered(body, is_front)

func slot_key(key: KeyData, is_front_or_knob = true) -> bool:
	if key == null:
		return false
	var is_front = true
	if is_front_or_knob is bool:
		is_front = is_front_or_knob
	elif is_front_or_knob is Node:
		is_front = not (is_front_or_knob as Node).name.to_lower().contains("back")

	slotted_keys[key.key_id] = key
	slotted_key_sides[key.key_id] = is_front
	key_inserted.emit(key)
	_update_key_visuals()

	if _are_all_required_keys_slotted():
		open_door(is_front)
	return true

func _unslot_key(key_id: StringName) -> KeyData:
	if not slotted_keys.has(key_id):
		return null
	var removed = slotted_keys[key_id]
	slotted_keys.erase(key_id)
	slotted_key_sides.erase(key_id)
	key_removed.emit(removed)
	_update_key_visuals()

	if slotted_keys.is_empty() and is_open:
		close_door()
	return removed

func open_door(from_front: bool = true) -> void:
	if is_open:
		return
	is_open = true
	door_opened.emit()
	var angle_deg: float = open_angle_deg if from_front else -open_angle_deg
	_animate_hinge(deg_to_rad(angle_deg))

func close_door() -> void:
	if not is_open:
		return
	is_open = false
	door_closed.emit()
	_animate_hinge(0.0)

func _animate_hinge(target_rot_y: float) -> void:
	var pivot = hinge_pivot if hinge_pivot != null else self
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(pivot, "rotation:y", target_rot_y, open_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _update_key_visuals() -> void:
	for inst in _key_visual_instances:
		if is_instance_valid(inst):
			inst.queue_free()
	_key_visual_instances.clear()

	var front_mount: Node3D = find_child("KeyMountFront", true, false) as Node3D
	var back_mount: Node3D = find_child("KeyMountBack", true, false) as Node3D

	if slotted_keys.is_empty():
		if front_mount != null:
			front_mount.visible = false
		if back_mount != null:
			back_mount.visible = false
		return

	var has_front_key: bool = false
	var has_back_key: bool = false

	if front_mount != null or back_mount != null:
		for key in slotted_keys.values():
			if key == null or key.model_scene == null:
				continue

			var is_front: bool = slotted_key_sides.get(key.key_id, true)
			var target_mount: Node3D = front_mount if is_front else back_mount
			if target_mount == null:
				target_mount = front_mount if front_mount != null else back_mount

			if is_front:
				has_front_key = true
			else:
				has_back_key = true

			if target_mount != null:
				var model = key.model_scene.instantiate()
				target_mount.add_child(model)
				_key_visual_instances.push_back(model)

		if front_mount != null:
			front_mount.visible = has_front_key
		if back_mount != null:
			back_mount.visible = has_back_key
	else:
		var generic_mounts = find_children("KeyMount*", "", true, false)
		for mount in generic_mounts:
			if mount is Node3D:
				for key in slotted_keys.values():
					if key != null and key.model_scene != null:
						var model = key.model_scene.instantiate()
						mount.add_child(model)
						_key_visual_instances.push_back(model)
