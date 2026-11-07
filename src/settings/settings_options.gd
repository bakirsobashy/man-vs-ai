class_name SettingsOptions
extends Resource
## The choices the settings screen offers (data/settings/settings_options.tres). SaveManager stores the player's
## picks as indices into these lists and applies them.

## The shared controls tuning (joystick, swipe and tap thresholds) the settings write into.
@export var tuning: ControlsTuning
## Swipe sensitivity: Low, Normal, High.
@export var swipe_presets: Array[SwipePreset] = []
@export var swipe_names: Array[String] = ["settings.swipe.low", "settings.swipe.normal", "settings.swipe.high"]
## Joystick size (stick radius): Small, Normal, Large.
@export var stick_radii: Array[float] = [36.0, 48.0, 64.0]
@export var stick_size_names: Array[String] = ["settings.stick_size.small", "settings.stick_size.normal", "settings.stick_size.large"]
@export var palettes: Array[BulletPalette] = []
## Text size: theme font size multipliers.
@export var text_scales: Array[float] = [1.0, 1.25]
@export var text_size_names: Array[String] = ["settings.text_size.normal", "settings.text_size.large"]
## Frame-rate caps (30 saves battery).
@export var fps_caps: Array[int] = [60, 30]
## Languages: locale codes ("" = the device's language) and their names in the picker.
@export var languages: Array[String] = ["", "en"]
@export var language_names: Array[String] = ["settings.language.device", "English"]
