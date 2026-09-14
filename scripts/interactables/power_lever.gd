class_name PowerLever
extends Interactable

signal lever_activated
signal ending_triggered

@export var animation_name: StringName = &"down up"
@export var animation_start_time: float = 0.0
@export var animation_end_time: float = 1.5
@export var animation_duration: float = 1.5
@export var ending_delay: float = 2.0
@export var is_activated: bool = false

@onready var anim_player: AnimationPlayer = find_child("AnimationPlayer", true, false)
@onready var audio_buzz: AudioStreamPlayer3D = find_child("AudioElectricBuzz", true, false)

var _tween: Tween = null

func _ready() -> void:
	prompt_text = "E - turn on the switch"
	if is_activated and anim_player != null:
		anim_player.play(animation_name)
		anim_player.seek(animation_end_time, true)
		anim_player.pause()

func get_interaction_prompt(_player: Node = null) -> String:
	if is_activated:
		return ""
	return prompt_text

func interact(_player: Node) -> void:
	if is_activated:
		return
	activate_switch()

func activate_switch() -> void:
	if is_activated:
		return
	is_activated = true
	lever_activated.emit()

	if audio_buzz != null:
		audio_buzz.play(0.0)

	if anim_player != null:
		anim_player.play(animation_name)
		anim_player.pause()
		anim_player.seek(animation_start_time, true)

		if _tween != null and _tween.is_valid():
			_tween.kill()

		_tween = create_tween()
		_tween.tween_method(
			func(pos: float):
				if anim_player != null and is_instance_valid(anim_player):
					anim_player.seek(pos, true),
			animation_start_time,
			animation_end_time,
			animation_duration
		).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_IN)

	var timer = get_tree().create_timer(ending_delay)
	timer.timeout.connect(_on_ending_timeout)

func _on_ending_timeout() -> void:
	ending_triggered.emit()
	EventBus.power_switch_activated.emit()
	EventBus.game_ended.emit(true, "power_switch_activated")
