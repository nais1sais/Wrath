extends Node

func play_2d_sound(sound: AudioStream, pitch_min: float, pitch_max: float, volume_min: float = 0.0, volume_max: float = 0.0) -> AudioStreamPlayer2D:
	var player = AudioStreamPlayer2D.new()
	player.stream = sound
	player.pitch_scale = randf_range(pitch_min, pitch_max)
	player.volume_db = randf_range(volume_min, volume_max)
	player.bus = "SFX"
	player.attenuation = 0
	player.connect("tree_entered", Callable(player, "play"))
	player.connect("finished", Callable(player, "queue_free"))
	get_tree().root.call_deferred("add_child", player)
	return player
