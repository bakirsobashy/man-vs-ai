extends Node
## The M6 smoke test (started by tools/smoke_test_m6.gd): monetization through the desktop stub (consent gating,
## rewarded ads, purchases and restore), Second Chance and the Salvage bonus in real levels.
## Save files go to user://test_saves_m6/ so a player's real slots and purchases are never touched.

const TEST_DIR := "user://test_saves_m6/"
const LEVEL_PATH := "res://src/levels/level.tscn"
const LAB_PATH := "res://src/hub/lab.tscn"
const COSMETICS := "res://data/cosmetics/catalog.tres"

var _failures := 0
var _rewards: Array[String] = []
var _purchases: Array[String] = []
var _consents: Array[bool] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	SaveManager.save_dir = TEST_DIR
	_clear_test_dir()
	EventBus.rewarded_ad_finished.connect(func(placement: StringName, granted: bool) -> void: _rewards.append("%s:%s" % [placement, granted]))
	EventBus.purchase_finished.connect(func(product: StringName, success: bool) -> void: _purchases.append("%s:%s" % [product, success]))
	EventBus.consent_resolved.connect(func(allowed: bool) -> void: _consents.append(allowed))
	await _test_monetization()
	await _test_second_chance()
	await _test_salvage()
	await _test_no_consent()
	await _test_final_boss()
	await _test_cosmetics_shop()
	await _test_cosmetics_in_play()
	await _test_settings()
	await _test_settings_panel()
	_reset_settings()
	_reset_stub()
	Monetization.owned = PackedStringArray()
	_clear_test_dir()
	print("M6 smoke test finished: %d failure(s)" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _test_monetization() -> void:
	_check(not Monetization.uses_store() and not Monetization.android_ads.is_available() and not Monetization.android_billing.is_available(),
		"on the desktop the stub stands in for the AdMob and Play Billing plugins")
	_check(Monetization.config.rewarded_ad_unit_android.begins_with("ca-app-pub-3940256099942544/") and Monetization.config.test_ads,
		"the config ships with Google's test ad unit and test ads on")
	_check(not Monetization.consent_gathered and not Monetization.can_show_ads(), "no ads before the consent flow has run")
	_rewards.clear()
	Monetization.show_rewarded(&"salvage")
	await _frames(2)
	_check(_rewards == ["salvage:false"], "an ad requested before consent is refused")
	Monetization.gather_consent()
	await _frames(2)
	_check(_consents == [true] and Monetization.can_show_ads(), "consent allows ads (EventBus.consent_resolved)")
	_rewards.clear()
	Monetization.show_rewarded(&"salvage")
	await _frames(2)
	Monetization.stub.grant_rewards = false
	Monetization.show_rewarded(&"salvage")
	await _frames(2)
	_check(_rewards == ["salvage:true", "salvage:false"], "a watched ad grants the reward; one closed early doesn't")
	_reset_stub()

	_purchases.clear()
	Monetization.purchase(&"outfit_test")
	await _frames(2)
	_check(_purchases == ["outfit_test:true"] and Monetization.owns(&"outfit_test"), "a purchase makes the product owned")
	Monetization.owned = PackedStringArray()
	Monetization.load_owned()
	_check(Monetization.owns(&"outfit_test"), "owned products are saved (purchases.cfg) and load back")
	Monetization.stub.purchases_succeed = false
	Monetization.purchase(&"outfit_cancelled")
	await _frames(2)
	_check(not Monetization.owns(&"outfit_cancelled") and _purchases.back() == "outfit_cancelled:false", "a cancelled purchase grants nothing")
	_reset_stub()
	var restored := [false]
	EventBus.purchases_restored.connect(func() -> void: restored[0] = true, CONNECT_ONE_SHOT)
	Monetization.restore_purchases()
	await _frames(2)
	_check(restored[0] and Monetization.owns(&"outfit_test"), "Restore purchases keeps what's owned")


func _test_second_chance() -> void:
	var level := await _load_level(1, 61)
	var director := level.get_node(^"LevelDirector") as LevelDirector
	var player := level.get_node(^"Player") as Player
	var hud := level.get_node(^"HUD") as Hud
	var emp := player.emp_charges
	await _die(player)
	_check(hud.second_chance_panel.visible and get_tree().paused and director.can_offer_second_chance(),
		"after a death, Second Chance is offered and the game pauses")
	var enemy_bullets := _pool(level, "enemy_bullet_small")
	enemy_bullets.spawn(player.global_position + Vector2(0, -30), Vector2.DOWN)
	hud._on_second_chance_watch_pressed()
	await _frames(3)
	_check(not get_tree().paused and player.state_machine.is_in(&"Stand") and player.health.hp == 2 and player.health.is_invulnerable(),
		"watching the ad revives the hero with 1 heart, briefly invulnerable")
	_check(player.emp_charges == emp and enemy_bullets.active_count == 0, "and a free EMP clears the bullets around him")
	_check(RunState.second_chance_used and RunState.active and not hud.summary_panel.visible, "the run goes on; Second Chance is used up")
	var saved := RunState.to_dict()
	_check(bool(saved.get("second_chance_used", false)), "and a saved run remembers it")
	await _die(player)
	_check(not hud.second_chance_panel.visible and hud.summary_panel.visible and not get_tree().paused, "the next death goes straight to the summary")
	level.queue_free()
	await _wait(0.3)


func _test_salvage() -> void:
	var level := await _load_level(1, 62)
	var player := level.get_node(^"Player") as Player
	var hud := level.get_node(^"HUD") as Hud
	RunState.second_chance_used = true
	RunState.crypto_earned = 40
	var crypto := GameState.crypto
	await _die(player)
	_check(hud.summary_panel.visible and hud.salvage_button.visible and hud.salvage_button.text.contains("+10"),
		"the summary offers Salvage: +25% of the run's 40 Crypto")
	hud._on_salvage_button_pressed()
	await _frames(3)
	_check(GameState.crypto == crypto + 10 and not hud.salvage_button.visible and hud.summary_stats.text.contains("Salvaged +10"),
		"watching it adds 10 Crypto, once")
	level.queue_free()
	await _wait(0.3)


func _test_no_consent() -> void:
	Monetization.stub.consent_given = false
	Monetization.gather_consent()
	await _frames(2)
	var level := await _load_level(1, 63)
	var player := level.get_node(^"Player") as Player
	var hud := level.get_node(^"HUD") as Hud
	RunState.crypto_earned = 40
	await _die(player)
	_check(not hud.second_chance_panel.visible and hud.summary_panel.visible and not hud.salvage_button.visible,
		"without consent there's no Second Chance and no Salvage")
	level.queue_free()
	await _wait(0.3)
	_reset_stub()
	Monetization.gather_consent()
	await _frames(2)

	level = await _load_level(1, 64)
	player = level.get_node(^"Player") as Player
	hud = level.get_node(^"HUD") as Hud
	Monetization.stub.grant_rewards = false
	await _die(player)
	hud._on_second_chance_watch_pressed()
	await _frames(3)
	_check(not RunState.second_chance_used and hud.summary_panel.visible and not get_tree().paused,
		"an ad closed early doesn't revive: the summary follows")
	_reset_stub()
	level.queue_free()
	await _wait(0.3)


func _test_final_boss() -> void:
	var level := await _load_level(5, 65)
	var director := level.get_node(^"LevelDirector") as LevelDirector
	var player := level.get_node(^"Player") as Player
	var hud := level.get_node(^"HUD") as Hud
	director.enter_room(director.layout.boss_id, Vector2i.ZERO)
	await _wait(0.6)
	await _die(player)
	_check(not hud.second_chance_panel.visible and hud.summary_panel.visible, "there's no Second Chance against ZERO (Q9)")
	level.queue_free()
	await _wait(0.3)


func _test_cosmetics_shop() -> void:
	var catalog := load(COSMETICS) as CosmeticCatalog
	var kinds_ok := true
	for kind: int in [CosmeticData.Kind.OUTFIT, CosmeticData.Kind.WEAPON_SKIN, CosmeticData.Kind.LAB_DECOR, CosmeticData.Kind.EMP_STYLE]:
		kinds_ok = kinds_ok and catalog.items_of(kind).size() >= 3
	_check(kinds_ok and catalog.product_ids().size() == 12 and Monetization.config.product_ids == catalog.product_ids(),
		"the catalog has outfits, weapon skins, lab decorations and EMP styles; their product IDs go to the store")
	GameState.reset_to_new()
	_check(catalog.equipped(CosmeticData.Kind.OUTFIT).id == "outfit_field_jacket" and catalog.equipped(CosmeticData.Kind.WEAPON_SKIN).id == "skin_factory"
		and catalog.equipped(CosmeticData.Kind.EMP_STYLE).id == "emp_blue", "a new save wears the free defaults")
	var runner := catalog.find("outfit_night_runner")
	_check(not catalog.equip(runner) and catalog.equipped(CosmeticData.Kind.OUTFIT).id == "outfit_field_jacket", "an item that isn't owned can't be equipped")

	GameState.flags.assign(["lab_intro_done"])
	var lab := (load(LAB_PATH) as PackedScene).instantiate()
	get_tree().root.add_child(lab)
	await _wait(0.3)
	var ui := lab.get_node(^"LabUI") as LabUI
	ui.open_shop()
	var rows := ui.shop_list.get_children()
	var first := rows[0] as CosmeticRow
	var second := rows[1] as CosmeticRow
	_check(rows.size() == 4 and first.action_button.text == "Equipped" and second.action_button.text == "$1.99" and get_tree().paused,
		"the lab shop lists outfits: the default is equipped, the rest show a price")
	ui.use_cosmetic(runner)
	await _frames(3)
	var doll := ui.doll
	_check(Monetization.owns(&"outfit_night_runner") and catalog.equipped(CosmeticData.Kind.OUTFIT) == runner
		and second.action_button.text == "Equipped" and ui.shop_info.text.contains("Night Runner"), "buying an outfit owns and equips it")
	_check(doll.body.self_modulate == runner.tint, "and the hero's body takes its look")
	var drawings := catalog.find("decor_drawings")
	var node := lab.get_node(^"Decor/decor_drawings") as CanvasItem
	_check(not node.visible, "lab decorations start hidden")
	ui.show_shop_kind(CosmeticData.Kind.LAB_DECOR)
	ui.use_cosmetic(drawings)
	await _frames(3)
	_check(node.visible and catalog.decor_visible(drawings), "a bought decoration appears in the lab")
	ui.use_cosmetic(drawings)
	_check(not node.visible and GameState.hidden_decor.has("decor_drawings"), "it can be hidden")
	ui.use_cosmetic(drawings)
	_check(node.visible, "and shown again")
	Monetization.stub.purchases_succeed = false
	ui.show_shop_kind(CosmeticData.Kind.EMP_STYLE)
	ui.use_cosmetic(catalog.find("emp_violet"))
	await _frames(3)
	_check(not Monetization.owns(&"emp_violet") and ui.shop_info.text.contains("didn't go through"), "a cancelled purchase says so")
	_reset_stub()
	ui._on_restore_pressed()
	await _frames(3)
	_check(ui.shop_info.text == "Purchases restored." and Monetization.owns(&"outfit_night_runner"), "Restore purchases refreshes the shop")
	var saved := GameState.to_dict()
	GameState.reset_to_new()
	GameState.from_dict(saved)
	_check(GameState.equipped.get("outfit", "") == "outfit_night_runner" and Monetization.owns(&"decor_drawings"),
		"the equipped look is saved on the slot; ownership stays with the account")
	ui._on_shop_close_pressed()
	_check(not get_tree().paused, "closing the shop unpauses")
	lab.queue_free()
	await _wait(0.2)


func _test_cosmetics_in_play() -> void:
	var catalog := load(COSMETICS) as CosmeticCatalog
	for product: StringName in [&"skin_carbon", &"emp_red_alert"]:
		Monetization.purchase(product)
	await _frames(3)
	var level := await _load_level(1, 66)
	var player := level.get_node(^"Player") as Player
	catalog.equip(catalog.find("skin_carbon"))
	catalog.equip(catalog.find("emp_red_alert"))
	await _frames(2)
	var gun_sprite := player.weapon.get_node(^"Sprite") as CanvasItem
	var bullet := _pool(level, "player_bullet").spawn(player.global_position, Vector2.UP)
	_check(gun_sprite.self_modulate == catalog.find("skin_carbon").tint and bullet.self_modulate == Color.WHITE and bullet.modulate == Color.WHITE,
		"a weapon skin tints the gun, never its bullets")
	bullet.despawn()
	_check(player.emp_wave.self_modulate == catalog.find("emp_red_alert").tint, "an EMP style tints the EMP wave")
	_check(GameState.equipped.get("outfit", "") == "" and (player.get_node(^"Visual") as HeroVisual).body.self_modulate == Color.WHITE,
		"a fresh slot wears the default outfit")
	level.queue_free()
	await _wait(0.3)


func _test_settings() -> void:
	var options := SaveManager.options
	_reset_settings()
	_check(is_equal_approx(options.tuning.stick_radius, 48.0) and Engine.max_fps == 60 and SaveManager.palette().hostile_material == null,
		"default settings: normal joystick, 60 fps, original bullet colors")
	SaveManager.stick_size = 2
	SaveManager.swipe_sensitivity = 0
	SaveManager.double_tap_window = 0.4
	SaveManager.fps_cap = 1
	SaveManager.show_joystick = false
	SaveManager.apply_settings()
	_check(is_equal_approx(options.tuning.stick_radius, 64.0) and is_equal_approx(options.tuning.swipe_min_speed, options.swipe_presets[0].swipe_min_speed)
		and is_equal_approx(options.tuning.double_tap_window, 0.4) and not options.tuning.show_joystick and Engine.max_fps == 30,
		"the settings write the controls tuning (stick size, swipe preset, double-tap, joystick) and cap the frame rate")
	SaveManager.save_settings()
	_reset_settings()
	SaveManager.load_settings()
	_check(SaveManager.stick_size == 2 and SaveManager.swipe_sensitivity == 0 and SaveManager.fps_cap == 1 and not SaveManager.show_joystick,
		"settings are saved and load back (settings.cfg)")
	_reset_settings()

	var level := await _load_level(1, 67)
	var player := level.get_node(^"Player") as Player
	var hud := level.get_node(^"HUD") as Hud
	var hostile := _pool(level, "enemy_bullet_small")
	var friendly := _pool(level, "player_bullet")
	_check(hostile.material == null and friendly.material == null, "default bullets keep their art")
	SaveManager.bullet_palette = 2
	SaveManager.apply_settings()
	var bullet := hostile.spawn(player.global_position + Vector2(0, -60), Vector2.UP)
	_check(hostile.material == options.palettes[2].hostile_material and friendly.material == options.palettes[2].friendly_material
		and bullet.use_parent_material and (bullet.get_node(^"Sprite") as CanvasItem).use_parent_material,
		"the color-blind palette recolors enemy and player bullets through their pools")
	bullet.despawn()
	var scaler := level.get_node(^"HUD/TextScaler") as TextScaler
	SaveManager.text_size = 1
	SaveManager.apply_settings()
	_check(scaler.theme.default_font_size == roundi(scaler.base_size * 1.25), "Large text scales the HUD's font (%d)" % scaler.theme.default_font_size)
	SaveManager.screen_shake = false
	var camera := level.get_node(^"Camera") as CameraFollow
	EventBus.screen_shake_requested.emit(1.0)
	await _frames(2)
	_check(camera.offset == Vector2.ZERO, "screen shake can be turned off")
	SaveManager.show_reticle = false
	var target := (load("res://src/enemies/grunt/grunt.tscn") as PackedScene).instantiate() as Enemy
	var room := (level.get_node(^"LevelDirector") as LevelDirector).current_room()
	target.position = room.enemies.to_local(player.global_position + Vector2(0, -60))
	room.enemies.add_child(target)
	await _wait(0.9)
	player.target_selector.current_target = target
	player.update_aim(Vector2.ZERO)
	_check(not player.reticle.visible, "the aim reticle can be hidden")
	SaveManager.stick_opacity = 0.4
	hud.show_stick(Vector2(180, 500))
	_check(is_equal_approx(hud.joystick.modulate.a, 0.4), "joystick opacity follows the setting")
	hud.hide_stick()
	_reset_settings()
	_check(hostile.material == null and scaler.theme.default_font_size == scaler.base_size, "back to defaults, everything re-applies")
	level.queue_free()
	await _wait(0.3)


func _test_settings_panel() -> void:
	GameState.reset_to_new()
	GameState.flags.assign(["lab_intro_done"])
	var lab := (load(LAB_PATH) as PackedScene).instantiate()
	get_tree().root.add_child(lab)
	await _wait(0.3)
	var ui := lab.get_node(^"LabUI") as LabUI
	var panel := lab.get_node(^"LabUI/SettingsPanel") as SettingsPanel
	ui._on_settings_button_pressed()
	_check(panel.visible and panel.stick_size_option.item_count == 3 and panel.palette_option.item_count == 3 and panel.fps_option.get_item_text(1) == "30 fps"
		and not panel.privacy_button.visible, "the lab opens the settings screen with every option")
	panel._on_text_size_option_item_selected(1)
	panel._on_haptics_check_toggled(false)
	_check(SaveManager.text_size == 1 and not SaveManager.haptics and FileAccess.file_exists(TEST_DIR + "settings.cfg"),
		"changing an option applies and saves it at once")
	panel._on_close_button_pressed()
	Monetization.stub.privacy_options_required = true
	panel.open()
	_check(panel.privacy_button.visible and panel.text_size_option.selected == 1, "where the law requires it, Privacy options shows up")
	_reset_stub()
	Monetization.stub.privacy_options_required = false
	panel._on_close_button_pressed()
	lab.queue_free()
	await _wait(0.2)
	var title := (load("res://src/ui/title/title.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(title)
	await _wait(0.2)
	title.call(&"_on_settings_button_pressed")
	var hud_scene := (load("res://src/ui/hud.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(hud_scene)
	await _wait(0.1)
	(hud_scene as Hud)._on_settings_button_pressed()
	_check((title.get_node(^"SettingsPanel") as Control).visible and (hud_scene.get_node(^"Root/SettingsPanel") as Control).visible,
		"the title and the pause menu open it too")
	title.queue_free()
	hud_scene.queue_free()
	await _wait(0.2)


func _reset_settings() -> void:
	SaveManager.show_joystick = true
	SaveManager.stick_size = 1
	SaveManager.stick_opacity = 0.8
	SaveManager.swipe_sensitivity = 1
	SaveManager.double_tap_window = 0.3
	SaveManager.show_reticle = true
	SaveManager.screen_shake = true
	SaveManager.bullet_palette = 0
	SaveManager.text_size = 0
	SaveManager.fps_cap = 0
	SaveManager.haptics = true
	SaveManager.language = ""
	SaveManager.apply_settings()


# --- Helpers ---

func _load_level(number: int, level_seed: int) -> Node:
	get_tree().paused = false
	GameState.reset_to_new()
	RunState.start_new_run()
	RunState.level_number = number
	var level := (load(LEVEL_PATH) as PackedScene).instantiate()
	var director := level.get_node(^"LevelDirector") as LevelDirector
	director.return_to_lab = false
	director.fixed_seed = level_seed
	get_tree().root.add_child(level)
	await _wait(0.5)
	return level


func _die(player: Player) -> void:
	player.health.invuln_timer.stop()
	player.health.armor = 0
	player.health.take_hit(99)
	await _wait(1.5)


func _pool(level: Node, bullet_file: String) -> BulletPool:
	for node: Node in level.get_tree().get_nodes_in_group(&"bullet_pools"):
		var pool := node as BulletPool
		if pool.bullet_scene.resource_path.ends_with(bullet_file + ".tscn"):
			return pool
	return null


func _reset_stub() -> void:
	Monetization.stub.consent_given = true
	Monetization.stub.grant_rewards = true
	Monetization.stub.purchases_succeed = true


func _clear_test_dir() -> void:
	var dir := DirAccess.open(TEST_DIR)
	if dir == null:
		return
	for file: String in dir.get_files():
		dir.remove(file)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true).timeout


func _frames(count: int) -> void:
	for _i: int in count:
		await get_tree().process_frame


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS  ", label)
	else:
		_failures += 1
		print("FAIL  ", label)
