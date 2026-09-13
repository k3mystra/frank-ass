class_name Monster
extends Node3D

# Actual level
@export var metrics: Array[Metric]
var metric_name_to_idx: Dictionary[String, int]
var is_maintained: Array[bool]

var is_alarm_active: bool = false

var critical_timers: Array[Timer] = []
var critical_state: Array[bool]


func _ready() -> void:
	critical_state.resize(metrics.size())
	critical_state.fill(false)

	is_maintained.resize(metrics.size())
	is_maintained.fill(false)

	EventBus.power_up.connect(_on_machine_power_up)
	EventBus.power_down.connect(_on_machine_power_down)

	const CRIT_TIMER_NAME = "CritTimer"
	for i in range(metrics.size()):
		var timer_name = CRIT_TIMER_NAME + str(i)

		var timer = Timer.new()
		timer.set_name(timer_name)
		timer.wait_time = GameConfig.CRITICAL_FAILURE_DURATION
		timer.one_shot = true

		add_child(timer)
		critical_timers.push_back(get_node(timer_name))

		metric_name_to_idx.set(metrics[i].name, i)


func toggle_alarm() -> void:
	is_alarm_active = not is_alarm_active
	if is_alarm_active:
		print("Alarm Active")
		EventBus.alarm_started.emit()
	else:
		EventBus.alarm_stopped.emit()
		print("Alarm Stop")


func toggle_critical(i: int) -> void:
	critical_state[i] = not critical_state[i]
	if critical_state[i]:
		print("%s is critical!" % metrics[i].name)
		critical_timers[i].start()
		EventBus.critical_started.emit(metrics[i].name)
	else:
		print("%s is normal" % metrics[i].name)
		critical_timers[i].stop()
		EventBus.critical_resolved.emit(metrics[i].name)


func _on_tick_timeout() -> void:
	var new_alarm_state = false
	for i in range(metrics.size()):
		if is_maintained[i]:
			new_alarm_state = metrics[i].inc_value() or new_alarm_state
		else:
			new_alarm_state = metrics[i].dec_value() or new_alarm_state

		EventBus.metric_updated.emit(metrics[i].name)

		var is_critical = metrics[i].value <= 0.0
		if critical_state[i] != is_critical:
			toggle_critical(i)

	if new_alarm_state != is_alarm_active:
		toggle_alarm()


func _on_machine_power_up(metric_name: String):
	var idx = metric_name_to_idx[metric_name]
	is_maintained[idx] = true


func _on_machine_power_down(metric_name: String):
	var idx = metric_name_to_idx[metric_name]
	is_maintained[idx] = false
