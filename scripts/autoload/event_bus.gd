extends Node

## Emitted when a machine's vital meter changes (value: 0.0 - 100.0)
signal meter_changed(machine_id: StringName, value: float)

## Emitted when a meter reaches 0% and starts its 30s critical failure countdown
signal critical_failure_started(machine_id: StringName)

## Emitted when a meter recovers above 0% and cancels the critical failure countdown
signal critical_failure_resolved(machine_id: StringName)

## Emitted when a critical failure countdown reaches 0 without recovery (triggers game over)
signal critical_failure_expired(machine_id: StringName)

## Emitted periodically to update remaining survival countdown (seconds_left: float)
signal survival_timer_updated(seconds_left: float)

## Emitted when a battery is physically installed into any socket (machine, rack, or terminal)
signal battery_installed(socket_id: StringName, battery: Resource)

## Emitted when a battery is removed from any socket
signal battery_removed(socket_id: StringName)

## Emitted when game concludes
## success: true if survived 20:00 or interacted with final cache; 
## false if critical failure expired
signal game_ended(success: bool, reason: String)

## Emitted when player changes active hotbar slot or inventory modifies (ADR-002)
signal active_slot_changed(slot_index: int, item: Resource)
signal inventory_updated(slots: Array)
