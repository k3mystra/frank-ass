extends Node3D

@onready var anim_player = $AnimationPlayer
@onready var shock_timer = $ShockTimer

signal finished_shock

func _ready() -> void:
	EventBus.game_ended.connect(_play_shock)


func _play_shock(_success, _reason):
	anim_player.play("Armature|Shock")
	shock_timer.start()


func _on_shock_timer_timeout() -> void:
	anim_player.stop()
	finished_shock.emit()
	anim_player.play("Armature|TwerkDance")
