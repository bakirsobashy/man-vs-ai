class_name EndingData
extends Resource
## One of the endings (docs/narrative.md §9; GDD §5.5). The band Kade is in when ZERO falls picks it; its comic plays,
## then the credits, which close on Vorn's post-credits line. One .tres per ending in data/endings/.

@export var id := ""
@export var title := ""
## The humanity band that gets this ending (GameState.Band: Human, Patched, Hollow, Machine).
@export_enum("Human", "Patched", "Hollow", "Machine") var band := 0
@export_file("*.tscn") var comic_scene := ""
## Vorn's line after the credits: each ending shows a different side of him (he's morally grey, Q1).
@export_multiline var post_credits := ""
