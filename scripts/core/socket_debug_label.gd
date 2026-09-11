extends Label3D

const BatteryDataClass = preload("res://resources/data/battery_data.gd")

@export var target_socket: BatterySocket

func _ready() -> void:
	if target_socket == null:
		push_error("SocketDebugLabel: target_socket is null!")
		assert(target_socket != null, "SocketDebugLabel: target_socket is null!")
		return

	target_socket.battery_attached.connect(_on_battery_attached)
	target_socket.battery_detached.connect(_on_battery_detached)
	target_socket.battery_depleted.connect(_on_battery_depleted)

	if target_socket.has_battery():
		_on_battery_attached(target_socket.get_battery())
	else:
		_update_debug_text("Detached")

func _on_battery_attached(battery: Resource) -> void:
	if _is_battery_empty(battery):
		_update_debug_text("Empty")
	else:
		_update_debug_text("Attached")

func _on_battery_detached(_battery: Resource) -> void:
	_update_debug_text("Detached")

func _on_battery_depleted(_battery: Resource) -> void:
	_update_debug_text("Empty")

func _is_battery_empty(battery: Resource) -> bool:
	if battery is BatteryDataClass:
		return (battery as BatteryDataClass).is_depleted()
	elif "charge" in battery:
		return battery.charge <= 0.0
	return true

func _update_debug_text(status: String) -> void:
	text = status
	match status:
		"Attached":
			modulate = Color(0.2, 1.0, 0.4) # Green
		"Empty":
			modulate = Color(1.0, 0.25, 0.25) # Red
		"Detached":
			modulate = Color(0.7, 0.7, 0.7) # Grey
