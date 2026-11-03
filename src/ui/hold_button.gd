class_name HoldButton
extends Button
## A button that can demand a press-and-hold (irreversible choices, GDD §2.3). With require_hold off it acts on a
## plain press. The Fill bar and HoldTimer are nodes in hold_button.tscn; their signals are connected there.

signal confirmed

## Needs the HoldTimer's full wait (1.5 s) before it confirms.
@export var require_hold := false

@onready var fill: ProgressBar = %Fill
@onready var hold_timer: Timer = %HoldTimer


func _process(_delta: float) -> void:
	fill.value = 1.0 - hold_timer.time_left / hold_timer.wait_time if not hold_timer.is_stopped() else 0.0


func _on_button_down() -> void:
	if require_hold and not disabled:
		hold_timer.start()


func _on_button_up() -> void:
	hold_timer.stop()


func _on_pressed() -> void:
	if not require_hold:
		confirmed.emit()


func _on_hold_timer_timeout() -> void:
	confirmed.emit()
