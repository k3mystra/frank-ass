extends Node

@export var associated_metric: Metric


func _on_battery_attached():
    GameConfig.power_up.emit(associated_metric.name)


func _on_battery_detached():
    GameConfig.power_down.emit(associated_metric.name)


func _on_battery_depleted():
    GameConfig.power_down.emit(associated_metric.name)
