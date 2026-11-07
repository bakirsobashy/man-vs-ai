class_name DialogueBox
extends PanelContainer
## Speech at the bottom of the screen. Tap it to advance; it hides after the last line.
## Its labels are nodes in dialogue_box.tscn; gui_input is connected in the scene.

signal finished

@onready var speaker_label: Label = %Speaker
@onready var line_label: Label = %Line

var _queue: Array[DialogueLine] = []


func play(conversation: Conversation) -> void:
	if conversation == null:
		return
	_queue.append_array(conversation.lines)
	if not visible:
		_next()


## One line, queued after anything already showing. `speaker` and `text` are translation keys (or plain text).
func say(speaker: String, text: String) -> void:
	var line := DialogueLine.new()
	line.speaker = speaker
	line.text = text
	_queue.append(line)
	if not visible:
		_next()


func is_talking() -> bool:
	return visible


func _next() -> void:
	if _queue.is_empty():
		visible = false
		finished.emit()
		return
	var line: DialogueLine = _queue.pop_front()
	speaker_label.text = tr(line.speaker).to_upper()
	line_label.text = tr(line.text)
	visible = true


func _on_gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	var touch := event as InputEventScreenTouch
	if (click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT) or (touch != null and touch.pressed):
		accept_event()
		AudioManager.click()
		_next()
