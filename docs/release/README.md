# Release material (M6)

Everything the owner needs to take the game from this repository to the Play Store. The code side is done: ads,
purchases, consent, settings, localization, the Android export preset and the performance benchmark. What's left
needs the owner's accounts, devices and decisions. Most of these steps can't be done or checked from the repository.

Work through the documents in this order:

| # | Document | What it covers |
|---|---|---|
| 1 | [android_build.md](android_build.md) | Export templates, SDK, signing keys, the export preset, and checking performance on the test phones |
| 2 | [monetization_setup.md](monetization_setup.md) | The AdMob and Play Billing plugins, ad units, consent, and the 12 cosmetic products |
| 3 | [privacy_policy.md](privacy_policy.md) | A draft privacy policy to publish at a public URL |
| 4 | [data_safety.md](data_safety.md) | Draft answers for the Play Console Data safety form |
| 5 | [content_rating.md](content_rating.md) | Draft answers for the rating questionnaire, target audience, and the other App content declarations |
| 6 | [store_listing.md](store_listing.md) | Draft store texts and the graphics to make |
| 7 | [testing_tracks.md](testing_tracks.md) | Internal → closed → open testing → production, with the checks for each step |

**Decisions still open** ([open-questions.md](../open-questions.md)):
- Q3, the final title;
- Q12, the launch languages;
- the package name (`package/unique_name`), which is permanent once the first build is uploaded.

The drafts are written from the game as it is in the repository. Google's forms and rules change, so check each
answer against the Play Console when you fill it in.
