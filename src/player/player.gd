class_name Player
extends CharacterBody2D
## The hero. Every node used here is authored in player.tscn; this script only adds behavior.
## Touch intents arrive through signals connected in the level scene; HUD requests arrive through EventBus.

@export_group("Movement")
## Run speed at full stick deflection (6 tiles/s).
@export_range(0.0, 400.0, 1.0, "suffix:px/s") var move_speed := 96.0

@export_group("Roll")
## Distance of one roll (3.5 tiles).
@export_range(0.0, 200.0, 1.0, "suffix:px") var roll_distance := 56.0
## Duration of the moving part of the roll.
@export_range(0.05, 1.0, 0.01, "suffix:s") var roll_time := 0.40
## Share of the roll that is invulnerable.
@export_range(0.0, 1.0, 0.05) var iframe_ratio := 0.6
## Standstill after a roll before the hero can act again.
@export_range(0.0, 0.5, 0.01, "suffix:s") var recovery_time := 0.10

@export_group("Cover")
## Slide speed toward cover (12 tiles/s). The search radius is the CoverSensor circle.
@export_range(0.0, 400.0, 1.0, "suffix:px/s") var slide_speed := 192.0
## Give up a slide that hasn't arrived after this long.
@export_range(0.05, 1.0, 0.01, "suffix:s") var max_slide_time := 0.4
## The slide has arrived within this distance of its spot.
@export_range(0.5, 8.0, 0.5, "suffix:px") var cover_arrive_distance := 1.5
## Gap kept between the hero's body and the cover.
@export_range(0.0, 8.0, 0.5, "suffix:px") var cover_gap := 2.0

@export_group("Reload speed")
## Reload speed multiplier while running.
@export_range(0.0, 3.0, 0.05) var reload_speed_running := 0.5
## Reload speed multiplier while standing in the open.
@export_range(0.0, 3.0, 0.05) var reload_speed_standing := 1.0
## Reload speed multiplier while in cover.
@export_range(0.0, 3.0, 0.05) var reload_speed_cover := 1.4

@export_group("EMP")
## EMP charges at the start of each level.
@export_range(0, 9) var emp_charges_per_level := 2
## How long the EMP stuns enemies inside the EmpRange circle.
@export_range(0.0, 5.0, 0.1, "suffix:s") var emp_stun_time := 1.5

@export_group("Pickups")
## Share of the found gun's ammo pool one ammo pickup adds.
@export_range(0.0, 1.0, 0.05) var ammo_pickup_share := 0.25
## Copied to put a dropped gun on the floor.
@export var weapon_pickup_scene: PackedScene

@export_group("Feedback")
## Vibrate on hits, rolls, cover and EMP (Android needs the VIBRATE permission in the export preset).
@export var haptics_enabled := true
@export_range(0, 200, 1, "suffix:ms") var haptic_hit_ms := 60
@export_range(0, 200, 1, "suffix:ms") var haptic_roll_ms := 15
@export_range(0, 200, 1, "suffix:ms") var haptic_cover_ms := 15
@export_range(0, 200, 1, "suffix:ms") var haptic_emp_ms := 80
## Camera shake when the hero is hit (0..1).
@export_range(0.0, 1.0, 0.05) var hit_shake := 0.5

@export_group("Links")
## The level's TouchController.
@export var touch: TouchController
## Shared controls tuning (the A/B switches live here).
@export var tuning: ControlsTuning
## Where the hero comes back after dying (greybox convenience).
@export var respawn_point: Marker2D

@onready var body_shape: CollisionShape2D = %BodyShape
@onready var gun_pivot: Node2D = %GunPivot
@onready var weapon_slot: Node2D = %WeaponSlot
@onready var reticle: Node2D = %Reticle
@onready var hurtbox: Area2D = %Hurtbox
@onready var cover_sensor: Area2D = %CoverSensor
@onready var emp_range: Area2D = %EmpRange
@onready var pickup_magnet: Area2D = %PickupMagnet
@onready var interact_sensor: Area2D = %InteractSensor
@onready var state_machine: StateMachine = %StateMachine
@onready var health: Health = %Health
@onready var target_selector: TargetSelector = %TargetSelector
@onready var partial_reload_timer: Timer = %PartialReloadTimer
@onready var respawn_timer: Timer = %RespawnTimer
@onready var body_animation: AnimationPlayer = %BodyAnimation
@onready var flash_animation: AnimationPlayer = %FlashAnimation
@onready var emp_animation: AnimationPlayer = %EmpAnimation

