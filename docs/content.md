# Man vs AI — Content & Balance Sheet

**Version:** 0.1 (draft). Every number here is a **first-pass [PROPOSED] value** to tune in playtests.
**Units:** 1 tile = 16 px; time in seconds; damage in HP. A hit on the hero costs ½ heart unless noted. **†** = placeholder name.
**Baseline:** the starter pistol deals 4 damage per shot at 4 shots/s, or 16 DPS.

---

## 1. Districts
| Level | District† | Look | Hazards | New enemies | Boss† | Music mood |
|---|---|---|---|---|---|---|
| 1 | Rustline Slums | Rain, scrap, shipping containers, flickering neon | Explosive barrels | Grunt, Charger, Turret, Swarmer | SCRAPJAW | Slow industrial, rain |
| 2 | Neon Bazaar | Holo-ads, stalls, lanterns | Holo-signs (block sight, not bullets) | Shotgunner, Drone, Hacker | GLITCH | Glitchy synth-pop |
| 3 | The Foundry | Conveyors, molten channels, robot arms | Conveyors, molten lanes | Grenadier, Shield-bot | FORGEMOTHER | Heavy percussion |
| 4 | Skyline Spires | Glass, wind, searchlights | Timed laser grids, cracking glass floors | Sniper, EMP-bot | WARDEN | Cold, sparse, high synths |
| 5 | Syndicate Core | Servers, cables, coolant | Coolant floods (slow), firewall lasers | Null Knight, plus elite variants | ZERO | Every motif combined |

---

## 2. Enemies (robots only)
| Enemy† | From | Role | Behavior | Attack (telegraph) | HP | Threat | RAM (MB) | Spawn kind |
|---|---|---|---|---|---|---|---|---|
| Grunt | L1 | Basic shooter | Holds mid range, strafes | 3-round aimed burst (0.4 s glow) | 20 | 1 | 3 | ground |
| Charger | L1 | Melee **flusher** | Locks onto a line and dashes, smashing cover in its path; stunned 1 s if it hits a wall | Contact, ½ heart (0.6 s red glow + line) | 30 | 1.5 | 4 | ground |
| Turret | L1 | Area denial | Stationary | Slow rotating 8-way bursts (0.5 s spin-up) | 40 | 2 | 5 | stationary |
| Swarmer | L1 | Swarm | Groups of 4–6 that rush the hero | Contact (slow and weak, no telegraph) | 6 | 0.5 | 1 | ground |
| Shotgunner | L2 | Pressure | Closes distance | 5-bullet 40° spread (0.5 s pump) | 28 | 1.5 | 4 | ground |
| Drone | L2 | Aerial **flusher** | Flies over cover and walls, circles | Aimed shots that ignore cover protection (0.4 s blink) | 15 | 1 | 3 | flyer |
| Hacker | L2 | Support **flusher** | Keeps its distance, hides behind allies | Rigs a cover object: it blinks red for 1.5 s, then explodes (1 heart, 2 tiles). Also shields one ally | 22 | 2.5 | 8 | ground |
| Grenadier | L3 | **Flusher** | Stays far away | Grenade lobbed at the hero's position: landing circle for 1.0 s, explosion ignores cover | 30 | 2 | 5 | ground |
| Shield-bot | L3 | Blocker | Frontal shield blocks player bullets; turns slowly | 6-bullet wave every 2.5 s, lowering the shield (the attack window) | 45 | 3 | 8 | ground |
| Sniper | L4 | Long range | Stays at max range, relocates after each shot | Laser sight for 1.0 s, then a fast shot (1 heart). Cover blocks the laser | 25 | 2 | 6 | ground |
| EMP-bot | L4 | **Flusher** | Slow; projects a 3-tile EMP field | The field shorts out cover (no protection inside it); a pulse knocks the hero back | 35 | 2.5 | 6 | ground |
| Null Knight | L5 | Elite guard | Mirrors the hero: rolls through bullets, uses cover | Burst, roll and grenade combos | 80 | 5 | 16 | ground |

