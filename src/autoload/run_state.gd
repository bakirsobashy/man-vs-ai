extends Node
## The current run (autoload "RunState", docs/technical.md §8): everything that resets on death.
## The level and its seed, which rooms are done, the hero's hearts, armor, EMP charges and found gun,
## and the run summary. SaveManager writes it to user://run_N.json so a run can be continued.

## True between starting a run (the lab elevator) and its end (death or the boss elevator).
var active := false
## Set when the level scene should rebuild a saved run instead of starting a fresh level.
var resuming := false
## Between levels: the boss fell and Kade is in the lab; the lab's elevator continues to level_number.
var in_lab := false
## The level being played (prices and rewards scale with it).
var level_number := 1
## NG+ threat level of this run (copied from GameState when the run starts).
var threat_level := 0
## RAM multiplier from the threat level (set by the LevelDirector, not saved).
var reward_scale := 1.0
## The Second Chance ad was used this run (it's once per run).
var second_chance_used := false
var level_seed := 0
## The room the hero is in, and the door they came through (zero = the start room's PlayerStart).
var room_id := -1
var entry_direction := Vector2i.ZERO
var known_rooms: Array[int] = []
var visited_rooms: Array[int] = []
var cleared_rooms: Array[int] = []
var opened_chests: Array[int] = []
## Hero state as last saved (-1 = full / default).
var hp := -1
var armor := 0
var emp_charges := -1
## The found gun in slot 2 (a weapon catalog id; empty = none) and its ammo.
var found_gun := ""
var found_magazine := 0
var found_reserve := 0
## Run summary.
var crypto_earned := 0
var ram_earned := 0
var kills := 0
var rooms_cleared := 0
## Rooms cleared since the last Fusion Heart Mk III heal.
var rooms_since_heal := 0


func _ready() -> void:
	EventBus.enemy_killed.connect(_on_enemy_killed)


## A fresh run from level 1 (new maps, full health, no found gun).
func start_new_run(first_seed: int = 0) -> void:
	active = true
	resuming = false
	in_lab = false
	level_number = 1
	threat_level = GameState.threat_level
	level_seed = first_seed
	_clear_level()
	hp = -1
	armor = 0
	emp_charges = -1
	found_gun = ""
	found_magazine = 0
	found_reserve = 0
	crypto_earned = 0
	ram_earned = 0
	kills = 0
	rooms_cleared = 0
	rooms_since_heal = 0
	second_chance_used = false


## The next level of the same run (the hero keeps hearts, armor and the found gun).
func start_level(number: int, new_seed: int) -> void:
	level_number = number
	level_seed = new_seed
	_clear_level()


## The boss fell: on to the next level (the hero keeps hearts, armor and the found gun), via the lab.
func advance_level() -> void:
	level_number += 1
	level_seed = 0
	in_lab = true
	_clear_level()


func end_run() -> void:
	active = false
	resuming = false
	in_lab = false


func to_dict() -> Dictionary:
	return {
		"level_number": level_number,
		"level_seed": level_seed,
		"threat_level": threat_level,
		"in_lab": in_lab,
		"room_id": room_id,
		"entry_direction": [entry_direction.x, entry_direction.y],
		"known_rooms": known_rooms.duplicate(),
		"visited_rooms": visited_rooms.duplicate(),
		"cleared_rooms": cleared_rooms.duplicate(),
		"opened_chests": opened_chests.duplicate(),
		"hp": hp,
		"armor": armor,
		"emp_charges": emp_charges,
		"found_gun": found_gun,
		"found_magazine": found_magazine,
		"found_reserve": found_reserve,
		"crypto_earned": crypto_earned,
		"ram_earned": ram_earned,
		"kills": kills,
		"rooms_cleared": rooms_cleared,
		"rooms_since_heal": rooms_since_heal,
		"second_chance_used": second_chance_used,
	}


## Reads a snapshot written by to_dict() and marks the run as resuming.
func from_dict(data: Dictionary) -> void:
	start_new_run()
	level_number = clampi(int(data.get("level_number", 1)), 1, 5)
	level_seed = int(data.get("level_seed", 0))
	threat_level = maxi(int(data.get("threat_level", 0)), 0)
	in_lab = bool(data.get("in_lab", false))
	room_id = int(data.get("room_id", -1))
	var direction: Variant = data.get("entry_direction", [0, 0])
	if direction is Array and (direction as Array).size() == 2:
		entry_direction = Vector2i(int((direction as Array)[0]), int((direction as Array)[1]))
	known_rooms = _ints(data.get("known_rooms", []))
	visited_rooms = _ints(data.get("visited_rooms", []))
	cleared_rooms = _ints(data.get("cleared_rooms", []))
	opened_chests = _ints(data.get("opened_chests", []))
	hp = int(data.get("hp", -1))
	armor = int(data.get("armor", 0))
	emp_charges = int(data.get("emp_charges", -1))
	found_gun = str(data.get("found_gun", ""))
	found_magazine = int(data.get("found_magazine", 0))
	found_reserve = int(data.get("found_reserve", 0))
	crypto_earned = int(data.get("crypto_earned", 0))
	ram_earned = int(data.get("ram_earned", 0))
	kills = int(data.get("kills", 0))
	rooms_cleared = int(data.get("rooms_cleared", 0))
	rooms_since_heal = int(data.get("rooms_since_heal", 0))
	second_chance_used = bool(data.get("second_chance_used", false))
	resuming = true


func _clear_level() -> void:
	room_id = -1
	entry_direction = Vector2i.ZERO
	known_rooms.clear()
	visited_rooms.clear()
	cleared_rooms.clear()
	opened_chests.clear()


func _ints(value: Variant) -> Array[int]:
	var result: Array[int] = []
	if value is Array:
		for item: Variant in value:
			result.append(int(item))
	return result


func _on_enemy_killed(_enemy: Node2D) -> void:
	if active:
		kills += 1
