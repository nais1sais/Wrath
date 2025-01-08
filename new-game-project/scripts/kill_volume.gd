extends Area3D

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if body is not CharacterBody3D: return
	body.health = 0
	if body.has_method("death"): body.death()
