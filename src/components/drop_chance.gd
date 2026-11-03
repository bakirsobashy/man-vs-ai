class_name DropChance
extends Resource
## One optional drop in a Drops list: a pickup scene, its chance and its amount.

## The authored pickup scene to copy.
@export var scene: PackedScene
## Chance to drop, 0..1.
@export_range(0.0, 1.0, 0.01) var chance := 0.1
## Amount the pickup carries (half-hearts, armor pips, Crypto…).
@export_range(1, 999) var amount := 1
