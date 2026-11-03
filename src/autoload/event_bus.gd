extends Node
## Global signals for scenes that don't know about each other (autoload "EventBus").
## Code may connect to these; signals inside one scene are connected in the editor (docs/technical.md §0).

@warning_ignore("unused_signal")
signal player_health_changed(hp: int, max_hp: int, armor: int)
@warning_ignore("unused_signal")
signal player_ammo_changed(magazine: int, magazine_size: int, reserve: int, reloading: bool)
@warning_ignore("unused_signal")
signal player_emp_changed(charges: int)
@warning_ignore("unused_signal")
signal player_state_changed(state_name: StringName)
@warning_ignore("unused_signal")
signal player_died
@warning_ignore("unused_signal")
signal enemy_killed(enemy: Node2D)
@warning_ignore("unused_signal")
signal cover_destroyed(cover: Node2D)
@warning_ignore("unused_signal")
signal gesture_classified(kind: StringName, details: String)
