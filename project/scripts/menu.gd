
# Make sure process mode for this node is 'always' so when game pauses it doesnt pause aswell
extends CanvasLayer

@export_subgroup("Audio")
@export var hover_sound_player: AudioStreamPlayer2D
@export var press_sound_player: AudioStreamPlayer2D
@export var hover_sound: AudioStream
@export var press_sound: AudioStream
func play_hover_sound() -> void:
	hover_sound_player.stream = hover_sound; 
	hover_sound_player.play()
func play_press_sound() -> void:
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
func resume() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	self.visible = false
	Engine.time_scale = 1
	get_tree().paused = false
func pause() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE 
	self.visible = true;
	Engine.time_scale = 0
	get_tree().paused = true
func restart() -> void:
	if Save.data.has("checkpoint_scene_path"): 
		get_tree().change_scene_to_file(Save.data["checkpoint_scene_path"])
	else: 
		get_tree().change_scene_to_file("res://scenes/zones/exterior.tscn")
func new_game() -> void:
	Save.data = {}
	Save.save_game()
	if Save.data.has("checkpoint_scene_path"): 
		get_tree().change_scene_to_file(Save.data["checkpoint_scene_path"])
	else: 
		get_tree().change_scene_to_file("res://scenes/zones/exterior.tscn")
func options() -> void:
	main_menu.visible = false
	options_menu.visible = true
func controls() -> void:
	main_menu.visible = false
	controls_menu.visible = true
func credits() -> void:
	main_menu.visible = false
	credits_menu.visible = true
func quit() -> void:
	get_tree().quit()
func init_main_menu() -> void:
	if resume_button: 
		resume_button.connect("pressed", Callable(self, "resume"))
		resume_button.connect("mouse_entered", Callable(self, "play_hover_sound"))
	if restart_button: 
		restart_button.connect("pressed", Callable(self, "restart"))
		restart_button.connect("mouse_entered", Callable(self, "play_hover_sound"))
	if new_game_button: 
		new_game_button.connect("pressed", Callable(self, "new_game"))
		new_game_button.connect("mouse_entered", Callable(self, "play_hover_sound"))
	if options_button: 
		options_button.connect("pressed", Callable(self, "options"))
		options_button.connect("mouse_entered", Callable(self, "play_hover_sound"))
		options_button.connect("pressed", Callable(self, "play_press_sound"))	
	if controls_button: 
		controls_button.connect("pressed", Callable(self, "controls"))
		controls_button.connect("mouse_entered", Callable(self, "play_hover_sound"))
		controls_button.connect("pressed", Callable(self, "play_press_sound"))	
	if credits_button: 
		credits_button.connect("pressed", Callable(self, "credits"))
		credits_button.connect("mouse_entered", Callable(self, "play_hover_sound"))
		credits_button.connect("pressed", Callable(self, "play_press_sound"))
	if quit_button: 
		quit_button.connect("pressed", Callable(self, "quit"))  
		quit_button.connect("mouse_entered", Callable(self, "play_hover_sound"))

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

func check_for_window_changes() -> void:
	if window_position != Vector2(DisplayServer.window_get_position()):
		window_position = Vector2(DisplayServer.window_get_position())
		save_settings()
	if window_size != Vector2(DisplayServer.window_get_size()):
		window_size = Vector2(DisplayServer.window_get_size())
		save_settings()

func save_settings() -> void: 
	var config = ConfigFile.new()
	if options_master_slider: config.set_value("audio", "master_volume", options_master_slider.value)
	if options_sfx_slider: config.set_value("audio", "sfx_volume", options_sfx_slider.value)
	if options_music_slider: config.set_value("audio", "music_volume", options_music_slider.value)
	config.set_value("window", "mode", DisplayServer.window_get_mode())
	config.set_value("window", "position", DisplayServer.window_get_position())
	config.set_value("window", "size", DisplayServer.window_get_size())
	config.save("user://settings.cfg")
