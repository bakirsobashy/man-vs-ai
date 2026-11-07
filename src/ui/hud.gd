class_name Hud
extends CanvasLayer
## The in-game HUD. The layout is authored in hud.tscn; this script fills in values and moves the stick graphic.
## The joystick zone IS the JoystickZone node: resize it in the editor to change the zone.

## Shared controls tuning (stick size, zone top, show stick).
@export var tuning: ControlsTuning
@export var heart_full: Texture2D
@export var heart_half: Texture2D
@export var heart_empty: Texture2D
## Off-screen enemy arrows stay this far inside the screen edges (top: below the top band).
@export_range(0.0, 64.0, 1.0, "suffix:px") var arrow_margin := 10.0
@export_range(0.0, 160.0, 1.0, "suffix:px") var arrow_margin_top := 60.0
## Levels show the minimap; the lab and tutorial hide it.
@export var show_minimap := true

@onready var joystick_zone: Control = %JoystickZone
@onready var joystick: Control = %Joystick
@onready var knob: Control = %Knob
@onready var hearts_box: Control = %Hearts
@onready var armor_box: Control = %Armor
@onready var emp_label: Label = %EmpLabel
@onready var crypto_label: Label = %CryptoLabel
@onready var ram_label: Label = %RamLabel
@onready var weapon_card: Button = %WeaponCard
@onready var prompt_bubble: Button = %PromptBubble
@onready var wave_label: Label = %WaveLabel
@onready var wave_animation: AnimationPlayer = %WaveAnimation
@onready var edge_arrows: Control = %EdgeArrows
@onready var touch_path: Line2D = %TouchPath
@onready var full_map: Control = %FullMap
@onready var shop_panel: Control = %ShopPanel
@onready var shop_info: Label = %ShopInfo
@onready var shop_buttons: Array[Button] = [%BuyHeart, %BuyArmor, %BuyEmp, %BuyAmmo]
@onready var memory_panel: Control = %MemoryPanel
@onready var memory_title: Label = %MemoryTitle
@onready var memory_body: Label = %MemoryBody
@onready var toast_label: Label = %ToastLabel
@onready var toast_animation: AnimationPlayer = %ToastAnimation
@onready var boss_bar: ProgressBar = %BossBar
@onready var minimap_button: Button = %MinimapButton
@onready var pause_panel: Control = %PausePanel
@onready var music_slider: Range = %MusicSlider
@onready var sfx_slider: Range = %SfxSlider
@onready var haptics_check: CheckButton = %HapticsCheck
@onready var flashing_check: CheckButton = %FlashingCheck
@onready var glitch_animation: AnimationPlayer = %GlitchAnimation
@onready var summary_panel: Control = %SummaryPanel
@onready var summary_title: Label = %SummaryTitle
@onready var summary_stats: Label = %SummaryStats
## M6 rewarded ads: the Salvage bonus on the run summary, and the Second Chance offer after a death.
@onready var salvage_button: Button = %SalvageButton
@onready var second_chance_panel: Control = %SecondChancePanel

## Crypto the Salvage ad would add to this summary (0 once it's used).
var salvage_amount := 0
var _weapon_text := "Pistol"
var _ammo_text := ""
var _station: RepairStation


func _ready() -> void:
	EventBus.player_health_changed.connect(_on_player_health_changed)
	EventBus.player_emp_changed.connect(_on_player_emp_changed)
	EventBus.player_ammo_changed.connect(_on_player_ammo_changed)
	EventBus.player_weapon_changed.connect(_on_player_weapon_changed)
	EventBus.currency_changed.connect(_on_currency_changed)
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.interact_prompt_changed.connect(_on_interact_prompt_changed)
	EventBus.banner_requested.connect(_on_banner_requested)
	EventBus.toast_requested.connect(_on_toast_requested)
	EventBus.boss_health_changed.connect(_on_boss_health_changed)
	EventBus.shop_opened.connect(_on_shop_opened)
	EventBus.memory_opened.connect(_on_memory_opened)
	EventBus.run_summary_requested.connect(_on_run_summary_requested)
	EventBus.second_chance_offered.connect(_on_second_chance_offered)
	EventBus.rewarded_ad_finished.connect(_on_rewarded_ad_finished)
	EventBus.screen_glitch_requested.connect(_on_screen_glitch_requested)
	minimap_button.visible = show_minimap
	set_joystick_zone_top(tuning.joystick_zone_top)
	hide_stick()
	_on_currency_changed(GameState.crypto, GameState.ram_mb)
	music_slider.set_value_no_signal(SaveManager.music_volume)
	sfx_slider.set_value_no_signal(SaveManager.sfx_volume)
	haptics_check.set_pressed_no_signal(SaveManager.haptics)
	flashing_check.set_pressed_no_signal(SaveManager.reduced_flashing)


