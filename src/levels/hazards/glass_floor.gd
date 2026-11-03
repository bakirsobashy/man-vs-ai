class_name GlassFloor
extends Area2D
## A cracking glass floor panel (Skyline Spires). Standing on it starts the CrackTimer; when it runs out the glass
## shatters into a hole for RegrowTimer's wait. A hero on the hole falls: he loses `damage` and is put back where he
## stepped on. A roll carries him over a hole (Player.airborne). Robots ignore it. Timer timeouts are connected in the
## scene.

enum GlassState { INTACT, CRACKING, BROKEN }

## Half-hearts lost in a fall.
@export_range(0, 6) var damage := 2

@onready var shape: CollisionShape2D = %Shape
@onready var crack_timer: Timer = %CrackTimer
@onready var regrow_timer: Timer = %RegrowTimer
@onready var glass_animation: AnimationPlayer = %GlassAnimation

var glass_state := GlassState.INTACT
var _hero: Player
## Where the hero stood just before stepping onto the panel.
var _safe_spot := Vector2.ZERO


func _ready() -> void:
	glass_animation.play(&"intact")


func _physics_process(_delta: float) -> void:
	if _hero == null:
		_safe_spot = Player.hero_position
	elif glass_state == GlassState.BROKEN:
		_drop_hero()


func is_broken() -> bool:
	return glass_state == GlassState.BROKEN


func _crack() -> void:
	glass_state = GlassState.CRACKING
	glass_animation.play(&"cracking")
	crack_timer.start()


func _drop_hero() -> void:
	if _hero == null or _hero.airborne:
		return
	var hero := _hero
	_hero = null
	hero.fall_to(_outside(_safe_spot, hero.hero_radius() + 2.0), damage)


## `spot`, pushed out of the panel (plus `margin`) along the shortest way if it's on it.
func _outside(spot: Vector2, margin: float) -> Vector2:
	var rect := shape.shape as RectangleShape2D
	if rect == null:
		return spot
	var local := shape.to_local(spot)
	var half := rect.size * 0.5 + Vector2.ONE * margin / maxf(shape.global_scale.x, 0.01)
	if absf(local.x) >= half.x or absf(local.y) >= half.y:
		return spot
	if half.x - absf(local.x) < half.y - absf(local.y):
		local.x = (1.0 if local.x >= 0.0 else -1.0) * half.x
	else:
		local.y = (1.0 if local.y >= 0.0 else -1.0) * half.y
	return shape.to_global(local)


func _on_body_entered(body: Node2D) -> void:
	var hero := body as Player
	if hero == null:
		return
	_hero = hero
	if glass_state == GlassState.INTACT:
		_crack()
	elif glass_state == GlassState.BROKEN:
		_drop_hero()


func _on_body_exited(body: Node2D) -> void:
	if body == _hero:
		_hero = null


func _on_crack_timer_timeout() -> void:
	glass_state = GlassState.BROKEN
	glass_animation.play(&"broken")
	regrow_timer.start()
	_drop_hero()


func _on_regrow_timer_timeout() -> void:
	glass_state = GlassState.INTACT
	glass_animation.play(&"intact")
	if _hero != null:
		_crack()
