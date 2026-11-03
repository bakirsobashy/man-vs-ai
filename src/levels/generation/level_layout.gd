class_name LevelLayout
extends RefCounted
## A generated level: rooms (index = id) on an abstract grid, joined by doors. Plain data.

var level_seed := 0
var rooms: Array[RoomNode] = []
var start_id := 0
var boss_id := 0


func count_of(type: Room.RoomType) -> int:
	var count := 0
	for room: RoomNode in rooms:
		if room.type == type:
			count += 1
	return count


## Doors from the start room to every room (-1 = unreachable).
func depths() -> Array[int]:
	var result: Array[int] = []
	result.resize(rooms.size())
	result.fill(-1)
	result[start_id] = 0
	var queue: Array[int] = [start_id]
	while not queue.is_empty():
		var id: int = queue.pop_front()
		for neighbor: int in rooms[id].neighbors.values():
			if result[neighbor] == -1:
				result[neighbor] = result[id] + 1
				queue.append(neighbor)
	return result
