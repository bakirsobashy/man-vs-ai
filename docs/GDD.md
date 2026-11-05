# Man vs AI — Game Design Document

**Version:** 0.1 (foundation draft) · **Date:** 2026-11-03 · **Engine:** Godot 4.7 · **Platform:** Android, portrait

> **Tags used in every design doc**
> - **[LOCKED]**: decided with the project owner in the foundation Q&A. Change it only on purpose.
> - **[PROPOSED]**: the designer's default. Tune or replace it freely.
> - **[OPEN]**: not decided yet. Tracked in [open-questions.md](open-questions.md).
> - Names marked **†** are placeholders.

| Companion doc | Covers |
|---|---|
| [narrative.md](narrative.md) | World, characters, boss backstories, memory rooms, endings, dialogue tone |
| [content.md](content.md) | Numbers and lists: weapons, implants, enemies, boss phases, rooms, loot, economy |
| [technical.md](technical.md) | Godot architecture, input state machine, level generation, saves, performance, Android |
| [roadmap.md](roadmap.md) | Milestones M0–M6 and their exit gates |
| [open-questions.md](open-questions.md) | Pending decisions and design risks |

---

## 1. Vision

### 1.1 Elevator pitch
A grieving war veteran who hates machines hunts the robot gang that murdered his family. Every
upgrade that makes him strong enough to win replaces another piece of the man. It's a fast,
readable bullet-hell roguelite inspired by *Enter the Gungeon*, played in portrait with **one finger**.

### 1.2 Key facts
| | |
|---|---|
| Genre | Top-down 2D bullet-hell roguelite shooter |
| Platform | Android phones, portrait only (desktop builds for development) |
| Input | One finger: move, auto-fire, roll, cover, special |
| Run | 5 levels × 8–10 rooms, about 10 minutes per level, about 55 minutes per full run |
| Progression | Permanent implants (paid in RAM) and permanent weapon unlocks (paid in Crypto), per save slot |
| Endings | 3, decided by how many of the 6 body slots are implanted |
| Business | Free; optional rewarded ads (a small help only) and cosmetic IAP |
| Tech | Godot 4.7, GDScript, Compatibility renderer |
| Team | Small (2–4 people) |
| Comparable games | Enter the Gungeon (combat, rooms), Archero (one-finger mobile play), Rogue Legacy (progress that persists across deaths) |

### 1.3 Design pillars
1. **One finger, full control.** Moving, shooting, dodging, hiding and the special all use one finger.
   A feature that needs a second finger, or a precise tap in the middle of a fight, doesn't ship.
2. **Every upgrade costs a piece of you.** Power is always on offer, and the price is the
   hero's humanity. The player's build *is* the story.
3. **Fast, readable bullet-hell.** Patterns are dense, but every attack is telegraphed, every bullet can be
   read on a 6" screen, and every hit feels fair.

### 1.4 Player fantasy
*"I'm a veteran soldier. I run and gun through robot gangs, roll through bullet storms, and duck
behind cover when it gets hot. I can turn myself into a walking weapon, or prove that a human can still win."*

### 1.5 Audience and rating
- Core audience: mobile players aged 16–35 who like action roguelites (Archero, Soul Knight, Gungeon).
- Secondary: PC/console roguelite fans who want a pick-up-and-play mobile game.
- Rating target: PEGI 12 / ESRB Teen. The violence is against robots, and the family's deaths are implied, never
  shown. [PROPOSED]

---

## 2. Game structure

### 2.1 The run [LOCKED]
```
New save ─► prologue comic ─► LAB (tutorial the first time)
                                │
      ┌─────────────────────────┘
      ▼
     L1 ─► LAB ─► L2 ─► LAB ─► L3 ─► LAB ─► L4 ─► LAB ─► L5 ─► ENDING (decided by implant count)
      ▲
      └──── death anywhere: back to the LAB, restart at L1 with new maps
```
- Each level is a randomly generated set of 8–10 rooms that ends with a gang boss.
- Between levels the hero returns to the **lab hub** to spend currency.
- **Death** sends the hero back to the lab, and the next run starts at Level 1 with fresh maps.
- In the fiction, the gang restores its lieutenants from backups, so only killing all five in
  *one night* finishes them (see [narrative.md](narrative.md) §4.3 and §6).

