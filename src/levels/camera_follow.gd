class_name CameraFollow
extends Camera2D
## Follows the hero vertically inside the room's CameraBounds rect. Rooms are one screen wide,
## so the camera stays centered horizontally. The hero sits at tuning.hero_anchor of the screen height.

## The node to follow (the Player).
@export var target: Node2D
## The room's CameraBounds rect (a ReferenceRect).
@export var bounds: Control
## Shared controls tuning (hero_anchor is an M1 A/B switch).
@export var tuning: ControlsTuning
## Vertical lead, in seconds of the target's velocity.
@export_range(0.0, 1.0, 0.01, "suffix:s") var lead_time := 0.15
## Screen shake (hits, explosions). Strength requests arrive through EventBus.
@export var shake_enabled := true
@export_range(0.0, 16.0, 0.5, "suffix:px") var max_shake := 5.0
## How fast the shake fades, per second.
@export_range(0.1, 10.0, 0.1) var shake_decay := 2.5

var _trauma := 0.0


func _ready() -> void:
	EventBus.screen_shake_requested.connect(_on_screen_shake_requested)
	_place()
	reset_smoothing.call_deferred()


func _physics_process(delta: float) -> void:
	_place()
	_trauma = maxf(_trauma - shake_decay * delta, 0.0)
	var amount := _trauma * _trauma * max_shake if shake_enabled else 0.0
	offset = Vector2(randf_range(-amount, amount), randf_range(-amount, amount))


func _on_screen_shake_requested(strength: float) -> void:
	_trauma = clampf(_trauma + strength, 0.0, 1.0)


func _place() -> void:
	if target == null or bounds == null:
		return
	var view := get_viewport_rect().size / zoom
	var rect := bounds.get_global_rect()
	var body := target as CharacterBody2D
	var lead := body.velocity.y * lead_time if body != null else 0.0
	var y := target.global_position.y + lead + (0.5 - tuning.hero_anchor) * view.y
	var top := rect.position.y + view.y * 0.5
	var bottom := rect.end.y - view.y * 0.5
	y = rect.get_center().y if top > bottom else clampf(y, top, bottom)
	global_position = Vector2(rect.get_center().x, y)
