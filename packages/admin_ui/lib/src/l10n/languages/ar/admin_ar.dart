import 'package:common_locale_data/ar.dart' show CommonLocaleDataAr;
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoLocalizationAr;
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_localizations/flutter_localizations.dart'
    show WidgetsLocalizationAr;
import 'package:material_ui/material_ui.dart' show MaterialLocalizationAr;

import '../../admin_language.dart';
import 'admin_localizations_ar.dart';
import 'date_data.dart';

/// The kit in Arabic: its own strings, Material's, Cupertino's and
/// the widgets', intl's date data, and CLDR's names of languages.
const adminAr = AdminLanguage(
  locale: Locale('ar'),
  strings: AdminLocalizationsAr(),
  material: MaterialLocalizationAr.new,
  cupertino: CupertinoLocalizationAr.new,
  widgets: WidgetsLocalizationAr(),
  dateSymbols: dateSymbols,
  datePatterns: datePatterns,
  names: CommonLocaleDataAr.staticInstance,
);
