extends Node
## The Level 5 (Syndicate Core) smoke test (started by tools/smoke_test_l5.gd).
## Plays level 5 of the campaign without a save slot: coolant floods and firewalls, the Null Knight, the Peacekeeper
## and the Black Box, ZERO's three phases and The Night.

const LEVEL_PATH := "res://src/levels/level.tscn"
const GRUNT := "res://src/enemies/grunt/grunt.tscn"
const SHIELDBOT := "res://src/enemies/shieldbot/shieldbot.tscn"
const KNIGHT := "res://src/enemies/null_knight/null_knight.tscn"
const CRATE := "res://src/cover/crate_light.tscn"
const COOLANT := "res://src/levels/hazards/coolant_flood.tscn"
const FIREWALL := "res://src/levels/hazards/firewall_laser.tscn"
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
	RunState.level_number = 5
	_level = (load(LEVEL_PATH) as PackedScene).instantiate()
	_director = _level.get_node(^"LevelDirector") as LevelDirector
	_director.return_to_lab = false
	_director.fixed_seed = 51
	get_tree().root.add_child(_level)
	_player = _level.get_node(^"Player") as Player
	_spawner = _level.get_node(^"WaveSpawner") as WaveSpawner
	_player.health.max_hp = 99
	_player.health.reset()
	await _wait(0.5)

	_check(_director.config.level_number == 5 and _director.config.district_name == "district.syndicate_core"
		and _director.current.type == Room.RoomType.START and _director.campaign.is_last(5), "Level 5, the Syndicate Core, is the last level")
	await _test_coolant()
	await _test_firewalls()
	await _test_null_knight()
	await _test_guns()
	_test_memory()
	await _test_zero()
	_level.queue_free()
	await _wait(0.2)

	print("Level 5 smoke test finished: %d failure(s)" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _test_coolant() -> void:
	var origin := _reset_hero()
	var flood := _add_coolant(origin, 3.8)
	await _physics_frames(3)
	_check(flood.is_wet() and is_equal_approx(_player.slow_scale(), 0.5), "wading through flooded coolant halves the hero's speed")
	_player.global_position = origin + Vector2(0, 80)
	await _physics_frames(3)
	_check(is_equal_approx(_player.slow_scale(), 1.0), "full speed once he's out")
	flood.queue_free()
	await _physics_frames(2)
	_reset_hero()
	flood = _add_coolant(origin, 0.0)
	await _physics_frames(3)
	_check(not flood.is_wet() and is_equal_approx(_player.slow_scale(), 1.0), "dry coolant channels don't slow him")
	flood.queue_free()
	flood = _add_coolant(origin, 3.7)
	await _wait(0.3)
	_check(flood.is_wet() and is_equal_approx(_player.slow_scale(), 0.5), "a channel that floods under him slows him")
	flood.queue_free()
	await _physics_frames(3)
	_check(is_equal_approx(_player.slow_scale(), 1.0), "and a removed flood lets go")


func _test_firewalls() -> void:
	var origin := _reset_hero()
	var hp := _player.health.hp
	var wall := _add_firewall(origin + Vector2(0, -40), 80.0, 2.0, true)
	await _wait(0.8)
	_check(_player.health.hp == hp - 1, "a firewall sweeps across the room and burns the hero (½ heart)")
	wall.queue_free()

	_reset_hero()
	hp = _player.health.hp
	_player.state_machine.transition_to(&"Roll", {"direction": Vector2.UP})
	wall = _add_firewall(origin, 200.0, 6.0, true)
	await _wait(0.7)
	_check(_player.health.hp == hp, "rolling through it is safe")
	wall.queue_free()

	_reset_hero()
	hp = _player.health.hp
	wall = _add_firewall(origin, 80.0, 4.0, false)
	await _wait(0.6)
	_check(not wall.visible and _player.health.hp == hp, "an inactive firewall (ZERO's edges) is hidden and harmless")
	wall.set_active(true)
	await _wait(0.6)
	_check(wall.visible and _player.health.hp == hp - 1, "until it's switched on")
	wall.queue_free()
	await _physics_frames(2)


func _test_null_knight() -> void:
	var origin := _reset_hero()
	var knight := await _spawn(KNIGHT, origin + Vector2(0, -100))
	var sensor := knight.get_node(^"DodgeSensor") as DodgeSensor
	sensor.chance = 1.0
	knight.state_machine.transition_to(&"Approach")
	knight.global_position = origin + Vector2(0, -100)
	var hp := knight.health.hp
	_pool("player_bullet").spawn(origin + Vector2(0, -20), Vector2.UP)
	await _physics_frames(10)
	_check(knight.state_machine.is_in(&"Dodge") and knight.dodging, "a Null Knight rolls when bullets come at it")
	await _physics_frames(12)
	_check(knight.health.hp == hp, "and the bullet passes through the roll")
	await _wait(0.4)
	knight.state_machine.transition_to(&"Stunned", {"duration": 30.0})
	knight.global_position = origin + Vector2(0, -100)
	await _physics_frames(2)
	knight.state_machine.transition_to(&"Approach")
	_pool("player_bullet").spawn(origin + Vector2(0, -20), Vector2.UP)
	await _physics_frames(14)
	_check(knight.health.hp < hp, "but it can't roll again right away (cooldown)")

	knight.state_machine.transition_to(&"Stunned", {"duration": 30.0})
	knight.global_position = origin + Vector2(0, -100)
	var crate := _add_crate(origin + Vector2(60, -100))
	await _physics_frames(3)
	knight.state_machine.transition_to(&"SeekCover")
	await _wait(1.2)
	var side := (knight.global_position - crate.global_position).dot(crate.global_position - origin)
	_check(knight.global_position.distance_to(crate.global_position) < 40.0 and side > 0.0, "it takes cover on the far side from the hero")
	var grenade := false
	for _i: int in 40:
		await _wait(0.1)
		grenade = grenade or _drop_layer().get_children().any(func(n: Node) -> bool: return n is Grenade)
	_check(grenade, "then fires a burst and lobs a grenade")
	_kill(knight)
	crate.queue_free()
	await _wait(1.2)


func _test_guns() -> void:
	var origin := _reset_hero()
	var bot := await _spawn(SHIELDBOT, origin + Vector2(0, -80))
	var pivot := bot.get_node(^"ShieldPivot") as Node2D
	pivot.rotation = (origin - bot.global_position).angle()
	await _physics_frames(2)
	var hp := bot.health.hp
	_pool("player_peacekeeper").spawn(origin + Vector2(0, -30), Vector2.UP)
	await _physics_frames(12)
	_check(bot.health.hp == hp - 8, "Peacekeeper rounds go through a Shield-bot's plate")
	_kill(bot)
	var elite := await _spawn(GRUNT, origin + Vector2(0, -60))
	elite.make_elite(Enemy.Elite.SHIELDED)
	hp = elite.health.hp
	_pool("player_peacekeeper").spawn(origin + Vector2(0, -20), Vector2.UP)
	await _physics_frames(10)
	_check(elite.health.hp == hp - 8 and elite.shield_hits == 3, "and through a Shielded elite's bubble")
	_kill(elite)
	await _physics_frames(2)

	var orbs := _pool("player_blackbox")
	var shards := _pool("player_bullet")
	var orb := orbs.spawn(origin + Vector2(0, -10), Vector2.UP)
	var eater := orb.get_node(^"Eater") as BulletEater
	var small := _pool("enemy_bullet_small")
	hp = _player.health.hp
	for i: int in 3:
		small.spawn(origin + Vector2(-6 + 6 * i, -70), Vector2.DOWN)
	await _wait(0.4)
	_check(eater.eaten == 3 and _player.health.hp == hp, "the Black Box orb eats enemy bullets (%d)" % eater.eaten)
	var before := shards.active_count
	var popped := false
	for _i: int in 180:
		await get_tree().physics_frame
		if not orb.active:
			popped = true
			break
	_check(popped and shards.active_count - before == 7, "and bursts them back as 4 + 3 shards when it pops (%d)" % (shards.active_count - before))
	await _wait(0.8)
	var dummy := await _spawn(GRUNT, origin + Vector2(0, -60))
	dummy.health.max_hp = 9999
	dummy.health.hp = 9999
	orbs.spawn(origin + Vector2(0, -20), Vector2.UP)
	await _wait(0.8)
	_check(9999 - dummy.health.hp >= 9, "an orb that hits a robot pops on it, shards included (%d damage)" % (9999 - dummy.health.hp))
	_kill(dummy)

	var catalog := load(CATALOG) as WeaponCatalog
	var legend := catalog.entries.filter(func(e: WeaponCatalogEntry) -> bool:
		return e.id in [&"peacekeeper", &"black_box"] and e.rarity == WeaponCatalogEntry.Rarity.LEGENDARY and e.unlock_cost == 400)
	_check(legend.size() == 2 and catalog.entries.size() == 21, "Peacekeeper and Black Box are 400-Crypto Legendaries: all 21 guns exist")
	await _physics_frames(2)


func _test_memory() -> void:
	var memory := load("res://data/memories/l5_the_night.tres") as MemoryData
	_check(tr(memory.text_for(GameState.Band.HUMAN)).contains("Live with it, Sergeant.") and tr(memory.text_for(GameState.Band.MACHINE)).begins_with("Recording:"),
		"The Night (the Warden's recording) changes with Kade's humanity band")


func _test_zero() -> void:
	_director.enter_room(_director.layout.boss_id, Vector2i.ZERO)
	var boss := _spawner.alive[0] as Enemy if _spawner.alive.size() == 1 else null
	_check(boss != null and boss.scene_file_path.ends_with("zero.tscn"), "ZERO is Level 5's boss")
	if boss == null:
		return
	_player.health.max_hp = 99
	_player.health.reset()
	var phases := boss.get_node(^"Phases") as BossPhases
	var edges := get_tree().get_nodes_in_group(&"zero_edges")
	_check(edges.size() == 2 and edges.all(func(n: Node) -> bool: return not (n as FirewallLaser).active), "the arena's edge firewalls start off")
	await _wait(1.4)
	(boss.get_node(^"DodgeSensor") as DodgeSensor).chance = 1.0
	var covered := false
	var dodged := false
	var small := _pool("enemy_bullet_small")
	var burst := false
	for _i: int in 40:
		await _wait(0.1)
		covered = covered or boss.state_machine.is_in(&"DuelCover")
		burst = burst or small.active_count >= 2
		if not dodged and boss.state_machine.is_in(&"DuelApproach"):
			_pool("player_bullet").spawn(_player.global_position + (boss.global_position - _player.global_position).normalized() * 12.0,
				(boss.global_position - _player.global_position).normalized())
			await _physics_frames(20)
			dodged = boss.state_machine.is_in(&"Dodge") or boss.dodging or dodged
	_check(dodged and covered and burst, "Duel: ZERO mirrors the hero (rolls %s, cover %s, bursts %s)" % [dodged, covered, burst])

	boss.take_damage(500)
	_check(phases.phase == 1, "below 65% HP: Syndicate")
	await _wait(0.3)
	_check(get_tree().get_nodes_in_group(&"glitch_decoys").size() == 2, "Glitch's decoys")
	var aimed := false
	var minions := false
	var sniped := false
	for _i: int in 60:
		await _wait(0.1)
		aimed = aimed or (boss.get_node(^"AimPivot/AimLine") as CanvasItem).visible
		minions = minions or get_tree().get_nodes_in_group(&"zero_minions").size() >= 2
		sniped = sniped or (boss.get_node(^"LaserSight") as CanvasItem).visible
		if aimed and minions and sniped:
			break
	_check(aimed and minions and sniped, "Scrapjaw's charge, Forgemother's minions and Warden's laser (%s %s %s)" % [aimed, minions, sniped])

	boss.take_damage(490)
	_check(phases.phase == 2, "below 30% HP: Zero Hour")
	await _wait(0.4)
	_check(is_equal_approx(boss.attack_rate, 1.5) and edges.all(func(n: Node) -> bool: return (n as FirewallLaser).active),
		"ZERO overclocks and the arena edges close in")
	var storm := false
	for _i: int in 20:
		await _wait(0.1)
		storm = storm or small.active_count >= 12
	_check(storm, "bullet-hell spirals")
	boss.take_damage(9999)
	await _wait(0.5)
	_check(get_tree().get_nodes_in_group(&"glitch_decoys").size() + get_tree().get_nodes_in_group(&"zero_minions").size()
		+ get_tree().get_nodes_in_group(&"zero_edges").size() == 0, "his decoys, minions and edges go with him")
	_check(not _director.is_fighting() and GameState.has_flag("l5_cleared"), "ZERO falls")


# --- Helpers ---

func _room() -> Room:
	return _director.current_room()


func _reset_hero() -> Vector2:
	var origin := _room().player_start.global_position
	_player.global_position = origin
	_player.state_machine.transition_to(&"Stand")
	_player.health.invuln_timer.stop()
	return origin


func _add_coolant(at: Vector2, offset: float) -> CoolantFlood:
	var flood := (load(COOLANT) as PackedScene).instantiate() as CoolantFlood
	flood.position = _room().to_local(at)
	flood.start_offset = offset
	_room().add_child(flood)
	return flood


func _add_firewall(at: Vector2, travel: float, period: float, active: bool) -> FirewallLaser:
	var wall := (load(FIREWALL) as PackedScene).instantiate() as FirewallLaser
	wall.position = _room().to_local(at)
	wall.travel = travel
	wall.period = period
	wall.active = active
	_room().add_child(wall)
	return wall


func _add_crate(at: Vector2) -> Cover:
	var crate := (load(CRATE) as PackedScene).instantiate() as Cover
	crate.position = _room().to_local(at)
	_room().get_node(^"Cover").add_child(crate)
	return crate


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
		target.dodging = false
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
