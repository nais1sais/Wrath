extends Area3D
@export var REAPER: CharacterBody3D
@export var checkpoint_node: Node3D

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if body == REAPER:
		Save.data["checkpoint_x"] = checkpoint_node.global_transform.origin.x
		Save.data["checkpoint_y"] = checkpoint_node.global_transform.origin.y
		Save.data["checkpoint_z"] = checkpoint_node.global_transform.origin.z
		Save.data["checkpoint_rotation_y"] = checkpoint_node.global_transform.basis.get_euler().y
		Save.save_game()
