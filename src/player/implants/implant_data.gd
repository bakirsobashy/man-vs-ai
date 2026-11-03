class_name ImplantData
extends Resource
## One implant tier for one body slot (data/implants/*.tres). Tiers are cumulative: Mk II keeps Mk I's modifiers.

## Body slot name, as in GameState.IMPLANT_SLOTS ("heart", "legs"…).
@export var slot := "heart"
@export_range(1, 3) var tier := 1
@export var display_name := ""
@export_multiline var description := ""
## RAM cost (Mk I 256, Mk II 512, Mk III 1,024).
@export_range(0, 4096) var cost_mb := 256
@export var modifiers: Array[StatModifier] = []
## Vorn's line after this tier is installed.
@export var vorn_line := ""
