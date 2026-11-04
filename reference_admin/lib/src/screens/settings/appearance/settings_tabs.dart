import 'package:admin_ui/fields.dart';
import 'package:admin_ui/shell.dart';
import 'package:admin_ui/theme.dart';
import 'package:admin_ui/widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../../../api/shop_api.dart';
import '../../../keys/settings_keys.dart';
import '../../../l10n/ref_strings.dart';
import '../../../routing/routes.dart';
import '../../../services.dart';
import '../../../widgets/page_width.dart';

/// The settings pages, in the order their tabs show.
enum SettingsSection { appearance, profile, shop }

/// A settings page: the shared "Settings" title, the strip of settings pages
/// the role may open, then [body] in a readable column.
///
/// The sidebar has one Settings item; the strip is how its pages reach each
/// other. The shop settings page takes it too, so the three read as one place.
class SettingsScaffold extends StatelessWidget {
  final SettingsSection section;
  final String? subtitle;
  final Widget body;
  final Widget? bottomBar;

  const SettingsScaffold({
    super.key,
    required this.section,
    this.subtitle,
    required this.body,
    this.bottomBar,
  });

  /// The widest a settings page's content grows: the app's one page width.
  static const maxWidth = pageMaxWidth;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: context.strings.settings.settingsTitle,
      subtitle: subtitle,
      maxWidth: maxWidth,
      tabs: SettingsTabs(current: section),
      bottomBar: bottomBar,
      body: body,
    );
  }
}

/// The strip of settings pages; the shop's only for a role that manages it.
class SettingsTabs extends StatelessWidget {
  final SettingsSection current;

  const SettingsTabs({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings.settings;
    final session = context.services.session;
    final sections = [
      SettingsSection.appearance,
      SettingsSection.profile,
      if (session.can(Permission.manageShop)) SettingsSection.shop,
    ];
    return Tabs(
      key: SettingsKeys.tabs,
      tabs: [
        for (final section in sections)
          switch (section) {
            SettingsSection.appearance => TabItem(
              strings.appearanceTitle,
              icon: Icons.palette_outlined,
            ),
            SettingsSection.profile => TabItem(
              strings.profileTitle,
              icon: Icons.person_outline,
            ),
            SettingsSection.shop => TabItem(
              strings.shopTab,
              icon: Icons.storefront_outlined,
            ),
          },
      ],
      selected: sections.indexOf(current),
      onChanged: (i) => context.go(switch (sections[i]) {
        SettingsSection.appearance => const SettingsAppearance(),
        SettingsSection.profile => const SettingsProfile(),
        SettingsSection.shop => const SettingsShop(),
      }),
    );
  }
}

/// One card of a settings page: a titled, bordered group whose [children]
/// stack with the kit's field rhythm.
class SettingsCard extends StatelessWidget {
  final String title;
  final String? description;
  final List<Widget> children;

  const SettingsCard({
    super.key,
    required this.title,
    this.description,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return FieldGroup(
      title: title,
      description: description,
      boxed: true,
      spacing: AdminSpacing.xl,
      children: children,
    );
  }
}
