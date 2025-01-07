extends Camera3D
@export var shake = 0.0
@export var decay_rate = 5.0
@export var max_shake = 10.0
var noise := FastNoiseLite.new()
var shake_offset := Vector3.ZERO

func _ready():
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 2.0

func _process(delta):
	rotation_degrees -= shake_offset # Remove previous frame's shake
	if shake > 0.0:
		shake -= decay_rate * delta
		shake = max(shake, 0.0)
		var time = Engine.get_physics_frames()
		var shake_x = noise.get_noise_2d(time * 0.05, 0.0)
		var shake_y = noise.get_noise_2d(time * 0.05, 1000.0) 
		var shake_z = noise.get_noise_2d(time * 0.05, 2000.0) 
		shake_offset.x = clamp(shake_x * shake, -max_shake, max_shake)
		shake_offset.y = clamp(shake_y * shake, -max_shake, max_shake)
		shake_offset.z = clamp(shake_z * shake, -max_shake, max_shake)
		rotation_degrees += shake_offset
