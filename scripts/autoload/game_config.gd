extends Node

const MACHINE_HEART: StringName = &"heart_pump"
const MACHINE_OXYGEN: StringName = &"oxygen_system"
const MACHINE_NEURAL: StringName = &"neural_stimulator"

const ALL_MACHINES: Array[StringName] = [
	MACHINE_HEART,
	MACHINE_OXYGEN,
	MACHINE_NEURAL
]

## Seconds a 100% battery lasts in an active machine
const BATTERY_LIFESPAN_SECONDS: float = 60.0
static func get_battery_drain_rate() -> float:
	return 100.0 / BATTERY_LIFESPAN_SECONDS

## Maximum capacity of each machine meter in seconds
const METER_MAX_CAPACITY: float = 180.0

## Life meter drain rate per second when unpowered
const METER_UNPOWERED_DRAIN_RATE: float = 1.0

## Life meter recovery rate per second when powered
const METER_POWERED_RECOVERY_RATE: float = 1.0

## Grace duration before failure when a meter reaches 0s 
const CRITICAL_FAILURE_DURATION: float = 30.0

const INTERACTION_DISTANCE: float = 2.5

const SHOW_INTERACTION_TEXT: bool = true

