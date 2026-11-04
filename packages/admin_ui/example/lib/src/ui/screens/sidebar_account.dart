import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

/// The signed-in account at the foot of a sidebar, its menu pinned open:
/// above the row in the expanded sidebar, beside the avatar in the rail,
/// where the header is what says who is signed in.
class SidebarAccountDemo extends StatelessWidget {
  @Preview(name: 'Sidebar account', wrapper: adminUiPreview)
  const SidebarAccountDemo({super.key});

  static final _entries = [
    MenuItem('Profile', icon: Icons.person_outline_rounded, onSelect: () {}),
    MenuItem('Preferences', icon: Icons.tune_rounded, onSelect: () {}),
    const MenuDivider(),
    MenuItem('Sign out', icon: Icons.logout_rounded, onSelect: () {}),
  ];

  static const _navigation = [
    NavItem('Dashboard', icon: Icons.dashboard_outlined, selected: true),
    NavItem('Pages', icon: Icons.description_outlined),
    NavItem('Media', icon: Icons.perm_media_outlined),
  ];

  Widget _sidebar({required bool collapsed}) {
    return SizedBox(
      height: 420,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Sidebar(
          collapsed: collapsed,
          entries: _navigation,
          footer: PinnedOpen(
            child: SidebarAccount(
              name: 'Jane Doe',
              detail: 'jane.doe@example.com',
              badge: const Tag('Owner'),
              entries: _entries,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      children: [
        const DemoSection('Expanded: the menu opens above the row'),
        _sidebar(collapsed: false),
        const Gap(AdminSpacing.xxl),
        const DemoSection('Collapsed rail: the avatar, the menu beside it'),
        _sidebar(collapsed: true),
      ],
    );
  }
}
