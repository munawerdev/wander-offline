# WanderOffline — Project Plan

**Offline-first travel companion app for Android & iOS**
Built in Flutter | Portfolio piece + side-income product

---

## 1. Project Description

WanderOffline is a travel companion app for people heading to areas with poor or expensive mobile data. Before a trip, users download a complete "country/city pack" — country facts, currency info, weather trends, cultural landmarks, and basic maps — so the app works fully offline once they land.

**Problem it solves:** Roaming data is expensive or unreliable in many destinations. Travelers currently juggle 4–5 apps (weather, currency converter, Wikipedia, maps, guidebook) that all fail without a signal. WanderOffline consolidates the essentials into one pack, downloaded once on Wi-Fi.

**Who it's for:** Budget/backpacker travelers, first-time international travelers, and people visiting countries with patchy connectivity — a global audience, not limited to Pakistan.

---

## 2. Monetization Model

| Tier | What's included | Price |
|---|---|---|
| Free | 1 country pack of user's choice, ads on non-critical screens | Free |
| Pack unlock | Additional country/region packs, one-time purchase | $1.99–$3.99 each |
| Unlimited | All current + future packs, no ads | $14.99/year or $29.99 lifetime |

- Use **RevenueCat** to manage IAP + subscriptions across both App Store and Play Store from one SDK — avoids building your own receipt-validation server.
- Use **rewarded ads** (not banners) for one-off unlocks ("watch an ad to preview a pack") — better UX and CPM than banners.
- No backend server needed for v1 — all data comes from free public APIs at build/update time and is cached locally.

---

## 3. Tech Stack

| Layer | Choice | Why |
|---|---|---|
| State management | **Riverpod** or **Bloc/Cubit** | Predictable state for async downloads/caching |
| Local storage | **Hive** | Lightweight, fast, no native build complexity (skip Isar for v1) |
| Networking | **Dio** | Better interceptor/retry support than plain http |
| Navigation | **GoRouter** | Simple, supports deep links for phase 2 sharing |
| IAP/Subscriptions | **RevenueCat + in_app_purchase** | Cross-platform billing without custom backend |
| Maps | **flutter_map** (OpenStreetMap tiles) | Free — avoids Google Maps API billing for a bootstrapped app |
| Ads | **google_mobile_ads** | Rewarded ads for pack previews |

### APIs used (all free tiers)
- **REST Countries API** — country facts, currency, flags, languages
- **Open-Meteo API** — historical weather averages / seasonal forecast trends
- **Art Institute of Chicago API** (or similar open museum APIs) — cultural landmark highlights, seed content
- **OpenStreetMap / Nominatim** — map tiles and landmark coordinates (free, no key needed)

---

## 4. Architecture (Clean Architecture, offline-first)

```
lib/
├── core/
│   ├── network/         (Dio client, connectivity checker)
│   ├── storage/         (Hive boxes, cache manager)
│   └── error/           (failure/exception handling)
├── features/
│   ├── country_pack/
│   │   ├── data/        (API models, repository impl, local datasource)
│   │   ├── domain/      (entities, repository interface, use cases)
│   │   └── presentation/(bloc/cubit, screens, widgets)
│   ├── weather/
│   ├── landmarks/
│   └── billing/         (RevenueCat integration, paywall UI)
└── main.dart
```

**Offline-first rule:** every feature reads from Hive first; a background sync job refreshes from the API only when online and only for packs the user already owns. The UI never blocks on a network call for previously downloaded content.

---

## 5. MVP Scope (what ships in v1 — resist adding more)

- Browse & download 1 free country pack
- View: country facts, currency + live-updated conversion (cached last rate), 7-day seasonal weather pattern, 5–10 hand-picked landmarks with descriptions and offline map pins
- Paywall to unlock additional packs (IAP)
- Fully functional in airplane mode once a pack is downloaded

**Explicitly out of scope for v1:** deep-link sharing, user accounts, community content, live chat, real-time flight data. Add these only after the MVP validates.

---

## 6. Timeline (solo dev, part-time alongside job search)

| Week | Focus |
|---|---|
| 1 | Project scaffold, Clean Architecture folders, Hive setup, Dio client, pick 3 launch countries |
| 2 | REST Countries + Open-Meteo integration, data models, repository layer, caching logic |
| 3 | Landmarks feature — source & write content for 3 countries, flutter_map integration, offline pin rendering |
| 4 | UI polish — pack browser, country detail screens, download progress states, empty/offline states |
| 5 | RevenueCat setup, paywall screen, rewarded ads integration, test purchases (sandbox) |
| 6 | QA pass on real devices, airplane-mode testing, App Store/Play Store listing assets, submit for review |

Add 1–2 buffer weeks for store review cycles and rejection fixes (common on first submission).

---

## 7. Content Strategy (the part APIs can't do for you)

Raw API data alone will look like a tutorial project. Differentiate by hand-writing:
- 2–3 sentence "why visit" blurbs per landmark (not just API descriptions)
- A short "local tips" section per country pack (currency quirks, tipping norms, common scams to avoid)

This is manual work but it's what separates a sellable product from a wrapper app — budget real time for it in Week 3.

---

## 8. Launch & Distribution

- Launch with 3 well-polished countries rather than 20 shallow ones — quality signals in reviews matter more than catalog size early on
- Post in relevant travel subreddits / backpacker Facebook groups (with disclosure, not spam) for first real users
- Ask for reviews in-app after a successful offline session (not on first launch)
- Track which countries get downloaded most — expand the catalog based on real demand, not guesses

---

## 9. Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Store rejection for "insufficient functionality" | Ensure offline mode is genuinely robust before submitting, not just cached API dumps |
| Low organic discovery | Budget for ASO (App Store Optimization) — keyword-rich title/description, not just marketing |
| API rate limits / deprecation | Cache aggressively; data refreshes are optional, not required for app function |
| Content creation bottleneck | Start with 3 countries, not 20 — expand only after validating demand |

---

## 10. Success Metrics (first 90 days)

- 500+ downloads (organic)
- 3%+ conversion to paid pack/unlimited
- 4.0+ star average rating
- <5% crash rate on offline usage sessions

