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

@export var base_position: Vector3 = Vector3(0.24, -0.30, -0.38)
@export var base_rotation_deg: Vector3 = Vector3(10.0, -15.0, 10.0)

var current_item: Resource = null
var bob_timer: float = 0.0
var current_bob_offset: Vector3 = Vector3.ZERO

func _ready() -> void:
	EventBus.active_slot_changed.connect(_on_active_slot_changed)

	position = base_position
	rotation_degrees = base_rotation_deg

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

	_update_bobbing(delta)

func _update_bobbing(delta: float) -> void:
	var target_bob_offset = Vector3.ZERO

	if player != null and player.is_on_floor():
		var horiz_speed: float = Vector2(player.velocity.x, player.velocity.z).length()
		if horiz_speed > 0.1:
			var freq: float = 14.0 if player.is_sprinting else 10
			bob_timer += delta * freq
			# Figure-8 / sway: horizontal sway + vertical step dip
			target_bob_offset.x = cos(bob_timer * 0.5) * 0.015
			target_bob_offset.y = sin(bob_timer) * 0.010
		else:
			bob_timer = move_toward(bob_timer, 0.0, delta * 5.0)
	else:
		bob_timer = move_toward(bob_timer, 0.0, delta * 5.0)

	current_bob_offset = current_bob_offset.lerp(target_bob_offset, delta * 12.0)
	position = base_position + current_bob_offset

func _on_active_slot_changed(_slot_index: int, item: Resource) -> void:
	current_item = item

	if item is BatteryDataClass:
		visible = true
		_update_battery_visuals(item as BatteryDataClass)
	else:
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

