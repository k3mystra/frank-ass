extends Node

## Emitted when a machine's vital meter changes (value: 0.0 - METER_MAX_CAPACITY seconds)
signal metric_updated(metric_name: StringName, value: float)

# Emit on metric reaching alarm treshold
signal metric_alarm_reached

## Emitted when a meter reaches 0s and starts its 30s critical failure countdown
signal critical_started(metric_name: StringName)

## Emitted when a meter recovers above 0s and cancels the critical failure countdown
signal critical_resolved(metric_name: StringName)

## Emitted when a critical failure countdown reaches 0 without recovery (triggers game over)
signal critical_expired(metric_name: StringName)

# On Alarm active
signal alarm_started
signal alarm_stopped

## Emitted when the auxiliary power knife switch in Room 3B is pulled 
signal power_switch_activated

## Emitted when a battery is physically installed into any socket (machine, rack, or terminal)
signal battery_installed(socket_id: StringName, battery: Resource)

## Emitted when a battery is removed from any socket
signal battery_removed(socket_id: StringName)

# Emit on machine getting power/no power, passing the associated metrics
signal power_up(metric_name: String)
signal power_down(metric_name: String)

## Emitted when game concludes
## success: true if power switch activated; false if critical failure expired
signal game_ended(success: bool, reason: String)

## Emitted when player changes active hotbar slot or inventory modifies 
signal active_slot_changed(slot_index: int, item: Resource)
signal inventory_updated(slots: Array)
