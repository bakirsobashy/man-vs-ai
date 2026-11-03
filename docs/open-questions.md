# Man vs AI — Open Questions & Risks

**Version:** 0.1. Update this file whenever a decision is made: move the answer into the relevant doc and mark the row
**Decided**.

## Open decisions
| ID | Question | Options | Needed by | Notes |
|---|---|---|---|---|
| Q1 | What is Dr. Vorn's true role? | A) true ally · B) hidden villain who ordered or enabled the attack to get his test subject · C) morally grey, shown differently in each ending | Before the ending scripts (M5); ideally M4 | Until then, every Vorn line must work for A, B and C ([narrative.md](narrative.md) §5) |
| Q2 | Art direction | Pixel art · HD hand-drawn or vector · other | M4 art test | Constraints are in [GDD](GDD.md) §11. Affects texture filter and pixel-snap settings |
| Q3 | Final title | "Man vs AI" (working) · "Meatware" · "Flesh Protocol" · "Last Human Standing" | M5 (store listing) | Check trademark and store-name availability |
| Q4 | Placeholder names (cast, city, gang, bosses, districts, weapons) | Keep or rename | M4 | Listed in [narrative.md](narrative.md) §12 |
| Q5 | What happens after an ending? | Keep playing the same save · NG+ / threat levels · nothing | M5 | Permanent power makes repeat runs easy |
| Q6 | Should human-path players get a RAM sink? | None (pure hard mode) · RAM → Crypto exchange at a bad rate · hacked terminals only | M4 balance | The owner chose "hard mode by design"; hacked terminals already use RAM |
| Q7 | How to handle weapon-pool dilution | Accept it · "favorite" weights · let players disable unlocked guns | M5 | Unlocking weak guns lowers the odds of good ones; Gungeon has the same problem |
| Q8 | Should the Normal ending have variants for Patched (1–2) and Hollow (3–5)? | One ending · two flavors | M5 | [narrative.md](narrative.md) §9 |
| Q9 | Is the Second Chance ad allowed during the final boss? | Yes · no | M6 | |
| Q10 | Voice acting scope | None · barks only · key lines | M4 (budget) | Every line is subtitled regardless |
| Q11 | Sell an "ad-free rewards" IAP? | No · yes | M6 | Could read as pay-to-win; the owner said ads are "a small help" only |

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
| R15 | M2 enemies steer straight and can get stuck behind cover | Strafe flips on collision for now; M3 adds `NavigationAgent2D` with navigation baked around each room's cover |