## The starter pistol (pre-placed in WeaponSlot). Always carried, infinite ammo.
var primary: Weapon
## The found gun (a copy taken from a WeaponPickup), or null.
var secondary: Weapon
## The gun in the hero's hands.
var weapon: Weapon
var emp_charges := 0
var rolling_invulnerable := false
var cover: Cover
var cover_normal := Vector2.ZERO
var _reload_multiplier := 1.0
var _prompt_pickup: WeaponPickup


func _ready() -> void:
	primary = weapon_slot.get_child(0) as Weapon
	weapon = primary
	target_selector.range_area = weapon.range_area
	emp_charges = emp_charges_per_level
	EventBus.cover_destroyed.connect(_on_cover_destroyed)
	EventBus.weapon_swap_requested.connect(swap_weapon)
	EventBus.interact_requested.connect(interact)
	_announce.call_deferred()


func _physics_process(delta: float) -> void:
	if state_machine.is_in(&"Dead"):
		return
	_check_contact_damage()
	_pull_pickups(delta)
	_update_interact_prompt()


## After the finger lifts (or a roll ends with the finger up): take cover if any is in range, else stand.
func settle() -> void:
	var spot := find_cover_spot()
	if spot != null:
		state_machine.transition_to(&"SlideToCover", {"spot": spot})
	else:
		state_machine.transition_to(&"Stand")


## The best reachable spot next to cover inside the CoverSensor circle, or null.
func find_cover_spot() -> CoverSpot:
	var clearance := hero_radius() + cover_gap
	var smart := tuning.cover_mode == ControlsTuning.CoverMode.SMART_SIDE
	var away := _away_from_threats() if smart else Vector2.ZERO
	var best: CoverSpot = null
	var best_score := INF
	for body: Node2D in cover_sensor.get_overlapping_bodies():
		var piece := body as Cover
		if piece == null or not piece.is_intact() or not piece.provides_cover:
			continue
		for spot: CoverSpot in piece.spots_for(global_position, clearance):
			if test_move(global_transform, spot.position - global_position):
				continue
			var score := global_position.distance_to(spot.position) - spot.normal.dot(away) * tuning.smart_side_bias
			if score < best_score:
				best_score = score
				best = spot
	return best


func take_cover(spot: CoverSpot) -> void:
	cover = spot.cover
	cover_normal = spot.normal
	body_animation.play(&"crouch")
	haptic(haptic_cover_ms)


func leave_cover() -> void:
	cover = null
	body_animation.play(&"uncrouch")


func update_aim(move_direction: Vector2) -> void:
	var target := target_selector.current_target
	if target != null:
		gun_pivot.rotation = (target.global_position - gun_pivot.global_position).angle()
		reticle.global_position = target.global_position
		reticle.visible = true
		return
	reticle.visible = false
	if move_direction != Vector2.ZERO:
		gun_pivot.rotation = move_direction.angle()


func try_fire() -> void:
	if weapon != primary and weapon.is_empty():
		_activate(primary)
	var target := target_selector.current_target
	if target != null:
		weapon.try_fire(target.global_position)


func set_reload_speed(multiplier: float) -> void:
	_reload_multiplier = multiplier
	weapon.reload_speed = multiplier


## Switch between the starter pistol and the found gun (the HUD weapon card).
func swap_weapon() -> void:
	if secondary == null or state_machine.is_in(&"Dead"):
		return
	if weapon == primary:
		if not secondary.is_empty():
			_activate(secondary)
	else:
		_activate(primary)


