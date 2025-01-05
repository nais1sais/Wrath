extends CharacterBody3D
@export var SPEED = 4.0
@export var SPRINT_MULTIPLIER = 2.0
@export var MAX_STAMINA = 50
@export var STAMINA_RECOVERY_SPEED = 30
@export var SPEED_FRICTION = 0.9999999999
@export var JUMP_VELOCITY = 4.5
@export var MOUSE_SENSITIVITY = 0.003
@export var TURN_INFLUENCE: float = 1.0
@export var CAMERA: Camera3D
@export var VISUAL: Node3D
@export var PIVOT: Node3D
@export var ANIM: AnimationPlayer
@export var STAMINA_BAR: ColorRect
var speed_multiplier = 0
var mouse_delta = Vector2.ZERO
var stamina = MAX_STAMINA

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_delta += event.relative

func _on_animation_finished(animation_name: String) -> void:

	if animation_name == "Windown":
		ANIM.play("Idle", 0, 1, false)
		ANIM.seek(0, true)

	if animation_name == "Spin":
		if Input.is_action_pressed("attack") and stamina > 0:
			ANIM.play("Spin", 0, 1, false)
			ANIM.seek(0, true)
			stamina -= 10
			
		else:
			ANIM.play("Windown", 0, 1, false)
			ANIM.seek(0, true) 
	
	if animation_name == "Windup":
		ANIM.play("Spin", 0, 1, false)
		ANIM.seek(0, true) 
		stamina -= 10

func _ready() -> void:
	ANIM.play("Idle")
	ANIM.connect("animation_finished", Callable(self, "_on_animation_finished"))

func _physics_process(delta: float) -> void:

	if (stamina > 0):
		STAMINA_BAR.visible = true;
		STAMINA_BAR.size.x = stamina * 5
	else:
		STAMINA_BAR.visible = false
	#ANIM.current_animation not in ["Windup", "Windown", "Spin"]:
	if Input.is_action_just_pressed("attack"):
		ANIM.play("Windup")
		
	if not Input.is_action_pressed("attack"):
		stamina += STAMINA_RECOVERY_SPEED * delta
		if stamina > MAX_STAMINA: stamina = MAX_STAMINA
		
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
		var visual_direction = Vector3(0, 0, -1).rotated(Vector3.UP, VISUAL.rotation.y) 
		if Input.is_action_pressed("sprint"):
			velocity.x = visual_direction.x * SPEED * SPRINT_MULTIPLIER
			velocity.z = visual_direction.z * SPEED * SPRINT_MULTIPLIER
		else:
			velocity.x = visual_direction.x * SPEED
			velocity.z = visual_direction.z * SPEED

		var direction = (Vector3(input_direction.x, 0, input_direction.y)).normalized()
		var target_rotation = atan2(direction.x, direction.z) + PI
		VISUAL.rotation.y = lerp_angle(VISUAL.rotation.y, target_rotation + PIVOT.rotation.y, 16.0 * TURN_INFLUENCE * delta)
	else:
		velocity.x = 0 
		velocity.z = 0

	move_and_slide()
