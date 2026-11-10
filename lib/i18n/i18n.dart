import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'strings_en.dart';
import 'strings_ko.dart';
import 'strings_ru.dart';

/// The site's four languages. Uzbek is the source text written in the code;
/// the other tables are keyed by that Uzbek text.
enum AppLang {
  uz('UZ', 'languz'),
  ru('RU', 'langru'),
  en('EN', 'langen'),
  kr('KR', 'langkr');

  const AppLang(this.code, this.flag);
  final String code;
  final String flag;

  String get flagAsset => 'assets/flags/$flag.png';
}

/// Current language, persisted across launches (key "locale", like the site).
class I18n extends ChangeNotifier {
  I18n._();
  static final I18n instance = I18n._();

  static const _key = 'locale';
  final _storage = const FlutterSecureStorage();
  AppLang _lang = AppLang.uz;

  AppLang get lang => _lang;

  Future<void> init() async {
    try {
      final saved = await _storage.read(key: _key);
      _lang = AppLang.values
          .firstWhere((l) => l.name == saved, orElse: () => AppLang.uz);
    } catch (_) {/* first launch or no keystore: stay Uzbek */}
  }

  Future<void> set(AppLang lang) async {
    if (lang == _lang) return;
    _lang = lang;
    notifyListeners();
    try {
      await _storage.write(key: _key, value: lang.name);
    } catch (_) {}
  }

  static const _tables = {
    AppLang.ru: stringsRu,
    AppLang.en: stringsEn,
    AppLang.kr: stringsKo,
  };

  /// Uzbek source text -> current language. Unknown text (server data such
  /// as titles and names) comes back unchanged.
  String tr(String uz) {
    final table = _tables[_lang];
    if (table == null) return uz;
    final exact = table[uz];
    if (exact != null) return exact;
    return _templated(uz, table) ?? uz;
  }

  /// "12 bikes", "Showing 1-6 of 20": numbers are swapped for {n} placeholders
  /// so one table entry covers every count.
  static final _number = RegExp(r'\d+');

  String? _templated(String uz, Map<String, String> table) {
    if (!_number.hasMatch(uz)) return null;
    final numbers = _number.allMatches(uz).map((m) => m.group(0)!).toList();
    var i = 0;
    final key = uz.replaceAllMapped(_number, (_) => '{${i++}}');
    final template = table[key];
    if (template == null) return null;
    return template.replaceAllMapped(
        RegExp(r'\{(\d+)\}'), (m) => numbers[int.parse(m.group(1)!)]);
  }
}

/// Puts the language in the widget tree so every [Text] rebuilds when it changes.
class I18nScope extends InheritedNotifier<I18n> {
  I18nScope({super.key, required super.child}) : super(notifier: I18n.instance);

  static void watch(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<I18nScope>();
}

extension Tr on String {
  /// For strings that are not shown through [Text] (hints, tooltips, dialogs).
  String get tr => I18n.instance.tr(this);
}
