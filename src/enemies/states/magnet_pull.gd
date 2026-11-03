extends EnemyState
## SCRAPJAW's magnet (docs/content.md §4, phase 2). Scrap streams from a few of the arena's ScrapSpots toward the
## boss (lines to dodge) while the hero is pulled in lightly; at the end, scrap drops in piles at free ScrapSpots
## and becomes new cover. ScrapSpots are hand-placed markers in the boss room (group "scrap_spots").

## The enemy bullet scene the streams are made of (its BulletPool is in the level scene).
@export var scrap_bullet: PackedScene
## The cover scene copied for each scrap pile.
@export var pile_scene: PackedScene
@export_range(0.5, 10.0, 0.1, "suffix:s") var duration := 2.4
@export_range(0.05, 1.0, 0.01, "suffix:s") var stream_interval := 0.22
## How many ScrapSpots stream at once.
@export_range(1, 8) var streams := 3
## How fast the hero is dragged toward the boss (walls and cover stop it).
@export_range(0.0, 120.0, 1.0, "suffix:px/s") var pull_speed := 28.0
## Piles dropped when the pull ends.
@export_range(0, 8) var piles := 2
@export var next_state := &"MagnetSpray"

var _left := 0.0
var _next_volley := 0.0
var _spots: Array[Marker2D] = []
var _pool: BulletPool


func enter(_msg: Dictionary) -> void:
	enemy.velocity = Vector2.ZERO
	_left = duration
	_next_volley = 0.0
	_pool = BulletPool.find_for(get_tree(), scrap_bullet)
	var all := _all_spots()
	all.shuffle()
	_spots = all.slice(0, streams)


func physics_update(delta: float) -> void:
	_left -= delta
	_next_volley -= delta
	if _next_volley <= 0.0 and _pool != null:
		_next_volley = stream_interval
		for spot: Marker2D in _spots:
			_pool.spawn(spot.global_position, (enemy.global_position - spot.global_position).normalized())
	var hero := enemy.player as CharacterBody2D
	if hero != null and pull_speed > 0.0:
		var toward := enemy.global_position - hero.global_position
		if toward.length() > 24.0:
			hero.move_and_collide(toward.normalized() * pull_speed * delta)
	if _left <= 0.0:
		drop_piles()
		machine.transition_to(next_state)


## Scrap piles on free ScrapSpots (a spot with a pile on it is taken).
func drop_piles() -> void:
	if pile_scene == null:
		return
	var free := _all_spots().filter(func(spot: Marker2D) -> bool: return spot.get_child_count() == 0)
	free.shuffle()
	for i: int in mini(piles, free.size()):
		var pile := pile_scene.instantiate() as Node2D
		(free[i] as Marker2D).add_child(pile)
		EventBus.cover_restored.emit(pile)


func _all_spots() -> Array[Marker2D]:
	var result: Array[Marker2D] = []
	var root := get_tree().get_first_node_in_group(&"scrap_spots")
	if root != null:
		for child: Node in root.get_children():
			if child is Marker2D:
				result.append(child as Marker2D)
	return result
