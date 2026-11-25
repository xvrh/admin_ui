import 'package:common_locale_data/pt.dart' show CommonLocaleDataPt;
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoLocalizationPt;
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_localizations/flutter_localizations.dart'
    show WidgetsLocalizationPt;
import 'package:material_ui/material_ui.dart' show MaterialLocalizationPt;

import '../../admin_language.dart';
import 'admin_localizations_pt.dart';
import 'date_data.dart';

/// The kit in Brazilian Portuguese: its own strings, Material's, Cupertino's and
/// the widgets', intl's date data, and CLDR's names of languages.
const adminPt = AdminLanguage(
  locale: Locale('pt'),
  strings: AdminLocalizationsPt(),
  material: MaterialLocalizationPt.new,
  cupertino: CupertinoLocalizationPt.new,
  widgets: WidgetsLocalizationPt(),
  dateSymbols: dateSymbols,
  datePatterns: datePatterns,
  names: CommonLocaleDataPt.staticInstance,
);
