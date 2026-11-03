@icon("res://assets/art/placeholder/icon_spawn.svg")
class_name WaveSpawner
extends Node
## Spends each wave's threat budget at the room's hand-placed SpawnPoints (docs/technical.md §6.4).
## Enemies are copies of authored scenes. Two modes:
## - Endless (the M2 arena): every cleared wave drops the reward, and the NextWaveTimer starts the next one.
## - Room (levels): the LevelDirector calls start_room() or spawn_boss(); after the room's last wave,
##   room_cleared is emitted (connected to the director in the level scene).

signal room_cleared

@export var settings: WaveSettings
## The room's SpawnPoints node.
@export var spawn_points: Node2D
## Where enemy copies are added.
@export var enemy_parent: Node2D
## Started after each cleared wave.
@export var next_wave_timer: Timer
## Dropped at reward_spot when a wave is cleared.
@export var reward_drops: Drops
@export var reward_spot: Marker2D
## What a Splitter elite leaves behind when it dies (two copies).
@export var splitter_scene: PackedScene
@export_range(0, 6) var splitter_count := 2

var wave := 0
var alive: Array[Node] = []
var _rng := RandomNumberGenerator.new()
var _room_mode := false
var _waves_left := 0
var _room_budget := 0.0
## Chance that a single (not grouped) enemy is an elite; elites cost twice the threat.
var _elite_chance := 0.0
var _pending_splits := 0


func _ready() -> void:
	_rng.randomize()
	EventBus.enemy_killed.connect(_on_enemy_killed)


## Fight in a level room: `wave_count` waves of `budget` threat at the room's SpawnPoints.
func start_room(points: Node2D, parent: Node2D, wave_count: int, budget: float, elite_chance: float = 0.0) -> void:
	spawn_points = points
	enemy_parent = parent
	_elite_chance = elite_chance
	_room_mode = true
	_waves_left = wave_count
	_room_budget = budget
	wave = 0
	alive.clear()
	start_next_wave()


## A hacked terminal's trap: one elite ground enemy at a free SpawnPoint; room_cleared follows its death.
func spawn_elite_ambush(points: Node2D, parent: Node2D) -> Node2D:
	spawn_points = points
	enemy_parent = parent
	_room_mode = true
	_waves_left = 0
	wave = 1
	alive.clear()
	var hero := get_tree().get_first_node_in_group(&"player") as Node2D
	var options: Array[SpawnPoint] = []
	for child: Node in points.get_children():
		var point := child as SpawnPoint
		if point != null and point.accepts(Enemy.SpawnKind.GROUND, 1) \
				and (hero == null or point.global_position.distance_to(hero.global_position) >= settings.min_spawn_distance):
			options.append(point)
	var singles := settings.enemy_pool.filter(func(e: EnemySpawnEntry) -> bool:
		return e.kind == Enemy.SpawnKind.GROUND and e.group_max == 1)
	if options.is_empty() or singles.is_empty():
		_wave_done()
		return null
	var entry: EnemySpawnEntry = singles[_rng.randi_range(0, singles.size() - 1)]
	var enemy := _spawn(entry.scene, options[_rng.randi_range(0, options.size() - 1)].global_position)
	(enemy as Enemy).make_elite(_rng.randi_range(1, Enemy.Elite.size() - 1) as Enemy.Elite)
	EventBus.wave_started.emit(wave, entry.threat_cost * 2.0)
	return enemy


## A boss fight: one enemy copy at `at`; room_cleared follows its death.
func spawn_boss(scene: PackedScene, at: Vector2, parent: Node2D) -> Node2D:
	enemy_parent = parent
	_room_mode = true
	_waves_left = 0
	alive.clear()
	_spawn(scene, at)
	return alive.back() as Node2D


