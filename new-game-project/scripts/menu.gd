
# Make sure process mode for this node is 'always' so when game pauses it doesnt pause aswell
extends CanvasLayer

@export_subgroup("Main Menu")
@export var main_menu: Control
@export var resume_button: Button
@export var restart_button: Button
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
	resume()
	get_tree().reload_current_scene()
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
func save_settings() -> void:
	var config = ConfigFile.new()
	if options_master_slider: config.set_value("audio", "master_volume", options_master_slider.value)
	if options_sfx_slider: config.set_value("audio", "sfx_volume", options_sfx_slider.value)
	if options_music_slider: config.set_value("audio", "music_volume", options_music_slider.value)
	if options_display_dropdown: config.set_value("options", "display", options_display_dropdown.selected)
	config.save("user://settings.cfg")
func load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		var window_mode = config.get_value("options", "display", 0)
		var sfx_volume = config.get_value("audio", "sfx_volume", 100)
		var music_volume = config.get_value("audio", "music_volume", 100)
		var master_volume = config.get_value("audio", "master_volume", 100)
		if options_display_dropdown: options_display_dropdown.select(window_mode)
		window_mode_changed(window_mode)
		if options_sfx_slider: options_sfx_slider.value = sfx_volume
		sfx_changed(sfx_volume)
		if options_music_slider: options_music_slider.value = music_volume
		music_changed(music_volume)
		if options_master_slider: options_master_slider.value = master_volume
		master_changed(master_volume)
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

@export_subgroup("Controls")
@export var controls_menu: Control
@export var controls_back_button: Button
func controls_back() -> void:
	main_menu.visible = true
	controls_menu.visible = false

@export_subgroup("Credits")
@export var credits_menu: Control
@export var credits_back_button: Button
func credits_back() -> void:
	main_menu.visible = true
	credits_menu.visible = false

@export_subgroup("Audio")
@export var hover_sound_player: AudioStreamPlayer2D
@export var pressed_sound_player: AudioStreamPlayer2D
@export var hover_sound: AudioStream
@export var pressed_sound: AudioStream
func play_hover_sound() -> void:
	$AudioStreamPlayer2D.stream = hover_sound; 
	$AudioStreamPlayer2D.play()
func play_pressed_sound() -> void:
	$AudioStreamPlayer2D.stream = pressed_sound; 
	$AudioStreamPlayer2D.play()

func _ready() -> void:
	load_settings()
	resume()
	if resume_button: resume_button.connect("pressed", Callable(self, "resume"))
	if restart_button: restart_button.connect("pressed", Callable(self, "restart"))
	if options_button: options_button.connect("pressed", Callable(self, "options"))
	if controls_button: controls_button.connect("pressed", Callable(self, "controls"))
	if credits_button: credits_button.connect("pressed", Callable(self, "credits"))
	if quit_button: quit_button.connect("pressed", Callable(self, "quit"))  
	if options_back_button: options_back_button.connect("pressed", Callable(self, "options_back"))
	if controls_back_button: controls_back_button.connect("pressed", Callable(self, "controls_back"))
	if credits_back_button: credits_back_button.connect("pressed", Callable(self, "credits_back"))
	if options_sfx_slider: options_sfx_slider.connect("value_changed", Callable(self, "sfx_changed"))
	if options_music_slider: options_music_slider.connect("value_changed", Callable(self, "music_changed"))
	if options_master_slider: options_master_slider.connect("value_changed", Callable(self, "master_changed"))
	if options_display_dropdown: options_display_dropdown.connect("item_selected", Callable(self, "window_mode_changed"))
	
	# Recursively connect hover and pressed sounds to buttons
	var all_nodes = get_children(); while all_nodes.size() > 0:
		var current_node = all_nodes.pop_back()
		if current_node is Button:
			current_node.connect("mouse_entered", Callable(self, "play_hover_sound"))
			current_node.connect("pressed", Callable(self, "play_pressed_sound"))
		all_nodes += current_node.get_children()
		
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("menu"):
		if self.visible:
			play_pressed_sound()
			resume()	
		else :
			play_pressed_sound()
			pause()
