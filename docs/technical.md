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
  *Create New Node* dialog. They live in `src/components/`. Built in M1–M2: `Health`, `StateMachine` (with `State`
  children), `TargetSelector`, `BulletEmitter`, `BulletPool`, `Drops`, `SpawnPoint`, `ContactHitbox`. Planned: `BossPhase`.
- **Hurtboxes** are plain `Area2D` nodes; their `area_entered` signal is connected in the editor to the scene's root script.
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

**Player** (`src/player/player.tscn`, built in M1)
```
Player (CharacterBody2D)              player.gd — exports: move_speed, roll_*, cover slide, reload multipliers, EMP,
│                                     haptics, implant_catalog, auto_respawn, weapon_catalog (group: player · floating)
├─ %BodyShape (CollisionShape2D)      CircleShape2D r = 6 px — body vs. walls, cover and enemies
├─ Visual (hero_visual.tscn instance) the paper doll: Body plus one overlay node per implant slot and tier
├─ %GunPivot (Node2D)                 rotated toward the current target
│  └─ %WeaponSlot (Node2D)            the equipped weapon's scene: ServicePistol (instance)
├─ %Reticle (Sprite2D, top_level)     drawn on the current target
├─ Hurtbox (Area2D)                   child Shape: RectangleShape2D 6×6 (mask: enemy_bullets); crouch scales it to 6×4
├─ %CoverSensor (Area2D)              child Shape: CircleShape2D r = 32 px — the 2-tile cover radius (mask: cover)
├─ %EmpRange (Area2D)                 child Shape: CircleShape2D r = 64 px — the EMP stun radius (mask: enemies)
├─ LineOfSight (RayCast2D)            mask: world, cover
├─ %StateMachine (StateMachine)       children: Run · Roll · SlideToCover · InCover · Stand · Dead
├─ %Health (Health)                   max_hp = 6 (half-hearts), max_armor = 4 — uses InvulnTimer
├─ %TargetSelector (TargetSelector)   uses LineOfSight; re-evaluated by RetargetTimer
├─ RetargetTimer (Timer)              0.1 s
├─ InvulnTimer (Timer)                1.0 s
├─ %PartialReloadTimer (Timer)        0.3 s
├─ %RespawnTimer (Timer)              1.5 s (test levels only; real levels show the Retrieved panel)
├─ EmpWave (Sprite2D, hidden)         the EMP ring
├─ %BodyAnimation (AnimationPlayer)   roll, crouch, uncrouch
├─ %FlashAnimation (AnimationPlayer)  hurt_blink, exposed, dead
├─ %EmpAnimation (AnimationPlayer)    emp
├─ %RollShockwave (Area2D)            CircleShape2D r = 24 px (mask: enemies) — the Hydraulic Legs Mk III shockwave
├─ ShockwaveRing (Sprite2D, hidden) · %ShockwaveAnimation (AnimationPlayer)
└─ %HurtSound · %RollSound · %EmpSound · %CoverSound · %PickupSound · %DeathSound (AudioStreamPlayer, bus SFX)
```

**Weapon** (`src/weapons/service_pistol/service_pistol.tscn`, built in M1)
```
ServicePistol (Node2D)                weapon.gd — exports: bullet_scene, damage, fire_rate, magazine_size, reload_time,
│                                     ammo_pool, spread_deg, pellets
├─ Sprite (Sprite2D)
├─ %Muzzle (Marker2D)                 bullets start here
│  └─ MuzzleFlash (Sprite2D, hidden)
├─ %Range (Area2D)                    child Shape: CircleShape2D r = 144 px (9 tiles) — the auto-aim range (mask: enemies)
└─ %MuzzleAnimation (AnimationPlayer) flash
```
Fire rate and reload time are weapon stats, so the weapon needs no Timer nodes. Sounds arrive with the audio pass.

**Bullet** (`src/weapons/bullets/enemy_bullet_small.tscn`, built in M1)
```
EnemyBulletSmall (Area2D)             bullet.gd — exports: speed, damage, cover_damage, lifetime, explosive, aerial
│                                     (layer: enemy_bullets · mask: world, cover)
├─ Shape (CollisionShape2D)           CircleShape2D r = 3 px
├─ Sprite (Sprite2D)
└─ ScreenNotifier (VisibleOnScreenNotifier2D)   returns the bullet to its pool when it leaves the screen
```

**Enemy** (`src/enemies/grunt/grunt.tscn`, built in M2)
```
Grunt (CharacterBody2D)               enemy.gd — exports: move_speed, spawn_kind, stun_state, death_fx_scene, attack_animation
│                                     (group: enemies · layer: enemies · mask: world, cover, enemies)
├─ BodyShape (CollisionShape2D)
├─ %Sprite (Sprite2D)
├─ TelegraphGlow (Sprite2D, hidden)   shown by the "telegraph" animation
├─ Hurtbox (Area2D)                   child Shape (mask: player_bullets)
├─ %LineOfSight (RayCast2D)           mask: world, cover
├─ %Health (Health)                   max_hp = 20
├─ %Drops (Drops)                     ram_mb = 3, ram_scene, extras: 3% ammo
├─ Emitter (BulletEmitter)            count 1, burst 3, aimed — rotate the node to aim patterns that aren't aimed
├─ %StateMachine (StateMachine)       SpawnIn → Approach → Telegraph → Attack → Approach … (+ Stunned)
├─ %FlashAnimation (AnimationPlayer)  RESET, hurt, spawn_in (shared: src/enemies/enemy_animations.tres)
└─ AttackAnimation (AnimationPlayer)  RESET, telegraph
```
The states are reusable nodes in `src/enemies/states/`, each tuned in the Inspector:
- `SpawnIn`: plays `spawn_in`; the enemy is harmless and untargetable until it ends.
- `Approach`: keeps a `min_range`–`max_range` band from the hero while strafing, then attacks after a random delay
  (needs line of sight). With an empty `attack_state` it just closes in (swarmers).
- `Wait`: stands still for a random time (turrets).
- `Telegraph`: plays a tell animation; `lock_aim` remembers the direction to the hero (chargers point `aim_node` along it).
- `FireEmitter`: fires its `emitter`, waits for the burst plus `recover_time`.
- `Charge`: dashes along the locked direction, smashes cover, and is stunned after hitting a wall or cover.
- `Stunned`: used by the EMP and by charges.

