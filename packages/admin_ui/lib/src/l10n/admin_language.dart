/// @docImport '../i18n/locale_status.dart';
/// @docImport 'formats.dart';
library;

import 'package:common_locale_data/common_locale_data.dart'
    show CommonLocaleData;
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_custom.dart';
import 'package:intl/date_symbols.dart';
import 'package:intl/intl.dart' show DateFormat, Intl, NumberFormat;
import 'package:material_ui/material_ui.dart';

import 'admin_ui_localizations.dart';
import 'date_locale.dart';
import 'language_names.dart';
import 'languages/en/date_data.dart' as en;

/// Builds Material's strings for one language from that language's date and
/// number formats, as material_ui's `GlobalMaterialLocalizations.delegate`
/// does: the constructor of one of its classes, such as
/// `MaterialLocalizationEs.new`.
typedef AdminMaterialLocalizationsBuilder =
    GlobalMaterialLocalizations Function({
      required String localeName,
      required DateFormat fullYearFormat,
      required DateFormat compactDateFormat,
      required DateFormat shortDateFormat,
      required DateFormat mediumDateFormat,
      required DateFormat longDateFormat,
      required DateFormat yearMonthFormat,
      required DateFormat shortMonthDayFormat,
      required NumberFormat decimalFormat,
      required NumberFormat twoDigitZeroPaddedFormat,
    });

/// Builds Cupertino's strings for one language from that language's date and
/// number formats, as cupertino_ui's `GlobalCupertinoLocalizations.delegate`
/// does: the constructor of one of its classes, such as
/// `CupertinoLocalizationEs.new`.
typedef AdminCupertinoLocalizationsBuilder =
    GlobalCupertinoLocalizations Function({
      required String localeName,
      required DateFormat fullYearFormat,
      required DateFormat dayFormat,
      required DateFormat weekdayFormat,
      required DateFormat mediumDateFormat,
      required DateFormat singleDigitHourFormat,
      required DateFormat singleDigitMinuteFormat,
      required DateFormat doubleDigitMinuteFormat,
      required DateFormat singleDigitSecondFormat,
      required NumberFormat decimalFormat,
    });

/// One language of the kit: everything its widgets show in that language.
///
/// That is the kit's own strings, Material's, Cupertino's and the widgets'
/// (the reading direction among them), intl's date symbols and patterns,
/// and the names of languages from CLDR. An app lists the languages it
/// ships in [AdminLanguages], whose delegates load them; a language it does
/// not list is not in its build.
///
/// The kit's languages come one library each, `adminEn` from
/// `package:admin_ui/l10n.dart` and the others from their own, such as
/// `adminEs` from `package:admin_ui/l10n/es.dart`. Any part can be replaced
/// with [copyWith]: an app overrides a few of the kit's strings with a
/// subclass of that language's class.
///
/// ```dart
/// class ShopStringsEs extends AdminLocalizationsEs {
///   const ShopStringsEs();
///   @override
///   String get searchPlaceholder => 'Buscar pedidos…';
/// }
///
/// final languages = AdminLanguages([
///   adminEn,
///   adminEs.copyWith(strings: const ShopStringsEs()),
/// ]);
/// ```
///
/// A language the kit does not have is an [AdminLanguage] of the app's own:
/// a subclass of [AdminLocalizationsEn] (which shows English for a string it
/// does not translate) or of [AdminLocalizations] (which fails to compile
/// until it translates every string), with material_ui's, cupertino_ui's and
/// flutter_localizations' classes for that language, intl's date data for it
/// and common_locale_data's names.
@immutable
class AdminLanguage {
  const AdminLanguage({
    required this.locale,
    required this.strings,
    required this.material,
    required this.cupertino,
    required this.widgets,
    required this.dateSymbols,
    required this.datePatterns,
    this.names,
  });

  /// The language, as an app lists it in `supportedLocales`. An app locale
  /// with the same language code is shown in it: 'es' for es_MX.
  final Locale locale;

  /// The kit's own strings.
  final AdminLocalizations strings;

  /// Material's strings, for the Material widgets in the app and the kit.
  final AdminMaterialLocalizationsBuilder material;

  /// Cupertino's strings.
  final AdminCupertinoLocalizationsBuilder cupertino;

  /// The widgets' strings, and the reading direction.
  final WidgetsLocalizations widgets;

  /// intl's date symbols for the language. A function, as `DateSymbols` has
  /// no const constructor.
  final DateSymbols Function() dateSymbols;

  /// intl's date patterns for the language, by skeleton.
  final Map<String, String> datePatterns;

  /// CLDR's data for the language, from common_locale_data, where
  /// [nameOf] finds the names of languages. Null names none.
  final CommonLocaleData? names;

