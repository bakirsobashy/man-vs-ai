@icon("res://assets/art/placeholder/icon_room.svg")
class_name LevelDirector
extends Node
## Runs a level (docs/technical.md §7): generates the layout, copies room scenes into RoomHolder as the hero
## walks through doors (behind a fade), locks combat rooms until their waves are cleared, rolls chests,
## hands out rewards, and ends the run from the boss room's elevator or on death.
## Visited rooms are kept (out of the tree) so their pickups, cover damage and opened chests persist.
## The run is saved (RunState + SaveManager) on every room entry and clear, and rebuilt from its seed on Continue.

@export var config: LevelConfig
## 0 = a new random seed for every level.
@export var fixed_seed := 0
@export var room_holder: Node2D
@export var player: Player
@export var camera: CameraFollow
@export var wave_spawner: WaveSpawner
## Dropped at a combat room's RewardSpot when it's cleared.
@export var room_reward: Drops
## Dropped (with a Rare chest) when a challenge arena is beaten.
@export var arena_reward: Drops
@export var chest_scene: PackedScene
## Plays "fade_out" (its last key calls _on_fade_out_finished) and "fade_in" (its last key calls
## _on_fade_in_finished).
@export var transition: AnimationPlayer
## The boss elevator and death go back to the lab. Off in tests: the elevator starts another level in place.
@export var return_to_lab := true
## Started when the hero dies; its timeout (connected in the scene) shows the "Retrieved" summary.
@export var death_timer: Timer

var layout: LevelLayout
var current: RoomNode
var levels_started := 0
var _rooms: Dictionary[int, Room] = {}
var _fight_room := -1
var _pending_room := -1
var _pending_travel := Vector2i.ZERO
var _pending_level := false
## True from a door or the elevator until the fade-in ends. Door signals are ignored meanwhile: every room
## shares the same origin, so a door Exit in the new room can overlap where the hero stood a moment ago.
var _transitioning := false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	EventBus.door_entered.connect(_on_door_entered)
	EventBus.challenge_requested.connect(_on_challenge_requested)
	EventBus.ambush_requested.connect(_on_ambush_requested)
	EventBus.reward_chest_requested.connect(_on_reward_chest_requested)
	EventBus.level_exit_requested.connect(_on_level_exit_requested)
	EventBus.player_died.connect(_on_player_died)
	EventBus.summary_closed.connect(_on_summary_closed)
	wave_spawner.settings = config.wave_settings
	if not RunState.active:
		RunState.start_new_run()  # started straight from the editor or a test
	if RunState.resuming:
		resume_run.call_deferred()
	else:
		start_level.call_deferred(fixed_seed if fixed_seed != 0 else RunState.level_seed)


## A fresh level (new rooms). 0 = a random seed.
func start_level(level_seed: int = 0) -> void:
	_build_level(level_seed if level_seed != 0 else _rng.randi())
	RunState.start_level(config.level_number, layout.level_seed)
	player.begin_level()
	enter_room(layout.start_id, Vector2i.ZERO)
	EventBus.banner_requested.emit("%s · %d" % [config.district_name.to_upper(), levels_started])


## Continue a saved run: rebuild its level from the seed, mark what was done, and put the hero at the entrance of
## the room they were in (an uncleared room starts its fight again).
func resume_run() -> void:
	RunState.resuming = false
	_build_level(RunState.level_seed)
	for id: int in RunState.known_rooms:
		layout.rooms[id].known = true
	for id: int in RunState.visited_rooms:
		layout.rooms[id].visited = true
	for id: int in RunState.cleared_rooms:
		layout.rooms[id].cleared = true
	player.restore_run_state()
	if RunState.room_id >= 0 and RunState.room_id < layout.rooms.size():
		enter_room(RunState.room_id, RunState.entry_direction)
	else:
		enter_room(layout.start_id, Vector2i.ZERO)
	EventBus.banner_requested.emit("RUN CONTINUED")


