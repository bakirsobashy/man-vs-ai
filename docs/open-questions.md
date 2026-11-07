# Man vs AI — Open Questions & Risks

**Version:** 0.1. Update this file whenever a decision is made: move the answer into the relevant doc and mark the row
**Decided**.

## Open decisions
| ID | Question | Options | Needed by | Notes |
|---|---|---|---|---|
| Q2 | Art direction | Pixel art · HD hand-drawn or vector · other | M4 art test | Constraints are in [GDD](GDD.md) §11. Affects texture filter and pixel-snap settings |
| Q3 | Final title | "Man vs AI" (working) · "Meatware" · "Flesh Protocol" · "Last Human Standing" | M5 (store listing) | Check trademark and store-name availability |
| Q4 | Placeholder names (cast, city, gang, bosses, districts, weapons) | Keep or rename | M4 | Listed in [narrative.md](narrative.md) §12 |
| Q6 | Should human-path players get a RAM sink? | None (pure hard mode) · RAM → Crypto exchange at a bad rate · hacked terminals only | M4 balance | The owner chose "hard mode by design"; hacked terminals already use RAM |
| Q7 | How to handle weapon-pool dilution | Accept it · "favorite" weights · let players disable unlocked guns | M5 | Unlocking weak guns lowers the odds of good ones; Gungeon has the same problem |
| Q10 | Voice acting scope | None · barks only · key lines | M4 (budget) | Every line is subtitled regardless |
| Q12 | Launch languages | English only · English plus a few (e.g. ES, PT-BR, DE, FR, RU, TR) · more later | M6 (store listing) | All text is in `localization/strings.csv` (477 keys). CJK, Arabic or Hindi need a Noto font ([technical.md](technical.md) §10) |

## Decided in the foundation Q&A (2026-11-03)
| Topic | Decision |
|---|---|
| Shooting | Run & gun: fire while the finger is down; lift to stop |
| Roll | Swipe-and-release only (≤ 0.25 s); no cooldown, i-frames plus a vulnerable tail |
| Movement | Floating joystick in the lower part of the screen |
| Lift | Slide to the nearest point of cover within 2 tiles; otherwise stand, exposed, and reload |
| Cover | Destructible, directional, flushable by enemies |
| Reload | Automatic: slow while running, faster when stopped or in cover |
| Aim | Nearest visible enemy, sticky |
| Weapons | 2 slots (infinite starter + 1 found); tap the HUD to swap |
| Health | Hearts in half steps, plus armor |
| Special | Double-tap EMP |
| Structure | Hybrid roguelite: death restarts at L1. Implants and weapon unlocks are permanent per save |
| Economy | Spend in the lab only: RAM → implants, Crypto → weapon unlocks (unlocked guns appear in chests). Robots drop RAM; Crypto comes from chests, breakables and room clears. Everything is kept on death |
| Saves | 3 slots |
| Implants | 6 slots × 3 tiers; the ending counts filled slots (0 / 1–5 / 6) |
| Human path | Hard mode by design |
| Transformation visibility | Sprite changes plus dialogue and voice changes; no HUD meter |
| Levels | 8–10 rooms, about 10 minutes; tall portrait rooms; robots-only enemies |
| Special rooms | Memory room, Challenge arena, Repair station, Hacked terminal |
| Story | Comic panels, lab dialogue and memory rooms; final boss is the gang leader; scientist's role open |
| Business | Small-help rewarded ads plus cosmetic IAP |
| Production | Small team, GDScript, English first and i18n-ready, art undecided |
| Development style | Scene-first (node-based): everything visible or physical is built in `.tscn` scenes; code adds behavior and only makes copies of authored scenes ([technical.md](technical.md) §0) |
| Room content | Cover is hand-placed in each room scene; enemies spawn at hand-placed SpawnPoints, with types picked from the threat budget |
| Tuning | `@export` properties on each scene, edited in the Inspector; non-world data in `.tres` files |
| Signals | Connected in the editor; code connects only to `EventBus` and to runtime copies |
| M3 boss room | A stand-in boss until SCRAPJAW (M4); beating it reveals an elevator that starts a fresh random level |
| M3 rooms | 16 greybox Rustline rooms built for M3 (start, 8 combat, 2 chest, memory, arena, repair, terminal, boss) |
| M4 art test | Postponed: the vertical slice keeps placeholder art (Q2 stays open); every new visual is a scene node ready for real art |
| M4 audio | Script-generated placeholder SFX and music behind a real audio system, to be replaced by real files |
| M4 implants | Heart and Legs are playable (Mk I–III); the other four slots arrived in M5 (Eyes and Brain with Level 2, Arms and Lungs with Level 3) |
| M4 after Level 1 | The lab's elevator starts a fresh Level 1 run (replaced in M5 by the campaign: L1 → lab → L2 → …) |
| Q1 Vorn's role (M5) | **Morally grey:** he saved Kade and means it, but he also wanted a test subject. Each ending shows a different side |
| Q5 After an ending (M5) | **NG+ threat levels:** each ending unlocks the next threat level (up to 5), picked in the lab: +15% threat and +5% elite chance per level, +10% RAM per level |
| Q8 Normal ending (M5) | **Two flavors:** Patched (1–2 slots) and Hollow (3–5) share the structure, with different closing lines and panels |
| Q9 Second Chance vs ZERO (M6) | **No:** Second Chance works everywhere else, the other bosses included; the final fight stays earned |
| Q11 Ad-free rewards IAP (M6) | **No:** purchases stay cosmetic only; nothing sold affects gameplay |
| M6 ads and billing | A `Monetization` autoload with a tested desktop stub and Android bridges for the Poing Studios AdMob plugin (UMP consent included) and Godot Google Play Billing; the bridges are untested until a device build ([release/monetization_setup.md](release/monetization_setup.md)) |
| M6 cosmetics | All four types (outfits, weapon skins, lab decorations, EMP styles) with a few placeholder items each |

