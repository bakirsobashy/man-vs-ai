extends EnemyState
## FORGEMOTHER's Overtime: every conveyor in the room speeds up and reverses (speed_scale), and crate copies ride in
## as new cover onto free hand-placed crate spots (group "crate_spots"; a spot with a child is taken).

@export_range(-4.0, 4.0, 0.1) var conveyor_scale := -2.0
@export var crate_scene: PackedScene
@export_range(0, 6) var crates := 2
@export var next_state := &"Approach"


func enter(_msg: Dictionary) -> void:
	enemy.velocity = Vector2.ZERO
	for node: Node in get_tree().get_nodes_in_group(&"conveyors"):
		(node as Conveyor).set_speed_scale(conveyor_scale)
	drop_crates()
	machine.transition_to.call_deferred(next_state)


func drop_crates() -> int:
	var root := get_tree().get_first_node_in_group(&"crate_spots")
	if crate_scene == null or root == null:
		return 0
	var free := root.get_children().filter(func(n: Node) -> bool: return n is Marker2D and n.get_child_count() == 0)
	free.shuffle()
	for spot: Node in free.slice(0, crates):
		var crate := crate_scene.instantiate() as Node2D
		spot.add_child(crate)
		EventBus.cover_restored.emit(crate)
	return mini(crates, free.size())
