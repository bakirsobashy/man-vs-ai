class_name TutorialStep
extends Node2D
## One step of the rehab session (GDD §8.3). Its dummies are its children; until the step starts it is hidden and
## disabled, which also takes its bodies and areas out of the physics world.

enum Goal { KILLS, COVER, ROLL, EMP }

@export_multiline var instruction := ""
@export var goal := Goal.KILLS
## How many times the goal has to happen (kills: dummies destroyed).
@export_range(1, 20) var count := 1


func set_active(on: bool) -> void:
	visible = on
	process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
