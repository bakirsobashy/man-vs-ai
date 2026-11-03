# Man vs AI — Technical Design

**Version:** 0.2 (draft) · **Engine:** Godot 4.7 · **Language:** GDScript · **Target:** Android, portrait

---

## 0. Scene-first development (read this first) [LOCKED]

> **The project is developed node-based.** Anything you can see, collide with or position is a node in a `.tscn` scene,
> built in the Godot editor. Scripts add behavior to those nodes; they never build them. When you open any scene in the
> editor, you see exactly what the game uses, and you can change it there.

### 0.1 The rule
| Code MAY | Code must NOT |
|---|---|
| Add behavior to nodes that already exist in the scene | Construct nodes, sprites, areas, bodies, shapes, timers, cameras or UI (`Area2D.new()`, `CollisionShape2D.new()`, `Sprite2D.new()`, `Timer.new()`, `RectangleShape2D.new()`, …) |
| Change properties of existing nodes: `visible`, `process_mode`, `text`, `value`, `scale`, animation playback | Assemble node trees in `_ready()` or anywhere else |
| Move things at runtime (movement, physics, aiming) | Hard-code layout positions, sizes, shape dimensions, collision layers/masks or groups. Set them in the scene |
| Make **copies of authored scenes** (`@export var bullet_scene: PackedScene` → `instantiate()`) and place them at positions read from marker nodes | Connect signals between nodes of the same scene. Do it in the editor (Node dock → Signals) |
| Connect to the `EventBus` autoload, and to signals of a runtime copy it just created | Draw game visuals with `_draw()` |
| Draw the debug overlay and `@tool` editor gizmos with `_draw()` | |

### 0.2 Runtime copies (allowed)
Some things can't exist before play, so they are authored once as scenes and copied at runtime. Everything inside them
(sprites, shapes, markers) is still built in the editor.

| Copy of | Made by | Placed at |
|---|---|---|
| Bullet scenes (`player_bullet.tscn`, `enemy_bullet_small.tscn`, …) | `BulletPool` nodes, which pre-copy them when a level loads | The weapon's `Muzzle`, or an enemy's `BulletEmitter` |
| Pickups and effects (`pickup_*.tscn`, `fx_*.tscn`) | The enemy's `Drops` component | Where the enemy died |
| Enemy scenes | `WaveSpawner` | A hand-placed `SpawnPoint` in the room |
| Weapon scenes | Chests and the player's weapon swap | `WeaponSlot`, or the chest's drop spot |
| Room templates | `LevelGenerator` | The level's `RoomHolder` node |

### 0.3 How scripts find nodes
- Mark nodes that a script needs as **scene-unique** (`%Hurtbox`), then use `@onready var hurtbox: Area2D = %Hurtbox`.
- For a node outside the scene, add an `@export var target: Node2D` and assign it in the Inspector.
- Avoid long relative paths like `get_node("../../HUD/Joystick")`.

### 0.4 Where the numbers live
| Data | Lives in | Edited in |
|---|---|---|
| Player stats (speed, roll, hearts, reload multipliers) | `@export` on the root of `player.tscn` and its `Health` node | Inspector |
| Weapon stats (damage, fire rate, magazine, reload, ammo, spread, pellets) | `@export` on each weapon scene's root. Its range is the circle of its `Range` area | Inspector / viewport |
| Enemy stats (HP, speed, RAM drop, spawn kind) | `@export` on each enemy scene's root | Inspector |
| Bullet patterns | `BulletEmitter` nodes inside enemy and boss scenes (count, spread, speed, interval). Rotate the node to aim it | Inspector / viewport |
| Cover HP and material | `@export` on each cover scene | Inspector |
| Boss phases | `PhaseN` nodes (HP threshold export) holding attack nodes | Scene dock / Inspector |
| Timings (invulnerability, retarget interval, attack rhythm) | `wait_time` of `Timer` nodes | Inspector |
| Implant definitions | `data/implants/*.tres` (`ImplantData`) | Inspector |
| Level settings: room counts, room pool, enemy pool with threat costs, elite chance, chest odds | `data/levels/level_N.tres` (`LevelConfig`) | Inspector |
| Weapon catalog: id, scene, rarity, unlock cost, icon | `data/weapons/weapon_catalog.tres` | Inspector |
| Control thresholds (GDD §3.4) | `data/controls/controls_tuning.tres`, assigned to the `TouchController` | Inspector |

