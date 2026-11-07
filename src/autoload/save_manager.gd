extends Node
## Save files (autoload "SaveManager", docs/technical.md §8). Plain JSON, never .tres, so a tampered file can't run code.
## - user://slot_N.json: the save slot (GameState).
## - user://run_N.json: the run in progress (RunState), deleted when the run ends.
## - user://settings.cfg: volumes and haptics (ConfigFile).
## Every write goes to a .tmp file first and is then renamed over the old file. Nothing is written while no slot is
## loaded (GameState.slot == 0), so the test levels never touch the disk.

const VERSION := 1
const SLOT_COUNT := 3

## Folder for every file; tests point it somewhere else.
var save_dir := "user://"
var music_volume := 0.8
var sfx_volume := 1.0
var haptics := true
## Tones down screen flashes and glitches (GDD §8.5).
var reduced_flashing := false
## M6 settings and accessibility (GDD §3.5, §8.5). Index fields pick from SettingsOptions' lists.
var show_joystick := true
var stick_size := 1
var stick_opacity := 0.8
var swipe_sensitivity := 1
var double_tap_window := 0.3
var show_reticle := true
var screen_shake := true
var bullet_palette := 0
var text_size := 0
var fps_cap := 0
## A locale code ("en"); empty = the device language.
var language := ""
var options: SettingsOptions = preload("res://data/settings/settings_options.tres")


func _ready() -> void:
	load_settings()
	apply_settings()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_all()


func slot_path(slot: int) -> String:
	return save_dir.path_join("slot_%d.json" % slot)


func run_path(slot: int) -> String:
	return save_dir.path_join("run_%d.json" % slot)


# --- Slots ---

## Loads slot `slot` into GameState (a new life story if the file doesn't exist). Returns false on a bad file.
func load_slot(slot: int) -> bool:
	var data := _read_json(slot_path(slot))
	GameState.slot = slot
	if data.is_empty():
		GameState.reset_to_new()
		return not FileAccess.file_exists(slot_path(slot))
	GameState.from_dict(_migrate(data))
	return true


func save_slot() -> void:
	if GameState.slot <= 0:
		return
	var data := GameState.to_dict()
	data["version"] = VERSION
	_write_json(slot_path(GameState.slot), data)


## What the slot select card shows; empty for an unused slot.
func slot_summary(slot: int) -> Dictionary:
	var data := _read_json(slot_path(slot))
	if data.is_empty():
		return {}
	data = _migrate(data)
	var implants: Variant = data.get("implants", {})
	var filled := 0
	if implants is Dictionary:
		for tier: Variant in (implants as Dictionary).values():
			filled += 1 if int(tier) > 0 else 0
	var stats: Variant = data.get("stats", {})
	return {
		"playtime_s": int(data.get("playtime_s", 0)),
		"best_level": int((stats as Dictionary).get("best_level", 0)) if stats is Dictionary else 0,
		"runs": int((stats as Dictionary).get("runs", 0)) if stats is Dictionary else 0,
		"filled_slots": filled,
		"endings": (data.get("endings_seen", []) as Array).size() if data.get("endings_seen", []) is Array else 0,
		"has_run": FileAccess.file_exists(run_path(slot)),
	}


func delete_slot(slot: int) -> void:
	for path: String in [slot_path(slot), run_path(slot)]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if GameState.slot == slot:
		GameState.slot = 0
		GameState.reset_to_new()


# --- Runs ---

func has_run(slot: int = GameState.slot) -> bool:
	return slot > 0 and FileAccess.file_exists(run_path(slot))


func save_run() -> void:
	if GameState.slot <= 0 or not RunState.active:
		return
	var data := RunState.to_dict()
	data["version"] = VERSION
	_write_json(run_path(GameState.slot), data)


## Loads the saved run into RunState (resuming = true). False if there's none.
func load_run() -> bool:
	var data := _read_json(run_path(GameState.slot))
	if data.is_empty():
		return false
	RunState.from_dict(_migrate(data))
	RunState.active = true
	return true


func clear_run() -> void:
	if GameState.slot > 0 and FileAccess.file_exists(run_path(GameState.slot)):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(run_path(GameState.slot)))


## The slot and, during a run, the run snapshot.
func save_all() -> void:
	save_slot()
	save_run()


