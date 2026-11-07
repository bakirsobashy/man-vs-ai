extends Node
## The performance benchmark (started by tools/benchmark.gd). For each district's level (fixed seed) it:
## 1. enters every room once and times the first entry (the room transition hitch);
## 2. fights in a combat room with 15 robots and 300 enemy bullets kept in flight for `stress_seconds`, sampling
##    the script + physics time of every frame;
## 3. frees the level and checks that no nodes are left behind.
## Times are from this machine's CPU, so the gates are a regression alarm, not the device budget: at M6 the worst
## case cost about 1.2 ms of logic per frame (median) on the development machine, and the alarms ring at 2.5 times
## that. A low-end phone is several times slower, so the budget itself (technical.md §13) is checked on the test
## device with the debug panel's 300-bullet storm.
## Saves go to user://benchmark_saves/. Options after `--`: `--level=3` runs one level, `--seconds=10` stresses longer.

const LEVEL_PATH := "res://src/levels/level.tscn"
const CAMPAIGN_PATH := "res://data/levels/campaign.tres"
const SAVE_DIR := "user://benchmark_saves/"
const EXTRA_ENEMY := "res://src/enemies/grunt/grunt.tscn"
const SEED := 4242
## Budgets (technical.md §13) and the desktop gates.
const ENEMY_BULLETS := 300
const ENEMIES := 15
const GATE_MEDIAN_MS := 3.0
const GATE_P95_MS := 5.0
const GATE_TRANSITION_MS := 50.0

