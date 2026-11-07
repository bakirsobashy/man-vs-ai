class_name LineSet
extends Resource
## Alternative lines for the same moment (death retrievals, Patch's sales talk). pick() cycles through them.

@export var speaker := "speaker.vorn"
@export_multiline var lines: Array[String] = []


## The line for the `index`-th time this moment happens (wraps around).
func pick(index: int) -> String:
	return lines[posmod(index, lines.size())] if not lines.is_empty() else ""