**Elite modifiers** (from L2; chance by level in §6). Elites cost 2× threat and drop 3× RAM.
| Modifier | Effect | Visual |
|---|---|---|
| Overclocked | +50% fire rate and speed | Red glow, sparks |
| Armored | +100% HP, −20% speed | Extra plating |
| Splitter | Spawns 2 Swarmers on death | Blinking core |
| Shielded | Absorbs the first 3 hits | Blue bubble |

Enemy RAM drops scale by ×(1 + 0.15 × (level − 1)).

**Where the numbers live:** HP, speed, RAM drop and spawn kind are exported on each enemy scene. Threat costs live in each
level's `LevelConfig` enemy pool. A `SpawnPoint` only accepts the spawn kinds ticked in its Inspector
([technical.md](technical.md) §0.4).

---

## 3. Weapons
"Reload" is the base time at standing speed. It takes 2× as long while running and about 0.7× as long in cover (GDD §3.3).
"Ammo" is the total pool.

| # | Weapon† | Class | Rarity | Unlock ◈ | Dmg | Shots/s | Mag | Reload | Ammo | Trait / flavor |
|---|---|---|---|---|---|---|---|---|---|---|
| 0 | Service Pistol "Old Faithful" | Pistol | Starter | — | 4 | 4 | 10 | 1.2 | ∞ | Kade's army sidearm. *"Never jammed. Never left."* |
| 1 | Scattergun | Shotgun | Common | free | 3×5 | 1.5 | 6 | 1.6 | 60 | 30° spread |
| 2 | Buzz SMG | SMG | Common | free | 2 | 12 | 30 | 1.4 | 300 | 8° inaccuracy |
| 3 | Rivet Driver | Nail gun | Common | free | 5 | 5 | 16 | 1.3 | 160 | Pierces 1 enemy |
| 4 | Bolt Revolver | Revolver | Common | 60 | 14 | 2 | 6 | 1.5 | 90 | Heavy single shots |
| 5 | Junk Cannon | Launcher | Common | 60 | 8–20 | 1.2 | 6 | 1.8 | 48 | Fires random scrap; big chunks knock back |
| 6 | Ricochet Carbine | Rifle | Common | 60 | 5 | 5 | 20 | 1.4 | 200 | Bullets bounce off walls twice |
| 7 | Arc Caster | Energy | Rare | 150 | 6 | 3 | 12 | 1.5 | 120 | Lightning chains to 2 more robots |
| 8 | Magnet Coil | Pistol | Rare | 150 | 5 | 4 | 14 | 1.2 | 160 | Mild homing |
| 9 | Volt Shotgun | Shotgun | Rare | 150 | 3×6 | 1.2 | 5 | 1.8 | 50 | Pellets stun for 0.3 s |
| 10 | Longshot | Marksman | Rare | 150 | 28 | 1 | 5 | 1.8 | 60 | Pierces every enemy; very fast bullet |
| 11 | Firecracker | Burst rifle | Rare | 150 | 4×3 | 2 bursts | 9 | 1.6 | 135 | Each bullet pops in a tiny blast |
| 12 | Cryo Sprayer | Sprayer | Rare | 150 | 1/tick | 15 | 60 | 1.6 | 400 | Short range; freezes after a buildup |
| 13 | Overclock Pistol | Pistol | Rare | 150 | 4 | 3→9 | 24 | 1.4 | 240 | Fire rate ramps up the longer you keep firing (rewards staying exposed) |
| 14 | Rail Spike | Railgun | Epic | 250 | 60 | 1.2 s charge | 3 | 2.0 | 30 | Auto-fires when charged; pierces cover and enemies |
| 15 | Scrap Minigun | Minigun | Epic | 250 | 2 | 20 | 120 | 2.5 | 600 | 0.6 s spin-up; −20% move speed while firing |
| 16 | Swarm Launcher | Launcher | Epic | 250 | 6×4 | 1 | 4 | 2.0 | 40 | Homing micro-missiles |
| 17 | Beam Cutter | Beam | Epic | 250 | 30 DPS | beam | 3 s | 1.8 | 60 s | Continuous beam; shreds cover |
| 18 | Toaster Cannon | Oddball | Epic | 250 | 10 + burn | 2 | 8 | 1.5 | 80 | Fires flaming toast that leaves burning ground. *Patch's finest work.* |
| 19 | Peacekeeper | Rifle | Legendary | 400 | 8 | 8 | 40 | 1.6 | 400 | A stolen STEWARD police rifle; ignores enemy shields |
| 20 | Black Box | Oddball | Legendary | 400 | 3 + absorbed | 1 | 3 | 2.2 | 36 | A slow orb that eats enemy bullets and bursts them back out as yours |
| 21 | M7 Line Rifle | Rifle | Legendary | story | 10 | 6 | 30 | 1.4 | 300 | Kade's old service rifle; unlocked free after the first WARDEN kill |

