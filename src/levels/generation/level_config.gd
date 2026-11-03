class_name LevelConfig
extends Resource
## Everything that makes one level (docs/content.md §6–§8): room counts, the room pool, fights, rewards and odds.
## One .tres per level in data/levels/.

@export_group("Identity")
@export_range(1, 5) var level_number := 1
@export var district_name := "Rustline Slums"

@export_group("Room counts")
@export_range(1, 12) var combat_min := 4
@export_range(1, 12) var combat_max := 5
@export_range(0, 4) var chest_min := 1
@export_range(0, 4) var chest_max := 2
## Special rooms include the one Memory room every level has.
@export_range(1, 4) var special_min := 1
@export_range(1, 4) var special_max := 2
## Total rooms, Start and Boss included.
@export_range(4, 20) var total_min := 8
@export_range(4, 20) var total_max := 9
## Relative chance of each extra special room type.
@export_range(0.0, 10.0, 0.05) var repair_weight := 0.5
@export_range(0.0, 10.0, 0.05) var arena_weight := 0.25
@export_range(0.0, 10.0, 0.05) var terminal_weight := 0.25

@export_group("Audio")
## The district's music (the level director's own music is the fallback).
@export var music: AudioStream
@export var boss_music: AudioStream

@export_group("Rooms")
@export var room_pool: Array[RoomEntry] = []
## The boss (M3: a stand-in until SCRAPJAW arrives in M4).
@export var boss_scene: PackedScene
## A story gun the first boss kill unlocks (Level 4: WARDEN unlocks the M7 Line Rifle). Empty for none.
@export var boss_reward_weapon := &""
## Its name in the unlock banner.
@export var boss_reward_name := ""

@export_group("Fights")
## Enemy pool used in this level's rooms.
@export var wave_settings: WaveSettings
@export_range(1, 5) var waves_min := 1
@export_range(1, 5) var waves_max := 2
## Threat budget of each wave in a combat room.
@export_range(1.0, 50.0, 0.5) var room_threat := 6.0
## Challenge arena: waves and threat per wave (the next level's budget).
@export_range(1, 6) var arena_waves := 3
@export_range(1.0, 50.0, 0.5) var arena_threat := 8.0
## Hacked-terminal ambush: one wave with this budget (levels without elites).
@export_range(1.0, 50.0, 0.5) var ambush_threat := 3.0
## Chance that a single enemy spawns as an elite (L1 0%, L2 10% …). With elites, the terminal ambush is one elite.
@export_range(0.0, 1.0, 0.01) var elite_chance := 0.0

@export_group("Loot")
## Chest rarity odds: Common, Rare, Epic, Legendary.
@export var chest_odds: Array[float] = [0.70, 0.25, 0.05, 0.0]


## A chest rarity from chest_odds for a 0–1 `roll`, never below `minimum` (the odds above it are rescaled).
func roll_rarity(roll: float, minimum := WeaponCatalogEntry.Rarity.COMMON) -> WeaponCatalogEntry.Rarity:
	var total := 0.0
	for i: int in range(minimum, chest_odds.size()):
		total += chest_odds[i]
	if total <= 0.0:
		return minimum
	var left := roll * total
	for i: int in range(minimum, chest_odds.size()):
		left -= chest_odds[i]
		if left <= 0.0:
			return i as WeaponCatalogEntry.Rarity
	return (chest_odds.size() - 1) as WeaponCatalogEntry.Rarity
