extends Node

@export var game_scene: PackedScene
@export_range(0, 1) var stop_chance: float

@onready var rng = RandomNumberGenerator.new()
@onready var anim_player = $AnimationPlayer
@onready var stop_timer = $StopTimer

func _on_exit_btn_pressed() -> void:
	get_tree().quit()


func _on_play_btn_pressed() -> void:
	SceneManager.goto_scene(game_scene.resource_path)


func _on_stop_timer_timeout() -> void:
	anim_player.play()


func _on_cycle_timer_timeout() -> void:
	var value = rng.randf()
	if value < stop_chance and stop_timer.is_stopped():
		anim_player.pause()
		stop_timer.start()
