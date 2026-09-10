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

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	platform_on_leave = CharacterBody3D.PLATFORM_ON_LEAVE_DO_NOTHING
	platform_floor_layers = 0

func _unhandled_input(event: InputEvent) -> void:

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
