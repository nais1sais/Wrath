extends Node3D
@export var REAPER: CharacterBody3D
@export var ANIM: AnimationPlayer
@export var ENTER_AREA: Area3D
@export var EXIT_AREA: Area3D
var inside = false

func _on_body_entered(body: Node) -> void:
	if body != REAPER: return
	if inside == true: return
	inside = true
	if ANIM: ANIM.queue("ENTERED")
	
func _on_body_exited(body: Node) -> void:
	if body != REAPER: return
	if inside == false: return
	inside = false
	if ANIM: ANIM.queue("EXITED")
	
func _connect_exit_queue_free() -> void:
	if ANIM: ANIM.queue("EXITED")
	ANIM.connect("animation_finished", Callable(self, "_on_animation_finished"))
	
func _on_animation_finished(_anim_name: String) -> void:
	queue_free()	

func _ready() -> void:
	REAPER = get_tree().root.get_node("Main/Reaper")
	if ENTER_AREA: ENTER_AREA.connect("body_entered", Callable(self, "_on_body_entered"))
	if EXIT_AREA: EXIT_AREA.connect("body_exited", Callable(self, "_on_body_exited"))
