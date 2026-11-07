@icon("res://assets/art/placeholder/icon_pool.svg")
class_name BulletPool
extends Node2D
## Copies one authored bullet scene when the level loads and recycles those copies,
## so nothing is instanced mid-fight. Keep this node in the "bullet_pools" group (set in the scene),
## and place it outside the playfield: inactive bullets wait at the pool's position.

## The authored bullet scene to copy.
@export var bullet_scene: PackedScene
## Number of copies. Firing silently stops while all of them are in flight.
@export_range(1, 2000) var size := 200
## Enemy bullets. The EMP clears every hostile pool.
@export var hostile := false

var active_count := 0
var _free: Array[Bullet] = []


func _ready() -> void:
	EventBus.settings_changed.connect(apply_palette)
	apply_palette()
	for _i: int in size:
		var bullet := bullet_scene.instantiate() as Bullet
		bullet.pool = self
		add_child(bullet)
		bullet.deactivate()
		_free.append(bullet)


func spawn(at: Vector2, direction: Vector2, damage_override := -1) -> Bullet:
	if _free.is_empty():
		return null
	var bullet: Bullet = _free.pop_back()
	active_count += 1
	bullet.launch(at, direction, damage_override)
	return bullet


func release(bullet: Bullet) -> void:
	active_count -= 1
	_free.append(bullet)


func clear_active() -> void:
	for child: Node in get_children():
		var bullet := child as Bullet
		if bullet != null and bullet.active:
			bullet.despawn()


## Despawns active bullets within `radius` of `center` (the Hydraulic Legs shockwave).
func clear_within(center: Vector2, radius: float) -> void:
	for child: Node in get_children():
		var bullet := child as Bullet
		if bullet != null and bullet.active and bullet.global_position.distance_to(center) <= radius:
			bullet.despawn()


static func find_for(tree: SceneTree, scene: PackedScene) -> BulletPool:
	for node: Node in tree.get_nodes_in_group(&"bullet_pools"):
		var pool := node as BulletPool
		if pool != null and pool.bullet_scene == scene:
			return pool
	return null


## The bullet color setting (GDD §8.5): the pool's material recolors its bullets (they use the parent material).
func apply_palette() -> void:
	var palette := SaveManager.palette()
	material = null if palette == null else (palette.hostile_material if hostile else palette.friendly_material)
