extends Area3D
@export var REAPER: CharacterBody3D
@export var CHECKPOINT_NODE: Node3D
@export var CHECKPOINT_SCENE_PATH: String

func _ready() -> void:
	REAPER = get_tree().root.get_node("Main/Reaper")
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if body != REAPER: return
	Save.data["checkpoint_x"] = CHECKPOINT_NODE.global_transform.origin.x
	Save.data["checkpoint_y"] = CHECKPOINT_NODE.global_transform.origin.y
	Save.data["checkpoint_z"] = CHECKPOINT_NODE.global_transform.origin.z
	Save.data["checkpoint_rotation_y"] = CHECKPOINT_NODE.global_transform.basis.get_euler().y
	Save.data["checkpoint_scene_path"] = CHECKPOINT_SCENE_PATH
	Save.save_game()
