extends Label3D

@export var target_terminal: CodeTerminal

func _ready() -> void:
	if target_terminal == null:
		push_error("TerminalDebugLabel: target_terminal is null!")
		return

	text = "Locked (Code: " + target_terminal.target_code + ")"
	modulate = Color(1.0, 0.4, 0.4)

	target_terminal.code_correct.connect(_on_code_correct)
	target_terminal.code_incorrect.connect(_on_code_incorrect)

func _on_code_correct(code: String) -> void:
	text = "UNLOCKED (" + code + ")"
	modulate = Color(0.3, 1.0, 0.4)

func _on_code_incorrect(code: String) -> void:
	text = "Failed: " + code
	modulate = Color(1.0, 0.2, 0.2)
	var timer = get_tree().create_timer(1.2)
	timer.timeout.connect(func():
		if not is_instance_valid(self):
			return
		if target_terminal != null and not target_terminal.is_solved:
			text = "Locked (Code: " + target_terminal.target_code + ")"
			modulate = Color(1.0, 0.4, 0.4)
	)

