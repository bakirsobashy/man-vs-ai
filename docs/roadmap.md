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
**Status: built, device playtest pending.**
- **Built:** the player, touch controller, HUD with debug panel, test room, cover in three materials, and target and shooter dummies.
- **Tests:** the headless smoke test (`tools/smoke_test_controls.gd`) passes all 17 checks.
- **Still to do:**
  - build an Android export and put it on 2+ phones;
  - run the exit-gate playtest below;
  - then copy the winning values into `controls_tuning.tres`.

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
**Status: built, device playtest pending.**
- **Built:**
  - Weapons: Scattergun, Buzz SMG and Rivet Driver (with piercing), two weapon slots, floor pickups.
  - Enemies: Grunt, Charger, Turret and Swarmer, built from reusable state nodes.
  - World: explosive barrels; RAM, Crypto and pickups with a magnet.
  - Waves: a threat-budget wave spawner and endless waves in `combat_test.tscn`.
  - HUD v1: hearts, armor, currencies, weapon card, prompt, wave banner, edge arrows.
- **Tests:** the combat smoke test passes 31/31, and a 90-second endless-wave soak runs with no errors.
- **Still to do:**
  - the 10-minute fun test on phones;
  - the performance gate, using the debug panel's **300-bullet storm** button and its FPS readout.

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
**Status: built, device playtest pending.**
- **Built:**
  - The level generator (`LevelGenerator`), driven by `data/levels/level_1.tres`, and the `LevelDirector`:
    - door transitions behind a fade;
    - locked fights and room rewards;
    - rooms that keep their state when the hero comes back.
  - 16 greybox Rustline rooms: start, 8 combat, 2 chest, memory, challenge arena, repair, terminal and boss.
    Cover and SpawnPoints are hand-placed, and navigation is baked around the cover.
  - Chests from the weapon catalog, a repair shop, a hacked terminal, the first memory, and the challenge arena.
  - A stand-in boss (ring and fan attacks, HUD boss bar); beating it reveals an elevator that starts a fresh random level.
  - HUD: minimap, full map, shop and memory panels, and toasts.
- **Tests:**
  - the generator test validates 10,000 levels in about 3 s;
  - the level smoke test passes 55/55;
  - the M1 and M2 smoke tests still pass.
- **Stand-ins until later milestones:**
  - the boss (SCRAPJAW comes in M4);
  - the terminal ambush is a normal 3-threat wave (elites come in M5);
  - death respawns the hero at the room's door (the run ending and the lab come in M4);
  - the elevator starts another random level 1.
- **Still to do:** play a level from start to the boss door on a phone and time it (the target is about 10 minutes).

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
**Status: systems built, art and real audio still to come, device playtest pending.**
- **Built:**
  - **SCRAPJAW**, the Level 1 boss, with all three phases (Wreck, Magnet, Grind) in a scrapyard arena.
  - **The lab hub:**
    - Dr. Vorn's surgery with Fusion Heart and Hydraulic Legs at Mk I–III (hold to confirm the first install, plus a comic panel);
    - Patch's armory with 6 unlockable guns (Bolt Revolver, Ricochet Carbine, Magnet Coil, Volt Shotgun, Longshot,
      Firecracker); chests only drop unlocked guns;
    - the elevator and Quick Start.
  - **Saves:** three save slots on the title screen, auto-saving runs, Continue run, settings, and Save and quit.
  - **Story and flow:** the prologue comic, the four-step rehab tutorial, lab conversations, and death through Vorn's
    Retrieved summary back to the lab.
  - **Audio:** an audio system with generated placeholder sound effects and three music loops (lab, Rustline, boss).
- **Tests:**
  - the M4 smoke test passes 42/42 and the flow smoke test 28/28;
  - every earlier test still passes.
- **Owner's choices for M4:**
  - The art-direction test is postponed (Q2 stays open); the slice uses placeholder art, with the paper-doll nodes in place.
  - Audio is generated by script for now.
  - Heart and Legs are the playable implants.
  - After SCRAPJAW, the lab loops back to a fresh Level 1 run (Level 2 arrives in M5).