## Pick up the gun the prompt is showing. The current found gun is dropped in its place.
func interact() -> void:
	if _prompt_pickup == null or not is_instance_valid(_prompt_pickup) or state_machine.is_in(&"Dead"):
		return
	var pickup := _prompt_pickup
	_prompt_pickup = null
	EventBus.interact_prompt_changed.emit("")
	var gun := pickup.take()
	if secondary != null:
		_drop_weapon(secondary, pickup.global_position)
	gun.reparent(weapon_slot, false)
	gun.position = Vector2.ZERO
	gun.rotation = 0.0
	gun.ammo_changed.connect(_on_weapon_ammo_changed)
	secondary = gun
	_activate(gun)


func take_explosion_hit(amount: int) -> void:
	if state_machine.is_in(&"Dead") or rolling_invulnerable:
		return
	health.take_hit(amount)


func hero_radius() -> float:
	var circle := body_shape.shape as CircleShape2D
	return circle.radius if circle != null else 0.0


func fire_emp() -> void:
	if state_machine.is_in(&"Dead") or emp_charges <= 0:
		return
	emp_charges -= 1
	for node: Node in get_tree().get_nodes_in_group(&"bullet_pools"):
		var pool := node as BulletPool
		if pool != null and pool.hostile:
			pool.clear_active()
	for body: Node2D in emp_range.get_overlapping_bodies():
		if body.has_method(&"stun"):
			body.call(&"stun", emp_stun_time)
	emp_animation.stop()
	emp_animation.play(&"emp")
	haptic(haptic_emp_ms)
	EventBus.screen_shake_requested.emit(0.4)
	EventBus.player_emp_changed.emit(emp_charges)


func haptic(duration_ms: int) -> void:
	if haptics_enabled and duration_ms > 0:
		Input.vibrate_handheld(duration_ms)


func respawn() -> void:
	if respawn_point != null:
		global_position = respawn_point.global_position
	health.reset()
	emp_charges = emp_charges_per_level
	primary.refill()
	_activate(primary)
	flash_animation.play(&"RESET")
	state_machine.transition_to(&"Stand")
	_announce()


func _activate(gun: Weapon) -> void:
	if weapon != null and weapon != gun:
		weapon.set_active(false)
	weapon = gun
	weapon.set_active(true)
	weapon.reload_speed = _reload_multiplier
	target_selector.range_area = weapon.range_area
	target_selector.current_target = null
	EventBus.player_weapon_changed.emit(weapon.display_name, 1 if weapon == primary else 2, 1 if secondary == null else 2)
	weapon.announce()


func _drop_weapon(gun: Weapon, at: Vector2) -> void:
	gun.ammo_changed.disconnect(_on_weapon_ammo_changed)
	if gun == weapon:
		_activate(primary)
	secondary = null
	var layer := get_tree().get_first_node_in_group(&"drop_layer")
	if layer == null or weapon_pickup_scene == null:
		gun.queue_free()
		return
	var pickup := weapon_pickup_scene.instantiate() as WeaponPickup
	pickup.position = at
	layer.add_child(pickup)
	pickup.hold(gun)


func _announce() -> void:
	EventBus.player_health_changed.emit(health.hp, health.max_hp, health.armor)
	EventBus.player_emp_changed.emit(emp_charges)
	EventBus.player_weapon_changed.emit(weapon.display_name, 1 if weapon == primary else 2, 1 if secondary == null else 2)
	weapon.announce()


func _state() -> PlayerState:
	return state_machine.current as PlayerState


func _is_protected_from(bullet: Bullet) -> bool:
	return state_machine.is_in(&"InCover") and cover != null and cover.is_intact() \
		and not bullet.explosive and not bullet.aerial and bullet.direction.dot(cover_normal) > 0.0


func _away_from_threats() -> Vector2:
	var sum := Vector2.ZERO
	var count := 0
	for node: Node in get_tree().get_nodes_in_group(&"enemies"):
		var enemy := node as Node2D
		if enemy != null and enemy.is_visible_in_tree():
			sum += enemy.global_position
			count += 1
	return (global_position - sum / count).normalized() if count > 0 else Vector2.ZERO


## Touch damage from ContactHitbox areas overlapping the Hurtbox (checked every frame, not only on entry).
func _check_contact_damage() -> void:
	if rolling_invulnerable or health.is_invulnerable():
		return
	for area: Area2D in hurtbox.get_overlapping_areas():
		var contact := area as ContactHitbox
		if contact != null and contact.is_active():
			health.take_hit(contact.damage)
			return


