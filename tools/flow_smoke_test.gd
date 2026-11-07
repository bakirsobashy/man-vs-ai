extends Node
## The M4 save and flow smoke test (started by tools/smoke_test_flow.gd).
## Checks SaveManager and the run snapshot, then plays the real scene flow through SceneRouter:
## title → prologue → tutorial → lab → level, quitting and continuing a run, death, and the boss elevator.
## Save files go to user://test_saves/ so a player's real slots are never touched.

const TEST_DIR := "user://test_saves/"

var _failures := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	SaveManager.save_dir = TEST_DIR
	_clear_test_dir()
	_test_slot_files()
	_test_run_snapshot()
	_test_settings()
	await _test_new_story()
	await _test_tutorial()
	await _test_lab_to_level()
	await _test_quit_and_continue()
	await _test_death()
	await _test_boss_elevator()
	SaveManager.delete_slot(1)
	_clear_test_dir()
	print("Flow smoke test finished: %d failure(s)" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


# --- Save files ---

func _test_slot_files() -> void:
	GameState.reset_to_new()
	GameState.slot = 1
	GameState.add_crypto(123)
	GameState.add_ram(456)
	GameState.set_implant("heart", 2)
	GameState.unlock_weapon(&"longshot")
	GameState.set_flag("prologue_seen")
	GameState.stats["runs"] = 3
	SaveManager.save_slot()
	_check(FileAccess.file_exists(SaveManager.slot_path(1)) and not FileAccess.file_exists(SaveManager.slot_path(1) + ".tmp"),
		"saving writes slot_1.json (through a .tmp file)")
	GameState.reset_to_new()
	SaveManager.load_slot(1)
	_check(GameState.crypto == 123 and GameState.ram_mb == 456 and GameState.implant_tier("heart") == 2
		and GameState.is_unlocked(&"longshot") and GameState.has_flag("prologue_seen") and GameState.stat("runs") == 3,
		"loading the slot restores currencies, implants, unlocks, flags and stats")
	var summary := SaveManager.slot_summary(1)
	_check(int(summary.get("filled_slots", -1)) == 1 and int(summary.get("runs", -1)) == 3, "the slot card summary reads the file")
	_check(SaveManager.slot_summary(2).is_empty(), "an unused slot has no summary")

	var bad := FileAccess.open(SaveManager.slot_path(2), FileAccess.WRITE)
	bad.store_string("{ not json")
	bad.close()
	_check(not SaveManager.load_slot(2) and GameState.crypto == 0 and GameState.is_unlocked(&"scattergun"),
		"a corrupt slot file loads as a new story instead of crashing")
	var future := FileAccess.open(SaveManager.slot_path(3), FileAccess.WRITE)
	future.store_string(JSON.stringify({"version": 99, "crypto": 5, "implants": {"legs": 7}}))
	future.close()
	SaveManager.load_slot(3)
	_check(GameState.crypto == 5 and GameState.implant_tier("legs") == 3, "unknown versions still load, with values clamped")
	SaveManager.delete_slot(2)
	SaveManager.delete_slot(3)
	_check(not FileAccess.file_exists(SaveManager.slot_path(2)) and GameState.slot == 0, "deleting a slot removes its files")


func _test_run_snapshot() -> void:
	SaveManager.load_slot(1)
	RunState.start_new_run()
	RunState.level_seed = 4242
	RunState.room_id = 3
	RunState.entry_direction = Vector2i.LEFT
	RunState.cleared_rooms.assign([1, 3])
	RunState.hp = 4
	RunState.found_gun = "longshot"
	RunState.found_magazine = 2
	RunState.crypto_earned = 31
	SaveManager.save_run()
	_check(SaveManager.has_run(1), "a run in progress is saved to run_1.json")
	RunState.start_new_run()
	SaveManager.load_run()
	_check(RunState.resuming and RunState.level_seed == 4242 and RunState.room_id == 3 and RunState.entry_direction == Vector2i.LEFT
		and RunState.cleared_rooms == [1, 3] and RunState.hp == 4 and RunState.found_gun == "longshot" and RunState.crypto_earned == 31,
		"loading the run restores its seed, room, progress and hero state")
	SaveManager.clear_run()
	RunState.end_run()
	_check(not SaveManager.has_run(1), "ending a run deletes its snapshot")


func _test_settings() -> void:
	SaveManager.music_volume = 0.3
	SaveManager.haptics = false
	SaveManager.save_settings()
	SaveManager.music_volume = 1.0
	SaveManager.haptics = true
	SaveManager.load_settings()
	_check(is_equal_approx(SaveManager.music_volume, 0.3) and not SaveManager.haptics, "settings survive a restart (settings.cfg)")
	SaveManager.music_volume = 0.8
	SaveManager.haptics = true
	SaveManager.save_settings()


# --- Flow ---

func _test_new_story() -> void:
	SaveManager.delete_slot(1)
	get_tree().change_scene_to_file(SceneRouter.title_scene)
	await _wait(0.4)
	var title := get_tree().current_scene as TitleScreen
	_check(title != null, "the game starts on the title screen")
	title._on_slot_chosen(1)
	await _wait(0.7)
	_check(_scene_name() == "Prologue" and GameState.slot == 1, "a new story opens with the prologue comic")
	var comic := get_tree().current_scene as ComicPlayer
	for _i: int in 4:
		comic._advance()
	await _wait(0.7)
	_check(_scene_name() == "Tutorial" and GameState.has_flag("prologue_seen"), "after the last panel comes the rehab tutorial")


func _test_tutorial() -> void:
	var director := get_tree().current_scene.get_node(^"TutorialDirector") as TutorialDirector
	_check(director.current != null and director.current.name == &"Walk", "rehab starts with walking and auto-fire")
	EventBus.enemy_killed.emit(null)
	EventBus.enemy_killed.emit(null)
	await _wait(1.2)
	_check(director.current.name == &"Cover", "destroying both targets moves on to cover")
	EventBus.player_state_changed.emit(&"InCover")
	await _wait(1.2)
	EventBus.player_state_changed.emit(&"Roll")
	EventBus.player_state_changed.emit(&"Roll")
	await _wait(1.2)
	_check(director.current.name == &"Emp", "then rolling, then the EMP")
	EventBus.player_emp_changed.emit(8)
	await _wait(1.8)
	_check(_scene_name() == "Lab" and GameState.has_flag("tutorial_done"), "finishing rehab wakes Kade in the lab")


func _test_lab_to_level() -> void:
	await _wait(0.3)
	var ui := get_tree().current_scene.get_node(^"LabUI") as LabUI
	_check(ui.dialogue.is_talking() and GameState.has_flag("lab_intro_done"), "Vorn and Patch introduce the lab the first time")
	EventBus.station_used.emit(&"elevator")
	await _wait(0.9)
	_check(_scene_name() == "Level" and RunState.active and GameState.stat("runs") == 1, "the elevator starts a run in the Rustline")
	_check(SaveManager.has_run(1), "entering the first room saves the run")


func _test_quit_and_continue() -> void:
	var director := get_tree().current_scene.get_node(^"LevelDirector") as LevelDirector
	var player := get_tree().current_scene.get_node(^"Player") as Player
	player.health.take_hit(1)
	var direction := Vector2i.ZERO
	for dir: Vector2i in director.current.neighbors:
		if director.layout.rooms[director.current.neighbors[dir]].type == Room.RoomType.COMBAT:
			direction = dir
	player.global_position = (director.current_room().door(direction).get_node(^"Exit") as Node2D).global_position
	await _wait(0.8)
	var room_id := director.current.id
	var hp := player.health.hp
	var hud := get_tree().current_scene.get_node(^"HUD") as Hud
	hud._on_quit_pressed()
	await _wait(0.7)
	_check(_scene_name() == "Title" and SaveManager.has_run(1), "Save and quit returns to the title with the run kept")
	(get_tree().current_scene as TitleScreen)._on_slot_chosen(1)
	await _wait(1.0)
	director = get_tree().current_scene.get_node(^"LevelDirector") as LevelDirector
	player = get_tree().current_scene.get_node(^"Player") as Player
	_check(_scene_name() == "Level" and director.current != null and director.current.id == room_id,
		"Continue run rebuilds the level and returns to the saved room")
	_check(player.health.hp == hp and director.is_fighting(), "with the saved hearts, and the room's fight starts again")


func _test_death() -> void:
	var player := get_tree().current_scene.get_node(^"Player") as Player
	var deaths := GameState.stat("deaths")
	player.health.invuln_timer.stop()
	player.health.take_hit(99)
	await _wait(1.6)
	var hud := get_tree().current_scene.get_node(^"HUD") as Hud
	_check(hud.summary_panel.visible and hud.summary_title.text == "RETRIEVED", "dying shows the Retrieved summary")
	_check(GameState.stat("deaths") == deaths + 1 and not SaveManager.has_run(1) and not RunState.active,
		"the run ends: it can't be continued, and the death is counted")
	hud._on_summary_button_pressed()
	await _wait(1.0)
	var ui := get_tree().current_scene.get_node(^"LabUI") as LabUI
	_check(_scene_name() == "Lab" and ui.dialogue.is_talking() and ui.dialogue.speaker_label.text == "VORN",
		"back in the lab, Vorn comments on the retrieval")


func _test_boss_elevator() -> void:
	EventBus.station_used.emit(&"elevator")
	await _wait(0.9)
	var director := get_tree().current_scene.get_node(^"LevelDirector") as LevelDirector
	var player := get_tree().current_scene.get_node(^"Player") as Player
	player.health.invuln_timer.stop()
	player.health.take_hit(1)
	var hp := player.health.hp
	director._on_level_exit_requested()
	await _wait(0.9)
	_check(_scene_name() == "Lab" and RunState.active and RunState.in_lab and RunState.level_number == 2 and SaveManager.has_run(1),
		"after Level 1's boss the run continues: back in the lab, Level 2 next")
	var lab_director := get_tree().current_scene.get_node(^"LabDirector") as LabDirector
	_check(lab_director.elevator.prompt.contains("Neon Bazaar"), "the lab's elevator now goes to the Neon Bazaar (%s)" % lab_director.elevator.prompt)
	EventBus.station_used.emit(&"elevator")
	await _wait(1.0)
	director = get_tree().current_scene.get_node(^"LevelDirector") as LevelDirector
	player = get_tree().current_scene.get_node(^"Player") as Player
	_check(_scene_name() == "Level" and director.config.level_number == 2 and director.config.district_name == "Neon Bazaar",
		"the elevator starts Level 2")
	_check(player.health.hp == hp, "the hero keeps the hearts from Level 1 (%d)" % player.health.hp)
	player.health.invuln_timer.stop()
	player.health.take_hit(99)
	await _wait(1.6)
	(get_tree().current_scene.get_node(^"HUD") as Hud)._on_summary_button_pressed()
	await _wait(1.0)
	_check(_scene_name() == "Lab" and not RunState.active and (get_tree().current_scene.get_node(^"LabDirector") as LabDirector).elevator.prompt.contains("Level 1"),
		"dying in Level 2 ends the run: the next one starts at Level 1")


# --- Helpers ---

func _scene_name() -> String:
	return String(get_tree().current_scene.name) if get_tree().current_scene != null else ""


func _clear_test_dir() -> void:
	var dir := DirAccess.open(TEST_DIR)
	if dir == null:
		return
	for file: String in dir.get_files():
		dir.remove(file)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS  ", label)
	else:
		_failures += 1
		print("FAIL  ", label)
