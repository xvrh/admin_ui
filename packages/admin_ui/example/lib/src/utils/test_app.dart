import 'package:admin_ui/admin_ui.dart';
import 'package:admin_ui/l10n/de.dart';
import 'package:admin_ui/l10n/es.dart';
import 'package:admin_ui/l10n/it.dart';
import 'package:admin_ui/l10n/ja.dart';
import 'package:admin_ui/l10n/ko.dart';
import 'package:admin_ui/l10n/nl.dart';
import 'package:admin_ui/l10n/pl.dart';
import 'package:admin_ui/l10n/pt.dart';
import 'package:admin_ui/l10n/tr.dart';
import 'package:admin_ui/l10n/zh.dart';
import 'package:material_ui/material_ui.dart';

/// Wraps a demo widget with the admin theme so Views render exactly as they
/// would in production — without any services.
///
/// The kit's [languages] are registered, then Material's, so a demo renders
/// in [locale] (Hebrew has Material's strings only, which exercises the
/// English fallback under right-to-left). [locale] null follows the
/// platform. [textDirection] forces a direction whatever the locale; null
/// takes the locale's. A package built on the kit whose widgets bring
/// strings of their own passes [localizationsDelegates], listing the kit's
/// among them.
class TestApp extends StatelessWidget {
  final Widget child;
  final ThemeData? theme;
  final ThemeData? darkTheme;
  final ThemeMode? themeMode;
  final Locale? locale;
  final TextDirection? textDirection;
  final Iterable<LocalizationsDelegate<Object?>>? localizationsDelegates;

  /// The kit's languages a demo can be rendered in.
  static const languages = AdminLanguages([
    adminEn,
    adminFr,
    adminAr,
    adminEs,
    adminDe,
    adminIt,
    adminPt,
    adminNl,
    adminPl,
    adminJa,
    adminZh,
    adminKo,
    adminTr,
  ]);

  /// [languages]' delegates, then material_ui's, for the locales the kit
  /// has no language for.
  static List<LocalizationsDelegate<Object?>> get delegates => [
    ...languages.delegates,
    ...GlobalMaterialLocalizations.delegates,
  ];

  /// The locales a demo can be rendered in.
  static const locales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('ar'),
    Locale('es'),
    Locale('de'),
    Locale('it'),
    Locale('pt'),
    Locale('nl'),
    Locale('pl'),
    Locale('ja'),
    Locale('zh'),
    Locale('ko'),
    Locale('tr'),
    Locale('he'),
  ];

  const TestApp({
    super.key,
    required this.child,
    this.theme,
    this.darkTheme,
    this.themeMode,
    this.locale,
    this.textDirection,
    this.localizationsDelegates,
  });

  @override
  Widget build(BuildContext context) {
    final direction = textDirection;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme ?? buildAppTheme(defaultTokens),
      darkTheme: darkTheme,
      themeMode: themeMode ?? ThemeMode.light,
      locale: locale,
      localizationsDelegates: localizationsDelegates ?? delegates,
      supportedLocales: locales,
      builder: direction == null
          ? null
          : (context, child) =>
                Directionality(textDirection: direction, child: child!),
      home: child,
    );
  }
}
