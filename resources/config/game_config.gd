class_name GameConfig
extends Resource

const MACHINE_HEART: StringName = &"heart_pump"
const MACHINE_OXYGEN: StringName = &"oxygen_system"
const MACHINE_NEURAL: StringName = &"neural_stimulator"

const ALL_MACHINES: Array[StringName] = [
	MACHINE_HEART,
	MACHINE_OXYGEN,
	MACHINE_NEURAL
]

const BATTERY_LIFESPAN_SECONDS: float = 120.0
static func get_battery_drain_rate() -> float:
	return 100.0 / BATTERY_LIFESPAN_SECONDS

#for the devices
const METER_UNPOWERED_DRAIN_RATE: float = 1.0

const METER_POWERED_RECOVERY_RATE: float = 2.5

const CRITICAL_FAILURE_DURATION: float = 30.0

const SURVIVAL_TIMER_DURATION: float = 1200.0

const INTERACTION_DISTANCE: float = 2.5

const SHOW_INTERACTION_TEXT: bool = true

