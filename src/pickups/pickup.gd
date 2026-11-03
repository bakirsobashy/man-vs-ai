class_name Pickup
extends Area2D
## Something to collect (layer: pickups). The hero's PickupMagnet pulls in pickups the hero can use;
## the hero decides what each kind does (Player._apply_pickup).

enum Kind { RAM, CRYPTO, HALF_HEART, ARMOR, AMMO }

@export var kind := Kind.RAM
## RAM in MB, Crypto, half-hearts or armor pips. Ammo pickups always add 25% of the found gun's pool.
@export_range(1, 9999) var amount := 1
## How fast the magnet pulls it.
@export_range(0.0, 600.0, 1.0, "suffix:px/s") var magnet_speed := 220.0
## Collected within this distance of the hero.
@export_range(1.0, 32.0, 1.0, "suffix:px") var collect_distance := 8.0


## Moves toward the hero; true once it's close enough to collect.
func pull_toward(target: Vector2, delta: float) -> bool:
	global_position = global_position.move_toward(target, magnet_speed * delta)
	return global_position.distance_to(target) <= collect_distance


func collect() -> void:
	queue_free()
