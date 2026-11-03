extends Node
## The current run (autoload "RunState"). M2 holds the wallet; seeds, rooms and saving arrive in M3–M4.

var crypto := 0
var ram_mb := 0


func add_crypto(amount: int) -> void:
	crypto += amount
	EventBus.currency_changed.emit(crypto, ram_mb)


func add_ram(amount: int) -> void:
	ram_mb += amount
	EventBus.currency_changed.emit(crypto, ram_mb)


func reset() -> void:
	crypto = 0
	ram_mb = 0
	EventBus.currency_changed.emit(crypto, ram_mb)
