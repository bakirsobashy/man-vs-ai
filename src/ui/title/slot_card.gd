class_name SlotCard
extends PanelContainer
## One save slot on the title screen (three pre-placed in title.tscn). Shows the slot's summary; Play loads it,
## Delete needs a second tap within the ConfirmTimer's wait. Its buttons are connected in slot_card.tscn.

signal chosen(slot: int)
signal delete_requested(slot: int)

@export_range(1, 3) var slot := 1

@onready var title_label: Label = %TitleLabel
@onready var info_label: Label = %InfoLabel
@onready var play_button: Button = %PlayButton
@onready var delete_button: Button = %DeleteButton
@onready var confirm_timer: Timer = %ConfirmTimer


func refresh() -> void:
	var summary := SaveManager.slot_summary(slot)
	title_label.text = "SLOT %d" % slot
	delete_button.visible = not summary.is_empty()
	delete_button.text = "Delete"
	confirm_timer.stop()
	if summary.is_empty():
		info_label.text = "Empty"
		play_button.text = "New story"
		return
	var minutes := int(summary["playtime_s"]) / 60
	info_label.text = "Best level %d · %d runs · implants %d/6 · %dh %02dm" % [
		summary["best_level"], summary["runs"], summary["filled_slots"], minutes / 60, minutes % 60]
	play_button.text = "Continue run" if summary["has_run"] else "Continue"


func _on_play_button_pressed() -> void:
	chosen.emit(slot)


func _on_delete_button_pressed() -> void:
	if confirm_timer.is_stopped():
		delete_button.text = "Tap again to delete"
		confirm_timer.start()
		return
	delete_requested.emit(slot)


func _on_confirm_timer_timeout() -> void:
	delete_button.text = "Delete"
