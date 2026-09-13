class_name InteractionRayCast
extends RayCast3D

const InteractableClass = preload("res://scripts/interactables/interactable.gd")

signal prompt_updated(prompt: String)

var current_interactable: InteractableClass = null
@onready var player: PlayerController = owner as PlayerController

func _ready() -> void:
	target_position = Vector3(0, 0, -GameConfig.INTERACTION_DISTANCE)
	collide_with_areas = true
	collide_with_bodies = true
	collision_mask = 2

func _physics_process(_delta: float) -> void:
	if player != null and player.has_method("is_camera_focused") and player.is_camera_focused():
		if current_interactable != null and is_instance_valid(current_interactable):
			current_interactable.set_highlight(false)
			current_interactable = null
		prompt_updated.emit("")
		return

	if current_interactable != null and not is_instance_valid(current_interactable):
		current_interactable = null
		prompt_updated.emit("")

	var collider: Object = get_collider()
	var new_interactable: InteractableClass = null

	if is_colliding() and is_instance_valid(collider) and collider is InteractableClass:
		new_interactable = collider as InteractableClass

	if new_interactable != current_interactable:
		if current_interactable != null and is_instance_valid(current_interactable):
			current_interactable.set_highlight(false)

		current_interactable = new_interactable

		if current_interactable != null and is_instance_valid(current_interactable):
			current_interactable.set_highlight(true)

	if current_interactable != null and is_instance_valid(current_interactable):
		var prompt: String = current_interactable.get_interaction_prompt(player)
		prompt_updated.emit(prompt)
	else:
		prompt_updated.emit("")

func _unhandled_input(event: InputEvent) -> void:
	if player != null and player.has_method("is_camera_focused") and player.is_camera_focused():
		return

	if event.is_action_pressed("interact") and current_interactable != null and is_instance_valid(current_interactable):
		current_interactable.interact(player)
