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
@export var SQUASH_AMOUNT = .15
@export var SQUASH_SPEED = .03

@export_group("References")
@export var CAMERA: Camera3D
@export var MESH: Node3D
@export var PIVOT: Node3D
@export var ATTACK_AREA: Area3D
@export var LOCK_ON_AREA: Area3D
@export var ANIM: AnimationPlayer
@export var MESH_ANIM: AnimationPlayer
@export var COLLISON_SHAPE: CollisionShape3D
@export var ZONES: Node
@export var CLOAK_MATERIAL: ShaderMaterial

@export var CLOAK_TEXTURE: Texture2D
@export var ALTERNATIVE_CLOAK_TEXTURE: Texture2D


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
@export var NEW_GAME_SPAWN_SOUND: AudioStream
@export var SPAWN_SOUND: AudioStream
@export var FALL_SPAWN_SOUND: AudioStream
@export var SPAWN_PLAYER: AudioStreamPlayer2D
@export var JUMP_SOUNDS: Array[AudioStream] = []
@export var LAND_SOUNDS: Array[AudioStream] = []
@export var FOOTSTEP_SOUNDS: Array[AudioStream] = []
@export var SPIN_SOUNDS: Array[AudioStream] = []
@export var HURT_SOUNDS: Array[AudioStream] = []
func play_spin_sound() -> void:
	if SPIN_SOUNDS.size() > 0:
		Audio.play_2d_sound(SPIN_SOUNDS[randi() % SPIN_SOUNDS.size()], 0.9, 1.1)
func play_footstep_sound() -> void:
	if FOOTSTEP_SOUNDS.size() > 0:
		Audio.play_2d_sound(FOOTSTEP_SOUNDS[randi() % FOOTSTEP_SOUNDS.size()], 0.9, 1.1)
func play_hurt_sound() -> void:
	if HURT_SOUNDS.size() > 0:
		Audio.play_2d_sound(HURT_SOUNDS[randi() % HURT_SOUNDS.size()], 0.9, 1.1, -10, -10)

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
func dissolve_cloak(speed: float, amount: float) -> void:
	var tween = create_tween()
	tween.tween_property(CLOAK_MATERIAL, "shader_parameter/dissolve_amount", amount, speed)
func damage(_amount: float) -> void:
	ANIM.play("HURT")
	CAMERA.shake += 3
	if (health <= 0):
		death()	
func death() -> void:
	ANIM.play("DEATH")
	Save.data["death_type"] = "regular"
	Save.save_game()
func fall_death() -> void:
	ANIM.play("FALL_DEATH")	
	Save.data["death_type"] = "fall"
	Save.save_game()	
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
		
	if animation_name == "DEATH" or animation_name == "FALL_DEATH":
		get_tree().call_deferred("reload_current_scene")	
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
func update_squash(target_squash: float, squash_speed: float, delta: float):
	if delta == 0: return
	var current_squash = MESH.scale.y
	current_squash = lerp(current_squash, target_squash, (delta * squash_speed) * (1.0 / delta))
	var squash_compensation = 1 - ((current_squash - 1) * .5)
	MESH.scale.y = current_squash
	MESH.scale.x = squash_compensation
	MESH.scale.z = squash_compensation
	
func _ready() -> void:

	if Save.data.has("checkpoint_scene_path"): # loads checkpoint like door
		var new_scene = ResourceLoader.load(Save.data["checkpoint_scene_path"])
		if new_scene and new_scene is PackedScene:
			var new_zone = new_scene.instantiate()
			ZONES.add_child(new_zone)
		var children = ZONES.get_children()
		for i in range(len(children) - 1):  # Exclude the new added zone
			children[i].queue_free()
	if Save.data.has("checkpoint_x") and Save.data.has("checkpoint_y") and Save.data.has("checkpoint_z"):
		position = Vector3(Save.data["checkpoint_x"], Save.data["checkpoint_y"], Save.data["checkpoint_z"])
	if Save.data.has("checkpoint_rotation_y"):
		rotation.y = Save.data["checkpoint_rotation_y"]	
	if Save.data.has("max_health"):
		MAX_HEALTH = Save.data["max_health"]
		health = MAX_HEALTH
	else:
		Save.data["max_health"] = MAX_HEALTH
	if Save.data.has("max_stamina"):
		MAX_STAMINA = Save.data["max_stamina"]
		stamina = MAX_STAMINA
	else:
		Save.data["max_stamina"] = MAX_STAMINA
	if Save.data.has("death_type"):
		if Save.data["death_type"] == "fall":
			SPAWN_PLAYER.stream = FALL_SPAWN_SOUND
		else:
			SPAWN_PLAYER.stream = SPAWN_SOUND
	else:
		SPAWN_PLAYER.stream = NEW_GAME_SPAWN_SOUND
		Save.data["death_type"] = "regular"
		Save.save_game()
	SPAWN_PLAYER.play()
	
	ANIM.play("IDLE")
	ANIM.connect("animation_finished", Callable(self, "_on_animation_finished"))
	if ATTACK_AREA: ATTACK_AREA.connect("body_entered", Callable(self, "_on_attack_area_body_entered"))
	if LOCK_ON_AREA: LOCK_ON_AREA.connect("body_entered", Callable(self, "_on_lock_on_area_body_entered"))
	dissolve_cloak(0,0)
	update_ui()
	
var alternative_cloak = false
	
func _process(delta: float) -> void:
		
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
