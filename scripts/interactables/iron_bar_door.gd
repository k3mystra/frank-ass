class_name IronBarDoor
extends Node3D

signal bar_opened

@export var target_terminal: CodeTerminal = null
@export var linked_spotlight: Light3D = null
@export var linked_wall_hint: Node3D = null
@export var drop_distance: float = 3.5
@export var drop_duration: float = 0.6
@export var is_open: bool = false

var _tween: Tween = null
var _closed_y: float = 0.0

func _ready() -> void:
	_closed_y = position.y
	if is_open:
		position.y = _closed_y - drop_distance

	if target_terminal != null:
		connect_terminal(target_terminal)

	_update_power_state()

func connect_terminal(terminal: CodeTerminal) -> void:
	if terminal == null or not is_instance_valid(terminal):
		return
	if not terminal.code_correct.is_connected(_on_terminal_code_correct):
		terminal.code_correct.connect(_on_terminal_code_correct)

	if terminal.battery_socket != null:
		if not terminal.battery_socket.battery_attached.is_connected(_on_power_changed):
			terminal.battery_socket.battery_attached.connect(_on_power_changed)
		if not terminal.battery_socket.battery_detached.is_connected(_on_power_changed):
			terminal.battery_socket.battery_detached.connect(_on_power_changed)
		if not terminal.battery_socket.battery_depleted.is_connected(_on_power_changed):
			terminal.battery_socket.battery_depleted.connect(_on_power_changed)
	_update_power_state()

func _on_power_changed(_battery: Resource = null) -> void:
	_update_power_state()

func _update_power_state() -> void:
	var powered: bool = target_terminal != null and target_terminal.has_power()
	if linked_spotlight != null:
		linked_spotlight.visible = powered
	if linked_wall_hint != null:
		linked_wall_hint.visible = powered

func _on_terminal_code_correct(_code: String) -> void:
	if not is_open:
		open_bar()

func open_bar() -> void:
	if is_open:
		return
	is_open = true
	bar_opened.emit()

	if _tween != null and _tween.is_valid():
		_tween.kill()

	var target_y: float = _closed_y - drop_distance
	_tween = create_tween()
	_tween.tween_property(self, "position:y", target_y, drop_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

