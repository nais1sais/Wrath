
# Make sure process mode for this node is 'always' so when game pauses it doesnt pause aswell
extends CanvasLayer

@export_subgroup("Audio")
@export var hover_sound_player: AudioStreamPlayer2D
@export var press_sound_player: AudioStreamPlayer2D
@export var hover_sound: AudioStream
@export var press_sound: AudioStream
func _play_hover_sound() -> void:
	if not hover_sound_player.is_inside_tree(): return
	hover_sound_player.stream = hover_sound; 
	hover_sound_player.play()
func _play_press_sound() -> void:
	if not press_sound_player.is_inside_tree(): return
	press_sound_player.stream = press_sound; 
	press_sound_player.play()

@export_subgroup("Main Menu")
@export var main_menu: Control
@export var resume_button: Button
@export var restart_button: Button
@export var new_game_button: Button
@export var options_button: Button
@export var controls_button: Button
@export var credits_button: Button
@export var quit_button: Button
func _on_resume_pressed() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	self.visible = false
	Engine.time_scale = 1
	get_tree().paused = false
func _on_pause_pressed() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE 
	self.visible = true;
	Engine.time_scale = 0
	get_tree().paused = true
func _on_game_pressed() -> void:
	if not (main_menu and game_menu): return
	main_menu.visible = false
	game_menu.visible = true
func _on_options_pressed() -> void:
	main_menu.visible = false
	options_menu.visible = true
func _on_controls_pressed() -> void:
	if not (main_menu and controls_menu): return
	main_menu.visible = false
	controls_menu.visible = true
func _on_credits_pressed() -> void:
	if not (main_menu and credits_menu): return
	main_menu.visible = false
	credits_menu.visible = true
func _on_quit_pressed() -> void:
	get_tree().quit()

@export_subgroup("Game Menu")
@export var game_menu: Control
@export var load_menu: Control
@export var delete_menu: Control
@export var save_theme: Theme
func format_time(total_seconds: float) -> String:
	var total_seconds_int = int(total_seconds)
	var milliseconds = int(fmod(total_seconds, 1) * 10) 
	var time_parts = []
	if total_seconds_int >= 86400: time_parts.append(str(total_seconds_int / 86400.0))
	if total_seconds_int >= 3600: time_parts.append("%02d" % ((total_seconds_int % 86400) / 3600.0))
	if total_seconds_int >= 60: time_parts.append("%02d" % ((total_seconds_int % 3600) / 60.0))
	time_parts.append("%02d.%d" % [total_seconds_int % 60, milliseconds])
	return ":".join(time_parts)
func populate_menu_with_saves(menu: Control, on_press_func: Callable) -> void:	
	for child in menu.get_children():
		if child.name == "Back":
			continue
		menu.remove_child(child)
		child.queue_free()
	
	var saves = Save.get_save_files()
	for save in saves:
		var button = Button.new()
		button.theme = save_theme
		if "play_time" in save:
			button.text = format_time(save["play_time"])
		else:
			button.text = save["file_name"]
		button.mouse_entered.connect(_play_hover_sound)
		button.pressed.connect(on_press_func.bind(save["file_name"]))
		menu.add_child(button)
		menu.move_child(button, 0)  
func _on_delete_save_pressed(file_name: String) -> void:
	Save.delete_save(file_name)
	populate_menu_with_saves(delete_menu, _on_delete_save_pressed)
func _on_load_save_pressed(file_name: String) -> void:
	Save.load_game(file_name)
	populate_menu_with_saves(load_menu, _on_load_save_pressed)
func _on_game_restart_pressed() -> void:
	if Save.data.has("checkpoint_scene_path"): 
		get_tree().change_scene_to_file(Save.data["checkpoint_scene_path"])
func _on_game_new_pressed() -> void:
	Save.load_game()
func _on_game_load_pressed() -> void:
	if not (load_menu and game_menu): return
	game_menu.visible = false
	load_menu.visible = true
	populate_menu_with_saves(load_menu, _on_load_save_pressed)
func _on_game_delete_pressed() -> void:
	if not (delete_menu and game_menu): return
	game_menu.visible = false
	delete_menu.visible = true
	populate_menu_with_saves(delete_menu, _on_delete_save_pressed)
