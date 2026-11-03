class_name Door
extends Node2D
## A doorway in a room wall. One scene for every wall: rotate the instance to fit (0° top, 90° right,
## 180° bottom, -90° left) and set `direction` to match.
## OPEN: walking into the Exit area takes the hero to the next room. LOCKED: bars during a fight.
## SEALED: no room behind it (looks like wall).

enum Direction { NORTH, EAST, SOUTH, WEST }
enum Status { OPEN, LOCKED, SEALED }

const VECTORS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

@export var direction := Direction.NORTH

@onready var blocker_shape: CollisionShape2D = %BlockerShape
@onready var sprite: Sprite2D = %Sprite
## Where the hero appears when arriving through this door.
@onready var entry: Marker2D = %Entry

var status := Status.SEALED


func direction_vector() -> Vector2i:
	return VECTORS[direction]


func set_status(new_status: Status) -> void:
	status = new_status
	blocker_shape.set_deferred(&"disabled", new_status == Status.OPEN)
	sprite.frame = new_status


func _on_exit_body_entered(body: Node2D) -> void:
	if status == Status.OPEN and body is Player:
		EventBus.door_entered.emit(direction_vector())