The four M2 enemies combine these:
- **Turret:** `Wait → Telegraph → Attack`, with a rotating 8-way emitter.
- **Charger:** `Approach → Telegraph (lock_aim) → Charge`, plus a `ContactHitbox`.
- **Swarmer:** an `Approach` that only closes in, plus a `ContactHitbox`.
The Sniper adds a `LaserSight (Line2D)`. The EMP-bot carries an `EmpField (Area2D)` child with its 3-tile circle.
The M1 greybox uses simpler test dummies (`src/enemies/dummy/`): a target dummy, plus aimed and spread shooters
built from the same parts (Hurtbox, Health, HpBar, BulletEmitter, AttackTimer, a telegraph animation that calls
`fire_emitter()` at its end).

**Cover** (`src/cover/crate_light.tscn`, built in M1)
```
CrateLight (StaticBody2D)             cover.gd — exports: max_hp = 40, cover_material, cracked_below, regenerates
│                                     (layer: cover · group: cover)
├─ %Shape (CollisionShape2D)          RectangleShape2D 32×16
├─ %Sprite (Sprite2D, 3 frames)       intact · cracked · broken
├─ %Animation (AnimationPlayer)       hit, break (shared library: src/cover/cover_animations.tres)
└─ %RegenTimer (Timer)                test rooms only: rebuilds broken cover
```
`barrier_medium.tscn` (48×16, 120 HP) and `block_heavy.tscn` (32×32, 300 HP) follow the same tree. Break
particles and sounds arrive with the art and audio passes.

**Room template** (`src/levels/rooms/rustline/combat_03.tscn`, built in M3)
```
RustlineScrapyard (Node2D)            room.gd — exports: room_type, waves (0 = the level's 1–2)
├─ Floor (TileMapLayer)               floor tiles, the door gaps included
├─ Walls (TileMapLayer, group nav_source)  collision from the tileset; a 2-tile gap in the middle of each wall
├─ %NavRegion (NavigationRegion2D)    local-to-scene NavigationPolygon over the floor, baked when the room loads around
│                                     the nav_source groups (walls and cover) and re-baked after cover breaks
├─ %Doors (Node2D)                    North · East · South · West — door.tscn instances, rotated to their wall
├─ Cover (Node2D, group nav_source)   hand-placed cover instances: Block1 · Barrel1 · Crate1 · …
├─ %Chest / %Station / %Terminal / %Shrine / %Console / %Elevator   the room's feature (special rooms only)
├─ %SpawnPoints (Node2D)              Spawn1 … Spawn11 — exports: kinds (ground / flyer / stationary), waves (1–3)
├─ %DropLayer (Node2D, group drop_layer)  the room's pickups, dropped guns and effects; they stay with the room
├─ %Enemies (Node2D)                  the WaveSpawner adds enemy copies here
├─ %RewardSpot · %PlayerStart (Marker2D)  room-clear reward and level start; the boss room adds %BossSpot
├─ %CameraBounds (ReferenceRect)      the camera's limits in this room
└─ %RebakeTimer (Timer, 0.3 s)        re-bakes the navigation after cover breaks or regrows (timeout connected in the scene)
```

**Door** (`src/levels/rooms/door.tscn`, built in M3)
```
Door (Node2D)                         door.gd — exports: direction (N/E/S/W); status OPEN / LOCKED / SEALED at runtime
├─ %Sprite (Sprite2D, 3 frames)       open · locked bars · sealed (looks like wall)
├─ Blocker (StaticBody2D, world)      %BlockerShape 32×16 fills the gap unless OPEN, and stops bullets
├─ Backstop (StaticBody2D, world)     behind the gap, so nothing leaves the room
├─ Exit (Area2D, mask: player)        walking in while OPEN emits EventBus.door_entered (connected in the scene)
└─ %Entry (Marker2D)                  inside the room: where the hero arrives through this door
```

**Level** (`src/levels/level.tscn`, built in M3; the main scene. The M1 and M2 test levels stay in `src/levels/test/`.)
```
Level (Node2D)
├─ RoomHolder (Node2D)                the current room's copy goes here
├─ Player (player.tscn instance)      touch → TouchController; the director points respawn_point at the entry door
├─ BulletPools (Node2D)               placed far outside the playfield (-4096, -4096): idle bullets wait there
│                                     PlayerBullets · PlayerPellets · PlayerRivets · EnemyBulletsSmall (BulletPool)
├─ Camera (CameraFollow: Camera2D)    follows the Player inside the current room's CameraBounds
├─ TouchController (TouchController)  exports: tuning (controls_tuning.tres), hud — its signals are connected to Player
├─ HUD (hud.tscn instance)
├─ WaveSpawner (WaveSpawner)          room mode: waves at the room's SpawnPoints, then room_cleared → LevelDirector
│  └─ NextWaveTimer (Timer, 1.2 s)    the pause between a room's waves
├─ RoomRewardDrops (Drops)            combat-room clear: 3–6 Crypto, ½ heart 10%, ammo 25%, armor 5%
├─ ArenaRewardDrops (Drops)           challenge arena: 30 Crypto and 48 MB (plus a Rare-or-better chest copy)
├─ LevelDirector (LevelDirector)      exports: config (data/levels/level_1.tres), fixed_seed, chest_scene and the nodes above
└─ Transition (CanvasLayer, layer 10) Fade (ColorRect) · TransitionAnimation — the last key of fade_out calls
                                      LevelDirector._on_fade_out_finished, the last key of fade_in _on_fade_in_finished
```
The M1/M2 test levels (`controls_test.tscn`, `combat_test.tscn`) keep `DropLayer` and `Enemies` at the level root.

