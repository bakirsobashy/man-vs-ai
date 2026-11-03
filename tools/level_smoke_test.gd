extends Node
## The M3 level smoke test (started by tools/smoke_test_level.gd).
## Loads level.tscn and plays generated levels through the LevelDirector: doors and transitions, locked fights,
## room rewards, persistence, every special room, the boss and the elevator to the next level.
## The hero is moved by placing it (into a door's Exit area, next to a feature); enemies are killed directly.

const LEVEL_PATH := "res://src/levels/level.tscn"
const CONFIG_PATH := "res://data/levels/level_1.tres"

var _failures := 0
var _level: Node
var _director: LevelDirector
var _player: Player
var _spawner: WaveSpawner
var _hud: Hud
var _minimap: MapView
var _config: LevelConfig
var _prompt := ""
var _waves_started := 0
var _rooms_entered := 0
var _walks := 0
var _bad_walks := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_config = load(CONFIG_PATH) as LevelConfig
	_level = (load(LEVEL_PATH) as PackedScene).instantiate()
	_director = _level.get_node(^"LevelDirector") as LevelDirector
	_director.fixed_seed = _find_seed(Room.RoomType.REPAIR)
	_director.return_to_lab = false  # the elevator starts another level in place (tested in the flow test too)
	get_tree().root.add_child(_level)
	_player = _level.get_node(^"Player") as Player
	_spawner = _level.get_node(^"WaveSpawner") as WaveSpawner
	_hud = _level.get_node(^"HUD") as Hud
	_minimap = _hud.get_node(^"Root/MinimapButton/Minimap") as MapView
	EventBus.interact_prompt_changed.connect(_on_prompt_changed)
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.room_entered.connect(_on_room_entered)
	await _wait(0.5)

	_test_start_room()
	await _test_combat_room()
	await _test_revisit_and_persistence()
	await _test_chest_room()
	await _test_memory_room()
	await _test_repair_room()

	_director.start_level(_find_seed(Room.RoomType.TERMINAL))
	await _wait(0.3)
	await _test_terminal_ambush()

	_director.start_level(_find_seed(Room.RoomType.ARENA))
	await _wait(0.3)
	await _test_challenge_arena()
	await _test_boss_and_elevator()
	_check(_walks > 10 and _bad_walks == 0, "every door leads exactly one room on (%d walks, %d wrong)" % [_walks, _bad_walks])

	print("Level smoke test finished: %d failure(s)" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _test_start_room() -> void:
	var room := _director.current_room()
	_check(_director.current.type == Room.RoomType.START, "the level begins in the start room")
	_check(_player.global_position.distance_to(room.player_start.global_position) < 1.0, "the hero stands on PlayerStart")
	var doors_ok := true
	for door: Door in room.all_doors():
		var has_neighbor := _director.current.neighbors.has(door.direction_vector())
		doors_ok = doors_ok and door.status == (Door.Status.OPEN if has_neighbor else Door.Status.SEALED)
	_check(doors_ok, "doors with a room behind them are open, the rest sealed (%d open)" % _director.current.neighbors.size())
	_check(_level.get_node(^"Camera").get(&"bounds") == room.camera_bounds, "the camera uses the room's CameraBounds")
	_check(_minimap.known_cells() == _known_rooms(), "the minimap shows the start room and its neighbors (%d cells)" % _minimap.known_cells())


func _test_combat_room() -> void:
	var direction := _direction_to_type(Room.RoomType.COMBAT)
	var from_id := _director.current.id
	await _walk_through(direction)
	var room := _director.current_room()
	_check(_director.current.type == Room.RoomType.COMBAT and _director.current.id != from_id, "walking into an open door enters the next room")
	_check(_player.global_position.distance_to(room.door(-direction).entry.global_position) < 2.0,
		"the hero arrives at the matching door's Entry")
	_check(_doors_are(room, Door.Status.LOCKED), "a combat room locks its doors")
	_check(_spawner.alive.size() > 0, "the first wave spawns at the room's SpawnPoints (%d)" % _spawner.alive.size())
	var nearest := INF
	for node: Node in _spawner.alive:
		nearest = minf(nearest, (node as Node2D).global_position.distance_to(_player.global_position))
	_check(nearest >= _config.wave_settings.min_spawn_distance - 13.0, "no enemy spawns on top of the hero (%.0f px)" % nearest)
	var polygon := room.nav_region.navigation_polygon
	_check(polygon.get_polygon_count() > 1 and polygon.get_vertices().size() > 4,
		"the room's navigation mesh is baked around its cover (%d polygons)" % polygon.get_polygon_count())
	var walker: Enemy = null
	for node: Node in _spawner.alive:
		if (node as Enemy).nav_agent != null:
			walker = node as Enemy
	await _wait(1.0)
	if walker != null and is_instance_valid(walker):
		walker.direction_toward(_player.global_position)
		await _physics_frames(4)
	_check(walker != null and is_instance_valid(walker) and walker.nav_agent.get_current_navigation_path().size() > 0,
		"walking robots get a navigation path to the hero")
	await _clear_fight()
	_check(not _director.is_fighting() and _director.current.cleared, "killing every wave clears the room")
	_check(_doors_are(room, Door.Status.OPEN), "a cleared room opens its doors")
	await _physics_frames(3)
	_check(_pickups_in(room, Pickup.Kind.CRYPTO) > 0, "clearing the room drops the Crypto reward at RewardSpot")


func _test_revisit_and_persistence() -> void:
	var combat_room := _director.current_room()
	var combat_id := _director.current.id
	var back := Vector2i.ZERO
	for direction: Vector2i in _director.current.neighbors:
		if _director.layout.rooms[_director.current.neighbors[direction]].type == Room.RoomType.START:
			back = direction
	await _walk_through(back)
	_check(_director.current.type == Room.RoomType.START, "the hero can walk back to the start room (%s, hp %d, at %s)"
		% [_player.state_machine.current.name, _player.health.hp, _player.global_position])
	await _walk_through(-back)
	_check(_director.current.id == combat_id and _director.current_room() == combat_room, "the cleared room is the same copy as before")
	_check(not _director.is_fighting() and _doors_are(combat_room, Door.Status.OPEN), "a cleared room stays open on return")


func _test_chest_room() -> void:
	var room := await _go_to_type(Room.RoomType.CHEST)
	var chest := room.feature("Chest") as Chest
	_check(chest != null and not chest.opened, "the chest room has a closed chest")
	var crypto_before := _pickups_in(room, Pickup.Kind.CRYPTO)
	_player.global_position = chest.global_position + Vector2(0, 4)
	await _physics_frames(4)
	_check(chest.opened, "touching the chest opens it")
	var pickup: WeaponPickup = null
	for node: Node in room.get_node(^"%DropLayer").get_children():
		if node is WeaponPickup:
			pickup = node as WeaponPickup
	_check(pickup != null and pickup.weapon() != null, "the chest drops a gun from the weapon catalog (%s)"
		% (pickup.weapon().display_name if pickup != null and pickup.weapon() != null else "none"))
	_check(_pickups_in(room, Pickup.Kind.CRYPTO) > crypto_before, "and its Crypto bonus")
	await _go_to_type(Room.RoomType.START)
	room = await _go_to_type(Room.RoomType.CHEST)
	_check((room.feature("Chest") as Chest).opened, "an opened chest stays open when the hero comes back")


func _test_memory_room() -> void:
	var room := await _go_to_type(Room.RoomType.MEMORY)
	var shrine := room.feature("Shrine") as MemoryShrine
	_player.health.hp = _player.health.max_hp - 2
	await _stand_next_to(shrine)
	_check(_prompt == "Remember", "the memory shrine shows its prompt")
	var hp := _player.health.hp
	_player.interact()
	_check(_hud.memory_panel.visible and get_tree().paused, "opening the memory shows its panel and pauses the game")
	_check(_hud.memory_title.text == "The Wedding", "the panel shows the level's memory (%s)" % _hud.memory_title.text)
	_check(_player.health.hp == hp + 1, "the first look heals 1/2 heart")
	_hud._on_memory_close_pressed()
	_check(not _hud.memory_panel.visible and not get_tree().paused, "closing the panel resumes the game")


func _test_repair_room() -> void:
	var room := await _go_to_type(Room.RoomType.REPAIR)
	var station := room.feature("Station") as RepairStation
	GameState.add_crypto(100)
	_player.health.hp = _player.health.max_hp - 1
	await _stand_next_to(station)
	_check(_prompt.begins_with("Repair station"), "the repair station shows its prompt")
	_player.interact()
	_check(_hud.shop_panel.visible and get_tree().paused, "the station opens the shop panel")
	var crypto := GameState.crypto
	var price := station.price(RepairStation.Item.HALF_HEART)
	_hud._on_buy_heart_pressed()
	_check(_player.health.hp == _player.health.max_hp and GameState.crypto == crypto - price,
		"buying 1/2 heart heals and costs %d Crypto" % price)
	_hud._on_buy_heart_pressed()
	_check(GameState.crypto == crypto - price and station.purchases_left == station.purchases - 1, "a heal at full health isn't sold")
	_hud._on_shop_close_pressed()
	_check(not get_tree().paused, "leaving the shop resumes the game")


func _test_terminal_ambush() -> void:
	var room := await _go_to_type(Room.RoomType.TERMINAL)
	var terminal := room.feature("Terminal") as HackedTerminal
	terminal.forced_outcome = HackedTerminal.Outcome.AMBUSH
	GameState.add_ram(terminal.cost())
	var ram := GameState.ram_mb
	await _stand_next_to(terminal)
	_check(_prompt.begins_with("Hack terminal"), "the hacked terminal shows its prompt")
	_player.interact()
	_check(GameState.ram_mb == ram - terminal.cost(), "hacking costs %d MB of RAM" % terminal.cost())
	_check(_director.is_fighting() and _doors_are(room, Door.Status.LOCKED) and _spawner.alive.size() > 0,
		"an ambush locks the doors and spawns robots (%d)" % _spawner.alive.size())
	await _clear_fight()
	_check(not _director.is_fighting() and _doors_are(room, Door.Status.OPEN), "beating the ambush opens the doors")
	await _stand_next_to(terminal)
	_check(_prompt == "", "a used terminal has no prompt")
	terminal.used = false
	terminal.forced_outcome = HackedTerminal.Outcome.RARE_CHEST
	GameState.add_ram(terminal.cost())
	await _stand_next_to(terminal)
	_player.interact()
	await _physics_frames(3)
	var prize: Chest = null
	for node: Node in room.get_node(^"%DropLayer").get_children():
		if node is Chest:
			prize = node as Chest
	_check(prize != null and prize.rarity >= WeaponCatalogEntry.Rarity.RARE, "the terminal's chest prize is Rare or better")


func _test_challenge_arena() -> void:
	var room := await _go_to_type(Room.RoomType.ARENA)
	var console := room.feature("Console") as ChallengeConsole
	_check(not _director.is_fighting() and _doors_are(room, Door.Status.OPEN), "the arena stays open until the challenge starts")
	await _stand_next_to(console)
	_check(_prompt == "Start the challenge", "the console shows its prompt")
	_waves_started = 0
	_player.interact()
	_check(_director.is_fighting() and _doors_are(room, Door.Status.LOCKED), "starting the challenge locks the doors")
	await _clear_fight()
	_check(_waves_started == _config.arena_waves, "the challenge runs %d waves (%d)" % [_config.arena_waves, _waves_started])
	await _physics_frames(3)
	var chest: Chest = null
	for node: Node in room.get_node(^"%DropLayer").get_children():
		if node is Chest:
			chest = node as Chest
	_check(chest != null and chest.rarity >= WeaponCatalogEntry.Rarity.RARE, "beating it drops a Rare-or-better chest")
	_check(_pickups_in(room, Pickup.Kind.RAM) > 0 and _pickups_in(room, Pickup.Kind.CRYPTO) > 0, "plus the RAM and Crypto reward")


func _test_boss_and_elevator() -> void:
	var room := await _go_to_type(Room.RoomType.BOSS)
	_check(_doors_are(room, Door.Status.LOCKED), "the boss room locks its doors")
	var boss := _spawner.alive[0] as Enemy if _spawner.alive.size() == 1 else null
	_check(boss != null and boss.is_boss, "the stand-in boss spawns at BossSpot")
	await _wait(1.0)
	boss.take_damage(10)
	_check(_hud.boss_bar.visible and _hud.boss_bar.value == boss.health.hp, "the HUD shows the boss bar (%d/%d)" % [boss.health.hp, int(_hud.boss_bar.max_value)])
	var elevator := room.feature("Elevator") as Elevator
	_check(not elevator.visible, "the elevator is hidden during the fight")
	await _clear_fight()
	_check(not _hud.boss_bar.visible, "the boss bar hides when the boss falls")
	_check(elevator.visible and elevator.revealed, "beating the boss reveals the elevator")
	var started := _director.levels_started
	var old_layout := _director.layout
	_director.fixed_seed = 0
	await _stand_next_to(elevator)
	_check(_prompt == "Take the elevator", "the elevator shows its prompt")
	_player.interact()
	await _wait(0.6)
	_check(_director.levels_started == started + 1 and _director.layout != old_layout, "the elevator starts a new level")
	_check(_director.current.type == Room.RoomType.START and _minimap.known_cells() == _known_rooms(),
		"the new level begins in its start room with a fresh minimap")


# --- Helpers ---

func _find_seed(type: Room.RoomType) -> int:
	for level_seed: int in range(1, 2000):
		if LevelGenerator.generate(_config, level_seed).count_of(type) > 0:
			return level_seed
	return 1


## Walks along the doors to the first room of `type`, clearing any fight on the way (but not in the target).
func _go_to_type(type: Room.RoomType) -> Room:
	var target := -1
	for room: RoomNode in _director.layout.rooms:
		if room.type == type and target == -1:
			target = room.id
	for direction: Vector2i in _path(_director.current.id, target):
		await _walk_through(direction)
		if _director.is_fighting() and _director.current.id != target:
			await _clear_fight()
	return _director.current_room()


func _path(from_id: int, to_id: int) -> Array[Vector2i]:
	var came_from: Dictionary[int, int] = {from_id: -1}
	var queue: Array[int] = [from_id]
	while not queue.is_empty():
		var id: int = queue.pop_front()
		for neighbor: int in _director.layout.rooms[id].neighbors.values():
			if not came_from.has(neighbor):
				came_from[neighbor] = id
				queue.append(neighbor)
	var steps: Array[Vector2i] = []
	var at := to_id
	while came_from.get(at, -1) != -1:
		var previous: int = came_from[at]
		steps.push_front(_director.layout.rooms[at].cell - _director.layout.rooms[previous].cell)
		at = previous
	return steps


func _direction_to_type(type: Room.RoomType) -> Vector2i:
	for direction: Vector2i in _director.current.neighbors:
		if _director.layout.rooms[_director.current.neighbors[direction]].type == type:
			return direction
	return Vector2i.ZERO


func _walk_through(direction: Vector2i) -> void:
	var door := _director.current_room().door(direction)
	_player.global_position = (door.get_node(^"Exit") as Node2D).global_position
	var before := _rooms_entered
	await _wait(0.6)
	_walks += 1
	_bad_walks += 0 if _rooms_entered == before + 1 else 1


func _clear_fight() -> void:
	for _round: int in 16:
		if not _director.is_fighting():
			return
		await _wait(1.0)
		for node: Node in _spawner.alive.duplicate():
			if is_instance_valid(node):
				(node as Enemy).take_damage(9999)
		await _physics_frames(3)


func _stand_next_to(feature: Node2D) -> void:
	_player.global_position = feature.global_position + Vector2(0, 20)
	await _physics_frames(4)


func _known_rooms() -> int:
	var count := 0
	for room: RoomNode in _director.layout.rooms:
		count += 1 if room.known else 0
	return count


## Every door that leads to a room has `status`.
func _doors_are(room: Room, status: Door.Status) -> bool:
	for door: Door in room.all_doors():
		if _director.current.neighbors.has(door.direction_vector()) and door.status != status:
			return false
	return true


func _pickups_in(room: Room, kind: Pickup.Kind) -> int:
	var count := 0
	for node: Node in room.get_node(^"%DropLayer").get_children():
		var pickup := node as Pickup
		if pickup != null and pickup.kind == kind and not pickup.is_queued_for_deletion():
			count += 1
	return count


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


func _on_prompt_changed(text: String) -> void:
	_prompt = text


func _on_wave_started(_wave: int, _threat: float) -> void:
	_waves_started += 1


func _on_room_entered(_room_id: int) -> void:
	_rooms_entered += 1
