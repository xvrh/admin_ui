import 'package:common_locale_data/de.dart' show CommonLocaleDataDe;
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoLocalizationDe;
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_localizations/flutter_localizations.dart'
    show WidgetsLocalizationDe;
import 'package:material_ui/material_ui.dart' show MaterialLocalizationDe;

import '../../admin_language.dart';
import 'admin_localizations_de.dart';
import 'date_data.dart';

/// The kit in German: its own strings, Material's, Cupertino's and
/// the widgets', intl's date data, and CLDR's names of languages.
const adminDe = AdminLanguage(
  locale: Locale('de'),
  strings: AdminLocalizationsDe(),
  material: MaterialLocalizationDe.new,
  cupertino: CupertinoLocalizationDe.new,
  widgets: WidgetsLocalizationDe(),
  dateSymbols: dateSymbols,
  datePatterns: datePatterns,
  names: CommonLocaleDataDe.staticInstance,
);
