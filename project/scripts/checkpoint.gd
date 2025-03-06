extends Area3D
@export var REAPER: CharacterBody3D
@export var CHECKPOINT_NODE: Node3D
@export var CHECKPOINT_SCENE_PATH: String
@export var ANIM: AnimationPlayer

func _on_body_entered(body: Node) -> void:
	if body != REAPER: return

	if Save.data.has("checkpoint_node_path") and get_path() == NodePath(Save.data["checkpoint_node_path"]) and \
	   Save.data.has("checkpoint_scene_path") and Save.data["checkpoint_scene_path"] == get_tree().current_scene.scene_file_path:
		return  # Skip if already acquired
	
	ANIM.play("ACQUIRED")  
	Save.data["checkpoint_node_path"] = get_path()
	Save.data["checkpoint_scene_path"] = get_tree().current_scene.scene_file_path
	Save.save_game()
