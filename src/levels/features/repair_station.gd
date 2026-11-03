class_name RepairStation
extends Interactable
## Sells repairs for Crypto (docs/content.md §7). Its prompt opens the HUD shop panel, which calls buy().

enum Item { HALF_HEART, ARMOR, EMP_CHARGE, AMMO }

## Price = base + per_level × level, in item order: ½ heart, armor, EMP charge, ammo refill.
@export var base_prices: Array[int] = [10, 15, 20, 8]
@export var price_per_level: Array[int] = [5, 5, 5, 4]
## Purchases per station.
@export_range(0, 9) var purchases := 3

var purchases_left := 3


func _ready() -> void:
	purchases_left = purchases


func price(item: Item) -> int:
	return base_prices[item] + price_per_level[item] * RunState.level_number


func prompt_text() -> String:
	return "Repair station (%d left)" % purchases_left


func can_interact(_player: Player) -> bool:
	return purchases_left > 0


func interact(_player: Player) -> void:
	EventBus.shop_opened.emit(self)


## Tries to buy one item; returns the message the HUD shows.
func buy(item: Item, player: Player) -> String:
	if purchases_left <= 0:
		return "Sold out"
	var cost := price(item)
	if RunState.crypto < cost:
		return "Not enough Crypto"
	if not player.apply_repair(item):
		return "You don't need that"
	RunState.spend_crypto(cost)
	purchases_left -= 1
	return "Bought for %d Crypto" % cost
