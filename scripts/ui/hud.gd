class_name HUD
extends Control

const BatteryDataClass = preload("res://resources/data/battery_data.gd")
const BATTERY_ICON: Texture2D = preload("res://assets/images/Battery.png")

@onready var reticle: CenterContainer = $CenterReticle
@onready var reticle_dot: ColorRect = $CenterReticle/ReticleDot
@onready var prompt_label: Label = get_node_or_null("PromptLabel") if has_node("PromptLabel") else get_node_or_null("CenterReticle/PromptLabel")

@onready var hotbar_container: HBoxContainer = $HotbarContainer
@onready var slot_panels: Array[Panel] = [
	$HotbarContainer/Slot0,
	$HotbarContainer/Slot1,
	$HotbarContainer/Slot2
]
@onready var slot_labels: Array[Label] = [
	$HotbarContainer/Slot0/Label,
	$HotbarContainer/Slot1/Label,
	$HotbarContainer/Slot2/Label
]
@onready var slot_icons: Array[TextureRect] = [
	$HotbarContainer/Slot0/Icon,
	$HotbarContainer/Slot1/Icon,
	$HotbarContainer/Slot2/Icon
]

@onready var game_over_banner: Panel = $GameOverBanner
@onready var game_over_title: Label = $GameOverBanner/TitleLabel
@onready var game_over_subtext: Label = $GameOverBanner/SubtextLabel

var active_slot: int = 0

func _ready() -> void:
	EventBus.active_slot_changed.connect(_on_active_slot_changed)
	EventBus.inventory_updated.connect(_on_inventory_updated)
	EventBus.game_ended.connect(_on_game_ended)

	if game_over_banner != null:
		game_over_banner.visible = false

	_update_slot_highlights()

func update_prompt(text: String) -> void:
	if prompt_label == null or reticle_dot == null:
		return

	if text.is_empty():
		prompt_label.text = ""
		reticle_dot.custom_minimum_size = Vector2(4, 4)
		reticle_dot.color = Color(1.0, 1.0, 1.0, 0.7)
	else:
		prompt_label.text = text if GameConfig.SHOW_INTERACTION_TEXT else ""
		reticle_dot.custom_minimum_size = Vector2(8, 8)
		reticle_dot.color = Color(0.2, 0.9, 1.0, 1.0)

func _on_active_slot_changed(slot_index: int, _item: Resource) -> void:
	active_slot = slot_index
	_update_slot_highlights()

func _on_inventory_updated(slots: Array) -> void:
	for i in range(slot_labels.size()):
		if i < slots.size() and slots[i] != null:
			var item = slots[i]
			if item is BatteryDataClass:
				slot_icons[i].texture = BATTERY_ICON
				slot_icons[i].visible = true
				slot_labels[i].text = ""
			elif item is KeyData:
				slot_icons[i].texture = item.icon
				slot_icons[i].visible = item.icon != null
				slot_labels[i].text = ""
			else:
				slot_icons[i].texture = null
				slot_icons[i].visible = false
				slot_labels[i].text = item.resource_name if not item.resource_name.is_empty() else "ITEM"
		else:
			slot_icons[i].texture = null
			slot_icons[i].visible = false
			slot_labels[i].text = ""

func _update_slot_highlights() -> void:
	for i in range(slot_panels.size()):
		var panel: Panel = slot_panels[i]
		if i == active_slot:
			panel.modulate = Color(1.2, 1.2, 0.4) 
		else:
			panel.modulate = Color(0.6, 0.6, 0.6)

# func _on_game_ended(success: bool, reason: String) -> void:
# 	if game_over_banner == null:
# 		return

# 	game_over_banner.visible = true
# 	if success:
# 		game_over_title.text = "SURVIVAL ACHIEVED"
# 		game_over_subtext.text = reason + "\nLightning strikes... The creature awakens."
# 	else:
# 		game_over_title.text = "EXPERIMENT FAILED"
# 		game_over_subtext.text = reason + "\nDarkness falls... Then a thunderous spark."
