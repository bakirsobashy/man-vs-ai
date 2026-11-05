class_name Credits
extends Control
## The credits after an ending (GDD §8.2: Ending → Credits → Lab). The RollAnimation scrolls %Roll up; its last key
## calls _on_roll_finished, which shows %PostCredits: Vorn's line for GameState.last_ending (from `endings`) and the
## threat level the ending unlocked. A tap skips the roll; the next tap goes to the lab.

@export var endings: Array[EndingData] = []
@export var music: AudioStream
@export_file("*.tscn") var lab_scene := "res://src/hub/lab.tscn"

@onready var roll_animation: AnimationPlayer = %RollAnimation
@onready var post_credits: Control = %PostCredits
@onready var vorn_line: Label = %VornLine
@onready var unlock_label: Label = %UnlockLabel
@onready var skip_hint: Control = %SkipHint

var finished := false


func _ready() -> void:
	post_credits.visible = false
	if music != null:
		AudioManager.play_music(music)
	roll_animation.play(&"roll")


func _on_roll_finished() -> void:
	if finished:
		return
	finished = true
	roll_animation.stop()
	vorn_line.text = ""
	for ending: EndingData in endings:
		if ending.id == GameState.last_ending:
			vorn_line.text = ending.post_credits
	unlock_label.text = "THREAT LEVEL %d UNLOCKED · choose it in the lab" % GameState.threat_unlocked if GameState.threat_unlocked > 0 else ""
	post_credits.visible = true
	skip_hint.visible = false


func _on_gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	var touch := event as InputEventScreenTouch
	if not ((click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT) or (touch != null and touch.pressed)):
		return
	accept_event()
	AudioManager.click()
	if not finished:
		_on_roll_finished()
	else:
		SceneRouter.go_to(lab_scene)
