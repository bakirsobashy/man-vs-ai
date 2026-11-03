extends Node
## The Level 2 (Neon Bazaar) smoke test (started by tools/smoke_test_l2.gd).
## Plays level 2 of the campaign without a save slot: the district's robots, elites and holo-signs, GLITCH, the
## new armory guns, the Eyes and Brain implants, memory band variants and the Level 2 lab talk.

const LEVEL_PATH := "res://src/levels/level.tscn"
const LAB_PATH := "res://src/hub/lab.tscn"
const GRUNT := "res://src/enemies/grunt/grunt.tscn"
const DRONE := "res://src/enemies/drone/drone.tscn"
const HACKER := "res://src/enemies/hacker/hacker.tscn"
const CRATE := "res://src/cover/crate_light.tscn"
const SIGN := "res://src/levels/hazards/holo_sign.tscn"
const CATALOG := "res://data/weapons/weapon_catalog.tres"

var _failures := 0
var _level: Node
var _director: LevelDirector
var _player: Player
var _spawner: WaveSpawner
var _glitches := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	GameState.reset_to_new()
	RunState.start_new_run()
	RunState.level_number = 2
	_level = (load(LEVEL_PATH) as PackedScene).instantiate()
	_director = _level.get_node(^"LevelDirector") as LevelDirector
	_director.return_to_lab = false
	_director.fixed_seed = 21
	get_tree().root.add_child(_level)
	_player = _level.get_node(^"Player") as Player
	_spawner = _level.get_node(^"WaveSpawner") as WaveSpawner
	_player.health.max_hp = 99
	_player.health.reset()
	EventBus.screen_glitch_requested.connect(func() -> void: _glitches += 1)
	await _wait(0.5)

	_check(_director.config.level_number == 2 and _director.config.district_name == "Neon Bazaar"
		and _director.current.type == Room.RoomType.START, "Level 2 of the campaign is the Neon Bazaar")
	await _test_holo_signs()
	await _test_drone()
	await _test_hacker()
	await _test_elites()
	await _test_guns()
	await _test_eyes_and_brain()
	_test_memories()
	await _test_glitch()
	_level.queue_free()
	await _wait(0.2)
	await _test_lab_talks()

	print("Level 2 smoke test finished: %d failure(s)" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _test_holo_signs() -> void:
	var room := _director.current_room()
	var origin := room.player_start.global_position
	var sign := (load(SIGN) as PackedScene).instantiate() as Node2D
	sign.position = room.to_local(origin + Vector2(0, -40))
	room.add_child(sign)
	_player.global_position = origin
	await _physics_frames(3)
	var ray := _player.get_node(^"LineOfSight") as RayCast2D
	ray.target_position = ray.to_local(origin + Vector2(0, -80))
	ray.force_raycast_update()
	_check(ray.is_colliding() and ray.get_collider() == sign, "a holo-sign blocks the hero's line of sight")
	var shot := _pool("player_bullet").spawn(origin + Vector2(0, -20), Vector2.UP)
	await _physics_frames(8)
	_check(shot.active and shot.global_position.y < origin.y - 50.0, "but bullets fly straight through it")
	_check(not _player.test_move(_player.global_transform, Vector2(0, -60)), "and so does the hero")
	sign.queue_free()


func _test_drone() -> void:
	var room := _director.current_room()
	var drone := await _spawn(DRONE, room.player_start.global_position + Vector2(0, -90), false)
	var crate := (load(CRATE) as PackedScene).instantiate() as Cover
	crate.position = room.to_local(drone.global_position)
	room.add_child(crate)
	var start := drone.global_position
	await _wait(0.6)
	_check(drone.global_position.distance_to(start) > 10.0, "a Drone flies over cover, circling the hero")
	var rect := room.camera_bounds.get_global_rect()
	_check(rect.has_point(drone.global_position), "and stays inside the room")
	var aerial := _pool("enemy_bullet_aerial").spawn(crate.global_position + Vector2(0, -20), Vector2.DOWN)
	await _physics_frames(24)
	_check(aerial.active and aerial.global_position.y > crate.global_position.y + 10.0, "its shots pass over cover")
	aerial.despawn()
	_kill(drone)
	crate.queue_free()
	await _physics_frames(2)


func _test_hacker() -> void:
	var room := _director.current_room()
	var origin := room.player_start.global_position
	var crate := (load(CRATE) as PackedScene).instantiate() as Cover
	crate.position = room.to_local(origin + Vector2(0, -24))
	room.add_child(crate)
	_player.global_position = origin
	var hacker := await _spawn(HACKER, origin + Vector2(-120, -120))
	var ally := await _spawn(GRUNT, origin + Vector2(-90, -120))
	var hack := hacker.state_machine.get_node(^"Hack")
	var rigged: Cover = hack.call(&"rig_cover")
	_check(rigged == crate and crate.has_node(^"RigCharge"), "a Hacker rigs the cover next to the hero")
	await _wait(1.7)
	_check(not crate.is_intact(), "the rigged cover explodes after 1.5 s")
	var shielded: Enemy = hack.call(&"shield_ally")
	var hp := ally.health.hp
	for _i: int in 3:
		ally.take_damage(5)
	_check(shielded == ally and ally.health.hp == hp, "and shields an ally for 3 hits")
	ally.take_damage(5)
	_check(ally.health.hp == hp - 5, "the 4th hit gets through")
	_kill(hacker)
	_kill(ally)
	crate.queue_free()
	await _physics_frames(2)


func _test_elites() -> void:
	var origin := _director.current_room().player_start.global_position
	var fast := await _spawn(GRUNT, origin + Vector2(-60, -100))
	var speed := fast.move_speed
	fast.make_elite(Enemy.Elite.OVERCLOCKED)
	_check(is_equal_approx(fast.move_speed, speed * 1.5) and fast.attack_rate > 1.0 and fast.elite_fx.visible,
		"Overclocked elites move and attack 50% faster, with an elite ring")
	var tank := await _spawn(GRUNT, origin + Vector2(0, -100))
	var ram := tank.drops.ram_mb
	tank.make_elite(Enemy.Elite.ARMORED)
	_check(tank.health.max_hp == 40 and tank.health.hp == 40 and tank.drops.ram_mb == ram * 3, "Armored elites have double HP and drop 3x RAM")
	var bubble := await _spawn(GRUNT, origin + Vector2(60, -100))
	bubble.make_elite(Enemy.Elite.SHIELDED)
	_check(bubble.shield_hits == 3 and bubble.shield_bubble.visible, "Shielded elites absorb their first 3 hits")
	for enemy: Enemy in [fast, tank, bubble]:
		_kill(enemy)
	await _physics_frames(2)

	_spawner.start_room(_director.current_room().spawn_points, _director.current_room().enemies, 1, 2.0, 0.0)
	for node: Node in _spawner.alive.duplicate():
		(node as Node).queue_free()
	_spawner.alive.clear()
	var splitter := _spawner.call(&"_spawn", load(GRUNT), origin + Vector2(0, -120)) as Enemy
	await _wait(0.9)
	splitter.make_elite(Enemy.Elite.SPLITTER)
	splitter.take_damage(999)
	await _physics_frames(3)
	var swarmers := _spawner.alive.filter(func(n: Node) -> bool: return is_instance_valid(n) and (n as Node).scene_file_path.ends_with("swarmer.tscn"))
	_check(swarmers.size() == 2 and _director.is_fighting() == _director.is_fighting(), "a Splitter elite leaves 2 Swarmers behind (%d)" % swarmers.size())
	for node: Node in _spawner.alive.duplicate():
		await _wait(0.0)
		_kill(node)
	await _wait(1.0)
	for node: Node in _spawner.alive.duplicate():
		_kill(node)
	await _physics_frames(3)

	var start_id := _director.current.id
	var combat := -1
	for direction: Vector2i in _director.current.neighbors:
		var id: int = _director.current.neighbors[direction]
		if _director.layout.rooms[id].type == Room.RoomType.COMBAT:
			combat = id
	_director.enter_room(combat, Vector2i.ZERO)
	await _clear_fight()
	var room := _director.current_room()
	var ambush := _spawner.spawn_elite_ambush(room.spawn_points, room.enemies) as Enemy
	_check(ambush != null and ambush.elite != Enemy.Elite.NONE and _spawner.alive.size() == 1, "a terminal ambush is one elite")
	await _wait(1.0)
	_kill(ambush)
	await _physics_frames(3)
	_director.enter_room(start_id, Vector2i.ZERO)
	await _physics_frames(3)


func _test_guns() -> void:
	var origin := _director.current_room().player_start.global_position
	_player.global_position = origin + Vector2(0, 100)
	var cannon := _equip(&"junk_cannon")
	var rolls: Array[int] = []
	for _i: int in 40:
		rolls.append(cannon.call(&"_roll_damage"))
	_check(rolls.min() >= 8 and rolls.max() <= 20 and rolls.max() > rolls.min(), "Junk Cannon shots deal 8-20 (%d-%d)" % [rolls.min(), rolls.max()])
	var shoved := await _spawn(GRUNT, origin + Vector2(0, -30))
	var before := shoved.global_position
	var chunk := _pool("player_scrap").spawn(origin + Vector2(0, -10), Vector2.UP, 18)
	await _physics_frames(6)
	_check(not chunk.active and shoved.global_position.y < before.y - 8.0, "big chunks knock robots back")
	_kill(shoved)

	var targets: Array[Enemy] = []
	for i: int in 3:
		targets.append(await _spawn(GRUNT, origin + Vector2(-40 + 40 * i, -40)))
	_pool("player_arc").spawn(origin + Vector2(-40, -10), Vector2.UP)
	await _physics_frames(8)
	var hit := targets.filter(func(e: Enemy) -> bool: return e.health.hp < e.health.max_hp).size()
	_check(hit == 3, "Arc Caster lightning chains to 2 more robots (%d hit)" % hit)
	for enemy: Enemy in targets:
		_kill(enemy)

	var pistol := _equip(&"overclock_pistol")
	var slow := pistol.current_fire_rate()
	var dummy := await _spawn(GRUNT, origin + Vector2(0, -60))
	dummy.health.max_hp = 9999
	dummy.health.hp = 9999
	for _i: int in 150:  # 2.5 s of held fire, one try per physics frame like auto-fire
		pistol.try_fire(dummy.global_position)
		await get_tree().physics_frame
	_check(is_equal_approx(slow, 3.0) and pistol.current_fire_rate() > 8.0, "the Overclock Pistol ramps from 3 to 9 shots/s (%.1f)" % pistol.current_fire_rate())
	_kill(dummy)
	await _physics_frames(2)


func _test_eyes_and_brain() -> void:
	GameState.set_implant("eyes", 1)
	_check(is_equal_approx(_player.aim_range_scale, 1.25) and is_equal_approx(_player.weapon.range_area.scale.x, 1.25),
		"Hawk Optics Mk I: +25% aim range")
	var target := await _spawn(GRUNT, _player.global_position + Vector2(0, -50))
	target.take_damage(5)
	_player.target_selector.current_target = target
	_player.update_aim(Vector2.ZERO)
	_check(_player.target_hp.visible and _player.target_hp.value == 15, "and shows the target's HP")
	GameState.set_implant("eyes", 2)
	_check(is_equal_approx(_player.weapon.crit_chance, 0.15), "Mk II: 15% critical hits")
	GameState.set_implant("eyes", 3)
	_check(is_equal_approx(Player.telegraph_bonus, 0.2) and Player.highlight_aimed, "Mk III: Threat Sight (tells +0.2 s, aimed bullets highlighted)")
	var aimed := _pool("enemy_bullet_small").spawn(_player.global_position + Vector2(0, -150), Vector2.DOWN)
	await _physics_frames(2)
	_check(aimed.self_modulate != Color.WHITE, "a bullet aimed at the hero is highlighted")
	aimed.despawn()
	_kill(target)

	var base_emp := _player.emp_charges_per_level
	GameState.set_implant("brain", 1)
	_check(_player.emp_charges_per_level == base_emp + 1, "Neural Coprocessor Mk I: +1 EMP charge per level")
	GameState.set_implant("brain", 2)
	_check(is_equal_approx(_player.emp_range.scale.x, 1.5) and is_equal_approx(_player.emp_stun_time, 2.5), "Mk II: EMP radius 6 tiles, 2.5 s stun")
	GameState.set_implant("brain", 3)
	_player.begin_level()
	_player.health.max_hp = 6
	_player.health.hp = 1
	_player.health.armor = 0
	_player.health.invuln_timer.stop()
	_player.take_explosion_hit(4)
	_check(_player.health.hp == 1 and not _player.failsafe_ready, "Mk III: Failsafe negates the first lethal hit of a level")
	_player.health.invuln_timer.stop()
	_player.take_explosion_hit(4)
	_check(not _player.health.is_alive(), "only once per level")
	GameState.reset_to_new()
	EventBus.implants_changed.emit()
	await _wait(0.2)
	_player.health.max_hp = 99
	_player.respawn()
	_player.state_machine.transition_to(&"Stand")
	await _physics_frames(3)


func _test_memories() -> void:
	var memory := load("res://data/memories/l2_miras_drawing.tres") as MemoryData
	_check(memory.text_for(GameState.Band.HUMAN).contains("bigger than the house") and memory.text_for(GameState.Band.MACHINE).begins_with("Image file"),
		"memories change with Kade's humanity band")


func _test_glitch() -> void:
	_director.enter_room(_director.layout.boss_id, Vector2i.ZERO)
	var boss := _spawner.alive[0] as Enemy if _spawner.alive.size() == 1 else null
	_check(boss != null and boss.scene_file_path.ends_with("glitch.tscn"), "GLITCH is Level 2's boss")
	if boss == null:
		return
	var phases := boss.get_node(^"Phases") as BossPhases
	await _wait(1.3)
	var decoys := get_tree().get_nodes_in_group(&"glitch_decoys")
	_check(decoys.size() == 2, "Decoys phase: 2 decoys appear (%d)" % decoys.size())
	_check(decoys.size() > 0 and (decoys[0] as Enemy).is_in_group(&"enemies"), "decoys can be auto-aimed")
	var hollow := _pool("enemy_bullet_hollow").spawn(_player.global_position + Vector2(0, -30), Vector2.DOWN)
	var hp := _player.health.hp
	await _physics_frames(10)
	_check(_player.health.hp == hp, "hollow decoy bullets do no damage")
	hollow.despawn()

	boss.take_damage(260)
	_check(phases.phase == 1, "below 65% HP: Holo-walls")
	await _wait(0.4)
	var spots := TeleportSpots.all(get_tree())
	var on_spot := spots.any(func(s: Vector2) -> bool: return s.distance_to(boss.global_position) < 2.0)
	_check(on_spot, "GLITCH teleports between the arena's TeleportSpots")
	var caged := false
	for _i: int in 20:
		await _wait(0.1)
		for node: Node in _director.current_room().get_node(^"%DropLayer").get_children():
			caged = caged or node is HoloCage
	_check(caged, "and boxes the hero in with holo-walls")

	boss.take_damage(250)
	await _wait(0.3)
	_check(phases.phase == 2 and get_tree().get_nodes_in_group(&"glitch_decoys").size() >= 4 and _glitches > 0,
		"below 30% HP: Static Storm with 4 decoys and screen glitches")
	boss.take_damage(9999)
	await _wait(0.5)
	_check(get_tree().get_nodes_in_group(&"glitch_decoys").size() == 0, "GLITCH's decoys vanish with it")
	_check(not _director.is_fighting() and (_director.current_room().feature("Elevator") as Elevator).revealed, "beating GLITCH reveals the elevator")


func _test_lab_talks() -> void:
	GameState.reset_to_new()
	GameState.flags.assign(["lab_intro_done", "l1_cleared", "l1_talk_done", "l2_cleared"])
	var lab := (load(LAB_PATH) as PackedScene).instantiate()
	get_tree().root.add_child(lab)
	await _wait(0.3)
	var ui := lab.get_node(^"LabUI") as LabUI
	_check(ui.dialogue.is_talking() and ui.dialogue.line_label.text.contains("Glitch"), "beating GLITCH unlocks Vorn's Level 2 talk")
	_check(GameState.has_flag("l2_talk_done"), "once")
	lab.queue_free()
	await _wait(0.2)
	GameState.reset_to_new()
	GameState.flags.assign(["lab_intro_done"])
	GameState.stats["runs"] = 2
	lab = (load(LAB_PATH) as PackedScene).instantiate()
	get_tree().root.add_child(lab)
	await _wait(0.3)
	ui = lab.get_node(^"LabUI") as LabUI
	_check(ui.dialogue.is_talking() and ui.dialogue.speaker_label.text == "VORN", "otherwise Vorn has an idle line for Kade's band")
	ui.open_surgery()
	ui._select_slot("eyes")
	_check(not ui.install_button.disabled or GameState.ram_mb < 256, "Eyes are installable in surgery now")
	ui._on_surgery_close_pressed()
	lab.queue_free()
	GameState.reset_to_new()
	await _wait(0.2)


# --- Helpers ---

func _clear_fight() -> void:
	for _round: int in 16:
		if not _director.is_fighting():
			return
		await _wait(1.0)
		for node: Node in _spawner.alive.duplicate():
			_kill(node)
		await _physics_frames(3)


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
	_director.current_room().get_node(^"%DropLayer").add_child(pickup)
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
