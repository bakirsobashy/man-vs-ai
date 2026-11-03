extends EnemyState
## Hackers (docs/content.md §2): rig the cover nearest the hero to explode (a rig_charge copy on it), and give the
## nearest unshielded ally a shield. Then back to next_state.

## The charge copied onto the rigged cover (it blinks, then explodes).
@export var rig_scene: PackedScene
## Only cover this close to the hero gets rigged.
@export_range(0.0, 160.0, 1.0, "suffix:px") var rig_range := 64.0
## Hits the ally's shield absorbs.
@export_range(0, 9) var shield_hits := 3
@export var next_state := &"Approach"


func enter(_msg: Dictionary) -> void:
	enemy.velocity = Vector2.ZERO
	rig_cover()
	shield_ally()
	machine.transition_to.call_deferred(next_state)


## Rigs the intact cover nearest the hero (in range). Returns the cover, or null.
func rig_cover() -> Cover:
	if enemy.player == null or rig_scene == null:
		return null
	var best: Cover = null
	var best_distance := rig_range
	for node: Node in get_tree().get_nodes_in_group(&"cover"):
		var cover := node as Cover
		if cover == null or not cover.is_intact() or not cover.provides_cover or cover.has_node(^"RigCharge"):
			continue
		var distance := cover.global_position.distance_to(enemy.player.global_position)
		if distance < best_distance:
			best_distance = distance
			best = cover
	if best != null:
		var charge := rig_scene.instantiate() as Node2D
		charge.name = &"RigCharge"
		best.add_child(charge)
	return best


## Shields the nearest other enemy that has no shield. Returns it, or null.
func shield_ally() -> Enemy:
	var best: Enemy = null
	var best_distance := INF
	for node: Node in get_tree().get_nodes_in_group(&"enemies"):
		var ally := node as Enemy
		if ally == null or ally == enemy or ally.is_boss or ally.shield_hits > 0 or not ally.is_alive():
			continue
		var distance := ally.global_position.distance_to(enemy.global_position)
		if distance < best_distance:
			best_distance = distance
			best = ally
	if best != null:
		best.give_shield(shield_hits)
	return best
