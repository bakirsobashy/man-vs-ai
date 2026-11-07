class_name EmpField
extends Area2D
## An EMP field (EMP-bots carry one; WARDEN drops them on the hero). While `active`, cover gives the hero no
## protection inside it (Player._is_protected_from). With starts_warming it blinks harmlessly until WarmupTimer
## fires, and LifeTimer removes it; both timeouts are connected in the scene and only autostart on dropped fields.

## Start in the warning state (the WarmupTimer must autostart).
@export var starts_warming := false

@onready var field_animation: AnimationPlayer = %FieldAnimation

var active := true


func _ready() -> void:
	active = not starts_warming
	field_animation.play(&"warn" if starts_warming else &"hum")


## True when the hero stands inside an active field.
static func shorts_out(hero: Player) -> bool:
	for node: Node in hero.get_tree().get_nodes_in_group(&"emp_fields"):
		var field := node as EmpField
		if field != null and field.active and field.overlaps_body(hero):
			return true
	return false


func _on_warmup_timer_timeout() -> void:
	active = true
	field_animation.play(&"hum")


func _on_life_timer_timeout() -> void:
	queue_free()
