extends CharacterBody3D

@export_group("Difficulty")
@export var MAX_HEALTH: int = 30
@export var SPEED = 9.0
@export var JUMP_ATTACK_PERCENTAGE = 0.8
@export var SLAM_ATTACK_PERCENTAGE = 2.2
@export var TRACKING_SPEED: float = 5.0
@export var TRACKING_MULTIPLIER: float = 1.0
@export var ATTACK_ANIMATION: Array[String] = []
@export var ATTACK_RADIUS: Array[float] = []
@export var ATTACK_LIKELEHOOD: Array[Curve] = []

@export_group("References")
@export var REAPER: CharacterBody3D
@export var ANIM: AnimationPlayer
@export var MESH_ANIM: AnimationPlayer
@export var MESH: Node3D
@export var NAV_REGION: NavigationRegion3D 
@export var NAV_AGENT: NavigationAgent3D
@export var HEALTH_BAR: ProgressBar
@export var RIGHT_HAND_ATTACK_AREA: Area3D
@export var LEFT_HAND_ATTACK_AREA: Area3D
@export var JUMP_ATTACK_AREA: Area3D
@export var TORSO_ATTACK_AREA: Area3D
@export var TRIGGER_AREA: Area3D
@export var PROGRESSION_AREA: Area3D 
@export var DEATH_PARTICLE_SCENE: PackedScene
@export var BODY_MATERIAL: ShaderMaterial

@export_group("Sounds")
@export var MUSIC: Node
@export var HIT_SOUNDS: Array[AudioStream] = []
@export var SLAM_SOUNDS: Array[AudioStream] = []

var health = MAX_HEALTH
var triggered = false;
var target_direction = Vector3.ZERO

func root_motion() -> void: # Make sure mesh anim uses physics callback or will not be moving enough
	var root_motion_position = MESH_ANIM.get_root_motion_position() 
	var transformed_root_motion = MESH.global_transform.basis * root_motion_position
	global_transform.origin += transformed_root_motion; 
func track_towards_direction(delta: float) -> void:
	if target_direction.length_squared() > 0:
		target_direction = target_direction.normalized()
	var target_basis = Basis.looking_at(target_direction, Vector3.UP)
	var interpolated_basis = MESH.global_transform.basis.slerp(target_basis, TRACKING_SPEED * TRACKING_MULTIPLIER * delta)
	MESH.global_transform.basis = interpolated_basis.orthonormalized()
func unlock_progression() -> void:
	PROGRESSION_AREA.monitoring = true
func play_SLAM_sound() -> void:
	if SLAM_SOUNDS.size() > 0:
		Audio.play_2d_sound(SLAM_SOUNDS[randi() % SLAM_SOUNDS.size()], 0.9, 1.1)
func dissolve_body(speed: float, amount: float) -> void:
	var tween = create_tween()
	tween.tween_property(BODY_MATERIAL, "shader_parameter/dissolve_amount", amount, speed)
func damage(_amount: float) -> void:
	REAPER.CAMERA.shake += 1
	if HIT_SOUNDS.size() > 0:
		Audio.play_2d_sound(HIT_SOUNDS[randi() % HIT_SOUNDS.size()], 0.9, 1.1)
func death() -> void:
	ANIM.play("DEATH",0,1,false)
	Save.data["wrath_defeated"] = true
	Save.save_game()
	MUSIC._connect_exit_queue_free()
func spawn_death_particles() -> void:
	if DEATH_PARTICLE_SCENE:
		var particles = DEATH_PARTICLE_SCENE.instantiate()
		particles.global_transform = global_transform
		get_parent().add_child(particles)
func shake_camera() -> void:
	REAPER.CAMERA.shake += 3
func _on_attack_area_body_entered(body: Node) -> void:
	if body == self: return
	if body is not CharacterBody3D: return
	if not body.health: return
	REAPER.health -= 10;
	if body.has_method("damage"): body.damage(10)	
func _on_trigger_area_body_entered(body: Node) -> void:
	if body != REAPER: return
	if triggered: return
	triggered = true
	ANIM.play("INTRO")
func _on_jump_attack_area_body_entered(body: Node) -> void:	
	if body != REAPER: return
	if REAPER.is_on_floor():
		REAPER.health -= 10;
		REAPER.damage(10)

func _ready() -> void:
	
	target_direction = -global_transform.basis.z.normalized()
	REAPER = get_tree().root.get_node("Main/Reaper")
	dissolve_body(0,1)
	if Save.data.has("wrath_defeated") and Save.data["wrath_defeated"]:
		queue_free()
		MUSIC.queue_free()

	health = MAX_HEALTH
	HEALTH_BAR.max_value = MAX_HEALTH
	HEALTH_BAR.value = health
	RIGHT_HAND_ATTACK_AREA.connect("body_entered", Callable(self, "_on_attack_area_body_entered"))
	LEFT_HAND_ATTACK_AREA.connect("body_entered", Callable(self, "_on_attack_area_body_entered"))
	TORSO_ATTACK_AREA.connect("body_entered", Callable(self, "_on_attack_area_body_entered"))
	TRIGGER_AREA.connect("body_entered", Callable(self, "_on_trigger_area_body_entered"))
	JUMP_ATTACK_AREA.connect("body_entered", Callable(self, "_on_jump_attack_area_body_entered"))

func _physics_process(delta: float) -> void:

	root_motion()
	if health > 0: 
		move_and_slide()
	else:
		velocity = Vector3(0, 0, 0)
	if not is_on_floor(): velocity += get_gravity() * delta
	if not triggered or health <= 0: return;
	HEALTH_BAR.value = health
	if REAPER.health <= 0: MUSIC._connect_exit_queue_free()
	track_towards_direction(delta)
	target_direction = (REAPER.global_transform.origin - global_transform.origin).normalized()

	if ANIM.current_animation == "CHASE" and global_transform.origin.distance_to(REAPER.global_transform.origin) > 2.0:
		NAV_AGENT.target_position = REAPER.global_transform.origin
		var direction = NAV_AGENT.get_next_path_position() - global_transform.origin
		direction.y = 0  # Ignore vertical movement
		velocity.x = direction.normalized().x * SPEED
		velocity.z = direction.normalized().z * SPEED
		if direction.length() > 0: target_direction = direction
	else:
		velocity.x = 0
		velocity.z = 0

	if not ANIM.current_animation in ["CHASE"]: return
		
	var indices = range(ATTACK_ANIMATION.size())  
	indices.shuffle();  #print(indices) # randomly sort attacks to distrubte priorty
	for i in indices:
		var normalized_distance = clamp(global_transform.origin.distance_to(REAPER.global_transform.origin) / ATTACK_RADIUS[i], 0.0, 1.0)
		var attack_likelihood = ATTACK_LIKELEHOOD[i].sample(randf()) * (1.0 - normalized_distance)
		attack_likelihood *= delta 
		attack_likelihood *= (1 / delta)
		if randf() < attack_likelihood:
			ANIM.play(ATTACK_ANIMATION[i])
			break
		
