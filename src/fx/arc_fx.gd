class_name ArcFx
extends Node2D
## The Arc Caster's lightning between two robots (a copy in the drop layer). The Line2D and its fade animation are
## nodes in arc_fx.tscn; the animation's last key frees it.

@onready var line: Line2D = %Line


func set_points(from: Vector2, to: Vector2) -> void:
	var middle := (from + to) * 0.5 + (to - from).orthogonal().normalized() * randf_range(-6.0, 6.0)
	line.points = PackedVector2Array([from - position, middle - position, to - position])