- **New-save pool:** #0–#3.
- **Built in M4:** #0–#3 plus the armory's first six unlocks: #4 Bolt Revolver, #6 Ricochet Carbine, #8 Magnet Coil,
  #9 Volt Shotgun, #10 Longshot and #11 Firecracker. The others arrive in M5.
- **Total Crypto to unlock everything:** 3×60 + 7×150 + 5×250 + 2×400 = **3,280 ◈**.
- **Where the numbers live:** combat stats are exported on each weapon scene, and its range is the circle of its `Range` area.
  Rarity and unlock cost are in `data/weapons/weapon_catalog.tres`.

---

## 4. Bosses
HP values are first-pass numbers that assume the expected hero power at that level.

### SCRAPJAW† (L1, The Breaker). Teaches destructible cover. HP 600
| Phase | HP | Attacks |
|---|---|---|
| 1 · Wreck | 100–60% | Charges in a straight line (0.8 s tell), destroying cover in its path. Stunned for 1 s if it hits a wall, which opens a damage window. Slow 8-way bolt spray between charges |
| 2 · Magnet | 60–25% | Magnet pull: scrap streams across the arena toward it (lines to dodge), then drops in piles that become new cover. A light pull on the hero |
| 3 · Grind | < 25% | Spins its jaw and moves with a bullet spiral; double charges |

Arena: a scrapyard full of light cover.
**Built in M4:**
- Each phase loops through its attacks: Wreck charges (300 px/s, cover smashed, 1 s wall stun) with a 3-volley 8-way spray.
- Magnet: streams from 3 of 8 hand-placed scrap spots for 2.4 s, a 28 px/s pull, and 2 scrap piles of light cover
  per pull.
- Grind: a 3 s spiral chase, then a double charge.
- Contact damage is 1 heart; drops are 64 MB, 50 Crypto and an ammo pickup.

### GLITCH† (L2, The Liar). Teaches reading bullets and beating auto-aim. HP 700
| Phase | HP | Attacks |
|---|---|---|
| 1 · Decoys | 100–65% | 2 decoys (no shadow, slight flicker). The real Glitch fires aimed fan bursts; decoys fire hollow, outline-only bullets that do no damage. Auto-aim may pick a decoy, and shooting one pops it |
| 2 · Holo-walls | 65–30% | Teleports between the arena edges; temporary holo-walls box the hero in while it fires through the gaps |
| 3 · Static Storm | < 30% | 4 decoys, faster teleports, brief screen glitches (toned down by the reduced-flashing setting) |

### FORGEMOTHER† (L3, The Maker). Teaches target priority and moving floors. HP 850
| Phase | HP | Attacks |
|---|---|---|
| 1 · Assembly | 100–60% | Builds 2 Swarmers every 6 s; fires lines of molten rivets. Conveyors move both the hero and the cover |
| 2 · Overtime | 60–30% | Conveyors speed up and reverse; crates ride in as new cover; grenade arcs |
| 3 · Meltdown | < 30% | Core exposed (takes ×2 damage); floods molten lanes (1.0 s tell) |

### WARDEN† (L4, The Watcher). Teaches directional cover and flanks. HP 1,000
| Phase | HP | Attacks |
|---|---|---|
| 1 · Overwatch | 100–60% | Perched: sniper laser (1.0 s tell, 1 heart) while 2 Drones flank |
| 2 · Suppression | 60–30% | EMP pulses short out cover; sweeping suppressive fire |
| 3 · Hunt | < 30% | Drops down and strafes fast, mixing laser sweeps with snipes |

