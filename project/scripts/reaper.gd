extends CharacterBody3D

@export_group("Movement")
@export var SPEED = 5.35
@export var SPRINT_MULTIPLIER = 2.1
@export var MAX_STAMINA = 10.0
@export var MAX_HEALTH = 10.0
@export var STAMINA_RECOVERY_SPEED = 20.0
@export var SPEED_FRICTION = 0.9999999999
@export var JUMP_VELOCITY = 14.0
@export var GRAVITY_MULTIPLIER = 4
@export var MOUSE_SENSITIVITY = 0.003
@export var TURN_SPEED: float = 16.0
@export var TURN_MULTIPLIER: float = 1.0
@export var SPEED_MULTIPLIER: float = 1.0
@export var COYOTE_TIME: float = .4
@export var JUMP_BUFFER_TIME: float = .2
@export var LOCK_ON_SPEED = 7

@export_group("Visuals")
@export var SQUASH_AMOUNT = .23
@export var SQUASH_SPEED = .09
func update_squash(target_squash: float, squash_speed: float, delta: float):
	if delta == 0: return
	var current_squash = MESH.scale.y
	current_squash = lerp(current_squash, target_squash, (delta * squash_speed) * (1.0 / delta))
	var squash_compensation = 1 - ((current_squash - 1) * .5)
	MESH.scale.y = current_squash
	MESH.scale.x = squash_compensation
	MESH.scale.z = squash_compensation

@export_group("References")
@export var CAMERA: Camera3D
@export var MESH: Node3D
@export var PIVOT: Node3D
@export var ATTACK_AREA: Area3D
@export var LOCK_ON_AREA: Area3D
@export var ANIM: AnimationPlayer
@export var MESH_ANIM: AnimationPlayer
@export var COLLISON_SHAPE: CollisionShape3D

@export_group("Material")
@export var CLOAK_TEXTURE: Texture2D
@export var ALTERNATIVE_CLOAK_TEXTURE: Texture2D
@export var CLOAK_MATERIAL: ShaderMaterial
@export var BODY_MATERIAL: ShaderMaterial
@export var STAFF_MATERIAL: ShaderMaterial
func dissolve_cloak(speed: float, amount: float) -> void:
	var tween = create_tween()
	tween.tween_property(CLOAK_MATERIAL, "shader_parameter/dissolve_amount", amount, speed)
func dissolve_body(speed: float, amount: float) -> void:
	var tween = create_tween()
	tween.tween_property(BODY_MATERIAL, "shader_parameter/dissolve_amount", amount, speed)
func dissolve_staff(speed: float, amount: float) -> void:
	var tween = create_tween()
	tween.tween_property(STAFF_MATERIAL, "shader_parameter/dissolve_amount", amount, speed)
var alternative_cloak = false

@export_group("UI")
@export var STAMINA_BAR: ProgressBar
@export var HEALTH_BAR: ProgressBar
@export var BAR_PIXEL_WIDTH = 4
func update_ui():
	STAMINA_BAR.size.x = MAX_STAMINA * BAR_PIXEL_WIDTH
	HEALTH_BAR.size.x = MAX_HEALTH * BAR_PIXEL_WIDTH
	STAMINA_BAR.max_value = MAX_STAMINA
	HEALTH_BAR.max_value = MAX_HEALTH
	STAMINA_BAR.value = stamina
	HEALTH_BAR.value = health

@export_group("Sounds")
@export var SPAWN_SOUND_INDEX: int = 0
@export var SPAWN_SOUNDS: Array[AudioStream] = [] 
@export var SPAWN_PLAYER: AudioStreamPlayer2D
@export var JUMP_SOUNDS: Array[AudioStream] = []
@export var LAND_SOUNDS: Array[AudioStream] = []
@export var FOOTSTEP_SOUNDS: Array[AudioStream] = []
@export var SPIN_SOUNDS: Array[AudioStream] = []
@export var WINDOWN_SOUNDS: Array[AudioStream] = []
@export var HURT_SOUNDS: Array[AudioStream] = []
@export var DEATH_SOUNDS: Array[AudioStream] = []
func play_spin_sound() -> void:
	if SPIN_SOUNDS.size() > 0:
		Audio.play_2d_sound(SPIN_SOUNDS[randi() % SPIN_SOUNDS.size()], 0.9, 1.1)
