# Man vs AI — Technical Design

**Version:** 0.1 (draft) · **Engine:** Godot 4.7 · **Language:** GDScript · **Target:** Android, portrait

---

## 1. Project settings (applied in M0)
| Setting | Value | Why |
|---|---|---|
| Renderer (desktop and mobile) | Compatibility (`gl_compatibility`) | Widest Android device support (OpenGL ES 3.0) and plenty for 2D. It also allows web builds for quick playtests |
| Base viewport | 360 × 640 | Portrait 9:16 logical resolution; 1 tile = 16 px |
| Desktop window override | 450 × 800 | A comfortable portrait window for testing on PC |
| Stretch | `canvas_items` + `expand` | Sharp at any resolution. Taller phones see more height, tablets see more width |
| Orientation | Portrait (`window/handheld/orientation=1`) | Locked |
| Emulate touch from mouse | On | Test touch gestures with a mouse on desktop |
| VRAM compression | ETC2/ASTC import on | Needed for Android texture export |
| GDScript warnings | Untyped declarations warn | Pushes the team toward static typing |
| 2D physics layer names | §1.1 | |

Settings that depend on the art style get decided at M4: texture filter (nearest for pixel art), pixel snapping, integer scaling.

### 1.1 Physics layers
| # | Layer | Used by |
|---|---|---|
| 1 | world | Walls, room bounds |
| 2 | cover | Cover objects |
| 3 | player | Hero body and hurtbox |
| 4 | enemies | Robot bodies |
| 5 | player_bullets | Hero projectiles (collide with world, cover, enemies) |
| 6 | enemy_bullets | Enemy projectiles (collide with world, cover, player) |
| 7 | pickups | Hearts, ammo, currency (detect the player) |
| 8 | interactables | Chests, stations, NPCs, doors (detect the player) |

---

## 2. Folder structure
```
res://
├─ assets/              raw art, audio and fonts (placeholders until M4)
│  ├─ art/
│  ├─ audio/
│  └─ fonts/
├─ data/                designer-edited .tres resources
│  ├─ weapons/
│  ├─ implants/
│  ├─ enemies/
│  └─ levels/
├─ localization/        CSV translation tables
├─ src/                 scenes (.tscn) and scripts (.gd), grouped by feature
│  ├─ autoload/         singletons (§3.1)
│  ├─ input/            TouchController and gesture classifier
│  ├─ player/           hero scene, state machine, paper-doll visuals
│  ├─ enemies/          enemy scenes, AI, bullet patterns
│  ├─ bosses/           boss scenes and phase scripts
│  ├─ weapons/          weapon and projectile scenes, bullet pools
│  ├─ cover/            cover objects
│  ├─ levels/
│  │  ├─ generation/    level graph and room selection
│  │  └─ rooms/         handcrafted room templates, per district
│  ├─ hub/              the lab
│  └─ ui/               HUD, menus, comic-panel player
└─ docs/                design documents (contains .gdignore, so Godot skips it)
```
**Conventions:** snake_case file names and PascalCase `class_name`s. Scenes and their scripts sit side by side, with one feature per folder.
Content data lives in `data/` as Resources.

---

## 3. Architecture

### 3.1 Autoloads
| Autoload | Responsibility |
|---|---|
| `EventBus` | Global signals: `enemy_killed`, `room_cleared`, `currency_changed`, `implant_installed`, `player_died`, … |
| `GameState` | The loaded save slot: implants, unlocks, Crypto, RAM, memories, endings, stats. Derives `filled_slots` and `humanity_band` |
| `RunState` | The current run: seed, level index, room states, hearts, armor, weapons and ammo, EMP charges, `revive_used` |
| `SaveManager` | Slot files, atomic writes, versioning and migrations, run snapshots |
| `SceneRouter` | Transitions between title, lab, level and ending; loading screens |
| `AudioManager` | Buses, music stems, adaptive layers by band and combat intensity |
| `Monetization` | Rewarded ads and IAP behind one interface, with a stub on desktop (§12) |

Keep autoloads thin, holding data and signals; gameplay logic lives in scenes.

### 3.2 Data-driven content
Custom `Resource` classes (with `class_name`) live next to the code that uses them, and their `.tres` instances live in `data/`.

| Resource | Key fields |
|---|---|
| `WeaponData` | id, name_key, rarity, unlock_cost, damage, fire_rate, magazine, reload_time, ammo_pool, range_tiles, spread_deg, pellets, projectile (PackedScene), traits |
| `ImplantData` | slot, tier, cost_mb, modifiers (`Array[StatModifier]`), overlay frames, dialogue tag |
| `StatModifier` | stat (enum), op (add / mul), value |
| `EnemyData` | id, scene, hp, threat_cost, ram_drop, first_level |
| `BulletPattern` | count, spread, speed, rotation, waves, interval, aimed |
| `RoomTemplate` | scene, type, district, door_sockets, weight |
| `LevelConfig` | district, room-count ranges, wave and threat table, enemy pool, elite chance, chest odds, boss |
| `ControlsTuning` | every threshold from GDD §3.4 |

