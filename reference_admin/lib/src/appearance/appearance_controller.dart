import 'package:admin_ui/theme.dart';
import 'package:material_ui/material_ui.dart';

import '../api/shop_api.dart';
import 'themes.dart';

/// How the app looks for the signed-in staff member: the kit's
/// [AdminAppearance] (theme, mode, accent, table density), plus the language
/// and motion.
///
/// It lives in memory for the whole app, is loaded from the staff member's
/// prefs as they sign in and saved on every change, and outlives signing
/// out, so the sign-in page keeps the last look.
class AppearanceController extends ChangeNotifier {
  /// Stores the prefs after every change; null while nobody is signed in.
  Future<void> Function(UserPrefs prefs)? save;

  AppearanceController({this.save});

  AdminAppearance _look = AdminAppearance(theme: irisTheme);
  Locale? _locale;
  bool _reduceMotion = false;

  /// The theme, mode, accent and density.
  AdminAppearance get look => _look;

  String get themeName => _look.themeName;
  AdminTheme get theme => _look.theme;
  ThemeMode get mode => _look.mode;
  Color? get accent => _look.accent;
  TableDensity get density => _look.density;

  /// Null follows the device.
  Locale? get locale => _locale;
  bool get reduceMotion => _reduceMotion;

  AdminTokens get lightTokens => _withFallback(_look.tokens(Brightness.light));
  AdminTokens get darkTokens => _withFallback(_look.tokens(Brightness.dark));

  /// The kit holds one token set per theme, accent and brightness; this
  /// holds the one with the Arabic fallback beside it.
  static final _fallback = Expando<AdminTokens>('Arabic fallback');

  static AdminTokens _withFallback(AdminTokens tokens) =>
      _fallback[tokens] ??= withArabicFallback(tokens);

  void setLook(AdminAppearance look) => _change(() => _look = look);
  void setTheme(String name) =>
      setLook(_look.copyWith(theme: themeNamed(name)));
  void setMode(ThemeMode mode) => setLook(_look.copyWith(mode: mode));
  void setLocale(Locale? locale) => _change(() => _locale = locale);
  void setReduceMotion(bool reduce) => _change(() => _reduceMotion = reduce);

  void _change(VoidCallback update) {
    final before = (_look, _locale, _reduceMotion);
    update();
    if ((_look, _locale, _reduceMotion) == before) return;
    notifyListeners();
    save?.call(toPrefs()).ignore();
  }

  /// Takes [prefs] without saving them back. Prefs that name no theme keep
  /// the one on screen.
  void apply(UserPrefs prefs) {
    // The prefs' names are the kit's: modes and densities alike.
    _look = AdminAppearance.fromJson({
      ...prefs.toJson(),
      'theme': prefs.theme ?? _look.themeName,
    }, themes: appThemes);
    _locale = prefs.locale == null ? null : Locale(prefs.locale!);
    _reduceMotion = prefs.reduceMotion;
    notifyListeners();
  }

  UserPrefs toPrefs() => UserPrefs(
    theme: _look.themeName,
    mode: AppearanceMode.values.byName(_look.mode.name),
    accent: _look.accent?.toARGB32(),
    density: Density.values.byName(_look.density.name),
    locale: _locale?.languageCode,
    reduceMotion: _reduceMotion,
  );
}
