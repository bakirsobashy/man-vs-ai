class_name RoomEntry
extends Resource
## One room template the LevelGenerator may use (part of a LevelConfig's room pool).

## The authored room scene (its root runs room.gd).
@export var scene: PackedScene
## Must match the scene's room_type.
@export var type := Room.RoomType.COMBAT
## Relative pick chance among rooms of the same type.
@export_range(0.0, 10.0, 0.1) var weight := 1.0
