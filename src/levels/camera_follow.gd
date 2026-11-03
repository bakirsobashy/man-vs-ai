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


func _ready() -> void:
	_place()
	reset_smoothing.call_deferred()


func _physics_process(_delta: float) -> void:
	_place()


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
