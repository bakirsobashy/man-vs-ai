class_name MemoryData
extends Resource
## One memory of Lena and Mira (docs/narrative.md §8). Band variants arrive in M5.

@export var title := ""
@export_multiline var text := ""
## Half-hearts healed the first time the memory is opened.
@export_range(0, 6) var heal := 1
