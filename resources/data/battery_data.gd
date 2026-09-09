class_name BatteryData
extends Resource

@export var id: String = ""
@export_range(0.0, 100.0) var charge: float = 100.0

func _init(p_charge: float = 100.0, p_id: String = "") -> void:
	charge = clampf(p_charge, 0.0, 100.0)
	if p_id.is_empty():
		id = "battery_" + str(ResourceUID.create_id())
	else:
		id = p_id

func get_blocks_lit() -> int:
	if charge > 75.0:
		return 4
	elif charge > 50.0:
		return 3
	elif charge > 25.0:
		return 2
	elif charge > 0.0:
		return 1
	else:
		return 0


func is_depleted() -> bool:
	return charge <= 0.0

func duplicate_data() -> Resource:
	var copy = duplicate()
	return copy

