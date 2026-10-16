# WanderOffline

An offline-first travel companion for people heading somewhere with expensive or
unreliable mobile data. Download a country pack on wifi before you fly, and the
country facts, hand-picked places, local tips, weather averages and a currency
converter keep working in airplane mode.

Built with Flutter, feature-first, with a Clean Architecture data/domain split.

## The problem it solves

Roaming data is expensive and patchy in a lot of destinations. Travellers
currently juggle four or five apps — weather, currency converter, a wiki, maps,
a guidebook — and all of them fail the moment the signal does. WanderOffline
folds those into one pack that is downloaded once and then read from disk.

## How offline-first is actually enforced

The rule the code follows is: **a screen never awaits the network to render
content you already own.**

- **Curated content ships inside the app bundle.** Country facts, the eight
  hand-written places per country, and the local-tips sections are read from
  `assets/content/*.json` and written into Hive at install time. Installing a
  pack therefore needs no network at all — you end up with a usable pack even if
  the download happens on one bar of airport wifi.
- **Only genuinely volatile data is fetched.** Weather and exchange rates go
  stale, so they are the only things that touch the network, and both are
  best-effort: if either call fails, the pack still installs and the UI says
  "no weather yet" rather than showing an error screen.
- **Refresh is opt-in and only refreshes what you own.** The refresh action on a
  pack updates the live forecast and the rate snapshot. The seasonal weather
  average is expensive to rebuild and never meaningfully goes stale, so it is
  computed once and kept.
- **Reading is always local.** `installedPack()` and `installedCountryCodes()`
  read Hive and never touch the network.

## Screens

| Screen | What it does |
|---|---|
| **Explore** | The pack catalogue with download state, a filter for what is on the device, per-pack download progress, and delete/refresh actions. Everything is free. |
| **Pack detail** | Five tabs: *Overview* (country facts and practical notes), *Weather* (seven-day seasonal average plus a live forecast when online), *Currency* (converter with a saved rate snapshot), *Places* (map plus the hand-written entries), *Tips* (money, tipping, scams, transport, etiquette, emergency numbers). |
| **Settings** | Support (optional tip jar), offline storage, dark theme toggle, and data-source attribution. |

### Maps and the offline diagram

The *Places* tab has two map modes:

1. **Street map** — `flutter_map` with OpenStreetMap tiles, cached to disk by
   `cached_network_image`, so everywhere you have already looked keeps working
   offline. Bulk pre-downloading OSM tiles is prohibited by the OSM tile usage
   policy, so opportunistic caching is the shipping-correct trade-off rather
   than a "download this region" button.
2. **Offline diagram** — a tile-free schematic map that projects real landmark
   coordinates with an equirectangular projection over a graticule. No network,
   no cache, nothing to pre-download: it works the instant a pack is installed
   and keeps working forever. This is why "offline map pins" is a real feature
   and not a promise.

## Data sources

Every live source is keyless and free, which is what lets the app ship with no
backend.

| Source | Used for | Notes |
|---|---|---|
| **Open-Meteo** | Seasonal weather averages and the seven-day forecast | Keyless. Averages the same calendar week across three past years of archive data. |
| **Frankfurter** (ECB reference rates) | Exchange-rate snapshot | Keyless. One snapshot is stored per pack so conversions work offline. |
| **OpenStreetMap** | Map tiles | Tiles cached on disk; attribution shown on the map. |

### A note on REST Countries

The original plan specified the REST Countries API for country facts. That is no
longer possible: **v1–v4 were shut down upstream, and v5 requires an account and
an API key**, so it can no longer be called from a keyless client. Country facts
are therefore authored into the pack content files instead, which is also the
better architecture for this app — the facts card is complete the moment a pack
is installed, with no dependency on a third party that can change shape.

`lib/core/utils/app_url.dart` documents this, and all facts live in the `facts`
block of each `assets/content/*.json`.

## Content

The packs are the product, so the content is hand-written rather than dumped from
an API. Eight countries, each with eight places:

| Pack | Places | Cities covered |
|---|---|---|
| Japan | 8 | Tokyo, Kyoto, Osaka, Nara, Kanazawa, Miyajima |
| Italy | 8 | Rome, Vatican City, Florence, Venice, Cinque Terre, Pompeii |
| Thailand | 8 | Bangkok, Chiang Mai, Chiang Rai, Ayutthaya, Sukhothai, Railay |
| Vietnam | 8 | Hanoi, Ha Long, Hue, Hoi An, Ho Chi Minh City, Ninh Binh |
| Portugal | 8 | Lisbon, Sintra, Porto, Coimbra, Évora |
| Morocco | 8 | Marrakesh, Casablanca, Rabat, Ait Benhaddou, Meknes |
| Turkey | 8 | Istanbul, Göreme, Selçuk, Pamukkale, Adıyaman, Mardin |
| Peru | 8 | Cusco, Lima, Arequipa, Chivay, Puno, Machu Picchu |

