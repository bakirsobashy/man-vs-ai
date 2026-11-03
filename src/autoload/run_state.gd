extends Node
## The current run (autoload "RunState"). M2 holds the wallet; seeds, rooms and saving arrive in M3–M4.

var crypto := 0
var ram_mb := 0
## The level being played (prices and rewards scale with it).
var level_number := 1


func add_crypto(amount: int) -> void:
	crypto += amount
	EventBus.currency_changed.emit(crypto, ram_mb)


func add_ram(amount: int) -> void:
	ram_mb += amount
	EventBus.currency_changed.emit(crypto, ram_mb)


## False (and nothing spent) when the wallet is short.
func spend_crypto(amount: int) -> bool:
	if crypto < amount:
		return false
	crypto -= amount
	EventBus.currency_changed.emit(crypto, ram_mb)
	return true


func spend_ram(amount: int) -> bool:
	if ram_mb < amount:
		return false
	ram_mb -= amount
	EventBus.currency_changed.emit(crypto, ram_mb)
	return true


func reset() -> void:
	crypto = 0
	ram_mb = 0
	EventBus.currency_changed.emit(crypto, ram_mb)