  /// The language [AdminLanguages.delegates] loaded for [context], or null
  /// under other delegates.
  static AdminLanguage? of(BuildContext context) =>
      Localizations.of<AdminLanguage>(context, AdminLanguage);

  /// What this language calls the language [code] ("espagnol" for 'es' in
  /// French), or null when [names] has no name for it. The code is read as
  /// [languageName] reads it.
  String? nameOf(String code) {
    final names = this.names;
    return names == null ? null : languageNameIn(names, code);
  }

  AdminLanguage copyWith({
    Locale? locale,
    AdminLocalizations? strings,
    AdminMaterialLocalizationsBuilder? material,
    AdminCupertinoLocalizationsBuilder? cupertino,
    WidgetsLocalizations? widgets,
    DateSymbols Function()? dateSymbols,
    Map<String, String>? datePatterns,
    CommonLocaleData? names,
  }) => AdminLanguage(
    locale: locale ?? this.locale,
    strings: strings ?? this.strings,
    material: material ?? this.material,
    cupertino: cupertino ?? this.cupertino,
    widgets: widgets ?? this.widgets,
    dateSymbols: dateSymbols ?? this.dateSymbols,
    datePatterns: datePatterns ?? this.datePatterns,
    names: names ?? this.names,
  );

  @override
  bool operator ==(Object other) =>
      other is AdminLanguage &&
      other.locale == locale &&
      other.strings == strings &&
      other.material == material &&
      other.cupertino == cupertino &&
      other.widgets == widgets &&
      other.dateSymbols == dateSymbols &&
      other.datePatterns == datePatterns &&
      other.names == names;

  @override
  int get hashCode => Object.hash(
    locale,
    strings,
    material,
    cupertino,
    widgets,
    dateSymbols,
    datePatterns,
    names,
  );

  @override
  String toString() => 'AdminLanguage($locale)';
}

/// The languages an app ships the kit in, and the delegates that load them.
///
/// ```dart
/// import 'package:admin_ui/l10n.dart';
/// import 'package:admin_ui/l10n/de.dart';
/// import 'package:admin_ui/l10n/es.dart';
///
/// const languages = AdminLanguages([adminEn, adminEs, adminDe]);
///
/// MaterialApp(
///   localizationsDelegates: languages.delegates,
///   supportedLocales: languages.locales,
/// )
/// ```
///
/// The [delegates] load the kit's strings, Material's, Cupertino's and the
/// widgets' for the app's locale, from the language with its language code,
/// and intl's date data for every listed language and English. The kit's
/// accepts every locale: one with no language listed gets English, or the
/// first language when English is not listed. Material's, Cupertino's and
/// the widgets' support the listed languages only, so for another locale
/// Flutter warns that it has no Material strings.
///
/// On the web, a language the app does not list is not in its build. An app
/// that wants Material's own widgets in more languages than the kit's lists
/// material_ui's `GlobalMaterialLocalizations.delegates` after these, which
/// brings all 82 of Material's.
@immutable
class AdminLanguages {
  const AdminLanguages(this.languages);

  /// The languages, the first being the app's default.
  final List<AdminLanguage> languages;

  /// Each language's [AdminLanguage.locale], for `supportedLocales`.
  List<Locale> get locales => [
    for (final language in languages) language.locale,
  ];

  /// The kit's, Material's, Cupertino's and the widgets' delegates for
  /// [languages], for `localizationsDelegates`.
  List<LocalizationsDelegate<Object?>> get delegates => [
    _LanguageDelegate(this),
    _MaterialDelegate(this),
    _CupertinoDelegate(this),
    _WidgetsDelegate(this),
  ];

  /// The language with [locale]'s language code, or null.
  AdminLanguage? resolve(Locale locale) {
    for (final language in languages) {
      if (language.locale.languageCode == locale.languageCode) return language;
    }
    return null;
  }

  /// The language the kit's strings are in for [locale]: its own, else
  /// English, else the first.
  AdminLanguage _stringsFor(Locale locale) =>
      resolve(locale) ?? resolve(const Locale('en')) ?? languages.first;

  static AdminLanguages? _loaded;

  /// The languages an app's delegates loaded last: what code with no
  /// [BuildContext] reads its language from.
  @internal
  static AdminLanguages? get loaded => _loaded;

  /// The kit's strings for [locale] among the [loaded] languages, English
  /// when none has its language.
  @internal
  static AdminLocalizations stringsFor(Locale locale) =>
      _loaded?.resolve(locale)?.strings ?? const AdminLocalizationsEn();

  /// Makes these the [loaded] languages, and loads intl's date data for each
  /// of them and for English, which intl falls back to.
  @internal
  void load() {
    _loaded = this;
    _loadDateData(en.dateSymbols, en.datePatterns);
    for (final language in languages) {
      _loadDateData(language.dateSymbols, language.datePatterns);
    }
  }