func play_windown_sound() -> void:
	if WINDOWN_SOUNDS.size() > 0:
		Audio.play_2d_sound(WINDOWN_SOUNDS[randi() % WINDOWN_SOUNDS.size()], 0.9, 1.1)
func play_footstep_sound() -> void:
	if FOOTSTEP_SOUNDS.size() > 0:
		Audio.play_2d_sound(FOOTSTEP_SOUNDS[randi() % FOOTSTEP_SOUNDS.size()], 0.9, 1.1)
func play_hurt_sound() -> void:
	if HURT_SOUNDS.size() > 0:
		Audio.play_2d_sound(HURT_SOUNDS[randi() % HURT_SOUNDS.size()], 0.9, 1.1, -10, -10)
func play_death_sound() -> void:
	if DEATH_SOUNDS.size() > 0:
		Audio.play_2d_sound(DEATH_SOUNDS[randi() % DEATH_SOUNDS.size()], 0.9, 1.1, -10, -10)

var mouse_delta = Vector2.ZERO
var health = MAX_HEALTH
var stamina = MAX_STAMINA
var falling = COYOTE_TIME;
var was_on_floor = true
var has_been_on_floor = false
var jump_buffer = 0;
var lock_on_activated = false
var lock_on_target: CharacterBody3D

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_delta += event.relative
func damage(_amount: float) -> void:
	if health > 0:
		ANIM.play("HURT")
		CAMERA.shake += 3
	if (health <= 0):
		death()		
func death() -> void:
	if ANIM.current_animation == "DEATH": return
	Save.data["deaths"] += 1
	ANIM.play("DEATH")
func fall_death() -> void:
	if ANIM.current_animation == "FALL_DEATH": return
	Save.data["deaths"] += 1
	ANIM.play("FALL_DEATH")	
func reload_checkpoint() -> void:
	Save.data["spawn_sound_index"] = SPAWN_SOUND_INDEX
	Save.save_game()
	get_tree().change_scene_to_file(Save.data["checkpoint_scene_path"])

func _on_animation_finished(animation_name: String) -> void:
	if animation_name == "WINDOWN":
		ANIM.play("IDLE", 0.0, 1, false)
		ANIM.seek(0, true)
		MESH_ANIM.playback_default_blend_time = 0.2

	if animation_name == "SPIN":
		if Input.is_action_pressed("attack") and stamina > 0:
			MESH_ANIM.playback_default_blend_time = 0.0
			ANIM.play("SPIN", 0.0, 1, false)
			ANIM.seek(0, true)
			stamina -= 10
			STAMINA_BAR.value = stamina
			
		else:
			MESH_ANIM.playback_default_blend_time = 0.0
			ANIM.play("WINDOWN", 0.0, 1, false)
			ANIM.seek(0, true) 
	
	if animation_name == "WINDUP":
		MESH_ANIM.playback_default_blend_time = 0.0
		ANIM.play("SPIN", 0.0, 1, false)
		ANIM.seek(0, true) 
		stamina -= 10
		STAMINA_BAR.value = stamina
func _on_lock_on_area_body_entered(body: Node) -> void:
	if body == self: return
	if body is not CharacterBody3D: return
	lock_on_target = body
func _on_attack_area_body_entered(body: Node) -> void:
	if body == self: return
	if body is not CharacterBody3D: return
	if not body.health: return
	body.damage(1, ATTACK_AREA.global_position)
	body.health -= 1;
	if body.health > 0: return
	if body.has_method("death"): body.death()

func find_node_by_name(target_name: String) -> Node:
	var stack = [get_tree().get_root()]
	while stack.size() > 0:
		var node = stack.pop_back()
		if node.name == target_name:
			return node
		stack += node.get_children()
	return null
