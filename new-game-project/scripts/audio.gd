extends Node

func play_2d_oneshot_sound(sound: AudioStream, pitch_min: float, pitch_max: float) -> void:
	var player = AudioStreamPlayer2D.new()
	player.stream = sound
	player.pitch_scale = randf_range(pitch_min, pitch_max)
	player.bus = "SFX"
	get_tree().root.add_child(player)  # Add to the root
	player.play()
	player.connect("finished", Callable(player, "queue_free"))
	