func _process(_delta: float) -> void:
	_place_edge_arrows()


func is_in_joystick_zone(at: Vector2) -> bool:
	return joystick_zone.get_global_rect().has_point(at)


func set_joystick_zone_top(ratio: float) -> void:
	joystick_zone.anchor_top = ratio


func show_stick(center: Vector2) -> void:
	joystick.scale = Vector2.ONE * (tuning.stick_radius / (joystick.size.x * 0.5))
	update_stick(center, Vector2.ZERO)
	joystick.modulate.a = SaveManager.stick_opacity
	joystick.visible = tuning.show_joystick


func update_stick(center: Vector2, offset: Vector2) -> void:
	var stick_scale := joystick.scale.x
	joystick.position = center - joystick.size * 0.5 * stick_scale
	knob.position = (joystick.size - knob.size) * 0.5 + offset / stick_scale


func hide_stick() -> void:
	joystick.visible = false


func begin_touch_path(at: Vector2) -> void:
	touch_path.clear_points()
	touch_path.add_point(at)


func add_touch_path_point(at: Vector2) -> void:
	if touch_path.visible:
		touch_path.add_point(at)


## Arrows at the screen edge pointing at enemies that are off screen (pre-placed Arrow nodes).
func _place_edge_arrows() -> void:
	var arrows := edge_arrows.get_children()
	var screen := get_viewport().get_visible_rect()
	var inner := Rect2(screen.position + Vector2(arrow_margin, arrow_margin_top),
		screen.size - Vector2(arrow_margin * 2.0, arrow_margin_top + arrow_margin))
	var to_screen := get_viewport().get_canvas_transform()
	var used := 0
	for node: Node in get_tree().get_nodes_in_group(&"enemies"):
		var enemy := node as Node2D
		if used >= arrows.size():
			break
		if enemy == null or not enemy.is_visible_in_tree():
			continue
		var at := to_screen * enemy.global_position
		if screen.has_point(at):
			continue
		var arrow := arrows[used] as Control
		var clamped := at.clamp(inner.position, inner.end)
		arrow.position = clamped - arrow.size * 0.5
		arrow.rotation = (at - clamped).angle()
		arrow.visible = true
		used += 1
	for i: int in range(used, arrows.size()):
		(arrows[i] as Control).visible = false


func _refresh_weapon_card() -> void:
	weapon_card.text = "%s  %s" % [_weapon_text, _ammo_text]


func _on_player_health_changed(hp: int, max_hp: int, armor: int) -> void:
	var hearts := hearts_box.get_children()
	for i: int in hearts.size():
		var heart := hearts[i] as TextureRect
		var half_hearts := hp - i * 2
		heart.visible = i * 2 < max_hp
		heart.texture = heart_full if half_hearts >= 2 else (heart_half if half_hearts == 1 else heart_empty)
	var pips := armor_box.get_children()
	for i: int in pips.size():
		(pips[i] as Control).visible = i < armor


func _on_player_emp_changed(charges: int) -> void:
	emp_label.text = "EMP %d" % charges


func _on_player_weapon_changed(display_name: String, slot: int, slots: int) -> void:
	_weapon_text = display_name if slots == 1 else "[%d/2] %s" % [slot, display_name]
	_refresh_weapon_card()


func _on_player_ammo_changed(magazine: int, magazine_size: int, reserve: int, reloading: bool) -> void:
	_ammo_text = "%d/%d" % [magazine, magazine_size]
	if reserve >= 0:
		_ammo_text += " +%d" % reserve
	if reloading:
		_ammo_text += " RLD"
	_refresh_weapon_card()


func _on_currency_changed(crypto: int, ram_mb: int) -> void:
	crypto_label.text = str(crypto)
	ram_label.text = "%d MB" % ram_mb


func _on_wave_started(wave: int, _threat: float) -> void:
	wave_label.text = "WAVE %d" % wave
	wave_animation.stop()
	wave_animation.play(&"banner")


func _on_interact_prompt_changed(text: String) -> void:
	prompt_bubble.text = text
	prompt_bubble.visible = text != ""


## Panels pause the game while they're open (the HUD itself keeps running).
func _set_panel(panel: Control, open: bool) -> void:
	panel.visible = open
	get_tree().paused = full_map.visible or shop_panel.visible or memory_panel.visible or pause_panel.visible


func _refresh_shop() -> void:
	if _station == null:
		return
	var labels: Array[String] = ["+1/2 heart", "+1 armor", "+1 EMP", "Refill ammo"]
	for i: int in shop_buttons.size():
		shop_buttons[i].text = "%s — %d Crypto" % [labels[i], _station.price(i as RepairStation.Item)]
		shop_buttons[i].disabled = _station.purchases_left <= 0
	shop_info.text = "%d purchases left · you have %d Crypto" % [_station.purchases_left, GameState.crypto]