func _load() -> void: 	

	if not Save.data.has("deaths"):
		Save.data["deaths"] = 0

	if Save.data.has("max_health"):
		MAX_HEALTH = Save.data["max_health"]
		health = MAX_HEALTH
	if Save.data.has("max_stamina"):
		MAX_STAMINA = Save.data["max_stamina"]
		stamina = MAX_STAMINA
	Save.data["max_health"] = MAX_HEALTH
	Save.data["max_stamina"] = MAX_STAMINA	

	if Save.data.has("door_node_name"):		
		var door_node = find_node_by_name(Save.data["door_node_name"])
		if door_node: if door_node.START: global_transform = door_node.START.global_transform
		$FadeIn.play("DOOR_FADE_IN")
		Save.data.erase("door_node_name")
		Save.save_game()
		return
	
	if Save.data.has("checkpoint_scene_path"):
		if get_tree().current_scene and get_tree().current_scene.scene_file_path != Save.data["checkpoint_scene_path"]:
			get_tree().call_deferred("change_scene_to_file", Save.data["checkpoint_scene_path"])
			return
	if not Save.data.has("checkpoint_scene_path"):
		Save.data["checkpoint_scene_path"] = get_tree().current_scene.scene_file_path
	if Save.data.has("checkpoint_node_path"):
		var checkpoint_node = get_node_or_null(Save.data["checkpoint_node_path"])
		if checkpoint_node: global_transform = checkpoint_node.global_transform
		
	if Save.data.has("spawn_sound_index"):
		SPAWN_SOUND_INDEX = Save.data["spawn_sound_index"]
	SPAWN_PLAYER.stream = SPAWN_SOUNDS[SPAWN_SOUND_INDEX]	
	SPAWN_PLAYER.play()

func _ready() -> void:
	
	_load()
	dissolve_cloak(0,0)
	dissolve_body(0,0)
	dissolve_staff(0,0)
	update_ui()
	