Document every `@export` with a `##` comment so it shows as an Inspector tooltip, and use `@export_range` where a
value has sensible limits.

### 0.5 Building blocks
- **Timers:** `Timer` nodes with their wait time in the Inspector. Don't use `create_timer()` for gameplay timing.
- **Animation:** `AnimationPlayer` tracks and `AnimatedSprite2D` (`SpriteFrames` resources) for hit flashes, telegraphs,
  rolls, crouching and breaking cover. Code only calls `play("name")`.
- **State machines:** a `StateMachine` node with one child node per state (`Run`, `Roll`, …), each with its own script.
  The states are visible in the Scene dock.
- **Components:** reusable behavior as small nodes with a `class_name` (and an `@icon`), so they appear in the
  *Create New Node* dialog: `Health`, `Hurtbox`, `BulletEmitter`, `SpawnPoint`, `Drops`, `StateMachine`,
  `TargetSelector`, `BossPhase`. They live in `src/components/`.
- **Groups** (`enemies`, `cover`, `pickups`) are assigned in the editor (Node dock → Groups) and saved with the scene.
- **Autoloads that need nodes are scenes.** `audio_manager.tscn` has one `AudioStreamPlayer` per music stem, and
  `scene_router.tscn` has the fade `ColorRect` and its `AnimationPlayer`. Pure data and signal autoloads (`EventBus`,
  `GameState`, `RunState`, `SaveManager`, `Monetization`) are scripts.
- **UI:** every screen is a Control scene (`hud.tscn`, `lab_menu.tscn`, …) laid out in the editor with anchors and
  containers. Code only fills in values.

### 0.6 Exceptions
A rare, justified case (debug tooling, for example) is tagged on the line with `# scene-first: allow <reason>` and
needs the owner's OK in review.

### 0.7 Guardrails
- **`CLAUDE.md`** tells every Claude Code session to follow this section.
- **`tools/check_scene_first.sh`** fails if any script in `src/` constructs nodes or collision shapes.
- **`tools/check_scenes.gd`** loads and instantiates every scene under `src/`, and checks that every editor signal
  connection still points to a real signal and method.
- **The review checklist** in §14.

### 0.8 Example scene trees
`%Name` marks a scene-unique node. A component name in brackets (`Hurtbox: Area2D`) means an `Area2D` running the
`Hurtbox` component script.

**Player** (`src/player/player.tscn`)
```
Player (CharacterBody2D)              player.gd — exports: move_speed, roll_distance, roll_time, iframe_ratio,
│                                     recovery_time, reload_speed_running / _standing / _cover
├─ BodyShape (CollisionShape2D)       CircleShape2D — body vs. walls and cover (layer: player)
├─ Visual (HeroVisual)                instance of hero_visual.tscn
├─ GunPivot (Node2D)                  rotated toward the current target
│  └─ %WeaponSlot (Node2D)            the equipped weapon's scene sits here
├─ %Hurtbox (Hurtbox: Area2D)         child CollisionShape2D: RectangleShape2D 6×6 (layer: player)
├─ %CoverSensor (Area2D)              child CollisionShape2D: CircleShape2D r = 32 px — the 2-tile cover radius (mask: cover)
├─ %LineOfSight (RayCast2D)           mask: world, cover
├─ %StateMachine (StateMachine)       children: Run · Roll · SlideToCover · InCover · Stand · Dead
├─ %Health (Health)                   exports: max_half_hearts, max_armor — uses InvulnTimer
├─ %TargetSelector (TargetSelector)
├─ RetargetTimer (Timer)              0.1 s
├─ InvulnTimer (Timer)                1.0 s
├─ PartialReloadTimer (Timer)         0.3 s
├─ AnimationPlayer                    hurt_blink, roll, crouch
└─ Sounds (Node2D)                    Roll · Hurt · CoverEnter (AudioStreamPlayer2D)
```

