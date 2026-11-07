extends PlayerState
## Finger lifted near cover: slide to the chosen spot, then crouch (InCover).

var _spot: CoverSpot
var _elapsed := 0.0


func enter(msg: Dictionary) -> void:
	_spot = msg.get("spot") as CoverSpot
	_elapsed = 0.0


func physics_update(delta: float) -> void:
	_elapsed += delta
	var to_spot := _spot.position - player.global_position
	var distance := to_spot.length()
	if not is_instance_valid(_spot.cover) or not _spot.cover.is_intact() or _elapsed >= player.max_slide_time:
		machine.transition_to(&"Stand")
		return
	if distance <= player.cover_arrive_distance:
		machine.transition_to(&"InCover", {"spot": _spot})
		return
	player.velocity = to_spot / distance * minf(player.slide_speed, distance / delta)
	player.move_and_slide()
	player.update_aim(Vector2.ZERO)


func on_touch_started() -> void:
	machine.transition_to(&"Run")
