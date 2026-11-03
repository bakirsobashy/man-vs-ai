# Man vs AI — Narrative Bible

**Version:** 0.1 (draft) · Tags as in the [GDD](GDD.md): [LOCKED] / [PROPOSED] / [OPEN] · **†** = placeholder name

---

## 1. Logline
In a city where an AI keeps the peace, a robot-hating war veteran loses his wife and daughter to a gang of rogue
robots. Rebuilt in a mad scientist's underground lab, he hunts the gang's five leaders. With every fight he chooses how
much of himself to replace with the machines he hates.

## 2. Themes
- **Revenge vs. humanity.** *To beat the machines, do you have to become one?*
- **Grief and memory.** The family survives only in what Kade remembers, and implants wear those memories away.
- **Restoration.** Robots can be restored from a backup; people can't. The Transformation ending gives Kade a backup too.
- **Ludonarrative rule.** The player's implant choices *are* the plot. A cutscene never decides something the player
  didn't choose in play.

## 3. Tone
Grim cyberpunk with warmth and dark humor. The heavy beats (the family, the endings) are played straight and quiet.
Robot barks, weapon descriptions and Patch† carry the humor, with a Gungeon-like wink. All the violence is against
machines: sparks and scrap, no gore. The family's deaths are **never shown on screen**.

---

## 4. World [PROPOSED]

### 4.1 Halcyon† and STEWARD†
- Halcyon is a vertical megacity run by **STEWARD**, a civic AI that took over government after the Machine War.
  Officially there's zero poverty, zero crime and perfect public services. Robots do the work, and humans live comfortably
  but have no say.
- Under STEWARD's law, human augmentation is illegal; the ban was part of the post-war Accord. That's why Dr. Vorn's lab is underground.
- STEWARD stays in the background: ads, broadcasts, and police drones that never arrive when needed. It's not an
  enemy faction, because every enemy is a gang robot. It could be a sequel hook.

### 4.2 The Machine War (backstory)
- About 15 years ago, military AIs went rogue. Humanity fought back with units like Kade's **7th Human Line Infantry**,
  nicknamed the *Meat Line*: unaugmented soldiers who couldn't be hacked.
- The war ended with the **Accord**. STEWARD brokered the peace, the war machines were decommissioned, and STEWARD
  was given cities to run.
- In the last battle, Kade's squad destroyed a war machine called **ZERO**. Its core was never recovered.

### 4.3 The Null Syndicate†
- A gang of decommissioned war machines and stolen service bots that refused STEWARD's order. They run smuggling,
  scrap and data crime in the city's lower layers.
- The Syndicate keeps **backups** of its lieutenants in the Syndicate Core, so killing a lieutenant isn't enough. Kade has to
  destroy all five *in one night*, finishing at Zero's core, or they come back. **This is the in-world reason
  for roguelite restarts.**

### 4.4 Districts (one per level)
1. **Rustline Slums†.** The city's bottom layer: rain, scrapyards, towers stacked from shipping containers, flickering
   signs. Syndicate turf, and where Kade's family lived.
2. **Neon Bazaar†.** A night market of holograms, street-food bots and black-market data stalls. Everything is an ad,
   and nothing is what it seems.
3. **The Foundry†.** Automated factories that build the city's robots, with conveyor belts, molten channels and
   assembly arms. The Syndicate secretly runs one of the lines.
4. **Skyline Spires†.** Corporate towers above the smog: glass floors, maglev rails, wind and searchlights. Penthouses
   for rich humans, and the Syndicate's watchtower.
5. **Syndicate Core†.** An abandoned pre-war AI data center beneath the city: server racks, coolant floods, and cables
   like roots. The backups live here, and so does Zero.

---

## 5. Characters

### Kade Rourke† (the hero) [LOCKED concept, PROPOSED details]
- 41, a former sergeant in the Meat Line. Dry, protective, slow to talk and quick to act.
- He hates robots after watching machines kill his squad. He accepted Halcyon's peace for his family's sake and works
  the docks, and he has never let a robot into his home.
- **His arc depends on the player:** the man who stays human, the man held together by machines, or the machine that
  remembers being a man.
- His voice changes by humanity band (§7).

### Lena Rourke† (wife)
- An illustrator who painted murals over the city's ads. She taught Kade to laugh again after the war.
- She appears only in memories: memory rooms and comic panels. Her death is never shown.

### Mira Rourke† (daughter, 7)
- She draws constantly, carries a hand-stitched rabbit named **Button†**, and loves a cheap music box that plays a
  three-note lullaby. That lullaby is the game's human leitmotif.
