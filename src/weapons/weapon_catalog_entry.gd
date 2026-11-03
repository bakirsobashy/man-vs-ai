class_name WeaponCatalogEntry
extends Resource
## One gun in the weapon catalog (docs/content.md §3).

enum Rarity { COMMON, RARE, EPIC, LEGENDARY }

@export var id := &""
@export var scene: PackedScene
@export var rarity := Rarity.COMMON
## Crypto to unlock it in the lab (M4). 0 = unlocked from the start.
@export_range(0, 9999) var unlock_cost := 0