Designers balance the game by editing `.tres` files, with no code changes.

### 3.3 Stats
`PlayerStats` holds the base values plus modifiers from installed implants and temporary buffs. It's recomputed when an implant
changes and at the start of each level, and all gameplay reads from it rather than hard-coded values.

---

## 4. Input: TouchController
This is the highest-risk system, so it gets built first (M1), with a live debug overlay.

### 4.1 Output intents
| Intent | Type | When |
|---|---|---|
| `move_vector` | `Vector2` (length 0..1) | Continuously while touching |
| `touching` | `bool` | Firing is allowed while this is true |
| `roll(direction)` | signal | On a swipe release |
| `lifted` | signal | On any release that isn't a swipe |
| `special` | signal | On a double-tap |

The controller handles input in `_unhandled_input`, so HUD controls (`mouse_filter = STOP`) consume their taps first.

### 4.2 Rules
- Track only the first active touch index and ignore any others, since this is a one-finger game.
- A touch-down in the joystick zone (y ≥ 40% of the visible rect, outside the 16 px edge margins) starts the joystick.
  A touch-down in the UI zone that misses every HUD control only counts toward a double-tap.
- Gestures are classified **on release**:
```gdscript
# Illustrative pseudo-code
func _classify_release(release_pos: Vector2, now: float) -> void:
    var duration := now - touch_start_time
    var displacement := release_pos - touch_start_pos
    if duration <= tuning.swipe_max_time \
            and displacement.length() >= tuning.swipe_min_dist \
            and _recent_speed() >= tuning.swipe_min_speed:
        roll.emit(displacement.normalized())
        return
    lifted.emit()
    if duration <= tuning.tap_max_time and displacement.length() <= tuning.tap_max_move:
        if now - last_tap_time <= tuning.double_tap_window \
                and release_pos.distance_to(last_tap_pos) <= tuning.double_tap_max_dist:
            special.emit()
            last_tap_time = -INF
        else:
            last_tap_time = now
            last_tap_pos = release_pos
```
- `_recent_speed()` is the distance covered in the last 100 ms, read from a ring buffer of drag samples.
- Screen positions are converted to logical pixels through the canvas transform, so the thresholds don't depend on resolution.
- The thresholds live in `ControlsTuning`. The debug overlay can edit them at runtime, and the sensitivity settings expose them as presets.

### 4.3 Debug overlay (M1)
- Shows the touch path, the classification result and its timings, the joystick vector, the cover search radius, the current target, FPS
  and the bullet count.
- Has a slider for every threshold.
- Logs misclassifications during playtests.

---

## 5. Player
The hero is a `CharacterBody2D` driven by a state machine:

| State | Entered on | Leaves to |
|---|---|---|
| Run | `touching` | Roll (roll intent), SlideToCover or Stand (lifted), Dead |
| Roll | Roll intent, when not recovering | SlideToCover or Stand when it ends (finger up); Run (finger down or buffered) |
| SlideToCover | Lifted with cover found | InCover on arrival; Run if touched |
| InCover | Arrival at cover | Run (touch), Roll (swipe), Stand (cover destroyed) |
| Stand | Lifted with no cover | Run (touch), Roll (swipe) |
| Dead | Hearts reach 0 | — |

- Hurt is an overlay rather than a state: it plays the invulnerability blink without interrupting the current state.
- The hurtbox is a tiny `Area2D`, 6×6 px (6×4 crouched), separate from the body collider.
- A `Reloader` component ticks with a per-state speed multiplier: running 0.5, standing 1.0, in cover 1.4.
- An `AutoFire` component fires while `touching` is true and `TargetSelector` has a target.

---

## 6. Combat systems

### 6.1 TargetSelector
- Every 0.1 s, it checks the enemies in the `enemies` group that are within range, raycasts against the world and cover layers for line of sight, and picks the nearest.
- Stickiness follows GDD §3.3.
- Decoys are deliberately in the `enemies` group (boss GLITCH).

### 6.2 Projectiles and pooling
- Every bullet comes from a pool: pre-instantiated and recycled, so nothing is instantiated in combat.
- To start, use pooled `Area2D` bullets with straight, arc and homing motion, which are easy to author.
- If profiling on the low-end test device shows trouble above ~300 bullets, move enemy bullets to a `BulletServer`.
  It would move bullets in a packed array, collide through `PhysicsServer2D` shape queries, and draw with one
  `MultiMeshInstance2D`. The `BulletPattern` API stays the same either way.

