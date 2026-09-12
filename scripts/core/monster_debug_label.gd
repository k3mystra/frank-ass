extends Label3D

@export var monster: Monster


func _process(_dt) -> void:
	_update_text()


func _update_text() -> void:
	text = "STATS\n"
	text += "Alarm state: " + ("ON" if monster.is_alarm_active else "OFF") + '\n'

	text += '\n'
	for i in range(monster.metrics.size()):
		text += monster.metrics[i].name + ": "
		text += str(monster.metrics[i].value)
		if monster.critical_state[i]:
			text += " [CRITICAL]"
		text += '\n'
