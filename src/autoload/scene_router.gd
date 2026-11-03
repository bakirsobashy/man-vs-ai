extends CanvasLayer
## Moves between the title, prologue, tutorial, lab and level behind a fade (autoload scene "SceneRouter",
## scene_router.tscn). The last key of fade_out calls _on_fade_out_finished; fade_in's calls _on_fade_in_finished.

@export_file("*.tscn") var title_scene := "res://src/ui/title/title.tscn"
@export_file("*.tscn") var prologue_scene := "res://src/ui/comic/prologue.tscn"
@export_file("*.tscn") var tutorial_scene := "res://src/hub/tutorial.tscn"
@export_file("*.tscn") var lab_scene := "res://src/hub/lab.tscn"
@export_file("*.tscn") var level_scene := "res://src/levels/level.tscn"

@onready var animation: AnimationPlayer = %FadeAnimation

## True from go_to() until the new scene has faded in.
var busy := false
var _next := ""


func go_to(scene_path: String) -> void:
	if busy:
		return
	busy = true
	_next = scene_path
	animation.play(&"fade_out")


## Where a freshly loaded save goes: its saved run, the prologue, the tutorial, or the lab.
func enter_slot() -> void:
	if SaveManager.has_run() and SaveManager.load_run():
		go_to(lab_scene if RunState.in_lab else level_scene)
	elif not GameState.has_flag("prologue_seen"):
		go_to(prologue_scene)
	elif not GameState.has_flag("tutorial_done"):
		go_to(tutorial_scene)
	else:
		go_to(lab_scene)


func _on_fade_out_finished() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(_next)
	animation.play(&"fade_in")


func _on_fade_in_finished() -> void:
	busy = false