- **Still to do:**
  - the art-direction test and the real music and sound pass;
  - the external playtest with 10+ people.

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
**Status: content complete. All five levels, every boss and the endings are playable; the balance pass and adaptive
audio layers are left.**
- **The campaign:** runs go L1 → lab → L2 → lab → L3 → lab → L4 → lab → L5. Hearts, armor and the found gun carry
  between levels, and death restarts at Level 1. Beating ZERO plays the ending for Kade's band.
- **Level 2, Neon Bazaar:**
  - 16 rooms with holo-signs (they block sight, not bullets) and the Shotgunner, Drone and Hacker.
  - **Elite modifiers** (Overclocked, Armored, Splitter, Shielded), from Level 2 at 10%.
  - **GLITCH**, with decoys, holo-wall cages and the Static Storm.
  - **Guns:** the Junk Cannon, Arc Caster and Overclock Pistol.
  - **Implants:** Hawk Optics and Neural Coprocessor.
  - **Story:** memory band variants, Mira's Drawing, the Level 2 lab talk, and Vorn's band-aware idle lines.
- **Level 3, The Foundry:**
  - 16 rooms with conveyor belts (they carry the hero and walking robots) and molten lanes (rolling crosses them).
  - The **Grenadier** (lobbed grenades with a landing circle) and the **Shield-bot** (a turning front shield that
    drops when it attacks). Elites at 15%.
  - **FORGEMOTHER**: Assembly (builds Swarmers, rivet fans), Overtime (belts reverse at double speed, crates ride
    in, grenade volleys) and Meltdown (core takes double damage, molten floods with a 1 s warning).
  - **Guns:** the Cryo Sprayer, Rail Spike and Scrap Minigun.
  - **Implants:** Servo Arms and Filter Lungs (all 6 body slots now have implants).
  - **Story:** Lena's Message and the Level 3 lab talk.
- **Level 4, Skyline Spires:**
  - 16 rooms with timed laser grids (off, a warning blink, then ½ heart; rolls pass through) and cracking glass
    floors (they break 0.9 s after you step on them; falling costs a heart, and a roll carries you over a hole).
  - The **Sniper** (a laser sight that cover blocks, a 1-heart shot, then it relocates) and the **EMP-bot** (an EMP
    field that shorts out cover, and a pulse that knocks the hero out of it). Elites at 20%.
  - **WARDEN**: Overwatch (2 flanking Drones, perched snipes), Suppression (EMP fields on the hero, sweeping fire)
    and Hunt (drops down 80% faster, sweeps and snipes). The first kill unlocks the M7 Line Rifle.
  - **Guns:** the Swarm Launcher, Beam Cutter and Toaster Cannon, plus the M7 Line Rifle story gun (19 of 21 guns).
  - **Story:** Mira's Birthday and the Level 4 lab talk (the Warden's recording is in the Syndicate Core).
- **Level 5, Syndicate Core:**
  - 16 rooms with coolant channels (they flood on a cycle and halve the hero's speed) and sweeping firewalls (roll
    through them).
  - The **Null Knight** mirrors the hero: it rolls through bullets, takes cover and chains bursts with grenades.
    Elites at 25%.
  - **ZERO**: Duel (rolls, cover, bursts), Syndicate (Glitch's decoys, Scrapjaw's charge, Forgemother's minions,
    Warden's laser) and Zero Hour (overclocked spirals while the arena's edge firewalls close in).
  - **Guns:** the Peacekeeper (ignores enemy shields) and the Black Box (an orb that eats enemy bullets and bursts
    them back). All 21 guns exist.
  - **Story:** The Night, the Warden's recording, in four band variants.
- **Endings and post-game:**
  - Four ending comics (Humanity, Normal Patched, Normal Hollow, Transformation) by implant count, then the credits
    and Vorn's post-credits line, then the lab.
  - NG+ threat levels (Q5): each ending unlocks the next (up to 5), picked in the lab: +15% threat and +5% elite
    chance per level for +10% RAM.
- **Owner decisions:** Vorn is morally grey (Q1), the Normal ending has Patched and Hollow flavors (Q8), and
  post-game is NG+ threat levels (Q5).
- **Tests:**
  - every earlier suite still passes;
  - the Level 2 smoke test passes 44/44, Level 3 49/49, Level 4 43/43, Level 5 33/33 and the endings test 25/25;
  - the generator validates 10,000 layouts for each campaign level.
- **Left in M5:** the balance pass (it needs the M5 playtests' data) and adaptive audio layers.

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