func _physics_process(delta: float) -> void:
		
	if Save.data.has("play_time"):
		Save.data["play_time"] += delta	
	else:
		Save.data["play_time"] = delta	
		
	if Input.is_action_just_pressed("debug"):
		alternative_cloak = !alternative_cloak
		if alternative_cloak:
			CLOAK_MATERIAL.set_shader_parameter("base_texture", ALTERNATIVE_CLOAK_TEXTURE)
		else:
			CLOAK_MATERIAL.set_shader_parameter("base_texture", CLOAK_TEXTURE)

	update_squash(1, SQUASH_SPEED, delta)
	
	update_ui()
	
	if not was_on_floor and is_on_floor() and has_been_on_floor:
		if LAND_SOUNDS.size() > 0:
			update_squash(1 - SQUASH_AMOUNT, 1, delta)
			Audio.play_2d_sound(LAND_SOUNDS[randi() % LAND_SOUNDS.size()], 0.9, 1.1)		
	was_on_floor = is_on_floor()
	if is_on_floor(): has_been_on_floor = true
	
	if ANIM.current_animation in "ESCAPE": return

	if Input.is_action_just_pressed("attack"): # ATTACK
		if is_on_floor():
			if ANIM.current_animation not in ["WINDUP", "SPIN", "WINDOWN", "DEATH", "FALL_DEATH", "HURT"]:
				ANIM.play("WINDUP")
		
	if not Input.is_action_pressed("attack"): # STAMINA RECOVERY
		stamina += STAMINA_RECOVERY_SPEED * delta
		if stamina > MAX_STAMINA: stamina = MAX_STAMINA
		STAMINA_BAR.value = stamina
		
	if not is_on_floor(): # GRAVITY
		velocity += get_gravity() * GRAVITY_MULTIPLIER * delta

	if is_on_floor(): 
		falling = 0
	else:
		falling += delta;

	if Input.is_action_just_pressed("jump"): 
		jump_buffer = JUMP_BUFFER_TIME;
	else:
		if jump_buffer > 0:
			jump_buffer -= delta;

	if jump_buffer > 0 and falling < COYOTE_TIME: # JUMP
		if ANIM.current_animation not in ["WINDOWN", "WINDUP", "SPIN", "DEATH", "FALL_DEATH", "HURT"]:
			if JUMP_SOUNDS.size() > 0:  
				Audio.play_2d_sound(JUMP_SOUNDS[randi() % JUMP_SOUNDS.size()], 0.9, 1.1)
			ANIM.play("JUMP")
			update_squash(1 + SQUASH_AMOUNT, 1, delta)
			velocity.y = JUMP_VELOCITY
			falling = COYOTE_TIME
			jump_buffer = 0

	if Input.is_action_just_pressed("lock_on"):
		lock_on_activated = !lock_on_activated
	
	var look_left_right = Input.get_axis("look_left", "look_right")
	var look_up_down = Input.get_axis("look_down", "look_up")
	mouse_delta.x += look_left_right * MOUSE_SENSITIVITY * 3000
	mouse_delta.y -= look_up_down * MOUSE_SENSITIVITY * 3000
		
	if lock_on_activated:
		if lock_on_target and is_instance_valid(lock_on_target):
			var target_position = lock_on_target.global_transform.origin
			var current_rotation = PIVOT.global_transform.basis.get_rotation_quaternion()
			PIVOT.look_at(target_position + PIVOT.position, Vector3.UP)
			var new_rotation = PIVOT.global_transform.basis.get_rotation_quaternion()
			
			PIVOT.global_transform.basis = Basis(current_rotation.slerp(new_rotation, LOCK_ON_SPEED * delta))

			mouse_delta = Vector2.ZERO

	if mouse_delta.length() > 0:
		
		var y_rot = Quaternion(Vector3.UP, -mouse_delta.x * MOUSE_SENSITIVITY)
		var x_rot = Quaternion($Pivot.transform.basis.x.normalized(), -mouse_delta.y * MOUSE_SENSITIVITY)
		$Pivot.transform.basis = Basis(y_rot) * Basis(x_rot) * $Pivot.transform.basis

		mouse_delta = Vector2.ZERO

	if ANIM.current_animation not in ["WINDUP", "SPIN", "WINDOWN","DEATH", "FALL_DEATH", "HURT"] and !is_on_floor():
		if (velocity.y < 0):
			ANIM.play("FALL")
		else:
			ANIM.play("JUMP")

	var keyboard_vector := Input.get_vector("keyboard_left", "keyboard_right", "keyboard_forward", "keyboard_back")
	var controller_vector := Input.get_vector("controller_left", "controller_right", "controller_forward", "controller_back")
	var input_vector := keyboard_vector + controller_vector
	
	if input_vector.length() > 0:
		var mesh_direction = Vector3(0, 0, -1).rotated(Vector3.UP, MESH.rotation.y + global_transform.basis.get_euler().y)
		if (Input.is_action_pressed("sprint") or controller_vector.length() > 0.75) and stamina > 0:
			if ANIM.current_animation not in ["WINDUP", "SPIN", "WINDOWN", "DEATH", "FALL_DEATH", "HURT"] and is_on_floor():
				ANIM.play("RUN", 0.0, 1, false)
			velocity.x = mesh_direction.x * SPEED * SPRINT_MULTIPLIER * SPEED_MULTIPLIER
			velocity.z = mesh_direction.z * SPEED * SPRINT_MULTIPLIER * SPEED_MULTIPLIER
		else:
			if ANIM.current_animation not in ["WINDUP", "SPIN", "WINDOWN", "DEATH", "FALL_DEATH", "HURT"] and is_on_floor():
				ANIM.play("WALK", 0.0, 1, false)
			velocity.x = mesh_direction.x * SPEED * SPEED_MULTIPLIER
			velocity.z = mesh_direction.z * SPEED * SPEED_MULTIPLIER

		var direction = (Vector3(input_vector.x, 0, input_vector.y)).normalized()
		var target_rotation = atan2(direction.x, direction.z) + PI
		MESH.rotation.y = lerp_angle(MESH.rotation.y, target_rotation + PIVOT.rotation.y, TURN_SPEED * TURN_MULTIPLIER * delta)
	else:
		if ANIM.current_animation not in ["WINDUP", "SPIN", "WINDOWN", "DEATH", "FALL_DEATH", "HURT"] and is_on_floor():
			ANIM.play("IDLE", 0, 1, false)
		velocity.x = 0 
		velocity.z = 0

	move_and_slide()
