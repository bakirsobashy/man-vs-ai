class_name BulletPalette
extends Resource
## A bullet color scheme (GDD §8.5: color-blind-safe bullets). Each BulletPool uses the material for its side;
## bullets inherit it (use_parent_material), so the recolor never touches their shape or size. Null = original art.

@export var display_name := "settings.palette.default"
@export var hostile_material: Material
@export var friendly_material: Material
