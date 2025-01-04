extends CharacterBody3D
@export var SPEED = 5.0
@export var JUMP_VELOCITY = 4.5
@export var MOUSE_SENSITIVITY = 0.003
@export var TURN_INFLUENCE: float = 1.0
@export var CAMERA: Camera3D
@export var MESH: MeshInstance3D
@export var PIVOT: Node3D

var mouse_delta = Vector2.ZERO
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_delta += event.relative

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:

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
		var mesh_direction = Vector3(0, 0, 1).rotated(Vector3.UP, MESH.rotation.y) 
		velocity.x = mesh_direction.x * SPEED
		velocity.z = mesh_direction.z * SPEED

		var direction = (Vector3(input_direction.x, 0, input_direction.y)).normalized()
		var target_rotation = atan2(direction.x, direction.z)
		MESH.rotation.y = lerp_angle(MESH.rotation.y, target_rotation + PIVOT.rotation.y, 8.0 * TURN_INFLUENCE * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
