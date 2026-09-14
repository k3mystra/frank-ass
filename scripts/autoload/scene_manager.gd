extends Node

const BG_MUSIC_STREAM: AudioStream = preload("res://assets/audio/RainBGMusic.mp3")
const NORMAL_VOLUME_DB: float = 10.0
const MAIN_VOLUME_DB: float = -5.0

var current_scene = null
var bg_music_player: AudioStreamPlayer = null
var _volume_tween: Tween = null


func _ready() -> void:
	_setup_bg_music()
	call_deferred("_init_current_scene")


func _setup_bg_music() -> void:
	bg_music_player = AudioStreamPlayer.new()
	bg_music_player.name = "GlobalBackgroundMusic"
	bg_music_player.stream = BG_MUSIC_STREAM
	bg_music_player.volume_db = NORMAL_VOLUME_DB
	bg_music_player.finished.connect(_on_bg_music_finished)
	add_child(bg_music_player)


func _on_bg_music_finished() -> void:
	if bg_music_player != null and not bg_music_player.playing:
		bg_music_player.play(0.0)


func _init_current_scene() -> void:
	var root = get_tree().root
	current_scene = root.get_child(-1)
	_update_bg_volume(false)


func goto_scene(path: String) -> void:
	_deferred_goto_scene.call_deferred(path)


func _deferred_goto_scene(path: String) -> void:
	if current_scene != null and is_instance_valid(current_scene):
		current_scene.free()

	var s = ResourceLoader.load(path)
	current_scene = s.instantiate()
	get_tree().root.add_child(current_scene)

	get_tree().current_scene = current_scene
	_update_bg_volume(true)


func set_main_scene_volume(fade: bool = false) -> void:
	_set_target_volume(MAIN_VOLUME_DB, fade)


func set_normal_volume(fade: bool = false) -> void:
	_set_target_volume(NORMAL_VOLUME_DB, fade)


func _update_bg_volume(fade: bool = true) -> void:
	if bg_music_player == null:
		return

	var is_menu: bool = false
	var is_main: bool = false

	if current_scene != null and is_instance_valid(current_scene):
		var scene_path: String = current_scene.scene_file_path if ("scene_file_path" in current_scene and current_scene.scene_file_path != null) else ""
		if current_scene.name == "Menu" or scene_path.ends_with("menu.tscn"):
			is_menu = true
		elif current_scene.name == "Main" or scene_path.ends_with("Main.tscn"):
			is_main = true

	if is_menu:
		if bg_music_player.playing:
			bg_music_player.stop()
		return

	# In gameplay scenes, ensure rain music is playing
	if not bg_music_player.playing:
		bg_music_player.play(0.0)

	var target_volume: float = MAIN_VOLUME_DB if is_main else NORMAL_VOLUME_DB
	_set_target_volume(target_volume, fade)


func _set_target_volume(target_volume: float, fade: bool) -> void:
	if bg_music_player == null:
		return

	if _volume_tween != null and _volume_tween.is_valid():
		_volume_tween.kill()

	if fade:
		_volume_tween = create_tween()
		_volume_tween.tween_property(bg_music_player, "volume_db", target_volume, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		bg_music_player.volume_db = target_volume
