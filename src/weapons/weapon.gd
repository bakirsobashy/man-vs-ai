class_name Weapon
extends Node2D
## A gun. Its stats are Inspector exports; Muzzle, Range and the flash are nodes in the weapon scene.
## Each gun keeps its own magazine; the owner sets reload_speed from its current state.

signal ammo_changed(weapon: Weapon, magazine: int, magazine_size: int, reserve: int, reloading: bool)
## Every shot (the ShotSound node is connected to it in each weapon scene).
signal shot_fired

## Name shown on the HUD weapon card and the pickup prompt.
@export var display_name := "Gun"
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
## Spare ammo on top of the loaded magazine; -1 means infinite.
@export_range(-1, 9999) var ammo_pool := -1
## Total spread. One bullet gets a random angle inside it; several pellets fan out across it.
@export_range(0.0, 90.0, 0.5, "suffix:°") var spread_deg := 4.0
## Bullets per shot.
@export_range(1, 20) var pellets := 1
## Shots per trigger pull (Firecracker: 3); each uses one round. fire_rate counts bursts.
@export_range(1, 10) var burst := 1
## Time between the shots of a burst.
@export_range(0.01, 0.5, 0.01, "suffix:s") var burst_interval := 0.07
## Junk Cannon: each shot's damage is random between damage and damage_max (0 = always `damage`).
@export_range(0, 999) var damage_max := 0
## Overclock Pistol: the fire rate climbs to this while the trigger stays held (0 = no ramp).
@export_range(0.0, 30.0, 0.1, "suffix:/s") var ramp_fire_rate := 0.0
## Seconds of continuous fire to reach ramp_fire_rate.
@export_range(0.1, 10.0, 0.1, "suffix:s") var ramp_time := 2.0
## A pause longer than this resets the ramp.
@export_range(0.05, 2.0, 0.05, "suffix:s") var ramp_reset := 0.5
## Rail Spike: the trigger must be held this long before each shot, which then fires by itself (0 = none).
@export_range(0.0, 5.0, 0.05, "suffix:s") var charge_time := 0.0
## Scrap Minigun: the trigger must be held this long before the first shot; it then fires freely (0 = none).
@export_range(0.0, 3.0, 0.05, "suffix:s") var spin_up := 0.0
## Scrap Minigun: the hero's move speed multiplier while this gun is firing.
@export_range(0.1, 1.0, 0.05) var firing_move_scale := 1.0

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
var _burst_left := 0
var _burst_timer := 0.0
var _burst_target := Vector2.ZERO
var _ramp_elapsed := 0.0
var _since_shot := 99.0
## Seconds the trigger has been held (try_fire called within the last 0.15 s).
var _held := 0.0
var _since_try := 99.0
## Hawk Optics Mk II: chance that a bullet deals double damage (set by the hero).
var crit_chance := 0.0
## Servo Arms and Second Wind multipliers (set by the hero).
var spread_scale := 1.0
var fire_rate_scale := 1.0
var damage_scale := 1.0


func _ready() -> void:
	refill()


func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	_since_shot += delta
	_ramp_elapsed = _ramp_elapsed + delta if _since_shot < ramp_reset else 0.0
	_since_try += delta
	_held = _held + delta if _since_try <= 0.15 else 0.0
	if _burst_left > 0:
		_burst_timer -= delta
		if _burst_timer <= 0.0:
			_burst_timer = burst_interval
			_burst_left -= 1
			_shoot(_burst_target)
	if reloading:
		_reload_progress += delta * reload_speed / reload_time
		if _reload_progress >= 1.0:
			_finish_reload()


## Shown and processing while in the hero's hands; hidden and paused when holstered.
func set_active(on: bool) -> void:
	visible = on
	process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED


func try_fire(target_position: Vector2) -> bool:
	_since_try = 0.0
	if reloading or _cooldown > 0.0:
		return false
	if (spin_up > 0.0 and _held < spin_up) or (charge_time > 0.0 and _held < charge_time):
		return false
	if magazine <= 0:
		start_reload()
		return false
	if not _can_emit():
		return false
	_cooldown = 1.0 / current_fire_rate()
	_since_shot = 0.0
	if charge_time > 0.0:
		_held = 0.0
	_burst_left = burst - 1
	_burst_timer = burst_interval
	_burst_target = target_position
	_shoot(target_position)
	return true


func _shoot(target_position: Vector2) -> void:
	if magazine <= 0 or reloading:
		_burst_left = 0
		return
	_emit((target_position - muzzle.global_position).normalized())
	magazine -= 1
	muzzle_animation.stop()
	muzzle_animation.play(&"flash")
	shot_fired.emit()
	if magazine == 0:
		_burst_left = 0
		start_reload()
	else:
		announce()


## Whether a shot can go out (bullet guns need their level's BulletPool). BeamWeapon overrides it.
func _can_emit() -> bool:
	if _pool == null:
		_pool = BulletPool.find_for(get_tree(), bullet_scene)
	return _pool != null


## One shot's bullets along `aim` (pellets fan out across the spread). BeamWeapon overrides it.
func _emit(aim: Vector2) -> void:
	var spread := deg_to_rad(spread_deg * spread_scale)
	for i: int in pellets:
		var angle := randf_range(-spread, spread) * 0.5
		if pellets > 1:
			angle = -spread * 0.5 + spread * i / (pellets - 1) + randf_range(-spread, spread) / (pellets * 4.0)
		_pool.spawn(muzzle.global_position, aim.rotated(angle), _roll_damage())


## Shots per second right now (the Overclock Pistol's ramp included).
func current_fire_rate() -> float:
	if ramp_fire_rate <= fire_rate:
		return fire_rate * fire_rate_scale
	return lerpf(fire_rate, ramp_fire_rate, clampf(_ramp_elapsed / ramp_time, 0.0, 1.0)) * fire_rate_scale


## 0–1 progress of the Rail Spike's charge or the minigun's spin-up (for the HUD and effects).
func charge_progress() -> float:
	var need := maxf(charge_time, spin_up)
	return clampf(_held / need, 0.0, 1.0) if need > 0.0 else 1.0


## The hero's move speed multiplier from this gun (the Scrap Minigun slows the hero while firing).
func move_speed_scale() -> float:
	return firing_move_scale if _since_shot < 0.25 else 1.0


## Hawk Optics Mk I: a longer auto-aim reach (the Range circle scales with it).
func set_range_scale(factor: float) -> void:
	range_area.scale = Vector2.ONE * factor


func _roll_damage() -> int:
	var amount := roundi((randi_range(damage, damage_max) if damage_max > damage else damage) * damage_scale)
	return amount * 2 if crit_chance > 0.0 and randf() < crit_chance else amount


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


## Out of bullets for good (magazine and spare ammo both empty).
func is_empty() -> bool:
	return magazine <= 0 and reserve == 0


func needs_ammo() -> bool:
	return ammo_pool >= 0 and reserve < ammo_pool


## Ammo pickups add a share of the gun's pool (content.md: 25%).
func add_ammo_share(share: float) -> void:
	if ammo_pool < 0:
		return
	reserve = mini(reserve + ceili(ammo_pool * share), ammo_pool)
	if magazine == 0:
		start_reload()
	announce()


func announce() -> void:
	ammo_changed.emit(self, magazine, magazine_size, reserve, reloading)


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
