extends Node
## The Level 4 (Skyline Spires) smoke test (started by tools/smoke_test_l4.gd).
## Plays level 4 of the campaign without a save slot: laser grids and cracking glass, EMP fields, the Sniper and the
## EMP-bot, WARDEN and the M7 unlock, the new armory guns, Mira's Birthday and the Level 4 lab talk.

const LEVEL_PATH := "res://src/levels/level.tscn"
const LAB_PATH := "res://src/hub/lab.tscn"
const GRUNT := "res://src/enemies/grunt/grunt.tscn"
const SNIPER := "res://src/enemies/sniper/sniper.tscn"
const EMPBOT := "res://src/enemies/empbot/empbot.tscn"
const CRATE := "res://src/cover/crate_light.tscn"
const LASER := "res://src/levels/hazards/laser_grid.tscn"
const GLASS := "res://src/levels/hazards/glass_floor.tscn"
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
	RunState.start_new_run()
	RunState.level_number = 4
	_level = (load(LEVEL_PATH) as PackedScene).instantiate()
	_director = _level.get_node(^"LevelDirector") as LevelDirector
	_director.return_to_lab = false
	_director.fixed_seed = 41
	get_tree().root.add_child(_level)
	_player = _level.get_node(^"Player") as Player
	_spawner = _level.get_node(^"WaveSpawner") as WaveSpawner
	_player.health.max_hp = 99
	_player.health.reset()
	await _wait(0.5)

	_check(_director.config.level_number == 4 and _director.config.district_name == "Skyline Spires"
		and _director.current.type == Room.RoomType.START, "Level 4 of the campaign is the Skyline Spires")
	await _test_lasers()
	await _test_glass()
	await _test_emp()
	await _test_sniper()
	await _test_guns()
	_test_memories()
	await _test_warden()
	_level.queue_free()
	await _wait(0.2)
	await _test_lab()

	print("Level 4 smoke test finished: %d failure(s)" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _test_lasers() -> void:
	var origin := _reset_hero()
	var hp := _player.health.hp
	var grid := _add_grid(origin, 0.0)
	await _physics_frames(3)
	_check(grid.phase == LaserGrid.GridPhase.OFF and _player.health.hp == hp, "a laser grid starts off: standing in it is safe")
	await _wait(2.3)
	_check(grid.phase == LaserGrid.GridPhase.WARN and _player.health.hp == hp, "then it blinks a warning, still harmless")
	await _wait(0.5)
	_check(grid.is_hot() and _player.health.hp == hp - 1, "then it burns (½ heart)")
	grid.queue_free()

	GameState.set_implant("lungs", 2)
	_reset_implant_hp()
	_reset_hero()
	hp = _player.health.hp
	grid = _add_grid(origin, 2.6)
	await _physics_frames(3)
	_check(_player.hazard_immune and _player.health.hp == hp - 1, "Filter Lungs don't stop lasers (they aren't a floor hazard)")
	grid.queue_free()
	_reset_implants()

	_reset_hero()
	hp = _player.health.hp
	grid = _add_grid(origin + Vector2(0, -24), 2.6)
	_player.state_machine.transition_to(&"Roll", {"direction": Vector2.UP})
	await _wait(0.7)
	_check(grid.is_hot() and _player.health.hp == hp and _player.global_position.y < origin.y - 40.0, "rolling passes through a live grid")
	grid.queue_free()
	await _physics_frames(2)


func _test_glass() -> void:
	var origin := _reset_hero()
	var glass := (load(GLASS) as PackedScene).instantiate() as GlassFloor
	glass.position = _room().to_local(origin + Vector2(0, -80))
	_room().add_child(glass)
	var edge := glass.global_position + Vector2(0, 23)
	_player.global_position = edge
	await _physics_frames(3)
	var hp := _player.health.hp
	_player.global_position = edge + Vector2(0, -10)
	await _physics_frames(3)
	_check(glass.glass_state == GlassFloor.GlassState.CRACKING, "stepping on glass cracks it")
	await _wait(1.0)
	_check(glass.is_broken() and _player.health.hp == hp - 2 and _player.global_position.distance_to(edge) < 3.0,
		"it gives way: the hero falls (1 heart) and is put back where he stepped on")
	_player.health.invuln_timer.stop()
	hp = _player.health.hp
	_player.global_position = glass.global_position + Vector2(0, 24)
	await _physics_frames(2)
	_player.state_machine.transition_to(&"Roll", {"direction": Vector2.UP})
	await _wait(0.7)
	_check(glass.is_broken() and _player.health.hp == hp and _player.global_position.y < glass.global_position.y - 20.0,
		"a roll carries him over the hole")
	await _wait(3.5)
	_check(glass.glass_state == GlassFloor.GlassState.INTACT, "the glass grows back after 4 s")
	glass.queue_free()
	await _physics_frames(2)


func _test_emp() -> void:
	var origin := _reset_hero()
	var crate := _add_crate(origin + Vector2(0, -24))
	await _physics_frames(3)
	_player.settle()
	await _wait(0.6)
	var bullet := _pool("enemy_bullet_small").spawn(origin + Vector2(0, -200), Vector2.DOWN)
	var protected := _player._is_protected_from(bullet)
	bullet.despawn()
	_check(_player.state_machine.is_in(&"InCover") and protected, "in cover, the hero is protected from the cover side")
	var bot := await _spawn(EMPBOT, _player.global_position + Vector2(40, 0))
	bullet = _pool("enemy_bullet_small").spawn(origin + Vector2(0, -200), Vector2.DOWN)
	protected = _player._is_protected_from(bullet)
	bullet.despawn()
	_check(EmpField.shorts_out(_player) and not protected, "an EMP-bot's field shorts out his cover")
	var pulse := bot.state_machine.get_node(^"Pulse")
	var before := _player.global_position
	var shoved: bool = pulse.call(&"pulse")
	await _physics_frames(2)
	_check(shoved and _player.global_position.distance_to(before) > 30.0 and not _player.state_machine.is_in(&"InCover"),
		"its pulse knocks the hero back, out of cover")
	_player.global_position = bot.global_position + Vector2(-30, 0)
	_player.state_machine.transition_to(&"Roll", {"direction": Vector2.LEFT})
	shoved = pulse.call(&"pulse")
	_check(not shoved, "rolling dodges the pulse")
	await _wait(0.6)
	_reset_hero()
	await _physics_frames(2)
	_kill(bot)
	crate.queue_free()
	await _physics_frames(2)


func _test_sniper() -> void:
	var origin := _reset_hero()
	var spot := origin + Vector2(0, -180)
	var sniper := await _spawn(SNIPER, spot)
	var laser := sniper.get_node(^"LaserSight") as LaserSight
	sniper.state_machine.transition_to(&"Snipe")
	await _wait(0.3)
	var end := laser.to_global(laser.points[1])
	var aim := (end - sniper.global_position).normalized().dot((origin - sniper.global_position).normalized())
	_check(laser.visible and aim > 0.99, "a Sniper's laser sight tracks the hero")
	_player.health.invuln_timer.stop()
	var hp := _player.health.hp
	await _wait(1.3)
	_check(_player.health.hp == hp - 2, "after 1 s it fires a fast shot (1 heart)")
	await _wait(0.8)
	_check(sniper.global_position.distance_to(spot) > 8.0, "then it relocates")

	var crate := _add_crate(origin + Vector2(0, -60))
	sniper.global_position = spot
	sniper.state_machine.transition_to(&"Snipe")
	await _wait(0.2)
	end = laser.to_global(laser.points[1])
	_check(end.y > origin.y - 80.0 and end.y < origin.y - 60.0, "cover blocks the laser")
	_player.health.invuln_timer.stop()
	hp = _player.health.hp
	await _wait(1.4)
	_check(_player.health.hp == hp, "and the shot")
	_kill(sniper)
	crate.queue_free()
	await _physics_frames(2)


func _test_guns() -> void:
	var origin := _reset_hero()
	var launcher := _equip(&"swarm_launcher")
	var missiles := _pool("player_missile")
	var before := missiles.active_count
	launcher.try_fire(origin + Vector2(0, -100))
	_check(missiles.active_count - before == 4, "the Swarm Launcher fires 4 micro-missiles")
	await _wait(1.8)
	var dummy := await _spawn(GRUNT, origin + Vector2(0, -70))
	dummy.health.max_hp = 9999
	dummy.health.hp = 9999
	missiles.spawn(origin + Vector2(0, -10), Vector2(1, -1))
	await _wait(1.0)
	_check(dummy.health.hp == 9999 - 6, "missiles home in on robots")

	var cutter := _equip(&"beam_cutter") as BeamWeapon
	dummy.health.hp = 9999
	for _i: int in 60:
		cutter.try_fire(dummy.global_position)
		await get_tree().physics_frame
	var dealt := 9999 - dummy.health.hp
	_check(cutter != null and cutter.beam.visible and dealt >= 24 and dealt <= 36, "the Beam Cutter's beam deals 30 damage per second (%d)" % dealt)
	var crate := _add_crate(origin + Vector2(0, -35))
	for _i: int in 72:
		cutter.try_fire(dummy.global_position)
		await get_tree().physics_frame
	_check(not crate.is_intact(), "and shreds cover")
	crate.queue_free()
	_kill(dummy)
	await _wait(0.3)

	var toasts := _pool("player_toast")
	var target := await _spawn(GRUNT, origin + Vector2(0, -50))
	target.health.max_hp = 9999
	target.health.hp = 9999
	toasts.spawn(origin + Vector2(0, -20), Vector2.UP)
	await _wait(1.3)
	var burnt := 9999 - target.health.hp
	_check(_fires() >= 1 and burnt >= 16, "Toaster Cannon toast hits for 10 and leaves burning ground (%d damage)" % burnt)
	var fires := _fires()
	toasts.spawn(origin + Vector2(0, 10), Vector2.DOWN)
	await _wait(1.1)
	_check(_fires() > fires, "a toast that misses still lands burning")
	_kill(target)

	var m7: WeaponCatalogEntry = null
	for entry: WeaponCatalogEntry in (load(CATALOG) as WeaponCatalog).entries:
		if entry.id == &"m7_line_rifle":
			m7 = entry
	_check(m7 != null and m7.rarity == WeaponCatalogEntry.Rarity.LEGENDARY and m7.unlock_hint != "" and not GameState.is_unlocked(m7.id),
		"the M7 Line Rifle is a Legendary story gun, locked on a new save")
	await _physics_frames(2)


func _test_memories() -> void:
	var memory := load("res://data/memories/l4_miras_birthday.tres") as MemoryData
	_check(memory.text_for(GameState.Band.HUMAN).contains("seven candles") and memory.text_for(GameState.Band.MACHINE).begins_with("Hologram file"),
		"Mira's Birthday changes with Kade's humanity band")


func _test_warden() -> void:
	_director.enter_room(_director.layout.boss_id, Vector2i.ZERO)
	var boss := _spawner.alive[0] as Enemy if _spawner.alive.size() == 1 else null
	_check(boss != null and boss.scene_file_path.ends_with("warden.tscn"), "WARDEN is Level 4's boss")
	if boss == null:
		return
	_player.health.max_hp = 99
	_player.health.reset()
	var phases := boss.get_node(^"Phases") as BossPhases
	var perch := (_room().feature("BossSpot") as Node2D).global_position
	await _wait(1.4)
	var drones := get_tree().get_nodes_in_group(&"warden_drones")
	_check(drones.size() == 2 and (drones[0] as Node).scene_file_path.ends_with("drone.tscn"), "Overwatch: WARDEN calls 2 Drones to flank (%d)" % drones.size())
	var laser := boss.get_node(^"LaserSight") as LaserSight
	var aimed := false
	for _i: int in 20:
		await _wait(0.1)
		aimed = aimed or laser.visible
	_check(aimed and boss.global_position.distance_to(perch) < 4.0, "and snipes from his perch with a laser sight")

	boss.take_damage(405)
	_check(phases.phase == 1, "below 60% HP: Suppression")
	await _wait(0.2)
	var zones := _drop_layer().get_children().filter(func(n: Node) -> bool: return n is EmpField)
	_check(zones.size() == 3 and zones.all(func(n: Node) -> bool: return not (n as EmpField).active), "3 EMP fields warn on and around the hero (%d)" % zones.size())
	await _wait(0.6)
	_check(zones.all(func(n: Node) -> bool: return is_instance_valid(n) and (n as EmpField).active), "then short out cover")
	var small := _pool("enemy_bullet_small")
	var swept := false
	for _i: int in 20:
		await _wait(0.1)
		swept = swept or small.active_count >= 4
	_check(swept, "and sweeping suppressive fire")

	var speed := boss.move_speed
	boss.take_damage(300)
	_check(phases.phase == 2, "below 30% HP: Hunt")
	await _wait(0.2)
	_check(is_equal_approx(boss.move_speed, speed * 1.8), "he drops from the perch and moves 80% faster")
	boss.take_damage(9999)
	await _wait(0.5)
	_check(get_tree().get_nodes_in_group(&"warden_drones").size() == 0, "his drones go down with him")
	_check(not _director.is_fighting() and (_room().feature("Elevator") as Elevator).revealed, "beating WARDEN reveals the elevator")
	_check(GameState.is_unlocked(&"m7_line_rifle"), "and the first WARDEN kill unlocks the M7 Line Rifle")


func _test_lab() -> void:
	GameState.reset_to_new()
	GameState.flags.assign(["lab_intro_done", "l1_cleared", "l1_talk_done", "l2_cleared", "l2_talk_done", "l3_cleared",
		"l3_talk_done", "l4_cleared"])
	var lab := (load(LAB_PATH) as PackedScene).instantiate()
	get_tree().root.add_child(lab)
	await _wait(0.3)
	var ui := lab.get_node(^"LabUI") as LabUI
	_check(ui.dialogue.is_talking() and ui.dialogue.line_label.text.contains("Warden"), "beating WARDEN unlocks Vorn's Level 4 talk")
	_check(GameState.has_flag("l4_talk_done"), "once")
	GameState.add_crypto(9999)
	ui.open_armory()
	var row: ArmoryRow = null
	for child: Node in ui.armory_list.get_children():
		if child is ArmoryRow and (child as ArmoryRow).entry.id == &"m7_line_rifle":
			row = child as ArmoryRow
	_check(row != null and row.buy_button.disabled and row.buy_button.text == "Beat WARDEN" and not ui.unlock(row.entry),
		"Patch can't sell the M7: the armory says to beat WARDEN")
	if row != null:
		GameState.unlock_weapon(row.entry.id)
		row.refresh()
		_check(row.buy_button.text == "Owned", "once WARDEN falls it shows as owned")
	ui._on_armory_close_pressed()
	lab.queue_free()
	GameState.reset_to_new()
	await _wait(0.2)


# --- Helpers ---

func _room() -> Room:
	return _director.current_room()


## Hero back on the room's start marker, standing still and hittable.
func _reset_hero() -> Vector2:
	var origin := _room().player_start.global_position
	_player.global_position = origin
	_player.state_machine.transition_to(&"Stand")
	_player.health.invuln_timer.stop()
	return origin


func _reset_implant_hp() -> void:
	_player.health.max_hp = 99
	_player.health.reset()


func _reset_implants() -> void:
	GameState.reset_to_new()
	EventBus.implants_changed.emit()
	_reset_implant_hp()


func _add_grid(at: Vector2, offset: float) -> LaserGrid:
	var grid := (load(LASER) as PackedScene).instantiate() as LaserGrid
	grid.position = _room().to_local(at)
	grid.start_offset = offset
	_room().add_child(grid)
	return grid


func _add_crate(at: Vector2) -> Cover:
	var crate := (load(CRATE) as PackedScene).instantiate() as Cover
	crate.position = _room().to_local(at)
	_room().add_child(crate)
	return crate


func _fires() -> int:
	return _drop_layer().get_children().filter(func(n: Node) -> bool: return n is BurningGround).size()


func _drop_layer() -> Node2D:
	return _room().get_node(^"%DropLayer") as Node2D


func _spawn(path: String, at: Vector2, hold := true) -> Enemy:
	var enemy := (load(path) as PackedScene).instantiate() as Enemy
	var parent := _room().enemies
	enemy.position = parent.to_local(at)
	parent.add_child(enemy)
	await _wait(0.9)
	if hold and is_instance_valid(enemy):
		enemy.state_machine.transition_to(&"Stunned", {"duration": 30.0})
		enemy.global_position = at
	return enemy


func _equip(id: StringName) -> Weapon:
	var catalog := load(CATALOG) as WeaponCatalog
	var pickup := _player.weapon_pickup_scene.instantiate() as WeaponPickup
	pickup.weapon_scene = catalog.scene_for(id)
	_drop_layer().add_child(pickup)
	_player.take_weapon(pickup)
	return _player.secondary


func _pool(bullet_file: String) -> BulletPool:
	for node: Node in get_tree().get_nodes_in_group(&"bullet_pools"):
		var pool := node as BulletPool
		if pool.bullet_scene.resource_path.ends_with(bullet_file + ".tscn"):
			return pool
	return null


func _kill(enemy: Variant) -> void:
	if is_instance_valid(enemy) and enemy is Enemy and (enemy as Enemy).health.is_alive():
		var target := enemy as Enemy
		target.shield_hits = 0
		target.spawning = false
		target.take_damage(9999)


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
