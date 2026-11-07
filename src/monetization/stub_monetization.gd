class_name StubMonetization
extends Node
## The desktop and debug stand-in for the ad and billing plugins (technical §12): consent, rewarded ads and purchases
## answer at once, as if everything succeeded. The test switches let smoke tests and the debug panel try the
## failure paths (consent refused, an ad closed early, a purchase cancelled).

signal consent_resolved(can_request_ads: bool)
signal rewarded_finished(placement: StringName, granted: bool)
signal purchase_finished(product_id: StringName, success: bool)
signal restored(product_ids: PackedStringArray)

## Answer the consent flow as if ads may be requested.
@export var consent_given := true
## Rewarded ads pay out (off: the viewer closed the ad early).
@export var grant_rewards := true
## Purchases go through (off: the player cancelled).
@export var purchases_succeed := true
## Ask for privacy options in the settings (UMP shows them only where the law requires).
@export var privacy_options_required := false

var _owned: PackedStringArray = []


func is_available() -> bool:
	return true


func start(_config: MonetizationConfig) -> void:
	pass


func gather_consent() -> void:
	consent_resolved.emit.call_deferred(consent_given)


func can_request_ads() -> bool:
	return consent_given


func needs_privacy_options() -> bool:
	return privacy_options_required


func show_privacy_options() -> void:
	gather_consent()


func show_rewarded(placement: StringName) -> void:
	rewarded_finished.emit.call_deferred(placement, grant_rewards and consent_given)


func purchase(product_id: StringName) -> void:
	if purchases_succeed and not _owned.has(String(product_id)):
		_owned.append(String(product_id))
	purchase_finished.emit.call_deferred(product_id, purchases_succeed)


func restore() -> void:
	restored.emit.call_deferred(_owned.duplicate())
