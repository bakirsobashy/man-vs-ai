class_name BulletEater
extends Area2D
## The Black Box orb's maw (a child of the orb bullet; mask: enemy bullets). Enemy bullets it touches are eaten.
## When the orb pops (a hit, cover, a wall or running out), it bursts `base_shards` plus one shard per eaten bullet
## (up to `max_shards`) as `shard_scene` copies from that scene's BulletPool, fanned in a full circle.
## The orb's `launched` and `popped` signals and this area's area_entered are connected in the orb scene.

@export var shard_scene: PackedScene
@export_range(0, 32) var base_shards := 4
@export_range(1, 64) var max_shards := 20
@export_range(0, 999) var shard_damage := 6

@onready var orb: Bullet = get_parent() as Bullet

var eaten := 0


func _on_area_entered(area: Area2D) -> void:
	var bullet := area as Bullet
	if orb == null or not orb.active or bullet == null or not bullet.active or bullet.pool == null or not bullet.pool.hostile:
		return
	bullet.despawn()
	eaten += 1


func _on_orb_launched() -> void:
	eaten = 0


func _on_orb_popped(at: Vector2) -> void:
	var pool := BulletPool.find_for(get_tree(), shard_scene)
	var shards := mini(base_shards + eaten, max_shards)
	eaten = 0
	if pool == null or shards <= 0:
		return
	for i: int in shards:
		pool.spawn(at, Vector2.from_angle(TAU * i / shards), shard_damage)
