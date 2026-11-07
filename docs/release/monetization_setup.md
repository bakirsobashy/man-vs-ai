# Monetization setup (owner steps)

The game talks to ads and the store only through the `Monetization` autoload (`src/autoload/monetization.tscn`,
[technical.md](../technical.md) §12). On the desktop, in the editor and in tests it uses the **stub**, which grants
everything at once. On Android it switches to the real bridges when both plugins are installed:

| Bridge | Plugin | Talks to |
|---|---|---|
| `src/monetization/android_ads.gd` | [Poing Studios AdMob plugin](https://github.com/poingstudios/godot-admob-plugin) (Godot 4.5+) | `PoingGodotAdMob`, `PoingGodotAdMobRewardedAd`, `PoingGodotAdMobConsentInformation`, `PoingGodotAdMobUserMessagingPlatform` |
| `src/monetization/android_billing.gd` | [Godot Google Play Billing](https://github.com/godotengine/godot-google-play-billing) 2.x (Godot 4.2+) | `GodotGooglePlayBilling` |

The bridges call the plugins' Android singletons directly, so the project compiles and runs without the addons.
They were written against the plugins' source and docs and **haven't run on a device yet**. Test them on a real
phone before release.

## 1. Install the plugins
1. In the editor's AssetLib, install **AdMob** by Poing Studios and **Godot Google Play Billing**, then enable both
   under Project Settings → Plugins.
2. Follow the AdMob plugin's Android platform guide. It downloads the native libraries and asks for your **AdMob App
   ID** (`ca-app-pub-…~…`), which goes into the Android manifest.
3. In Project → Export → Android, turn on **Use Gradle Build** (both plugins need it).

## 2. Ads (AdMob)
1. In the AdMob console, create the app and one **Rewarded** ad unit. One unit serves both placements:
   `second_chance` and `salvage`.
2. Put the unit ID in `data/monetization/monetization.tres` → `rewarded_ad_unit_android`. Until then it holds
   Google's public test unit (`ca-app-pub-3940256099942544/5224354917`).
3. Keep `test_ads` on while developing. Add your phone as a test device in AdMob so real ads are never clicked in
   testing.
4. Consent: the title screen runs the UMP flow once per session (`Monetization.gather_consent()`). Set up a GDPR
   message in AdMob → Privacy & messaging, or the form won't appear in the EEA and UK. No ad is requested until UMP
   says ads may be requested. The settings screen shows **Privacy options** where UMP requires it.

## 3. Cosmetic purchases (Play Billing)
1. In the Play Console, create a **one-time product** for each paid cosmetic in `data/cosmetics/catalog.tres`, with
   the same product ID: `outfit_night_runner`, `outfit_rain_coat`, `outfit_old_uniform`, `skin_carbon`,
   `skin_brass`, `skin_neon`, `decor_drawings`, `decor_plant`, `decor_neon_sign`, `emp_red_alert`, `emp_static`
   and `emp_violet`. The catalog fills `Monetization`'s product list at start.
   The shop shows each item's placeholder `price_label`. Showing Play's localized price needs the bridge to read
   `query_product_details_response` (not done yet).
2. Purchases are acknowledged on the client, which is enough for cosmetics (no server). Pending purchases are only
   granted once they're paid; **Restore purchases** re-reads them.
3. Billing only works in builds uploaded to a Play testing track. Add license testers in the Play Console to buy
   without being charged.

## 4. Check on a device
- [ ] The consent form appears on a fresh install in the EEA (use a VPN or UMP debug geography).
- [ ] Dying offers Second Chance, the test ad plays, and the hero gets back up with 1 heart and an EMP.
- [ ] Second Chance isn't offered against ZERO, or twice in one run.
- [ ] The run summary offers Salvage (+25% Crypto) once.
- [ ] Buying a cosmetic in the lab grants it; reinstalling and tapping Restore brings it back; a refund removes it
      on the next start.
- [ ] Turning off the network: the ad buttons fail gracefully and the game goes on.
