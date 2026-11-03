extends EnemyState
## Keeps between min_range and max_range of the hero (strafing inside the band), then attacks after a
## random delay. With an empty attack_state it just keeps closing in (swarmers).

## Back away when closer than this.
@export_range(0.0, 400.0, 1.0, "suffix:px") var min_range := 64.0
## Move in when farther than this.
@export_range(0.0, 400.0, 1.0, "suffix:px") var max_range := 112.0
## Sideways speed inside the band, as a share of the move speed.
@export_range(0.0, 1.0, 0.05) var strafe_ratio := 0.6
## State to switch to when attacking. Empty: never attacks.
@export var attack_state := &"Telegraph"
## Random delay before an attack.
@export_range(0.0, 10.0, 0.1, "suffix:s") var attack_delay_min := 1.2
@export_range(0.0, 10.0, 0.1, "suffix:s") var attack_delay_max := 2.0
## Only attack with a clear line of sight to the hero.
@export var needs_line_of_sight := true

var _wait := 0.0
var _strafe := 1.0


func enter(_msg: Dictionary) -> void:
	_wait = randf_range(attack_delay_min, attack_delay_max)
	_strafe = 1.0 if randf() < 0.5 else -1.0


func physics_update(delta: float) -> void:
	var offset := enemy.to_player()
	var distance := offset.length()
	var direction := Vector2.ZERO
	if distance > 0.001:
		var toward := offset / distance
		if distance > max_range:
			direction = toward
		elif distance < min_range:
			direction = -toward
		else:
			direction = toward.orthogonal() * _strafe * strafe_ratio
	enemy.velocity = direction * enemy.move_speed
	enemy.move_and_slide()
	if enemy.get_slide_collision_count() > 0:
		_strafe = -_strafe
	if attack_state == &"":
		return
	_wait -= delta
	if _wait <= 0.0 and distance <= max_range * 1.5 and (not needs_line_of_sight or enemy.can_see_player()):
		machine.transition_to(attack_state)
