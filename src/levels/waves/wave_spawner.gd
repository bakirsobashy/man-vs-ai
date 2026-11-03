@icon("res://assets/art/placeholder/icon_spawn.svg")
class_name WaveSpawner
extends Node
## Spends each wave's threat budget at the room's hand-placed SpawnPoints (docs/technical.md §6.4).
## Enemies are copies of authored scenes. When a wave's last enemy dies, the reward drops and the
## NextWaveTimer (its timeout is connected in the scene) starts the next wave.

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

var wave := 0
var alive: Array[Node] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	EventBus.enemy_killed.connect(_on_enemy_killed)


func start_next_wave() -> void:
	if not settings.endless and wave >= settings.waves:
		return
	wave += 1
	var budget := minf(settings.threat_first_wave + (wave - 1) * settings.threat_per_wave, settings.max_threat)
	var spent := _spawn_wave(budget)
	EventBus.wave_started.emit(wave, spent)
	if alive.is_empty():
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
			_spawn(entry.scene, point.global_position + offset)
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


func _spawn(scene: PackedScene, at: Vector2) -> void:
	var enemy := scene.instantiate() as Node2D
	enemy.position = enemy_parent.to_local(at)
	enemy_parent.add_child(enemy)
	alive.append(enemy)


func _on_next_wave_timer_timeout() -> void:
	start_next_wave()


func _on_enemy_killed(enemy: Node2D) -> void:
	if not alive.has(enemy):
		return
	alive.erase(enemy)
	if alive.is_empty():
		if reward_drops != null and reward_spot != null:
			reward_drops.drop(reward_spot.global_position)
		EventBus.wave_cleared.emit(wave)
		next_wave_timer.start()
