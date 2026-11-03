extends Node
## Music and interface sounds (autoload scene "AudioManager", audio_manager.tscn; docs/technical.md §3.1).
## World sounds are AudioStreamPlayer2D nodes inside each scene. The Music and SFX bus volumes come from the
## settings (SaveManager.apply_settings). MusicFade's fade_out ends with a call to _on_music_faded_out.

@onready var music: AudioStreamPlayer = %Music
@onready var music_fade: AnimationPlayer = %MusicFade
@onready var ui_sound: AudioStreamPlayer = %UiSound

var _next: AudioStream


## Crossfades to `stream` (looping music files loop by themselves). Same track: keeps playing.
func play_music(stream: AudioStream) -> void:
	if stream == null or (stream == music.stream and music.playing and _next == null):
		return
	_next = stream
	if music.playing:
		music_fade.play(&"fade_out")
	else:
		_on_music_faded_out()


func current_music() -> AudioStream:
	return _next if _next != null else music.stream


## A short tick for taps on dialogue and comics.
func click() -> void:
	ui_sound.play()


func _on_music_faded_out() -> void:
	if _next == null:
		return
	music.stream = _next
	_next = null
	music.play()
	music_fade.play(&"fade_in")
