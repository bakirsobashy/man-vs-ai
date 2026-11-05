extends Node
## The loaded save slot (autoload "GameState", docs/technical.md §8): everything that survives death.
## Currencies, implants, weapon unlocks, memories, stats and story flags. SaveManager writes it to
## user://slot_N.json. With no slot loaded (slot 0: the test levels) it still works in memory.

enum Band { HUMAN, PATCHED, HOLLOW, MACHINE }

## Body slots, in surgery order (docs/content.md §5). Saved by name.
const IMPLANT_SLOTS: Array[String] = ["eyes", "brain", "arms", "heart", "lungs", "legs"]
## A new save owns the Service Pistol and the three free Commons (GDD §5.3).
const STARTER_WEAPONS: Array[String] = ["service_pistol", "scattergun", "buzz_smg", "rivet_driver"]

## 1–3 while a save slot is loaded; 0 = none.
var slot := 0
var crypto := 0
var ram_mb := 0
## Slot name → tier (0 = human, 1–3 = Mk I–III).
var implants: Dictionary[String, int] = {}
var unlocked_weapons: Array[String] = []
var memories: Array[String] = []
var endings_seen: Array[String] = []
## The ending of the last finished campaign (the credits show its post-credits line).
var last_ending := ""
## NG+ (Q5): the threat level new runs start at, and the highest one an ending has unlocked.
var threat_level := 0
var threat_unlocked := 0
## runs, deaths, best_level, boss_kills, rooms_cleared.
var stats: Dictionary[String, int] = {}
## One-time story beats: prologue_seen, tutorial_done, first-implant panels, lab talks…
var flags: Array[String] = []
var playtime_s := 0.0


func _ready() -> void:
	reset_to_new()


func _process(delta: float) -> void:
	if slot > 0:
		playtime_s += delta


## A fresh life story (a new or deleted slot).
func reset_to_new() -> void:
	crypto = 0
	ram_mb = 0
	implants.clear()
	for slot_name: String in IMPLANT_SLOTS:
		implants[slot_name] = 0
	unlocked_weapons = STARTER_WEAPONS.duplicate()
	memories.clear()
	endings_seen.clear()
	last_ending = ""
	threat_level = 0
	threat_unlocked = 0
	stats = {"runs": 0, "deaths": 0, "best_level": 0, "boss_kills": 0, "rooms_cleared": 0}
	flags.clear()
	playtime_s = 0.0
	EventBus.currency_changed.emit(crypto, ram_mb)


# --- Currencies (kept on death) ---

func add_crypto(amount: int) -> void:
	crypto += amount
	RunState.crypto_earned += amount
	EventBus.currency_changed.emit(crypto, ram_mb)


func add_ram(amount: int) -> void:
	ram_mb += amount
	RunState.ram_earned += amount
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


# --- Implants (permanent and irreversible) ---

func implant_tier(slot_name: String) -> int:
	return implants.get(slot_name, 0)


func set_implant(slot_name: String, tier: int) -> void:
	implants[slot_name] = clampi(tier, 0, 3)
	EventBus.implants_changed.emit()


## Slots with any implant; tiers don't count (GDD §5.5).
func filled_slots() -> int:
	var count := 0
	for slot_name: String in IMPLANT_SLOTS:
		count += 1 if implant_tier(slot_name) > 0 else 0
	return count


## A campaign was finished: remember the ending and unlock threat level `unlock_threat` (if it's new).
func record_ending(ending_id: String, unlock_threat: int) -> void:
	if not endings_seen.has(ending_id):
		endings_seen.append(ending_id)
	last_ending = ending_id
	threat_unlocked = maxi(threat_unlocked, unlock_threat)
	add_stat("endings")


func humanity_band() -> Band:
	var filled := filled_slots()
	if filled == 0:
		return Band.HUMAN
	if filled <= 2:
		return Band.PATCHED
	if filled <= 5:
		return Band.HOLLOW
	return Band.MACHINE


# --- Unlocks, flags and stats ---

func is_unlocked(weapon_id: StringName) -> bool:
	return unlocked_weapons.has(String(weapon_id))


func unlock_weapon(weapon_id: StringName) -> void:
	if not is_unlocked(weapon_id):
		unlocked_weapons.append(String(weapon_id))


func has_flag(flag: String) -> bool:
	return flags.has(flag)


func set_flag(flag: String) -> void:
	if not flags.has(flag):
		flags.append(flag)


func add_stat(stat: String, amount: int = 1) -> void:
	stats[stat] = stats.get(stat, 0) + amount


func stat(stat_name: String) -> int:
	return stats.get(stat_name, 0)


# --- Save data (plain JSON values only) ---

func to_dict() -> Dictionary:
	return {
		"playtime_s": int(playtime_s),
		"crypto": crypto,
		"ram_mb": ram_mb,
		"implants": implants.duplicate(),
		"unlocked_weapons": unlocked_weapons.duplicate(),
		"memories": memories.duplicate(),
		"endings_seen": endings_seen.duplicate(),
		"last_ending": last_ending,
		"threat_level": threat_level,
		"threat_unlocked": threat_unlocked,
		"stats": stats.duplicate(),
		"flags": flags.duplicate(),
	}


## Reads a save written by to_dict(). Unknown or malformed fields fall back to a new save's values.
func from_dict(data: Dictionary) -> void:
	reset_to_new()
	playtime_s = float(data.get("playtime_s", 0))
	crypto = maxi(int(data.get("crypto", 0)), 0)
	ram_mb = maxi(int(data.get("ram_mb", 0)), 0)
	var saved_implants: Variant = data.get("implants", {})
	if saved_implants is Dictionary:
		for slot_name: String in IMPLANT_SLOTS:
			implants[slot_name] = clampi(int((saved_implants as Dictionary).get(slot_name, 0)), 0, 3)
	unlocked_weapons = _strings(data.get("unlocked_weapons", []), STARTER_WEAPONS)
	memories = _strings(data.get("memories", []), [])
	endings_seen = _strings(data.get("endings_seen", []), [])
	last_ending = str(data.get("last_ending", ""))
	threat_unlocked = maxi(int(data.get("threat_unlocked", 0)), 0)
	threat_level = clampi(int(data.get("threat_level", 0)), 0, threat_unlocked)
	flags = _strings(data.get("flags", []), [])
	var saved_stats: Variant = data.get("stats", {})
	if saved_stats is Dictionary:
		for key: Variant in (saved_stats as Dictionary):
			stats[str(key)] = int((saved_stats as Dictionary)[key])
	EventBus.currency_changed.emit(crypto, ram_mb)


func _strings(value: Variant, fallback: Array[String]) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item: Variant in value:
			result.append(str(item))
	return result if not result.is_empty() else fallback.duplicate()
