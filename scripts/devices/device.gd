extends Node

@export var associated_metric: Metric
@export var associated_socket: BatterySocket
@export var audio_players: Array[AudioStreamPlayer3D] = []

func _ready() -> void:
	for player in audio_players:
		if player != null and not player.finished.is_connected(player.play):
			player.finished.connect(player.play)

	if associated_socket != null:
		associated_socket.battery_attached.connect(_on_battery_attached)
		associated_socket.battery_detached.connect(_on_battery_detached)
		associated_socket.battery_depleted.connect(_on_battery_depleted)
		if associated_socket.has_battery():
			var b = associated_socket.get_battery()
			if b != null and b.charge > 0:
				_start_audio()

func _start_audio() -> void:
	for player in audio_players:
		if player != null and not player.playing:
			player.play(0.0)

func _stop_audio() -> void:
	for player in audio_players:
		if player != null and player.playing:
			player.stop()

func _on_battery_attached(battery_data: BatteryData):
	if battery_data.charge > 0:
		EventBus.power_up.emit(associated_metric.name)
		_start_audio()

func _on_battery_detached(_battery_data: BatteryData):
	EventBus.power_down.emit(associated_metric.name)
	_stop_audio()

func _on_battery_depleted(_battery_data: BatteryData):
	EventBus.power_down.emit(associated_metric.name)
	_stop_audio()
