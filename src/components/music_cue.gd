@icon("res://assets/art/placeholder/icon_state.svg")
class_name MusicCue
extends Node
## Starts this scene's music when the scene loads (AudioManager crossfades from the previous track).

@export var stream: AudioStream


func _ready() -> void:
	AudioManager.play_music(stream)
