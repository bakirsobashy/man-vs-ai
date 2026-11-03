class_name RoomNode
extends RefCounted
## One room of a generated level: its type, grid cell, doors to neighbors and progress. Plain data.

var id := 0
var type := Room.RoomType.COMBAT
var cell := Vector2i.ZERO
## Door direction → neighbor room id.
var neighbors: Dictionary[Vector2i, int] = {}
var scene: PackedScene
## Progress during play.
var known := false
var visited := false
var cleared := false
