extends Node3D
@export var REAPER: CharacterBody3D
@export var MESH: Node
@export var DESTINATION_SCENE_PATH: String
@export var NEW_POSITION_PATH: String
@export var AREA: Area3D
@export var ANIM: AnimationPlayer
@export var DOOR_SOUNDS: Array[AudioStream] = []
#
func play_door_sound() -> void:
	if DOOR_SOUNDS.size() > 0:
		Audio.play_2d_sound(DOOR_SOUNDS[randi() % DOOR_SOUNDS.size()], 0.9, 1.1)

func _change_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)

func _freeze_player(freeze: float) -> void:
	REAPER.SPEED_MULTIPLIER = freeze
	REAPER.TURN_MULTIPLIER = freeze

func _load_new_scene() -> void:
	Save.data["door_node_path"] = NEW_POSITION_PATH
	Save.save_game()
	get_tree().change_scene_to_file(DESTINATION_SCENE_PATH)

func _on_area_body_entered(body: Node) -> void:
	if body != REAPER: return
	if not DESTINATION_SCENE_PATH: return
	if ANIM: ANIM.play("DOOR")

func _ready() -> void:
	AREA.connect("body_entered", Callable(self, "_on_area_body_entered"))
