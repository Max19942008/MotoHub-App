# MotoHub App

Android app for **MotoHub** — a marketplace in Uzbekistan for motorcycles, spare parts and accessories. Built with Flutter, UI in Uzbek.

It talks to the same backend as the website ([MotoHub API](https://github.com/Max19942008/MotoHub), [web frontend](https://github.com/Max19942008/Ignition)) over GraphQL.

## Features

- **Motorcycles** — search, filters (brand, type, condition, region, price), sorting, infinite scroll, pull to refresh
- **Spare parts & accessories** — separate tabs with their own filters
- **Detail pages** — photo gallery, specs, description, seller card, one-tap call
- **Login / sign up** with the same account as the website; tokens kept in the Android keystore and refreshed silently
- **AI assistant** — ask in Uzbek, Russian or English; answers come from MotoHub listings (RAG on the backend) with tappable listing cards
- Friendly wait message while the free Render backend wakes up (~50 s)
- Account deletion inside the app (Google Play requirement)
- Light and dark theme

## Run

```bash
flutter pub get
flutter run                     # uses the deployed backend
flutter run --dart-define=API_URL=http://10.0.2.2:3007   # local backend from the emulator (debug builds allow http)
```

Build for Google Play:

```bash
flutter build appbundle --release   # build/app/outputs/bundle/release/app-release.aab
```

Release builds are signed with the upload key from `android/key.properties` (not in git):

```properties
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=C:/path/to/motohub-upload.jks
```

Without that file the release build falls back to the debug key (fine for `flutter run --release`, rejected by Play).

Play listing assets are in `store/` (512 px icon, 1024×500 feature graphic). Launcher icons are generated from `assets/icon/` with `dart run flutter_launcher_icons`.

- Package name: `uz.motohub.app`
- Privacy policy: https://motopresto.online/privacy
- Account deletion: in the app (Profile → Hisobni o'chirish) and at https://motopresto.online/account/delete

## Structure

```
lib/
  api/        GraphQL client + queries (repository.dart)
  models/     Motorbike, Part, Seller
  screens/    lists and detail pages
  widgets/    grid with paging, filter sheet, cards, detail layout
  utils/      Uzbek labels for enums, price/date formatting
```
