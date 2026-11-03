class_name CoverSpot
extends RefCounted
## A place where the hero can crouch next to a piece of cover. Plain data, not a node.

var cover: Cover
var position := Vector2.ZERO
## Points from the cover toward the hero. Bullets travelling along it come from the cover's side.
var normal := Vector2.ZERO


static func create(piece: Cover, at: Vector2, face_normal: Vector2) -> CoverSpot:
	var spot := CoverSpot.new()
	spot.cover = piece
	spot.position = at
	spot.normal = face_normal
	return spot
