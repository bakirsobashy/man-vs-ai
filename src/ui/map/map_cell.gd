class_name MapCell
extends Control
## One room on the map (copied by MapView for every known room). Background, icon and door stubs are nodes
## in map_cell.tscn; this script only colors and shows them.

@export var current_color := Color(1, 1, 1, 0.95)
@export var visited_color := Color(0.55, 0.6, 0.7, 0.9)
@export var known_color := Color(0.25, 0.28, 0.34, 0.85)

@onready var background: ColorRect = %Background
@onready var icon: TextureRect = %Icon
@onready var links: Array[ColorRect] = [%LinkNorth, %LinkEast, %LinkSouth, %LinkWest]


func show_room(room: RoomNode, is_current: bool, room_icon: Texture2D) -> void:
	background.color = current_color if is_current else (visited_color if room.visited else known_color)
	icon.texture = room_icon
	icon.visible = room_icon != null
	for i: int in Door.VECTORS.size():
		links[i].visible = room.neighbors.has(Door.VECTORS[i])
