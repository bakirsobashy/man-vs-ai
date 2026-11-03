extends Node
## Global signals for scenes that don't know about each other (autoload "EventBus").
## Code may connect to these; signals inside one scene are connected in the editor (docs/technical.md §0).

@warning_ignore("unused_signal")
signal player_health_changed(hp: int, max_hp: int, armor: int)
@warning_ignore("unused_signal")
signal player_ammo_changed(magazine: int, magazine_size: int, reserve: int, reloading: bool)
## slot is 1 (starter) or 2 (found gun); slots is how many guns the hero carries.
@warning_ignore("unused_signal")
signal player_weapon_changed(display_name: String, slot: int, slots: int)
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
@warning_ignore("unused_signal")
signal currency_changed(crypto: int, ram_mb: int)
@warning_ignore("unused_signal")
signal wave_started(wave: int, threat: float)
@warning_ignore("unused_signal")
signal wave_cleared(wave: int)
## Empty text hides the prompt bubble.
@warning_ignore("unused_signal")
signal interact_prompt_changed(text: String)
@warning_ignore("unused_signal")
signal interact_requested
@warning_ignore("unused_signal")
signal weapon_swap_requested
## strength 0..1, added to the camera's shake.
@warning_ignore("unused_signal")
signal screen_shake_requested(strength: float)
