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
signal cover_restored(cover: Node2D)
@warning_ignore("unused_signal")
signal gesture_classified(kind: StringName, details: String)
@warning_ignore("unused_signal")
signal currency_changed(crypto: int, ram_mb: int)
## An implant was installed or upgraded (GameState.implants changed).
@warning_ignore("unused_signal")
signal implants_changed
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
## A new level layout (LevelLayout) was generated.
@warning_ignore("unused_signal")
signal level_generated(layout: RefCounted)
@warning_ignore("unused_signal")
signal room_entered(room_id: int)
@warning_ignore("unused_signal")
signal room_cleared(room_id: int)
## The hero walked into an open door (grid direction of the next room).
@warning_ignore("unused_signal")
signal door_entered(direction: Vector2i)
@warning_ignore("unused_signal")
signal challenge_requested
@warning_ignore("unused_signal")
signal ambush_requested
## A Rare-or-better chest at `at` (a hacked terminal's prize); the LevelDirector rolls it and places it.
@warning_ignore("unused_signal")
signal reward_chest_requested(at: Vector2)
@warning_ignore("unused_signal")
signal level_exit_requested
## The run ended in death: the HUD shows its summary panel (title, stats).
@warning_ignore("unused_signal")
signal run_summary_requested(title: String, summary: String)
## The summary's "Back to the lab" button.
@warning_ignore("unused_signal")
signal summary_closed
## A lab station's prompt was tapped (surgery, armory, elevator).
@warning_ignore("unused_signal")
signal station_used(action: StringName)
@warning_ignore("unused_signal")
signal boss_health_changed(hp: int, max_hp: int)
## GLITCH's Static Storm: a short screen glitch (skipped with reduced flashing).
@warning_ignore("unused_signal")
signal screen_glitch_requested
@warning_ignore("unused_signal")
signal memory_opened(title: String, text: String)
## A repair station's prompt was tapped (the HUD opens its shop panel).
@warning_ignore("unused_signal")
signal shop_opened(station: Node)
@warning_ignore("unused_signal")
signal toast_requested(text: String)
@warning_ignore("unused_signal")
signal banner_requested(text: String)

# --- Monetization (M6): ads and purchases report back here ---
## The consent flow finished (Monetization.gather_consent): ads may be requested only when this says so.
@warning_ignore("unused_signal")
signal consent_resolved(can_request_ads: bool)
## A rewarded ad closed. `granted` is true only when the viewer earned the reward.
@warning_ignore("unused_signal")
signal rewarded_ad_finished(placement: StringName, granted: bool)
## A purchase flow ended (success: the product is now owned).
@warning_ignore("unused_signal")
signal purchase_finished(product_id: StringName, success: bool)
## Owned products were re-read from the store (Restore purchases, or the store connecting).
@warning_ignore("unused_signal")
signal purchases_restored
## The hero died and Second Chance can be offered (the HUD shows its panel; the game is paused).
@warning_ignore("unused_signal")
signal second_chance_offered
## The player answered the Second Chance panel.
@warning_ignore("unused_signal")
signal second_chance_answered(accepted: bool)
