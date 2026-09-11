class_name BatterySocket
extends "res://scripts/interactables/interactable.gd"

signal battery_attached(battery_data: Resource)
signal battery_detached(battery_data: Resource)
signal battery_depleted(battery_data: Resource)

const BatteryDataClass = preload("res://resources/data/battery_data.gd")
const BatteryPickupClass = preload("res://scripts/interactables/battery_pickup.gd")
const CHARGE_KEYFRAME_TIMES: Array[float] = [0.0417, 0.0833, 0.1250, 0.1667, 0.2083]

@export var socket_id: StringName = &""
@export var is_draining: bool = true
@export var drain_rate: float = 1.6667 
@export var starting_battery: Resource = null

@onready var battery_model: Node3D = $BatteryModel
@onready var anim_player: AnimationPlayer = find_child("AnimationPlayer", true, false) as AnimationPlayer
@onready var core_mesh: MeshInstance3D = find_child("Battery_001", true, false) as MeshInstance3D
@onready var battery_collision: CollisionShape3D = find_child("BatteryCollision", true, false) as CollisionShape3D
@onready var throw_hitbox: CollisionShape3D = find_child("ThrowHitBox", true, false) as CollisionShape3D

var installed_battery: Resource = null
var _last_blocks_lit: int = -1

func _ready() -> void:
	if has_signal("body_entered") and not is_connected("body_entered", _on_body_entered):
		connect("body_entered", _on_body_entered)

	if core_mesh == null:
		core_mesh = find_child("Battery.001", true, false) as MeshInstance3D

	if starting_battery != null:
		install_battery(starting_battery)
	else:
		_update_collision_state()
		_update_visuals()

func _on_body_entered(body: Node3D) -> void:
	if installed_battery != null:
		return

	if body.is_queued_for_deletion():
		return

	if body is BatteryPickupClass:
		var pickup = body as BatteryPickupClass
		if pickup.battery_data != null:
			install_battery(pickup.battery_data)
			pickup.queue_free()

func _process(delta: float) -> void:
	if installed_battery == null:
		return

	if is_draining and installed_battery.charge > 0.0:
		installed_battery.charge = maxf(0.0, installed_battery.charge - delta * drain_rate)
		_update_visuals()

		if installed_battery.charge <= 0.0:
			battery_depleted.emit(installed_battery)

func get_interaction_prompt(player: Node = null) -> String:
	if installed_battery == null:
		if player != null and player.has_node("Inventory"):
			var inv = player.get_node("Inventory")
			if inv != null and inv.has_method("get_active_item"):
				var active = inv.get_active_item()
				if active is BatteryDataClass:
					return "E - Insert Battery"
		return "Insert Battery"
	else:
		if player != null and player.has_node("Inventory"):
			var inv = player.get_node("Inventory")
			if inv != null and inv.has_method("is_full") and inv.is_full():
				return ""
		return "E - Take Battery"

func interact(player: Node) -> void:
	if player == null or not player.has_node("Inventory"):
		push_error("battery_socket: player is null")
		return

	var inv = player.get_node("Inventory")
	if inv == null:
		push_error("battery_socket: player inventory is non-existent")
		return

	if installed_battery == null:
		var active = inv.get_active_item()
		if active is BatteryDataClass:
			inv.remove_active_item()
			install_battery(active)
	else:
		var battery_to_take = installed_battery
		if inv.has_method("add_item") and inv.add_item(battery_to_take):
			remove_battery()

func install_battery(battery: Resource) -> bool:
	if installed_battery != null or battery == null:
		return false

	installed_battery = battery
	_last_blocks_lit = -1
	_update_collision_state()
	_update_visuals()

	battery_attached.emit(installed_battery)
	EventBus.battery_installed.emit(socket_id, installed_battery)
	return true

func remove_battery() -> Resource:
	if installed_battery == null:
		return null

	var removed = installed_battery
	installed_battery = null
	_last_blocks_lit = -1
	_update_collision_state()
	_update_visuals()

	battery_detached.emit(removed)
	EventBus.battery_removed.emit(socket_id)
	return removed

func _update_collision_state() -> void:
	if battery_collision != null:
		battery_collision.set_deferred("disabled", installed_battery == null)
	if throw_hitbox != null:
		throw_hitbox.set_deferred("disabled", installed_battery == null)

func has_battery() -> bool:
	return installed_battery != null

func get_battery() -> Resource:
	return installed_battery

func _update_visuals() -> void:
	if battery_model == null:
		return

	if installed_battery == null:
		battery_model.visible = false
		return

	battery_model.visible = true

	var blocks_lit: int = 0
	if installed_battery is BatteryDataClass:
		blocks_lit = (installed_battery as BatteryDataClass).get_blocks_lit()
	elif "charge" in installed_battery:
		blocks_lit = clampi(int(installed_battery.charge / 25.0) + 1, 0, 4) if installed_battery.charge > 0.0 else 0

	if blocks_lit != _last_blocks_lit:
		_last_blocks_lit = blocks_lit

		if blocks_lit <= 0:
			if core_mesh != null:
				core_mesh.visible = false
		else:
			if core_mesh != null:
				core_mesh.visible = true

			var target_index: int = clampi(blocks_lit, 0, CHARGE_KEYFRAME_TIMES.size() - 1)
			var target_time: float = CHARGE_KEYFRAME_TIMES[target_index]
			if anim_player != null and anim_player.has_animation("Battery_Charges"):
				anim_player.play("Battery_Charges")
				anim_player.seek(target_time, true)
				anim_player.pause()
