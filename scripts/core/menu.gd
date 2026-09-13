extends Node

@export var game_scene: PackedScene


func _on_exit_btn_pressed() -> void:
	get_tree().quit()


func _on_play_btn_pressed() -> void:
	SceneManager.goto_scene(game_scene.resource_path)
