import 'package:common_locale_data/pl.dart' show CommonLocaleDataPl;
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoLocalizationPl;
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_localizations/flutter_localizations.dart'
    show WidgetsLocalizationPl;
import 'package:material_ui/material_ui.dart' show MaterialLocalizationPl;

import '../../admin_language.dart';
import 'admin_localizations_pl.dart';
import 'date_data.dart';

/// The kit in Polish: its own strings, Material's, Cupertino's and
/// the widgets', intl's date data, and CLDR's names of languages.
const adminPl = AdminLanguage(
  locale: Locale('pl'),
  strings: AdminLocalizationsPl(),
  material: MaterialLocalizationPl.new,
  cupertino: CupertinoLocalizationPl.new,
  widgets: WidgetsLocalizationPl(),
  dateSymbols: dateSymbols,
  datePatterns: datePatterns,
  names: CommonLocaleDataPl.staticInstance,
);
