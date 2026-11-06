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
- Light and dark theme

## Run

```bash
flutter pub get
flutter run                     # uses the deployed backend
flutter run --dart-define=API_URL=http://10.0.2.2:3007   # local backend from the emulator (debug builds allow http)
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
