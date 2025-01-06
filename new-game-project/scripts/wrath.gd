extends CharacterBody3D
@export var REAPER: CharacterBody3D
@export var ANIM: AnimationPlayer
@export var NAV_REGION: NavigationRegion3D 
@export var NAV_AGENT: NavigationAgent3D
@export var HEALTHBAR: ProgressBar
@export var MESH: Node3D
@export var MAX_HEALTH = 50
@export var SPEED = 2.0
const JUMP_VELOCITY = 4.5
var health = MAX_HEALTH

func _ready() -> void:
	HEALTHBAR.max_value = MAX_HEALTH
	HEALTHBAR.value = health

func death() -> void:
	queue_free()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	HEALTHBAR.value = health

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

	move_and_slide()
	
