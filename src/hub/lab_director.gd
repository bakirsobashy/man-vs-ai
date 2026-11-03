class_name LabDirector
extends Node
## Runs the lab hub (GDD §5.2): plays the story talks that are due, opens the station panels, and starts runs
## from the elevator (or Quick Start). In M4 every run starts at Level 1; Level 2 arrives in M5.

@export var player: Player
@export var lab_ui: LabUI
## Vorn and Patch, the first time Kade wakes up in the lab after the tutorial.
@export var intro_talk: Conversation
## After the first SCRAPJAW kill (story flag "l1_cleared").
@export var first_clear_talk: Conversation
## After a death, when Kade is back on the table.
@export var retrieval_lines: LineSet


func _ready() -> void:
	EventBus.station_used.connect(_on_station_used)
	_play_due_talks.call_deferred()


func start_run() -> void:
	RunState.start_new_run()
	GameState.add_stat("runs")
	SaveManager.save_slot()
	SceneRouter.go_to(SceneRouter.level_scene)


func _play_due_talks() -> void:
	if not GameState.has_flag("lab_intro_done"):
		GameState.set_flag("lab_intro_done")
		lab_ui.dialogue.play(intro_talk)
	if GameState.has_flag("l1_cleared") and not GameState.has_flag("l1_talk_done"):
		GameState.set_flag("l1_talk_done")
		lab_ui.dialogue.play(first_clear_talk)
	if GameState.has_flag("just_died"):
		GameState.flags.erase("just_died")
		lab_ui.dialogue.say(retrieval_lines.speaker, retrieval_lines.pick(GameState.stat("deaths") - 1))
	SaveManager.save_slot()


func _on_station_used(action: StringName) -> void:
	match action:
		&"surgery":
			lab_ui.open_surgery()
		&"armory":
			lab_ui.open_armory()
		&"elevator":
			if not SceneRouter.busy:
				start_run()
