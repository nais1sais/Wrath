extends Node3D

func _ready() -> void:
	get_tree().paused = false 
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_play_pressed() -> void:
	if Save.data.has("checkpoint_scene_path"): 
		get_tree().change_scene_to_file(Save.data["checkpoint_scene_path"])
	else: 
		get_tree().change_scene_to_file("res://scenes/zones/exterior.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
