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


## Sets the Music and SFX bus volumes (default_bus_layout.tres) from the settings.
func apply_settings() -> void:
	for bus: String in ["Music", "SFX"]:
		var index := AudioServer.get_bus_index(bus)
		if index >= 0:
			var volume := music_volume if bus == "Music" else sfx_volume
			AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.0001)))


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "sfx", sfx_volume)
	config.set_value("feedback", "haptics", haptics)
	config.set_value("accessibility", "reduced_flashing", reduced_flashing)
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
