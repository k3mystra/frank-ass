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
	var active_key: KeyData = null
	var is_inv_full: bool = false

	if player != null and player.has_node("Inventory"):
		var inv = player.get_node("Inventory")
		if inv != null:
			if inv.has_method("is_full"):
				is_inv_full = inv.is_full()
			if inv.has_method("get_active_item"):
				var active = inv.get_active_item()
				if active is KeyData:
					active_key = active as KeyData

	if not is_open:
		if active_key != null and _is_key_needed(active_key):
			return "E - Unlock with " + active_key.display_name

		if not slotted_keys.is_empty():
			var missing_keys = _get_missing_keys()
			var missing_name: String = "A key"
			if not missing_keys.is_empty() and missing_keys[0] != null:
				missing_name = missing_keys[0].display_name

			if is_inv_full:
				return "(Locked. " + missing_name + " is needed)"
			return "E - Take key\n(Locked. " + missing_name + " is needed)"

		return "Locked. A key is needed"

	if not slotted_keys.is_empty():
		if is_inv_full:
			return ""
		var key_to_take: KeyData = slotted_keys.values().back()
		return "E - Take " + key_to_take.display_name

	return ""

func get_knob_interaction_prompt(player: Node, _knob: Node) -> String:
	return get_interaction_prompt(player)

func interact_from_side(player: Node, is_front: bool) -> void:
	if player == null or not player.has_node("Inventory"):
		return
	var inv = player.get_node("Inventory")
	if inv == null:
		return

	if not is_open and inv.has_method("get_active_item"):
		var active = inv.get_active_item()
		if active is KeyData:
			var key_candidate = active as KeyData
			if _is_key_needed(key_candidate):
				if inv.has_method("remove_active_item"):
					inv.remove_active_item()
				slot_key(key_candidate, is_front)
				return

	if not slotted_keys.is_empty():
		if inv.has_method("is_full") and inv.is_full():
			return
		var key_to_take: KeyData = slotted_keys.values().back()
		if inv.has_method("add_item") and inv.add_item(key_to_take):
			_unslot_key(key_to_take.key_id)
		return

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

	var front_mounts: Array[Node3D] = _get_mounts("KeyMountFront")
	var back_mounts: Array[Node3D] = _get_mounts("KeyMountBack")

	for m in front_mounts:
		m.visible = false
	for m in back_mounts:
		m.visible = false

	if slotted_keys.is_empty():
		return

	var front_idx: int = 0
	var back_idx: int = 0

	for key in slotted_keys.values():
		if key == null or key.model_scene == null:
			continue

		var is_front: bool = slotted_key_sides.get(key.key_id, true)
		var target_mount: Node3D = null

		if is_front:
			if front_idx < front_mounts.size():
				target_mount = front_mounts[front_idx]
				front_idx += 1
			elif not front_mounts.is_empty():
				target_mount = front_mounts.back()
		else:
			if back_idx < back_mounts.size():
				target_mount = back_mounts[back_idx]
				back_idx += 1
			elif not back_mounts.is_empty():
				target_mount = back_mounts.back()

		if target_mount != null:
			target_mount.visible = true
			var model = key.model_scene.instantiate()
			target_mount.add_child(model)
			_key_visual_instances.push_back(model)

func _get_missing_keys() -> Array[KeyData]:
	var missing: Array[KeyData] = []
	for req in required_keys:
		if req != null and not slotted_keys.has(req.key_id):
			missing.push_back(req)
	return missing

func _get_mounts(prefix: String) -> Array[Node3D]:
	var mounts: Array[Node3D] = []
	var all_children = find_children(prefix + "*", "", true, false)
	all_children.sort_custom(func(a, b):
		return a.name.naturalnocasecmp_to(b.name) < 0
	)
	for node in all_children:
		if node is Node3D:
			mounts.push_back(node as Node3D)
	return mounts
