extends EnemyState
## GLITCH (docs/content.md §4): keeps `count` decoys alive, copying decoy scenes onto free TeleportSpots (hand-placed
## markers in the arena, group "teleport_spots"). Decoys join the "glitch_decoys" group; the boss clears them on death.

@export var decoy_scene: PackedScene
@export_range(0, 8) var count := 2
## Static Storm: also asks the HUD for a screen glitch.
@export var screen_glitch := false
@export var next_state := &"Approach"


func enter(_msg: Dictionary) -> void:
	enemy.velocity = Vector2.ZERO
	summon()
	if screen_glitch:
		EventBus.screen_glitch_requested.emit()
	machine.transition_to.call_deferred(next_state)


## Adds decoys until `count` are alive. Returns how many were added.
func summon() -> int:
	var missing := count - get_tree().get_nodes_in_group(&"glitch_decoys").size()
	if missing <= 0 or decoy_scene == null:
		return 0
	var spots := TeleportSpots.free_spots(get_tree(), enemy.global_position)
	spots.shuffle()
	var added := 0
	for spot: Vector2 in spots.slice(0, missing):
		var decoy := decoy_scene.instantiate() as Node2D
		decoy.position = enemy.get_parent().to_local(spot) if enemy.get_parent() is Node2D else spot
		enemy.get_parent().add_child(decoy)
		added += 1
	return added
