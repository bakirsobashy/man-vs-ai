class_name AndroidAds
extends Node
## Rewarded ads and consent on Android through the Poing Studios AdMob plugin for Godot 4 (GDScript addon plus the
## Android singletons PoingGodotAdMob, PoingGodotAdMobRewardedAd, PoingGodotAdMobConsentInformation and
## PoingGodotAdMobUserMessagingPlatform). The singletons are called directly, so the game compiles without the addon.
## Untested until an Android build with the plugin installed: see docs/release/monetization_setup.md.
## Flow: UMP consent update → consent form if required → MobileAds.initialize → preload one rewarded ad.

signal consent_resolved(can_request_ads: bool)
signal rewarded_finished(placement: StringName, granted: bool)

## UMP ConsentInformation.ConsentStatus.
enum ConsentStatus { UNKNOWN, NOT_REQUIRED, REQUIRED, OBTAINED }
## UMP ConsentInformation.PrivacyOptionsRequirementStatus.
enum PrivacyStatus { UNKNOWN, NOT_REQUIRED, REQUIRED }

const ADS := "PoingGodotAdMob"
const REWARDED := "PoingGodotAdMobRewardedAd"
const CONSENT := "PoingGodotAdMobConsentInformation"
const UMP := "PoingGodotAdMobUserMessagingPlatform"

var _config: MonetizationConfig
var _initialized := false
## The loaded rewarded ad's plugin id (-1 = none loaded), and the one being shown.
var _ad_uid := -1
var _loading := false
var _showing_placement := &""
var _earned := false


func is_available() -> bool:
	return OS.get_name() == "Android" and Engine.has_singleton(ADS) and Engine.has_singleton(REWARDED) \
		and Engine.has_singleton(CONSENT) and Engine.has_singleton(UMP)


func start(config: MonetizationConfig) -> void:
	_config = config
	var rewarded := Engine.get_singleton(REWARDED)
	rewarded.connect(&"on_rewarded_ad_loaded", _on_rewarded_loaded)
	rewarded.connect(&"on_rewarded_ad_failed_to_load", _on_rewarded_failed_to_load)
	rewarded.connect(&"on_rewarded_ad_user_earned_reward", _on_user_earned_reward)
	rewarded.connect(&"on_rewarded_ad_dismissed_full_screen_content", _on_rewarded_closed)
	rewarded.connect(&"on_rewarded_ad_failed_to_show_full_screen_content", _on_rewarded_failed_to_show)


## Runs the UMP flow: update the consent info, show the form when it's required, then start the ads SDK.
func gather_consent() -> void:
	var consent := Engine.get_singleton(CONSENT)
	if not consent.is_connected(&"on_consent_info_updated_success", _on_consent_updated):
		consent.connect(&"on_consent_info_updated_success", _on_consent_updated)
		consent.connect(&"on_consent_info_updated_failure", _on_consent_failed)
	consent.call(&"update", {"tag_for_under_age_of_consent": _config.tag_for_under_age_of_consent, "consent_debug_settings": null})


func can_request_ads() -> bool:
	var status := int(Engine.get_singleton(CONSENT).call(&"get_consent_status"))
	return status == ConsentStatus.OBTAINED or status == ConsentStatus.NOT_REQUIRED


func needs_privacy_options() -> bool:
	return int(Engine.get_singleton(CONSENT).call(&"get_privacy_options_requirement_status")) == PrivacyStatus.REQUIRED


func show_privacy_options() -> void:
	var ump := Engine.get_singleton(UMP)
	if not ump.is_connected(&"on_privacy_options_form_dismissed_listener", _on_privacy_dismissed):
		ump.connect(&"on_privacy_options_form_dismissed_listener", _on_privacy_dismissed)
	ump.call(&"show_privacy_options_form")


func show_rewarded(placement: StringName) -> void:
	if _ad_uid < 0 or not can_request_ads():
		rewarded_finished.emit.call_deferred(placement, false)
		_load_rewarded()
		return
	_showing_placement = placement
	_earned = false
	Engine.get_singleton(REWARDED).call(&"show", _ad_uid)


func _on_consent_updated() -> void:
	var consent := Engine.get_singleton(CONSENT)
	var form_available := bool(consent.call(&"get_is_consent_form_available"))
	if form_available and int(consent.call(&"get_consent_status")) == ConsentStatus.REQUIRED:
		var ump := Engine.get_singleton(UMP)
		if not ump.is_connected(&"on_consent_form_load_success_listener", _on_form_loaded):
			ump.connect(&"on_consent_form_load_success_listener", _on_form_loaded)
			ump.connect(&"on_consent_form_load_failure_listener", _on_form_failed)
			ump.connect(&"on_consent_form_dismissed", _on_form_dismissed)
		ump.call(&"load_consent_form")
	else:
		_finish_consent()


func _on_consent_failed(_form_error: Dictionary) -> void:
	_finish_consent()


func _on_form_loaded(uid: int) -> void:
	Engine.get_singleton(UMP).call(&"show", uid)


func _on_form_failed(_form_error: Dictionary) -> void:
	_finish_consent()


func _on_form_dismissed(_uid: int, _form_error: Dictionary) -> void:
	_finish_consent()


func _on_privacy_dismissed(_form_error: Dictionary) -> void:
	_finish_consent()


func _finish_consent() -> void:
	var allowed := can_request_ads()
	if allowed and not _initialized:
		_initialized = true
		Engine.get_singleton(ADS).call(&"initialize")
		_load_rewarded()
	consent_resolved.emit(allowed)


func _load_rewarded() -> void:
	if _loading or _ad_uid >= 0 or not _initialized or not can_request_ads():
		return
	_loading = true
	var rewarded := Engine.get_singleton(REWARDED)
	var uid := int(rewarded.call(&"create"))
	var request := {"mediation_extras": {}, "extras": {}, "google_request_agent": "Godot-PoingStudios"}
	rewarded.call(&"load", _config.rewarded_ad_unit_android, request, PackedStringArray(), uid)


func _on_rewarded_loaded(uid: int) -> void:
	_loading = false
	_ad_uid = uid


func _on_rewarded_failed_to_load(_uid: int, _error: Dictionary) -> void:
	_loading = false
	_ad_uid = -1


func _on_user_earned_reward(uid: int, _reward: Dictionary) -> void:
	if uid == _ad_uid:
		_earned = true


func _on_rewarded_closed(uid: int) -> void:
	if uid != _ad_uid:
		return
	Engine.get_singleton(REWARDED).call(&"destroy", uid)
	_ad_uid = -1
	rewarded_finished.emit(_showing_placement, _earned)
	_load_rewarded()


func _on_rewarded_failed_to_show(uid: int, _error: Dictionary) -> void:
	if uid != _ad_uid:
		return
	_ad_uid = -1
	rewarded_finished.emit(_showing_placement, false)
	_load_rewarded()
