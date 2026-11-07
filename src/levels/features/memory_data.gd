class_name MemoryData
extends Resource
## One memory of Lena and Mira (docs/narrative.md §8). The text changes with Kade's humanity band: the more of him
## is machine, the less of the memory he can feel.

## Saved in GameState.memories once found (the lab codex).
@export var id := ""
@export var title := ""
## Fallback text (and the Human band's, if band_texts is empty).
@export_multiline var text := ""
## One text per band: Human, Patched, Hollow, Machine (GameState.Band order). Empty entries use `text`.
@export_multiline var band_texts: Array[String] = []
## Half-hearts healed the first time the memory is opened.
@export_range(0, 6) var heal := 1


## The text Kade reads in `band`.
func text_for(band: int) -> String:
	if band < band_texts.size() and band_texts[band] != "":
		return band_texts[band]
	return text
