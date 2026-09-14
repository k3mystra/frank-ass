class_name MainScene
extends Node3D

@onready var alarm_audio: AudioStreamPlayer = get_node_or_null("AudioCriticalAlarm")

func _ready() -> void:
	if SceneManager != null and SceneManager.has_method("set_main_scene_volume"):
		SceneManager.set_main_scene_volume(true)

	EventBus.alarm_started.connect(_on_alarm_started)
	EventBus.alarm_stopped.connect(_on_alarm_stopped)
	EventBus.critical_started.connect(_on_critical_started)
	EventBus.critical_resolved.connect(_on_critical_resolved)
	EventBus.game_ended.connect(_on_game_ended)

	if alarm_audio != null:
		if not alarm_audio.finished.is_connected(alarm_audio.play):
			alarm_audio.finished.connect(alarm_audio.play)

func _on_alarm_started() -> void:
	if alarm_audio != null and not alarm_audio.playing:
		alarm_audio.play(0.0)

func _on_alarm_stopped() -> void:
	if alarm_audio != null and alarm_audio.playing:
		alarm_audio.stop()

func _on_critical_started(_metric_name: StringName) -> void:
	if alarm_audio != null and not alarm_audio.playing:
		alarm_audio.play(0.0)

func _on_critical_resolved(_metric_name: StringName) -> void:
	pass

func _on_game_ended(_success: bool, _reason: String) -> void:
	if alarm_audio != null and alarm_audio.playing:
		alarm_audio.stop()
