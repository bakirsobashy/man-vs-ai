# Data safety form (draft answers)

Play Console → App content → **Data safety**. The answers describe the game as it is in the repository:
- local saves only;
- no accounts, analytics or crash-reporting SDK;
- the Google Mobile Ads SDK with the UMP consent SDK (through the Poing Studios AdMob plugin);
- Google Play Billing (through the Godot Google Play Billing plugin).

You're responsible for the final answers. Before submitting, compare them with Google's own disclosure pages:
- [Google Mobile Ads SDK: Play data disclosure](https://developers.google.com/admob/android/privacy/play-data-disclosure)
- [UMP SDK: Play data disclosure](https://developers.google.com/admob/ump/android/play-data-disclosure)

Those pages are versioned with the SDK, so read the one for the SDK version the plugin ships.

## What the game itself does
| Data | Where it goes |
|---|---|
| Save slots and runs (`slot_N.json`, `run_N.json`) | Stays on the device (`user://`) |
| Settings (`settings.cfg`) | Stays on the device |
| Owned cosmetics (`purchases.cfg`) | Stays on the device; Google Play holds the real record |

Data that never leaves the device doesn't count as "collected" on this form.

## Data collection and security
| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **Yes**, through the Google Mobile Ads SDK |
| Is all of the user data collected by your app encrypted in transit? | **Yes** (the SDKs use HTTPS) |
| Do you provide a way for users to request that their data is deleted? | Owner's call. The game holds no server-side data; ad data sits with Google. Many ad-only games answer **No** and explain in the privacy policy that users can reset their advertising ID |

## Data types (from the Google Mobile Ads SDK)
| Category → type | Collected | Shared | Processed ephemerally | Required or optional | Purposes |
|---|---|---|---|---|---|
| Location → Approximate location (from the IP address) | Yes | Check Google's page | No | Required | Advertising or marketing, Analytics, Fraud prevention, security and compliance |
| App activity → App interactions (launches, taps, ad views) | Yes | Check Google's page | No | Required | Advertising or marketing, Analytics, Fraud prevention, security and compliance |
| App info and performance → Diagnostics (and crash logs, if Google's page lists them) | Yes | Check Google's page | No | Required | Analytics, Fraud prevention, security and compliance |
| Device or other IDs → Device or other IDs (advertising ID, app set ID) | Yes | Check Google's page | No | Required | Advertising or marketing, Analytics, Fraud prevention, security and compliance |

**Shared:** Google's disclosure page says whether its SDK's transfers count as "sharing" for this form. Follow the
page for the SDK version you ship.

**Not collected:** personal info (name, email, user IDs), financial info, health, messages, photos and videos,
audio, files, calendar, contacts, web browsing, and precise location.

**Purchases:** Google Play handles payment. The game gets only the IDs of owned products and keeps them on the
device. Check Google's current guidance on whether Play Billing data needs to be declared; normally it doesn't,
because Google Play processes it.

## Related declarations
- **Advertising ID** (App content → Advertising ID): **Yes**, used for **Advertising or marketing** and **Analytics**.
  The AdMob SDK adds the `AD_ID` permission.
- **Ads** (App content → Ads): **Yes, my app contains ads** (rewarded ads only, always opt-in).
