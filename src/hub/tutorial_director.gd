class_name TutorialDirector
extends Node
## Runs the training room (GDD §8.3): one TutorialStep at a time, each finished by its goal (dummies destroyed,
## taking cover, a roll, an EMP). Then the tutorial is marked done and Kade goes to the lab.
## StepTimer (connected in the scene) leaves a short pause between steps.

@export var steps_root: Node2D
@export var step_label: Label
@export var instruction_label: Label
@export var step_timer: Timer

var current: TutorialStep
var progress := 0
var _index := -1
var _last_emp := -1
var _finished := false


func _ready() -> void:
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.player_state_changed.connect(_on_player_state_changed)
	EventBus.player_emp_changed.connect(_on_player_emp_changed)
	for child: Node in steps_root.get_children():
		(child as TutorialStep).set_active(false)
	next_step()


func step_count() -> int:
	return steps_root.get_child_count()


func next_step() -> void:
	if current != null:
		current.set_active(false)
	_index += 1
	progress = 0
	if _index >= step_count():
		finish()
		return
	current = steps_root.get_child(_index) as TutorialStep
	current.set_active(true)
	step_label.text = tr("tutorial.step") % [_index + 1, step_count()]
	instruction_label.text = tr(current.instruction)


## Marks the tutorial done and goes to the lab (also the Skip button).
func finish() -> void:
	if _finished:
		return
	_finished = true
	GameState.set_flag("tutorial_done")
	SaveManager.save_slot()
	SceneRouter.go_to(SceneRouter.lab_scene)


func _count(goal: TutorialStep.Goal) -> void:
	if current == null or current.goal != goal or not step_timer.is_stopped():
		return
	progress += 1
	if progress >= current.count:
		instruction_label.text = tr("tutorial.good")
		step_timer.start()


func _on_enemy_killed(_enemy: Node2D) -> void:
	_count(TutorialStep.Goal.KILLS)


func _on_player_state_changed(state_name: StringName) -> void:
	if state_name == &"InCover":
		_count(TutorialStep.Goal.COVER)
	elif state_name == &"Roll":
		_count(TutorialStep.Goal.ROLL)


func _on_player_emp_changed(charges: int) -> void:
	if _last_emp >= 0 and charges < _last_emp:
		_count(TutorialStep.Goal.EMP)
	_last_emp = charges


func _on_step_timer_timeout() -> void:
	next_step()


func _on_skip_pressed() -> void:
	finish()