**HUD** (`src/ui/hud.tscn`, built in M1)
```
HUD (CanvasLayer)                     hud.gd — exports: tuning
└─ Root (Control, full screen, ignores touches; theme sets the 11 px HUD font)
   ├─ %JoystickZone (Control)         anchored to the lower 60% with 16 px side and bottom margins — the zone IS this node
   │  └─ %ZoneHint (ColorRect)        shown while the debug panel is open
   ├─ %Joystick (Control)             Ring · %Knob (TextureRect), moved to the touch point
   ├─ %TouchPath (Line2D)             the finger's path, shown while the debug panel is open
   ├─ %EdgeArrows (Control)           Arrow1 … Arrow8 (pre-placed, hidden) — point at off-screen enemies
   ├─ TopBand (PanelContainer)        Row1: %Hearts (Heart1–6) · %Armor (Pip1–4) · %EmpLabel · DebugButton
   │                                  Row2: Crypto icon + %CryptoLabel · RAM icon + %RamLabel · %WeaponCard (tap = swap)
   ├─ %WaveLabel (Label)              "WAVE n" banner, faded by WaveAnimation
   ├─ %PromptBubble (Button, hidden)  "Take Scattergun", "Repair station", "Take the elevator" — tap to use
   ├─ %BossBar (ProgressBar, hidden)  the boss's health (EventBus.boss_health_changed)
   ├─ MinimapButton (Button)          Minimap (map_view.tscn instance) — tap for the full map
   ├─ %ToastLabel (Label)             short messages ("Bought for 15 Crypto"), faded by ToastAnimation
   ├─ %FullMap (PanelContainer)       a big MapView (cell_step 28×24, cell_scale 2) and Close
   ├─ %ShopPanel (PanelContainer)     %ShopInfo · %BuyHeart · %BuyArmor · %BuyEmp · %BuyAmmo · Leave
   ├─ %MemoryPanel (PanelContainer)   %MemoryTitle · %MemoryBody · Close
   ├─ %PausePanel (PanelContainer)    %MusicSlider · %SfxSlider · %HapticsCheck · Resume · Save and quit (TopBand's "II" opens it)
   ├─ %SummaryPanel (PanelContainer)  %SummaryTitle "RETRIEVED" · %SummaryStats · Back to the lab
   └─ %DebugPanel (DebugPanel)        gesture readout, A/B switches, TuningSlider instances, 300-bullet storm
```
The HUD runs while the game is paused (`process_mode` Always); the three panels pause the game while they're open.
The map cell is `map_cell.tscn` (Background, Icon and four link stubs); `MapView` copies one for each known room.
`show_minimap` hides the minimap in the lab and the tutorial.

**Hero paper doll** (`src/player/hero_visual.tscn`, built in M4 with placeholder art)
```
HeroVisual (Node2D)                   hero_visual.gd — exports: follow_game_state (off for the surgery preview)
├─ Body (Sprite2D)                    becomes an AnimatedSprite2D with the final art
└─ %Implants (Node2D)                 HeartMk1 · HeartMk2 · HeartMk3 · LegsMk1 · LegsMk2 · LegsMk3 (Sprite2D, hidden);
                                      the other slots' nodes arrive with their implants in M5
```
Only the overlay named `<Slot>Mk<tier>` that matches the installed tier is shown. The final version adds `Outfit`
and an `AnimationPlayer` that drives every layer with the same animation (§9).

**Lab hub** (`src/hub/lab.tscn`, built in M4)
```
Lab (Node2D)
├─ Floor · Walls (TileMapLayer)       one screen (22×40 tiles)
├─ Signs (Labels) · Props             Vorn, Patch and the cot (sprites)
├─ Stations (Node2D)                  SurgeryChair · Armory · LabElevator — station.tscn-style Interactables
│                                     (exports: prompt, action); their prompt sends EventBus.station_used
├─ DropLayer · PlayerStart · Player · CameraBounds · Camera · TouchController
├─ HUD (hud.tscn instance)            show_minimap = false
├─ LabUI (CanvasLayer, LabUI)         exports: implant_catalog, weapon_catalog, armory_row_scene, patch_lines,
│  │                                  implant_comics (slot → comic scene); runs while paused
│  ├─ QuickStart (Button)
│  ├─ %SurgeryPanel                   Preview/%Doll (HeroVisual) · %SlotRows (6 SurgeryRow buttons, one per body slot) ·
│  │                                  %ImplantName · %ImplantInfo · %InstallButton (HoldButton) · Close
│  ├─ %ArmoryPanel                    %ArmoryInfo · Scroll/%ArmoryList (armory_row.tscn copies, one per catalog gun) · Close
│  ├─ %Dialogue (dialogue_box.tscn)   tap to advance
│  ├─ %ComicLayer (Control)           first-implant comics are copied in here
│  └─ %PurchaseSound (AudioStreamPlayer)
├─ MusicCue (MusicCue)                the lab theme
└─ LabDirector (LabDirector)          exports: intro_talk, first_clear_talk, retrieval_lines (data/dialogue/)
```
`src/hub/tutorial.tscn` (the rehab room) is built the same way, with a `Steps` node of `TutorialStep` children
(each holding its own dummies) run by a `TutorialDirector`. Comics (`src/ui/comic/`) are a `ComicPlayer` Control whose
`%Panels` children are the panels, each with its `Art`, `Caption` and `Bubble` nodes.

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

### 1.0 Godot 4.7 gotchas (found while building M1)
- **An `Area2D` with `monitorable = false` doesn't detect static bodies,** even with `monitoring` on. Keep
  `monitorable` on for every sensor; give sensors `collision_layer = 0` so nothing else detects them.
- **Don't toggle `monitoring` or `monitorable` on pooled areas.** Detection can silently stop after a pooled
  bullet is recycled. Inactive bullets are hidden and parked at their pool node's position instead (§6.2).