The first kill unlocks the M7 Line Rifle.

### ZERO† (L5, The Leader). The final exam. HP 1,400
| Phase | HP | Attacks |
|---|---|---|
| 1 · Duel | 100–65% | Mirrors the hero: rolls through bullets, takes cover, fires bursts |
| 2 · Syndicate | 65–30% | Echoes earlier bosses: Scrapjaw's charge, Glitch's decoys, Forgemother's minions, Warden's laser |
| 3 · Zero Hour | < 30% | Overclocked bullet-hell as the arena edges close in. At 0 HP, the ending scene for the hero's band plays |

---

## 5. Implants
**Costs per slot:** Mk I 256 MB · Mk II 512 MB · Mk III 1,024 MB. Tiers are cumulative: Mk II keeps Mk I's effect and adds its own.
**Totals:** all 6 slots at Mk I = **1,536 MB** (the cheapest route to Transformation); every slot at Mk III = **10,752 MB**.

| Slot | Implant† | Mk I | Mk II | Mk III | Sprite change (I → II → III) |
|---|---|---|---|---|---|
| Eyes | Hawk Optics | Auto-aim range +25%; target HP shown | +15% crit chance (×2 damage) | Threat Sight: telegraphs show 0.2 s earlier, and bullets aimed at you are highlighted | Red iris → chrome socket → full visor |
| Brain | Neural Coprocessor | +1 EMP charge per level | EMP stun radius 4 → 6 tiles, stun 2.5 s | Failsafe: once per level, a lethal hit triggers a free EMP and is negated | Temple port → skull plate → glowing cortex dome |
| Arms | Servo Arms | Reload 25% faster | −40% spread, +15% fire rate | Dual Wield: both carried guns fire at once | Mechanical forearm → chrome arm → both arms chrome |
| Heart | Fusion Heart | +1 max heart | Start each level with +1 armor | +1 more max heart; heal ½ heart every 3 cleared rooms | Glowing chest seam → reactor glow through the shirt → exposed core |
| Lungs | Filter Lungs | Roll recovery −30% | Immune to gas, fire and molten floors; roll i-frames 60% → 75% | Second Wind: rolling through an enemy bullet triggers 0.4 s of slow motion and +20% damage for 3 s | Neck vents → rebreather → full respirator, venting steam |
| Legs | Hydraulic Legs | Move speed +12% | Roll distance +30% | Each roll ends in a shockwave: 10 damage within 1.5 tiles, and it clears bullets | Knee braces → mechanical legs → digitigrade hydraulics |

Art budget: 6 slots × 3 tiers = **18 overlay sets**, each covering every hero animation and direction.

**Built in M4:** Heart and Legs, all three tiers, from `data/implants/*.tres`. The other four slots show in surgery as
"arrives in M5".

---

## 6. Rooms and generation parameters
| Parameter | L1 | L2 | L3 | L4 | L5 |
|---|---|---|---|---|---|
| Combat rooms | 4–5 | 4–5 | 5–6 | 5–6 | 5–6 |
| Chest rooms | 1–2 | 1–2 | 1–2 | 1–2 | 1–2 |
| Special rooms (memory included) | 1–2 | 1–2 | 2 | 2 | 2 |
| Total rooms (clamped) | 8–9 | 8–9 | 9–10 | 9–10 | 9–10 |
| Waves per combat room | 1–2 | 1–2 | 2 | 2–3 | 2–3 |
| Threat budget per wave | 6 | 8 | 10 | 12 | 14 |
| Elite chance per spawn | 0% | 10% | 15% | 20% | 25% |

The `WaveSpawner` spends each wave's threat budget at the room's hand-placed SpawnPoints. Room scenes contain no
enemies, only the points where enemies can appear.
- **Level 1** (`data/levels/level_1.tres`, M3): the room counts, special-room odds, waves, budgets and chest odds in
  these tables. Its enemy pool (`level_1_waves.tres`) is Grunt 1, Charger 1.5, Turret 2 and Swarmer 0.5 in groups
  of 4–6, all from a room's first wave. Spawn points closer than 4 tiles to the hero are skipped.
