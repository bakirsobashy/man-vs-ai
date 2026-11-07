class_name TeleportSpots
extends RefCounted
## Reads a boss arena's hand-placed TeleportSpots markers (a Node2D in group "teleport_spots" with Marker2D children).


## Every spot's global position.
static func all(tree: SceneTree) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var root := tree.get_first_node_in_group(&"teleport_spots")
	if root != null:
		for child: Node in root.get_children():
			if child is Marker2D:
				result.append((child as Marker2D).global_position)
	return result


## Spots not occupied by a decoy and at least 24 px from `avoid`.
static func free_spots(tree: SceneTree, avoid: Vector2) -> Array[Vector2]:
	var taken: Array[Vector2] = []
	for node: Node in tree.get_nodes_in_group(&"glitch_decoys"):
		taken.append((node as Node2D).global_position)
	return all(tree).filter(func(spot: Vector2) -> bool:
		return spot.distance_to(avoid) > 24.0 and not taken.any(func(t: Vector2) -> bool: return t.distance_to(spot) < 24.0))