### 2.2 What persists [LOCKED]
| Thing | Scope | Notes |
|---|---|---|
| Implants (slot and tier) | **Permanent per save** | Irreversible; counted for the ending |
| Weapon unlocks | Permanent per save | Bought with Crypto; added to the chest loot pool |
| Crypto and RAM | Permanent per save | **Kept on death** |
| Memories found | Permanent per save | Viewable in the lab codex [PROPOSED] |
| Endings seen | Per save, plus a global gallery | [PROPOSED] |
| Hearts, armor, ammo, carried found gun, EMP charges | Per run | Reset on death |
| Maps | Per run | New seed every run |

### 2.3 Save slots [LOCKED]
- There are **3 independent save slots**. Each slot is one life story, so a player can keep one human, one mixed and one machine.
- The **first implant on a slot** shows an irreversible-choice warning and needs a 1.5 s hold to confirm.
- Each slot card shows playtime, best level reached, endings seen, and the hero's silhouette with the implanted
  parts marked.

### 2.4 Session design [PROPOSED]
- The game auto-saves on every room entry, room clear and lab purchase, and whenever the app goes to the background.
- Reopening the app offers **Continue run**. The hero resumes at the entrance of the room they were in; an
  uncleared room resets its enemies, and hearts and ammo are kept as last saved.
- A level takes about 10 minutes, so it fits one sitting.

---

## 3. Controls: one finger [LOCKED]

### 3.1 Screen zones
```
┌──────────────────────────────┐  0%
│ HUD band (buttons, prompts)  │
│                              │  UI ZONE: taps reach HUD buttons and prompts only.
│ world view                   │  (A double-tap here still triggers the special.)
├ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┤  40%
│                              │
│ world view                   │  JOYSTICK ZONE: a touch-down here spawns
│                              │  the floating joystick.
│                              │
└──────────────────────────────┘  100%
 16 px margins at the left, right and bottom edges are ignored (Android system gestures).
```
The owner chose "floating joystick, lower part of the screen". The default split is 40/60; M1 tests 35–50%.

### 3.2 Gestures
| Player does | Detected as | Hero does |
|---|---|---|
| Touch and hold in the joystick zone, drag | **Move** | Runs in the drag direction and **auto-fires** at the nearest visible enemy while the finger is down |
| Touch, quick flick, lift (≤ 0.25 s in total) | **Swipe** | **Dodge roll** in the flick direction |
| Lift the finger (any other release) | **Lift** | Stops firing. If cover is within 2 tiles, slides to the nearest point of that cover and crouches; otherwise stands still, exposed, and reloads |
| Two quick taps anywhere except a HUD button | **Double-tap** | **EMP special** (if a charge is left) |
| Tap the HUD weapon card | UI | Swaps weapons |
| Tap a prompt bubble (top band) | UI | Interacts: buy, swap gun, use station, talk |

### 3.3 Rules in detail

**Movement**
- Floating joystick: the touch-down point becomes the stick's center. The finger's offset sets direction, and speed
  rises with the offset, reaching full speed at about 70% of the stick radius.
- If the finger drags past the radius, the center follows it, so reversing direction feels instant.
- The joystick is invisible by default; settings can turn on a faint ring. (During M1 testing it's shown, and the debug
  panel can hide it.)

**Auto-fire (run & gun)**
- The hero fires **while the finger is down**, whether moving or holding still, and stops on lift.
- Target: the nearest enemy in line of sight within weapon range. The target is *sticky*: it's kept until it dies,
  stays out of sight for 0.2 s, or another enemy is at least 30% closer.
