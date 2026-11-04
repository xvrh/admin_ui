import 'package:admin_ui/admin_ui.dart';
import 'package:material_ui/material_ui.dart';

/// Wraps a demo widget with the admin theme so Views render exactly as they
/// would in production — without any services.
///
/// The kit's localizations are registered, so a demo renders in [locale]
/// (English, French and Arabic have kit strings; Hebrew has Material's only,
/// which exercises the English fallback under right-to-left). [locale] null
/// follows the platform. [textDirection] forces a direction whatever the
/// locale; null takes the locale's. A package built on the kit whose widgets
/// bring strings of their own passes [localizationsDelegates], listing the
/// kit's among them.
class TestApp extends StatelessWidget {
  final Widget child;
  final ThemeData? theme;
  final ThemeData? darkTheme;
  final ThemeMode? themeMode;
  final Locale? locale;
  final TextDirection? textDirection;
  final Iterable<LocalizationsDelegate<Object?>> localizationsDelegates;

  /// The locales a demo can be rendered in.
  static const locales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('ar'),
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
    this.localizationsDelegates = AdminLocalizations.localizationsDelegates,
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
      localizationsDelegates: localizationsDelegates,
      supportedLocales: locales,
      builder: direction == null
          ? null
          : (context, child) =>
                Directionality(textDirection: direction, child: child!),
      home: child,
    );
  }
}
