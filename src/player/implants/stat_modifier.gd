class_name StatModifier
extends Resource
## One change an implant makes to the hero (docs/content.md §5). Values add up across the slot's tiers.

enum Stat {
	MAX_HP,             ## Half-hearts added to max health.
	START_ARMOR,        ## Armor pips at the start of each level.
	MOVE_SPEED,         ## Share added to move speed (0.12 = +12%).
	ROLL_DISTANCE,      ## Share added to roll distance (0.3 = +30%).
	HEAL_EVERY_ROOMS,   ## Heal ½ heart after this many cleared rooms.
	ROLL_SHOCKWAVE,     ## Damage of the shockwave at the end of every roll.
	AIM_RANGE,          ## Share added to the auto-aim range (0.25 = +25%).
	TARGET_HP,          ## 1 = show the target's HP under the reticle.
	CRIT_CHANCE,        ## Chance of double damage per bullet (0.15).
	THREAT_SIGHT,       ## Seconds added to every enemy telegraph; also highlights bullets aimed at the hero.
	EMP_CHARGES,        ## EMP charges added per level.
	EMP_RADIUS,         ## Pixels added to the EMP stun radius.
	EMP_STUN,           ## Seconds added to the EMP stun.
	FAILSAFE,           ## 1 = once per level, a lethal hit fires a free EMP and is negated.
	RELOAD_SPEED,       ## Share added to reload speed (0.25 = 25% faster).
	SPREAD,             ## Share added to weapon spread (-0.4 = 40% tighter).
	FIRE_RATE,          ## Share added to fire rate (0.15).
	DUAL_WIELD,         ## 1 = both carried guns fire at once.
	ROLL_RECOVERY,      ## Share added to roll recovery time (-0.3 = 30% shorter).
	IFRAME_RATIO,       ## Added to the share of the roll that is invulnerable (0.15: 60% to 75%).
	HAZARD_IMMUNE,      ## 1 = gas, fire and molten floors don't hurt.
	SECOND_WIND,        ## 1 = rolling through an enemy bullet slows time and boosts damage.
}

@export var stat := Stat.MAX_HP
@export var value := 0.0
