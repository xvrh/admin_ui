import 'package:admin_ui/widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../appearance/themes.dart';
import '../keys/shell_keys.dart';
import '../l10n/ref_strings.dart';
import '../routing/routes.dart';
import '../services.dart';
import 'navigation.dart';

/// The signed-in staff member's avatar, opening their menu: profile, the
/// appearance submenus (theme, mode, language) and sign out.
class UserMenu extends StatelessWidget {
  const UserMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final services = context.services;
    final user = services.session.user;
    if (user == null) return const SizedBox.shrink();
    final strings = context.strings.shell;
    final appearance = services.appearance;
    final language = appearance.locale?.languageCode;
    return Menu(
      side: PopoverSide.bottom,
      align: PopoverAlign.end,
      entries: [
        MenuHeader(user.name),
        MenuItem(
          strings.profile,
          icon: Icons.person_outline,
          onSelect: () => services.router.go(const SettingsProfile()),
        ),
        MenuSubmenu(
          strings.appearance,
          icon: Icons.palette_outlined,
          entries: [
            MenuSubmenu(
              strings.theme,
              entries: [
                for (final theme in appThemes)
                  MenuCheckboxItem(
                    theme.name,
                    checked: theme.name == appearance.themeName,
                    onChanged: (_) => appearance.setTheme(theme.name),
                  ),
              ],
            ),
            MenuSubmenu(
              strings.mode,
              entries: [
                for (final (mode, label) in [
                  (ThemeMode.system, strings.modeSystem),
                  (ThemeMode.light, strings.modeLight),
                  (ThemeMode.dark, strings.modeDark),
                ])
                  MenuCheckboxItem(
                    label,
                    checked: appearance.mode == mode,
                    onChanged: (_) => appearance.setMode(mode),
                  ),
              ],
            ),
            MenuSubmenu(
              strings.language,
              entries: [
                MenuCheckboxItem(
                  strings.languageSystem,
                  checked: language == null,
                  onChanged: (_) => appearance.setLocale(null),
                ),
                for (final code in const ['en', 'fr', 'ar'])
                  MenuCheckboxItem(
                    strings.languageName(code),
                    checked: language == code,
                    onChanged: (_) => appearance.setLocale(Locale(code)),
                  ),
              ],
            ),
            const MenuDivider(),
            MenuItem(
              strings.appearance,
              icon: Icons.tune,
              onSelect: () => services.router.go(const SettingsAppearance()),
            ),
          ],
        ),
        const MenuDivider(),
        MenuItem(
          strings.signOut,
          icon: Icons.logout,
          onSelect: services.router.signOut,
        ),
      ],
      builder: (context, controller) => Tappable(
        key: ShellKeys.userMenu,
        onTap: controller.toggle,
        semanticLabel: user.name,
        focusRadius: 999,
        child: Avatar(
          name: user.name,
          color: staffAvatarColor(context, user.name),
          size: 32,
        ),
      ),
    );
  }
}
