class_name DoorArea
extends "res://scripts/interactables/interactable.gd"

@export var door: Door = null

func _ready() -> void:
	if door == null:
		if owner is Door:
			door = owner as Door
		else:
			push_error("owner is not a door")
	if not is_connected("body_entered", _on_body_entered):
		connect("body_entered", _on_body_entered)

func get_interaction_prompt(player: Node = null) -> String:
	if door != null and door.has_method("get_interaction_prompt"):
		return door.get_interaction_prompt(player)
	return prompt_text

func interact(player: Node) -> void:
	if door != null and door.has_method("interact_from_side"):
		var is_front: bool = true
		if player is Node3D:
			is_front = to_local((player as Node3D).global_position).z >= 0.0
		door.interact_from_side(player, is_front)

func _on_body_entered(body: Node) -> void:
	if door != null and door.has_method("on_door_body_entered"):
		var is_front: bool = true
		if body is Node3D:
			is_front = to_local((body as Node3D).global_position).z >= 0.0
		door.on_door_body_entered(body, is_front)

