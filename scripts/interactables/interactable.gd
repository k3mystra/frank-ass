class_name Interactable
extends CollisionObject3D

@export var prompt_text: String = "Interact"
@export var highlight_mesh: MeshInstance3D

func get_interaction_prompt(_player: Node = null) -> String:
	return prompt_text

func interact(_player: Node) -> void:
	pass

func set_highlight(active: bool) -> void:
	if highlight_mesh == null:
		return

	var mat: Material = highlight_mesh.get_surface_override_material(0)
	if mat == null:
		var base_mat: Material = highlight_mesh.get_active_material(0)
		if base_mat != null:
			mat = base_mat.duplicate()
			highlight_mesh.set_surface_override_material(0, mat)

	if mat is StandardMaterial3D:
		var std_mat: StandardMaterial3D = mat as StandardMaterial3D
		std_mat.emission_enabled = active
		if active:
			std_mat.emission = Color(0.8, 0.8, 0.2)
			std_mat.emission_energy_multiplier = 0.6