- **Controls placed in the world swallow touches** (a `ReferenceRect` or a dummy's `ProgressBar`, for example). Set
  `mouse_filter = Ignore` on every Control that isn't a button.
- **Command-line tools see autoloads only from `_initialize()`.** A `--script` tool that uses project classes
  (which use `EventBus`) loads them in `_initialize()`, not `_init()`; see `tools/smoke_test_controls.gd`.
- **(M3) A room added to the tree can catch the hero where it stood a moment ago.** Every room shares the same origin,
  so a door `Exit` in the new room may overlap the hero's old spot for one physics step. The `LevelDirector` ignores
  door signals from the fade-out until the fade-in ends.
- **(M3) Don't name an inner enum after a global class.** `enum State` inside `door.gd` clashed with the `State` node
  class; the door's enum is `Status`.
- **(M3) A Control's `resized` signal fires before `_ready`.** Handlers that use `@onready` nodes check `is_node_ready()`.
- **(M4) Nodes kept outside the tree are not freed with their old parent.** The LevelDirector frees its stored rooms
  in `NOTIFICATION_PREDELETE`; anything else that parks nodes outside the tree must do the same.
- **(M4) Headless runs report one leaked `AudioStreamPlayback` at exit** when a sound played (the dummy audio driver
  never finishes playbacks). It's harmless; the tests still exit cleanly.
- **(M4) A signal with arguments can't drive `AudioStreamPlayer.play` directly:** the first argument becomes
  `from_position`. Connect only argument-less signals (like `Weapon.shot_fired`) to `play`, or call it from a script.

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
| 8 | interactables | Chests, stations, NPCs, doors, weapon pickups (detected by the hero's InteractSensor) |
| 9 | enemy_contact | `ContactHitbox` areas of enemies that hurt by touch (detected by the hero's Hurtbox) |
| 10 | sight_blockers | Holo-signs (M5): only line-of-sight rays (hero and enemy `LineOfSight`, mask 515) hit them; bullets and bodies pass |

---

## 2. Folder structure
```
res://
├─ assets/              raw art, audio and fonts (placeholders until the art direction is chosen)
│  ├─ art/
│  ├─ audio/            sfx/ and music/ (generated placeholder WAVs; music loops via a WAV loop chunk)
│  └─ fonts/
├─ data/                non-world data as .tres resources, edited in the Inspector (§0.4)
│  ├─ controls/         controls_tuning.tres
│  ├─ implants/         one ImplantData per slot and tier, and implant_catalog.tres
│  ├─ levels/           one LevelConfig per level (level_1.tres) and its WaveSettings
│  ├─ memories/         one MemoryData per memory room
│  ├─ dialogue/         Conversations and LineSets (lab talks, retrieval lines, Patch)
│  └─ weapons/          weapon_catalog.tres (combat stats live on the weapon scenes)
├─ localization/        CSV translation tables
├─ src/                 scenes (.tscn) and their scripts (.gd), grouped by feature
│  ├─ autoload/         EventBus, GameState, RunState, SaveManager, Monetization; audio_manager.tscn, scene_router.tscn
│  ├─ components/       reusable component nodes: Health, Hurtbox, BulletEmitter, SpawnPoint, Drops, StateMachine, …
│  ├─ input/            TouchController
│  ├─ player/           player.tscn, hero_visual.tscn, state scripts
│  ├─ enemies/          one folder per enemy (scene, script, art)
│  ├─ bosses/           one folder per boss (scrapjaw/)
│  ├─ weapons/          one folder per weapon; bullets/ for bullet scenes
│  ├─ cover/            cover scenes by material
│  ├─ levels/           level.tscn (the main scene), CameraFollow
│  │  ├─ generation/    LevelConfig, LevelGenerator, LevelLayout, LevelDirector (pure data and logic + the director)
│  │  ├─ rooms/         room.gd, door.tscn, and room template scenes, one folder per district (rustline/)
│  │  ├─ features/      chest, repair station, hacked terminal, memory shrine, challenge console, elevator
│  │  ├─ waves/         WaveSpawner, WaveSettings
│  │  └─ test/          the M1 controls and M2 combat test levels
│  ├─ hub/              the lab, its stations and panels, and the rehab tutorial
│  └─ ui/               HUD, map/, title/ (title and slot cards), comic/ (comic player and comics), dialogue/
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
| `EventBus` | Script | Global signals: `enemy_killed`, `door_entered`, `room_entered`, `room_cleared`, `currency_changed`, `implants_changed`, `station_used`, `player_died`, `run_summary_requested`, … |
| `RunState` | Script | The current run: level and seed, room states, hearts, armor, the found gun and its ammo, EMP charges, the run summary (`revive_used` in M6) |
| `GameState` | Script | The loaded save slot: implants, unlocks, Crypto, RAM, memories, endings, stats, story flags. Derives `filled_slots` and `humanity_band` |
| `SaveManager` | Script | Slot and run files, atomic writes, versioning, `settings.cfg` (§8) |
| `AudioManager` | **Scene** | The Music player with its crossfade `AnimationPlayer` and the UI tick, in `audio_manager.tscn`. Buses are in `default_bus_layout.tres` (Master, Music, SFX). Adaptive layers by band arrive with the real music |
| `SceneRouter` | **Scene** | Fades between the title, prologue, tutorial, lab and level. Its `Fade` ColorRect and `FadeAnimation` are nodes in `scene_router.tscn`; the scene paths are exports |
| `Monetization` | Script | Rewarded ads and IAP behind one interface, with a stub on desktop (§12; M6) |

Autoload order matters: EventBus, RunState, GameState, SaveManager, AudioManager, SceneRouter.

Keep autoloads thin, holding data and signals; gameplay logic lives in scenes.

### 3.2 Non-world data (`.tres` resources)
Things that exist in the world keep their numbers on their own scenes (§0.4). Only data that isn't an object in the world
uses custom `Resource` classes. The classes (with `class_name`) live next to the code that uses them, and their `.tres`
files live in `data/`.

| Resource | File(s) | Key fields |
|---|---|---|
| `ImplantData` | `data/implants/heart_mk1.tres` … `legs_mk3.tres` | slot, tier, display name, description, cost_mb, modifiers (`Array[StatModifier]`), Vorn's line. Its overlay is the HeroVisual node named `<Slot>Mk<tier>` |
| `StatModifier` | Inside `ImplantData` | stat (max HP, start armor, move speed, roll distance, heal every N rooms, roll shockwave), value; tiers add up |
| `ImplantCatalog` | `data/implants/implant_catalog.tres` | every installable tier (Heart, Legs, Eyes and Brain so far, Mk I–III) |
| `Campaign` | `data/levels/campaign.tres` | the run's LevelConfigs in order; the level scene plays `config_for(RunState.level_number)` |
| `Conversation` / `DialogueLine` | `data/dialogue/lab_intro.tres`, `l1_first_clear.tres` | lines (speaker, text) for the DialogueBox |
| `LineSet` | `data/dialogue/retrieval_lines.tres`, `patch_lines.tres` | alternative lines for one moment, cycled |
| `LevelConfig` | `data/levels/level_1.tres`, `level_2.tres` … | level number, district, music and boss music, room-count ranges, extra-special weights, room pool (`RoomEntry`: scene, type, weight), boss scene, wave settings, waves per room, room / arena / ambush threat, elite chance, chest odds |
| `MemoryData` | `data/memories/l1_the_wedding.tres` … | title, text, half-hearts healed (band variants in M5) |
| `WeaponCatalog` | `data/weapons/weapon_catalog.tres` | entries (`WeaponCatalogEntry`): id, scene, rarity, unlock cost (icon later). 9 guns in M4 |
| `ControlsTuning` | `data/controls/controls_tuning.tres` | every threshold from GDD §3.4, plus the M1 A/B switches (cover mode, hero anchor, joystick zone top, show stick) |
| `SwipePreset` | `data/controls/swipe_low/normal/high.tres` | swipe max time, min distance, min speed |
| `WaveSettings` | `data/levels/level_1_waves.tres`, `m2_arena_waves.tres` | enemy pool (`EnemySpawnEntry`: scene, threat cost, kind, group size, first wave, weight), threat per wave, cap, endless, min spawn distance. A level's is set on its `LevelConfig` |
| `DropChance` | inside `Drops` nodes | pickup scene, chance, amount |

Designers balance the game in the Inspector, with no code changes.

### 3.3 Stats
`PlayerStats` combines the base values exported on `player.tscn` with modifiers from installed implants and temporary
buffs. It's recomputed when an implant changes and at the start of each level, and all gameplay reads from it rather than
hard-coded values.

---

## 4. Input: TouchController
This is the highest-risk system, so it gets built first (M1), with a live debug overlay. The `TouchController` node lives
in the level scene next to the HUD (§0.8): its `hud` export points at the HUD, and its signals are connected to the
Player in the editor. Code: `src/input/touch_controller.gd`.

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

### 4.3 Debug panel (M1)
- The **DBG** button in the HUD's top band opens `%DebugPanel` in `hud.tscn`.
- **Readout:** FPS, enemy bullets in flight, the hero's state, and the last gesture with its duration, travel and speed.
- **A/B switches** (OptionButtons whose item ids carry the values):
  - cover spot: nearest point / smart side;
  - stick zone top: 35 / 40 / 50%;
  - swipe sensitivity: Low / Normal / High (`SwipePreset` resources);
  - hero screen height: 40 / 45 / 55%;
  - show stick.
- **Sliders** (`TuningSlider` instances): swipe max time, min distance, min speed, double-tap window, stick radius,
  full speed at.
- While the panel is open, the joystick zone is tinted and the finger's path is drawn by the `%TouchPath` Line2D
  node, so no `_draw()` is needed.
- Changes apply live to the shared `controls_tuning.tres` resource in memory. They aren't saved, so note the winning values from a playtest in the `.tres`.

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
- **The hurtbox and the cover radius are visible in the editor.** They're the `Hurtbox` rectangle (6×6 px, 6×4 when
  crouched via the `crouch` animation) and the `%CoverSensor` circle (32 px).
- **Reload lives in the weapon scene,** because each gun keeps its own magazine. The player's current state passes
  its speed multiplier to the equipped weapon: running 0.5, standing 1.0, cover 1.4, all exported on `player.tscn`.
- **Auto-fire:** while `touching` is true and `TargetSelector` has a target, the player tells the weapon in
  `%WeaponSlot` to fire.
- **Implants (M4):** `apply_implants()` recomputes move speed, roll distance, max hearts, starting armor, the
  room-clear heal and the roll shockwave from the Inspector's base values plus `implant_catalog.total()` for
  `GameState.implants`. It runs when the hero loads and on `EventBus.implants_changed` (surgery). `begin_level()` refills
  EMP charges and adds the starting armor; the Roll state calls `roll_finished()` for the shockwave.
- **Runs (M4):** `capture_run_state()` and `restore_run_state()` move hearts, armor, EMP charges and the found gun
  (by catalog id) to and from `RunState`. `auto_respawn` is on in the test levels; real levels turn it off and the
  LevelDirector shows the Retrieved summary instead.

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
- **Bullets are authored scenes** (§0.8) in `src/weapons/bullets/`. Their exports cover every gun's trait: `pierce`,
  `bounces` (with a `WallProbe` RayCast2D node that finds the wall's normal), `homing` and `homing_range`, `stun_time`,
  and `blast_scene` (a copy placed where the bullet hits, the Firecracker's `mini_blast.tscn`).
- **Pooling:** each `BulletPool` node in `level.tscn` pre-copies its `bullet_scene` `size` times when the level loads,
  then hands bullets out and takes them back. Nothing is instanced in the middle of a fight.
- **Who detects what:** hurtboxes monitor the bullet layers; bullets only watch for walls and cover (`body_entered`).
- **Idle bullets are parked, not switched off.** A despawned bullet is hidden, stops processing, and moves back to its
  pool node's position, which the level places far outside the playfield. Physics flags are never toggled (§1.0).
- **Node-friendly performance:**
  - circle shapes only;
  - movement is a few lines in `_physics_process`;
  - bullets are recycled through their `VisibleOnScreenNotifier2D` or their lifetime;
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
- **Movement:** walking robots (Grunt, Charger, Swarmer, the stand-in boss) have a `NavAgent` (`NavigationAgent2D`)
  node. Moving in, they follow its path around walls and cover (`Enemy.direction_toward()`). Every level room and the
  M2 arena room bake a map; without one, robots steer straight with `move_and_slide` and flip their strafe when they
  bump into something.
- **Bodies:** enemies collide with walls, cover and each other, but not with the hero. They pass through the hero,
  and touch damage comes from `ContactHitbox` areas, which the hero checks every physics frame.
- **Spawning** (`src/levels/waves/wave_spawner.gd`):
  - The `WaveSpawner` reads the enemy pool from its `WaveSettings` (the level's, from `LevelConfig`).
  - **Room mode (M3):** the `LevelDirector` calls `start_room()` with the room's SpawnPoints, wave count and budget, or
    `spawn_boss()`. After the last wave, `room_cleared` fires (connected in `level.tscn`). Endless mode stays for the
    M2 arena.
  - It copies enemy scenes to the room's **hand-placed `SpawnPoint`s**. Each SpawnPoint's `kinds` and `waves` exports limit which enemies can appear there, and in which wave.
  - Spawn points within 3 tiles of the hero are skipped.
  - To make an elite, the spawner turns on the copy's `EliteFX` node and applies the modifier.
- **Deaths:** copies report through `EventBus.enemy_killed`, so no per-copy wiring is needed.
- **Level 2 robots (M5):**
  - **Shotgunner:** a closing approach and a 5-bullet pump spread.
  - **Drone** (`circle.gd`): spawn kind Flyer, with no collision mask, so it flies over walls and cover. It circles
    the hero inside the room's `CameraBounds`. Its shots (`enemy_bullet_aerial.tscn`, `aerial`, mask: world) pass
    over cover and ignore cover protection.
  - **Hacker** (`hack.gd`): copies `rig_charge.tscn` onto the intact cover nearest the hero. The charge blinks for
    1.5 s, then an explosion breaks the cover. The Hacker also shields the nearest ally for 3 hits.
- **Elites (M5):** single enemies roll the level's `elite_chance`. `Enemy.make_elite()` applies the modifier:
  - Overclocked: ×1.5 speed, faster attacks via `attack_rate` and the emitter interval;
  - Armored: ×2 HP, ×0.8 speed;
  - Splitter: the WaveSpawner copies 2 `splitter_scene` Swarmers where it died;
  - Shielded: absorbs 3 hits (`ShieldBubble`).

  An elite costs 2× threat, drops 3× RAM and shows its `EliteFX` ring in the modifier's color. With elites, a hacked
  terminal's ambush is one elite (`spawn_elite_ambush`).

### 6.4.1 Weapons, pickups and drops (M2)
- **Two slots:**
  - the starter pistol is pre-placed in the Player's `WeaponSlot`;
  - a found gun is taken from a `WeaponPickup` (the gun node itself moves into `WeaponSlot`, keeping its ammo);
  - the replaced gun moves into a new `WeaponPickup` copy on the floor;
  - a holstered gun is hidden and paused (`Weapon.set_active`);
  - an empty found gun switches back to the pistol.
- **HUD requests:** the weapon card and the pickup prompt send `EventBus.weapon_swap_requested` and
  `EventBus.interact_requested`. The hero's `InteractSensor` decides what the prompt says.
- **Piercing:** `Bullet.pierce` lets a bullet (the Rivet Driver's) hit more enemies; `try_hit()` never hits the same target twice.
- **Pickups:** `Pickup` scenes (RAM, Crypto, half heart, armor, ammo).
  - The hero's `PickupMagnet` (40 px) pulls in only what the hero can use; a full hero leaves hearts on the floor.
  - Currencies go to `GameState` (the save slot), so they survive death; `RunState` counts what this run earned.
- **Drops:** each enemy's `Drops` node drops its RAM (plus a 3% ammo chance) into the level's `drop_layer` node (a
  Node2D at the origin). The spawner's `RewardDrops` drops the wave-clear reward: 3–6 Crypto, 10% ½ heart, 25% ammo, 5% armor.
- **Armory guns (M4):** Bolt Revolver, Ricochet Carbine, Magnet Coil, Volt Shotgun, Longshot and Firecracker, each a
  weapon scene in its own folder. `Weapon.burst` and `burst_interval` give the Firecracker 3-round bursts. Chests only
  pick guns that `GameState.unlocked_weapons` lists (`WeaponCatalog.pick`).
- **Sounds:** every weapon scene has a `ShotSound` (AudioStreamPlayer2D), connected to the weapon's `shot_fired` signal.
- **Barrels:** a cover scene with `provides_cover = false` and `break_scene = explosion.tscn`. The `Explosion` damages
  the hero (ignoring cover), enemies and cover in 32 px, so barrels chain.

### 6.5 Bosses
**SCRAPJAW** (`src/bosses/scrapjaw/scrapjaw.tscn`, built in M4) is an enemy scene with a phase component:
```
Scrapjaw (CharacterBody2D, Enemy)     exports: move_speed, is_boss … (HP 600 on %Health)
├─ BodyShape · %Sprite · TelegraphGlow · AimPivot/AimLine · Hurtbox · ContactHitbox · NavAgent · LineOfSight
├─ %Health · %Drops                   64 MB RAM, 50 Crypto and an ammo pickup
├─ SprayEmitter · SpiralEmitter       BulletEmitter nodes: 8-way rotating bolts; the Grind spiral
├─ HitSound · RoarSound               AudioStreamPlayer2D
├─ Phases (BossPhases)                exports: thresholds [0.6, 0.25], phase_states, phase_names, roar
├─ %StateMachine                      SpawnIn · Resume · Stunned ·
│                                     WreckApproach → WreckChargeTell → WreckCharge → WreckSprayTell → WreckSpray ·
│                                     MagnetTell → MagnetPull → MagnetSpray → MagnetApproach → MagnetChargeTell → MagnetCharge ·
│                                     GrindSpin → GrindChargeTell → GrindCharge → GrindChargeTell2 → GrindCharge2
├─ %FlashAnimation                    the shared enemy animations
└─ AttackAnimation                    charge_tell, spray_tell, magnet_tell, grind_tell, grind_tell_fast
```
- **Phases:** `Health.changed` is connected to `Phases` in the scene. When HP falls below the next threshold, the boss
  jumps to that phase's first state, the HUD shows the phase banner, and `RoarSound` plays. Each phase's states form
  a loop; `Stunned` and `SpawnIn` go to `Resume` (`phase_resume.gd`), which returns to the current phase's loop.
- **Wreck:** `Charge` with `plow_through_cover` smashes cover in its path; any static body (walls, a locked door)
  stuns it for 1 s.
- **Magnet** (`magnet_pull.gd`): scrap streams fly from a few of the arena's hand-placed `ScrapSpots` markers toward
  the boss, the hero is pulled in lightly (walls and cover stop the pull), and scrap piles (`scrap_pile.tscn`, light cover)
  are copied onto free spots. They're added under the room's `Cover` node, so the navigation re-bakes around them.
- **Grind** (`spin_chase.gd`): spins the sprite and walks at the hero while `SpiralEmitter` fires; then double charges.
- **Arena:** `rooms/rustline/boss.tscn`, a scrapyard of light cover, with `%BossSpot` and `Cover/ScrapSpots` (group `scrap_spots`).
- The HUD boss bar listens to `EventBus.boss_health_changed`. The old stand-in (`src/enemies/boss_standin/`) stays
  as a placeholder for the L3–L5 bosses until they're built.

**GLITCH** (`src/bosses/glitch/glitch.tscn`, M5) uses the same pattern, with HP 700 and thresholds [0.65, 0.3]:
- **Decoys** (`summon_decoys.gd`): keeps 2 `glitch_decoy.tscn` copies on free `TeleportSpots`. Decoys are 1-HP
  enemies in the `glitch_decoys` group, with no shadow and a flicker. Their hollow bullets do no damage (the hero
  ignores zero-damage bullets).
- **Holo-walls:** `teleport.gd` blinks to a spot far from the hero; `cage.gd` copies `holo_cage.tscn` around the hero.
  Its four walls block movement and bullets, its corners are open, and its `LifeTimer` removes it after 3 s.
- **Static Storm:** 4 decoys, faster blinks, and `EventBus.screen_glitch_requested`. The HUD's `GlitchOverlay` plays
  `glitch`, or the gentle `glitch_soft` with the reduced-flashing setting.
- `clears_group_on_death` removes the decoys when GLITCH falls. The arena (`rooms/neon/boss.tscn`) holds
  `TeleportSpots` (group `teleport_spots`).

---

## 7. Level generation

### 7.1 Discrete rooms
Rooms are separate scenes joined by door transitions (Isaac-style), not one continuous stitched map (Gungeon-style). Reasons:
- Portrait rooms are one screen wide, so neighboring rooms would never be visible anyway.
- Only one room is in memory at a time, which keeps RAM use low on phones.
- Saving and resuming per room is simple, and generation is deterministic per seed.
- There's no corridor routing or overlap solving.

### 7.2 Algorithm
`LevelGenerator` (`src/levels/generation/level_generator.gd`) is pure logic with no nodes. It turns a `LevelConfig` and a
seed into a `LevelLayout`: a list of `RoomNode`s, each with a type, a grid cell, its doors and a room scene.
1. Seed the generator with `rng.seed = hash([level_seed, level_number, attempt])`; the same seed always gives the same
   level. `attempt` counts re-rolls.
2. Roll room counts from `LevelConfig` and clamp the total to that level's range ([content.md](content.md) §6).
3. Grow the graph on an abstract grid (one cell per room; neighbors share a door, N/E/S/W):
   - a main path of 2+ combat rooms runs from Start to Boss, each step to a random free neighboring cell;
   - extra combat rooms branch off Start or a combat room;
   - the leaves come last: the memory room (attached to a combat room, so never next to Start or Boss), the extra
     special room (weighted: repair, arena, terminal) and the chest rooms.
4. Pick a room scene for each node from the `LevelConfig` room pool, matching its type and weighted, avoiding repeats
   within a level when the pool allows. Every template has all four doors, so any room fits any position.
5. Validate (`LevelGenerator.validate()`): exactly one start, boss and memory room; counts within range; doors matched
   on both sides; every room reachable; the boss at least 3 doors from Start; boss, chest and special rooms are dead
   ends; the memory room doesn't touch Start or Boss. If it fails, re-roll (up to 200 attempts).

**Playing a level** (`LevelDirector`, `src/levels/generation/level_director.gd`):
- The first time the hero enters a room, the director adds a copy of its scene to `RoomHolder`. When the hero leaves, the
  copy is taken out of the tree but kept, so its pickups, broken cover and opened chest are still there on return.
  A chest's rarity is rolled from the config's odds when its room is first copied.
- On entering, it places the hero at the arrival door's `Entry`, points the camera at the room's `CameraBounds`, and
  sets each door: OPEN (or LOCKED in an uncleared fight) where the map has a neighbor, SEALED elsewhere.
- Combat and boss rooms fight at once. The arena waits for its console and the terminal can start an ambush. The doors
  stay locked until the `WaveSpawner` reports `room_cleared`. Then the director drops the reward: the room reward at
  `RewardSpot`, the arena's Rare-or-better chest and Crypto/RAM, or the boss room's elevator. A hacked terminal's chest
  prize comes through the director too (`EventBus.reward_chest_requested`), so both roll from the level's odds.
- A door's `Exit` emits `door_entered`. The director plays `fade_out`, swaps rooms at its last key, then plays
  `fade_in`; door signals are ignored until the fade-in ends (§1.0).
- **Runs (M4):** the level starts the run's level from `RunState` (or rebuilds a saved run, §8). Every room entry and
  clear saves the run. The boss room's elevator ends the run and returns to the lab (M4 loops back to Level 1; M5 will
  chain L1 → lab → L2). On death, the `DeathTimer` (1.2 s) shows the HUD's Retrieved summary, the run ends, and its
  button returns to the lab. Tests turn off `return_to_lab` to keep the M3 in-place level loop.
- When the level is freed, the director frees the visited rooms it kept outside the tree.
- **Campaign (M5):** the director's `campaign` picks the LevelConfig for `RunState.level_number`. The boss elevator
  calls `_finish_level()`: it saves the hero's state, then `RunState.advance_level()` sets `in_lab`, and the run file
  is kept. The lab's elevator (named after the next district) continues the run. After the last level, the run ends.
- `EventBus.level_generated`, `room_entered` and `room_cleared` drive the minimap (`MapView`), which shows rooms once the
  hero has been next to them.

**Tests:** `tools/test_level_generator.gd` validates 10,000 seeds (about 3 s), checks determinism and variety, and
checks that `validate()` catches broken layouts. `tools/smoke_test_level.gd` plays generated levels (§15).

### 7.3 Room template authoring
- **Structure:** each room is a scene built entirely in the editor (tree in §0.8). It has:
  - floor and wall tiles, with a 2-tile door gap in the middle of each wall;
  - four `door.tscn` instances, rotated to their wall;
  - hand-placed cover and `SpawnPoint`s;
  - a `NavRegion` whose outline covers the floor (local to scene, so copies don't share a baked mesh);
  - the room type's feature, if any (`%Chest`, `%Station`, `%Terminal`, `%Shrine`, `%Console`, `%Elevator` and
    `%BossSpot`);
  - `%DropLayer`, `%Enemies`, `%RewardSpot`, `%PlayerStart`, `%CameraBounds` and `%RebakeTimer`.
- **Size:** 22 tiles wide (walls included) and 28–72 tiles tall. Rooms shorter than the screen (40 tiles) are
  letterboxed.
- **Layout rules:**
  - Keep 44 px (almost 3 tiles) clear around every door's `Entry`. Leave at least 20 px between cover and walls and
    16 px between cover pieces, so robots can't get stuck.
  - Cover within about 6 tiles of every walkable spot, mixing light, medium and heavy.
  - Combat rooms have 10–14 SpawnPoints, at least 6 tiles from every door Entry. Some take stationary enemies
    (turrets) as well as ground ones.
  - `CameraBounds` covers the whole room.
- **M3 set (Rustline, `src/levels/rooms/rustline/`):** start, 8 combat rooms (Alley, Market, Scrapyard, Underpass,
  Checkpoint, Courtyard, Long Street (2 waves), Garage; 40–64 tiles tall), 2 chest rooms, and one each of memory,
  challenge arena, repair, terminal and boss. All are greybox.
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

**Built in M4:**
- `GameState` (autoload) holds the loaded slot: currencies, implants, unlocks, memories, endings, stats
  (`runs`, `deaths`, `best_level`, `boss_kills`, `rooms_cleared`) and story `flags` (`prologue_seen`, `tutorial_done`,
  `lab_intro_done`, `l1_cleared`, first-implant comics…). `slot` 0 means no slot (the test levels), and nothing is written.
- `RunState` (autoload) holds the run: level and seed, the room and the door the hero came through, known, visited and
  cleared rooms, opened chests, hearts, armor, EMP charges, the found gun (catalog id and ammo) and the run summary.
- `SaveManager` (autoload) writes both as JSON through a `.tmp` file. A corrupt file loads as a new story; unknown
  fields are ignored and values are clamped. Saves happen on room entry and clear, lab purchases, story beats, the
  pause menu's Save and quit, and `NOTIFICATION_APPLICATION_PAUSED` / `NOTIFICATION_WM_CLOSE_REQUEST`. The run file is
  deleted when a run ends (death or the boss elevator).
- `settings.cfg` keeps the Music and SFX volumes and vibration (pause menu); `SaveManager.apply_settings()` sets the bus volumes.
- An uncleared room restarts its fight on Continue; floor pickups in visited rooms aren't saved yet.

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
- `hero_visual.tscn` (tree in §0.8) holds the body and one overlay node per implant slot and tier. M4 has the six
  Heart and Legs overlays (placeholders); the final version holds all 18 plus the outfit.
- `hero_visual.gd` only shows the overlay that matches `GameState.implants[slot]` and hides the others, and refreshes
  on `EventBus.implants_changed`. The surgery panel's preview turns `follow_game_state` off to show the next tier.
  Outfit cosmetics will swap the outfit's `SpriteFrames`.
- For pixel art, every layer is an `AnimatedSprite2D` sharing the same animation names. For HD art, it becomes a
  `Skeleton2D` cutout rig with one pre-placed `Sprite2D` per bone and slot. This is decided with the art style
  (open question Q2; the M4 art test was postponed and the slice uses placeholders).
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
- **Controls smoke test (M1):** run `godot --headless --path . --script res://tools/smoke_test_controls.gd`.
  It loads `controls_test.tscn`, plays scripted gestures and checks 17 reactions. The checks cover:
  - holding moves and fires;
  - lifting stands;
  - a swipe rolls;
  - lifting near cover slides into cover and hugs the near face;
  - cover absorbs bullets from its side only;
  - auto-fire damages a dummy;
  - a double-tap fires the EMP and clears bullets;
  - the roll's i-frames let bullets pass.
- **Combat smoke test (M2):** run `godot --headless --path . --script res://tools/smoke_test_combat.gd`.
  It loads `combat_test.tscn` and checks 31 results. The checks cover:
  - wave spawning, spawn-in and drops;
  - the wave-clear reward and the pickup magnet;
  - floor guns, swapping and firing with a found gun;
  - the empty-gun fallback;
  - barrel explosions;
  - swarmer contact damage;
  - a charger smashing cover;
  - EMP stuns, turret fire and rivet piercing.
- **Level generator test (M3):** run `godot --headless --path . --script res://tools/test_level_generator.gd`.
  It generates 10,000 levels from `level_1.tres` and checks that every one passes `LevelGenerator.validate()`. It also
  checks that layouts vary, that a seed always gives the same layout, that `validate()` catches broken layouts, and that
  chest rarity rolls follow the level's odds.
- **Level smoke test (M3):** run `godot --headless --path . --script res://tools/smoke_test_level.gd`.
  It loads `level.tscn` and plays generated levels, checking 55 results. The checks cover:
  - door states, transitions and arrival at the matching door, with each door leading exactly one room on;
  - locked fights, spawning, baked navigation, the room reward, and cleared rooms staying cleared;
  - chests (with their state kept), the memory shrine, the repair shop, and a terminal's ambush and chest prize;
  - the challenge arena's 3 waves and Rare-or-better chest;
  - the boss, its HUD bar, the elevator and the next level;
  - the minimap.
- **M4 smoke test:** run `godot --headless --path . --script res://tools/smoke_test_m4.gd`. It checks 42 results:
  - Heart and Legs implants at every tier (hearts, armor, the room-clear heal, speed, roll distance, the shockwave) and
    the paper doll;
  - every armory gun's trait (damage, bounce, homing, stun, pierce, bursts and blasts) and unlock-filtered chests;
  - SCRAPJAW: plowing charges, wall stuns, the Magnet phase (streams, pull, scrap piles), Grind, and the elevator;
  - the lab's surgery (hold to confirm, costs, tiers, comics) and armory.
- **Flow smoke test:** run `godot --headless --path . --script res://tools/smoke_test_flow.gd`. It checks 28 results:
  slot and run files (including a corrupt and a future-version file), settings, and the real scene flow from the title
  through the prologue, the tutorial, the lab, a run, Save and quit, Continue run, death, and the boss elevator. It
  saves to `user://test_saves/`, never to real slots.
- **Level 2 smoke test (M5):** run `godot --headless --path . --script res://tools/smoke_test_l2.gd`. It checks 44
  results:
  - holo-signs, Drones, Hackers, every elite modifier and the elite ambush;
  - GLITCH's three phases;
  - the Junk Cannon, Arc Caster and Overclock Pistol;
  - Hawk Optics and Neural Coprocessor at every tier;
  - memory band variants and the Level 2 lab talks.

  The generator test now validates 10,000 layouts for every campaign level, and the flow test covers L1 → lab → L2.
- **Unit tests** for the remaining pure logic: the gesture classifier and economy math. Pick GUT or
  gdUnit4 when they grow past the smoke tests.
- **Playtest builds** include the debug overlay. Optional local telemetry (deaths per room, gesture misclassifications)
  only runs with the tester's consent.
- Every milestone ends with a playtest on real devices ([roadmap.md](roadmap.md)).
