extends Node3D

# Actual level
@export var metrics: Array[Metric]

@export var critical_state: Array[bool]
@export var is_alarm_active: bool = false

func _ready() -> void:
    critical_state.resize(metrics.size())
    critical_state.fill(false)


func toggle_alarm() -> void:
    is_alarm_active = not is_alarm_active
    if is_alarm_active:
        print("Alarm Active")
    else:
        print("Alarm Stop")


func toggle_critical(i: int) -> void:
    critical_state[i] = not critical_state[i]
    if critical_state[i]:
        print()


func _on_tick_timeout() -> void:
    var new_alarm_state: bool = metrics.reduce(func(acc, val): return acc or val.tick_value(), false)
    if new_alarm_state != is_alarm_active:
        toggle_alarm()

    for i in range(metrics.size()):
        var is_critical = metrics[i].value <= 0.0
        if critical_state[i] != is_critical:
            toggle_critical(i)