- With no visible enemy the hero doesn't fire, so no ammo is wasted on walls.
- A small reticle marks the current target.

**Dodge roll**
- Only a swipe triggers it: touch, flick and lift within 0.25 s, past the distance and speed thresholds.
  A held drag never rolls.
- Movement starts the moment the finger touches down. If the release qualifies as a swipe, the gesture becomes a roll;
  the few frames of movement before it aren't noticeable.
- The hero is invulnerable for the first 60% of the roll, then vulnerable for the rest of it plus a short recovery.
  **There is no cooldown**: the vulnerable tail is the only limit, as in Gungeon.
- When a roll ends, the finger is up, so the **lift rule** applies: the hero slides into cover if any is within 2 tiles.
- Touching during a roll buffers movement: the hero starts running as soon as the roll ends.

**Lift: cover or reload**
- On lift, the game looks for cover whose nearest point is within **2 tiles** of the hero. If it finds one, the hero
  slides to the **nearest point** of that cover and crouches (the in-cover state).
- In cover the hero doesn't fire, has a smaller hurtbox, is protected from bullets coming from the cover's side
  (§4.6), and reloads at the fastest speed.
- With no cover in range, the hero stands still, exposed, and reloads.
- A partial magazine starts reloading after the finger has been up for 0.3 s.
- Touching again leaves cover immediately (running and firing).

