class_name ComicPlayer
extends Control
## Shows comic panels one at a time (docs/narrative.md §6). Each panel is a child node of the comic's scene
## (art, caption and speech bubbles as separate nodes); tap to advance. Emits finished after the last panel.
## A comic with next_scene set (the prologue) goes there when it ends.

signal finished

## Story flag set when the comic has been seen.
@export var flag := ""
## Where to go afterwards; empty when the comic is an overlay (the first-implant panels).
@export_file("*.tscn") var next_scene := ""

@onready var panels: Control = %Panels

var _index := -1


func _ready() -> void:
	for child: Node in panels.get_children():
		(child as CanvasItem).visible = false
	_advance()


func _advance() -> void:
	var children := panels.get_children()
	if _index >= children.size():
		return
	if _index >= 0 and _index < children.size():
		(children[_index] as CanvasItem).visible = false
	_index += 1
	if _index < children.size():
		(children[_index] as CanvasItem).visible = true
		return
	if flag != "":
		GameState.set_flag(flag)
		SaveManager.save_slot()
	finished.emit()
	if next_scene != "":
		SceneRouter.go_to(next_scene)


func _on_gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	var touch := event as InputEventScreenTouch
	if (click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT) or (touch != null and touch.pressed):
		accept_event()
		_advance()