  static final _dateDataLoaded = <DateSymbols Function()>{};

  static void _loadDateData(
    DateSymbols Function() symbols,
    Map<String, String> patterns,
  ) {
    if (!_dateDataLoaded.add(symbols)) return;
    final data = symbols();
    // Data the app loaded itself, from intl's own, stays.
    if (_hasDateData(data.NAME)) return;
    initializeDateFormattingCustom(
      locale: data.NAME,
      symbols: data,
      patterns: patterns,
    );
  }

  static bool _hasDateData(String locale) {
    try {
      return DateFormat.localeExists(locale);
    } on Exception {
      // No date data loaded yet: intl throws for all but en_US.
      return false;
    }
  }

  /// The intl locale [locale]'s dates are written in, after [load].
  String _dateLocale(Locale locale) =>
      dateLocaleOf(Intl.canonicalizedLocale(locale.toString())) ?? 'en';

  @override
  bool operator ==(Object other) =>
      other is AdminLanguages && listEquals(other.languages, languages);

  @override
  int get hashCode => Object.hashAll(languages);

  @override
  String toString() => 'AdminLanguages(${locales.join(', ')})';
}

class _LanguageDelegate extends LocalizationsDelegate<AdminLanguage> {
  const _LanguageDelegate(this.languages);

  final AdminLanguages languages;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AdminLanguage> load(Locale locale) {
    languages.load();
    return SynchronousFuture(languages._stringsFor(locale));
  }

  @override
  bool shouldReload(_LanguageDelegate old) => old.languages != languages;

  @override
  String toString() => 'AdminLanguages.delegates($languages)';
}

class _MaterialDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const _MaterialDelegate(this.languages);

  final AdminLanguages languages;

  @override
  bool isSupported(Locale locale) => languages.resolve(locale) != null;

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    languages.load();
    final dates = languages._dateLocale(locale);
    final numbers = Intl.verifiedLocale(
      dates,
      NumberFormat.localeExists,
      onFailure: (_) => null,
    );
    return SynchronousFuture(
      languages
          .resolve(locale)!
          .material(
            localeName: dates,
            fullYearFormat: DateFormat.y(dates),
            compactDateFormat: DateFormat.yMd(dates),
            shortDateFormat: DateFormat.yMMMd(dates),
            mediumDateFormat: DateFormat.MMMEd(dates),
            longDateFormat: DateFormat.yMMMMEEEEd(dates),
            yearMonthFormat: DateFormat.yMMMM(dates),
            shortMonthDayFormat: DateFormat.MMMd(dates),
            decimalFormat: NumberFormat.decimalPattern(numbers),
            twoDigitZeroPaddedFormat: NumberFormat('00', numbers),
          ),
    );
  }

  @override
  bool shouldReload(_MaterialDelegate old) => old.languages != languages;
}

class _CupertinoDelegate extends LocalizationsDelegate<CupertinoLocalizations> {
  const _CupertinoDelegate(this.languages);

  final AdminLanguages languages;

  @override
  bool isSupported(Locale locale) => languages.resolve(locale) != null;

  @override
  Future<CupertinoLocalizations> load(Locale locale) {
    languages.load();
    final dates = languages._dateLocale(locale);
    final numbers = Intl.verifiedLocale(
      dates,
      NumberFormat.localeExists,
      onFailure: (_) => null,
    );
    return SynchronousFuture(
      languages
          .resolve(locale)!
          .cupertino(
            localeName: dates,
            fullYearFormat: DateFormat.y(dates),
            dayFormat: DateFormat.d(dates),
            weekdayFormat: DateFormat.E(dates),
            mediumDateFormat: DateFormat.MMMEd(dates),
            singleDigitHourFormat: DateFormat('HH', dates),
            singleDigitMinuteFormat: DateFormat.m(dates),
            doubleDigitMinuteFormat: DateFormat('mm', dates),
            singleDigitSecondFormat: DateFormat.s(dates),
            decimalFormat: NumberFormat.decimalPattern(numbers),
          ),
    );
  }

  @override
  bool shouldReload(_CupertinoDelegate old) => old.languages != languages;
}

class _WidgetsDelegate extends LocalizationsDelegate<WidgetsLocalizations> {
  const _WidgetsDelegate(this.languages);

  final AdminLanguages languages;

  @override
  bool isSupported(Locale locale) => languages.resolve(locale) != null;

  @override
  Future<WidgetsLocalizations> load(Locale locale) {
    languages.load();
    return SynchronousFuture(languages.resolve(locale)!.widgets);
  }

  @override
  bool shouldReload(_WidgetsDelegate old) => old.languages != languages;
}
