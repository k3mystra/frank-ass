class_name Inventory
extends Node


const MAX_SLOTS: int = 3
const BatteryPickupScene = preload("res://scenes/props/battery_pickup.tscn")
const KeyPickupScene = preload("res://scenes/props/key_pickup.tscn")

var slots: Array = [null, null, null]
var active_slot_index: int = 0

func _ready() -> void:
	EventBus.active_slot_changed.emit(active_slot_index, get_active_item())
	EventBus.inventory_updated.emit(slots)

func _unhandled_input(event: InputEvent) -> void:
	var player = owner as PlayerController
	if player != null and player.has_method("is_camera_focused") and player.is_camera_focused():
		return

	if event.is_action_pressed("slot_1"):
		set_active_slot(0)
	elif event.is_action_pressed("slot_2"):
		set_active_slot(1)
	elif event.is_action_pressed("slot_3"):
		set_active_slot(2)
	elif event.is_action_pressed("slot_next"):
		cycle_slot(1)
	elif event.is_action_pressed("slot_prev"):
		cycle_slot(-1)
	elif event.is_action_pressed("drop_item") or (event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_Q):
		drop_active_item()

func cycle_slot(direction: int) -> void:
	active_slot_index = (active_slot_index + direction) % MAX_SLOTS
	if active_slot_index < 0:
		active_slot_index += MAX_SLOTS
	EventBus.active_slot_changed.emit(active_slot_index, get_active_item())

func set_active_slot(index: int) -> void:
	if index >= 0 and index < MAX_SLOTS:
		active_slot_index = index
		EventBus.active_slot_changed.emit(active_slot_index, get_active_item())

func get_active_item() -> Resource:
	return slots[active_slot_index]

func set_active_item(item: Resource) -> void:
	slots[active_slot_index] = item
	EventBus.active_slot_changed.emit(active_slot_index, item)
	EventBus.inventory_updated.emit(slots)

func remove_active_item() -> Resource:
	var item: Resource = slots[active_slot_index]
	slots[active_slot_index] = null
	EventBus.active_slot_changed.emit(active_slot_index, null)
	EventBus.inventory_updated.emit(slots)
	return item

func add_item(item: Resource) -> bool:
	if item == null:
		return false

	if slots[active_slot_index] == null:
		set_active_item(item)
		return true

	for i in range(MAX_SLOTS):
		if slots[i] == null:
			slots[i] = item
			EventBus.inventory_updated.emit(slots)
			return true

	return false

func is_full() -> bool:
	for slot in slots:
		if slot == null:
			return false
	return true

func drop_active_item() -> void:
	var item = get_active_item()
	if item == null:
		return

	var player = owner as CharacterBody3D
	if player == null or not player.is_inside_tree():
		return

	var removed_item = remove_active_item()
	var pickup = null
	if removed_item is KeyData:
		pickup = KeyPickupScene.instantiate()
		pickup.set_key_data(removed_item)
	else:
		pickup = BatteryPickupScene.instantiate()
		pickup.battery_data = removed_item

	var head = player.get_node_or_null("Head")
	var cam: Camera3D = head.get_node_or_null("Camera3D") as Camera3D if head != null else null
	var space_state = player.get_world_3d().direct_space_state

	var cam_pos: Vector3 = cam.global_position if cam != null else (player.global_position + Vector3.UP * 1.5)
	var cam_forward: Vector3 = -cam.global_transform.basis.z if cam != null else -player.global_transform.basis.z

	# Safe spawn distance check (ensure we don't spawn inside a wall at point-blank range)
	var spawn_dist: float = 0.45
	if space_state != null:
		var wall_query = PhysicsRayQueryParameters3D.create(cam_pos, cam_pos + cam_forward * 0.5)
		wall_query.exclude = [player.get_rid()]
		var wall_hit = space_state.intersect_ray(wall_query)
		if wall_hit:
			spawn_dist = maxf(0.1, cam_pos.distance_to(wall_hit.position) - 0.1)

	var spawn_pos: Vector3 = cam_pos + cam_forward * spawn_dist

	player.get_parent().add_child(pickup)
	pickup.global_position = spawn_pos

	# Calculate throw impulse and slight random tumble torque
	var throw_impulse: Vector3 = cam_forward * 5.2 + Vector3.UP * 1.6
	var tumble_torque: Vector3 = Vector3(
		randf_range(-1.2, 1.2),
		randf_range(-1.2, 1.2),
		randf_range(-1.2, 1.2)
	)

	if pickup.has_method("throw"):
		pickup.throw(throw_impulse, tumble_torque, player)
	elif pickup is RigidBody3D:
		pickup.apply_central_impulse(throw_impulse)
		pickup.apply_torque_impulse(tumble_torque)