**Weapon** (`src/weapons/scattergun/scattergun.tscn`)
```
Scattergun (Node2D)                   weapon.gd — exports: damage, fire_rate, magazine, reload_time, ammo_pool,
│                                     spread_deg, pellets, bullet_pool
├─ Sprite (Sprite2D)
├─ %Muzzle (Marker2D)                 bullets start here
├─ %Range (Area2D)                    child CollisionShape2D: CircleShape2D r = 144 px (9 tiles) (mask: enemies)
├─ FireTimer (Timer)
├─ ReloadTimer (Timer)
├─ MuzzleFlash (AnimatedSprite2D)
└─ ShotSound (AudioStreamPlayer2D)
```

**Bullet** (`src/weapons/bullets/enemy_bullet_small.tscn`)
```
EnemyBulletSmall (Area2D)             bullet.gd — exports: speed, damage, lifetime, explosive, aerial (layer: enemy_bullets)
├─ Shape (CollisionShape2D)           CircleShape2D r = 3 px
├─ Sprite (Sprite2D)
└─ ScreenNotifier (VisibleOnScreenNotifier2D)   returns the bullet to its pool when it leaves the screen
```

**Enemy** (`src/enemies/grunt/grunt.tscn`)
```
Grunt (CharacterBody2D)               enemy.gd — exports: max_hp, move_speed, ram_drop, spawn_kind
├─ BodyShape (CollisionShape2D)
├─ Sprite (AnimatedSprite2D)
├─ %Hurtbox (Hurtbox: Area2D)         child CollisionShape2D (layer: enemies)
├─ %Emitter (BulletEmitter)           exports: bullet_pool, count, spread_deg, speed, burst, interval, aimed — rotate to aim
├─ TelegraphGlow (Sprite2D, hidden)   shown by the "telegraph" animation
├─ NavigationAgent2D
├─ %StateMachine (StateMachine)       children: Spawn · Position · Telegraph · Attack · Recover
├─ EliteFX (Node2D, hidden)           turned on when the spawner makes this enemy an elite
├─ %Drops (Drops)                     exports: drop scenes and chances
├─ AttackTimer (Timer)
└─ AnimationPlayer                    spawn_in, telegraph, hurt, die
```
The Sniper adds a `LaserSight (Line2D)`. The EMP-bot carries an `EmpField (Area2D)` child with its 3-tile circle.

**Cover** (`src/cover/crate_light.tscn`)
```
CrateLight (StaticBody2D)             cover.gd — exports: max_hp = 40, material (layer: cover, group: cover)
├─ Shape (CollisionShape2D)           RectangleShape2D 32×16
├─ Sprite (AnimatedSprite2D)          frames: intact · cracked · broken
├─ BreakFX (CPUParticles2D)
├─ AnimationPlayer                    hit, break
└─ BreakSound (AudioStreamPlayer2D)
```

**Room template** (`src/levels/rooms/rustline/rustline_combat_03.tscn`)
```
RustlineCombat03 (Node2D)             room.gd
├─ Floor (TileMapLayer)
├─ Walls (TileMapLayer)               collision and navigation come from the tileset
├─ Doors (Node2D)                     DoorN · DoorS · DoorE · DoorW — door.tscn instances, each with an Entry marker;
│                                     doors the map doesn't use are sealed at runtime
├─ Cover (Node2D)                     hand-placed cover instances: CrateLight · CrateLight2 · BarrierMedium · …
├─ SpawnPoints (Node2D)               SpawnPoint · SpawnPoint2 · … — exports: kinds (ground / flyer / stationary), waves (1–3)
├─ Hazards (Node2D)                   barrels, conveyors (instances)
├─ ChestSpot (Marker2D)               chest rooms only
└─ CameraBounds (ReferenceRect)       the camera's limits in this room
```