var stress_seconds := 5.0
var only_level := 0
var _failures := 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	SaveManager.save_dir = SAVE_DIR
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--level="):
			only_level = arg.trim_prefix("--level=").to_int()
		elif arg.begins_with("--seconds="):
			stress_seconds = arg.trim_prefix("--seconds=").to_float()
	_rng.seed = SEED
	var campaign := load(CAMPAIGN_PATH) as Campaign
	var orphans_before := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var nodes_before := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	print("level | rooms | transition max ms (room) | frame logic avg / median / p95 / max ms | bullets | robots | nodes | physics pairs")
	for number: int in range(1, campaign.levels.size() + 1):
		if only_level == 0 or only_level == number:
			await _bench_level(number)
	await _wait(0.5)
	var orphans := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)) - orphans_before
	var nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)) - nodes_before
	_check(orphans <= 0 and nodes <= 0, "no nodes left behind once the levels are freed (%d orphan, %d in the tree)" % [orphans, nodes])
	print("Benchmark finished: %d failure(s)" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _bench_level(number: int) -> void:
	get_tree().paused = false
	GameState.reset_to_new()
	RunState.start_new_run()
	RunState.level_number = number
	var level := (load(LEVEL_PATH) as PackedScene).instantiate()
	var director := level.get_node(^"LevelDirector") as LevelDirector
	var player := level.get_node(^"Player") as Player
	director.return_to_lab = false
	director.fixed_seed = SEED
	get_tree().root.add_child(level)
	await _wait(0.5)
	player.health.invuln_timer.start(3600.0)

	# Every room's first entry, with fights switched off (rooms marked cleared).
	var worst_ms := 0.0
	var worst_room := ""
	var fight_room := -1
	for node: RoomNode in director.layout.rooms:
		var was_cleared := node.cleared
		node.cleared = true
		var started := Time.get_ticks_usec()
		director.enter_room(node.id, Vector2i.ZERO)
		var ms := (Time.get_ticks_usec() - started) / 1000.0
		await get_tree().process_frame
		node.cleared = was_cleared
		if ms > worst_ms:
			worst_ms = ms
			worst_room = String(Room.RoomType.keys()[node.type]).to_lower()
		if fight_room < 0 and node.type == Room.RoomType.COMBAT:
			fight_room = node.id
	await _wait(0.2)

	# The worst case: a fight with 15 robots and 300 enemy bullets in flight.
	director.enter_room(fight_room, Vector2i.ZERO)
	await _wait(1.0)
	var room := director.current_room()
	var pool := _hostile_pool(level)
	var samples: Array[float] = []
	var peak_bullets := 0
	var peak_robots := 0
	var peak_nodes := 0
	var peak_pairs := 0
	# With --fixed-fps 60 every frame is one physics step plus one process step and nothing waits, so the wall time
	# between two frames is the frame's whole logic cost. (Godot's TIME_PROCESS monitors report a per-second maximum.)
	var frames := int(stress_seconds * 60.0)
	var physics_frames := Engine.get_physics_frames()
	var last := Time.get_ticks_usec()
	for _frame: int in frames:
		_top_up_robots(room)
		_top_up_bullets(pool, room)
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		samples.append((now - last) / 1000.0)
		last = now
		peak_bullets = maxi(peak_bullets, _enemy_bullets(level))
		peak_robots = maxi(peak_robots, _robots())
		peak_nodes = maxi(peak_nodes, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
		peak_pairs = maxi(peak_pairs, int(Performance.get_monitor(Performance.PHYSICS_2D_COLLISION_PAIRS)))
	if absi(Engine.get_physics_frames() - physics_frames - frames) > 2:
		push_warning("Frames and physics steps differ: run with --fixed-fps 60 (tools/benchmark.gd) for exact frame times.")
	samples.sort()
	var average := 0.0
	for sample: float in samples:
		average += sample
	average /= maxf(samples.size(), 1.0)
	var median := samples[samples.size() / 2] if not samples.is_empty() else 0.0
	var p95 := samples[int(samples.size() * 0.95)] if not samples.is_empty() else 0.0
	var worst: float = samples.back() if not samples.is_empty() else 0.0
	print("L%d %s | %d | %.1f (%s) | %.2f / %.2f / %.2f / %.2f | %d | %d | %d | %d" % [number, tr(director.config.district_name),
		director.layout.rooms.size(), worst_ms, worst_room, average, median, p95, worst, peak_bullets, peak_robots, peak_nodes, peak_pairs])
	_check(peak_bullets >= ENEMY_BULLETS and peak_robots >= ENEMIES, "L%d holds the budget's worst case: %d enemy bullets, %d robots" % [number, peak_bullets, peak_robots])
	_check(median <= GATE_MEDIAN_MS and p95 <= GATE_P95_MS,
		"L%d logic per frame: %.2f ms median, %.2f ms p95 (alarms at %.1f / %.1f ms)" % [number, median, p95, GATE_MEDIAN_MS, GATE_P95_MS])
	_check(worst_ms <= GATE_TRANSITION_MS, "L%d room transitions: worst %.1f ms, a %s room (alarm at %.0f ms)" % [number, worst_ms, worst_room, GATE_TRANSITION_MS])
	for node: Node in get_tree().get_nodes_in_group(&"bullet_pools"):
		(node as BulletPool).clear_active()
	level.queue_free()
	await _wait(0.4)


func _hostile_pool(level: Node) -> BulletPool:
	return level.get_node(^"BulletPools/EnemyBulletsSmall") as BulletPool


## Keeps 300 enemy bullets in flight, launched from random spots in the room in random directions.
func _top_up_bullets(pool: BulletPool, room: Room) -> void:
	var bounds := room.camera_bounds.get_global_rect()
	while pool.active_count < ENEMY_BULLETS:
		var at := Vector2(_rng.randf_range(bounds.position.x, bounds.end.x), _rng.randf_range(bounds.position.y, bounds.end.y))
		if pool.spawn(at, Vector2.RIGHT.rotated(_rng.randf() * TAU)) == null:
			return


## Adds grunts at the room's spawn points until 15 robots are alive.
func _top_up_robots(room: Room) -> void:
	var points := room.spawn_points.get_children()
	var missing := ENEMIES - _robots()
	for i: int in missing:
		var robot := (load(EXTRA_ENEMY) as PackedScene).instantiate() as Node2D
		room.enemies.add_child(robot)
		robot.global_position = (points[i % points.size()] as Node2D).global_position


func _robots() -> int:
	var count := 0
	for node: Node in get_tree().get_nodes_in_group(&"enemies"):
		count += 1 if node.is_inside_tree() and (node as Enemy) != null and (node as Enemy).health.is_alive() else 0
	return count


func _enemy_bullets(level: Node) -> int:
	var count := 0
	for node: Node in level.get_node(^"BulletPools").get_children():
		var pool := node as BulletPool
		count += pool.active_count if pool != null and pool.hostile else 0
	return count


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS  " + label)
	else:
		_failures += 1
		print("FAIL  " + label)
