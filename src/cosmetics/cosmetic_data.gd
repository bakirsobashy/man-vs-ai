class_name CosmeticData
extends Resource
## One cosmetic in the shop (GDD §9: looks only, never stats). An empty product_id means it's free and always owned
## (each kind's default). Placeholder art tints existing nodes until the real art arrives: outfits tint the hero's
## body, weapon skins tint gun sprites (never bullets or silhouettes), EMP styles tint the EMP wave, and lab
## decorations show the pre-placed node named after the id under the lab's Decor node.

enum Kind { OUTFIT, WEAPON_SKIN, LAB_DECOR, EMP_STYLE }

@export var id := ""
## The Play Console product ID (one-time, non-consumable). Empty: free.
@export var product_id := ""
@export var kind := Kind.OUTFIT
@export var display_name := ""
@export_multiline var description := ""
## Shown until the store reports the real localized price.
@export var price_label := ""
## Placeholder look: the tint applied to the cosmetic's target node.
@export var tint := Color.WHITE


func is_free() -> bool:
	return product_id == ""
