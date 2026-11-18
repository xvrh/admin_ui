import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

/// A group of items folded under one row of a sidebar, in each of its
/// states: closed, open on the current item, closed over it, and as the
/// rail's one icon. Every sidebar is live: a click on the group's row
/// toggles it, an item becomes the current one, and the rail opens over the
/// page under the pointer or from the group's icon.
class SidebarGroupDemo extends StatelessWidget {
  @Preview(name: 'Sidebar group', wrapper: adminUiPreview)
  const SidebarGroupDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const DemoPage(
      maxWidth: 1180,
      children: [
        DemoSection('A group folds the pages few people open under one row'),
        Wrap(
          spacing: AdminSpacing.xxl,
          children: [
            _Variant('Closed', page: 'Orders'),
            _Variant('Open on the current item', page: 'Jobs'),
            _Variant(
              'Closed over the current item',
              page: 'Jobs',
              controlled: true,
            ),
            _Variant('The rail: its icon alone', page: 'Jobs', collapsed: true),
          ],
        ),
      ],
    );
  }
}

/// A sidebar of three items and a Developer group, opening on [page].
class _Variant extends StatefulWidget {
  final String caption;
  final String page;

  /// The demo keeps the group's state itself, and starts it closed.
  final bool controlled;
  final bool collapsed;

  const _Variant(
    this.caption, {
    required this.page,
    this.controlled = false,
    this.collapsed = false,
  });

  @override
  State<_Variant> createState() => _VariantState();
}

class _VariantState extends State<_Variant> {
  late var _page = widget.page;
  var _open = false;

  NavItem _item(String label, IconData icon) => NavItem(
    label,
    icon: icon,
    value: label,
    onTap: () => setState(() => _page = label),
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: Sidebar.widthOf(context),
      child: DemoVariant(
        widget.caption,
        SizedBox(
          height: 360,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Sidebar(
              collapsed: widget.collapsed,
              selected: _page,
              entries: [
                _item('Dashboard', Icons.dashboard_outlined),
                _item('Orders', Icons.receipt_long_outlined),
                _item('Products', Icons.inventory_2_outlined),
                NavGroup(
                  'Developer',
                  icon: Icons.terminal_rounded,
                  expanded: widget.controlled ? _open : null,
                  onExpandedChanged: (open) => setState(() => _open = open),
                  items: [
                    _item('API keys', Icons.key_outlined),
                    _item('Webhooks', Icons.webhook_rounded),
                    _item('Logs', Icons.subject_rounded),
                    _item('Jobs', Icons.schedule_rounded),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
