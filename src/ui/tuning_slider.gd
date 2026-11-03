class_name TuningSlider
extends HBoxContainer
## One debug slider bound to a ControlsTuning property. Each instance in hud.tscn sets its own
## property, caption and range in the Inspector.

## Shared controls tuning.
@export var tuning: ControlsTuning
## The ControlsTuning property this slider edits.
@export var property: StringName
## Text shown left of the slider.
@export var caption := ""
@export var min_value := 0.0
@export var max_value := 1.0
@export var step := 0.01
## Unit shown after the value.
@export var unit := ""

@onready var caption_label: Label = %Caption
@onready var slider: HSlider = %Slider
@onready var value_label: Label = %Value

var _syncing := true


func _ready() -> void:
	caption_label.text = caption
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	refresh()
	_syncing = false


## Re-read the value from the tuning resource (called through the "tuning_sliders" group).
func refresh() -> void:
	slider.set_value_no_signal(float(tuning.get(property)))
	_show_value(slider.value)


func _show_value(value: float) -> void:
	value_label.text = "%s%s" % [String.num(value, 2), unit]


func _on_slider_value_changed(value: float) -> void:
	if _syncing:
		return
	tuning.set(property, value)
	_show_value(value)
