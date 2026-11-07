# Content rating and App content (draft answers)

Play Console → App content. These draft answers come from the game as it is in the repository. The design target
is **PEGI 12 / ESRB Teen** ([GDD](../GDD.md) §1.5); the questionnaire decides the actual ratings, region by
region (IARC).

## Rating questionnaire (IARC)
- **Category:** Game.
- **Email:** the address where IARC should send the certificate.

| Topic | Answer | Notes from the game |
|---|---|---|
| Violence | **Yes**, fantasy violence | The hero shoots robots, and robots shoot him. Robots break apart into sparks and scrap: no blood or gore, and no violence against humans or animals on screen |
| Blood or gore | No | Placeholder art has none; keep it that way in the final art (or update this answer) |
| Death or harm of humans | Implied only | The story is about a man whose family was killed by machines, a child among them. It's told in text and comic panels and never shown (risk R10, [open-questions.md](../open-questions.md)). Implant surgery happens off-panel |
| Fear or horror | No horror content | Dark, sad themes (grief and loss of humanity), no jump scares |
| Sexual content or nudity | No | |
| Language (profanity, crude humor) | No | All 477 strings were checked: no profanity |
| Controlled substances (drugs, alcohol, tobacco) | No | |
| Gambling (real or simulated) | No | No betting or casino mechanics. Chests and hacked terminals give random in-game rewards, earned in play and never sold |
| Users can interact or exchange content | No | No chat, accounts or user content |
| Shares user's physical location with other users | No | |
| Digital purchases | **Yes** | Cosmetic, one-time, non-random items ([monetization_setup.md](monetization_setup.md)) |
| Randomized items for real money (loot boxes) | No | Nothing random is ever sold |
| Unrestricted internet access (web browsing) | No | |

**Expected ratings:** about ESRB E10+ or Teen for Fantasy Violence, and PEGI 7 to 12. If the result is lower than
the design target, that's fine; don't inflate answers.

## Target audience and content
- **Target age groups:** 13–15, 16–17 and 18+. The core audience is 16–35. Choosing an age under 13 brings in the
  Families policy:
  - only Families-certified ad SDKs;
  - ads tagged for child-directed treatment;
  - no personalized ads.

  Those don't fit this game's current setup.
- **Could the store listing unintentionally appeal to children?** No. Keep the screenshots and icon free of
  cartoon-for-kids styling.

## Other App content declarations
| Declaration | Answer |
|---|---|
| Privacy policy | The URL where [privacy_policy.md](privacy_policy.md) is published |
| Ads | Yes, the app contains ads (opt-in rewarded ads) |
| App access | All functionality is available without special access (no login) |
| Content rating | The questionnaire above |
| Target audience | As above |
| Data safety | [data_safety.md](data_safety.md) |
| Advertising ID | Yes: Advertising or marketing, and Analytics |
| Government app / Financial features / Health | No / None / No |
| News app | No |
