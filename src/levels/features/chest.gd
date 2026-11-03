class_name Chest
extends Area2D
## Opens when the hero touches it (mask: player). Drops one gun of its rarity from the weapon catalog as a
## WeaponPickup at DropSpot, plus a Crypto bonus of 5 × tier; with no usable gun it pays 15 × tier more instead
## (docs/content.md §8). The LevelDirector rolls the rarity when the room is first entered.

@export var rarity := WeaponCatalogEntry.Rarity.COMMON
@export var catalog: WeaponCatalog
@export var weapon_pickup_scene: PackedScene
## Lid tint per rarity: Common, Rare, Epic, Legendary.
@export var rarity_colors: Array[Color] = [Color(0.85, 0.7, 0.45), Color(0.4, 0.75, 1.0), Color(0.75, 0.45, 1.0), Color(1.0, 0.8, 0.2)]

@onready var sprite: Sprite2D = %Sprite
@onready var drop_spot: Marker2D = %DropSpot
@onready var bonus: Drops = %Bonus

var opened := false


func _ready() -> void:
	_refresh()


func set_rarity(value: WeaponCatalogEntry.Rarity) -> void:
	rarity = value
	if is_node_ready():
		_refresh()


func open() -> void:
	if opened:
		return
	opened = true
	_refresh()
	var layer := get_tree().get_first_node_in_group(&"drop_layer") as Node2D
	var tier := rarity + 1
	var scene := catalog.pick(rarity) if catalog != null else null
	var gave_gun := scene != null and weapon_pickup_scene != null and layer != null
	if gave_gun:
		var pickup := weapon_pickup_scene.instantiate() as WeaponPickup
		pickup.weapon_scene = scene
		pickup.position = layer.to_local(drop_spot.global_position)
		layer.add_child.call_deferred(pickup)
	bonus.crypto_min = 5 * tier if gave_gun else 20 * tier
	bonus.crypto_max = bonus.crypto_min
	bonus.drop(drop_spot.global_position + Vector2(0, 14))


func _refresh() -> void:
	sprite.frame = 1 if opened else 0
	if rarity < rarity_colors.size():
		sprite.self_modulate = rarity_colors[rarity]


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		open()
