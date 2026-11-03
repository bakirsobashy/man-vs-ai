extends Node
## The level generator test (started by tools/test_level_generator.gd).
## Generates LEVELS layouts for every level in data/levels/campaign.tres and checks each against LevelGenerator.validate().
## It also checks that the same seed gives the same layout, that layouts vary, and that validate() catches
## broken layouts.

const CAMPAIGN_PATH := "res://data/levels/campaign.tres"
const LEVELS := 10000

var _failures := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var campaign := load(CAMPAIGN_PATH) as Campaign
	for config: LevelConfig in campaign.levels:
		_test_level(config)
	var config := campaign.levels[0]
	var again := LevelGenerator.generate(config, 4242)
	_check(_signature(again) == _signature(LevelGenerator.generate(config, 4242)), "the same seed gives the same layout")
	_check(_signature(again) != _signature(LevelGenerator.generate(config, 4243)), "a different seed gives a different layout")
	_test_validate_catches_broken_layouts(config)
	_test_chest_rarity_odds(config)

	print("Level generator test finished: %d failure(s)" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _test_level(config: LevelConfig) -> void:
	var started := Time.get_ticks_msec()
	var invalid := 0
	var first_error := ""
	var signatures: Dictionary[String, bool] = {}
	var totals: Dictionary[int, int] = {}
	var specials: Dictionary[int, int] = {}
	var boss_depth_min := 99
	var boss_depth_max := 0
	for level_seed: int in range(1, LEVELS + 1):
		var layout := LevelGenerator.generate(config, level_seed)
		var error := "no layout" if layout == null else LevelGenerator.validate(layout, config)
		if error != "":
			invalid += 1
			if first_error == "":
				first_error = "seed %d: %s" % [level_seed, error]
			continue
		signatures[_signature(layout)] = true
		totals[layout.rooms.size()] = totals.get(layout.rooms.size(), 0) + 1
		for type: Room.RoomType in [Room.RoomType.ARENA, Room.RoomType.REPAIR, Room.RoomType.TERMINAL]:
			specials[type] = specials.get(type, 0) + layout.count_of(type)
		var depth: int = layout.depths()[layout.boss_id]
		boss_depth_min = mini(boss_depth_min, depth)
		boss_depth_max = maxi(boss_depth_max, depth)
	var seconds := (Time.get_ticks_msec() - started) / 1000.0
	_check(invalid == 0, "Level %d (%s): %d generated levels pass every rule (%d invalid%s) in %.1f s"
		% [config.level_number, config.district_name, LEVELS, invalid, ", first: " + first_error if first_error != "" else "", seconds])
	_check(signatures.size() > LEVELS * 0.9, "layouts vary (%d distinct of %d)" % [signatures.size(), LEVELS])
	print("      room counts: %s · boss depth %d–%d" % [totals, boss_depth_min, boss_depth_max])
	print("      extra specials: arena %d · repair %d · terminal %d"
		% [specials.get(Room.RoomType.ARENA, 0), specials.get(Room.RoomType.REPAIR, 0), specials.get(Room.RoomType.TERMINAL, 0)])


func _test_validate_catches_broken_layouts(config: LevelConfig) -> void:
	var broken := LevelGenerator.generate(config, 7)
	var start := broken.rooms[broken.start_id]
	var direction: Vector2i = start.neighbors.keys()[0]
	start.neighbors.erase(direction)
	_check(LevelGenerator.validate(broken, config) != "", "validate() catches a one-sided door")

	broken = LevelGenerator.generate(config, 7)
	broken.rooms[broken.boss_id].type = Room.RoomType.COMBAT
	_check(LevelGenerator.validate(broken, config) != "", "validate() catches a missing boss room")

	broken = LevelGenerator.generate(config, 7)
	var boss := broken.rooms[broken.boss_id]
	var free := Vector2i.ZERO
	for candidate: Vector2i in LevelGenerator.DIRECTIONS:
		if not boss.neighbors.has(candidate) and not _cell_taken(broken, boss.cell + candidate):
			free = candidate
	var extra := RoomNode.new()
	extra.id = broken.rooms.size()
	extra.type = Room.RoomType.COMBAT
	extra.cell = boss.cell + free
	extra.scene = boss.scene
	extra.neighbors[-free] = boss.id
	boss.neighbors[free] = extra.id
	broken.rooms.append(extra)
	_check(free != Vector2i.ZERO and LevelGenerator.validate(broken, config) != "", "validate() catches a boss room that isn't a dead end")


func _test_chest_rarity_odds(config: LevelConfig) -> void:
	var counts: Array[int] = [0, 0, 0, 0]
	var reward_below_rare := 0
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for _i: int in 10000:
		counts[config.roll_rarity(rng.randf())] += 1
		if config.roll_rarity(rng.randf(), WeaponCatalogEntry.Rarity.RARE) < WeaponCatalogEntry.Rarity.RARE:
			reward_below_rare += 1
	var shares := counts.map(func(c: int) -> float: return c / 10000.0)
	var close := true
	for i: int in counts.size():
		close = close and absf(shares[i] - config.chest_odds[i]) < 0.02
	_check(close, "chest rarity rolls follow the level's odds (%s)" % [shares])
	_check(reward_below_rare == 0, "Rare-or-better rolls never give a Common")


func _cell_taken(layout: LevelLayout, cell: Vector2i) -> bool:
	for room: RoomNode in layout.rooms:
		if room.cell == cell:
			return true
	return false


func _signature(layout: LevelLayout) -> String:
	var parts: PackedStringArray = []
	for room: RoomNode in layout.rooms:
		parts.append("%d@%s:%s" % [room.type, room.cell, room.scene.resource_path.get_file()])
	return "|".join(parts)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS  ", label)
	else:
		_failures += 1
		print("FAIL  ", label)