func load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		
		if options_sfx_slider: 
			var sfx_volume = config.get_value("audio", "sfx_volume", 100)
			options_sfx_slider.value = sfx_volume
			sfx_changed(sfx_volume)
			
		if options_music_slider: 
			var music_volume = config.get_value("audio", "music_volume", 100)
			options_music_slider.value = music_volume
			music_changed(music_volume)
			
		if options_master_slider: 
			var master_volume = config.get_value("audio", "master_volume", 100)
			options_master_slider.value = master_volume
			master_changed(master_volume)
		
		DisplayServer.window_set_mode(config.get_value("window", "mode", DisplayServer.WINDOW_MODE_FULLSCREEN))
		DisplayServer.window_set_position(config.get_value("window", "position", Vector2(100, 100)))
		DisplayServer.window_set_size(config.get_value("window", "size", Vector2(1280, 720)))
		
		if options_display_dropdown:
			if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
				options_display_dropdown.select(1)
			else:
				options_display_dropdown.select(0)
			
func options_back() -> void:
	main_menu.visible = true
	options_menu.visible = false
func master_changed(value: float) -> void:
	var master_bus = AudioServer.get_bus_index(options_master_bus)
	var db_value = lerp(-80, 0, pow(value / 100, 0.5))  
	AudioServer.set_bus_volume_db(master_bus, db_value)
	save_settings()
func sfx_changed(value: float) -> void:
	var sfx_bus = AudioServer.get_bus_index(options_sfx_bus)
	var db_value = lerp(-80, 0, pow(value / 100, 0.5)) 
	AudioServer.set_bus_volume_db(sfx_bus, db_value)
	save_settings()
func music_changed(value: float) -> void:
	var music_bus = AudioServer.get_bus_index(options_music_bus)
	var db_value = lerp(-80, 0, pow(value / 100, 0.5))  
	AudioServer.set_bus_volume_db(music_bus, db_value)
	save_settings()
func window_mode_changed(index: int) -> void:
	match index:
		0: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		1: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	save_settings()

func init_options_menu() -> void:
	if options_sfx_slider: options_sfx_slider.connect("value_changed", Callable(self, "sfx_changed"))
	if options_music_slider: options_music_slider.connect("value_changed", Callable(self, "music_changed"))
	if options_master_slider: options_master_slider.connect("value_changed", Callable(self, "master_changed"))
	if options_display_dropdown: options_display_dropdown.connect("item_selected", Callable(self, "window_mode_changed"))
	if options_back_button: 
		options_back_button.connect("pressed", Callable(self, "options_back"))
		options_back_button.connect("mouse_entered", Callable(self, "play_hover_sound"))
		options_back_button.connect("pressed", Callable(self, "play_press_sound"))

@export_subgroup("Controls")
@export var controls_menu: Control
@export var controls_back_button: Button
func controls_back() -> void:
	main_menu.visible = true
	controls_menu.visible = false
func init_controls_menu() -> void:
	if controls_back_button: 
		controls_back_button.connect("pressed", Callable(self, "controls_back"))
		controls_back_button.connect("mouse_entered", Callable(self, "play_hover_sound"))
		controls_back_button.connect("pressed", Callable(self, "play_press_sound"))

@export_subgroup("Credits")
@export var credits_menu: Control
@export var credits_back_button: Button
func credits_back() -> void:
	main_menu.visible = true
	credits_menu.visible = false
func init_credits_menu() -> void:
	if credits_back_button: 
		credits_back_button.connect("pressed", Callable(self, "credits_back"))
		credits_back_button.connect("mouse_entered", Callable(self, "play_hover_sound"))
		credits_back_button.connect("pressed", Callable(self, "play_press_sound"))

func _ready() -> void:
	load_settings()
	resume()
	init_main_menu()
	init_controls_menu()
	init_options_menu()
	init_credits_menu()
		
func _process(_delta: float) -> void:
	check_for_window_changes()
	if Input.is_action_just_pressed("menu"):
		if self.visible:
			resume()	
			resume_button.grab_focus()
		else :
			play_press_sound()
			pause()
			resume_button.release_focus()
