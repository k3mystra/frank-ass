class_name ExitObj
extends Interactable

@export var game_scene: PackedScene


func interact(_player: Node) -> void:
	SceneManager.goto_scene(game_scene.resource_path)
