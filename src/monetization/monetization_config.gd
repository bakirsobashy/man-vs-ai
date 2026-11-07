class_name MonetizationConfig
extends Resource
## Ad and store settings (data/monetization/monetization.tres; GDD §9, technical §12). The ad unit IDs default to
## Google's public test units: replace them with the game's own AdMob IDs before release, and keep test_ads on until
## then.

@export_group("Ads")
## AdMob rewarded ad unit (Android). The default is Google's sample rewarded unit.
@export var rewarded_ad_unit_android := "ca-app-pub-3940256099942544/5224354917"
## Serve test ads (and use the UMP debug settings) while developing.
@export var test_ads := true
## The game is aimed at 16+ (GDD §1.5), so the consent request doesn't tag users as under the age of consent.
@export var tag_for_under_age_of_consent := false

@export_group("Rewards")
## Salvage bonus: the share of the run's Crypto the ad adds.
@export_range(0.0, 1.0, 0.05) var salvage_share := 0.25
## Second Chance: half-hearts restored.
@export_range(1, 6) var second_chance_hp := 2

@export_group("Store")
## Cosmetic product IDs, as created in the Play Console (one-time, non-consumable).
@export var product_ids: PackedStringArray = []
## Desktop and debug builds use the stub even on Android (for testing without the plugins).
@export var force_stub := false
