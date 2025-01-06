extends CharacterBody3D
@export var SPEED = 4.0
@export var SPRINT_MULTIPLIER = 2.0
@export var MAX_STAMINA = 50.0
@export var MAX_HEALTH = 50.0
@export var STAMINA_RECOVERY_SPEED = 30.0
@export var SPEED_FRICTION = 0.9999999999
@export var JUMP_VELOCITY = 4.5
@export var MOUSE_SENSITIVITY = 0.003
@export var TURN_INFLUENCE: float = 1.0
@export var CAMERA: Camera3D
@export var MESH: Node3D
@export var PIVOT: Node3D
@export var ANIM: AnimationPlayer
@export var STAMINA_BAR: ProgressBar
@export var HEALTH_BAR: ProgressBar
@export var ATTACK_AREA: Area3D
var mouse_delta = Vector2.ZERO
var health = 50
var stamina = MAX_STAMINA

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_delta += event.relative

func death() -> void:
	get_tree().reload_current_scene()

func _on_animation_finished(animation_name: String) -> void:

	if animation_name == "WINDOWN":
		ANIM.play("IDLE", 0, 1, false)
		ANIM.seek(0, true)

	if animation_name == "SPIN":
		if Input.is_action_pressed("attack") and stamina > 0:
			ANIM.play("SPIN", 0, 1, false)
			ANIM.seek(0, true)
			stamina -= 10
			STAMINA_BAR.value = stamina
			
		else:
			ANIM.play("WINDOWN", 0, 1, false)
			ANIM.seek(0, true) 
	
	if animation_name == "WINDUP":
		ANIM.play("SPIN", 0, 1, false)
		ANIM.seek(0, true) 
		stamina -= 10
		STAMINA_BAR.value = stamina

func _ready() -> void:
	ANIM.play("IDLE")
	ANIM.connect("animation_finished", Callable(self, "_on_animation_finished"))
	ATTACK_AREA.connect("body_entered", Callable(self, "_on_attack_area_body_entered"))
	STAMINA_BAR.max_value = MAX_STAMINA
	STAMINA_BAR.value = stamina
	HEALTH_BAR.max_value = MAX_HEALTH
	HEALTH_BAR.value = health

func _on_attack_area_body_entered(body: Node) -> void:
	if body == self: return
	if body is not CharacterBody3D: return
	if not body.health: return
	body.health -= 1;
	if body.health > 0: return
	if body.has_method("death"): body.death()

func _physics_process(delta: float) -> void:

	HEALTH_BAR.value = health

	#ANIM.current_animation not in ["WINDUP", "WINDOWN", "SPIN"]:
	if Input.is_action_just_pressed("attack"):
		ANIM.play("WINDUP")
		
	if not Input.is_action_pressed("attack"):
		stamina += STAMINA_RECOVERY_SPEED * delta
		if stamina > MAX_STAMINA: stamina = MAX_STAMINA
		STAMINA_BAR.value = stamina
		
	if not is_on_floor(): # Gravity
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if mouse_delta.length() > 0:
		var y_rot = Quaternion(Vector3.UP, -mouse_delta.x * MOUSE_SENSITIVITY)
		var x_rot = Quaternion($Pivot.transform.basis.x.normalized(), -mouse_delta.y * MOUSE_SENSITIVITY)
		$Pivot.transform.basis = Basis(y_rot) * Basis(x_rot) * $Pivot.transform.basis

		mouse_delta = Vector2.ZERO

	var input_direction := Input.get_vector("left", "right", "forward", "back")
	if input_direction.length() > 0:
		var mesh_direction = Vector3(0, 0, -1).rotated(Vector3.UP, MESH.rotation.y + global_transform.basis.get_euler().y)
		if Input.is_action_pressed("sprint"): 
			velocity.x = mesh_direction.x * SPEED * SPRINT_MULTIPLIER
			velocity.z = mesh_direction.z * SPEED * SPRINT_MULTIPLIER
		else:
			velocity.x = mesh_direction.x * SPEED
			velocity.z = mesh_direction.z * SPEED

		var direction = (Vector3(input_direction.x, 0, input_direction.y)).normalized()
		var target_rotation = atan2(direction.x, direction.z) + PI
		MESH.rotation.y = lerp_angle(MESH.rotation.y, target_rotation + PIVOT.rotation.y, 16.0 * TURN_INFLUENCE * delta)
	else:
		velocity.x = 0 
		velocity.z = 0

	move_and_slide()
