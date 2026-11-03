@icon("res://assets/art/placeholder/icon_state.svg")
class_name StateMachine
extends Node
## Runs its State child nodes, so the states are visible in the Scene dock.

signal state_changed(state_name: StringName)

## The state that is active when the scene starts.
@export var initial_state: State

var current: State


func _ready() -> void:
	for child: Node in get_children():
		var state := child as State
		if state != null:
			state.machine = self
	await owner.ready
	current = initial_state
	current.enter({})
	state_changed.emit(current.name)


func _physics_process(delta: float) -> void:
	if current != null:
		current.physics_update(delta)


func transition_to(state_name: StringName, msg: Dictionary = {}) -> void:
	var next := get_node_or_null(NodePath(state_name)) as State
	if next == null:
		push_error("StateMachine: no state node named '%s'" % state_name)
		return
	if current != null:
		current.exit()
	current = next
	current.enter(msg)
	state_changed.emit(state_name)


func is_in(state_name: StringName) -> bool:
	return current != null and current.name == state_name
