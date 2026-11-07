class_name Campaign
extends Resource
## The run's levels in order (data/levels/campaign.tres). A run goes L1 → lab → L2 → lab → … → the last level's boss.

@export var levels: Array[LevelConfig] = []
## The endings, one per humanity band (decided when the last boss falls).
@export var endings: Array[EndingData] = []

@export_group("Threat levels (NG+)")
## Highest threat level. Each ending unlocks the next one, up to this.
@export_range(0, 10) var max_threat := 5
## Extra room, arena and ambush threat per threat level (0.15 = +15% each).
@export_range(0.0, 1.0, 0.01) var threat_step := 0.15
## Extra elite chance per threat level.
@export_range(0.0, 0.2, 0.01) var elite_step := 0.05
## Extra RAM from robots per threat level (the small reward).
@export_range(0.0, 0.5, 0.01) var reward_step := 0.1


func count() -> int:
	return levels.size()


## The config for level `number` (1-based), clamped to the levels that exist.
func config_for(number: int) -> LevelConfig:
	return levels[clampi(number, 1, levels.size()) - 1] if not levels.is_empty() else null


func is_last(number: int) -> bool:
	return number >= levels.size()


## The ending for a humanity band (GameState.Band), or null.
func ending_for(band: int) -> EndingData:
	for ending: EndingData in endings:
		if ending.band == band:
			return ending
	return null


func find_ending(ending_id: String) -> EndingData:
	for ending: EndingData in endings:
		if ending.id == ending_id:
			return ending
	return null


func threat_scale(threat: int) -> float:
	return 1.0 + threat_step * threat


func elite_bonus(threat: int) -> float:
	return elite_step * threat


func reward_scale(threat: int) -> float:
	return 1.0 + reward_step * threat