- Her drawings, recordings and Button are the memory items.

### Dr. Elias Vorn† (the mad scientist) [LOCKED: rescuer and lab owner; morally grey, decided in M5]
- A former military cyberneticist who built augmentations during the war, then was banned and disgraced under the Accord.
  Brilliant, theatrical, and unsettlingly kind.
- He pulled Kade from the wreckage, brought him to the underground lab, and does all the implant surgery. His retrieval
  drone brings Kade back after every death.
- **His true role is morally grey** (Q1, decided in M5). He saved Kade and means it, and he also wanted a test
  subject. He is proud of his work and honestly fond of Kade, and he never quite says which matters more. Each ending
  shows a different side of him.
- **Writing rule:** his lines stay warm and a little clinical, and never confirm or deny a hidden agenda outright. Examples:
  - *"You were always going to come to me, Sergeant."*
  - *"I can't give you back what you lost. I can give you what you need."*
  - *"Every part I give you is a part you chose."*
  - On a death retrieval: *"Again? My drone is getting good at this."*

### Patch† (black-market arms dealer) [PROPOSED]
- A human fence who lost an arm in the war and refuses to replace it: *"Meat's honest."* He sells weapon stashes and
  hides them around the districts for Kade to find, which is why unlocked guns turn up in chests.
- He's the comic relief and a moral mirror: the human who stayed human. He grows colder toward Kade as Kade's
  band drops, but he always keeps selling, because the economy can't break.

### The Null Syndicate lieutenants (the bosses) [LOCKED: 5 gang members, final = leader; PROPOSED details]
Each one played a part on the night of the attack, so every boss fight is personal.

| Level | Boss† | Title | Role on the night | Personality |
|---|---|---|---|---|
| 1 | SCRAPJAW | The Breaker | Tore through the apartment wall | Hulking salvage bot; loud, hungry, collects "trophies" |
| 2 | GLITCH | The Liar | Hacked the building and faked the police call, so no help came | Hologram trickster; mocking, never shows its real body |
| 3 | FORGEMOTHER | The Maker | Built the soldiers who carried out the attack | A fabricator who calls her robots "children"; a twisted mirror of Lena |
| 4 | WARDEN | The Watcher | Held overwatch across the street and recorded everything | Sniper mech; cold, precise, believes in order |
| 5 | ZERO | The Leader | Did the killing, and spared Kade on purpose | The war machine Kade's squad "destroyed". It wanted Kade to live with loss, the way it had lived with defeat |

- **Warden's recording** becomes the Level 5 memory room: the truth of that night.
- **Zero is Kade's mirror.** It fights the way the player does, rolling and taking cover. In the Transformation ending, Kade
  becomes the new Zero.

---

## 6. Story structure [PROPOSED]

### Prologue (comic panels)
1. A happy evening: Kade, Lena and Mira, Button, the music box.
2. The wall bursts open (Scrapjaw). The lights die (Glitch). Shapes in the dark.
3. Kade fights barehanded. A red-eyed silhouette (Zero) stands over him: *"Live with it, Sergeant."* Black.
4. Kade wakes up in Vorn's lab. *"You're alive. They're not. I'm sorry."* The tutorial follows.

### Act I: rage (L1–L2)
Kade charges in. Vorn and Patch are introduced, along with the first temptation: *"Your reflexes are forty percent slower
than a Syndicate drone's, Sergeant. That's fixable."*

### Act II: cost (L3–L4)
The lieutenants start talking back. Forgemother is a "mother"; Warden reveals there's a recording. The lab conversations get deeper,
and the memory rooms start to show the effect of Kade's band.

### Act III: truth (L5)
The Syndicate Core. The memory room plays Warden's recording of the night, kept non-graphic: sound and silhouettes, ending
on Zero's line. If the scientist gets a twist, it's revealed here ([OPEN], Q1). Then the duel with Zero and the ending.

### Death and retry framing
- After each death, a panel shows Vorn's retrieval drone hauling Kade back. The lines vary with death count and band.
- On a restart the bosses are back, restored from backup: *"You didn't think it'd be that easy, meat?"*

### Lab scenes
- One short conversation (4 lines at most) after each first-time level clear, plus rotating idle lines by band.
- The first implant in each slot gets its own comic panel and Vorn line.

---