func _build_level(level_seed: int) -> void:
	for room: Room in _rooms.values():
		if room.is_inside_tree():
			room_holder.remove_child(room)
		room.queue_free()
	_rooms.clear()
	current = null
	_fight_room = -1
	levels_started += 1
	RunState.level_number = config.level_number
	layout = LevelGenerator.generate(config, level_seed)
	EventBus.level_generated.emit(layout)


## Show room `id`. `travel` is the grid direction the hero moved (zero for the level start).
func enter_room(id: int, travel: Vector2i) -> void:
	if current != null and _rooms.has(current.id) and _rooms[current.id].is_inside_tree():
		room_holder.remove_child(_rooms[current.id])
	current = layout.rooms[id]
	var room := _room_for(current)
	room_holder.add_child(room)
	current.visited = true
	current.known = true
	for neighbor: int in current.neighbors.values():
		layout.rooms[neighbor].known = true
	var entry: Marker2D = room.player_start
	var door := room.door(-travel) if travel != Vector2i.ZERO else null
	if door != null:
		entry = door.entry
	player.global_position = entry.global_position
	player.velocity = Vector2.ZERO
	player.respawn_point = entry
	if not player.state_machine.is_in(&"Dead"):
		player.state_machine.transition_to(&"Stand")
	camera.bounds = room.camera_bounds
	camera.snap()
	var fight := not current.cleared and (current.type == Room.RoomType.COMBAT or current.type == Room.RoomType.BOSS)
	_set_doors(room, Door.Status.LOCKED if fight else Door.Status.OPEN)
	EventBus.room_entered.emit(current.id)
	RunState.room_id = current.id
	RunState.entry_direction = travel
	_autosave()
	if fight:
		_begin_fight(room)


func current_room() -> Room:
	return _rooms.get(current.id) if current != null else null


## True while the current room's doors are locked for a fight (waves, challenge, ambush or boss).
func is_fighting() -> bool:
	return _fight_room != -1


func _room_for(node: RoomNode) -> Room:
	if not _rooms.has(node.id):
		var room := node.scene.instantiate() as Room
		var chest := room.feature("Chest") as Chest
		if chest != null:
			chest.rarity = config.roll_rarity(_rng.randf())
			chest.opened = RunState.opened_chests.has(node.id)
		_rooms[node.id] = room
	return _rooms[node.id]


func _set_doors(room: Room, status_with_neighbor: Door.Status) -> void:
	for door: Door in room.all_doors():
		door.set_status(status_with_neighbor if current.neighbors.has(door.direction_vector()) else Door.Status.SEALED)


func _begin_fight(room: Room) -> void:
	_fight_room = current.id
	if current.type == Room.RoomType.BOSS:
		var spot := room.feature("BossSpot") as Node2D
		wave_spawner.spawn_boss(config.boss_scene, spot.global_position, room.enemies)
		EventBus.banner_requested.emit("BOSS")
		return
	var waves := room.waves if room.waves > 0 else _rng.randi_range(config.waves_min, config.waves_max)
	wave_spawner.start_room(room.spawn_points, room.enemies, waves, config.room_threat)


## A Rare-or-better chest copy in the current room's DropLayer (arena and terminal prizes).
func _drop_reward_chest(at: Vector2) -> void:
	var layer := current_room().get_node(^"%DropLayer") as Node2D
	var chest := chest_scene.instantiate() as Chest
	chest.rarity = config.roll_rarity(_rng.randf(), WeaponCatalogEntry.Rarity.RARE)
	chest.position = layer.to_local(at)
	layer.add_child.call_deferred(chest)


func _on_wave_spawner_room_cleared() -> void:
	if _fight_room == -1:
		return
	var node := layout.rooms[_fight_room]
	var room := _rooms[node.id]
	_fight_room = -1
	node.cleared = true
	_set_doors(room, Door.Status.OPEN)
	match node.type:
		Room.RoomType.COMBAT:
			room_reward.drop(room.reward_spot.global_position)
		Room.RoomType.ARENA:
			_drop_reward_chest(room.reward_spot.global_position)
			arena_reward.drop(room.reward_spot.global_position + Vector2(0, 24))
			EventBus.banner_requested.emit("CHALLENGE BEATEN")
		Room.RoomType.BOSS:
			(room.feature("Elevator") as Elevator).reveal()
			EventBus.banner_requested.emit("LEVEL CLEAR")
			GameState.add_stat("boss_kills")
			GameState.stats["best_level"] = maxi(GameState.stat("best_level"), config.level_number)
			GameState.set_flag("l%d_cleared" % config.level_number)
	RunState.rooms_cleared += 1
	GameState.add_stat("rooms_cleared")
	EventBus.room_cleared.emit(node.id)
	_autosave()


