import 'package:common_locale_data/nl.dart' show CommonLocaleDataNl;
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoLocalizationNl;
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_localizations/flutter_localizations.dart'
    show WidgetsLocalizationNl;
import 'package:material_ui/material_ui.dart' show MaterialLocalizationNl;

import '../../admin_language.dart';
import 'admin_localizations_nl.dart';
import 'date_data.dart';

/// The kit in Dutch: its own strings, Material's, Cupertino's and
/// the widgets', intl's date data, and CLDR's names of languages.
const adminNl = AdminLanguage(
  locale: Locale('nl'),
  strings: AdminLocalizationsNl(),
  material: MaterialLocalizationNl.new,
  cupertino: CupertinoLocalizationNl.new,
  widgets: WidgetsLocalizationNl(),
  dateSymbols: dateSymbols,
  datePatterns: datePatterns,
  names: CommonLocaleDataNl.staticInstance,
);
