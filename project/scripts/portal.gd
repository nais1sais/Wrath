extends Node3D
@export var AREA: Area3D
@export var CUTSCENE_PLAYER: AnimationPlayer
@export var REAPER: CharacterBody3D
@export var PLAYER_SPOT: Node3D

func _on_body_entered(body: Node) -> void:
	if not body == REAPER: return
	REAPER.global_transform.origin = PLAYER_SPOT.global_transform.origin
	CUTSCENE_PLAYER.play("ESCAPE")
	
func _ready() -> void:
	AREA.connect("body_entered", Callable(self, "_on_body_entered"))
