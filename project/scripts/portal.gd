extends Node3D
@export var AREA: Area3D
@export var CUTSCENE_PLAYER: AnimationPlayer
@export var REAPER: CharacterBody3D
@export var PLAYER_SPOT: Node3D

func _play_end_cutscene()-> void:
	REAPER.global_transform = PLAYER_SPOT.global_transform
	REAPER.ANIM.play("ESCAPE")
	
func _on_body_entered(body: Node) -> void:
	if not body == REAPER: return
	REAPER.position = Vector3(0, 0, 0)
	REAPER.global_transform.origin = PLAYER_SPOT.global_transform.origin
	CUTSCENE_PLAYER.play("ESCAPE")
	
func _ready() -> void:
	
	if Save.data.has("wrath_defeated") and Save.data["wrath_defeated"]:
		AREA.monitoring = true

	REAPER = get_tree().root.get_node("Main/Reaper")
	AREA.connect("body_entered", Callable(self, "_on_body_entered"))
