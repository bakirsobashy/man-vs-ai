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

var _weapon_text := "Pistol"
var _ammo_text := ""


func _ready() -> void:
	EventBus.player_health_changed.connect(_on_player_health_changed)
	EventBus.player_emp_changed.connect(_on_player_emp_changed)
	EventBus.player_ammo_changed.connect(_on_player_ammo_changed)
	EventBus.player_weapon_changed.connect(_on_player_weapon_changed)
	EventBus.currency_changed.connect(_on_currency_changed)
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.interact_prompt_changed.connect(_on_interact_prompt_changed)
	set_joystick_zone_top(tuning.joystick_zone_top)
	hide_stick()
	_on_currency_changed(RunState.crypto, RunState.ram_mb)


func _process(_delta: float) -> void:
	_place_edge_arrows()


func is_in_joystick_zone(at: Vector2) -> bool:
	return joystick_zone.get_global_rect().has_point(at)


func set_joystick_zone_top(ratio: float) -> void:
	joystick_zone.anchor_top = ratio


func show_stick(center: Vector2) -> void:
	joystick.scale = Vector2.ONE * (tuning.stick_radius / (joystick.size.x * 0.5))
	update_stick(center, Vector2.ZERO)
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


# --- Signals connected in hud.tscn ---

func _on_weapon_card_pressed() -> void:
	EventBus.weapon_swap_requested.emit()


func _on_prompt_bubble_pressed() -> void:
	EventBus.interact_requested.emit()
