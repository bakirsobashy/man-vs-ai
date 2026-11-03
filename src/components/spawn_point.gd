@icon("res://assets/art/placeholder/icon_spawn.svg")
class_name SpawnPoint
extends Marker2D
## Where enemies may appear. Placed by hand in room scenes; the WaveSpawner picks enemy types for it
## from the threat budget. Tick which kinds of enemy and which waves may use this point.

@export_flags("Ground", "Flyer", "Stationary") var kinds := 1
@export_flags("Wave 1", "Wave 2", "Wave 3+") var waves := 7


func accepts(kind: int, wave: int) -> bool:
	var wave_bit := 1 << (clampi(wave, 1, 3) - 1)
	return (kinds & kind) != 0 and (waves & wave_bit) != 0
