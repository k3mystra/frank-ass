class_name Metric
extends Resource

@export var name: String = ""
@export var value: float = 0
@export var alarm_treshold: float = 0


func _init(p_name = "", p_value = GameConfig.METRIC_MAX_CAPACITY, p_alarm_treshold = 0) -> void:
	name = p_name
	value = p_value
	alarm_treshold = p_alarm_treshold


# Return true if need to turn on alarm
func dec_value() -> bool:
	value = max(0, value - GameConfig.METRIC_UNPOWERED_DRAIN_RATE)
	return value <= alarm_treshold


func inc_value() -> bool:
	value = min(GameConfig.METRIC_MAX_CAPACITY, value + GameConfig.METRIC_POWERED_RECOVERY_RATE)
	return value <= alarm_treshold
