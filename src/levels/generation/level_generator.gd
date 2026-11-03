class_name LevelGenerator
extends RefCounted
## Builds a level layout from a LevelConfig and a seed (docs/technical.md §7.2). Pure logic: no nodes.
## The same config and seed always give the same layout.
##
## A main path runs Start → combat rooms → Boss; extra combat rooms branch off it; chest and special rooms
## are dead ends. The memory room never touches Start or Boss.

const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const MAX_ATTEMPTS := 200
const SPECIALS: Array[Room.RoomType] = [Room.RoomType.MEMORY, Room.RoomType.ARENA, Room.RoomType.REPAIR, Room.RoomType.TERMINAL]


static func generate(config: LevelConfig, level_seed: int) -> LevelLayout:
	var rng := RandomNumberGenerator.new()
	for attempt: int in MAX_ATTEMPTS:
		rng.seed = hash([level_seed, config.level_number, attempt])
		var layout := _try_build(config, rng)
		if layout != null and validate(layout, config) == "":
			layout.level_seed = level_seed
			return layout
	push_error("LevelGenerator: no valid layout for seed %d" % level_seed)
	return null


## "" when the layout follows every rule, otherwise what's wrong.
static func validate(layout: LevelLayout, config: LevelConfig) -> String:
	var combat := layout.count_of(Room.RoomType.COMBAT)
	var chest := layout.count_of(Room.RoomType.CHEST)
	var special := 0
	for type: Room.RoomType in SPECIALS:
		special += layout.count_of(type)
	if layout.count_of(Room.RoomType.START) != 1 or layout.count_of(Room.RoomType.BOSS) != 1:
		return "needs exactly one start and one boss room"
	if layout.count_of(Room.RoomType.MEMORY) != 1:
		return "needs exactly one memory room"
	if combat < config.combat_min or combat > config.combat_max:
		return "combat rooms %d outside %d–%d" % [combat, config.combat_min, config.combat_max]
	if chest < config.chest_min or chest > config.chest_max:
		return "chest rooms %d outside %d–%d" % [chest, config.chest_min, config.chest_max]
	if special < config.special_min or special > config.special_max:
		return "special rooms %d outside %d–%d" % [special, config.special_min, config.special_max]
	if layout.rooms.size() < config.total_min or layout.rooms.size() > config.total_max:
		return "total rooms %d outside %d–%d" % [layout.rooms.size(), config.total_min, config.total_max]
	var cells: Dictionary[Vector2i, int] = {}
	for room: RoomNode in layout.rooms:
		if cells.has(room.cell):
			return "two rooms share cell %s" % room.cell
		cells[room.cell] = room.id
		if room.scene == null:
			return "room %d has no scene" % room.id
		for direction: Vector2i in room.neighbors:
			var other := layout.rooms[room.neighbors[direction]]
			if other.cell != room.cell + direction or other.neighbors.get(-direction, -1) != room.id:
				return "door %d→%d isn't matched on both sides" % [room.id, other.id]
	var depths := layout.depths()
	if depths.has(-1):
		return "some rooms can't be reached from the start"
	if depths[layout.boss_id] < 3:
		return "boss is only %d rooms from the start" % depths[layout.boss_id]
	for room: RoomNode in layout.rooms:
		var dead_end := room.type == Room.RoomType.BOSS or room.type == Room.RoomType.CHEST or SPECIALS.has(room.type)
		if dead_end and room.neighbors.size() != 1:
			return "room %d (type %d) must be a dead end" % [room.id, room.type]
		if room.type == Room.RoomType.MEMORY:
			for neighbor: int in room.neighbors.values():
				if neighbor == layout.start_id or neighbor == layout.boss_id:
					return "memory room touches the start or boss room"
	return ""


