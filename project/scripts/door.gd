extends Node3D
@export var REAPER: CharacterBody3D
@export var ZONES: Node
@export var DESTINATION_SCENE_PATH: String
@export var NEW_POSITION_PATH: String
@export var AREA: Area3D
@export var DOOR_SOUNDS: Array[AudioStream] = []

func _change_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)

func _on_area_body_entered(body: Node) -> void:
	if body != REAPER: return
	if not DESTINATION_SCENE_PATH: return

	var new_scene = ResourceLoader.load(DESTINATION_SCENE_PATH)
	if new_scene and new_scene is PackedScene:
		var new_zone = new_scene.instantiate()
		
		ZONES.add_child(new_zone)
		Audio.play_2d_sound(DOOR_SOUNDS[randi() % DOOR_SOUNDS.size()], 0.9, 1.1)
		if NEW_POSITION_PATH:
			var NEW_POSITION = new_zone.get_node(NEW_POSITION_PATH)
			if NEW_POSITION:
				REAPER.position = Vector3(0, 0, 0)
				REAPER.global_transform.origin = NEW_POSITION.global_transform.origin
			else:
				print("Node not found at path:", NEW_POSITION_PATH)

	var children = ZONES.get_children()
	for i in range(len(children) - 1):  # Exclude the new added zone
		children[i].queue_free()

func _ready() -> void:
	REAPER = get_tree().root.get_node("Main/Reaper")
	ZONES = get_tree().root.get_node("Main/Zones")
	AREA.connect("body_entered", Callable(self, "_on_area_body_entered"))
