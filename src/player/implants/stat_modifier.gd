class_name StatModifier
extends Resource
## One change an implant makes to the hero (docs/content.md §5). Values add up across the slot's tiers.

enum Stat {
	MAX_HP,             ## Half-hearts added to max health.
	START_ARMOR,        ## Armor pips at the start of each level.
	MOVE_SPEED,         ## Share added to move speed (0.12 = +12%).
	ROLL_DISTANCE,      ## Share added to roll distance (0.3 = +30%).
	HEAL_EVERY_ROOMS,   ## Heal ½ heart after this many cleared rooms.
	ROLL_SHOCKWAVE,     ## Damage of the shockwave at the end of every roll.
}

@export var stat := Stat.MAX_HP
@export var value := 0.0
