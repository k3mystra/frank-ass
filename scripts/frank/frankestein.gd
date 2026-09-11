extends Node3D

# Actual level
@export var metrics: Array[Metric]

@export var critical_state: Array[bool]
@export var is_alarm_active: bool = false

@export var critical_timer_scene: PackedScene
var critical_timers: Array[Timer] = []


func _ready() -> void:
    critical_state.resize(metrics.size())
    critical_state.fill(false)

    const CRIT_TIMER_NAME = "CritTimer"
    for i in range(metrics.size()):
        var timer = critical_timer_scene.instantiate()
        var timer_name = CRIT_TIMER_NAME + str(i)
        timer.set_name(timer_name)
        add_child(timer)

        critical_timers.push_back(get_node(timer_name))


func toggle_alarm() -> void:
    is_alarm_active = not is_alarm_active
    if is_alarm_active:
        print("Alarm Active")
    else:
        print("Alarm Stop")


func toggle_critical(i: int) -> void:
    critical_state[i] = not critical_state[i]
    if critical_state[i]:
        print("%s is critical!" % metrics[i].name)
        critical_timers[i].start()
    else:
        print("%s is normal" % metrics[i].name)
        critical_timers[i].stop()


func _on_tick_timeout() -> void:
    var new_alarm_state: bool = metrics.reduce(func(acc, val): return acc or val.tick_value(), false)
    if new_alarm_state != is_alarm_active:
        toggle_alarm()

    for i in range(metrics.size()):
        var is_critical = metrics[i].value <= 0.0
        if critical_state[i] != is_critical:
            toggle_critical(i)
