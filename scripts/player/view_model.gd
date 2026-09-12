class_name ViewModel
extends Node3D

## First-Person Held Item ViewModel
## Renders the active inventory item (battery with real-time glowing charge rings)
## and simulates walk bobbing motion (with sprint scaling).

const BatteryDataClass = preload("res://resources/data/battery_data.gd")
const CHARGE_KEYFRAME_TIMES: Array[float] = [0.0417, 0.0833, 0.1250, 0.1667, 0.2083]

@onready var player: PlayerController = owner as PlayerController
@onready var battery_model: Node3D = $BatteryModel
@onready var anim_player: AnimationPlayer = find_child("AnimationPlayer", true, false) as AnimationPlayer
@onready var core_mesh: MeshInstance3D = find_child("Battery_001", true, false) as MeshInstance3D

var _held_key_instance: Node3D = null

@export var base_position: Vector3 = Vector3(0.22, -0.28, -0.32)
@export var base_rotation_deg: Vector3 = Vector3(10.0, -15.0, 10.0)

# Key held offsets / base transforms (defaults to matching withDummyKey)
@export var key_base_position: Vector3 = Vector3(0.22, -0.14305973, -0.3645995)
@export var key_base_rotation_deg: Vector3 = Vector3(0.0, 180.0, 0.0)
@export var key_scale: Vector3 = Vector3(2.0, 2.0, 2.0)

var _active_base_position: Vector3 = Vector3(0.22, -0.28, -0.32)
var _active_base_rotation_deg: Vector3 = Vector3(10.0, -15.0, 10.0)

# Proximity retraction settings
@export var retract_pos_offset: Vector3 = Vector3(-0.06, -0.06, 0.18)
@export var retract_rot_offset: Vector3 = Vector3(-25.0, 15.0, -10.0)
@export var max_proximity_distance: float = 0.65
@export var min_proximity_distance: float = 0.28

@onready var center_ray: RayCast3D = get_parent().get_node("CenterProximityRay") as RayCast3D
@onready var right_ray: RayCast3D = get_parent().get_node("RightProximityRay") as RayCast3D

var current_item: Resource = null
var bob_timer: float = 0.0
var current_bob_offset: Vector3 = Vector3.ZERO
var current_retract_weight: float = 0.0

func _ready() -> void:
	EventBus.active_slot_changed.connect(_on_active_slot_changed)

	_active_base_position = base_position
	_active_base_rotation_deg = base_rotation_deg

	if get_parent() != null:
		var dummy_key = get_parent().find_child("DummyKey", false, false) as Node3D
		if dummy_key != null:
			key_base_position = dummy_key.position
			key_base_rotation_deg = dummy_key.rotation_degrees
			key_scale = dummy_key.scale
			dummy_key.visible = false

	position = _active_base_position
	rotation_degrees = _active_base_rotation_deg

	if player != null:
		center_ray.add_exception(player)
		right_ray.add_exception(player)

	if core_mesh == null:
		core_mesh = find_child("Battery.001", true, false) as MeshInstance3D

	# Initial setup based on current active item
	if player != null and player.has_node("Inventory"):
		var inv = player.get_node("Inventory")
		if inv != null and inv.has_method("get_active_item"):
			_on_active_slot_changed(0, inv.get_active_item())
	else:
		visible = false

func _process(delta: float) -> void:
	if not visible:
		return

	_update_proximity(delta)
	_update_bobbing(delta)
	_apply_transform()

func _update_proximity(delta: float) -> void:
	var target_weight: float = 0.0
	var closest_dist: float = max_proximity_distance

	if center_ray.is_colliding():
		var hit_pt: Vector3 = center_ray.get_collision_point()
		closest_dist = minf(closest_dist, center_ray.global_position.distance_to(hit_pt))

	if right_ray.is_colliding():
		var hit_pt: Vector3 = right_ray.get_collision_point()
		closest_dist = minf(closest_dist, right_ray.global_position.distance_to(hit_pt))

	if closest_dist < max_proximity_distance:
		target_weight = clampf(1.0 - (closest_dist - min_proximity_distance) / (max_proximity_distance - min_proximity_distance), 0.0, 1.0)

	current_retract_weight = lerpf(current_retract_weight, target_weight, delta * 12.0)
	if absf(current_retract_weight - target_weight) < 0.001:
		current_retract_weight = target_weight

func _update_bobbing(delta: float) -> void:
	var target_bob_offset = Vector3.ZERO

	if player != null and player.is_on_floor():
		var horiz_speed: float = Vector2(player.velocity.x, player.velocity.z).length()
		if horiz_speed > 0.1:
			var freq: float = 14.0 if player.is_sprinting else 10.0
			bob_timer += delta * freq
			# Dampen bobbing when pulled back against self
			var bob_scale: float = 1.0 - current_retract_weight * 0.7
			target_bob_offset.x = cos(bob_timer * 0.5) * (0.015 * bob_scale)
			target_bob_offset.y = sin(bob_timer) * (0.010 * bob_scale)
		else:
			bob_timer = move_toward(bob_timer, 0.0, delta * 5.0)
	else:
		bob_timer = move_toward(bob_timer, 0.0, delta * 5.0)

	current_bob_offset = current_bob_offset.lerp(target_bob_offset, delta * 12.0)

func _apply_transform() -> void:
	position = _active_base_position + (retract_pos_offset * current_retract_weight) + current_bob_offset
	rotation_degrees = _active_base_rotation_deg + (retract_rot_offset * current_retract_weight)

func _on_active_slot_changed(_slot_index: int, item: Resource) -> void:
	current_item = item

	if _held_key_instance != null:
		_held_key_instance.queue_free()
		_held_key_instance = null

	if item is BatteryDataClass:
		_active_base_position = base_position
		_active_base_rotation_deg = base_rotation_deg
		_apply_transform()
		visible = true
		if battery_model != null:
			battery_model.visible = true
		_update_battery_visuals(item as BatteryDataClass)
	elif item is KeyData:
		_active_base_position = key_base_position
		_active_base_rotation_deg = key_base_rotation_deg
		_apply_transform()
		visible = true
		if battery_model != null:
			battery_model.visible = false
		var key_item = item as KeyData
		if key_item.model_scene != null:
			_held_key_instance = key_item.model_scene.instantiate()
			_held_key_instance.position = Vector3.ZERO
			_held_key_instance.rotation_degrees = Vector3.ZERO
			_held_key_instance.scale = key_scale
			add_child(_held_key_instance)
	else:
		_active_base_position = base_position
		_active_base_rotation_deg = base_rotation_deg
		_apply_transform()
		if battery_model != null:
			battery_model.visible = false
		visible = false

func _update_battery_visuals(battery: BatteryDataClass) -> void:
	var blocks_lit: int = battery.get_blocks_lit()

	if blocks_lit <= 0:
		if core_mesh != null:
			core_mesh.visible = false
	else:
		if core_mesh != null:
			core_mesh.visible = true

		var target_index: int = clampi(blocks_lit, 0, CHARGE_KEYFRAME_TIMES.size() - 1)
		var target_time: float = CHARGE_KEYFRAME_TIMES[target_index]
		if anim_player != null and anim_player.has_animation("Battery_Charges"):
			anim_player.play("Battery_Charges")
			anim_player.seek(target_time, true)
			anim_player.pause()
