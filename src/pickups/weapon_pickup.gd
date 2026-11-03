class_name WeaponPickup
extends Area2D
## A gun lying on the floor. Place one in a room and set weapon_scene; the gun copy it holds is shown on the
## floor and handed to the hero (ammo and all). The hero's InteractSensor finds it; the HUD prompt picks it up.

## The authored weapon scene to hold. Leave empty when the pickup is created to hold a dropped gun.
@export var weapon_scene: PackedScene

@onready var holder: Node2D = %Holder


func _ready() -> void:
	if holder.get_child_count() == 0 and weapon_scene != null:
		hold(weapon_scene.instantiate() as Weapon)


func weapon() -> Weapon:
	return holder.get_child(0) as Weapon if holder.get_child_count() > 0 else null


## Put a gun on the floor here (a new copy, or a gun the hero just dropped).
func hold(gun: Weapon) -> void:
	if gun.get_parent() == null:
		holder.add_child(gun)
	else:
		gun.reparent(holder, false)
	gun.position = Vector2.ZERO
	gun.rotation = 0.0
	gun.set_active(false)
	gun.visible = true


## Hand the gun over and remove the pickup.
func take() -> Weapon:
	var gun := weapon()
	queue_free()
	return gun
