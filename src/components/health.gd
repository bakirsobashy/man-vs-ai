@icon("res://assets/art/placeholder/icon_health.svg")
class_name Health
extends Node
## Hit points, armor and post-hit invulnerability for the node that owns it.

## Emitted on every change; damaged is true when the change came from a hit.
signal changed(hp: int, max_hp: int, armor: int, damaged: bool)
signal died

## Maximum hit points. For the hero, 1 hp = half a heart (6 = 3 hearts).
@export_range(1, 9999) var max_hp := 6
## Maximum armor pips. Each pip absorbs one whole hit.
@export_range(0, 9) var max_armor := 0
## Armor at the start and after reset().
@export_range(0, 9) var start_armor := 0
## Optional. Started after each hit; no damage is taken while it runs.
@export var invuln_timer: Timer

var hp := 0
var armor := 0


func _ready() -> void:
	hp = max_hp
	armor = mini(start_armor, max_armor)


func reset() -> void:
	hp = max_hp
	armor = mini(start_armor, max_armor)
	if invuln_timer != null:
		invuln_timer.stop()
	changed.emit(hp, max_hp, armor, false)


func heal(amount: int) -> void:
	if not is_alive() or amount <= 0:
		return
	hp = mini(hp + amount, max_hp)
	changed.emit(hp, max_hp, armor, false)


func add_armor(amount: int) -> void:
	armor = mini(armor + amount, max_armor)
	changed.emit(hp, max_hp, armor, false)


func is_alive() -> bool:
	return hp > 0


func is_invulnerable() -> bool:
	return invuln_timer != null and not invuln_timer.is_stopped()


func take_hit(amount: int) -> void:
	if not is_alive() or is_invulnerable() or amount <= 0:
		return
	if armor > 0:
		armor -= 1
	else:
		hp = maxi(hp - amount, 0)
	if invuln_timer != null:
		invuln_timer.start()
	changed.emit(hp, max_hp, armor, true)
	if hp == 0:
		died.emit()