func _buy(item: RepairStation.Item) -> void:
	var hero := get_tree().get_first_node_in_group(&"player") as Player
	if _station == null or hero == null:
		return
	_on_toast_requested(_station.buy(item, hero))
	_refresh_shop()


func _on_banner_requested(text: String) -> void:
	wave_label.text = text
	wave_animation.stop()
	wave_animation.play(&"banner")


func _on_toast_requested(text: String) -> void:
	toast_label.text = text
	toast_animation.stop()
	toast_animation.play(&"toast")


func _on_boss_health_changed(hp: int, max_hp: int) -> void:
	boss_bar.max_value = max_hp
	boss_bar.value = hp
	boss_bar.visible = hp > 0


func _on_run_summary_requested(title: String, summary: String) -> void:
	summary_title.text = title
	summary_stats.text = summary
	summary_panel.visible = true
	salvage_amount = ceili(RunState.crypto_earned * Monetization.config.salvage_share)
	salvage_button.text = "Watch an ad: salvage +%d Crypto" % salvage_amount
	salvage_button.disabled = false
	salvage_button.visible = salvage_amount > 0 and Monetization.can_show_ads()


func _on_salvage_button_pressed() -> void:
	salvage_button.disabled = true
	Monetization.show_rewarded(&"salvage")


func _on_second_chance_offered() -> void:
	second_chance_panel.visible = true


func _on_second_chance_watch_pressed() -> void:
	second_chance_panel.visible = false
	EventBus.second_chance_answered.emit(true)


func _on_second_chance_decline_pressed() -> void:
	second_chance_panel.visible = false
	EventBus.second_chance_answered.emit(false)


## Salvage pays out once per summary; a failed ad leaves the button for another try.
func _on_rewarded_ad_finished(placement: StringName, granted: bool) -> void:
	if placement != &"salvage":
		return
	if not granted:
		salvage_button.disabled = false
		return
	GameState.add_crypto(salvage_amount)
	SaveManager.save_slot()
	summary_stats.text += "\nSalvaged +%d Crypto" % salvage_amount
	salvage_amount = 0
	salvage_button.visible = false


func _on_shop_opened(station: Node) -> void:
	_station = station as RepairStation
	_refresh_shop()
	_set_panel(shop_panel, true)


func _on_memory_opened(title: String, text: String) -> void:
	memory_title.text = title
	memory_body.text = text
	_set_panel(memory_panel, true)


# --- Signals connected in hud.tscn ---

func _on_minimap_button_pressed() -> void:
	_set_panel(full_map, true)


func _on_full_map_close_pressed() -> void:
	_set_panel(full_map, false)


func _on_shop_close_pressed() -> void:
	_station = null
	_set_panel(shop_panel, false)


func _on_memory_close_pressed() -> void:
	_set_panel(memory_panel, false)


func _on_buy_heart_pressed() -> void:
	_buy(RepairStation.Item.HALF_HEART)


func _on_buy_armor_pressed() -> void:
	_buy(RepairStation.Item.ARMOR)


func _on_buy_emp_pressed() -> void:
	_buy(RepairStation.Item.EMP_CHARGE)


func _on_buy_ammo_pressed() -> void:
	_buy(RepairStation.Item.AMMO)


func _on_pause_button_pressed() -> void:
	_set_panel(pause_panel, true)


func _on_resume_pressed() -> void:
	_set_panel(pause_panel, false)


func _on_music_slider_value_changed(value: float) -> void:
	SaveManager.music_volume = value
	SaveManager.apply_settings()
	SaveManager.save_settings()


func _on_sfx_slider_value_changed(value: float) -> void:
	SaveManager.sfx_volume = value
	SaveManager.apply_settings()
	SaveManager.save_settings()


func _on_flashing_check_toggled(on: bool) -> void:
	SaveManager.reduced_flashing = on
	SaveManager.save_settings()


func _on_screen_glitch_requested() -> void:
	glitch_animation.stop()
	glitch_animation.play(&"glitch_soft" if SaveManager.reduced_flashing else &"glitch")


func _on_haptics_check_toggled(on: bool) -> void:
	SaveManager.haptics = on
	SaveManager.save_settings()


## Saves and goes back to the title. A run in progress can be continued from its slot.
func _on_quit_pressed() -> void:
	SaveManager.save_all()
	SceneRouter.go_to(SceneRouter.title_scene)


func _on_summary_button_pressed() -> void:
	summary_panel.visible = false
	EventBus.summary_closed.emit()


func _on_weapon_card_pressed() -> void:
	EventBus.weapon_swap_requested.emit()


func _on_prompt_bubble_pressed() -> void:
	EventBus.interact_requested.emit()


## The pause menu's "More settings": the full settings screen (shared settings_panel.tscn).
func _on_settings_button_pressed() -> void:
	(%SettingsPanel as SettingsPanel).open()
