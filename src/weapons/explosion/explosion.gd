class_name Explosion
extends Area2D
## A one-shot blast, copied from explosion.tscn (barrels, later grenades). Damages everything inside its circle
## once: the hero (explosions ignore cover), enemies and cover (so barrels chain). Frees itself when its
## animation ends.

## Damage to the hero, in half-hearts (1 heart).
@export_range(0, 6) var damage_hero := 2
## Damage to enemies (HP).
@export_range(0, 999) var damage_enemies := 20
## Damage to cover and other barrels.
@export_range(0, 999) var damage_cover := 50
## Camera shake (0..1).
@export_range(0.0, 1.0, 0.05) var shake := 0.8


func _ready() -> void:
	_detonate()


func _detonate() -> void:
	# Overlaps are known after the area's first physics step.
	await get_tree().physics_frame
	await get_tree().physics_frame
	for body: Node2D in get_overlapping_bodies():
		if body is Player:
			(body as Player).take_explosion_hit(damage_hero)
		elif body is Cover:
			(body as Cover).take_damage(damage_cover)
		elif body.has_method(&"take_damage"):
			body.call(&"take_damage", damage_enemies)
	EventBus.screen_shake_requested.emit(shake)


func _on_animation_finished(_animation_name: StringName) -> void:
	queue_free()
