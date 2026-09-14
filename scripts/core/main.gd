extends Node3D


@onready var anim_player: AnimationPlayer = $AnimationPlayer

@export var frank: Monster

func _ready() -> void:
	EventBus.game_ended.connect(_on_game_ended)
	var timer = get_tree().create_timer(3)
	timer.timeout.connect(_call_em)


func _call_em():
	EventBus.game_ended.emit(true, "wkwkwk")


func _on_game_ended(_success, _reason) -> void:
	# Ligthning sequence
	anim_player.play("lightning")
