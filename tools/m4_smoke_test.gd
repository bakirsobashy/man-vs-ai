extends Node
## The M4 gameplay smoke test (started by tools/smoke_test_m4.gd).
## Loads level.tscn (no save slot, so nothing touches the disk) and checks the implants, the armory guns and the
## chest pool, and SCRAPJAW's phases; then loads lab.tscn and checks surgery and the armory.

const LEVEL_PATH := "res://src/levels/level.tscn"
const LAB_PATH := "res://src/hub/lab.tscn"
const GRUNT := "res://src/enemies/grunt/grunt.tscn"
const CATALOG := "res://data/weapons/weapon_catalog.tres"

var _failures := 0
var _level: Node
var _director: LevelDirector
var _player: Player
var _spawner: WaveSpawner


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	GameState.reset_to_new()
	_level = (load(LEVEL_PATH) as PackedScene).instantiate()
	_director = _level.get_node(^"LevelDirector") as LevelDirector
	_director.return_to_lab = false
	_director.fixed_seed = 11
	get_tree().root.add_child(_level)
	_player = _level.get_node(^"Player") as Player
	_spawner = _level.get_node(^"WaveSpawner") as WaveSpawner
	await _wait(0.5)

	await _test_implants()
	await _test_guns()
	_test_chest_pool()
	await _test_scrapjaw()
	_level.queue_free()
	await _wait(0.2)
	await _test_lab()

	print("M4 smoke test finished: %d failure(s)" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


# --- Implants ---

func _test_implants() -> void:
	var base_hp := _player.health.max_hp
	var base_speed := _player.move_speed
	var base_roll := _player.roll_distance
	GameState.set_implant("heart", 1)
	_check(_player.health.max_hp == base_hp + 2, "Fusion Heart Mk I adds a heart (%d -> %d half-hearts)" % [base_hp, _player.health.max_hp])
	GameState.set_implant("heart", 2)
	_player.health.armor = 0
	_player.begin_level()
	_check(_player.health.armor >= 1, "Mk II starts each level with armor (%d)" % _player.health.armor)
	GameState.set_implant("heart", 3)
	_check(_player.health.max_hp == base_hp + 4, "Mk III adds another heart (%d)" % _player.health.max_hp)
	_player.health.hp = _player.health.max_hp - 2
	RunState.rooms_since_heal = 0
	for i: int in 3:
		EventBus.room_cleared.emit(-1 - i)
	_check(_player.health.hp == _player.health.max_hp - 1, "Mk III heals 1/2 heart every 3 cleared rooms")

	GameState.set_implant("legs", 1)
	_check(is_equal_approx(_player.move_speed, base_speed * 1.12), "Hydraulic Legs Mk I: +12%% move speed (%.1f)" % _player.move_speed)
	GameState.set_implant("legs", 2)
	_check(is_equal_approx(_player.roll_distance, base_roll * 1.3), "Mk II: +30%% roll distance (%.1f)" % _player.roll_distance)
	GameState.set_implant("legs", 3)
	var visual := _player.get_node(^"Visual") as HeroVisual
	_check((visual.get_node(^"%Implants/HeartMk3") as CanvasItem).visible and (visual.get_node(^"%Implants/LegsMk3") as CanvasItem).visible
		and not (visual.get_node(^"%Implants/HeartMk1") as CanvasItem).visible, "the paper doll shows only the installed tiers")
	var grunt := await _spawn_ready(_player.global_position + Vector2(16, 0))
	var pool := _level.get_node(^"BulletPools/EnemyBulletsSmall") as BulletPool
	var bullet := pool.spawn(_player.global_position + Vector2(-12, 0), Vector2.RIGHT)
	var hp := grunt.health.hp
	await _physics_frames(2)
	_player.roll_finished()
	_check(grunt.health.hp == hp - 10, "Mk III: a roll ends in a 10-damage shockwave (%d -> %d)" % [hp, grunt.health.hp])
	_check(not bullet.active, "and the shockwave clears nearby bullets")
	grunt.take_damage(999)

	GameState.reset_to_new()
	EventBus.implants_changed.emit()
	_check(_player.health.max_hp == base_hp and is_equal_approx(_player.move_speed, base_speed), "without implants the hero is back to base stats")
	_player.health.reset()
	await _physics_frames(2)


# --- Guns ---

func _test_guns() -> void:
	var room := _director.current_room()
	var origin := room.player_start.global_position
	_player.global_position = origin + Vector2(0, 120)

	var revolver := _equip("bolt_revolver")
	var target := await _spawn_ready(origin + Vector2(0, -40))
	var hp := target.health.hp
	var fired := revolver.try_fire(target.global_position)
	await _wait(0.8)  # player bullets fly 320 px/s
	_check(fired and is_instance_valid(target) and target.health.hp == hp - 14,
		"the Bolt Revolver hits for 14 (fired: %s, %d -> %d)" % [fired, hp, target.health.hp if is_instance_valid(target) else -1])
	_kill(target)

	var ricochet := _pool_for("player_ricochet")
	var bouncing := ricochet.spawn(Vector2(40, origin.y), Vector2.LEFT)
	await _physics_frames(10)
	_check(bouncing.active and bouncing.direction.x > 0.5, "a Ricochet Carbine bullet bounces off the wall")

	var aim := await _spawn_ready(origin + Vector2(90, -60))
	var homing := _pool_for("player_homing").spawn(origin + Vector2(0, 40), Vector2.UP)
	await _wait(0.25)
	_check(not homing.active or homing.direction.x > 0.2, "a Magnet Coil bullet curves toward the nearest robot")
	_kill(aim)

	var stun_target := await _spawn_ready(origin + Vector2(0, -30))
	_pool_for("player_volt_pellet").spawn(origin + Vector2(0, -6), Vector2.UP)
	await _physics_frames(6)
	_check(stun_target.state_machine.is_in(&"Stunned"), "Volt Shotgun pellets stun robots")
	_kill(stun_target)

	var line: Array[Enemy] = []
	for i: int in 3:
		line.append(await _spawn_ready(origin + Vector2(-60 + 60 * i, -40)))
	var hps: Array[int] = []
	for enemy: Enemy in line:
		hps.append(enemy.health.hp)
	_pool_for("player_longshot").spawn(origin + Vector2(-110, -40), Vector2.RIGHT)
	await _wait(0.4)
	var all_hit := true
	for i: int in line.size():
		all_hit = all_hit and (not is_instance_valid(line[i]) or line[i].health.hp < hps[i])
	_check(all_hit, "a Longshot bullet pierces every robot in line")
	for enemy: Variant in line:
		_kill(enemy)

	var firecracker := _equip("firecracker")
	var popper := await _spawn_ready(origin + Vector2(0, -40))
	var magazine := firecracker.magazine
	firecracker.try_fire(popper.global_position)
	await _wait(0.9)
	_check(firecracker.magazine == magazine - 3, "the Firecracker fires 3-round bursts (%d -> %d)" % [magazine, firecracker.magazine])
	var blasts := 0
	for node: Node in room.get_node(^"%DropLayer").get_children():
		blasts += 1 if node.name.begins_with("MiniBlast") else 0
	_check(blasts > 0 or not is_instance_valid(popper) or popper.health.hp < popper.health.max_hp - 12,
		"its bullets pop in tiny blasts")
	_kill(popper)
	await _physics_frames(3)


func _test_chest_pool() -> void:
	var catalog := load(CATALOG) as WeaponCatalog
	GameState.reset_to_new()
	var starter_only := true
	for _i: int in 20:
		var scene := catalog.pick(WeaponCatalogEntry.Rarity.RARE)
		starter_only = starter_only and scene != null and GameState.is_unlocked(catalog.id_for_scene(scene.resource_path))
	_check(starter_only, "with nothing unlocked, a Rare chest falls back to the free Commons")
	GameState.unlock_weapon(&"longshot")
	_check(catalog.pick(WeaponCatalogEntry.Rarity.RARE) == catalog.scene_for(&"longshot"), "an unlocked Rare gun shows up in Rare chests")
	GameState.reset_to_new()


# --- SCRAPJAW ---

func _test_scrapjaw() -> void:
	_director.enter_room(_director.layout.boss_id, Vector2i.ZERO)
	var room := _director.current_room()
	var boss := _spawner.alive[0] as Enemy if _spawner.alive.size() == 1 else null
	_check(boss != null and boss.scene_file_path.ends_with("scrapjaw.tscn"), "SCRAPJAW is Level 1's boss")
	if boss == null:
		return
	var phases := boss.get_node(^"Phases") as BossPhases
	await _wait(1.0)

	var crate: Cover = null
	for node: Node in room.get_node(^"Cover").get_children():
		var cover := node as Cover
		if cover != null and cover.position == Vector2(176, 560):
			crate = cover
	boss.global_position = Vector2(176, 250)
	_player.global_position = Vector2(176, 640)
	_player.health.max_hp = 99
	_player.health.reset()
	boss.state_machine.transition_to(&"WreckChargeTell")
	await _wait(2.4)
	_check(crate != null and not crate.is_intact(), "a Wreck charge plows through cover in its path")

	boss.global_position = Vector2(176, 800)
	_player.global_position = Vector2(176, 860)
	boss.state_machine.transition_to(&"WreckChargeTell")
	var stunned := false
	for _i: int in 30:
		await _wait(0.1)
		stunned = stunned or boss.state_machine.is_in(&"Stunned")
	_check(stunned, "a charge into a wall stuns SCRAPJAW")

	boss.take_damage(260)
	_check(phases.phase == 1 and boss.state_machine.is_in(&"MagnetTell"), "below 60% HP it switches to the Magnet phase")
	_player.global_position = Vector2(176, 600)
	boss.global_position = Vector2(176, 250)
	await _wait(1.2)
	var scrap := _level.get_node(^"BulletPools/EnemyScrap") as BulletPool
	_check(boss.state_machine.is_in(&"MagnetPull") and scrap.active_count > 0, "the magnet streams scrap from the ScrapSpots (%d)" % scrap.active_count)
	var before := _player.global_position.distance_to(boss.global_position)
	await _wait(0.8)
	_check(_player.global_position.distance_to(boss.global_position) < before - 5.0, "and pulls the hero in")
	await _wait(1.4)
	var piles := 0
	for spot: Node in room.get_node(^"Cover/ScrapSpots").get_children():
		piles += spot.get_child_count()
	_check(piles > 0, "the scrap drops in piles that become cover (%d)" % piles)

	boss.take_damage(220)
	await _physics_frames(2)
	_check(phases.phase == 2 and boss.state_machine.is_in(&"GrindSpin"), "below 25% HP it starts to Grind")
	await _wait(0.6)
	var small := _level.get_node(^"BulletPools/EnemyBulletsSmall") as BulletPool
	_check(small.active_count > 0, "spinning with a bullet spiral (%d bullets)" % small.active_count)
	boss.take_damage(9999)
	await _wait(0.5)
	_check(not _director.is_fighting() and (room.feature("Elevator") as Elevator).revealed, "beating SCRAPJAW reveals the elevator")


# --- Lab ---

func _test_lab() -> void:
	GameState.reset_to_new()
	GameState.flags.append("lab_intro_done")
	GameState.add_ram(2048)
	GameState.add_crypto(200)
	var lab := (load(LAB_PATH) as PackedScene).instantiate()
	get_tree().root.add_child(lab)
	await _wait(0.3)
	var ui := lab.get_node(^"LabUI") as LabUI
	var hero := lab.get_node(^"Player") as Player

	ui.open_surgery()
	_check(ui.surgery_panel.visible and get_tree().paused, "the surgery chair opens Vorn's panel and pauses")
	_check(ui.install_button.require_hold, "the first install in a slot needs a hold to confirm")
	var ram := GameState.ram_mb
	var hearts := hero.health.max_hp
	_check(ui.install("heart") and GameState.implant_tier("heart") == 1 and GameState.ram_mb == ram - 256,
		"installing Fusion Heart Mk I costs 256 MB")
	_check(hero.health.max_hp == hearts + 2, "the hero gets the extra heart right away")
	_check(ui.comic_layer.get_child_count() == 1, "the first install in a slot shows its comic panel")
	ui._select_slot("heart")
	_check(not ui.install_button.require_hold, "upgrades don't need the hold")
	_check(ui.install("heart") and ui.install("heart") and not ui.install("heart"), "Heart goes to Mk III and no further")
	ui._select_slot("eyes")
	_check(ui.install_button.disabled and not ui.install("eyes"), "slots without implants yet can't be installed")
	GameState.ram_mb = 100
	_check(not ui.install("legs") and GameState.implant_tier("legs") == 0, "surgery needs enough RAM")
	ui._on_surgery_close_pressed()
	_check(not get_tree().paused, "closing surgery resumes the lab")

	ui.open_armory()
	var catalog := load(CATALOG) as WeaponCatalog
	_check(ui.armory_list.get_child_count() == catalog.entries.size(), "the armory lists every gun (%d)" % ui.armory_list.get_child_count())
	var longshot: WeaponCatalogEntry = null
	for entry: WeaponCatalogEntry in catalog.entries:
		if entry.id == &"longshot":
			longshot = entry
	var crypto := GameState.crypto
	_check(ui.unlock(longshot) and GameState.is_unlocked(&"longshot") and GameState.crypto == crypto - 150, "unlocking the Longshot costs 150 Crypto")
	_check(not ui.unlock(longshot), "an owned gun can't be bought twice")
	ui._on_armory_close_pressed()
	lab.queue_free()
	GameState.reset_to_new()
	await _wait(0.2)


# --- Helpers ---

func _equip(id: StringName) -> Weapon:
	var catalog := load(CATALOG) as WeaponCatalog
	var pickup := _player.weapon_pickup_scene.instantiate() as WeaponPickup
	pickup.weapon_scene = catalog.scene_for(id)
	_director.current_room().get_node(^"%DropLayer").add_child(pickup)
	_player.take_weapon(pickup)
	return _player.secondary


func _pool_for(bullet_file: String) -> BulletPool:
	for node: Node in get_tree().get_nodes_in_group(&"bullet_pools"):
		var pool := node as BulletPool
		if pool.bullet_scene.resource_path.ends_with(bullet_file + ".tscn"):
			return pool
	return null


func _spawn_ready(at: Vector2) -> Enemy:
	var enemy := (load(GRUNT) as PackedScene).instantiate() as Enemy
	var parent := _director.current_room().enemies
	enemy.position = parent.to_local(at)
	parent.add_child(enemy)
	await _wait(0.9)
	enemy.state_machine.transition_to(&"Stunned", {"duration": 30.0})
	enemy.global_position = at
	return enemy


func _kill(enemy: Variant) -> void:
	if is_instance_valid(enemy) and (enemy as Enemy).health.is_alive():
		(enemy as Enemy).take_damage(999)


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