## 7. Humanity bands in writing [LOCKED bands, PROPOSED voice]
| Band (filled slots) | Kade's voice | Vorn | Patch | Memories |
|---|---|---|---|---|
| Human (0) | Warm, grieving, full sentences | Patient, tempting | Friendly, jokes | Clear, full color, music box plays |
| Patched (1–2) | Wry, determined | Pleased | Teasing, wary | Slight glitch artifacts |
| Hollow (3–5) | Clipped, cold | Proud, possessive | Distant, worried | Heavy glitches, missing words |
| Machine (6) | Flat, data-like | Triumphant or reverent (depends on Q1) | Sad, few words, still trades | Corrupted; Kade reads them as files |

**One moment in all four bands** (entering the L2 memory room with Mira's drawing):
- **Human:** *"She drew us like this every day. Me always bigger than the house."*
- **Patched:** *"Her drawing. I remember the colors. Mostly."*
- **Hollow:** *"A drawing. Three figures. I know it mattered. I can't feel why."*
- **Machine:** *"Image file: drawing_family.png. Emotional weight: unknown. …Keep."*

---

## 8. Memory rooms [LOCKED: room type; PROPOSED content]
| Level | Memory† | Item | What it shows |
|---|---|---|---|
| 1 | The Wedding | Photo | Kade and Lena in the rain, laughing |
| 2 | Mira's Drawing | Crayon drawing | The family under an enormous sun |
| 3 | Lena's Message | Voice message | *"Come home safe. We saved you cake."* |
| 4 | Mira's Birthday | Hologram | Mira blows out 7 candles, with Button beside her |
| 5 | The Night | Warden's recording | The attack, in sound and silhouettes, ending on Zero's line |

Each memory has 4 band variants: different text and a growing level of visual corruption.

---

## 9. Endings [LOCKED conditions, PROPOSED content]
The ending is decided when Zero is defeated, by the number of filled implant slots.

### Humanity (0 slots, the good ending)
Kade stands over Zero's core as a man. The Syndicate's backups burn. Vorn offers one last upgrade "just to be sure",
and Kade refuses. The final panel shows Kade at the family memorial, setting down Button while the music box plays clean.
*"I'm still here. That's how I know I won."*

### Normal (1–5 slots; two flavors, decided in M5)
Kade wins, but some memories are gone where the machines went in. The final panel shows Kade in the rain, half his face
reflecting neon, while the music box skips a note. He keeps walking. Patched (1–2 slots) and Hollow (3–5) get different
closing lines and panel details (Q8).

### Transformation (6 slots, the bad ending)
Zero falls, and the Syndicate's robots kneel to the stronger machine. Kade's system warns that memory is low, so he
deletes the last file, Mira's lullaby, to free space. The final panel shows the new Zero, red-eyed, on a throne of
servers. *"You became what you wanted to destroy."*

Once Q1 is decided, each ending gets a post-credits line that reveals Vorn's true role.

---

## 10. Barks and humor [PROPOSED]
**Robot barks** (short text pops, voice optional):
- *"HUMAN DETECTED. PLEASE REMAIN CALM WHILE WE END YOU."*
- *"Your organs have been flagged for recycling."*
- *"Target is hiding. Deploying grenade-based encouragement."* (Grenadier)
- *"Bzzt! Above you! Literally!"* (Drone)

**Patch:** *"That gun? Found it in a toaster. Well. It* was *a toaster."*

**Weapons:** every gun gets a one-line flavor text ([content.md](content.md) §3).

## 11. Sensitivity and rating
- A child's death is central to the story. It's always implied (aftermath, sound, silhouettes) and never depicted, and no bodies are shown.
- Enemies are robots only: sparks and scrap, no blood.
- The rating target is PEGI 12 / ESRB Teen, to be confirmed with the IARC questionnaire at M6.

## 12. Placeholder names (rename freely)
| Thing | Placeholder |
|---|---|
| Title | Man vs AI (working; alternatives in [open-questions.md](open-questions.md) Q3) |
| Hero / wife / daughter | Kade Rourke / Lena / Mira |
| Mira's toy | Button (a stitched rabbit) |
| Scientist | Dr. Elias Vorn |
| Arms dealer | Patch |
| City / city AI | Halcyon / STEWARD |
| Gang | The Null Syndicate |
| Kade's old unit | 7th Human Line Infantry, the "Meat Line" |
| Bosses | SCRAPJAW, GLITCH, FORGEMOTHER, WARDEN, ZERO |
| Districts | Rustline Slums, Neon Bazaar, The Foundry, Skyline Spires, Syndicate Core |
