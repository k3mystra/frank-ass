class_name PlayerController
extends CharacterBody3D


@export var speed: float = 4.5
@export var sprint_speed: float = 6.5
@export var jump_velocity: float = 4.0
@export var mouse_sensitivity: float = 0.0025

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D

var is_sprinting: bool = false
var is_jumping: bool = false
var is_focused: bool = false
var _focus_tween: Tween = null
var _focus_exit_callback: Callable = Callable()

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	platform_on_leave = CharacterBody3D.PLATFORM_ON_LEAVE_DO_NOTHING
	platform_floor_layers = 0

func _unhandled_input(event: InputEvent) -> void:
	if is_focused:
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clampf(head.rotation.x, deg_to_rad(-85.0), deg_to_rad(85.0))

	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if is_focused:
		velocity.x = 0.0
		velocity.z = 0.0
		if not is_on_floor():
			velocity.y -= gravity * delta
		move_and_slide()
		return

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		is_jumping = false

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		is_jumping = true

	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	is_sprinting = Input.is_action_pressed("sprint") if InputMap.has_action("sprint") else Input.is_key_pressed(KEY_SHIFT)
	var current_speed: float = sprint_speed if is_sprinting else speed

	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, current_speed)
		velocity.z = move_toward(velocity.z, 0.0, current_speed)

	move_and_slide()

	# Push dynamic physical rigid bodies (like batteries) smoothly when walked into
	var hit_rigid_body: bool = false
	for i in get_slide_collision_count():
		var col = get_slide_collision(i)
		var collider = col.get_collider()
		if collider is RigidBody3D and not collider.freeze:
			hit_rigid_body = true
			var push_dir = -col.get_normal()
			push_dir.y = 0.0
			if not push_dir.is_zero_approx():
				collider.apply_central_impulse(push_dir.normalized() * 0.8)

	# Prevent physics-body wedge pinch or slope normal deflection from launching the player upwards
	if hit_rigid_body and not is_jumping and velocity.y > 0.0:
		velocity.y = 0.0

func focus_camera(target_point: Node3D, on_exit: Callable = Callable(), unlock_mouse: bool = false) -> void:
	if is_focused or target_point == null:
		return
	is_focused = true
	_focus_exit_callback = on_exit
	if unlock_mouse:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if _focus_tween != null and _focus_tween.is_valid():
		_focus_tween.kill()

	camera.top_level = true
	_focus_tween = create_tween()
	_focus_tween.set_parallel(true)
	_focus_tween.tween_property(camera, "global_position", target_point.global_position, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_focus_tween.tween_property(camera, "global_basis", target_point.global_basis, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func unfocus_camera() -> void:
	if not is_focused:
		return
	is_focused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if _focus_tween != null and _focus_tween.is_valid():
		_focus_tween.kill()

	_focus_tween = create_tween()
	_focus_tween.set_parallel(true)
	_focus_tween.tween_property(camera, "global_position", head.global_position, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_focus_tween.tween_property(camera, "global_basis", head.global_basis, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_focus_tween.chain().tween_callback(func():
		camera.top_level = false
		camera.transform = Transform3D.IDENTITY
	)

	if _focus_exit_callback.is_valid():
		var cb = _focus_exit_callback
		_focus_exit_callback = Callable()
		cb.call()

func is_camera_focused() -> bool:
	return is_focused
