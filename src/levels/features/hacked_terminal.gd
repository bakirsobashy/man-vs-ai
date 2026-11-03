class_name HackedTerminal
extends Interactable
## Pay RAM for a random outcome, once (docs/content.md §7).

enum Outcome { RARE_CHEST, CRYPTO_JACKPOT, SUPPLIES, AMBUSH, VIRUS, NOTHING }

## RAM cost = this × level.
@export_range(1, 999) var cost_per_level := 32
## Chance of each outcome, in Outcome order.
@export var weights: Array[float] = [0.30, 0.20, 0.15, 0.15, 0.10, 0.10]
## Crypto jackpot = this × level.
@export_range(1, 999) var jackpot_per_level := 40
## Tests only: always roll this outcome (-1 = random).
@export_range(-1, 5) var forced_outcome := -1

@onready var sprite: Sprite2D = %Sprite
@onready var drop_spot: Marker2D = %DropSpot

var used := false


func cost() -> int:
	return cost_per_level * RunState.level_number


func prompt_text() -> String:
	return "Hack terminal (%d MB)" % cost()


func can_interact(_player: Player) -> bool:
	return not used


func interact(player: Player) -> void:
	if not GameState.spend_ram(cost()):
		EventBus.toast_requested.emit("Not enough RAM")
		return
	used = true
	sprite.frame = 1
	var outcome := forced_outcome if forced_outcome >= 0 else _roll()
	match outcome:
		Outcome.RARE_CHEST:
			EventBus.reward_chest_requested.emit(drop_spot.global_position)
			EventBus.toast_requested.emit("ACCESS GRANTED: rare chest")
		Outcome.CRYPTO_JACKPOT:
			GameState.add_crypto(jackpot_per_level * RunState.level_number)
			EventBus.toast_requested.emit("Jackpot: +%d Crypto" % (jackpot_per_level * RunState.level_number))
		Outcome.SUPPLIES:
			player.apply_repair(RepairStation.Item.AMMO)
			player.apply_repair(RepairStation.Item.ARMOR)
			EventBus.toast_requested.emit("Supplies: ammo and armor")
		Outcome.AMBUSH:
			EventBus.toast_requested.emit("TRAP: ambush!")
			EventBus.ambush_requested.emit()
		Outcome.VIRUS:
			player.emp_charges = maxi(player.emp_charges - 1, 0)
			EventBus.player_emp_changed.emit(player.emp_charges)
			EventBus.toast_requested.emit("Virus: -1 EMP charge")
		_:
			EventBus.toast_requested.emit("ERROR 404")


func _roll() -> int:
	var total := 0.0
	for weight: float in weights:
		total += weight
	var roll := randf() * total
	for i: int in weights.size():
		roll -= weights[i]
		if roll <= 0.0:
			return i
	return weights.size() - 1
