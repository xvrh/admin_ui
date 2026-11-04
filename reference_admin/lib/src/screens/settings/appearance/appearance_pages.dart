import 'package:admin_ui/forms.dart';
import 'package:material_ui/material_ui.dart';

import '../../../appearance/appearance_controller.dart';
import '../../../keys/settings_keys.dart';
import '../../../l10n/ref_strings.dart';
import '../../../routing/routes.dart';
import '../../../services.dart';
import 'appearance_view.dart';
import 'settings_tabs.dart';

Widget appearancePage(BuildContext context, SettingsAppearance route) =>
    const AppearanceScreen(key: SettingsKeys.appearancePage);

/// Theme, mode, accent, density, language and motion, each applied as it is
/// picked and saved to the staff member's prefs by the appearance
/// controller, so it follows them to any device.
class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  late final AppearanceController _appearance = context.services.appearance;
  final _scope = LocalScope();
  late final ValueCell<String> _language = _scope.text('language');

  @override
  void initState() {
    super.initState();
    _language.set(_languageOf(_appearance));
    _language.addListener(_onLanguage);
    _appearance.addListener(_onAppearance);
  }

  @override
  void dispose() {
    _appearance.removeListener(_onAppearance);
    _language.removeListener(_onLanguage);
    _scope.dispose();
    super.dispose();
  }

  static String _languageOf(AppearanceController appearance) =>
      appearance.locale?.languageCode ?? deviceLanguage;

  void _onLanguage() {
    final code = _language.value;
    _appearance.setLocale(code == deviceLanguage ? null : Locale(code));
  }

  // The user menu changes the same settings while this page shows.
  void _onAppearance() {
    final code = _languageOf(_appearance);
    if (_language.value != code) _language.set(code);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final appearance = _appearance;
    return SettingsScaffold(
      section: SettingsSection.appearance,
      subtitle: context.strings.settings.appearanceSubtitle,
      body: AppearanceView(
        appearance: appearance.look,
        onChanged: appearance.setLook,
        language: _language,
        reduceMotion: appearance.reduceMotion,
        onReduceMotion: appearance.setReduceMotion,
      ),
    );
  }
}
