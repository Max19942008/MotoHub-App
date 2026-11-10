# App translations

The app's text is written in Uzbek; `lib/i18n/strings_{ru,en,ko}.dart` map it to
the other languages and `lib/i18n/text.dart` translates every `Text` at build time.

To refresh after changing UI text:

    python tool/i18n/collect_strings.py   # scans lib/, pre-fills from ../ignition/public/locales
    # add missing ones to tool/i18n/tr_manual.py (numbers become {0}, {1}...)
    python tool/i18n/gen_tables.py        # rewrites lib/i18n/strings_*.dart
