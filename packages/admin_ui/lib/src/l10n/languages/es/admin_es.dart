import 'package:common_locale_data/es.dart' show CommonLocaleDataEs;
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoLocalizationEs;
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_localizations/flutter_localizations.dart'
    show WidgetsLocalizationEs;
import 'package:material_ui/material_ui.dart' show MaterialLocalizationEs;

import '../../admin_language.dart';
import 'admin_localizations_es.dart';
import 'date_data.dart';

/// The kit in Spanish: its own strings, Material's, Cupertino's and
/// the widgets', intl's date data, and CLDR's names of languages.
const adminEs = AdminLanguage(
  locale: Locale('es'),
  strings: AdminLocalizationsEs(),
  material: MaterialLocalizationEs.new,
  cupertino: CupertinoLocalizationEs.new,
  widgets: WidgetsLocalizationEs(),
  dateSymbols: dateSymbols,
  datePatterns: datePatterns,
  names: CommonLocaleDataEs.staticInstance,
);