**Level** (`src/levels/generation/level.tscn`)
```
Level (Node2D)                        level.gd — exports: config (LevelConfig .tres)
├─ RoomHolder (Node2D)                the current room's copy goes here
├─ Player (player.tscn instance)
├─ Camera (Camera2D)                  limits come from the room's CameraBounds
├─ BulletPools (Node)                 PlayerBullets · EnemyBulletsSmall · EnemyBulletsLarge (BulletPool — exports: bullet_scene, size)
├─ LevelGenerator (Node)              picks room scenes from the config
├─ WaveSpawner (Node)                 copies enemy scenes to SpawnPoints from the threat budget
└─ HUD (hud.tscn instance)
```

**HUD** (`src/ui/hud.tscn`)
```
HUD (CanvasLayer)
├─ %JoystickZone (Control)            anchored to the lower 60% with 16 px side and bottom margins — the zone IS this node
├─ %Joystick (Control)                Ring · Knob (TextureRect), moved to the touch point
├─ TopBand (MarginContainer)          hearts, armor, EMP, currencies, weapon card, minimap, pause
├─ %PromptBubble (Button, hidden)
├─ %BossBar (ProgressBar, hidden)
├─ EdgeArrows (Control)               Arrow1 … Arrow8 (hidden, pre-placed)
├─ DebugOverlay (Control, hidden)     M1 tuning sliders
└─ %TouchController (TouchController) exports: tuning (controls_tuning.tres), zone (JoystickZone)
```

**Hero paper doll** (`src/player/hero_visual.tscn`)
```
HeroVisual (Node2D)                   hero_visual.gd — shows the layers that match GameState.implants
├─ Body (AnimatedSprite2D)
├─ Outfit (AnimatedSprite2D)          cosmetic
├─ Implants (Node2D)                  EyesMk1 · EyesMk2 · EyesMk3 · BrainMk1–3 · ArmsMk1–3 · HeartMk1–3 ·
│                                     LungsMk1–3 · LegsMk1–3 (18 AnimatedSprite2D nodes, hidden)
└─ AnimationPlayer                    drives every layer with the same animation
```

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
Layers and masks are set on each node in the Inspector, never in code.

