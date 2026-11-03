class_name Dummy
extends StaticBody2D
## Greybox test dummy: takes hits, respawns, and (if it has an Emitter) telegraphs and shoots on its AttackTimer.

## Optional bullet emitter (shooter dummies).
@export var emitter: BulletEmitter
## Optional telegraph animation player; its "telegraph" animation calls fire_emitter() at the end.
@export var attack_animation: AnimationPlayer
## Optional: only attack while this notifier is on screen.
@export var screen_notifier: VisibleOnScreenNotifier2D
## Tint shown while stunned by an EMP.
@export var stun_tint := Color(0.55, 0.8, 1.0)

@onready var body_shape: CollisionShape2D = %BodyShape
@onready var sprite: Sprite2D = %Sprite
@onready var hurtbox: Area2D = %Hurtbox
@onready var health: Health = %Health
@onready var hp_bar: ProgressBar = %HpBar
@onready var flash_animation: AnimationPlayer = %FlashAnimation
@onready var respawn_timer: Timer = %RespawnTimer

var _stun_left := 0.0


func _ready() -> void:
	hp_bar.max_value = health.max_hp
	hp_bar.value = health.hp


func _physics_process(delta: float) -> void:
	if _stun_left <= 0.0:
		return
	_stun_left -= delta
	if _stun_left <= 0.0:
		sprite.modulate = Color.WHITE


func is_alive() -> bool:
	return health.is_alive()


func is_targetable() -> bool:
	return is_alive()


## Damage from explosions and other non-bullet sources.
func take_damage(amount: int) -> void:
	if not is_alive():
		return
	health.take_hit(amount)
	if is_alive():
		flash_animation.stop()
		flash_animation.play(&"hurt")


func stun(duration: float) -> void:
	if not is_alive():
		return
	_stun_left = maxf(_stun_left, duration)
	sprite.modulate = stun_tint
	if attack_animation != null:
		attack_animation.play(&"RESET")


## Called by the end of the "telegraph" animation.
func fire_emitter() -> void:
	if emitter != null and is_alive() and _stun_left <= 0.0:
		emitter.fire()


func _on_hurtbox_area_entered(area: Area2D) -> void:
	var bullet := area as Bullet
	if bullet == null or not bullet.active or not is_alive() or not bullet.try_hit(self):
		return
	take_damage(bullet.hit_damage)


func _on_health_changed(hp: int, _max_hp: int, _armor: int, _damaged: bool) -> void:
	if is_node_ready():
		hp_bar.value = hp


func _on_health_died() -> void:
	visible = false
	body_shape.set_deferred(&"disabled", true)
	hurtbox.set_deferred(&"monitoring", false)
	if attack_animation != null:
		attack_animation.play(&"RESET")
	respawn_timer.start()
	EventBus.enemy_killed.emit(self)


func _on_respawn_timer_timeout() -> void:
	health.reset()
	_stun_left = 0.0
	sprite.modulate = Color.WHITE
	visible = true
	body_shape.set_deferred(&"disabled", false)
	hurtbox.set_deferred(&"monitoring", true)


func _on_attack_timer_timeout() -> void:
	if emitter == null or attack_animation == null or not is_alive() or _stun_left > 0.0:
		return
	if screen_notifier != null and not screen_notifier.is_on_screen():
		return
	attack_animation.play(&"telegraph")
