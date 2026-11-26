import 'package:common_locale_data/fr.dart' show CommonLocaleDataFr;
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoLocalizationFr;
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_localizations/flutter_localizations.dart'
    show WidgetsLocalizationFr;
import 'package:material_ui/material_ui.dart' show MaterialLocalizationFr;

import '../../admin_language.dart';
import 'admin_localizations_fr.dart';
import 'date_data.dart';

/// The kit in French: its own strings, Material's, Cupertino's and
/// the widgets', intl's date data, and CLDR's names of languages.
const adminFr = AdminLanguage(
  locale: Locale('fr'),
  strings: AdminLocalizationsFr(),
  material: MaterialLocalizationFr.new,
  cupertino: CupertinoLocalizationFr.new,
  widgets: WidgetsLocalizationFr(),
  dateSymbols: dateSymbols,
  datePatterns: datePatterns,
  names: CommonLocaleDataFr.staticInstance,
);