## Saves the run (rooms, hero, found gun) and the slot. Does nothing without a loaded save slot.
func _autosave() -> void:
	if not RunState.active or layout == null:
		return
	RunState.known_rooms.clear()
	RunState.visited_rooms.clear()
	RunState.cleared_rooms.clear()
	for node: RoomNode in layout.rooms:
		if node.known:
			RunState.known_rooms.append(node.id)
		if node.visited:
			RunState.visited_rooms.append(node.id)
		if node.cleared:
			RunState.cleared_rooms.append(node.id)
	RunState.opened_chests.clear()
	for id: int in _rooms:
		var chest := _rooms[id].feature("Chest") as Chest
		if chest != null and chest.opened:
			RunState.opened_chests.append(id)
	player.capture_run_state()
	SaveManager.save_all()


## The run is over (death or the boss elevator): it's no longer resumable, and the slot keeps the currencies.
func _end_run() -> void:
	GameState.stats["best_level"] = maxi(GameState.stat("best_level"), config.level_number)
	RunState.end_run()
	SaveManager.clear_run()
	SaveManager.save_slot()


func _on_door_entered(travel: Vector2i) -> void:
	if _transitioning or _fight_room != -1 or current == null:
		return
	var next: int = current.neighbors.get(travel, -1)
	if next == -1:
		return
	_pending_room = next
	_pending_travel = travel
	_transitioning = true
	transition.play(&"fade_out")


func _on_fade_out_finished() -> void:
	if _pending_level:
		_pending_level = false
		start_level(fixed_seed)
	elif _pending_room != -1:
		enter_room(_pending_room, _pending_travel)
		_pending_room = -1
	transition.play(&"fade_in")


func _on_fade_in_finished() -> void:
	_transitioning = false


func _on_challenge_requested() -> void:
	var room := current_room()
	if room == null or current.type != Room.RoomType.ARENA or current.cleared:
		return
	_fight_room = current.id
	_set_doors(room, Door.Status.LOCKED)
	wave_spawner.start_room(room.spawn_points, room.enemies, config.arena_waves, config.arena_threat)


func _on_ambush_requested() -> void:
	var room := current_room()
	if room == null or room.spawn_points == null:
		return
	_fight_room = current.id
	_set_doors(room, Door.Status.LOCKED)
	wave_spawner.start_room(room.spawn_points, room.enemies, 1, config.ambush_threat)


func _on_reward_chest_requested(at: Vector2) -> void:
	if current_room() != null:
		_drop_reward_chest(at)


func _on_level_exit_requested() -> void:
	if _transitioning:
		return
	_transitioning = true
	if return_to_lab:
		_end_run()
		SceneRouter.go_to(SceneRouter.lab_scene)
		return
	_pending_level = true
	transition.play(&"fade_out")


func _on_player_died() -> void:
	if not player.auto_respawn and death_timer != null:
		death_timer.start()


## After the death beat: the run ends and the HUD shows Vorn's retrieval panel with the run summary.
func _on_death_timer_timeout() -> void:
	GameState.add_stat("deaths")
	GameState.set_flag("just_died")
	var summary := "Crypto +%d · RAM +%d MB\nRobots destroyed: %d · Rooms cleared: %d" % [
		RunState.crypto_earned, RunState.ram_earned, RunState.kills, RunState.rooms_cleared]
	_end_run()
	EventBus.run_summary_requested.emit("RETRIEVED", summary)


func _on_summary_closed() -> void:
	if return_to_lab:
		SceneRouter.go_to(SceneRouter.lab_scene)
