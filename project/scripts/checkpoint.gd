extends Area3D
@export var REAPER: CharacterBody3D
@export var CHECKPOINT_NODE: Node3D
@export var CHECKPOINT_SCENE_PATH: String
@export var ANIM: AnimationPlayer

func _on_body_entered(body: Node) -> void:
	if body != REAPER: return

	if (Save.data.has("checkpoint_x") and Save.data["checkpoint_x"] == CHECKPOINT_NODE.global_transform.origin.x) and \
	   (Save.data.has("checkpoint_y") and Save.data["checkpoint_y"] == CHECKPOINT_NODE.global_transform.origin.y) and \
	   (Save.data.has("checkpoint_z") and Save.data["checkpoint_z"] == CHECKPOINT_NODE.global_transform.origin.z) and \
	   (Save.data.has("checkpoint_scene_path") and Save.data["checkpoint_scene_path"] == get_tree().current_scene.scene_file_path):
		return  # Skip if all checkpoint data is already saved
	
	ANIM.play("ACQUIRED")  
	Save.data["checkpoint_x"] = CHECKPOINT_NODE.global_transform.origin.x
	Save.data["checkpoint_y"] = CHECKPOINT_NODE.global_transform.origin.y
	Save.data["checkpoint_z"] = CHECKPOINT_NODE.global_transform.origin.z
	Save.data["checkpoint_rotation_y"] = CHECKPOINT_NODE.global_rotation.y
	Save.data["checkpoint_scene_path"] = get_tree().current_scene.scene_file_path
	Save.save_game()
	
func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))
