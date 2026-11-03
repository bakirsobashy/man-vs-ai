class_name Campaign
extends Resource
## The run's levels in order (data/levels/campaign.tres). A run goes L1 → lab → L2 → lab → … → the last level's boss.

@export var levels: Array[LevelConfig] = []


func count() -> int:
	return levels.size()


## The config for level `number` (1-based), clamped to the levels that exist.
func config_for(number: int) -> LevelConfig:
	return levels[clampi(number, 1, levels.size()) - 1] if not levels.is_empty() else null


func is_last(number: int) -> bool:
	return number >= levels.size()
