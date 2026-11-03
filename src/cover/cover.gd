class_name Cover
extends StaticBody2D
## Destructible cover (docs/GDD.md §4.6). Shape, sprite frames and animations are authored in its scene.
## Blocks every bullet that hits it; while the hero crouches behind it, it also absorbs bullets
## arriving from its side (see Player._is_protected_from).

enum CoverMaterial { LIGHT, MEDIUM, HEAVY, EXPLOSIVE }

## Hit points: Light 40 · Medium 120 · Heavy 300.
@export_range(1, 9999) var max_hp := 40
## Material, for sounds and effects.
@export var cover_material := CoverMaterial.LIGHT
## The sprite shows the cracked frame below this share of HP.
@export_range(0.0, 1.0, 0.05) var cracked_below := 0.6
## Test rooms only: rebuild when the RegenTimer runs out.
@export var regenerates := false
## False for things that block bullets but are no place to hide (explosive barrels).
@export var provides_cover := true
## Copied into the level's drop layer when this breaks (an explosion for barrels).
@export var break_scene: PackedScene

@onready var shape_node: CollisionShape2D = %Shape
@onready var sprite: Sprite2D = %Sprite
@onready var animation: AnimationPlayer = %Animation
@onready var regen_timer: Timer = %RegenTimer

var hp := 0


func _ready() -> void:
	hp = max_hp
	_update_frame()


func is_intact() -> bool:
	return hp > 0


func take_damage(amount: int) -> void:
	if hp <= 0 or amount <= 0:
		return
	hp = maxi(hp - amount, 0)
	_update_frame()
	if hp == 0:
		_break()
		return
	animation.stop()
	animation.play(&"hit")


## A charging enemy hit this: light and medium cover breaks outright, heavy cover takes heavy_damage.
func smash(heavy_damage: int) -> void:
	take_damage(heavy_damage if cover_material == CoverMaterial.HEAVY else hp)


## Candidate crouch spots: on each face of the rectangle, the point closest to `from`, pushed out by `clearance`.
func spots_for(from: Vector2, clearance: float) -> Array[CoverSpot]:
	var spots: Array[CoverSpot] = []
	var rect_shape := shape_node.shape as RectangleShape2D
	if rect_shape == null:
		return spots
	var xform := shape_node.global_transform
	var local_from := xform.affine_inverse() * from
	var half := rect_shape.size * 0.5
	var corners: Array[Vector2] = [Vector2(-half.x, -half.y), Vector2(half.x, -half.y), half, Vector2(-half.x, half.y)]
	var normals: Array[Vector2] = [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
	for i: int in corners.size():
		var on_face := Geometry2D.get_closest_point_to_segment(local_from, corners[i], corners[(i + 1) % corners.size()])
		var normal := xform.basis_xform(normals[i]).normalized()
		spots.append(CoverSpot.create(self, xform * on_face + normal * clearance, normal))
	return spots


func _break() -> void:
	shape_node.set_deferred(&"disabled", true)
	animation.play(&"break")
	EventBus.cover_destroyed.emit(self)
	if break_scene != null:
		var effect := break_scene.instantiate() as Node2D
		var layer := get_tree().get_first_node_in_group(&"drop_layer")
		effect.position = global_position
		(layer if layer != null else get_parent()).add_child.call_deferred(effect)
	if regenerates:
		regen_timer.start()


func _update_frame() -> void:
	if hp <= 0:
		sprite.frame = 2
	elif float(hp) / max_hp < cracked_below:
		sprite.frame = 1
	else:
		sprite.frame = 0


func _on_regen_timer_timeout() -> void:
	hp = max_hp
	shape_node.set_deferred(&"disabled", false)
	animation.play(&"RESET")
	_update_frame()