static func _try_build(config: LevelConfig, rng: RandomNumberGenerator) -> LevelLayout:
	var combat := rng.randi_range(config.combat_min, config.combat_max)
	var chest := rng.randi_range(config.chest_min, config.chest_max)
	var special := rng.randi_range(config.special_min, config.special_max)
	while 2 + combat + chest + special > config.total_max:
		if chest > config.chest_min:
			chest -= 1
		elif special > config.special_min:
			special -= 1
		elif combat > config.combat_min:
			combat -= 1
		else:
			return null
	while 2 + combat + chest + special < config.total_min:
		if combat < config.combat_max:
			combat += 1
		elif chest < config.chest_max:
			chest += 1
		elif special < config.special_max:
			special += 1
		else:
			return null

	var layout := LevelLayout.new()
	var cells: Dictionary[Vector2i, RoomNode] = {}
	var start := _add_room(layout, cells, Room.RoomType.START, Vector2i.ZERO)
	layout.start_id = start.id
	var main_combat := clampi(combat - rng.randi_range(0, 2), 2, combat)
	var tip := start
	for _i: int in main_combat:
		tip = _grow(layout, cells, tip, Room.RoomType.COMBAT, rng)
		if tip == null:
			return null
	var boss := _grow(layout, cells, tip, Room.RoomType.BOSS, rng)
	if boss == null:
		return null
	layout.boss_id = boss.id
	for _i: int in combat - main_combat:
		if _grow_from_any(layout, cells, [Room.RoomType.START, Room.RoomType.COMBAT], Room.RoomType.COMBAT, rng) == null:
			return null
	var leaves: Array[Room.RoomType] = [Room.RoomType.MEMORY]
	for _i: int in special - 1:
		leaves.append(_pick_special(config, rng, leaves))
	for _i: int in chest:
		leaves.append(Room.RoomType.CHEST)
	for type: Room.RoomType in leaves:
		var parents: Array[Room.RoomType] = [Room.RoomType.COMBAT]
		if type != Room.RoomType.MEMORY:
			parents.append(Room.RoomType.START)
		if _grow_from_any(layout, cells, parents, type, rng) == null:
			return null
	if not _assign_scenes(layout, config, rng):
		return null
	return layout


static func _add_room(layout: LevelLayout, cells: Dictionary[Vector2i, RoomNode], type: Room.RoomType, cell: Vector2i) -> RoomNode:
	var room := RoomNode.new()
	room.id = layout.rooms.size()
	room.type = type
	room.cell = cell
	layout.rooms.append(room)
	cells[cell] = room
	return room


## A new room on a free cell next to `parent`, joined to it by a door. Null when every side is taken.
static func _grow(layout: LevelLayout, cells: Dictionary[Vector2i, RoomNode], parent: RoomNode,
		type: Room.RoomType, rng: RandomNumberGenerator) -> RoomNode:
	var free: Array[Vector2i] = []
	for direction: Vector2i in DIRECTIONS:
		if not cells.has(parent.cell + direction):
			free.append(direction)
	if free.is_empty():
		return null
	var direction := free[rng.randi_range(0, free.size() - 1)]
	var room := _add_room(layout, cells, type, parent.cell + direction)
	parent.neighbors[direction] = room.id
	room.neighbors[-direction] = parent.id
	return room


static func _grow_from_any(layout: LevelLayout, cells: Dictionary[Vector2i, RoomNode], parent_types: Array[Room.RoomType],
		type: Room.RoomType, rng: RandomNumberGenerator) -> RoomNode:
	var parents: Array[RoomNode] = []
	for room: RoomNode in layout.rooms:
		if parent_types.has(room.type):
			parents.append(room)
	while not parents.is_empty():
		var parent: RoomNode = parents.pop_at(rng.randi_range(0, parents.size() - 1))
		var room := _grow(layout, cells, parent, type, rng)
		if room != null:
			return room
	return null


## A weighted extra special room, preferring types the level doesn't have yet.
static func _pick_special(config: LevelConfig, rng: RandomNumberGenerator, taken: Array[Room.RoomType]) -> Room.RoomType:
	var types: Array[Room.RoomType] = [Room.RoomType.REPAIR, Room.RoomType.ARENA, Room.RoomType.TERMINAL]
	var weights: Array[float] = [config.repair_weight, config.arena_weight, config.terminal_weight]
	var total := 0.0
	for i: int in types.size():
		if taken.has(types[i]):
			weights[i] = 0.0
		total += weights[i]
	if total <= 0.0:
		return types[rng.randi_range(0, types.size() - 1)]
	var roll := rng.randf() * total
	for i: int in types.size():
		roll -= weights[i]
		if roll <= 0.0:
			return types[i]
	return types[types.size() - 1]


## Picks a room scene for every room, avoiding repeats when the pool allows it.
static func _assign_scenes(layout: LevelLayout, config: LevelConfig, rng: RandomNumberGenerator) -> bool:
	var used: Array[PackedScene] = []
	for room: RoomNode in layout.rooms:
		var options: Array[RoomEntry] = []
		for entry: RoomEntry in config.room_pool:
			if entry.type == room.type and entry.scene != null:
				options.append(entry)
		if options.is_empty():
			return false
		var fresh := options.filter(func(e: RoomEntry) -> bool: return not used.has(e.scene))
		var pool: Array = fresh if not fresh.is_empty() else options
		var total := 0.0
		for entry: RoomEntry in pool:
			total += entry.weight
		var roll := rng.randf() * total
		var chosen: RoomEntry = pool[pool.size() - 1]
		for entry: RoomEntry in pool:
			roll -= entry.weight
			if roll <= 0.0:
				chosen = entry
				break
		room.scene = chosen.scene
		used.append(chosen.scene)
	return true
