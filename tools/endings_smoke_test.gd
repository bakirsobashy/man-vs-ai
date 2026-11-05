extends Node
## The endings and NG+ smoke test (started by tools/smoke_test_endings.gd).
## Checks which ending each humanity band gets, the last boss handing over to the ending, the real scene flow
## ending comic → credits → lab, threat levels (unlock, scaling, rewards, the lab selector) and their saves.
## Save files go to user://test_saves_endings/ so a player's real slots are never touched.

const TEST_DIR := "user://test_saves_endings/"
const LEVEL_PATH := "res://src/levels/level.tscn"
const LAB_PATH := "res://src/hub/lab.tscn"
const CAMPAIGN := "res://data/levels/campaign.tres"
const GRUNT := "res://src/enemies/grunt/grunt.tscn"
const SLOT_CARD := "res://src/ui/title/slot_card.tscn"

var _failures := 0
var _banners: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	SaveManager.save_dir = TEST_DIR
	_clear_test_dir()
	EventBus.banner_requested.connect(func(text: String) -> void: _banners.append(text))
	_test_bands()
	await _test_last_boss()
	await _test_ending_flow()
	await _test_threat_levels()
	await _test_lab_selector()
	_test_saves()
	await _test_slot_card()
	SaveManager.delete_slot(1)
	_clear_test_dir()
	GameState.reset_to_new()
	print("Endings smoke test finished: %d failure(s)" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _test_bands() -> void:
	var campaign := load(CAMPAIGN) as Campaign
	var picked: Array[String] = []
	for filled: int in [0, 2, 4, 6]:
		_fill_slots(filled)
		var ending := campaign.ending_for(GameState.humanity_band())
		picked.append(ending.id if ending != null else "")
	_check(picked == ["humanity", "normal_patched", "normal_hollow", "transformation"],
		"0, 1–2, 3–5 and 6 filled slots get Humanity, Normal (Patched), Normal (Hollow) and Transformation (%s)" % ", ".join(picked))
	var comics := campaign.endings.all(func(e: EndingData) -> bool: return ResourceLoader.exists(e.comic_scene) and e.post_credits != "")
	_check(campaign.endings.size() == 4 and comics, "each ending has a comic and a post-credits line from Vorn")
	GameState.reset_to_new()


func _test_last_boss() -> void:
	GameState.reset_to_new()
	_fill_slots(4)
	RunState.start_new_run()
	RunState.level_number = 5
	var level := (load(LEVEL_PATH) as PackedScene).instantiate()
	var director := level.get_node(^"LevelDirector") as LevelDirector
	director.return_to_lab = false
	director.fixed_seed = 52
	get_tree().root.add_child(level)
	var player := level.get_node(^"Player") as Player
	player.health.max_hp = 99
	player.health.reset()
	await _wait(0.5)
	director.enter_room(director.layout.boss_id, Vector2i.ZERO)
	var spawner := level.get_node(^"WaveSpawner") as WaveSpawner
	await _wait(1.4)
	var boss := spawner.alive[0] as Enemy if spawner.alive.size() == 1 else null
	var had_boss := boss != null and boss.scene_file_path.ends_with("zero.tscn")
	if boss != null:
		boss.take_damage(9999)
	await _wait(0.5)
	var elevator := director.current_room().feature("Elevator") as Elevator
	_check(had_boss and director.ending_reached == "" and not elevator.revealed, "when ZERO falls there's no elevator: the ending comes")
	await _wait(2.0)
	_check(director.ending_reached == "normal_hollow" and GameState.last_ending == "normal_hollow" and GameState.endings_seen.has("normal_hollow"),
		"2 s later, the Hollow band's ending is reached and recorded")
	_check(GameState.threat_unlocked == 1 and not RunState.active, "the run ends and threat level 1 unlocks")
	level.queue_free()
	await _wait(0.3)


func _test_ending_flow() -> void:
	GameState.reset_to_new()
	GameState.record_ending("humanity", 1)
	SceneRouter.go_to("res://src/ui/comic/ending_humanity.tscn")
	await _wait(0.8)
	var comic := get_tree().current_scene as ComicPlayer
	_check(comic != null and comic.name == "EndingHumanity" and comic.panels.get_child_count() == 4, "the ending comic plays (4 panels)")
	if comic == null:
		return
	for _i: int in 4:
		comic._advance()
	_check(GameState.has_flag("ending_humanity_seen"), "the comic is marked as seen")
	await _wait(0.8)
	var credits := get_tree().current_scene as Credits
	_check(credits != null and credits.roll_animation.is_playing() and not credits.post_credits.visible, "then the credits roll")
	if credits == null:
		return
	credits._on_gui_input(_tap())
	_check(credits.finished and credits.post_credits.visible and credits.vorn_line.text.begins_with("Subject declined every upgrade"),
		"a tap skips to Vorn's post-credits line for the ending")
	_check(credits.unlock_label.text.contains("THREAT LEVEL 1"), "and says which threat level unlocked")
	credits._on_gui_input(_tap())
	await _wait(0.8)
	var lab := get_tree().current_scene
	_check(lab != null and lab.scene_file_path == LAB_PATH, "the next tap returns to the lab")
	var ui := lab.get_node_or_null(^"LabUI") as LabUI if lab != null else null
	_check(ui != null and ui.threat_box.visible, "where the threat selector is now shown")
	get_tree().unload_current_scene()
	await _wait(0.3)


func _test_threat_levels() -> void:
	GameState.reset_to_new()
	GameState.threat_unlocked = 3
	GameState.threat_level = 2
	RunState.start_new_run()
	_check(RunState.threat_level == 2, "a new run starts at the chosen threat level")
	var level := (load(LEVEL_PATH) as PackedScene).instantiate()
	var director := level.get_node(^"LevelDirector") as LevelDirector
	director.return_to_lab = false
	director.fixed_seed = 7
	_banners.clear()
	get_tree().root.add_child(level)
	await _wait(0.5)
	_check(is_equal_approx(director.threat_scale(), 1.3) and is_equal_approx(director.elite_chance(), 0.1)
		and is_equal_approx(RunState.reward_scale, 1.2), "threat 2: rooms +30% threat, +10% elite chance (even on Level 1), +20% RAM")
	_check(_banners.any(func(b: String) -> bool: return b.contains("THREAT 2")), "the level banner shows the threat level")
	var room := director.current_room()
	var grunt := (load(GRUNT) as PackedScene).instantiate() as Enemy
	grunt.position = room.enemies.to_local(room.player_start.global_position + Vector2(0, -80))
	room.enemies.add_child(grunt)
	await _wait(1.0)
	grunt.take_damage(9999)
	await _physics_frames(3)
	var ram := room.get_node(^"%DropLayer").get_children().filter(func(n: Node) -> bool:
		return n is Pickup and (n as Node).scene_file_path.ends_with("ram_chip.tscn"))
	_check(ram.size() == 1 and (ram[0] as Pickup).amount == 4, "a Grunt drops 4 MB instead of 3")
	level.queue_free()
	await _wait(0.3)
	GameState.threat_level = 0
	RunState.start_new_run()
	_check(RunState.threat_level == 0, "threat 0 plays like before")


func _test_lab_selector() -> void:
	GameState.reset_to_new()
	GameState.flags.assign(["lab_intro_done"])
	var lab := (load(LAB_PATH) as PackedScene).instantiate()
	get_tree().root.add_child(lab)
	await _wait(0.3)
	var ui := lab.get_node(^"LabUI") as LabUI
	_check(not ui.threat_box.visible, "before any ending, the lab has no threat selector")
	lab.queue_free()
	await _wait(0.2)
	GameState.threat_unlocked = 2
	lab = (load(LAB_PATH) as PackedScene).instantiate()
	get_tree().root.add_child(lab)
	await _wait(0.3)
	ui = lab.get_node(^"LabUI") as LabUI
	for _i: int in 3:
		ui._on_threat_up_pressed()
	_check(ui.threat_box.visible and GameState.threat_level == 2 and ui.threat_label.text == "THREAT 2", "the selector steps up to the highest unlocked level")
	for _i: int in 5:
		ui._on_threat_down_pressed()
	_check(GameState.threat_level == 0 and ui.threat_label.text.begins_with("THREAT 0"), "and back down to 0")
	lab.queue_free()
	await _wait(0.2)


func _test_saves() -> void:
	GameState.reset_to_new()
	GameState.record_ending("transformation", 3)
	GameState.threat_level = 2
	var data := GameState.to_dict()
	GameState.reset_to_new()
	GameState.from_dict(data)
	_check(GameState.last_ending == "transformation" and GameState.threat_unlocked == 3 and GameState.threat_level == 2
		and GameState.stat("endings") == 1, "endings and threat levels are saved on the slot")
	data["threat_level"] = 9
	GameState.from_dict(data)
	_check(GameState.threat_level == 3, "a saved threat level never exceeds what's unlocked")
	RunState.start_new_run()
	RunState.threat_level = 2
	var run := RunState.to_dict()
	RunState.start_new_run()
	RunState.from_dict(run)
	_check(RunState.threat_level == 2, "a saved run keeps its threat level")
	GameState.record_ending("transformation", 1)
	_check(GameState.threat_unlocked == 3 and GameState.endings_seen.size() == 1, "seeing an ending again never lowers the unlocked level")


func _test_slot_card() -> void:
	GameState.reset_to_new()
	GameState.slot = 1
	GameState.record_ending("humanity", 1)
	GameState.record_ending("normal_patched", 2)
	SaveManager.save_slot()
	GameState.slot = 0
	var card := (load(SLOT_CARD) as PackedScene).instantiate()
	card.set(&"slot", 1)
	get_tree().root.add_child(card)
	await _wait(0.1)
	card.call(&"refresh")
	var info := card.get_node(^"%InfoLabel") as Label
	_check(info.text.contains("endings 2/4"), "the save slot card counts the endings seen")
	card.queue_free()
	await _wait(0.1)


# --- Helpers ---

func _fill_slots(count: int) -> void:
	for i: int in GameState.IMPLANT_SLOTS.size():
		GameState.implants[GameState.IMPLANT_SLOTS[i]] = 1 if i < count else 0


func _tap() -> InputEventMouseButton:
	var tap := InputEventMouseButton.new()
	tap.button_index = MOUSE_BUTTON_LEFT
	tap.pressed = true
	return tap


func _clear_test_dir() -> void:
	var dir := DirAccess.open(TEST_DIR)
	if dir == null:
		return
	for file: String in dir.get_files():
		dir.remove(file)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _physics_frames(count: int) -> void:
	for _i: int in count:
		await get_tree().physics_frame


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS  ", label)
	else:
		_failures += 1
		print("FAIL  ", label)
