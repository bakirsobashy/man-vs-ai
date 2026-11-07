class_name AndroidBilling
extends Node
## Cosmetic purchases on Android through the official Godot Google Play Billing plugin (2.x, Godot 4.2+). It talks
## to the plugin's GodotGooglePlayBilling singleton directly (what its BillingClient wrapper does), so the game
## compiles without the addon. Cosmetics are one-time, non-consumable products: a purchase is acknowledged on the
## client and owned from then on (technical §12). Untested until an Android build with the plugin installed: see
## docs/release/monetization_setup.md.

signal purchase_finished(product_id: StringName, success: bool)
signal restored(product_ids: PackedStringArray)

const PLUGIN := "GodotGooglePlayBilling"
## BillingClient.BillingResponseCode.OK and .ITEM_ALREADY_OWNED.
const RESPONSE_OK := 0
const RESPONSE_ALREADY_OWNED := 7
## BillingClient.PurchaseState.PURCHASED.
const STATE_PURCHASED := 1

var _billing: Object
var _product_ids: PackedStringArray = []
## The product whose purchase flow is open (Play reports purchases in batches).
var _pending := &""


func is_available() -> bool:
	return OS.get_name() == "Android" and Engine.has_singleton(PLUGIN)


func start(config: MonetizationConfig) -> void:
	_product_ids = config.product_ids
	_billing = Engine.get_singleton(PLUGIN)
	_billing.call(&"initPlugin")
	_billing.connect(&"connected", _on_connected)
	_billing.connect(&"query_purchases_response", _on_query_purchases_response)
	_billing.connect(&"on_purchase_updated", _on_purchase_updated)
	_billing.connect(&"acknowledge_purchase_response", _on_acknowledge_response)
	_billing.call(&"startConnection")


func purchase(product_id: StringName) -> void:
	if _billing == null or not bool(_billing.call(&"isReady")):
		purchase_finished.emit.call_deferred(product_id, false)
		return
	_pending = product_id
	var result: Dictionary = _billing.call(&"purchase", String(product_id), "", "", false)
	if int(result.get("response_code", -1)) == RESPONSE_ALREADY_OWNED:
		restore()
		purchase_finished.emit.call_deferred(product_id, true)
	elif int(result.get("response_code", -1)) != RESPONSE_OK:
		_pending = &""
		purchase_finished.emit.call_deferred(product_id, false)


func restore() -> void:
	if _billing != null and bool(_billing.call(&"isReady")):
		_billing.call(&"queryPurchases", "inapp", false)


func _on_connected() -> void:
	# Product details must be queried before purchase() works.
	_billing.call(&"queryProductDetails", _product_ids, "inapp")
	restore()


func _on_query_purchases_response(response: Dictionary) -> void:
	if int(response.get("response_code", -1)) != RESPONSE_OK:
		return
	var owned: PackedStringArray = []
	for purchase_data: Dictionary in response.get("purchases", []):
		if int(purchase_data.get("purchase_state", 0)) != STATE_PURCHASED:
			continue
		_acknowledge(purchase_data)
		for product: String in purchase_data.get("product_ids", []):
			owned.append(product)
	restored.emit(owned)


func _on_purchase_updated(response: Dictionary) -> void:
	var product := _pending
	_pending = &""
	if int(response.get("response_code", -1)) != RESPONSE_OK:
		if product != &"":
			purchase_finished.emit(product, false)
		return
	for purchase_data: Dictionary in response.get("purchases", []):
		# A pending purchase (paid later) isn't granted until it's PURCHASED; Restore picks it up then.
		if int(purchase_data.get("purchase_state", 0)) != STATE_PURCHASED:
			continue
		_acknowledge(purchase_data)
		for bought: String in purchase_data.get("product_ids", []):
			purchase_finished.emit(StringName(bought), true)


func _acknowledge(purchase_data: Dictionary) -> void:
	if not bool(purchase_data.get("is_acknowledged", false)):
		_billing.call(&"acknowledgePurchase", String(purchase_data.get("purchase_token", "")))


func _on_acknowledge_response(_response: Dictionary) -> void:
	pass
