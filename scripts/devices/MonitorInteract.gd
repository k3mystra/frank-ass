extends Interactable

@onready var audio_hum: AudioStreamPlayer3D = get_node_or_null("../AudioScreenHum")

func _ready() -> void:
	if audio_hum != null:
		if not audio_hum.finished.is_connected(audio_hum.play):
			audio_hum.finished.connect(audio_hum.play)
		if not audio_hum.playing:
			audio_hum.play(0.0)