# --- Settings ---

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(save_dir.path_join("settings.cfg")) != OK:
		return
	music_volume = clampf(float(config.get_value("audio", "music", music_volume)), 0.0, 1.0)
	sfx_volume = clampf(float(config.get_value("audio", "sfx", sfx_volume)), 0.0, 1.0)
	haptics = bool(config.get_value("feedback", "haptics", haptics))
	reduced_flashing = bool(config.get_value("accessibility", "reduced_flashing", reduced_flashing))
	show_joystick = bool(config.get_value("controls", "show_joystick", show_joystick))
	stick_size = clampi(int(config.get_value("controls", "stick_size", stick_size)), 0, options.stick_radii.size() - 1)
	stick_opacity = clampf(float(config.get_value("controls", "stick_opacity", stick_opacity)), 0.2, 1.0)
	swipe_sensitivity = clampi(int(config.get_value("controls", "swipe_sensitivity", swipe_sensitivity)), 0, options.swipe_presets.size() - 1)
	double_tap_window = clampf(float(config.get_value("controls", "double_tap_window", double_tap_window)), 0.2, 0.5)
	show_reticle = bool(config.get_value("controls", "show_reticle", show_reticle))
	screen_shake = bool(config.get_value("feedback", "screen_shake", screen_shake))
	bullet_palette = clampi(int(config.get_value("accessibility", "bullet_palette", bullet_palette)), 0, options.palettes.size() - 1)
	text_size = clampi(int(config.get_value("accessibility", "text_size", text_size)), 0, options.text_scales.size() - 1)
	fps_cap = clampi(int(config.get_value("display", "fps_cap", fps_cap)), 0, options.fps_caps.size() - 1)
	language = str(config.get_value("display", "language", language))


## Applies every setting: bus volumes (default_bus_layout.tres), the shared controls tuning (joystick, swipe preset,
## double-tap window), the frame-rate cap and the language. Everything else reads its setting when it needs it,
## and EventBus.settings_changed tells the palettes and text scalers to re-apply.
func apply_settings() -> void:
	for bus: String in ["Music", "SFX"]:
		var index := AudioServer.get_bus_index(bus)
		if index >= 0:
			var volume := music_volume if bus == "Music" else sfx_volume
			AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.0001)))
	var tuning := options.tuning
	tuning.show_joystick = show_joystick
	tuning.stick_radius = options.stick_radii[stick_size]
	tuning.double_tap_window = double_tap_window
	if swipe_sensitivity < options.swipe_presets.size():
		options.swipe_presets[swipe_sensitivity].apply_to(tuning)
	Engine.max_fps = options.fps_caps[fps_cap]
	TranslationServer.set_locale(language if language != "" else OS.get_locale_language())
	EventBus.settings_changed.emit()


func palette() -> BulletPalette:
	return options.palettes[bullet_palette] if bullet_palette < options.palettes.size() else null


func text_scale() -> float:
	return options.text_scales[text_size] if text_size < options.text_scales.size() else 1.0


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "sfx", sfx_volume)
	config.set_value("feedback", "haptics", haptics)
	config.set_value("accessibility", "reduced_flashing", reduced_flashing)
	config.set_value("controls", "show_joystick", show_joystick)
	config.set_value("controls", "stick_size", stick_size)
	config.set_value("controls", "stick_opacity", stick_opacity)
	config.set_value("controls", "swipe_sensitivity", swipe_sensitivity)
	config.set_value("controls", "double_tap_window", double_tap_window)
	config.set_value("controls", "show_reticle", show_reticle)
	config.set_value("feedback", "screen_shake", screen_shake)
	config.set_value("accessibility", "bullet_palette", bullet_palette)
	config.set_value("accessibility", "text_size", text_size)
	config.set_value("display", "fps_cap", fps_cap)
	config.set_value("display", "language", language)
	config.save(save_dir.path_join("settings.cfg"))


# --- Files ---

## Upgrades older save data to VERSION (no older versions exist yet).
func _migrate(data: Dictionary) -> Dictionary:
	var version := int(data.get("version", 1))
	if version > VERSION:
		push_warning("SaveManager: save version %d is newer than %d" % [version, VERSION])
	return data


func _write_json(path: String, data: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(save_dir))
	var tmp := path + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: can't write %s (%s)" % [tmp, error_string(FileAccess.get_open_error())])
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	var error := DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(path))
	if error != OK:
		push_error("SaveManager: can't replace %s (%s)" % [path, error_string(error)])


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		return parsed as Dictionary
	push_warning("SaveManager: %s isn't a valid save" % path)
	return {}