### 6.3 Cover
- `Cover` is a `StaticBody2D` on the cover layer, with HP, damage-state sprites, and membership in the `cover` group.
- **Search on lift:**
  1. For each cover within (2 tiles + its bounding radius), compute the closest point on its collision shape (a rect clamp or `Geometry2D`
     segment tests).
  2. Keep the nearest one that is within 2 tiles.
  3. The target position is that closest point plus the surface normal × (hero radius + 2 px).
  4. Check reachability with `test_move`. If the target isn't reachable, try the next-nearest cover; if none works, Stand.
- **Slide:** at 12 tiles/s using `move_and_slide`. The slide cancels if the hero is blocked.
- **In-cover protection:** on arrival, store `cover_normal` (pointing from the cover toward the hero). When an enemy bullet reaches the hurtbox
  while the hero is in cover and `bullet_dir.dot(cover_normal) > 0`, the bullet came from the cover side (the 180° arc). The cover absorbs it and takes the damage instead.
- **Bypassing protection:** bullets flagged `explosive` or `aerial` (drones), and any hit while the hero stands inside an `EmpField`.
- **Breaking:** destroyed cover emits a signal, and the hero leaves InCover with an exposed flash.

### 6.4 Enemies
- Each enemy runs a simple state machine: Spawn → Position → Telegraph → Attack → Recover.
- Movement uses `NavigationAgent2D` with navigation from the room's `TileMapLayer`.
- A `Telegraph` component shows the tell and guarantees at least 0.4 s.
- A `WaveSpawner` in each room reads the threat budget from `LevelConfig`. Spawn markers are at least 3 tiles from the hero.

### 6.5 Bosses
- A phase machine is driven by HP thresholds, and each phase is a list of attack patterns with weights and cooldowns.
- The boss HP bar is updated through `EventBus`.

---

## 7. Level generation

### 7.1 Discrete rooms
Rooms are separate scenes joined by door transitions (Isaac-style), not one continuous stitched map (Gungeon-style). Reasons:
- Portrait rooms are one screen wide, so neighboring rooms would never be visible anyway.
- Only one room is in memory at a time, which keeps RAM use low on phones.
- Saving and resuming per room is simple, and generation is deterministic per seed.
- There's no corridor routing or overlap solving.

### 7.2 Algorithm
1. Seed the generator with `rng.seed = hash([run_seed, level_index])`; the same seed always gives the same level.
2. Roll room counts from `LevelConfig` and clamp the total to that level's range ([content.md](content.md) §6).
3. Build the graph:
   - A main path runs Start → combat rooms → Boss.
   - Extra combat rooms branch off the main path.
   - Chest and special rooms are leaves.
   - The memory room is never adjacent to Start or Boss.
4. Lay the graph out on an abstract grid (one cell per room, using a random walk). The grid is used for the minimap and for door
   directions (N/S/E/W).
5. Pick a `RoomTemplate` for each node, matching its type, district and required door sockets, weighted, with no repeats within a level.
6. When the hero enters a room: instance its template, lock or open the doors, and spawn waves from the threat budget.
7. Validate the result: connectivity, counts, and a boss at least 3 rooms from Start. If validation fails, re-roll with the next sub-seed.

A unit test generates 10,000 levels headless and asserts every constraint.

### 7.3 Room template authoring
- **Structure:** a `Room` root containing:
  - a `TileMapLayer` for floor, walls and navigation;
  - `DoorSocket` markers at fixed N/S/E/W positions;
  - `SpawnPoint` markers;
  - `CoverSlot` markers, filled with random cover variants;
  - a `ChestSlot`;
  - the camera bounds.
- **Size:** 22 tiles wide (walls included) and 32–72 tiles tall.
- **Layout rules:** cover within about 6 tiles of every walkable spot, spawn points at least 6 tiles from the doors, and at least one piece of cover next to each door.
- **Launch target:** about 12 combat templates per district, plus 2 for each other room type.

---

## 8. Saving
- **Files** in `user://`:
  - `slot_1.json` to `slot_3.json` (persistent);
  - `run_1.json` to `run_3.json` (the current run);
  - `settings.cfg` (a `ConfigFile`).
- Saves use **JSON, not `.tres`**, so a tampered save file can't execute code. Every file carries a `version` for migrations.
- **Atomic writes:** write to `*.tmp`, then rename.
- **When to write:**
  - on room enter and room clear;
  - when hearts change (debounced to 1 s);
  - immediately after every lab purchase or implant;
  - on `NOTIFICATION_APPLICATION_PAUSED` and `NOTIFICATION_WM_CLOSE_REQUEST`.
