extends Node
## The M1 controls smoke test (started by tools/smoke_test_controls.gd).
## Loads controls_test.tscn, plays scripted one-finger gestures, and checks how the hero reacts.

const LEVEL_PATH := "res://src/levels/test/controls_test.tscn"

var _failures := 0
var _level: Node
var _player: Player
var _touch: TouchController
var _enemy_pool: BulletPool
var _finger := Vector2.ZERO


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_level = (load(LEVEL_PATH) as PackedScene).instantiate()
	get_tree().root.add_child(_level)
	_player = _level.get_node(^"Player") as Player
	_touch = _level.get_node(^"TouchController") as TouchController
	_enemy_pool = _level.get_node(^"BulletPools/EnemyBulletsSmall") as BulletPool
	await _physics_frames(5)
	var zone := (_level.get_node(^"HUD") as Hud).joystick_zone.get_global_rect()
	_finger = Vector2(zone.get_center().x, zone.position.y + zone.size.y * 0.7)
	_check(zone.has_point(_finger), "a finger in the lower screen lands in the JoystickZone (%s)" % zone)

	await _test_hold_moves_then_lift_stands()
	await _test_swipe_rolls()
	await _test_lift_near_cover_takes_cover()
	await _test_cover_protects_from_its_side_only()
	await _test_auto_fire_hits_dummy()
	await _test_double_tap_fires_emp()
	await _test_roll_dodges_bullets()

	print("Smoke test finished: %d failure(s)" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _test_hold_moves_then_lift_stands() -> void:
	await _place_player(Vector2(176, 800))
	var start_y := _player.global_position.y
	_press(_finger)
	await _wait(0.05)
	_drag(_finger + Vector2(0, -40))
	await _wait(0.5)
	_check(_player.state_machine.is_in(&"Run"), "holding the finger runs")
	_check(start_y - _player.global_position.y > 20.0, "dragging up moves the hero up (%.0f px)" % (start_y - _player.global_position.y))
	_release(_finger + Vector2(0, -40))
	await _physics_frames(2)
	_check(_player.state_machine.is_in(&"Stand"), "lifting with no cover nearby stands still")


func _test_swipe_rolls() -> void:
	await _place_player(Vector2(176, 800))
	var start_y := _player.global_position.y
	_press(_finger)
	await _wait(0.02)
	_drag(_finger + Vector2(0, -20))
	await _wait(0.02)
	_drag(_finger + Vector2(0, -45))
	await _wait(0.02)
	_release(_finger + Vector2(0, -60))
	await _physics_frames(1)
	_check(_player.state_machine.is_in(&"Roll"), "a quick swipe-and-release rolls")
	await _wait(0.7)
	_check(not _player.state_machine.is_in(&"Roll"), "the roll ends on its own")
	_check(start_y - _player.global_position.y > 40.0, "the roll travels in the swipe direction (%.0f px)" % (start_y - _player.global_position.y))


func _test_lift_near_cover_takes_cover() -> void:
	await _place_player(Vector2(104, 752))
	_press(_finger)
	await _wait(0.3)
	_release(_finger)
	await _wait(0.5)
	var crate := _level.get_node(^"Room/Cover/CrateA") as Cover
	_check(_player.state_machine.is_in(&"InCover"), "lifting within 2 tiles of cover slides into cover")
	_check(_player.cover == crate, "the hero took cover at the nearest crate")
	_check(absf(_player.global_position.y - 736.0) < 2.0, "the hero hugs the crate's near face (y = %.1f)" % _player.global_position.y)


func _test_cover_protects_from_its_side_only() -> void:
	var crate := _player.cover
	if crate == null:
		_check(false, "cover protection test needs the hero in cover")
		return
	var hp_before := _player.health.hp
	var cover_hp_before := crate.hp
	_enemy_pool.spawn(_player.global_position + Vector2(0, -3), _player.cover_normal)
	await _physics_frames(4)
	_check(_player.health.hp == hp_before, "a bullet from the cover's side doesn't hurt the hero")
	_check(crate.hp < cover_hp_before, "the cover takes that bullet's damage (%d -> %d)" % [cover_hp_before, crate.hp])
	_enemy_pool.spawn(_player.global_position + Vector2(0, 3), -_player.cover_normal)
	await _physics_frames(4)
	_check(_player.health.hp == hp_before - 1, "a bullet from the open side hurts the hero")


func _test_auto_fire_hits_dummy() -> void:
	await _place_player(Vector2(120, 660))
	var dummy := _level.get_node(^"Room/Dummies/DummyA") as Dummy
	var hp_before := dummy.health.hp
	_press(_finger)
	await _wait(1.0)
	_release(_finger)
	await _physics_frames(2)
	_check(dummy.health.hp < hp_before, "holding the finger auto-fires at the nearest visible dummy (%d -> %d hp)" % [hp_before, dummy.health.hp])


func _test_double_tap_fires_emp() -> void:
	await _place_player(Vector2(176, 800))
	for i: int in 5:
		_enemy_pool.spawn(Vector2(60 + i * 40, 300), Vector2.RIGHT)
	var charges_before := _player.emp_charges
	_press(_finger)
	await _wait(0.05)
	_release(_finger)
	await _wait(0.1)
	_press(_finger)
	await _wait(0.05)
	_release(_finger)
	await _physics_frames(2)
	_check(_player.emp_charges == charges_before - 1, "a double-tap fires the EMP (charges %d -> %d)" % [charges_before, _player.emp_charges])
	_check(_enemy_pool.active_count == 0, "the EMP clears enemy bullets")


func _test_roll_dodges_bullets() -> void:
	await _wait(1.1)  # let post-hit invulnerability from earlier tests run out
	await _place_player(Vector2(176, 800))
	var hp_before := _player.health.hp
	_press(_finger)
	await _wait(0.02)
	_drag(_finger + Vector2(0, -40))
	await _wait(0.02)
	_release(_finger + Vector2(0, -60))
	await _physics_frames(2)
	_enemy_pool.spawn(_player.global_position, Vector2.DOWN)
	await _physics_frames(4)
	_check(_player.health.hp == hp_before, "bullets pass through the hero during the roll's i-frames")


# --- helpers ---

func _place_player(at: Vector2) -> void:
	_player.global_position = at
	_player.state_machine.transition_to(&"Stand")
	await _physics_frames(3)


func _press(at: Vector2) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = at
	event.pressed = true
	_touch._unhandled_input(event)


func _drag(at: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = 0
	event.position = at
	_touch._unhandled_input(event)


func _release(at: Vector2) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = at
	event.pressed = false
	_touch._unhandled_input(event)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _physics_frames(count: int) -> void:
	for _i: int in count:
		await get_tree().physics_frame


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS  ", label)
	else:
		_failures += 1
		print("FAIL  ", label)
