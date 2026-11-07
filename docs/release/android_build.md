# Android build (owner steps)

The repository has an Android export preset (`export_presets.cfg`, preset **Android**). Signing passwords never go
in it: Godot keeps keystore paths and passwords in `.godot/export_credentials.cfg`, which is gitignored with the
rest of `.godot/`.

## What the preset sets
| Option | Value | Why |
|---|---|---|
| Gradle build | on | The AdMob and Play Billing plugins need it ([monetization_setup.md](monetization_setup.md)) |
| Export format | AAB | Google Play only accepts app bundles for new apps |
| Architectures | arm64-v8a only | Play requires 64-bit; armeabi-v7a would only add old 32-bit phones |
| Target / min SDK | Godot 4.7 defaults (target 36, min 24) | Play requires API 36 for new apps and updates since 31 August 2026 |
| Version name | empty, so Godot uses Project Settings → Application → Config → Version (`0.6.0`) | One version number, shown on the title screen too |
| Version code | 1 | **Raise it for every upload**; Play rejects a code it has already seen |
| Package name | `com.example.manvsai` | **Placeholder.** Play rejects `com.example`. Pick your own (for example `com.yourstudio.manvsai`) before the first upload; it can never change after that |
| Immersive mode | on | Hides the navigation bar and cuts accidental system gestures ([technical.md](../technical.md) §11) |
| Permissions | Internet, Access network state, Vibrate | Ads and billing need the network; haptics need Vibrate. The plugins add their own (`AD_ID`, `BILLING`) |
| Export path | `build/android/man-vs-ai.aab` | `build/` is gitignored |
| Excluded | `tools/*` | Tests and the benchmark stay out of the game |

`rendering/textures/vram_compression/import_etc2_astc` is already on in the project settings, which Android export
requires.

## One-time setup
1. In the Godot editor: Editor → Manage Export Templates → download the **4.7** templates.
2. Install the Android SDK (command-line tools, platform-tools, build-tools) and a JDK 17. Set both paths in Editor
   Settings → Export → Android.
3. Project → Install Android Build Template. This creates `android/`, which is gitignored and stays local.
4. Install and enable the plugins ([monetization_setup.md](monetization_setup.md) §1).

## Signing keys
Google Play signs the app for players (**Play App Signing**, on by default for new apps). You sign uploads with your
own **upload key**:
```bash
keytool -genkeypair -v -keystore man-vs-ai-upload.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
```
- Keep the `.jks` file and its passwords outside the repository: a password manager, plus an offline backup. `*.jks`
  and `*.keystore` are gitignored anyway.
- In Project → Export → Android, enter the release keystore path, alias and passwords. Godot saves them to
  `.godot/export_credentials.cfg`, not to the preset.
- For one-click debug runs, Godot creates a debug keystore by itself.

## Exporting
- Release bundle: Project → Export → Android → Export Project, or from a terminal:
  ```bash
  godot --headless --path . --export-release "Android" build/android/man-vs-ai.aab
  ```
- Debug build on a USB-connected phone: the one-click deploy button (Android icon) in the editor's top bar.

Before a store upload:
- [ ] `data/monetization/monetization.tres`: real rewarded unit ID, `test_ads` off, `force_stub` off.
- [ ] Version code raised; version name (Project Settings) updated if it's a new version.
- [ ] Package name is your own, not `com.example`.
- [ ] All the checks in [CLAUDE.md](../../CLAUDE.md) pass, and the benchmark (below) shows no alarm.

## Performance on the test phones
The headless benchmark (`tools/benchmark.gd`, [technical.md](../technical.md) §13) measures game logic and physics
only. It can't see rendering or a phone's CPU, so check the budget on the devices themselves.

**Low-end phone** (about 3 GB RAM, around 2020):
1. Deploy a debug build and start a run.
2. Enter a combat room and tap **DBG** (top right) to open the debug panel, which shows FPS and enemy bullets.
3. Tap **300-bullet storm** several times while robots are alive. FPS must stay **at or above 30**.
4. Try the 30 fps cap (Settings → Frame rate), then play 10 minutes to see whether the phone heats up and slows down.

**Mid-range phone:** the same steps. FPS should stay near **60**.

**For detail:** run with the editor's remote debugger attached (Debug → Deploy with Remote Debug). The Debugger's
Monitors tab shows frame, process and physics time, draw calls and object counts. The Profiler shows which scripts
cost the most.

**Also check:**
- room transitions (no visible hitch);
- memory under 500 MB (Monitors → Memory);
- the AAB size in Play Console → App bundle explorer (target 150 MB or less, technical §11);
- that the App bundle explorer shows no 16 KB page-size warning. Google requires 16 KB page support for native code.

Write down the results (device, FPS during the storm, notes) in [roadmap.md](../roadmap.md) under M6. If the
low-end phone can't hold 30 fps, see technical §6.2 for the next steps, in order.
