class_name SettingsPanel
extends PanelContainer
## The settings screen (GDD §3.5 controls, §8.5 accessibility), one scene shared by the title, the pause menu and
## the lab. Every change is applied (SaveManager.apply_settings) and saved (settings.cfg) at once. The pickers list
## SettingsOptions' choices; the controls' signals are connected in the scene.

signal closed

@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var joystick_check: CheckButton = %JoystickCheck
@onready var stick_size_option: OptionButton = %StickSizeOption
@onready var stick_opacity_slider: HSlider = %StickOpacitySlider
@onready var swipe_option: OptionButton = %SwipeOption
@onready var double_tap_slider: HSlider = %DoubleTapSlider
@onready var reticle_check: CheckButton = %ReticleCheck
@onready var haptics_check: CheckButton = %HapticsCheck
@onready var shake_check: CheckButton = %ShakeCheck
@onready var flashing_check: CheckButton = %FlashingCheck
@onready var palette_option: OptionButton = %PaletteOption
@onready var text_size_option: OptionButton = %TextSizeOption
@onready var fps_option: OptionButton = %FpsOption
@onready var language_option: OptionButton = %LanguageOption
@onready var privacy_button: Button = %PrivacyButton


func _ready() -> void:
	var options := SaveManager.options
	_fill(stick_size_option, options.stick_size_names)
	_fill(swipe_option, options.swipe_names)
	var palette_names: Array[String] = []
	for palette: BulletPalette in options.palettes:
		palette_names.append(palette.display_name)
	_fill(palette_option, palette_names)
	_fill(text_size_option, options.text_size_names)
	var fps_names: Array[String] = []
	for cap: int in options.fps_caps:
		fps_names.append("%d fps" % cap)
	_fill(fps_option, fps_names)
	_fill(language_option, options.language_names)


## Shows the panel with the current settings.
func open() -> void:
	music_slider.set_value_no_signal(SaveManager.music_volume)
	sfx_slider.set_value_no_signal(SaveManager.sfx_volume)
	joystick_check.set_pressed_no_signal(SaveManager.show_joystick)
	stick_size_option.select(SaveManager.stick_size)
	stick_opacity_slider.set_value_no_signal(SaveManager.stick_opacity)
	swipe_option.select(SaveManager.swipe_sensitivity)
	double_tap_slider.set_value_no_signal(SaveManager.double_tap_window)
	reticle_check.set_pressed_no_signal(SaveManager.show_reticle)
	haptics_check.set_pressed_no_signal(SaveManager.haptics)
	shake_check.set_pressed_no_signal(SaveManager.screen_shake)
	flashing_check.set_pressed_no_signal(SaveManager.reduced_flashing)
	palette_option.select(SaveManager.bullet_palette)
	text_size_option.select(SaveManager.text_size)
	fps_option.select(SaveManager.fps_cap)
	language_option.select(maxi(SaveManager.options.languages.find(SaveManager.language), 0))
	privacy_button.visible = Monetization.needs_privacy_options()
	visible = true


func _fill(option: OptionButton, names: Array[String]) -> void:
	option.clear()
	for item_name: String in names:
		option.add_item(item_name)


func _commit() -> void:
	SaveManager.apply_settings()
	SaveManager.save_settings()


func _on_music_slider_value_changed(value: float) -> void:
	SaveManager.music_volume = value
	_commit()


func _on_sfx_slider_value_changed(value: float) -> void:
	SaveManager.sfx_volume = value
	_commit()


func _on_joystick_check_toggled(on: bool) -> void:
	SaveManager.show_joystick = on
	_commit()


func _on_stick_size_option_item_selected(index: int) -> void:
	SaveManager.stick_size = index
	_commit()


func _on_stick_opacity_slider_value_changed(value: float) -> void:
	SaveManager.stick_opacity = value
	_commit()


func _on_swipe_option_item_selected(index: int) -> void:
	SaveManager.swipe_sensitivity = index
	_commit()


func _on_double_tap_slider_value_changed(value: float) -> void:
	SaveManager.double_tap_window = value
	_commit()


func _on_reticle_check_toggled(on: bool) -> void:
	SaveManager.show_reticle = on
	_commit()


func _on_haptics_check_toggled(on: bool) -> void:
	SaveManager.haptics = on
	_commit()


func _on_shake_check_toggled(on: bool) -> void:
	SaveManager.screen_shake = on
	_commit()


func _on_flashing_check_toggled(on: bool) -> void:
	SaveManager.reduced_flashing = on
	_commit()


func _on_palette_option_item_selected(index: int) -> void:
	SaveManager.bullet_palette = index
	_commit()


func _on_text_size_option_item_selected(index: int) -> void:
	SaveManager.text_size = index
	_commit()


func _on_fps_option_item_selected(index: int) -> void:
	SaveManager.fps_cap = index
	_commit()


func _on_language_option_item_selected(index: int) -> void:
	SaveManager.language = SaveManager.options.languages[index]
	_commit()


func _on_privacy_button_pressed() -> void:
	Monetization.show_privacy_options()


func _on_close_button_pressed() -> void:
	AudioManager.click()
	visible = false
	closed.emit()
