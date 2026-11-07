extends Node
## Ads and purchases behind one interface (autoload scene "Monetization", monetization.tscn; GDD §9, technical §12).
## On Android with the plugins installed it uses the %AndroidAds and %AndroidBilling bridges; everywhere else (the
## desktop, the editor, tests, or an Android build without the plugins) the %Stub, which grants everything at once.
## No ad is requested before the consent flow has run (gather_consent at the title screen) and allowed it.
## Results go out through EventBus: consent_resolved, rewarded_ad_finished, purchase_finished, purchases_restored.
## Every provider's signals are connected in the scene; only the providers in use ever emit.
## Owned products are kept in user://purchases.cfg (SaveManager.save_dir) so they survive offline starts; on Android
## the Play Store's list replaces it whenever it's read (refunds remove items).

@export var config: MonetizationConfig

@onready var stub: StubMonetization = %Stub
@onready var android_ads: AndroidAds = %AndroidAds
@onready var android_billing: AndroidBilling = %AndroidBilling

## True once the consent flow has finished this session (whatever the answer).
var consent_gathered := false
## Placements used per run or per summary are tracked by their callers (RunState, the HUD).
var owned: PackedStringArray = []
var _ads: Node
var _billing: Node


func _ready() -> void:
	var real_ads := not config.force_stub and android_ads.is_available()
	var real_billing := not config.force_stub and android_billing.is_available()
	_ads = android_ads if real_ads else stub
	_billing = android_billing if real_billing else stub
	_ads.call(&"start", config)
	if _billing != _ads:
		_billing.call(&"start", config)
	load_owned()


## True when the real plugins run this session (Android with the plugins installed).
func uses_store() -> bool:
	return _billing == android_billing


## Runs the consent flow (UMP on Android). Call once per session before any ad; the title screen does.
func gather_consent() -> void:
	_ads.call(&"gather_consent")


## Ads may be requested: consent was gathered and allowed them.
func can_show_ads() -> bool:
	return consent_gathered and bool(_ads.call(&"can_request_ads"))


## UMP asks for a "Privacy options" entry point in the settings where the law requires one.
func needs_privacy_options() -> bool:
	return bool(_ads.call(&"needs_privacy_options"))


func show_privacy_options() -> void:
	_ads.call(&"show_privacy_options")


## Shows a rewarded ad for `placement` (&"second_chance", &"salvage"). The answer comes through
## EventBus.rewarded_ad_finished; without consent it's refused at once.
func show_rewarded(placement: StringName) -> void:
	if not can_show_ads():
		EventBus.rewarded_ad_finished.emit.call_deferred(placement, false)
		return
	_ads.call(&"show_rewarded", placement)


func purchase(product_id: StringName) -> void:
	_billing.call(&"purchase", product_id)


func owns(product_id: StringName) -> bool:
	return owned.has(String(product_id))


func restore_purchases() -> void:
	_billing.call(&"restore")


func load_owned() -> void:
	var file := ConfigFile.new()
	owned = PackedStringArray()
	if file.load(_owned_path()) == OK:
		owned = PackedStringArray(file.get_value("purchases", "owned", PackedStringArray()))


func _save_owned() -> void:
	var file := ConfigFile.new()
	file.set_value("purchases", "owned", owned)
	DirAccess.make_dir_recursive_absolute(SaveManager.save_dir)
	file.save(_owned_path())


func _owned_path() -> String:
	return SaveManager.save_dir.path_join("purchases.cfg")


func _on_consent_resolved(can_request_ads: bool) -> void:
	consent_gathered = true
	EventBus.consent_resolved.emit(can_request_ads)


func _on_rewarded_finished(placement: StringName, granted: bool) -> void:
	EventBus.rewarded_ad_finished.emit(placement, granted)


func _on_purchase_finished(product_id: StringName, success: bool) -> void:
	if success and not owns(product_id):
		owned.append(String(product_id))
		_save_owned()
	EventBus.purchase_finished.emit(product_id, success)


func _on_restored(product_ids: PackedStringArray) -> void:
	if uses_store():
		owned = product_ids.duplicate()
	else:
		for product: String in product_ids:
			if not owned.has(product):
				owned.append(product)
	_save_owned()
	EventBus.purchases_restored.emit()
