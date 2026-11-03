extends Node
## The Level 3 (The Foundry) smoke test (started by tools/smoke_test_l3.gd).
## Plays level 3 of the campaign without a save slot: conveyor belts and molten metal, the Grenadier and the
## Shield-bot, FORGEMOTHER, the new armory guns, the Servo Arms and Filter Lungs implants, Lena's Message and the
## Level 3 lab talk.

const LEVEL_PATH := "res://src/levels/level.tscn"
const LAB_PATH := "res://src/hub/lab.tscn"
const GRUNT := "res://src/enemies/grunt/grunt.tscn"
const GRENADIER := "res://src/enemies/grenadier/grenadier.tscn"
const SHIELDBOT := "res://src/enemies/shieldbot/shieldbot.tscn"
const CRATE := "res://src/cover/crate_light.tscn"
const LANE := "res://src/levels/hazards/molten_lane.tscn"
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
	RunState.level_number = 3
	_level = (load(LEVEL_PATH) as PackedScene).instantiate()
	_director = _level.get_node(^"LevelDirector") as LevelDirector
	_director.return_to_lab = false
	_director.fixed_seed = 31
	get_tree().root.add_child(_level)
	_player = _level.get_node(^"Player") as Player
	_spawner = _level.get_node(^"WaveSpawner") as WaveSpawner
	_player.health.max_hp = 99
	_player.health.reset()
	await _wait(0.5)

	_check(_director.config.level_number == 3 and _director.config.district_name == "The Foundry"
		and _director.current.type == Room.RoomType.START, "Level 3 of the campaign is The Foundry")
	await _test_conveyors()
	await _test_molten()
	await _test_grenadier()
	await _test_shieldbot()
	await _test_guns()
	await _test_arms()
	await _test_lungs()
	_test_memories()
	await _test_forgemother()
	_level.queue_free()
	await _wait(0.2)
	await _test_lab_talks()

	print("Level 3 smoke test finished: %d failure(s)" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _test_conveyors() -> void:
	var room := _director.current_room()
	var belt := room.get_node(^"Hazards/Conveyor1") as Conveyor
	_player.global_position = belt.global_position
	await _physics_frames(2)
	var start := _player.global_position
	await _wait(0.5)
	var moved := _player.global_position - start
	_check(moved.x > 12.0 and absf(moved.y) < 3.0, "a conveyor belt carries the hero along it (%.0f px in 0.5 s)" % moved.x)
	_reset_hero()
	var robot := await _spawn(GRUNT, belt.global_position + Vector2(-30, 0))
	var robot_start := robot.global_position
	await _wait(0.5)
	_check(robot.global_position.x > robot_start.x + 12.0, "and walking robots too")
	belt.set_speed_scale(-1.0)
	robot_start = robot.global_position
	await _wait(0.5)
	_check(robot.global_position.x < robot_start.x - 12.0, "a reversed belt carries them the other way")
	belt.set_speed_scale(1.0)
	_kill(robot)
	await _physics_frames(2)


func _test_molten() -> void:
	var origin := _reset_hero()
	var robot := await _spawn(GRUNT, origin + Vector2(20, 0))
	_player.health.invuln_timer.stop()
	var hp := _player.health.hp
	var lane := _add_lane(origin)
	await _physics_frames(3)
	_check(_player.health.hp == hp - 1, "molten metal burns the hero on contact")
	await _wait(2.2)
	_check(_player.health.hp < hp - 1, "and keeps burning while he stands in it")
	_check(robot.health.hp == robot.health.max_hp, "robots ignore it")
	lane.queue_free()
	_kill(robot)
	await _physics_frames(2)

	_reset_hero()
	hp = _player.health.hp
	lane = _add_lane(origin + Vector2(0, -20))
	_player.state_machine.transition_to(&"Roll", {"direction": Vector2.UP})
	await _wait(0.7)
	_check(_player.health.hp == hp and _player.global_position.y < origin.y - 40.0, "rolling crosses a molten lane safely")
	lane.queue_free()
	await _physics_frames(2)


func _test_grenadier() -> void:
	var origin := _reset_hero()
	var grenadier := await _spawn(GRENADIER, origin + Vector2(0, -150))
	var thrown: int = grenadier.state_machine.get_node(^"Lob").call(&"lob")
	var grenade: Grenade = null
	for node: Node in _drop_layer().get_children():
		if node is Grenade:
			grenade = node as Grenade
	_check(thrown == 1 and grenade != null and grenade.landing_circle.global_position.distance_to(origin) < 1.0,
		"a Grenadier lobs a grenade at the hero's spot, marked by a landing circle")
	if grenade == null:
		return
	_player.health.invuln_timer.stop()
	var hp := _player.health.hp
	await _wait(0.5)
	_check(is_instance_valid(grenade) and grenade.global_position.y > origin.y - 120.0 and grenade.global_position.y < origin.y - 30.0
		and grenade.sprite.position.y < -20.0, "the grenade flies in an arc")
	await _wait(0.8)
	_check(not is_instance_valid(grenade) and _player.health.hp == hp - 2, "and explodes on the circle (1 heart)")
	_kill(grenadier)
	await _physics_frames(2)


func _test_shieldbot() -> void:
	var origin := _reset_hero()
	var bot := await _spawn(SHIELDBOT, origin + Vector2(0, -80))
	var pivot := bot.get_node(^"ShieldPivot") as Node2D
	var shape := bot.get_node(^"ShieldPivot/Shield/Shape") as CollisionShape2D
	pivot.rotation = (origin - bot.global_position).angle()
	await _physics_frames(2)
	var hp := bot.health.hp
	var front := _pool("player_bullet").spawn(origin + Vector2(0, -30), Vector2.UP)
	await _physics_frames(12)
	_check(not front.active and bot.health.hp == hp, "a Shield-bot's front shield stops the hero's bullets")
	var back := _pool("player_bullet").spawn(bot.global_position + Vector2(0, -30), Vector2.DOWN)
	await _physics_frames(12)
	_check(not back.active and bot.health.hp < hp, "shots from behind get through")
	bot.state_machine.transition_to(&"Guard")
	await _wait(1.0)
	_check(not shape.disabled, "the shield stays up while it advances")
	await _wait(1.65)
	_check(shape.disabled, "and drops when it attacks")
	_kill(bot)
	await _physics_frames(2)


func _test_guns() -> void:
	var origin := _reset_hero()
	var frosty := await _spawn(GRUNT, origin + Vector2(0, -40))
	frosty.health.max_hp = 9999
	frosty.health.hp = 9999
	for _i: int in 6:
		_pool("player_cryo").spawn(origin + Vector2(0, -20), Vector2.UP)
		await _physics_frames(2)
	await _physics_frames(10)
	_check(is_equal_approx(frosty.chill, 0.48), "Cryo Sprayer hits chill a robot (%.2f)" % frosty.chill)
	for _i: int in 7:
		_pool("player_cryo").spawn(origin + Vector2(0, -20), Vector2.UP)
		await _physics_frames(2)
	await _physics_frames(10)
	_check(frosty.chill < 0.01 and frosty.state_machine.is_in(&"Stunned"), "full chill freezes it")
	await _wait(1.7)
	_check(not frosty.state_machine.is_in(&"Stunned"), "for 1.5 s")
	_kill(frosty)
	await _physics_frames(2)

	var far := origin + Vector2(0, -200)
	var rail := _equip(&"rail_spike")
	var shots: Array[int] = [0]
	rail.shot_fired.connect(func() -> void: shots[0] += 1)
	var early := rail.try_fire(far)
	for _i: int in 60:  # 1 s of held fire
		await get_tree().physics_frame
		rail.try_fire(far)
	var charging := shots[0]
	var progress := rail.charge_progress()
	for _i: int in 20:
		await get_tree().physics_frame
		rail.try_fire(far)
	_check(not early and charging == 0 and progress > 0.7 and progress < 1.0 and shots[0] == 1,
		"the Rail Spike charges for 1.2 s before it fires (%.2f charged after 1 s)" % progress)
	var crate := (load(CRATE) as PackedScene).instantiate() as Cover
	crate.position = _director.current_room().to_local(origin + Vector2(0, -40))
	_director.current_room().add_child(crate)
	var behind := await _spawn(GRUNT, origin + Vector2(0, -80))
	behind.health.max_hp = 9999
	behind.health.hp = 9999
	_pool("player_rail").spawn(origin + Vector2(0, -10), Vector2.UP)
	await _physics_frames(8)
	_check(behind.health.hp == 9999 - 60, "its spike goes through cover and hits the robot behind for 60")
	_kill(behind)
	if is_instance_valid(crate):
		crate.queue_free()

	var minigun := _equip(&"scrap_minigun")
	var rounds: Array[int] = [0]
	minigun.shot_fired.connect(func() -> void: rounds[0] += 1)
	for _i: int in 30:
		minigun.try_fire(far)
		await get_tree().physics_frame
	var spinning := rounds[0]
	for _i: int in 30:
		minigun.try_fire(far)
		await get_tree().physics_frame
	_check(spinning == 0 and rounds[0] >= 6, "the Scrap Minigun spins up for 0.6 s, then fires 20 shots/s (%d in 0.4 s)" % rounds[0])
	_check(is_equal_approx(minigun.move_speed_scale(), 0.8), "and slows the hero to 80% while it fires")
	await _wait(0.4)
	_check(is_equal_approx(minigun.move_speed_scale(), 1.0), "full speed again once it stops")


func _test_arms() -> void:
	_reset_hero()
	var gun := _equip(&"buzz_smg")
	var reload := gun.reload_speed
	var rate := gun.current_fire_rate()
	GameState.set_implant("arms", 1)
	_check(is_equal_approx(_player.reload_bonus, 1.25) and is_equal_approx(gun.reload_speed, reload * 1.25), "Servo Arms Mk I: reloads 25% faster")
	GameState.set_implant("arms", 2)
	_check(is_equal_approx(gun.spread_scale, 0.6) and is_equal_approx(gun.current_fire_rate(), rate * 1.15),
		"Mk II: 40% less spread and 15% faster fire")
	GameState.set_implant("arms", 3)
	var other := _player.primary
	_check(_player.weapon == gun and other.visible, "Mk III: the holstered gun comes out too")
	var dummy := await _spawn(GRUNT, _player.global_position + Vector2(0, -60))
	dummy.health.max_hp = 9999
	dummy.health.hp = 9999
	var mags := [gun.magazine, other.magazine]
	_player.target_selector.current_target = dummy
	_player.try_fire()
	_check(gun.magazine < mags[0] and other.magazine < mags[1], "and both guns fire at the target")
	_kill(dummy)
	_reset_implants()
	_check(not other.visible, "without the arms, the second gun goes back in the holster")
	await _physics_frames(2)


func _test_lungs() -> void:
	var origin := _reset_hero()
	var recovery := _player.recovery_time
	var iframes := _player.iframe_ratio
	GameState.set_implant("lungs", 1)
	_check(is_equal_approx(_player.recovery_time, recovery * 0.7), "Filter Lungs Mk I: roll recovery 30% shorter")
	GameState.set_implant("lungs", 2)
	_check(is_equal_approx(_player.iframe_ratio, iframes + 0.15) and _player.hazard_immune, "Mk II: longer roll i-frames and hazard immunity")
	_player.health.invuln_timer.stop()
	var hp := _player.health.hp
	var lane := _add_lane(origin)
	await _physics_frames(3)
	_check(_player.health.hp == hp, "so molten metal no longer burns")
	lane.queue_free()
	await _physics_frames(2)

	GameState.set_implant("lungs", 3)
	_player.state_machine.transition_to(&"Roll", {"direction": Vector2.RIGHT})
	var bullet := _pool("enemy_bullet_small").spawn(_player.global_position, Vector2.RIGHT)
	await _physics_frames(3)
	_check(is_equal_approx(Engine.time_scale, 0.4) and is_equal_approx(_player.weapon.damage_scale, 1.2) and _player.health.hp == hp,
		"Mk III: a bullet dodged mid-roll triggers Second Wind (slow motion, +20% damage)")
	bullet.despawn()
	await _wait(0.6)
	_check(is_equal_approx(Engine.time_scale, 1.0), "the slow motion is brief")
	await _wait(3.0)
	_check(is_equal_approx(_player.weapon.damage_scale, 1.0), "and the damage boost wears off")
	_reset_implants()
	await _physics_frames(2)


func _test_memories() -> void:
	var memory := load("res://data/memories/l3_lenas_message.tres") as MemoryData
	_check(memory.text_for(GameState.Band.HUMAN).contains("cake") and memory.text_for(GameState.Band.MACHINE).begins_with("Audio file"),
		"Lena's Message changes with Kade's humanity band")


func _test_forgemother() -> void:
	_director.enter_room(_director.layout.boss_id, Vector2i.ZERO)
	var boss := _spawner.alive[0] as Enemy if _spawner.alive.size() == 1 else null
	_check(boss != null and boss.scene_file_path.ends_with("forgemother.tscn"), "FORGEMOTHER is Level 3's boss")
	if boss == null:
		return
	var phases := boss.get_node(^"Phases") as BossPhases
	await _wait(1.4)
	var minions := get_tree().get_nodes_in_group(&"forge_minions")
	_check(minions.size() == 2 and (minions[0] as Node).scene_file_path.ends_with("swarmer.tscn"),
		"Assembly: she builds 2 Swarmers on the factory spots (%d)" % minions.size())

	boss.take_damage(345)
	_check(phases.phase == 1, "below 60% HP: Overtime")
	await _wait(0.3)
	var belts := get_tree().get_nodes_in_group(&"conveyors")
	_check(belts.size() == 2 and belts.all(func(n: Node) -> bool: return is_equal_approx((n as Conveyor).speed_scale, -2.0)),
		"every belt in the arena speeds up and reverses")
	var spots := get_tree().get_first_node_in_group(&"crate_spots")
	var filled := spots.get_children().filter(func(n: Node) -> bool: return n.get_child_count() > 0).size()
	_check(filled == 2, "and 2 crates ride in as new cover (%d)" % filled)

	boss.take_damage(255)
	_check(phases.phase == 2, "below 30% HP: Meltdown")
	await _wait(0.2)
	var floods := _drop_layer().get_children().filter(func(n: Node) -> bool: return n is MoltenLane)
	_check(floods.size() == 3 and floods.all(func(n: Node) -> bool: return not (n as MoltenLane).hot), "3 floods appear, harmless at first (%d)" % floods.size())
	await _wait(1.0)
	_check(floods.all(func(n: Node) -> bool: return is_instance_valid(n) and (n as MoltenLane).hot), "and burn after the 1 s warning")
	var hp := boss.health.hp
	boss.take_damage(10)
	_check(boss.health.hp == hp - 20 and (boss.get_node(^"CoreGlow") as CanvasItem).visible, "her exposed core takes double damage")

	boss.take_damage(9999)
	await _wait(0.5)
	_check(get_tree().get_nodes_in_group(&"forge_minions").size() == 0, "her robots shut down with her")
	_check(not _director.is_fighting() and (_director.current_room().feature("Elevator") as Elevator).revealed, "beating FORGEMOTHER reveals the elevator")


func _test_lab_talks() -> void:
	GameState.reset_to_new()
	GameState.flags.assign(["lab_intro_done", "l1_cleared", "l1_talk_done", "l2_cleared", "l2_talk_done", "l3_cleared"])
	var lab := (load(LAB_PATH) as PackedScene).instantiate()
	get_tree().root.add_child(lab)
	await _wait(0.3)
	var ui := lab.get_node(^"LabUI") as LabUI
	_check(ui.dialogue.is_talking() and ui.dialogue.line_label.text.contains("Forgemother"), "beating FORGEMOTHER unlocks Vorn's Level 3 talk")
	_check(GameState.has_flag("l3_talk_done"), "once")
	ui.open_surgery()
	ui._select_slot("arms")
	var arms := ui.implant_name.text
	ui._select_slot("lungs")
	_check(arms.contains("Servo Arms Mk I") and ui.implant_name.text.contains("Filter Lungs Mk I"), "surgery offers Servo Arms and Filter Lungs")
	ui._on_surgery_close_pressed()
	lab.queue_free()
	GameState.reset_to_new()
	await _wait(0.2)


# --- Helpers ---

## Hero back on the room's start marker, standing still and hittable.
func _reset_hero() -> Vector2:
	var origin := _director.current_room().player_start.global_position
	_player.global_position = origin
	_player.state_machine.transition_to(&"Stand")
	_player.health.invuln_timer.stop()
	return origin


func _reset_implants() -> void:
	GameState.reset_to_new()
	EventBus.implants_changed.emit()
	_player.health.max_hp = 99
	_player.health.reset()


func _add_lane(at: Vector2) -> MoltenLane:
	var room := _director.current_room()
	var lane := (load(LANE) as PackedScene).instantiate() as MoltenLane
	lane.position = room.to_local(at)
	room.add_child(lane)
	return lane


func _drop_layer() -> Node2D:
	return _director.current_room().get_node(^"%DropLayer") as Node2D


func _spawn(path: String, at: Vector2, hold := true) -> Enemy:
	var enemy := (load(path) as PackedScene).instantiate() as Enemy
	var parent := _director.current_room().enemies
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
