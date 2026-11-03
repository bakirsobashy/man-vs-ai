@icon("res://assets/art/placeholder/icon_contact.svg")
class_name ContactHitbox
extends Area2D
## Touch damage (layer: enemy_contact). The hero's Hurtbox checks for overlapping contact hitboxes every
## physics frame, so standing in a swarm keeps hurting once the post-hit invulnerability ends.

## Damage per touch, in half-hearts.
@export_range(1, 6) var damage := 1


## Harmless while the owner is still spawning in.
func is_active() -> bool:
	return not owner.has_method(&"is_targetable") or bool(owner.call(&"is_targetable"))