**Reload**
- An empty magazine reloads automatically, even while running, but slowly.
- Reload speed by state: running ×0.5, standing ×1.0, in cover ×1.4 (relative to the gun's base reload).

**Special (double-tap)**
- Two taps within 0.3 s and no more than 40 px apart, anywhere that isn't a HUD button.
- Fires an EMP pulse (§4.7). The first tap also counts as a lift, so the hero may start sliding toward cover.
  This is accepted for now and checked in M1 (risk R4).

**HUD and interaction**
- HUD buttons sit in the top band, which never spawns the joystick, so tapping them never moves the hero.
- World interactions are proximity-based:
  - **Chests** open on contact.
  - **Pickups** (hearts, ammo, currency) are magnetic.
  - **Guns on the floor, stations, terminals and NPCs** show a **prompt bubble in the top band**; tap it to act.

### 3.4 Tunable parameters (M1 defaults)
| Parameter | Default | Notes |
|---|---|---|
| Joystick zone top edge | 40% of screen height | Test 35–50% |
| Edge dead margin | 16 px | Keeps clear of Android back/home gestures |
| Stick radius / dead zone | 48 px / 8 px | |
| Full speed at | 70% deflection | |
| Swipe max duration | 0.25 s | From touch-down to lift |
| Swipe min distance | 24 px | |
| Swipe min speed | 500 px/s | Measured over the last 100 ms |
| Tap max duration / movement | 0.20 s / 12 px | |
| Double-tap window / max distance | 0.30 s / 40 px | |
| Cover search radius | 2 tiles (32 px) | From the hero's center to the nearest point of the cover shape |
| Cover slide speed | 12 tiles/s | |
| Partial-reload delay after lift | 0.3 s | |
| Target re-evaluation | Every 0.1 s | |

*px means logical pixels at the 360×640 base, which is roughly one dp on most phones. 1 tile = 16 px.*

In the project, the joystick zone and its margins are a `JoystickZone` node in the HUD scene, and every threshold is in
`data/controls/controls_tuning.tres`. Both are edited in the Godot editor ([technical.md](technical.md) §0, §4).

### 3.5 Control settings [PROPOSED]
Joystick visibility, size and opacity · swipe sensitivity presets (Low / Normal / High) · double-tap window ·
aim reticle on/off · haptics.

Known control risks (R1–R4, R7, R8) are listed in [open-questions.md](open-questions.md).

---

## 4. Combat

### 4.1 Moment-to-moment loop
```
touch & run (firing) ─► read the pattern ─► swipe-roll through bullets ─► lift into cover (reload)
        ▲                                                                          │
        └────────── cover breaks / you get flushed out / reload done ◄─────────────┘
```
The core tension is that **you only deal damage while exposed.** Cover gives safety and reloads, never damage.

### 4.2 Hero base stats [PROPOSED]
| Stat | Value |
|---|---|
| Hearts | 3 (6 half-hearts); the Fusion Heart implant adds up to +2 |
| Armor | 0 at start, max 4; each pip absorbs one whole hit |
| Damage per hit | ½ heart (some boss attacks deal 1 heart) |
| Invulnerability after a hit | 1.0 s |
| Hurtbox | 6×6 px (6×4 when crouched), much smaller than the sprite |
| Move speed | 6 tiles/s |
| Roll | 3.5 tiles in 0.40 s, i-frames for the first 60%, then 0.10 s recovery |
| EMP charges | 2 per level |

### 4.3 Health and armor [LOCKED: hearts + armor]
- Hearts go in half steps. Armor pips each absorb a whole hit and are lost before hearts.
- Losing an armor pip clears bullets in a small circle around the hero (1.5 tiles). [PROPOSED]
- Healing comes from rare half-heart drops, repair stations, memory rooms (½ heart, once) and the Fusion Heart implant.

### 4.4 Weapons [LOCKED: 2 slots]
- **Slot 1:** the **Service Pistol**, the starter weapon. Infinite ammo, always carried.
- **Slot 2:** **one found gun** with limited ammo. Taking a new gun drops the current one on the floor, where it can be picked up again.
- Tap the weapon card in the HUD to swap. Swapping is instant, and each gun keeps its own reload state.
- Guns come from **chests** (and from boss and arena rewards). The pool holds only guns this save has
  **unlocked** with Crypto in the lab.
- Stats per gun: damage, fire rate, magazine, reload time, ammo pool, spread, projectile speed, range, trait
  ([content.md](content.md) §3).
- Rarity (Common / Rare / Epic / Legendary) sets chest odds and unlock cost.
- An ammo pickup refills 25% of the found gun's pool.

### 4.5 Auto-aim [LOCKED: nearest visible enemy]
- Candidates are enemies within the current gun's range that have a clear line of sight; walls and cover block sight.
- The nearest one is chosen, with the stickiness rules from §3.3. Decoys can exploit this on purpose (the boss GLITCH).
- Default range is 9 tiles, varying per gun; the Eyes implant extends it.

### 4.6 Cover [LOCKED: destructible, directional, flushable]
**What cover is.** Solid, low objects: crates, barriers, vending machines, server racks, cars. Cover blocks
every bullet that physically hits it, from either side and including the hero's own, and loses HP when hit. Auto-aim's
line-of-sight check means the hero rarely shoots their own cover.

**Directional protection.** While the hero is crouched in cover, bullets arriving from the cover's side (a 180° arc)
are absorbed by the cover, even grazing shots around its edges. Bullets from the open side hit as usual.
The hero slides to the **nearest point**, not the safe side, so choosing where to lift matters.

**Destructible.** Cover has HP and 3 visual damage states. When it breaks, the hero is exposed, with a 0.3 s flash
and sound as warning.

| Material [PROPOSED] | HP | Examples |
|---|---|---|
| Light | 40 | Wooden crates, holo-kiosks |
| Medium | 120 | Metal barriers, vending machines |
| Heavy | 300 | Concrete blocks, server racks |
| Explosive (not cover) | 10 | Barrels: explode for 1 heart within 2 tiles |

**Flushing.** Enemies built to beat cover ([content.md](content.md) §2):
- **Explosions** (grenades) ignore cover protection.
- **EMP fields** short out cover, so it gives no protection while the hero is inside the field.
- **Drones** fire from above, and their bullets ignore cover protection.
- **Hackers** rig a cover object to explode; it blinks red first.
- **Chargers** smash any cover in their path.

**Level design rules.** Cover is placed by hand in each room scene. Every combat room has clusters of cover, no walkable
spot is more than about 6 tiles from cover, and at least one piece of cover sits near each door.

### 4.7 EMP special [LOCKED: double-tap]
- Clears every enemy bullet on screen, stuns enemies within 4 tiles for 1.5 s, and pushes them back 1 tile.
- 2 charges per level, refilled at the start of each level. Extra charges come from repair stations and chests, and the Brain implant improves the EMP.
- Feedback: a strong haptic and a shockwave visual.

### 4.8 Enemies [LOCKED: robots only]
- Every enemy is a machine of the Null Syndicate†, and every robot drops RAM.
- **Telegraph rule:** every attack shows a tell for at least 0.4 s (a glow, laser line or landing circle).
- **Spawn rule:** enemies arrive behind a 0.8 s marker and never within 3 tiles of the hero.
- **Where they appear:** at spawn points placed by hand in each room scene. The game picks which enemy types appear from the
  level's threat budget ([content.md](content.md) §6).
- Rooms run 1–3 waves, and the doors stay locked until the last wave dies.
- From L2, elites spawn with a modifier (Overclocked, Armored, Splitter or Shielded) and drop 3× RAM.
- Edge arrows point to enemies off screen.
- The full roster is in [content.md](content.md) §2.

### 4.9 Bullet readability [PROPOSED, art-independent]
- Enemy bullets are bright and high-contrast with a dark outline, come in 3 sizes, and use a reserved hue family
  (for example magenta and orange) that the environment art never uses.
- Player bullets are smaller and cool-colored, and they render under enemy bullets.
- At most about 300 enemy bullets on screen at once.
- Every pattern leaves a dodgeable gap, and one roll (3.5 tiles) always clears a single bullet line.

### 4.10 Bosses [PROPOSED]
- One gang lieutenant per level. The arena locks, a boss HP bar appears under the HUD band, and the fight has 2–3 phases, each with new patterns.
- The first encounter opens with a comic-panel intro; repeat encounters get a one-line intro.
- The reward is a RAM cache, Crypto and a guaranteed Rare-or-better chest, then the elevator to the lab.
- Each boss teaches one mechanic ([content.md](content.md) §4).

---

## 5. Progression and economy

### 5.1 Currencies [LOCKED]
| | Crypto (◈)† | RAM (MB) |
|---|---|---|
| Comes from | Chests, breakables, room-clear rewards, bosses, challenge arenas | Destroyed robots (every enemy), bosses, arenas |
| Spent on | **Unlocking weapons** in the lab; repair stations inside levels | **Implant surgery** in the lab; hacked terminals inside levels |
| On death | Kept | Kept |
| Real-money purchase | **Never** | **Never** |

RAM shows in MB/GB for flavor, and implant costs are powers of two.

### 5.2 The lab hub [LOCKED: spending happens here]
A small walkable scene visited before every level.

| Station | Function |
|---|---|
| Surgery chair (Dr. Vorn†) | Implants: choose a body slot, then install or upgrade it with RAM |
| Black-market armory (Patch†) | Unlock weapons with Crypto. Patch "stashes" each unlocked gun in the districts, so it shows up in chests |
| Firing range | Try any unlocked weapon, replay the tutorial [PROPOSED] |
| Kade's cot | Family photo, memory codex, endings gallery [PROPOSED] |
| Trophy wall | Defeated bosses (cosmetic) [PROPOSED] |
| Elevator | Starts the next level, or L1 after a death |

A **Quick Start** button skips the walk for players in a hurry.

**Built in M4:** the surgery chair, the armory and the elevator, plus Quick Start; Kade's cot is a prop for now. The
firing range and the trophy wall come later.

### 5.3 Weapon unlocks [LOCKED]
- Paying Crypto once adds the gun to this save's chest pool permanently.
- A new save starts with the Service Pistol and 3 free Commons. [PROPOSED]
- Pool dilution (unlocking weak guns lowers the odds of good ones) is [OPEN] (Q7).

### 5.4 Implants [LOCKED]
- 6 body slots: **Eyes, Brain, Arms, Heart, Lungs, Legs**. Each slot is installed at Mk I and can be upgraded to Mk II and Mk III.
- Implants are **permanent and irreversible**. The first install in each slot needs a hold to confirm, plays a Vorn line and shows a comic panel.
- Every tier visibly changes the hero's sprite (paper-doll overlays) and shifts the tone of the dialogue.
- Costs: Mk I 256 MB, Mk II 512 MB, Mk III 1 GB (1,024 MB). [PROPOSED]
- Effects are listed in [content.md](content.md) §5.

### 5.5 Humanity bands and endings [LOCKED thresholds]
The number of **filled slots** sets the hero's humanity band; tiers don't count.

| Filled slots | Band | Tone | Ending if Zero falls now |
|---|---|---|---|
| 0 | Human | Warm, grieving | **Humanity** (good) |
| 1–2 | Patched | Wry, determined | **Normal** |
| 3–5 | Hollow | Cold, clipped | **Normal** |
| 6 | Machine | Flat, synthetic | **Transformation** (bad) |

- The ending is decided at the moment Zero, the L5 boss, is defeated. Implants can't be bought during L5, so the last
  lab visit locks it in.
- There's no humanity meter in the HUD [LOCKED]; the sprite and the voice show the change.
- The human path is **hard mode by design**: weapons and skill only. [LOCKED]
- The Normal ending has two flavors, Patched (1–2 slots) and Hollow (3–5). After an ending, NG+ threat levels unlock
  (decided in M5; [open-questions.md](open-questions.md)).

### 5.6 Economy pacing targets [PROPOSED; tune in M4/M5]
| Target | Value |
|---|---|
| First Mk I implant affordable | After the first run that clears L1 and reaches L2 (~270–370 MB) |
| All 6 slots at Mk I (Transformation possible) | ~4–5 early runs |
| Every weapon unlocked (3,280 ◈) | ~15–20 runs |
| Income from a typical full clear | ~2,600 MB RAM, ~800 Crypto |

Detailed tables are in [content.md](content.md) §8.

### 5.7 Difficulty curve [PROPOSED]
- Power accumulates every run through implants and unlocks, so the game gets easier for implant users and stays hard for
  human players. That moral pressure is intended.
- Each level adds new enemy types, denser patterns and a bigger threat budget per room ([content.md](content.md) §6).
- After an ending, NG+ **threat levels** unlock one at a time (up to 5): more threat and elites per room for more
  RAM. The player picks the level in the lab ([content.md](content.md) §6).

---

## 6. Levels and rooms

### 6.1 Districts [PROPOSED]
| Level | District† | Boss† | Mechanic it teaches |
|---|---|---|---|
| 1 | Rustline Slums | SCRAPJAW | Destructible cover |
| 2 | Neon Bazaar | GLITCH | Reading bullets; decoys vs. auto-aim |
| 3 | The Foundry | FORGEMOTHER | Moving floors; target priority |
| 4 | Skyline Spires | WARDEN | Directional cover; flanks |
| 5 | Syndicate Core | ZERO | Everything (a mirror duel) |

### 6.2 Room types [LOCKED types, PROPOSED counts]
| Type | Per level | Description |
|---|---|---|
| Start | 1 | Safe room where the elevator arrives; shows the level title |
| Combat | 4–6 | Doors lock; 1–3 waves; a clear reward (Crypto, sometimes ammo or ½ heart) |
| Chest | 1–2 | Dead-end room with one chest (opens on contact) |
| Special | 1–2 | Always 1 Memory room, plus 0–1 of: Challenge arena, Repair station, Hacked terminal |
| Boss | 1 | Boss arena, then the elevator to the lab |

The total is clamped to 8–10 rooms per level.

### 6.3 Special rooms [LOCKED]
- **Memory room:** a quiet story room, one per level, with no enemies. It holds a memory of Lena and Mira, and its
  presentation degrades with the hero's band (clear, then glitched, then corrupted). It restores ½ heart once. [PROPOSED heal]
- **Challenge arena:** optional, and the door asks before you enter. Three hard waves with no way out until they're done, for a big reward.
- **Repair station:** buy ½ heart, armor, an EMP charge or ammo with Crypto. 3 purchases per station.
- **Hacked terminal:** pay RAM for a random outcome: a rare chest, a Crypto jackpot, supplies, an elite ambush, a virus, or nothing.

Prices and odds are in [content.md](content.md) §7.

### 6.4 Map layout [PROPOSED]
- Rooms are separate spaces joined by doors. Walking through a door triggers a quick transition, Isaac-style, rather than one
  continuous stitched map ([technical.md](technical.md) §7 explains why).
- A main path runs from Start to Boss through most combat rooms. Chest and special rooms are dead-end branches, and
  the memory room is never next to Start or Boss.
- **Minimap** (top-right): visited and known rooms with icons. Tap it to open the full map, which pauses the game.

### 6.5 Room size and camera (portrait) [LOCKED: tall rooms]
- 1 tile = 16 px at 360×640, so the screen is 22.5 × 40 tiles.
- Rooms are **22 tiles wide** (walls included) and **1–2 screens tall** (about 32–72 tiles).
- Inside a room the camera never scrolls sideways. It follows the hero vertically, with a lead toward the direction of
  movement and the current target.
- The hero sits at about 45% of the screen height by default, so a thumb resting low on the screen rarely covers the hero
  or the threats ahead. [PROPOSED; tune in M1]
- Wide screens and tablets show extra background past the walls; tall phones show more of the room vertically.

---

## 7. Narrative delivery [LOCKED]
The premise, cast and endings are in [narrative.md](narrative.md). The story is delivered through:
- **Comic panels** for the prologue, first boss encounters, first implants and the endings.
- **Lab dialogue** with Dr. Vorn† and Patch† between levels, with lines that vary by humanity band.
- **Memory rooms** inside levels, which carry the family story.
- Live text only, never baked into images, so everything can be localized.

---

## 8. UX and UI

### 8.1 HUD layout
```
┌──────────────────────────────────────────┐
│ ♥♥♥ ◆◆  ⚡⚡             ◈ 120   ▣ 340 MB  │ hearts · armor · EMP · currencies
│ [Pistol ∞ | Rivet 12/96] ◄ tap      [▦][Ⅱ]│ weapon card · minimap · pause
│ ═══════════ BOSS HP ═══════════           │ (boss rooms only)
│        [ Swap to Volt Shotgun? ]          │ prompt bubble (only when near something)
│                  (world)                  │
│                    ☺  ← hero at ~45%      │
│                                           │
│            ( floating stick )             │
└───────────────────────────────────────────┘
```
- The HUD respects safe areas (notches and rounded corners).

### 8.2 Flow
- **Main flow:** Splash → Title → Save slot select → (new slot: prologue comic → lab tutorial) → Lab → Level → … →
  Ending → Credits → Lab (post-game).
- **Death:** slow-motion → "Retrieved" panel → Second Chance (ad, once per run) → Run summary (+25% Crypto
  ad) → Lab.
- **Built in M4:** title → three save slots → (new slot: prologue comic → rehab tutorial) → lab → Level 1 → lab. Death
  shows one "Retrieved" panel with the run summary (no ads until M6); Vorn's retrieval line plays back in the lab. A run
  in progress shows **Continue run** on its slot card.
- **Built in M5:** two seconds after ZERO falls, the ending for Kade's band plays as a comic, then the credits roll and
  close on Vorn's post-credits line, then the lab. The slot card counts the endings seen; the endings gallery is still
  [PROPOSED].

### 8.3 Onboarding [PROPOSED; built in M4]
A rehab session in the lab's training room teaches one skill per step (each step can be skipped):
1. Drag to walk. The hero auto-fires at target dummies ("your hands remember").
2. Lift next to a crate. The hero slides into cover while a turret fires.
3. Swipe to roll through a line of bullets.
4. Double-tap. The EMP clears a wall of bullets.

Then Vorn introduces the surgery chair: *"When you're ready… I can make you better."*

### 8.4 Feedback
- **Haptics:** hit taken (strong), roll (light), entering cover (light), EMP (strong), reload done (tick).
- **Impact:** 40 ms hit-stop on kills, screen shake (can be turned off), muzzle flash, damage flash.
- **Audio cues:** reload complete, last bullet in the magazine, cover cracking, cover broken, low hearts.

### 8.5 Accessibility and settings [PROPOSED]
Joystick visibility, size and opacity · swipe sensitivity presets · double-tap window · haptics · reduced screen shake
and flashing (glitch effects included) · colorblind-safe bullet palettes · text size · subtitles for all voice ·
language · audio sliders · 30/60 fps (battery).

---

## 9. Monetization [LOCKED principles]
- **Rewarded ads only.** They're always optional and only a small help:
  - *Second Chance:* once per run, revive with 1 heart and a free EMP.
  - *Salvage bonus:* on the run summary, +25% of the Crypto collected that run.
- **Cosmetic IAP:** hero outfits, weapon skins, lab decorations, EMP visual styles.
  - Outfits must work with all 18 implant overlays (an art constraint).
  - Weapon skins can't change a gun's silhouette, bullet color or bullet size (readability).
- **Never sold:** Crypto, RAM, implants, weapons, stats. Endings can't be bought.
- No forced or interstitial ads, no loot boxes, and no real cryptocurrency or NFTs. "Crypto" is fictional in-game money.
- Compliance work at M6: an ad consent flow (GDPR / UMP) before any ad, the Play data-safety form, and the content-rating
  questionnaire.

---

## 10. Audio direction [PROPOSED]
- **Music:** dark synthwave and industrial for the districts, with **adaptive humanity layers**. In the Human band the lab
  theme uses acoustic instruments and Mira's music-box motif. Each lower band replaces human instruments with synths,
  and in the Machine band the motif is bit-crushed.
- **Kade's voice** gets subtle processing per band, ending in a vocoder at Machine.
- **Robot barks** use dark humor ([narrative.md](narrative.md) §10).
- **M4 placeholders:** script-generated sound effects and three loops (lab music box, Rustline synth, boss), on Music
  and SFX buses with volume settings. Adaptive band layers and voice processing come with the real audio.

---

## 11. Art constraints (style still undecided) [LOCKED: undecided until M4]
Whatever style is chosen at the M4 art test has to satisfy these:
- A 360×640 logical base with gameplay measured in 16 px tiles. Sprites can be higher resolution internally.
- The readability rules in §4.9.
- The hero is a **paper doll**: a base body, an outfit and 6 implant layers × 3 tiers, all sharing one animation set.
- Hero animations: idle, run, roll, slide, crouch (in cover), hurt and death, in 8 directions (or 5 plus mirroring).
  The body faces the target while running; the gun is a separate sprite that rotates toward the target.
- Comic-panel speech bubbles stay as separate text layers.

---

## 12. Glossary
| Term | Meaning |
|---|---|
| Band | Humanity tier from the number of filled implant slots: Human / Patched / Hollow / Machine |
| Cover | A destructible object the hero crouches behind on lift |
| EMP | The double-tap special: clears bullets and stuns |
| Flusher | An enemy built to force the hero out of cover |
| Lift | Releasing the finger in any way that isn't a swipe |
| Run | One attempt from L1 until death or an ending |
| Stash | A weapon unlocked with Crypto and added to the chest pool |
| Tile | 16 logical px; the unit for every gameplay distance |
