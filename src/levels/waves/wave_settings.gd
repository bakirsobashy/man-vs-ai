class_name WaveSettings
extends Resource
## How a WaveSpawner builds its waves: the enemy pool and the threat budget per wave
## (docs/content.md §6). Becomes part of each level's LevelConfig in M3.

@export var enemy_pool: Array[EnemySpawnEntry] = []
## Threat budget of wave 1.
@export_range(0.0, 50.0, 0.5) var threat_first_wave := 6.0
## Budget added each wave.
@export_range(0.0, 10.0, 0.5) var threat_per_wave := 1.5
## Budget cap.
@export_range(0.0, 50.0, 0.5) var max_threat := 14.0
## Keep starting waves forever (the M2 arena) instead of stopping after `waves`.
@export var endless := true
@export_range(1, 10) var waves := 3
## SpawnPoints closer than this to the hero are skipped (3 tiles).
@export_range(0.0, 400.0, 1.0, "suffix:px") var min_spawn_distance := 48.0
## Spacing of group members around their SpawnPoint.
@export_range(0.0, 64.0, 1.0, "suffix:px") var group_radius := 12.0
