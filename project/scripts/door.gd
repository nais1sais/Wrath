extends Node3D
@export var REAPER: CharacterBody3D
@export var MESH: Node
@export var ZONES: Node
@export var DESTINATION_SCENE_PATH: String
@export var NEW_POSITION_PATH: String
@export var AREA: Area3D
@export var ANIM: AnimationPlayer
@export var DOOR_SOUNDS: Array[AudioStream] = []

func play_door_sound() -> void:
	if DOOR_SOUNDS.size() > 0:
		Audio.play_2d_sound(DOOR_SOUNDS[randi() % DOOR_SOUNDS.size()], 0.9, 1.1)

func _change_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)

func _freeze_player(freeze: float) -> void:
	REAPER.SPEED_MULTIPLIER = freeze
	REAPER.TURN_MULTIPLIER = freeze

func _load_new_scene() -> void:
	var new_scene = ResourceLoader.load(DESTINATION_SCENE_PATH)
	if new_scene and new_scene is PackedScene:
		var new_zone = new_scene.instantiate()
		if get_parent() != null: get_parent().remove_child(self)
		new_zone.add_child(self)
		AREA.queue_free()
		ZONES.add_child(new_zone)
		
		if NEW_POSITION_PATH:
			var NEW_POSITION = new_zone.get_node(NEW_POSITION_PATH)
			if NEW_POSITION:
				REAPER.position = Vector3(0, 0, 0)
				REAPER.MESH.global_transform.basis = REAPER.MESH.get_parent().global_transform.basis
				REAPER.PIVOT.global_transform.basis = REAPER.MESH.get_parent().global_transform.basis
				REAPER.global_transform = NEW_POSITION.global_transform
			else:
				print("Node not found at path:", NEW_POSITION_PATH)

	var children = ZONES.get_children()
	for i in range(len(children) - 1):  # Exclude the new added zone
		children[i].queue_free()

func _on_area_body_entered(body: Node) -> void:
	if body != REAPER: return
	if not DESTINATION_SCENE_PATH: return
	if ANIM: ANIM.play("DOOR")

func _ready() -> void:
	REAPER = get_tree().root.get_node("Main/Reaper")
	ZONES = get_tree().root.get_node("Main/Zones")
	AREA.connect("body_entered", Callable(self, "_on_area_body_entered"))
