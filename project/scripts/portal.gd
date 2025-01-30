extends Node3D
@export var AREA: Area3D
@export var CUTSCENE_PLAYER: AnimationPlayer
@export var ANIM: AnimationPlayer
@export var REAPER: CharacterBody3D
@export var PLAYER_SPOT: Node3D

func _play_end_cutscene()-> void:
	REAPER.ANIM.play("ESCAPE")
	
func _on_body_entered(body: Node) -> void:
	if not body == REAPER: return
	ANIM.play("ESCAPE")
	CUTSCENE_PLAYER.play("ESCAPE")
	
func _freeze_player(freeze: float) -> void:
	REAPER.SPEED_MULTIPLIER = freeze
	REAPER.TURN_MULTIPLIER = freeze
	
func _teleport_player_to_cutscene_spot() -> void:
	REAPER.global_transform.origin = PLAYER_SPOT.global_transform.origin
	REAPER.global_transform = PLAYER_SPOT.global_transform
	REAPER.global_transform = PLAYER_SPOT.global_transform
	REAPER.MESH.transform = Transform3D.IDENTITY
	REAPER.MESH_ANIM.playback_default_blend_time = 0
	
func _return_to_title() -> void:
	get_tree().change_scene_to_file("res://scenes/zones/home.tscn")
	
func _ready() -> void:
	
	if Save.data.has("wrath_defeated") and Save.data["wrath_defeated"]:
		AREA.monitoring = true

	REAPER = get_tree().root.get_node("Main/Reaper")
	AREA.connect("body_entered", Callable(self, "_on_body_entered"))
