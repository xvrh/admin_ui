import 'package:common_locale_data/en.dart' show CommonLocaleDataEn;
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoLocalizationEn;
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_localizations/flutter_localizations.dart'
    show WidgetsLocalizationEn;
import 'package:material_ui/material_ui.dart' show MaterialLocalizationEn;

import '../../admin_language.dart';
import '../../admin_ui_localizations.dart';
import 'date_data.dart';

/// The kit in English: its own strings, Material's, Cupertino's and
/// the widgets', intl's date data, and CLDR's names of languages.
const adminEn = AdminLanguage(
  locale: Locale('en'),
  strings: AdminLocalizationsEn(),
  material: MaterialLocalizationEn.new,
  cupertino: CupertinoLocalizationEn.new,
  widgets: WidgetsLocalizationEn(),
  dateSymbols: dateSymbols,
  datePatterns: datePatterns,
  names: CommonLocaleDataEn.staticInstance,
);
