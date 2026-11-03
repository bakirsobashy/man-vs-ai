class_name MapView
extends Control
## The level map (minimap and full map). Copies map_cell.tscn for every known room, centered on the current
## room. Listens to EventBus; the cell size and spacing are exports so one scene serves both sizes.

@export var cell_scene: PackedScene
## Distance between neighboring cells.
@export var cell_step := Vector2(14, 11)
## Scale applied to each cell copy.
@export var cell_scale := 1.0
## Icon per room type (Room.RoomType order); empty for rooms without an icon.
@export var icons: Array[Texture2D] = []

@onready var cells_root: Control = %Cells

var _layout: LevelLayout
var _current := -1


func _ready() -> void:
	EventBus.level_generated.connect(_on_level_generated)
	EventBus.room_entered.connect(_on_room_entered)
	EventBus.room_cleared.connect(_on_room_cleared)


func rebuild() -> void:
	for child: Node in cells_root.get_children():
		child.queue_free()
	if _layout == null or _current < 0:
		return
	var center := cells_root.size * 0.5
	var here := _layout.rooms[_current].cell
	for room: RoomNode in _layout.rooms:
		if not room.known:
			continue
		var cell := cell_scene.instantiate() as MapCell
		cells_root.add_child(cell)
		cell.scale = Vector2.ONE * cell_scale
		cell.position = center + Vector2(room.cell - here) * cell_step - cell.size * cell_scale * 0.5
		cell.show_room(room, room.id == _current, icons[room.type] if room.type < icons.size() else null)


func known_cells() -> int:
	return cells_root.get_child_count()


func _on_level_generated(layout: RefCounted) -> void:
	_layout = layout as LevelLayout
	_current = -1


func _on_room_entered(room_id: int) -> void:
	_current = room_id
	rebuild()


func _on_room_cleared(_room_id: int) -> void:
	rebuild()


## Also fires during the first layout pass, before _ready.
func _on_resized() -> void:
	if is_node_ready():
		rebuild()
