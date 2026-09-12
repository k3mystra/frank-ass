class_name BatteryRack
extends BatterySocket

func _init() -> void:
	is_draining = false
	prompt_text = "Store Battery"

func get_interaction_prompt(player: Node = null) -> String:
	if installed_battery == null:
		if player != null and player.has_node("Inventory"):
			var inv = player.get_node("Inventory")
			if inv != null and inv.has_method("get_active_item"):
				var active = inv.get_active_item()
				if active is BatteryDataClass:
					return "E - Store Battery"
		return "Store Battery"
	else:
		if player != null and player.has_node("Inventory"):
			var inv = player.get_node("Inventory")
			if inv != null and inv.has_method("is_full") and inv.is_full():
				return ""
		return "E - Take Battery"

