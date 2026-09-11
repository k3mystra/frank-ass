class_name Metric
extends Resource

@export var name: String = ""
@export var value: float = 0
@export var alarm_treshold: float = 0

# percent-decrease per second
@export var regress_rate: float = 0


func _init(p_name = "", p_value = 0, p_alarm_treshold = 0, p_regress_rate = 0) -> void:
	name = p_name
	value = p_value
	alarm_treshold = p_alarm_treshold
	regress_rate = p_regress_rate


# Return true if need to turn on alarm
func dec_value() -> bool:
	value -= regress_rate
	return value <= alarm_treshold


func inc_value() -> bool:
	value += regress_rate
	return value <= alarm_treshold
