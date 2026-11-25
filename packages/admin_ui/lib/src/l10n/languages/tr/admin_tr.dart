import 'package:common_locale_data/tr.dart' show CommonLocaleDataTr;
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoLocalizationTr;
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_localizations/flutter_localizations.dart'
    show WidgetsLocalizationTr;
import 'package:material_ui/material_ui.dart' show MaterialLocalizationTr;

import '../../admin_language.dart';
import 'admin_localizations_tr.dart';
import 'date_data.dart';

/// The kit in Turkish: its own strings, Material's, Cupertino's and
/// the widgets', intl's date data, and CLDR's names of languages.
const adminTr = AdminLanguage(
  locale: Locale('tr'),
  strings: AdminLocalizationsTr(),
  material: MaterialLocalizationTr.new,
  cupertino: CupertinoLocalizationTr.new,
  widgets: WidgetsLocalizationTr(),
  dateSymbols: dateSymbols,
  datePatterns: datePatterns,
  names: CommonLocaleDataTr.staticInstance,
);
