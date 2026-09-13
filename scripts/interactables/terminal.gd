class_name CodeTerminal
extends Interactable

signal code_correct(code: String)
signal code_incorrect(code: String)
signal terminal_focused
signal terminal_unfocused

@export var target_code: String = "0830"
@export var max_digits: int = 4
@export var is_enabled: bool = true

@onready var focus_point: Node3D = find_child("CameraFocusPoint", true, false)
@onready var display_label: Label3D = find_child("DisplayLabel", true, false)
@onready var audio_beep: AudioStreamPlayer3D = find_child("AudioPlayerBeep", true, false)
@onready var audio_error: AudioStreamPlayer3D = find_child("AudioPlayerError", true, false)
@onready var audio_success: AudioStreamPlayer3D = find_child("AudioPlayerSuccess", true, false)
@onready var battery_socket: BatterySocket = find_child("TerminalBatterySocket", true, false) as BatterySocket

var entered_code: String = ""
var is_solved: bool = false
var is_focused: bool = false
var is_evaluating: bool = false
var _active_player: PlayerController = null

func _ready() -> void:
	if battery_socket == null:
		battery_socket = find_child("BatterySocket", true, false) as BatterySocket
	if battery_socket != null:
		if not battery_socket.battery_attached.is_connected(_on_battery_attached):
			battery_socket.battery_attached.connect(_on_battery_attached)
		if not battery_socket.battery_detached.is_connected(_on_battery_detached):
			battery_socket.battery_detached.connect(_on_battery_detached)
		if not battery_socket.battery_depleted.is_connected(_on_battery_depleted):
			battery_socket.battery_depleted.connect(_on_battery_depleted)

	_update_display()
	_update_button_labels()

func get_interaction_prompt(player: Node = null) -> String:
	if not is_enabled:
		return "Unpowered"
	if is_focused:
		return ""
	if is_player_behind(player):
		return ""
	if not has_power():
		return "No Power"
	return "E - " + prompt_text

func interact(player: Node) -> void:
	if not is_enabled:
		return
	if is_focused:
		_exit_focus()
		return
	if is_player_behind(player):
		return
	if not has_power():
		return
	if player is PlayerController:
		_enter_focus(player as PlayerController)

func _enter_focus(player: PlayerController) -> void:
	if is_focused:
		return
	is_focused = true
	_active_player = player

	var target = focus_point if focus_point != null else self
	player.focus_camera(target, Callable(self, "_on_player_unfocused"))
	terminal_focused.emit()

func _exit_focus() -> void:
	if not is_focused:
		return
	is_focused = false
	if _active_player != null and is_instance_valid(_active_player):
		_active_player.unfocus_camera()
		_active_player = null
	terminal_unfocused.emit()

func _on_player_unfocused() -> void:
	is_focused = false
	_active_player = null
	terminal_unfocused.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not is_focused:
		return

	if event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE):
		get_viewport().set_input_as_handled()
		_exit_focus()
		return

	if not has_power():
		_exit_focus()
		return

	if is_evaluating or is_solved:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		var key = event.physical_keycode
		if key >= KEY_0 and key <= KEY_9:
			get_viewport().set_input_as_handled()
			press_digit(str(key - KEY_0))
			return
		elif key >= KEY_KP_0 and key <= KEY_KP_9:
			get_viewport().set_input_as_handled()
			press_digit(str(key - KEY_KP_0))
			return
		elif key == KEY_BACKSPACE or key == KEY_DELETE:
			get_viewport().set_input_as_handled()
			press_backspace()
			return
		elif key == KEY_C:
			get_viewport().set_input_as_handled()
			press_clear()
			return
		elif key == KEY_ENTER or key == KEY_KP_ENTER:
			get_viewport().set_input_as_handled()
			press_submit()
			return

func press_digit(digit: String) -> void:
	if is_evaluating or is_solved or not is_enabled or not has_power():
		return
	if entered_code.length() >= max_digits:
		return

	entered_code += digit
	_play_beep()
	_update_display()

func press_backspace() -> void:
	if is_evaluating or is_solved or not has_power():
		return
	if not entered_code.is_empty():
		entered_code = entered_code.substr(0, entered_code.length() - 1)
		_play_beep()
		_update_display()

func press_clear() -> void:
	if is_evaluating or is_solved or not has_power():
		return
	if not entered_code.is_empty():
		entered_code = ""
		_play_beep()
		_update_display()

func press_submit() -> void:
	if is_evaluating or is_solved or not has_power():
		return
	if entered_code.is_empty():
		return
	_evaluate_code()

func _evaluate_code() -> void:
	is_evaluating = true

	if entered_code == target_code:
		is_solved = true
		if display_label != null:
			display_label.text = "OK"
			display_label.modulate = Color(0.2, 1.0, 0.3)
		_play_success()
		code_correct.emit(entered_code)
		is_evaluating = false
		_exit_focus()
	else:
		code_incorrect.emit(entered_code)
		if display_label != null:
			display_label.text = "ERR"
			display_label.modulate = Color(1.0, 0.2, 0.2)
		_play_error()

		var timer = get_tree().create_timer(1.0)
		timer.timeout.connect(func():
			entered_code = ""
			if display_label != null:
				display_label.modulate = Color(0.2, 0.9, 1.0)
			_update_display()
			is_evaluating = false
		)

func _update_display() -> void:
	_update_button_labels()
	if display_label == null:
		return
	if not is_enabled or not has_power():
		display_label.text = ""
		return
	if is_solved:
		display_label.text = "OK"
		display_label.modulate = Color(0.2, 1.0, 0.3)
		return

	var display_chars: Array[String] = []
	for i in range(max_digits):
		if i < entered_code.length():
			display_chars.push_back(entered_code[i])
		else:
			display_chars.push_back("_")

	display_label.text = " ".join(display_chars)

func _play_beep() -> void:
	if audio_beep != null:
		audio_beep.play(0.0)

func _play_error() -> void:
	if audio_error != null:
		audio_error.play(0.0)

func _play_success() -> void:
	if audio_success != null:
		audio_success.play(0.0)

func is_player_behind(player: Node) -> bool:
	var pc = player as PlayerController
	if pc == null or pc.camera == null:
		return false

	if to_local(pc.global_position).z <= 0.0:
		return true

	var cam_forward: Vector3 = -pc.camera.global_transform.basis.z.normalized()
	var term_forward: Vector3 = global_transform.basis.z.normalized()
	return cam_forward.dot(term_forward) >= 0.0

func has_power() -> bool:
	if not is_enabled:
		return false
	if battery_socket == null:
		return true
	return battery_socket.installed_battery != null and battery_socket.installed_battery.charge > 0.0

func _on_battery_attached(_battery: Resource) -> void:
	_update_display()
	_update_button_labels()

func _on_battery_detached(_battery: Resource) -> void:
	_handle_power_loss()

func _on_battery_depleted(_battery: Resource) -> void:
	_handle_power_loss()

func _handle_power_loss() -> void:
	if is_focused:
		_exit_focus()
	if not is_solved:
		entered_code = ""
	_update_display()
	_update_button_labels()

func _update_button_labels() -> void:
	var power_active: bool = has_power()
	var buttons_root = find_child("Buttons", true, false)
	if buttons_root == null:
		return
	var labels = buttons_root.find_children("*", "Label3D", true, false)
	for lbl in labels:
		if lbl is Label3D:
			lbl.visible = power_active
