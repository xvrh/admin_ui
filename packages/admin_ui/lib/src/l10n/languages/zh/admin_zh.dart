import 'package:common_locale_data/zh.dart' show CommonLocaleDataZh;
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoLocalizationZh;
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_localizations/flutter_localizations.dart'
    show WidgetsLocalizationZh;
import 'package:material_ui/material_ui.dart' show MaterialLocalizationZh;

import '../../admin_language.dart';
import 'admin_localizations_zh.dart';
import 'date_data.dart';

/// The kit in Simplified Chinese: its own strings, Material's, Cupertino's and
/// the widgets', intl's date data, and CLDR's names of languages.
const adminZh = AdminLanguage(
  locale: Locale('zh'),
  strings: AdminLocalizationsZh(),
  material: MaterialLocalizationZh.new,
  cupertino: CupertinoLocalizationZh.new,
  widgets: WidgetsLocalizationZh(),
  dateSymbols: dateSymbols,
  datePatterns: datePatterns,
  names: CommonLocaleDataZh.staticInstance,
);
