extends EnemyState
## FORGEMOTHER's Assembly (docs/content.md §4): copies `count` minion scenes onto random hand-placed spots (a Node2D in
## `spot_group` with Marker2D children) next to her. Minions join `minion_group`, which the boss clears on death.

@export var minion_scene: PackedScene
@export_range(1, 8) var count := 2
@export var spot_group := &"factory_spots"
@export var minion_group := &"forge_minions"
## Never more than this many minions alive at once.
@export_range(1, 16) var max_alive := 6
@export var next_state := &"Approach"


func enter(_msg: Dictionary) -> void:
	enemy.velocity = Vector2.ZERO
	build()
	machine.transition_to.call_deferred(next_state)


## Returns how many minions were built.
func build() -> int:
	var root := get_tree().get_first_node_in_group(spot_group)
	if minion_scene == null or root == null:
		return 0
	var spots := root.get_children().filter(func(n: Node) -> bool: return n is Marker2D)
	spots.shuffle()
	var room_left := max_alive - get_tree().get_nodes_in_group(minion_group).size()
	var built := 0
	for spot: Node in spots.slice(0, mini(count, room_left)):
		var minion := minion_scene.instantiate() as Node2D
		minion.position = enemy.get_parent().to_local((spot as Marker2D).global_position)
		enemy.get_parent().add_child(minion)
		minion.add_to_group(minion_group)
		built += 1
	return built
