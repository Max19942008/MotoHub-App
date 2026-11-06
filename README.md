# MotoHub App

Android app for **MotoHub** — a marketplace in Uzbekistan for motorcycles, spare parts and accessories. Built with Flutter, UI in Uzbek.

It talks to the same backend as the website ([MotoHub API](https://github.com/Max19942008/MotoHub), [web frontend](https://github.com/Max19942008/Ignition)) over GraphQL.

## Features (v1)

- **Motorcycles** — search, filters (brand, type, condition, region, price), sorting, infinite scroll, pull to refresh
- **Spare parts & accessories** — separate tabs with their own filters
- **Detail pages** — photo gallery, specs, description, seller card, one-tap call
- Friendly wait message while the free Render backend wakes up (~50 s)
- Light and dark theme

## Run

```bash
flutter pub get
flutter run                     # uses the deployed backend
flutter run --dart-define=API_URL=http://192.168.1.10:3007   # a local backend
```

Build an APK:

```bash
flutter build apk --release     # build/app/outputs/flutter-apk/app-release.apk
```

## Structure

```
lib/
  api/        GraphQL client + queries (repository.dart)
  models/     Motorbike, Part, Seller
  screens/    lists and detail pages
  widgets/    grid with paging, filter sheet, cards, detail layout
  utils/      Uzbek labels for enums, price/date formatting
```