func start_next_wave() -> void:
	if not _room_mode and not settings.endless and wave >= settings.waves:
		return
	wave += 1
	var budget := minf(settings.threat_first_wave + (wave - 1) * settings.threat_per_wave, settings.max_threat)
	if _room_mode:
		_waves_left -= 1
		budget = _room_budget
	var spent := _spawn_wave(budget)
	EventBus.wave_started.emit(wave, spent)
	if alive.is_empty():
		if _room_mode:
			_wave_done()
		else:
			next_wave_timer.start()


func _spawn_wave(budget: float) -> float:
	var hero := get_tree().get_first_node_in_group(&"player") as Node2D
	var points: Array[SpawnPoint] = []
	for child: Node in spawn_points.get_children():
		var point := child as SpawnPoint
		if point != null and (hero == null or point.global_position.distance_to(hero.global_position) >= settings.min_spawn_distance):
			points.append(point)
	var left := budget
	for _attempt: int in 64:
		var entry := _pick_entry(left, points)
		if entry == null:
			break
		var candidates := points.filter(func(p: SpawnPoint) -> bool: return p.accepts(entry.kind, wave))
		var point: SpawnPoint = candidates[_rng.randi_range(0, candidates.size() - 1)]
		points.erase(point)
		var size := mini(_rng.randi_range(entry.group_min, entry.group_max), floori(left / entry.threat_cost))
		for i: int in size:
			var offset := Vector2.ZERO if size == 1 else Vector2.RIGHT.rotated(TAU * i / size) * settings.group_radius
			var copy := _spawn(entry.scene, point.global_position + offset)
			if size == 1 and _elite_chance > 0.0 and left >= entry.threat_cost * 2.0 and _rng.randf() < _elite_chance:
				(copy as Enemy).make_elite(_rng.randi_range(1, Enemy.Elite.size() - 1) as Enemy.Elite)
				left -= entry.threat_cost
		left -= entry.threat_cost * size
	return budget - left


## A weighted random entry that fits the budget and has a free SpawnPoint of its kind, or null.
func _pick_entry(budget: float, points: Array[SpawnPoint]) -> EnemySpawnEntry:
	var options: Array[EnemySpawnEntry] = []
	var total := 0.0
	for entry: EnemySpawnEntry in settings.enemy_pool:
		if entry.first_wave > wave or entry.threat_cost * entry.group_min > budget:
			continue
		if not points.any(func(p: SpawnPoint) -> bool: return p.accepts(entry.kind, wave)):
			continue
		options.append(entry)
		total += entry.weight
	var roll := _rng.randf() * total
	for entry: EnemySpawnEntry in options:
		roll -= entry.weight
		if roll <= 0.0:
			return entry
	return options.back() if not options.is_empty() else null


func _spawn(scene: PackedScene, at: Vector2) -> Node2D:
	var enemy := scene.instantiate() as Node2D
	enemy.position = enemy_parent.to_local(at)
	enemy_parent.add_child(enemy)
	alive.append(enemy)
	return enemy


func _on_next_wave_timer_timeout() -> void:
	start_next_wave()


func _on_enemy_killed(enemy: Node2D) -> void:
	if not alive.has(enemy):
		return
	alive.erase(enemy)
	var dead := enemy as Enemy
	if dead != null and dead.elite == Enemy.Elite.SPLITTER and splitter_scene != null:
		# Bodies can't be added during the physics callback that killed it; the wave stays open meanwhile.
		_pending_splits += 1
		_split.call_deferred(enemy.global_position)
	if alive.is_empty() and _pending_splits == 0:
		_wave_done()


func _split(at: Vector2) -> void:
	_pending_splits -= 1
	for i: int in splitter_count:
		_spawn(splitter_scene, at + Vector2.RIGHT.rotated(TAU * i / splitter_count) * 10.0)
	if alive.is_empty() and _pending_splits == 0:
		_wave_done()


func _wave_done() -> void:
	EventBus.wave_cleared.emit(wave)
	if _room_mode:
		if _waves_left > 0:
			next_wave_timer.start()
		else:
			_room_mode = false
			room_cleared.emit()
		return
	if reward_drops != null and reward_spot != null:
		reward_drops.drop(reward_spot.global_position)
	next_wave_timer.start()
