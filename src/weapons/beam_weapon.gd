class_name BeamWeapon
extends Weapon
## The Beam Cutter: a continuous beam instead of bullets. Every "shot" (fire_rate ticks per second) casts the
## %BeamRay (a child of the Muzzle) toward the target: the first robot body it reaches takes the shot's damage,
## cover takes cover_damage (it shreds cover), and walls and enemy shields stop it. Magazine and ammo count ticks.
## %Beam (a top-level Line2D) shows the beam until %BeamTimer (connected in the scene) hides it.

## Cover damage per tick.
@export_range(0, 100) var cover_damage := 6
## Longest beam, in pixels.
@export_range(16.0, 400.0, 1.0, "suffix:px") var beam_length := 170.0

@onready var beam: Line2D = %Beam
@onready var beam_ray: RayCast2D = %BeamRay
@onready var beam_timer: Timer = %BeamTimer


func _can_emit() -> bool:
	return true


func _emit(aim: Vector2) -> void:
	var from := muzzle.global_position
	beam_ray.target_position = beam_ray.to_local(from + aim * beam_length)
	beam_ray.force_raycast_update()
	var end := from + aim * beam_length
	if beam_ray.is_colliding():
		end = beam_ray.get_collision_point()
		var hit := beam_ray.get_collider()
		if hit is Enemy:
			(hit as Enemy).take_damage(_roll_damage())
		elif hit is Cover:
			(hit as Cover).take_damage(cover_damage)
	beam.points = PackedVector2Array([from, end])
	beam.visible = true
	beam_timer.start()


func set_active(on: bool) -> void:
	super.set_active(on)
	if not on and beam != null:
		beam.visible = false


func _on_beam_timer_timeout() -> void:
	beam.visible = false
