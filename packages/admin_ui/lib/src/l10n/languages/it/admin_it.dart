import 'package:common_locale_data/it.dart' show CommonLocaleDataIt;
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoLocalizationIt;
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_localizations/flutter_localizations.dart'
    show WidgetsLocalizationIt;
import 'package:material_ui/material_ui.dart' show MaterialLocalizationIt;

import '../../admin_language.dart';
import 'admin_localizations_it.dart';
import 'date_data.dart';

/// The kit in Italian: its own strings, Material's, Cupertino's and
/// the widgets', intl's date data, and CLDR's names of languages.
const adminIt = AdminLanguage(
  locale: Locale('it'),
  strings: AdminLocalizationsIt(),
  material: MaterialLocalizationIt.new,
  cupertino: CupertinoLocalizationIt.new,
  widgets: WidgetsLocalizationIt(),
  dateSymbols: dateSymbols,
  datePatterns: datePatterns,
  names: CommonLocaleDataIt.staticInstance,
);
