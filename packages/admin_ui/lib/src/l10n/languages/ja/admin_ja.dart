import 'package:common_locale_data/ja.dart' show CommonLocaleDataJa;
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoLocalizationJa;
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_localizations/flutter_localizations.dart'
    show WidgetsLocalizationJa;
import 'package:material_ui/material_ui.dart' show MaterialLocalizationJa;

import '../../admin_language.dart';
import 'admin_localizations_ja.dart';
import 'date_data.dart';

/// The kit in Japanese: its own strings, Material's, Cupertino's and
/// the widgets', intl's date data, and CLDR's names of languages.
const adminJa = AdminLanguage(
  locale: Locale('ja'),
  strings: AdminLocalizationsJa(),
  material: MaterialLocalizationJa.new,
  cupertino: CupertinoLocalizationJa.new,
  widgets: WidgetsLocalizationJa(),
  dateSymbols: dateSymbols,
  datePatterns: datePatterns,
  names: CommonLocaleDataJa.staticInstance,
);
