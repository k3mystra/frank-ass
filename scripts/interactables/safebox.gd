class_name Safebox
extends Interactable

signal safe_opened
signal safe_closed

@export var target_terminal: CodeTerminal = null
@export var is_open: bool = false
@export var auto_open_on_correct: bool = true
@export var locked_prompt: String = "Locked Safe"

@onready var anim_player: AnimationPlayer = find_child("AnimationPlayer", true, false)
@onready var door_blocker: CollisionShape3D = find_child("DoorBlocker", true, false) as CollisionShape3D
@onready var door_physics_barrier: StaticBody3D = find_child("DoorPhysicsBarrier", true, false) as StaticBody3D

var _tween: Tween = null

func _ready() -> void:
	_update_blocker_state()

	if anim_player != null:
		anim_player.play("door open n close")
		anim_player.seek(2.0 if is_open else 0.0, true)
		anim_player.pause()

	if target_terminal != null:
		connect_terminal(target_terminal)

func get_interaction_prompt(_player: Node = null) -> String:
	return "" if is_open else locked_prompt

func interact(_player: Node) -> void:
	pass

func _update_blocker_state() -> void:
	if door_blocker != null:
		door_blocker.set_deferred("disabled", is_open)
	if door_physics_barrier != null:
		for child in door_physics_barrier.get_children():
			if child is CollisionShape3D:
				child.set_deferred("disabled", is_open)

func connect_terminal(terminal: CodeTerminal) -> void:
	if terminal != null and not terminal.code_correct.is_connected(_on_terminal_code_correct):
		terminal.code_correct.connect(_on_terminal_code_correct)

func _on_terminal_code_correct(_code: String) -> void:
	if auto_open_on_correct and not is_open:
		open_safe()

func open_safe() -> void:
	if is_open or anim_player == null:
		return
	is_open = true
	_update_blocker_state()
	safe_opened.emit()

	if _tween != null and _tween.is_valid():
		_tween.kill()

	anim_player.play("door open n close")
	anim_player.seek(0.0, true)

	_tween = create_tween()
	_tween.tween_interval(2.0)
	_tween.tween_callback(func():
		if anim_player != null:
			anim_player.pause()
			anim_player.seek(2.0, true)
	)

func close_safe() -> void:
	if not is_open or anim_player == null:
		return
	is_open = false
	safe_closed.emit()

	if _tween != null and _tween.is_valid():
		_tween.kill()

	anim_player.play("door open n close")
	anim_player.seek(2.0, true)

	_tween = create_tween()
	_tween.tween_interval(2.0)
	_tween.tween_callback(func():
		if anim_player != null:
			anim_player.pause()
			anim_player.seek(4.0, true)
		_update_blocker_state()
	)
