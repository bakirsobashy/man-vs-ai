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
	title_label.text = tr("slot.title") % slot
	delete_button.visible = not summary.is_empty()
	delete_button.text = tr("slot.delete")
	confirm_timer.stop()
	if summary.is_empty():
		info_label.text = tr("slot.empty")
		play_button.text = tr("slot.new_story")
		return
	var minutes := int(summary["playtime_s"]) / 60
	info_label.text = tr("slot.info") % [
		summary["best_level"], summary["runs"], summary["filled_slots"], minutes / 60, minutes % 60]
	if int(summary.get("endings", 0)) > 0:
		info_label.text += " · " + tr("slot.endings") % int(summary["endings"])
	play_button.text = tr("slot.continue_run") if summary["has_run"] else tr("slot.continue")


func _on_play_button_pressed() -> void:
	chosen.emit(slot)


func _on_delete_button_pressed() -> void:
	if confirm_timer.is_stopped():
		delete_button.text = tr("slot.confirm_delete")
		confirm_timer.start()
		return
	delete_requested.emit(slot)


func _on_confirm_timer_timeout() -> void:
	delete_button.text = tr("slot.delete")
