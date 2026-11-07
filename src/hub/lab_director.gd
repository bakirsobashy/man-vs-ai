class_name LabDirector
extends Node
## Runs the lab hub (GDD §5.2): plays the story talks that are due, opens the station panels, and sends Kade down
## the elevator (or Quick Start): to the next level of the run in progress, or to Level 1 for a new run.

@export var player: Player
@export var lab_ui: LabUI
## The elevator station; its prompt names the next level.
@export var elevator: Station
@export var campaign: Campaign
## Vorn and Patch, the first time Kade wakes up in the lab after the tutorial.
@export var intro_talk: Conversation
## After each level's first boss kill (index 0 = Level 1; story flags "l<N>_cleared").
@export var first_clear_talks: Array[Conversation] = []
## Vorn's idle lines when nothing else is due, one set per humanity band (Human, Patched, Hollow, Machine).
@export var idle_lines: Array[LineSet] = []
## After a death, when Kade is back on the table.
@export var retrieval_lines: LineSet


func _ready() -> void:
	EventBus.station_used.connect(_on_station_used)
	if RunState.active and RunState.in_lab:
		player.restore_run_state.call_deferred()
	_name_elevator()
	_play_due_talks.call_deferred()


## True between levels of a run (the elevator continues it instead of starting at Level 1).
func run_in_progress() -> bool:
	return RunState.active and RunState.in_lab


## The elevator: the next level of the run in progress, or a new run at Level 1.
func start_run() -> void:
	if run_in_progress():
		RunState.in_lab = false
		SaveManager.save_all()
	else:
		RunState.start_new_run()
		GameState.add_stat("runs")
		SaveManager.save_slot()
	SceneRouter.go_to(SceneRouter.level_scene)


func _name_elevator() -> void:
	if elevator == null or campaign == null:
		return
	var number := RunState.level_number if run_in_progress() else 1
	var next := campaign.config_for(number)
	elevator.prompt = tr("station.elevator_to") % [tr(next.district_name), number]


func _play_due_talks() -> void:
	_play_story_talks()
	if not lab_ui.dialogue.is_talking() and GameState.stat("runs") > 0:
		var band := GameState.humanity_band()
		if band < idle_lines.size() and idle_lines[band] != null:
			lab_ui.dialogue.say(idle_lines[band].speaker, idle_lines[band].pick(randi()))
	SaveManager.save_slot()


func _play_story_talks() -> void:
	if not GameState.has_flag("lab_intro_done"):
		GameState.set_flag("lab_intro_done")
		lab_ui.dialogue.play(intro_talk)
	for i: int in first_clear_talks.size():
		var level := i + 1
		if GameState.has_flag("l%d_cleared" % level) and not GameState.has_flag("l%d_talk_done" % level):
			GameState.set_flag("l%d_talk_done" % level)
			lab_ui.dialogue.play(first_clear_talks[i])
	if GameState.has_flag("just_died"):
		GameState.flags.erase("just_died")
		lab_ui.dialogue.say(retrieval_lines.speaker, retrieval_lines.pick(GameState.stat("deaths") - 1))


func _on_station_used(action: StringName) -> void:
	match action:
		&"surgery":
			lab_ui.open_surgery()
		&"armory":
			lab_ui.open_armory()
		&"elevator":
			if not SceneRouter.busy:
				start_run()
