# Man vs AI — Roadmap

**Version:** 0.1 (draft). Durations are rough estimates for a 2–4 person team. Re-plan after M1.

## Overview
| Milestone | Goal | Rough duration | Exit gate |
|---|---|---|---|
| **M0 Foundation** | Design docs and project setup | Done | The owner has reviewed the [PROPOSED] items |
| **M1 Controls greybox** | Prove the one-finger controls are fun | 2–3 weeks | Controls playtest passes |
| **M2 Combat core** | The real fight loop | 3–4 weeks | One room stays fun for 10 minutes |
| **M3 Levels** | Generated levels with every room type | 3–4 weeks | A greybox level plays from start to the boss door |
| **M4 Vertical slice** | L1 complete, plus the lab, saves and art direction | 6–8 weeks | One level at shippable quality |
| **M5 Content** | L2–L5, every boss, enemy, weapon and implant, all three endings | 4–6 months | The full game is playable and every ending is reachable |
| **M6 Release** | Monetization, polish, localization pass, store | 2–3 months | Play Store launch |

The highest risk (one-finger controls) is tested first. Nothing else gets built on top of controls that haven't passed their gate.

---

## M0: Foundation ✅
- Design docs: [GDD](GDD.md), [narrative](narrative.md), [content](content.md), [technical](technical.md), this roadmap,
  and [open questions](open-questions.md).
- `project.godot` configured for Android portrait, plus the folder structure.
- The scene-first rule ([technical.md](technical.md) §0), `CLAUDE.md`, and the check tools in `tools/`.
- **Exit:** the owner reviews the [PROPOSED] items and answers the urgent open questions.

## M1: Controls greybox
**Scope**
- Everything built scene-first: `player.tscn`, `hud.tscn`, `test_room.tscn` and the dummy scenes are authored in the
  editor ([technical.md](technical.md) §0).
- `TouchController` with the debug overlay ([technical.md](technical.md) §4).
- The hero: run, auto-fire, roll, slide to cover, in-cover, and stand-and-reload.
- EMP on double-tap.
- One test room with cover in every material, target dummies, and 2 dummy shooters (one aimed, one spread).
- An Android build running on real phones.

**A/B toggles to test**
- Cover target: nearest point vs. smart side.
- Joystick zone top: 35 / 40 / 50%.
- Swipe threshold presets.
- Hero screen anchor: 40 / 45 / 55%.

**Exit gate** (5+ testers, 2+ phones)
- Fewer than 5% of roll attempts are unintended or missed.
- At least 80% of the time, testers say cover "went where I wanted".
- Testers can explain the controls after 2 minutes without help.
- 10 minutes of play with no complaints of hand fatigue.

If the gate fails, iterate on M1 before moving on.

## M2: Combat core
**Scope**
- 4 weapon scenes with their stats in the Inspector, plus their bullet scenes.
- Bullet pools.
- 4 enemy scenes: Grunt, Charger, Turret, Swarmer.
- Hearts, armor and the hurt overlay; reload rules.
- Cover scenes for each material (light, medium, heavy, explosive).
- Drops: RAM, Crypto and pickups.
- HUD v1.

**Exit gate**
- A hand-built room with waves stays fun for 10 minutes.
- 60 fps on mid-range phones and at least 30 fps on low-end with 300 bullets on screen.

## M3: Levels
**Scope**
- The level generator, with validation tests.
- Door transitions and the minimap.
- About 8 greybox room scenes for Rustline, with hand-placed cover and SpawnPoints.
- Chest rooms.
- Working special rooms: memory, arena, repair and terminal.
- A placeholder boss room.

**Exit gate**
- 10,000 generated levels pass every constraint.
- A level plays from start to the boss door in about 10 minutes.

## M4: Vertical slice
**Scope**
- The SCRAPJAW boss.
- The lab hub: surgery with 2 implants and the armory with about 6 unlocks.
- Save slots and run resume.
- The tutorial and the first comic panels.
- An L1 music and SFX pass.
- An **art-direction test**:
  - the hero in final style (paper doll with 2 implant overlays);
  - one enemy;
  - the Rustline tileset;
  - the HUD skin.

**Decisions due:** art style ([open-questions.md](open-questions.md) Q2), and the scientist's role (Q1) if possible.

**Exit gate**
- L1 and the lab at near-final quality.
- An external playtest with 10+ people, including a "would you play again?" question.

## M5: Content production
**Scope**
- Districts 2–5: templates, hazards and tilesets.
- The remaining 8 enemy types and the elite modifiers.
- The 4 remaining bosses.
- All 21 weapons.
- All 6 implants × 3 tiers, with the 18 sprite overlays.
- 5 memory rooms × 4 band variants.
- Lab dialogue and the 3 endings.
- Adaptive audio layers.
- Balance passes on the economy tables.

**Exit gate**
- The full game can be completed.
- Playtesters have reached all three endings.
- No blocker bugs.

## M6: Release
**Scope**
- Rewarded ads (Second Chance, Salvage bonus) with the consent flow.
- Cosmetic IAP and the shop UI.
- Settings and accessibility options.
- A localization pass: extract every string and run a pseudo-localization test.
- Low-end performance work.
- Play Console: rating questionnaire, data-safety form, store listing, then internal → closed → open testing → launch.

---

## Team and ownership [PROPOSED]
| Area | Owner |
|---|---|
| Design docs, balance tables, room layouts | Designer / lead |
| Input, player, combat, generation, saves | Programmer |
| Art direction, paper doll, tilesets, comics | Artist (from M4; placeholder art before that) |
| Music and SFX | Contract composer and sound designer (M4–M5) |
| Builds, store, monetization | Programmer + lead |