- **Resume:** rebuild the level from its seed, mark cleared rooms, and place the hero at the entrance of the saved room.

Slot file sketch (implants: 0 = human, 1–3 = Mk tier):
```json
{
  "version": 1,
  "playtime_s": 0,
  "crypto": 0,
  "ram_mb": 0,
  "implants": {"eyes": 0, "brain": 0, "arms": 0, "heart": 0, "lungs": 0, "legs": 0},
  "unlocked_weapons": ["service_pistol", "scattergun", "buzz_smg", "rivet_driver"],
  "memories": [],
  "endings_seen": [],
  "stats": {"runs": 0, "deaths": 0, "best_level": 0}
}
```

---

## 9. Hero visuals (paper doll)
- A `HeroVisual` node holds the base body, an outfit layer (cosmetic), 6 implant layers and a gun pivot. Every body layer plays the
  same animation frames.
- Layer states come from `GameState.implants` (slot → tier).
- For pixel art, use frame-based `AnimatedSprite2D` layers with a shared frame layout. For HD art, use a `Skeleton2D` cutout rig that swaps
  textures per bone. This gets decided at M4 along with the art style.
- Art budget: 18 implant overlay sets (6 slots × 3 tiers) per outfit-compatible body.

---

## 10. Localization
- Every player-facing string is a key such as `tr("ui.play")`. Data Resources store keys, never text.
- The source table is `localization/strings.csv` (columns `keys,en`). Godot imports it as translations, and it's registered under Project
  Settings → Localization.
- Comic panels are art without text, with the bubbles drawn by `Label` or `RichTextLabel` nodes.
- Pick a font family with wide script coverage (Noto, for example) so new languages don't force a font change.
- Keep layouts tolerant of text that's 30% longer, and avoid hard-coded left/right positions so right-to-left languages stay possible.

---

## 11. Android
- Export with the official Godot 4.7 Android export template. The ad and billing plugins (M6) will need a Gradle build.
- Build arm64-v8a; armeabi-v7a is optional for older devices.
- Turn on immersive mode, which hides the navigation bar and cuts down on accidental system gestures.
- Keep the 16 px edge margins out of the joystick zone so back and home gestures don't fight with swipes.
- Target whatever API level Google Play requires at release time; check the Play Console before M6.
- **Never commit signing keystores.** `*.keystore` and `*.jks` are gitignored; keep them in a password manager or a CI secret.
- Target an AAB of 150 MB or less.

---

## 12. Monetization integration (M6)
The `Monetization` autoload exposes one interface:
```gdscript
signal rewarded_completed(placement: StringName, granted: bool)
signal purchase_completed(product_id: StringName, success: bool)

func show_rewarded(placement: StringName) -> void
func purchase(product_id: StringName) -> void
func owns(product_id: StringName) -> bool
func restore_purchases() -> void
```
- **Desktop and debug builds:** a stub that grants everything instantly.
- **Android:** an AdMob plugin for Godot 4 (including Google's UMP consent) plus a Google Play Billing plugin.
  - When M6 starts, check that both work with Godot 4.7.
  - Keep both behind this interface so either can be swapped out.
- **Consent first:** no ads before the consent flow has run, and no personalized ads without consent.
- **Purchases:** cosmetics only, so client-side purchase acknowledgment is enough.

---

## 13. Performance budgets
| Metric | Target |
|---|---|
| Frame rate | 60 fps on mid-range phones; never below 30 on the low-end test device |
| Enemy bullets on screen | 300 or fewer |
| Enemies alive at once | 15 or fewer |
| Memory | Under 500 MB |
| Room transition | Under 0.3 s |

- No allocations in hot loops. Pool bullets, VFX and hit flashes.
- Atlas textures, and keep materials batch-friendly.
- Test devices from M1 onward: one low-end phone (about 3 GB RAM, around 2020), one mid-range phone, one tall-screen phone, and one tablet
  for layout checks.
- Settings offer an optional 30 fps cap to save battery.

---

## 14. Code conventions
- Follow the official GDScript style guide, and use static typing everywhere (the project setting makes untyped code warn).
- Name signals in the past tense (`room_cleared`) and handlers `_on_<node>_<signal>`.
- No magic numbers in scripts: tuning values live in Resources.
- Set up Git LFS for large binaries (art and audio) once real assets arrive at M4.
- Work on feature branches and merge through reviewed pull requests.

## 15. Testing
- Unit-test the pure logic: the gesture classifier, level-generator constraints and determinism, economy math, and save migrations.
  Pick GUT or gdUnit4 at M1.
- Playtest builds include the debug overlay. Optional local telemetry (deaths per room, gesture misclassifications) only runs with the tester's consent.
- Every milestone ends with a playtest on real devices ([roadmap.md](roadmap.md)).