| # | Layer | Used by |
|---|---|---|
| 1 | world | Walls, room bounds |
| 2 | cover | Cover objects |
| 3 | player | Hero body and hurtbox |
| 4 | enemies | Robot bodies and hurtboxes |
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
├─ data/                non-world data as .tres resources, edited in the Inspector (§0.4)
│  ├─ controls/         controls_tuning.tres
│  ├─ implants/         one ImplantData per slot and tier
│  ├─ levels/           one LevelConfig per level
│  └─ weapons/          weapon_catalog.tres (combat stats live on the weapon scenes)
├─ localization/        CSV translation tables
├─ src/                 scenes (.tscn) and their scripts (.gd), grouped by feature
│  ├─ autoload/         EventBus, GameState, RunState, SaveManager, Monetization; audio_manager.tscn, scene_router.tscn
│  ├─ components/       reusable component nodes: Health, Hurtbox, BulletEmitter, SpawnPoint, Drops, StateMachine, …
│  ├─ input/            TouchController
│  ├─ player/           player.tscn, hero_visual.tscn, state scripts
│  ├─ enemies/          one folder per enemy (scene, script, art)
│  ├─ bosses/           one folder per boss
│  ├─ weapons/          one folder per weapon; bullets/ for bullet scenes
│  ├─ cover/            cover scenes by material
│  ├─ levels/
│  │  ├─ generation/    level.tscn, LevelGenerator, WaveSpawner
│  │  └─ rooms/         room template scenes, one folder per district
│  ├─ hub/              the lab
│  └─ ui/               HUD, menus, comic-panel player
├─ tools/               check scripts (§0.7)
└─ docs/                design documents (contains .gdignore, so Godot skips it)
```
**Conventions:** snake_case file names and PascalCase `class_name`s. Scenes and their scripts sit side by side, with
one feature per folder.

---

## 3. Architecture

### 3.1 Autoloads
| Autoload | Kind | Responsibility |
|---|---|---|
| `EventBus` | Script | Global signals: `enemy_killed`, `room_cleared`, `currency_changed`, `implant_installed`, `player_died`, … |
| `GameState` | Script | The loaded save slot: implants, unlocks, Crypto, RAM, memories, endings, stats. Derives `filled_slots` and `humanity_band` |
| `RunState` | Script | The current run: seed, level index, room states, hearts, armor, weapons and ammo, EMP charges, `revive_used` |
| `SaveManager` | Script | Slot files, atomic writes, versioning and migrations, run snapshots |
| `SceneRouter` | **Scene** | Transitions between title, lab, level and ending. Its fade `ColorRect` and `AnimationPlayer` are nodes in `scene_router.tscn` |
| `AudioManager` | **Scene** | Buses, music stems, adaptive layers by band and combat intensity. One `AudioStreamPlayer` node per stem in `audio_manager.tscn` |
| `Monetization` | Script | Rewarded ads and IAP behind one interface, with a stub on desktop (§12) |

Keep autoloads thin, holding data and signals; gameplay logic lives in scenes.

### 3.2 Non-world data (`.tres` resources)
Things that exist in the world keep their numbers on their own scenes (§0.4). Only data that isn't an object in the world
uses custom `Resource` classes. The classes (with `class_name`) live next to the code that uses them, and their `.tres`
files live in `data/`.

| Resource | File(s) | Key fields |
|---|---|---|
| `ImplantData` | `data/implants/*.tres` | slot, tier, cost_mb, modifiers (`Array[StatModifier]`), dialogue tag. Its overlay is the HeroVisual node named `<Slot>Mk<tier>` |
| `StatModifier` | Inside `ImplantData` | stat (enum), op (add / mul), value |
| `LevelConfig` | `data/levels/level_1.tres` … | district, room-count ranges, room pool (scene, type, weight), waves and threat per wave, enemy pool (scene, threat cost, first wave), elite chance, chest odds, boss scene |
| `WeaponCatalog` | `data/weapons/weapon_catalog.tres` | entries: id, scene, rarity, unlock cost, icon |
| `ControlsTuning` | `data/controls/controls_tuning.tres` | every threshold from GDD §3.4 |

Designers balance the game in the Inspector, with no code changes.

### 3.3 Stats
`PlayerStats` combines the base values exported on `player.tscn` with modifiers from installed implants and temporary
buffs. It's recomputed when an implant changes and at the start of each level, and all gameplay reads from it rather than
hard-coded values.

---

## 4. Input: TouchController
This is the highest-risk system, so it gets built first (M1), with a live debug overlay. The `TouchController` node lives
in `hud.tscn` (§0.8).

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
- **The joystick zone is a node.** A touch-down inside the rect of `%JoystickZone` starts the joystick. That `Control`
  is anchored to the lower 60% of the screen with 16 px side and bottom margins, so changing the split or the margins
  means resizing the node in the editor. A touch-down outside it that misses every HUD control only counts toward a double-tap.
- The joystick graphic is the `%Joystick` Control (ring and knob), shown and moved to the touch point.
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
- The thresholds live in `data/controls/controls_tuning.tres`, assigned to the controller's `tuning` export in the
  Inspector. The debug overlay edits that resource at runtime, and the sensitivity settings swap in preset resources.

### 4.3 Debug overlay (M1)
- A hidden `DebugOverlay` Control in `hud.tscn`, with a slider for every threshold.
- It shows the touch path, the classification result and its timings, the joystick vector, the current target, FPS and
  the bullet count. Drawing the touch path with `_draw()` is allowed here (§0.1).
- Logs misclassifications during playtests.

---

## 5. Player
The hero is `player.tscn` (tree in §0.8): a `CharacterBody2D` whose states are child nodes of its `StateMachine`.

| State | Entered on | Leaves to |
|---|---|---|
| Run | `touching` | Roll (roll intent), SlideToCover or Stand (lifted), Dead |
| Roll | Roll intent, when not recovering | SlideToCover or Stand when it ends (finger up); Run (finger down or buffered) |
| SlideToCover | Lifted with cover found | InCover on arrival; Run if touched |
| InCover | Arrival at cover | Run (touch), Roll (swipe), Stand (cover destroyed) |
| Stand | Lifted with no cover | Run (touch), Roll (swipe) |
| Dead | Hearts reach 0 | — |

- **Hurt** is an overlay, not a state: `InvulnTimer` runs and the `hurt_blink` animation plays without interrupting
  the current state.
- **The hurtbox and the cover radius are visible in the editor.** They're the `%Hurtbox` rectangle (6×6 px, 6×4 when
  crouched via the `crouch` animation) and the `%CoverSensor` circle (32 px).
- **Reload lives in the weapon scene,** because each gun keeps its own magazine. The player's current state passes
  its speed multiplier to the equipped weapon: running 0.5, standing 1.0, cover 1.4, all exported on `player.tscn`.
- **Auto-fire:** while `touching` is true and `TargetSelector` has a target, the player tells the weapon in
  `%WeaponSlot` to fire.

---

## 6. Combat systems

### 6.1 TargetSelector
- **Candidates:** enemy bodies overlapping the equipped weapon's `%Range` area. Its circle shows the range in the editor,
  and the Eyes implant scales it up.
- **Line of sight:** the player's `%LineOfSight` RayCast2D. For each candidate, set its `target_position`, call
  `force_raycast_update()`, and check whether the ray reached the enemy.
- The nearest visible enemy wins, with stickiness following GDD §3.3. `RetargetTimer` (0.1 s) triggers each re-evaluation.
- Decoys are deliberately in the `enemies` group (boss GLITCH).

### 6.2 Projectiles and pooling
- **Bullets are authored scenes** (§0.8): `player_bullet.tscn`, `enemy_bullet_small.tscn`, `enemy_bullet_medium.tscn`,
  `enemy_bullet_large.tscn`, `grenade.tscn`.
- **Pooling:** each `BulletPool` node in `level.tscn` pre-copies its `bullet_scene` `size` times when the level loads,
  then hands bullets out and takes them back. Nothing is instanced in the middle of a fight.
- **Node-friendly performance:**
  - bullets are only `monitorable`, and the hurtboxes do the monitoring;
  - circle shapes only;
  - movement is a few lines in `_physics_process`;
  - bullets are recycled through their `VisibleOnScreenNotifier2D`;
  - a cap of 300 enemy bullets.
- **No node-less bullet system.** Drawing bullets in code with no nodes is ruled out. It would only be considered with
  the owner's explicit approval, and only if a low-end test device can't hold 30 fps after the steps above.

### 6.3 Cover
- **Cover scenes:** one per material (`crate_light.tscn`, `barrier_medium.tscn`, `block_heavy.tscn`,
  `barrel_explosive.tscn`; tree in §0.8). They are **placed by hand** in every room scene.
- **Search on lift:**
  1. The player's `%CoverSensor` (32 px circle) lists the cover bodies in range with `get_overlapping_bodies()`.
  2. For each one, compute the closest point on its collision shape (a rect clamp or `Geometry2D` segment tests).
  3. Keep the nearest one that is within 2 tiles.
  4. The target position is that closest point plus the surface normal × (hero radius + 2 px).
  5. Check reachability with `test_move`. If the target isn't reachable, try the next-nearest cover; if none works, Stand.
- **Slide:** at 12 tiles/s using `move_and_slide`. The slide cancels if the hero is blocked.
- **In-cover protection:** on arrival, store `cover_normal` (pointing from the cover toward the hero). When an enemy bullet
  reaches the hurtbox while the hero is in cover and `bullet_dir.dot(cover_normal) > 0`, the bullet came from the cover
  side (the 180° arc). The cover absorbs it and takes the damage instead.
- **Bypassing protection:**
  - bullets whose scene exports `explosive` or `aerial` (drones);
  - any hit while the hero stands inside an `EmpField` area.
- **Damage and breaking:** HP thresholds switch the `Sprite` frame (intact, cracked, broken). At 0 HP the `break` animation
  plays the particles and sound, the cover emits `destroyed`, and the hero leaves InCover with an exposed flash.

### 6.4 Enemies
- **Scenes:** one enemy scene per type (tree in §0.8), in its own folder.
- **Attacks:** `BulletEmitter` nodes inside the scene. Patterns that aren't aimed are pointed by rotating the emitter
  in the editor, and enemies with several guns get several emitters.
- **Telegraphs:** nodes animated by the `AnimationPlayer`:
  - the `TelegraphGlow` sprite;
  - the Sniper's `LaserSight` Line2D, whose end point the script updates;
  - the Grenadier's landing circle, a copy of `landing_marker.tscn` placed at the target.
  The telegraph animation's length enforces the 0.4 s minimum.
- **Movement:** `NavigationAgent2D`, with navigation taken from the room's `Walls` TileMapLayer.
- **Spawning:**
  - The `WaveSpawner` in `level.tscn` reads the threat budget and enemy pool from `LevelConfig`.
  - It copies enemy scenes to the room's **hand-placed `SpawnPoint`s**. Each SpawnPoint's `kinds` and `waves` exports limit which enemies can appear there, and in which wave.
  - Spawn points within 3 tiles of the hero are skipped.
  - To make an elite, the spawner turns on the copy's `EliteFX` node and applies the modifier.
- **Deaths:** copies report through `EventBus.enemy_killed`, so no per-copy wiring is needed.

### 6.5 Bosses
```
Scrapjaw (CharacterBody2D)            boss.gd — exports: max_hp
├─ BodyShape · Sprite · %Hurtbox      as in an enemy scene
├─ Phases (Node)
│  ├─ Phase1 (BossPhase)              exports: until_hp = 0.60 — children: Charge (ChargeAttack) · BoltSpray (BulletEmitter)
│  ├─ Phase2 (BossPhase)              exports: until_hp = 0.25 — children: MagnetPull · ScrapDrop
│  └─ Phase3 (BossPhase)              exports: until_hp = 0.00 — children: Grind (BulletEmitter, spiral) · Charge
├─ AttackTimer (Timer)
└─ AnimationPlayer
```
- The boss moves to the next `PhaseN` node when its HP crosses that phase's threshold.
- Attacks are child nodes with exported weights and cooldowns.
- The arena is a room template scene.
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
5. Pick a room scene for each node from the `LevelConfig` room pool, matching its type and weighted, with no repeats within a level.
   Every template has all four doors, so any room fits any position.
6. When the hero enters a room:
   - add a copy of its scene to `RoomHolder`;
   - set each door to open, locked or sealed;
   - place the hero at the entry door's `Entry` marker;
   - set the camera limits from `CameraBounds`;
   - let the `WaveSpawner` fill the hand-placed SpawnPoints.
7. Validate the result: connectivity, counts, and a boss at least 3 rooms from Start. If validation fails, re-roll with the next sub-seed.

A unit test generates 10,000 levels headless and asserts every constraint.

### 7.3 Room template authoring
- **Structure:** each room is a scene built entirely in the editor (tree in §0.8). It has:
  - floor and wall tiles;
  - four `door.tscn` instances;
  - hand-placed cover;
  - hand-placed `SpawnPoint`s;
  - optional hazards and a `ChestSpot`;
  - a `CameraBounds` rect.
- **Size:** 22 tiles wide (walls included) and 32–72 tiles tall.
- **Layout rules:**
  - Cover within about 6 tiles of every walkable spot, mixing light, medium and heavy, with at least one piece next to each door.
  - At least 8 SpawnPoints per combat room, at least 6 tiles from the doors, mixing ground, flyer and stationary kinds.
  - `CameraBounds` covers the whole room.
- **Launch target:** about 12 combat templates per district, plus 2 for each other room type.

---

## 8. Saving
- **Files** in `user://`:
  - `slot_1.json` to `slot_3.json` (persistent);
  - `run_1.json` to `run_3.json` (the current run);
  - `settings.cfg` (a `ConfigFile`).
- Saves use **JSON, not `.tres`**, so a tampered save file can't execute code. Every file carries a `version` for migrations.
- Saves store data only, never nodes. On resume, rooms are rebuilt by copying the same authored scenes.
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
- `hero_visual.tscn` (tree in §0.8) already contains every layer: the base body, the outfit and all 18 implant overlays (6 slots × 3 tiers).
- `hero_visual.gd` only shows the overlay that matches `GameState.implants[slot]` and hides the others. It also swaps the
  outfit's `SpriteFrames` for cosmetics.
- For pixel art, every layer is an `AnimatedSprite2D` sharing the same animation names. For HD art, it becomes a
  `Skeleton2D` cutout rig with one pre-placed `Sprite2D` per bone and slot. This gets decided at M4 along with the art style.
- Art budget: 18 implant overlay sets per outfit-compatible body.

---

## 10. Localization
- **Text typed in the editor:** type translation keys directly into the text of Labels and Buttons (for example `ui.play`),
  and Godot translates them automatically.
- **Text built in code:** use `tr()` only here (counters, numbers). Data Resources store keys, never text.
- The source table is `localization/strings.csv` (columns `keys,en`). Godot imports it as translations, and it's registered under Project
  Settings → Localization.
- Comic panels are Control scenes: art without text, with `Label` or `RichTextLabel` bubbles placed in the editor.
- Pick a font family with wide script coverage (Noto, for example) so new languages don't force a font change.
- Keep layouts tolerant of text that's 30% longer, and avoid hard-coded left/right positions so right-to-left languages stay possible.

---

## 11. Android
- Export with the official Godot 4.7 Android export template. The ad and billing plugins (M6) will need a Gradle build.
- Build arm64-v8a; armeabi-v7a is optional for older devices.
- Turn on immersive mode, which hides the navigation bar and cuts down on accidental system gestures.
- Keep the 16 px edge margins of `%JoystickZone` clear so back and home gestures don't fight with swipes.
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

- No allocations in hot loops. Bullets, VFX and hit flashes are pooled copies of authored scenes.
- Atlas textures, and keep materials batch-friendly.
- Test devices from M1 onward: one low-end phone (about 3 GB RAM, around 2020), one mid-range phone, one tall-screen phone, and one tablet
  for layout checks.
- Settings offer an optional 30 fps cap to save battery.

---

## 14. Code conventions
- **Scene-first (§0) comes before everything else.**
- Follow the official GDScript style guide, and use static typing everywhere (the project setting makes untyped code warn).
- Name signals in the past tense (`room_cleared`). Editor-connected handlers use the editor's default name, `_on_<node>_<signal>`.
- No magic numbers in scripts: values are `@export`s, `Timer` wait times, or `.tres` data (§0.4).
- Set up Git LFS for large binaries (art and audio) once real assets arrive at M4.
- Work on feature branches and merge through reviewed pull requests.

**Review checklist** (every change):
1. Every node, sprite, shape, marker, timer and UI element is in a `.tscn` file.
2. No script constructs nodes or shapes (`tools/check_scene_first.sh` passes).
3. No hard-coded layout positions, sizes, collision layers/masks or groups in scripts.
4. Tuning values are `@export`s with `##` doc comments, `@export_range` where useful.
5. Same-scene signals are connected in the editor. Code connects only to `EventBus` and to runtime copies.
6. Every scene loads and its connections are valid (`tools/check_scenes.gd` passes).

## 15. Testing
- **Scene-first check:** run `tools/check_scene_first.sh` from the repo root.
- **Scene check:** run `godot --headless --path . --script res://tools/check_scenes.gd`. It instantiates every scene under `src/`
  and validates each editor connection.
- **Unit tests** for the pure logic: the gesture classifier, level-generator constraints and determinism, economy math, and
  save migrations. Pick GUT or gdUnit4 at M1.
- **Playtest builds** include the debug overlay. Optional local telemetry (deaths per room, gesture misclassifications)
  only runs with the tester's consent.
- Every milestone ends with a playtest on real devices ([roadmap.md](roadmap.md)).