Each place carries a hand-written *why visit* blurb (opinionated, not a wiki
summary), factual context, the best time to go, entry cost and an insider tip.
Each pack also carries a local-tips section: currency quirks, tipping norms, real
named scams to avoid, transport, etiquette and emergency numbers.

A pack's `latitude`/`longitude` is its primary city, not the country centroid,
because those coordinates are what the weather lookup uses — so the forecast is
for where travellers actually arrive rather than the middle of the country.

Adding a country is one `assets/content/<code>.json` file plus its code in
`CuratedPackDataSource.curatedCountryCodes`. Tests then enforce the quality: eight
places, unique ids, at least three cities, every coordinate inside the country's
bounding box, every tip section populated, and a check that the bounding-box table
and the catalogue cannot drift apart.

## Free, with an optional tip jar

The app is free and complete: every country pack, no ads, nothing locked, no
account, no backend. There is deliberately no paywall, no entitlement model and no
store integration in the codebase.

The only ask is an optional tip, offered from a single card in Settings. It gates
nothing — the app behaves identically whether or not anyone ever taps it.

Set your own page in one place, [`lib/config/support/support_config.dart`](lib/config/support/support_config.dart):

```dart
static const String donationUrl = 'https://ko-fi.com/your-handle';
```

While that URL still contains the placeholder, Settings shows a reminder instead
of a button, so a dead link cannot ship by accident.

Platform fees, for choosing:

| Option | Fee | Notes |
|---|---|---|
| **Ko-fi** | 0% on donations | Best economics, tipper needs no account |
| **Buy Me a Coffee** | 5% | Best-known name |
| **GitHub Sponsors** | 0% | Good if the project is open source |
| **PayPal.me** | ~2.9% | Instant, reads less like a product |

### The iOS caveat

App Review **Guideline 3.1.1** restricts linking out to external payment, and
donation links inside iOS apps have been rejected before. The link is
unproblematic on Android. `support_config.dart` therefore exposes:

```dart
static const bool showDonationLinkOnIos = true;
```

If a reviewer objects, set it to `false`. The Support card is then hidden on iOS
and nothing else changes. The
[Alternative](https://developer.apple.com/app-store/review/guidelines/#payments)
is an in-app-purchase "tip jar" (a consumable product that unlocks nothing),
which is permitted but reintroduces store accounts, store fees and billing code.

## Project structure

```
lib/
├── config/                 # Navigation, support config, tile source, theme
├── core/                   # Reusable widgets, utils, external-link service
├── data/
│   ├── datasources/        # Curated asset, Open-Meteo, Frankfurter, Hive, connectivity
│   ├── models/             # Pack models (hand-written JSON, no codegen)
│   └── repositories/       # Cache-first pack repository, network (Dio)
├── domain/
│   ├── failures/           # Typed failures
│   ├── repositories/       # Interfaces the data layer implements
│   └── usecases/           # Theme persistence
├── features/               # One folder per feature:
│   ├── pack_browser/       #   cubit + state + page + navigator + initial params
│   ├── pack_detail/        #   plus a widgets/ folder per tab
│   ├── settings/           #   includes the optional tip jar
│   ├── splash/
│   └── bottom_nav/         # The tab shell
└── injection_container.dart
assets/content/{jp,it,th}.json
test/                       # 134 tests
```

Conventions: `Bloc/Cubit` for state, `get_it` for DI, `GoRouter` for navigation,
`fpdart` `Either` for fallible calls, `flutter_screenutil` for sizing. No code
generation — models are hand-written and parse defensively, so one bad field
degrades to a default instead of throwing while a screen builds.

## Running it

```bash
flutter pub get
flutter test        # 134 tests
flutter analyze     # clean
flutter run
```

The app opens on the pack catalogue. Download a pack, then turn on airplane mode
and everything except the live forecast and fresh rates keeps working.

## Known limitations / next steps

- **Set your support link before shipping.** `SupportConfig.donationUrl` is still
  the placeholder, so Settings shows a developer reminder rather than a button.
  Also decide `showDonationLinkOnIos` (see the iOS caveat above).
- **The catalogue is eight countries.** The browser, storage and content tests are
  catalogue-size agnostic, so adding a ninth is one content file, one entry in
  `CuratedPackDataSource.curatedCountryCodes`, and its bounding box in the content
  test (which fails loudly if you forget the last one).
- **Pack content updates ship with app releases.** A backend would let content be
  published independently; that would be the first thing worth adding.
- **Deep-link sharing, accounts and community content** are deliberately out of
  scope for v1.
