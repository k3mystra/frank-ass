extends HBoxContainer

@export var metric_icon_texture: CompressedTexture2D
@export var associated_metric: Metric

@export var critical_color: Color
@export var normal_color: Color


func _ready() -> void:
	$Icon.texture = metric_icon_texture
	$ValueBar.max_value = GameConfig.METRIC_MAX_CAPACITY

	EventBus.metric_updated.connect(_update_value)

	EventBus.critical_started.connect(_critical_started)
	EventBus.critical_resolved.connect(_critical_resolved)
	EventBus.critical_expired.connect(_critical_expired)

	_update_value(associated_metric.name)


func _update_value(metric_name: StringName):
	if (metric_name != associated_metric.name):
		return

	$ValueBar.value = associated_metric.value


func _critical_started(metric_name: StringName):
	if (metric_name != associated_metric.name):
		return

	$WarningIcon.modulate = critical_color


func _critical_resolved(metric_name: StringName):
	if (metric_name != associated_metric.name):
		return

	$WarningIcon.modulate = normal_color


func _critical_expired(metric_name: StringName):
	if (metric_name != associated_metric.name):
		return
