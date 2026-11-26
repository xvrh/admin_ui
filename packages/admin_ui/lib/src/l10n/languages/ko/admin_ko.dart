import 'package:common_locale_data/ko.dart' show CommonLocaleDataKo;
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoLocalizationKo;
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_localizations/flutter_localizations.dart'
    show WidgetsLocalizationKo;
import 'package:material_ui/material_ui.dart' show MaterialLocalizationKo;

import '../../admin_language.dart';
import 'admin_localizations_ko.dart';
import 'date_data.dart';

/// The kit in Korean: its own strings, Material's, Cupertino's and
/// the widgets', intl's date data, and CLDR's names of languages.
const adminKo = AdminLanguage(
  locale: Locale('ko'),
  strings: AdminLocalizationsKo(),
  material: MaterialLocalizationKo.new,
  cupertino: CupertinoLocalizationKo.new,
  widgets: WidgetsLocalizationKo(),
  dateSymbols: dateSymbols,
  datePatterns: datePatterns,
  names: CommonLocaleDataKo.staticInstance,
);
