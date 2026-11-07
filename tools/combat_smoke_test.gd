extends Node
## The M2 combat smoke test (started by tools/smoke_test_combat.gd).
## Loads combat_test.tscn, drives waves, enemies, pickups and weapons directly, and checks the results.

const LEVEL_PATH := "res://src/levels/test/combat_test.tscn"
const SWARMER := "res://src/enemies/swarmer/swarmer.tscn"
const CHARGER := "res://src/enemies/charger/charger.tscn"
const GRUNT := "res://src/enemies/grunt/grunt.tscn"
const TURRET := "res://src/enemies/turret/turret.tscn"
const RIVET := "res://src/weapons/bullets/player_rivet.tscn"

var _failures := 0
var _level: Node
var _player: Player
var _spawner: WaveSpawner
var _next_wave_timer: Timer
var _drop_layer: Node2D
var _enemies: Node2D
var _enemy_pool: BulletPool
var _prompt := ""


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_level = (load(LEVEL_PATH) as PackedScene).instantiate()
	get_tree().root.add_child(_level)
	_player = _level.get_node(^"Player") as Player
	_spawner = _level.get_node(^"WaveSpawner") as WaveSpawner
	_next_wave_timer = _spawner.get_node(^"NextWaveTimer") as Timer
	_drop_layer = _level.get_node(^"DropLayer") as Node2D
	_enemies = _level.get_node(^"Enemies") as Node2D
	_enemy_pool = _level.get_node(^"BulletPools/EnemyBulletsSmall") as BulletPool
	_next_wave_timer.stop()  # the test starts waves itself
	EventBus.interact_prompt_changed.connect(_on_prompt_changed)
	await _physics_frames(5)

	await _test_wave_spawns()
	await _test_wave_clear_drops_and_magnet()
	await _test_weapon_pickup_and_swap()
	await _test_found_gun_fires()
	_test_empty_gun_switches_to_pistol()
	await _test_barrel_explodes()
	await _test_contact_damage()
	await _test_charger_smashes_cover()
	await _test_emp_stuns()
	await _test_turret_fires()
	_test_rivet_pierces()

	print("Combat smoke test finished: %d failure(s)" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _test_wave_spawns() -> void:
	_spawner.start_next_wave()
	var wave := _spawner.alive.duplicate()
	_check(wave.size() > 0, "wave 1 spawns enemies at the SpawnPoints (%d)" % wave.size())
	var too_close := false
	var any_targetable := false
	for node: Node in wave:
		var enemy := node as Enemy
		too_close = too_close or enemy.global_position.distance_to(_player.global_position) < 48.0
		any_targetable = any_targetable or enemy.is_targetable()
	_check(not too_close, "no enemy spawns within 3 tiles of the hero")
	await _physics_frames(2)
	_check(not _any(wave, func(e: Enemy) -> bool: return e.is_targetable()), "enemies are untargetable while spawning in")
	await _wait(1.0)
	_check(_all(wave, func(e: Enemy) -> bool: return e.is_targetable()), "enemies are targetable after the 0.8 s spawn-in")


func _test_wave_clear_drops_and_magnet() -> void:
	var killed := _spawner.alive.size()
	for node: Node in _spawner.alive.duplicate():
		(node as Enemy).take_damage(999)
	await _physics_frames(3)
	var ram := _pickups_of(Pickup.Kind.RAM)
	var crypto := _pickups_of(Pickup.Kind.CRYPTO)
	_check(ram.size() >= killed, "every robot drops RAM (%d chips for %d kills)" % [ram.size(), killed])
	_check(crypto.size() >= 1, "clearing the wave drops the Crypto reward")
	_check(not _next_wave_timer.is_stopped(), "the next wave is queued after a clear")
	_next_wave_timer.stop()
	var ram_before := GameState.ram_mb
	var crypto_before := GameState.crypto
	for pickup: Pickup in ram + crypto:
		if is_instance_valid(pickup):
			await _place_player(pickup.global_position)
	await _physics_frames(5)
	_check(GameState.ram_mb > ram_before, "the magnet collects RAM (%d -> %d MB)" % [ram_before, GameState.ram_mb])
	_check(GameState.crypto > crypto_before, "the magnet collects Crypto (%d -> %d)" % [crypto_before, GameState.crypto])


func _test_weapon_pickup_and_swap() -> void:
	var scatter_pickup := _level.get_node(^"Room/WeaponPickups/Scattergun") as WeaponPickup
	await _place_player(scatter_pickup.global_position + Vector2(0, 8))
	_check(_prompt == "Take Scattergun", "standing on a floor gun shows its prompt ('%s')" % _prompt)
	EventBus.interact_requested.emit()
	await _physics_frames(2)
	_check(_player.secondary != null and _player.secondary.display_name == "weapon.scattergun", "tapping the prompt fills slot 2")
	_check(_player.weapon == _player.secondary, "the new gun goes straight into the hero's hands")
	EventBus.weapon_swap_requested.emit()
	_check(_player.weapon == _player.primary, "tapping the weapon card swaps to the pistol")
	EventBus.weapon_swap_requested.emit()
	_check(_player.weapon == _player.secondary, "and back to the found gun")
	var smg_pickup := _level.get_node(^"Room/WeaponPickups/BuzzSmg") as WeaponPickup
	await _place_player(smg_pickup.global_position + Vector2(0, 8))
	EventBus.interact_requested.emit()
	await _physics_frames(2)
	_check(_player.secondary != null and _player.secondary.display_name == "weapon.buzz_smg", "a second floor gun replaces the found gun")
	var dropped := false
	for node: Node in _drop_layer.get_children():
		var pickup := node as WeaponPickup
		dropped = dropped or (pickup != null and pickup.weapon() != null and pickup.weapon().display_name == "weapon.scattergun")
	_check(dropped, "the replaced gun is left on the floor")


func _test_found_gun_fires() -> void:
	var gun := _player.weapon
	var grunt := _spawn(GRUNT, _player.global_position + Vector2(0, -70))
	await _wait(0.9)
	var magazine_before := gun.magazine
	_player.state_machine.transition_to(&"Run")
	await _wait(0.6)
	_player.state_machine.transition_to(&"Stand")
	_check(gun.magazine < magazine_before, "the found gun auto-fires at a robot in range (%d -> %d rounds)" % [magazine_before, gun.magazine])
	_check(not is_instance_valid(grunt) or grunt.health.hp < grunt.health.max_hp, "and its bullets hit")
	if is_instance_valid(grunt):
		grunt.take_damage(999)
	await _physics_frames(2)


func _test_empty_gun_switches_to_pistol() -> void:
	_player.secondary.magazine = 0
	_player.secondary.reserve = 0
	_player.try_fire()
	_check(_player.weapon == _player.primary, "an empty found gun switches back to the pistol")
	EventBus.weapon_swap_requested.emit()
	_check(_player.weapon == _player.primary, "an empty gun can't be swapped to")


func _test_barrel_explodes() -> void:
	var barrel := _level.get_node(^"Room/Cover/BarrelA") as Cover
	_player.health.reset()
	await _place_player(barrel.global_position + Vector2(24, 0))
	var hp_before := _player.health.hp
	barrel.take_damage(10)
	await _wait(0.3)
	_check(not barrel.is_intact(), "a shot-up barrel breaks")
	_check(_player.health.hp == hp_before - 2, "its explosion costs the hero a heart (%d -> %d)" % [hp_before, _player.health.hp])


func _test_contact_damage() -> void:
	_player.health.reset()
	await _place_player(Vector2(176, 620))
	var swarmer := _spawn(SWARMER, _player.global_position)
	var hp_before := _player.health.hp
	await _wait(0.5)
	_check(_player.health.hp == hp_before, "a swarmer is harmless while spawning in")
	for _i: int in 20:  # up to 2 s after the spawn-in
		if _player.health.hp < hp_before:
			break
		await _wait(0.1)
	_check(_player.health.hp < hp_before, "touching a swarmer hurts")
	swarmer.take_damage(999)
	await _physics_frames(2)


func _test_charger_smashes_cover() -> void:
	_player.health.reset()
	await _place_player(Vector2(250, 660))
	var crate := _level.get_node(^"Room/Cover/CrateA") as Cover
	var charger := _spawn(CHARGER, crate.global_position + Vector2(0, 60))
	await _wait(0.9)
	charger.locked_direction = Vector2.UP
	charger.state_machine.transition_to(&"Charge")
	await _wait(0.5)
	_check(not crate.is_intact(), "a charging Charger smashes light cover")
	_check(charger.state_machine.is_in(&"Stunned"), "and is stunned by the impact")
	charger.take_damage(999)
	await _physics_frames(2)


func _test_emp_stuns() -> void:
	var grunt := _spawn(GRUNT, _player.global_position + Vector2(40, -30))
	await _wait(0.9)
	_player.emp_charges = 2
	_player.fire_emp()
	await _physics_frames(2)
	_check(grunt.state_machine.is_in(&"Stunned"), "the EMP stuns robots inside its circle")
	grunt.take_damage(999)
	await _physics_frames(2)


func _test_turret_fires() -> void:
	_enemy_pool.clear_active()
	await _physics_frames(2)
	var turret := _spawn(TURRET, Vector2(176, 300))
	var fired := false
	for _i: int in 80:
		await _wait(0.05)
		if _enemy_pool.active_count > 0:
			fired = true
			break
	_check(fired, "a turret spawns in, telegraphs and fires its pattern")
	turret.take_damage(999)


func _test_rivet_pierces() -> void:
	var pool := BulletPool.find_for(get_tree(), load(RIVET) as PackedScene)
	var rivet := pool.spawn(Vector2(-3000, -3000), Vector2.RIGHT)
	var first := RefCounted.new()
	var second := RefCounted.new()
	_check(rivet.try_hit(first) and rivet.active, "a rivet survives its first hit")
	_check(not rivet.try_hit(first), "it can't hit the same target twice")
	_check(rivet.try_hit(second) and not rivet.active, "it stops after its second target")


# --- helpers ---

func _spawn(path: String, at: Vector2) -> Enemy:
	var enemy := (load(path) as PackedScene).instantiate() as Enemy
	enemy.position = _enemies.to_local(at)
	_enemies.add_child(enemy)
	return enemy


func _pickups_of(kind: Pickup.Kind) -> Array[Pickup]:
	var found: Array[Pickup] = []
	for node: Node in _drop_layer.get_children():
		var pickup := node as Pickup
		if pickup != null and pickup.kind == kind and not pickup.is_queued_for_deletion():
			found.append(pickup)
	return found


func _any(nodes: Array, test: Callable) -> bool:
	for node: Variant in nodes:
		if is_instance_valid(node) and bool(test.call(node)):
			return true
	return false


func _all(nodes: Array, test: Callable) -> bool:
	for node: Variant in nodes:
		if is_instance_valid(node) and not bool(test.call(node)):
			return false
	return true


func _place_player(at: Vector2) -> void:
	_player.global_position = at
	_player.state_machine.transition_to(&"Stand")
	await _physics_frames(4)


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


func _on_prompt_changed(text: String) -> void:
	_prompt = text
