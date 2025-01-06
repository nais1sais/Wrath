extends CharacterBody3D
@export var REAPER: CharacterBody3D
@export var ANIM: AnimationPlayer
@export var NAV_REGION: NavigationRegion3D 
@export var NAV_AGENT: NavigationAgent3D
@export var HEALTH_BAR: ProgressBar
@export var MESH: Node3D
@export var MAX_HEALTH = 50
@export var SPEED = 2.0
@export var ATTACK_AREA: Area3D
const JUMP_VELOCITY = 4.5
var health = MAX_HEALTH

func _ready() -> void:
	HEALTH_BAR.max_value = MAX_HEALTH
	HEALTH_BAR.value = health
	ATTACK_AREA.connect("body_entered", Callable(self, "_on_attack_area_body_entered"))

func death() -> void:
	queue_free()

func _on_attack_area_body_entered(body: Node) -> void:
	if body == self: return
	if body is not CharacterBody3D: return
	if not body.health: return
	body.health -= 10;
	if body.health > 0: return
	if body.has_method("death"): body.death()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		
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

	move_and_slide()
	
