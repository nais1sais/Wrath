extends Node3D
@export var REAPER: CharacterBody3D

func _ready() -> void:
	REAPER = get_tree().root.get_node("Main/Reaper")

func _process(_delta) -> void:
	global_transform.origin = REAPER.global_transform.origin
