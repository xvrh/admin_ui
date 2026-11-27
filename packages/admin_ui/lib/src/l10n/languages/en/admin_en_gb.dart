import 'package:common_locale_data/en.dart' show CommonLocaleDataEn;
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoLocalizationEnGb;
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_localizations/flutter_localizations.dart'
    show WidgetsLocalizationEnGb;
import 'package:material_ui/material_ui.dart' show MaterialLocalizationEnGb;

import '../../admin_language.dart';
import '../../admin_ui_localizations.dart';
import 'date_data_en_gb.dart';

/// The kit in British English: its English strings, with Material's,
/// Cupertino's and the widgets' for the United Kingdom and intl's en_GB
/// date data, so dates read day first (05/01/2026) on a 24-hour clock.
const adminEnGb = AdminLanguage(
  locale: Locale('en', 'GB'),
  strings: AdminLocalizationsEn(),
  material: MaterialLocalizationEnGb.new,
  cupertino: CupertinoLocalizationEnGb.new,
  widgets: WidgetsLocalizationEnGb(),
  dateSymbols: dateSymbols,
  datePatterns: datePatterns,
  names: CommonLocaleDataEn.staticInstance,
);
