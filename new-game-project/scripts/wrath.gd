extends CharacterBody3D
@export var REAPER: CharacterBody3D
@export var ANIM: AnimationPlayer
@export var NAV_REGION: NavigationRegion3D 
@export var NAV_AGENT: NavigationAgent3D
@export var HEALTH_BAR: ProgressBar
@export var MESH: Node3D
@export var MAX_HEALTH: int = 30
@export var SPEED = 2.0
@export var ATTACK_AREA: Area3D
@export var TRIGGER_AREA: Area3D
@export var DEATH_PARTICLE_SCENE: PackedScene
@export var MUSIC: AudioStreamPlayer2D

@export var HIT_SOUNDS: Array[AudioStream] = []
const JUMP_VELOCITY = 4.5
var health = MAX_HEALTH
var triggered = false;

func play_sound(sound: AudioStream, pitch_min: float, pitch_max: float) -> void:
	var player = AudioStreamPlayer2D.new()
	player.stream = sound
	player.pitch_scale = randf_range(pitch_min, pitch_max) 
	player.bus = "SFX"
	add_child(player)
	player.play()
	player.connect("finished", Callable(player, "queue_free"))

func damage(_amount: float) -> void:
	REAPER.CAMERA.shake += 1
	if HIT_SOUNDS.size() > 0:
		play_sound(HIT_SOUNDS[randi() % HIT_SOUNDS.size()], 0.9, 1.1)

func death() -> void:
	ANIM.play("DEATH",0,1,false)

func spawn_death_particles() -> void:
	if DEATH_PARTICLE_SCENE:
		var particles = DEATH_PARTICLE_SCENE.instantiate()
		particles.global_transform = global_transform
		get_parent().add_child(particles)

func shake_camera() -> void:
	REAPER.CAMERA.shake += 5

func _on_attack_area_body_entered(body: Node) -> void:
	if body == self: return
	if body is not CharacterBody3D: return
	if not body.health: return
	if body.has_method("damage"): body.damage(10)
	body.health -= 10;
	if body.health > 0: return
	if body.has_method("death"): body.death()
	
func _on_trigger_area_body_entered(body: Node) -> void:
	if body != REAPER: return
	if MUSIC.playing == true: return
	MUSIC.playing = true 
	triggered = true
	ANIM.play("INTRODUCTION")

func _ready() -> void:
	health = MAX_HEALTH
	HEALTH_BAR.max_value = MAX_HEALTH
	HEALTH_BAR.value = health
	ATTACK_AREA.connect("body_entered", Callable(self, "_on_attack_area_body_entered"))
	TRIGGER_AREA.connect("body_entered", Callable(self, "_on_trigger_area_body_entered"))

func _physics_process(delta: float) -> void:

	if not is_on_floor():
		velocity += get_gravity() * delta
	
	move_and_slide()
	
	if not triggered or health <= 0: return;
		
	HEALTH_BAR.value = health

	if not ANIM.current_animation == "ATTACK": # MOVE towards player
		NAV_AGENT.target_position = REAPER.global_transform.origin
		var direction = NAV_AGENT.get_next_path_position() - global_transform.origin
		direction.y = 0  # Ignore vertical movement
		velocity.x = direction.normalized().x * SPEED
		velocity.z = direction.normalized().z * SPEED
		
		if direction.length() > 0:  # Prevent issues when direction is zero
			MESH.look_at(global_transform.origin + direction, Vector3.UP)

	if global_transform.origin.distance_to(REAPER.global_transform.origin) < 2.0:  # Example distance threshold
		ANIM.play("ATTACK")

	