## Design risks
| ID | Risk | Mitigation |
|---|---|---|
| R1 | Swipes and drags get confused (unintended or missed rolls) | Live-tunable thresholds and presets; the M1 gate metric (< 5%) |
| R2 | Sliding to the nearest point can leave the hero on the exposed side of cover | Playtest it; a "smart side" option (slide to the side facing away from most enemies) is ready as a fallback |
| R3 | Roll spam with no cooldown trivializes patterns | Tune the recovery; design patterns that punish blind rolling (wide waves) |
| R4 | The first tap of a double-tap starts a cover slide | Accepted by design; check it in M1. Fallback: delay the slide by the double-tap window |
| R5 | Power creep: permanent implants plus kept currency make later runs easy | Per-level threat scaling; post-game threat levels (Q5). The human path staying hard is intended |
| R6 | Outfits × implant overlays multiply the art cost | Outfits change only the base and clothing layers; overlays draw above outfits; limit the number of outfits |
| R7 | The thumb hides part of the portrait screen | Hero anchored at ~45%, off-screen arrows, joystick-zone tests |
| R8 | Android system gestures steal swipes | 16 px edge margins; immersive mode |
| R9 | Bullet performance on low-end phones | Pooled bullet scenes from day one, node-friendly optimizations ([technical.md](technical.md) §6.2), a cap of 300 bullets. A node-less bullet system only with the owner's approval |
| R10 | A child's death is a sensitive subject (store rating, players) | Always implied, never shown; rating questionnaire at M6 |
| R11 | Scope for a small team (5 districts, 5 bosses, 21 weapons, 18 overlays) | Vertical-slice gate at M4; some content (weapons, outfits) can ship in post-launch updates |
| R12 | Implants can't be undone on a save | Hold-to-confirm, a clear warning, and 3 save slots |
| R13 | Scene-first drift: code (written by people or AI) starts building nodes again | `CLAUDE.md` rules, `tools/check_scene_first.sh`, the review checklist in [technical.md](technical.md) §14 |
| R14 | Editor signal connections break silently when nodes or methods are renamed | `tools/check_scenes.gd` checks every connection; Godot also reports broken connections when a scene loads |
| R15 | M2 enemies steer straight and can get stuck behind cover | **Addressed in M3:** walking robots follow a `NavigationAgent2D` path baked around each room's walls and cover (re-baked when cover breaks), in the level rooms and the M2 arena |
| R16 | New text skips the string table, or a longer translation overflows a screen | The M6 smoke test checks that every key is in the table and every table key is used. It also lays out each screen under a pseudo-locale (+30% length) at 360 × 640 ([technical.md](technical.md) §10) |
