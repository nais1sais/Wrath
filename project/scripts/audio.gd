extends Node

func play_2d_sound(sound: AudioStream, pitch_min: float, pitch_max: float) -> AudioStreamPlayer2D:
	var player = AudioStreamPlayer2D.new()
	player.stream = sound
	player.pitch_scale = randf_range(pitch_min, pitch_max)
	player.bus = "SFX"
	player.connect("tree_entered", Callable(player, "play"))
	player.connect("finished", Callable(player, "queue_free"))
	get_tree().root.call_deferred("add_child", player)
	return player
