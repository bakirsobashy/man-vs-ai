@icon("res://assets/art/placeholder/icon_state.svg")
class_name TextScaler
extends Node
## Text size setting (GDD §8.5): scales a UI scene's theme font size. Put one in each UI scene with that scene's
## Theme and the size it was designed at; labels with their own font-size override keep it.

@export var theme: Theme
@export_range(6, 48) var base_size := 13


func _ready() -> void:
	EventBus.settings_changed.connect(apply)
	apply()


func apply() -> void:
	if theme != null:
		theme.default_font_size = roundi(base_size * SaveManager.text_scale())
