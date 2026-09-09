class_name Inventory
extends Node


const MAX_SLOTS: int = 3
const BatteryPickupScene = preload("res://scenes/props/battery_pickup.tscn")

var slots: Array = [null, null, null]
var active_slot_index: int = 0

func _ready() -> void:
	EventBus.active_slot_changed.emit(active_slot_index, get_active_item())
	EventBus.inventory_updated.emit(slots)

func _unhandled_input(event: InputEvent) -> void:
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
	var pickup = BatteryPickupScene.instantiate()
	pickup.battery_data = removed_item

	player.get_parent().add_child(pickup)

	# Raycast from camera to place cleanly on the aimed surface (table top, floor)
	var head = player.get_node_or_null("Head")
	var cam: Camera3D = head.get_node_or_null("Camera3D") as Camera3D if head != null else null
	var space_state = player.get_world_3d().direct_space_state
	var drop_pos: Vector3

	if cam != null and space_state != null:
		var cam_pos = cam.global_position
		var cam_forward = -cam.global_transform.basis.z

		# Check if looking at a surface within 2.5m (table, pedestal, floor)
		var query = PhysicsRayQueryParameters3D.create(cam_pos, cam_pos + cam_forward * 2.5)
		query.exclude = [player.get_rid()]
		var hit = space_state.intersect_ray(query)

		if hit:
			if hit.normal.y >= 0.7:
				# Upward-facing horizontal surface (table top, floor, shelf)
				drop_pos = hit.position
			else:
				# Vertical wall or table side: drop down to floor at the base of the wall
				var wall_offset = hit.position + hit.normal * 0.25
				var down_query = PhysicsRayQueryParameters3D.create(wall_offset, wall_offset + Vector3.DOWN * 5.0)
				down_query.exclude = [player.get_rid()]
				var floor_hit = space_state.intersect_ray(down_query)
				if floor_hit:
					drop_pos = floor_hit.position
				else:
					drop_pos = player.global_position + (-player.global_transform.basis.z * 0.8)
		else:
			# If looking forward into open air, drop 1.2m ahead and find floor beneath
			var air_point = cam_pos + cam_forward * 1.2
			var down_query = PhysicsRayQueryParameters3D.create(air_point, air_point + Vector3.DOWN * 4.0)
			down_query.exclude = [player.get_rid()]
			var floor_hit = space_state.intersect_ray(down_query)
			if floor_hit:
				drop_pos = floor_hit.position
			else:
				drop_pos = player.global_position + (-player.global_transform.basis.z * 1.0)
	else:
		drop_pos = player.global_position + (-player.global_transform.basis.z * 1.0)

	pickup.global_position = drop_pos
