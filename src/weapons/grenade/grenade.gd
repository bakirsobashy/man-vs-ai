class_name Grenade
extends Node2D
## A lobbed grenade (Grenadier, FORGEMOTHER). Flies in an arc to `target` over the FlightTimer's wait while the
## LandingCircle (top level) marks the spot, then copies its explosion there. Explosions ignore cover.

@export var explosion_scene: PackedScene
## Peak height of the arc.
@export_range(0.0, 120.0, 1.0, "suffix:px") var arc_height := 40.0

@onready var sprite: Node2D = %Sprite
@onready var landing_circle: Node2D = %LandingCircle
@onready var flight_timer: Timer = %FlightTimer

var target := Vector2.ZERO
var _from := Vector2.ZERO


## Call right after adding the copy to the tree.
func launch(from: Vector2, to: Vector2) -> void:
	_from = from
	target = to
	global_position = from
	landing_circle.global_position = to
	flight_timer.start()


func _process(_delta: float) -> void:
	if flight_timer.is_stopped():
		return
	var t := 1.0 - flight_timer.time_left / flight_timer.wait_time
	global_position = _from.lerp(target, t)
	landing_circle.global_position = target
	sprite.position.y = -sin(t * PI) * arc_height


func _on_flight_timer_timeout() -> void:
	var layer := get_parent() as Node2D
	if explosion_scene != null and layer != null:
		var blast := explosion_scene.instantiate() as Node2D
		blast.position = layer.to_local(target)
		layer.add_child(blast)
	queue_free()