func _on_game_back_pressed() -> void:
	game_menu.visible = false
	main_menu.visible = true
func _on_load_back_pressed() -> void:
	load_menu.visible = false
	game_menu.visible = true
func _on_delete_back_pressed() -> void:
	delete_menu.visible = false
	game_menu.visible = true

@export_subgroup("Options")
@export var options_menu: Control
@export var options_master_slider: HSlider
@export var options_master_bus: String = "Master"
@export var options_sfx_slider: HSlider
@export var options_sfx_bus: String = "SFX"
@export var options_music_slider: HSlider
@export var options_music_bus: String = "Music"
@export var options_display_dropdown: OptionButton
@export var options_back_button: Button
var window_position : Vector2
var window_size : Vector2
func save_settings() -> void: 
	var config = ConfigFile.new()
	if options_master_slider: config.set_value("audio", "master_volume", options_master_slider.value)
	if options_sfx_slider: config.set_value("audio", "sfx_volume", options_sfx_slider.value)
	if options_music_slider: config.set_value("audio", "music_volume", options_music_slider.value)
	#config.set_value("window", "mode", DisplayServer.window_get_mode())
	#config.set_value("window", "position", DisplayServer.window_get_position())
	#config.set_value("window", "size", DisplayServer.window_get_size())
	config.save("user://settings.cfg")
func load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err != OK: return
	_on_sfx_changed(config.get_value("audio", "sfx_volume", 100))
	_on_music_changed(config.get_value("audio", "music_volume", 100))
	_on_master_changed(config.get_value("audio", "master_volume", 100))
	#DisplayServer.window_set_mode(config.get_value("window", "mode", DisplayServer.WINDOW_MODE_FULLSCREEN))
	#DisplayServer.window_set_position(config.get_value("window", "position", Vector2(100, 100)))
	#DisplayServer.window_set_size(config.get_value("window", "size", Vector2(1280, 720)))			
func _check_for_window_changes() -> void:
	pass
	#if window_position != Vector2(DisplayServer.window_get_position()):
		#window_position = Vector2(DisplayServer.window_get_position())
		#save_settings()
	#if window_size != Vector2(DisplayServer.window_get_size()):
		#window_size = Vector2(DisplayServer.window_get_size())
		#save_settings()	
func _on_options_back_pressed() -> void:
	options_menu.visible = false
	main_menu.visible = true
func _on_master_changed(value: float) -> void:
	if options_master_slider: options_master_slider.value = value
	var master_bus = AudioServer.get_bus_index(options_master_bus)
	var db_value = lerp(-80, 0, pow(value / 100, 0.5))  
	AudioServer.set_bus_volume_db(master_bus, db_value)
	save_settings()
func _on_sfx_changed(value: float) -> void:
	if options_sfx_slider: options_sfx_slider.value = value
	var sfx_bus = AudioServer.get_bus_index(options_sfx_bus)
	var db_value = lerp(-80, 0, pow(value / 100, 0.5)) 
	AudioServer.set_bus_volume_db(sfx_bus, db_value)
	save_settings()
func _on_music_changed(value: float) -> void:
	if options_music_slider: options_music_slider.value = value
	var music_bus = AudioServer.get_bus_index(options_music_bus)
	var db_value = lerp(-80, 0, pow(value / 100, 0.5))  
	AudioServer.set_bus_volume_db(music_bus, db_value)
	save_settings()
func _on_window_mode_changed(index: int) -> void:
	match index:
		0: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		1: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	#save_settings()
@export_subgroup("Controls")
@export var controls_menu: Control
func _on_controls_back_pressed() -> void:
	controls_menu.visible = false
	main_menu.visible = true

@export_subgroup("Credits")
@export var credits_menu: Control
func _on_credits_back_pressed() -> void:
	credits_menu.visible = false
	main_menu.visible = true

func _ready() -> void:
	load_settings()
	_on_resume_pressed()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("menu"):
		#_check_for_window_changes()
		if self.visible:
			_on_resume_pressed()	
		else :
			_play_press_sound()
			_on_pause_pressed()
