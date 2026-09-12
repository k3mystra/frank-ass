extends Node

@export var associated_metric: Metric
@export var associated_socket: BatterySocket


func _ready() -> void:
    associated_socket.battery_attached.connect(_on_battery_attached)
    associated_socket.battery_detached.connect(_on_battery_detached)
    associated_socket.battery_depleted.connect(_on_battery_depleted)


func _on_battery_attached():
    GameConfig.power_up.emit(associated_metric.name)


func _on_battery_detached():
    GameConfig.power_down.emit(associated_metric.name)


func _on_battery_depleted():
    GameConfig.power_down.emit(associated_metric.name)
