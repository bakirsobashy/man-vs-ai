class_name ImplantCatalog
extends Resource
## Every implant tier that surgery can install (data/implants/implant_catalog.tres). M4 ships Heart and Legs.

@export var implants: Array[ImplantData] = []


## The data for `slot` at `tier`, or null when that tier doesn't exist (yet).
func get_tier(slot: String, tier: int) -> ImplantData:
	for implant: ImplantData in implants:
		if implant.slot == slot and implant.tier == tier:
			return implant
	return null


func has_slot(slot: String) -> bool:
	return get_tier(slot, 1) != null


## Total of `stat` from every installed tier, given slot → tier.
func total(stat: StatModifier.Stat, installed: Dictionary[String, int]) -> float:
	var sum := 0.0
	for implant: ImplantData in implants:
		if implant.tier <= installed.get(implant.slot, 0):
			for modifier: StatModifier in implant.modifiers:
				if modifier.stat == stat:
					sum += modifier.value
	return sum
