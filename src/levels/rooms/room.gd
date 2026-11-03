@icon("res://assets/art/placeholder/icon_room.svg")
class_name Room
extends Node2D
## Root of every room template (docs/technical.md §7.3). The LevelDirector copies room scenes into the level;
## everything inside (doors, cover, spawn points, features) is placed by hand in the room's scene.
## The NavRegion's navigation mesh is baked around the walls and cover when the room first loads.

enum RoomType { START, COMBAT, CHEST, MEMORY, ARENA, REPAIR, TERMINAL, BOSS }

@export var room_type := RoomType.COMBAT
## Waves in this room (0 = use the level's range).
@export_range(0, 6) var waves := 0

@onready var doors: Node2D = get_node_or_null(^"%Doors") as Node2D
@onready var spawn_points: Node2D = get_node_or_null(^"%SpawnPoints") as Node2D
@onready var enemies: Node2D = get_node_or_null(^"%Enemies") as Node2D
@onready var reward_spot: Marker2D = get_node_or_null(^"%RewardSpot") as Marker2D
@onready var player_start: Marker2D = get_node_or_null(^"%PlayerStart") as Marker2D
@onready var camera_bounds: Control = get_node_or_null(^"%CameraBounds") as Control
@onready var nav_region: NavigationRegion2D = get_node_or_null(^"%NavRegion") as NavigationRegion2D
@onready var rebake_timer: Timer = get_node_or_null(^"%RebakeTimer") as Timer


func _ready() -> void:
	EventBus.cover_destroyed.connect(_on_cover_changed)
	EventBus.cover_restored.connect(_on_cover_changed)
	bake_navigation()


func bake_navigation() -> void:
	if nav_region != null:
		nav_region.bake_navigation_polygon(false)


## The door on the wall facing `direction` (grid direction), or null.
func door(direction: Vector2i) -> Door:
	if doors == null:
		return null
	for child: Node in doors.get_children():
		var candidate := child as Door
		if candidate != null and candidate.direction_vector() == direction:
			return candidate
	return null


func all_doors() -> Array[Door]:
	var result: Array[Door] = []
	if doors != null:
		for child: Node in doors.get_children():
			if child is Door:
				result.append(child as Door)
	return result


## Optional feature nodes by unique name (Chest, Station, Terminal, Shrine, Console, BossSpot, Elevator).
func feature(unique_name: String) -> Node:
	return get_node_or_null(NodePath("%" + unique_name))


func _on_cover_changed(cover: Node2D) -> void:
	if rebake_timer != null and is_inside_tree() and is_ancestor_of(cover):
		rebake_timer.start()


func _on_rebake_timer_timeout() -> void:
	bake_navigation()
