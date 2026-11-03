class_name Weapon
extends Node2D
## A gun. Its stats are Inspector exports; Muzzle, Range and the flash are nodes in the weapon scene.
## Each gun keeps its own magazine; the owner sets reload_speed from its current state.

signal ammo_changed(magazine: int, magazine_size: int, reserve: int, reloading: bool)

## The bullet scene this gun fires. A BulletPool for it must exist in the level.
@export var bullet_scene: PackedScene
## Damage per bullet (enemy HP).
@export_range(0, 999) var damage := 4
## Shots per second.
@export_range(0.1, 30.0, 0.1, "suffix:/s") var fire_rate := 4.0
## Rounds per magazine.
@export_range(1, 999) var magazine_size := 10
## Reload time at standing speed.
@export_range(0.1, 5.0, 0.05, "suffix:s") var reload_time := 1.2
## Spare ammo; -1 means infinite.
@export_range(-1, 9999) var ammo_pool := -1
## Total spread; each bullet gets a random angle inside it.
@export_range(0.0, 90.0, 0.5, "suffix:°") var spread_deg := 4.0
## Bullets per shot.
@export_range(1, 20) var pellets := 1

@onready var muzzle: Marker2D = %Muzzle
@onready var range_area: Area2D = %Range
@onready var muzzle_animation: AnimationPlayer = %MuzzleAnimation

## Multiplier set by the owner (running 0.5, standing 1.0, cover 1.4).
var reload_speed := 1.0
var magazine := 0
var reserve := 0
var reloading := false
var _reload_progress := 0.0
var _cooldown := 0.0
var _pool: BulletPool


func _ready() -> void:
	refill()


func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if reloading:
		_reload_progress += delta * reload_speed / reload_time
		if _reload_progress >= 1.0:
			_finish_reload()


func try_fire(target_position: Vector2) -> bool:
	if reloading or _cooldown > 0.0:
		return false
	if magazine <= 0:
		start_reload()
		return false
	if _pool == null:
		_pool = BulletPool.find_for(get_tree(), bullet_scene)
	if _pool == null:
		return false
	var aim := (target_position - muzzle.global_position).normalized()
	for _i: int in pellets:
		var angle := deg_to_rad(randf_range(-spread_deg, spread_deg) * 0.5)
		_pool.spawn(muzzle.global_position, aim.rotated(angle), damage)
	magazine -= 1
	_cooldown = 1.0 / fire_rate
	muzzle_animation.stop()
	muzzle_animation.play(&"flash")
	if magazine == 0:
		start_reload()
	else:
		announce()
	return true


func start_reload() -> void:
	if reloading or magazine >= magazine_size or reserve == 0:
		return
	reloading = true
	_reload_progress = 0.0
	announce()


func reload_if_partial() -> void:
	if magazine < magazine_size:
		start_reload()


func refill() -> void:
	magazine = magazine_size
	reserve = ammo_pool
	reloading = false
	_reload_progress = 0.0
	announce()


func announce() -> void:
	ammo_changed.emit(magazine, magazine_size, reserve, reloading)


func _finish_reload() -> void:
	var needed := magazine_size - magazine
	if reserve < 0:
		magazine = magazine_size
	else:
		var taken := mini(needed, reserve)
		magazine += taken
		reserve -= taken
	reloading = false
	announce()
