class_name EnemySpawnEntry
extends Resource
## One enemy type the WaveSpawner may buy with a wave's threat budget (docs/content.md §2 and §6).

## The authored enemy scene to copy.
@export var scene: PackedScene
## Threat cost of one enemy (Swarmer 0.5, Grunt 1, Charger 1.5, Turret 2…).
@export_range(0.1, 20.0, 0.1) var threat_cost := 1.0
## Must match the enemy's spawn kind; SpawnPoints only take the kinds ticked on them.
@export_flags("Ground", "Flyer", "Stationary") var kind := 1
## Enemies spawned together at one point (swarmers come in groups of 4–6).
@export_range(1, 12) var group_min := 1
@export_range(1, 12) var group_max := 1
## First wave this enemy can appear in.
@export_range(1, 99) var first_wave := 1
## Relative pick chance.
@export_range(0.0, 10.0, 0.1) var weight := 1.0