- **The M2 arena** (`m2_arena_waves.tres`) uses the same robots, with Charger and Turret from wave 2, and an endless
  budget of 6 + 1.5 per wave (cap 14).

**Odds for the second special room** (the first one is always the Memory room): Repair station 40% (50% in L1),
Challenge arena 30%, Hacked terminal 30%.

**Cover damage:** an enemy bullet deals 4 to cover; a Sniper shot 20; an explosion 50. A Charger destroys Light and
Medium cover outright and deals 150 to Heavy. Player bullets deal 50% of their damage to cover. Cover HP is exported on each cover scene (GDD §4.6 values).

---

## 7. Special rooms
### Repair station (3 purchases per station)
| Item | Price (◈, L = level) |
|---|---|
| ½ heart | 10 + 5×L |
| Armor pip | 15 + 5×L |
| EMP charge | 20 + 5×L |
| Ammo refill (found gun) | 8 + 4×L |

### Hacked terminal (costs 32×L MB of RAM, one use per terminal)
| Outcome | Chance |
|---|---|
| Rare-or-better chest | 30% |
| Crypto jackpot (40×L ◈) | 20% |
| Full ammo + 1 armor | 15% |
| Elite ambush (one elite, 3× RAM; until elites arrive in M5, one wave of 3 threat) | 15% |
| Virus: −1 EMP charge this level | 10% |
| "ERROR 404": nothing happens | 10% |

The terminal uses in-game currency only. No real money is ever involved, so it isn't a loot box.

### Challenge arena
3 waves at the next level's threat budget, with the doors locked until they're done.
**Reward:** a Rare-or-better chest, 30×L ◈ and 48×L MB.

### Memory room
No enemies. It holds one memory item (added to the codex) and heals ½ heart once. The visuals and text vary by humanity band.

---

## 8. Loot and economy

### Chest rarity odds by level (Common / Rare / Epic / Legendary, %)
| L1 | L2 | L3 | L4 | L5 |
|---|---|---|---|---|
| 70 / 25 / 5 / 0 | 55 / 33 / 10 / 2 | 40 / 40 / 16 / 4 | 30 / 40 / 24 / 6 | 20 / 40 / 30 / 10 |

A chest holds **one weapon of its rarity** from this save's unlocked pool. If nothing of that rarity is unlocked, it drops to the next
lower rarity; if the pool has nothing usable at all, it gives 15 × tier ◈ instead. Every chest also adds a **5 × tier ◈ bonus**
(tiers: Common 1, Rare 2, Epic 3, Legendary 4).

### Crypto sources
| Source | Crypto |
|---|---|
| Room clear | 3–6 × L |
| Breakable object | 0–2 |
| Chest bonus | 5 × tier |
| Boss | 40 + 10 × L |
| Challenge arena | 30 × L |

### RAM sources
- **Enemies:** §2, scaled by level.
- **Bosses:** 64 / 80 / 96 / 112 / 128 MB (L1–L5).
- **Challenge arena:** 48 × L MB.

### Expected income per level (average play, excluding elites and arenas)
| | L1 | L2 | L3 | L4 | L5 | Full run |
|---|---|---|---|---|---|---|
| RAM (MB) | ~170 | ~250 | ~480 | ~760 | ~960 | **~2,600** |
| Crypto (◈) | ~85 | ~115 | ~165 | ~200 | ~240 | **~800** |

**How these were estimated:** RAM ≈ rooms × waves × threat budget × ~2.7 MB per threat point × the level multiplier, plus the boss.
Crypto ≈ room clears + chest bonuses + boss + breakables.

### Pickup drop rates
| Pickup | Source | Rate |
|---|---|---|
| ½ heart | Room clear | 10% |
| Ammo | Room clear / per enemy | 25% / 3% |
| Armor | Room clear | 5% |
| EMP charge | Chest bonus | 10% |

Pickups are magnetic within 2.5 tiles.

### Rewarded ads (a small help only)
| Placement | Reward | Limit |
|---|---|---|
| Second Chance | Revive with 1 heart and a free EMP | Once per run |
| Salvage bonus | +25% of the run's Crypto | Once per run summary |
