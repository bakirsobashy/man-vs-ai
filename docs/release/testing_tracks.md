# Testing tracks and launch checklist

Play Console tracks run **internal → closed → open (optional) → production**. Each step below lists what to do and
what to check before moving on. Google changes these rules; the Play Console help is the source of truth.

## 0. Before the first upload
- [ ] Play Console developer account. Personal or organization: an organization needs a D-U-N-S number but skips the
      closed-testing rule in §2.
- [ ] Identity verification done.
- [ ] Final package name chosen and set in the export preset ([android_build.md](android_build.md)). It's
      permanent after the first upload.
- [ ] App created in Play Console (game, free).
- [ ] The 12 cosmetic products created as one-time products with the exact IDs from `data/cosmetics/catalog.tres`
      ([monetization_setup.md](monetization_setup.md) §3), and set to Active.
- [ ] License testers added (Settings → License testing) so test purchases are free.
- [ ] AdMob app and rewarded unit created; your phones registered as AdMob test devices.
- [ ] Privacy policy published ([privacy_policy.md](privacy_policy.md)).

## 1. Internal testing (up to 100 testers, no review wait)
Upload an AAB with **test ads on** (`test_ads` in `monetization.tres`). Then check:
- [ ] It installs from the Play link on the low-end and mid-range phones.
- [ ] Consent:
  - the UMP form appears with a debug geography of EEA;
  - declining stops all ad requests;
  - Settings → Privacy options appears and works.
- [ ] Rewarded ads:
  - Second Chance revives the hero;
  - Salvage pays out once;
  - an ad closed early grants nothing.
- [ ] Purchases:
  - a license tester can buy a cosmetic;
  - it's equipped;
  - it comes back after reinstalling (Restore purchases);
  - a cancelled purchase grants nothing.
- [ ] Performance on both phones ([android_build.md](android_build.md), "Performance on the test phones").
- [ ] A full run: tutorial → five levels → ending → credits → lab, with saves resumed after killing the app.
- [ ] Pre-launch report (Release → Testing → Pre-launch report): no crashes; review the accessibility and
      security warnings.

## 2. Closed testing
- [ ] Switch to the **real** ad unit and turn `test_ads` off only when testers aren't your own test devices.
      Never click your own live ads.
- [ ] Store listing, content rating, data safety, target audience and ads declaration filled in
      ([store_listing.md](store_listing.md), [content_rating.md](content_rating.md),
      [data_safety.md](data_safety.md)).
- [ ] **Personal accounts created after 13 November 2023:** run a closed test with **at least 12 testers** who stay
      opted in **for 14 days in a row**. Then apply for production access (Dashboard → Apply for production). Google
      reviews the application, usually within about a week. Invited testers who never opt in don't count.
- [ ] Collect feedback on controls (swipe sensitivity, the double-tap window), difficulty and battery use.

## 3. Open testing (optional)
A public opt-in listing, useful for a larger balance and performance sample before launch.

## 4. Production
- [ ] Target API 36 (Godot 4.7's default). Google Play requires it for new apps and updates since 31 August 2026,
      and raises the level every year.
- [ ] Version code raised; version name updated.
- [ ] Staged rollout: start at 10–20%, then widen if Android vitals stay healthy. Google's bad-behavior thresholds
      are a user-perceived crash rate of 1.09% and an ANR rate of 0.47%.
- [ ] Watch reviews and vitals for the first week; keep the upload key and its passwords safe and backed up.

## After launch
- Every update: raise the version code and run all the checks in [CLAUDE.md](../../CLAUDE.md) and the benchmark.
  Repeat the internal-testing checks that the change touches.
- New languages: add a column to `localization/strings.csv` ([technical.md](../technical.md) §10), then translate the
  store listing.