func _pull_pickups(delta: float) -> void:
	for area: Area2D in pickup_magnet.get_overlapping_areas():
		var pickup := area as Pickup
		if pickup == null or pickup.is_queued_for_deletion() or not _can_use(pickup):
			continue
		if pickup.pull_toward(global_position, delta):
			_apply_pickup(pickup)
			pickup.collect()


func _can_use(pickup: Pickup) -> bool:
	match pickup.kind:
		Pickup.Kind.HALF_HEART:
			return health.hp < health.max_hp
		Pickup.Kind.ARMOR:
			return health.armor < health.max_armor
		Pickup.Kind.AMMO:
			return secondary != null and secondary.needs_ammo()
	return true


func _apply_pickup(pickup: Pickup) -> void:
	match pickup.kind:
		Pickup.Kind.RAM:
			RunState.add_ram(pickup.amount)
		Pickup.Kind.CRYPTO:
			RunState.add_crypto(pickup.amount)
		Pickup.Kind.HALF_HEART:
			health.heal(pickup.amount)
		Pickup.Kind.ARMOR:
			health.add_armor(pickup.amount)
		Pickup.Kind.AMMO:
			secondary.add_ammo_share(ammo_pickup_share)


func _update_interact_prompt() -> void:
	var nearest: WeaponPickup = null
	var nearest_distance := INF
	for area: Area2D in interact_sensor.get_overlapping_areas():
		var pickup := area as WeaponPickup
		if pickup == null or pickup.is_queued_for_deletion() or pickup.weapon() == null:
			continue
		var distance := global_position.distance_to(pickup.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = pickup
	if nearest == _prompt_pickup:
		return
	_prompt_pickup = nearest
	EventBus.interact_prompt_changed.emit("" if nearest == null else "Take %s" % nearest.weapon().display_name)


# --- Touch intents (connected from the TouchController in the level scene) ---

func _on_touch_started() -> void:
	if _state() != null:
		_state().on_touch_started()


func _on_touch_rolled(direction: Vector2) -> void:
	if _state() != null:
		_state().on_rolled(direction)


func _on_touch_lifted() -> void:
	if _state() != null:
		_state().on_lifted()


func _on_touch_special_requested() -> void:
	fire_emp()


# --- Signals connected in player.tscn (and to found guns when they're picked up) ---

func _on_hurtbox_area_entered(area: Area2D) -> void:
	var bullet := area as Bullet
	if bullet == null or not bullet.active or state_machine.is_in(&"Dead"):
		return
	if _is_protected_from(bullet):
		cover.take_damage(bullet.cover_damage)
		bullet.despawn()
		return
	if rolling_invulnerable or health.is_invulnerable():
		return
	health.take_hit(bullet.hit_damage)
	bullet.despawn()


func _on_health_changed(hp: int, max_hp: int, armor: int, damaged: bool) -> void:
	if damaged and is_node_ready():
		flash_animation.stop()
		flash_animation.play(&"hurt_blink")
		haptic(haptic_hit_ms)
		EventBus.screen_shake_requested.emit(hit_shake)
	EventBus.player_health_changed.emit(hp, max_hp, armor)


func _on_health_died() -> void:
	state_machine.transition_to(&"Dead")
	EventBus.player_died.emit()


func _on_partial_reload_timer_timeout() -> void:
	weapon.reload_if_partial()


func _on_respawn_timer_timeout() -> void:
	respawn()


func _on_weapon_ammo_changed(gun: Weapon, magazine: int, magazine_size: int, reserve: int, reloading: bool) -> void:
	if gun == weapon:
		EventBus.player_ammo_changed.emit(magazine, magazine_size, reserve, reloading)


func _on_state_machine_state_changed(state_name: StringName) -> void:
	EventBus.player_state_changed.emit(state_name)


# --- EventBus ---

func _on_cover_destroyed(destroyed: Node2D) -> void:
	if destroyed == cover and state_machine.is_in(&"InCover"):
		state_machine.transition_to(&"Stand")
		flash_animation.play(&"exposed")
