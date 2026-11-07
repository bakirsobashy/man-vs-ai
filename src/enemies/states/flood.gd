extends EnemyState
## FORGEMOTHER's Meltdown: exposes her core (damage_taken_scale) and floods `count` random hand-placed flood spots
## (group "flood_spots") with molten_flood copies, which warn for 1 s before they burn.

@export var flood_scene: PackedScene
@export_range(1, 8) var count := 2
## Damage multiplier while the core is exposed (Meltdown: x2).
@export_range(1.0, 4.0, 0.1) var core_damage_scale := 2.0
## Shown while the core is exposed.
@export var core_glow: CanvasItem
@export var next_state := &"Approach"


func enter(_msg: Dictionary) -> void:
	enemy.velocity = Vector2.ZERO
	enemy.damage_taken_scale = core_damage_scale
	if core_glow != null:
		core_glow.visible = true
	flood()
	machine.transition_to.call_deferred(next_state)


func flood() -> int:
	var root := get_tree().get_first_node_in_group(&"flood_spots")
	var layer := get_tree().get_first_node_in_group(&"drop_layer") as Node2D
	if flood_scene == null or root == null or layer == null:
		return 0
	var spots := root.get_children().filter(func(n: Node) -> bool: return n is Marker2D)
	spots.shuffle()
	for spot: Node in spots.slice(0, count):
		var lane := flood_scene.instantiate() as Node2D
		lane.position = layer.to_local((spot as Marker2D).global_position)
		lane.rotation = (spot as Marker2D).global_rotation
		layer.add_child(lane)
	return mini(count, spots.size())
