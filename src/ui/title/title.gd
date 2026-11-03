class_name TitleScreen
extends Control
## The title screen (the main scene): Play opens the three save slots (GDD §2.3). The slot cards' signals are
## connected in title.tscn.

@onready var slot_panel: Control = %SlotPanel
@onready var cards: Array[SlotCard] = [%Slot1, %Slot2, %Slot3]


func _ready() -> void:
	get_tree().paused = false
	GameState.slot = 0
	RunState.end_run()
	for card: SlotCard in cards:
		card.refresh()


func _on_play_pressed() -> void:
	for card: SlotCard in cards:
		card.refresh()
	slot_panel.visible = true


func _on_back_pressed() -> void:
	slot_panel.visible = false


func _on_slot_chosen(slot: int) -> void:
	if SceneRouter.busy:
		return
	SaveManager.load_slot(slot)
	SceneRouter.enter_slot()


func _on_slot_delete_requested(slot: int) -> void:
	SaveManager.delete_slot(slot)
	for card: SlotCard in cards:
		card.refresh()
