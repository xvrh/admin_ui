import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

void _noop() {}

/// "Needs your attention" tiles: counts of things waiting on someone, each
/// tinted by its tone, with the empty and loading states.
class AttentionGridDemo extends StatelessWidget {
  @Preview(name: 'Attention tiles', wrapper: adminUiPreview)
  const AttentionGridDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const DemoPage(
      maxWidth: 760,
      children: [
        DemoSection('Populated'),
        AttentionGrid(
          items: [
            AttentionItem(
              label: 'requests to approve',
              count: 5,
              icon: Icons.fact_check_outlined,
              caption: 'oldest 3 days ago',
              onTap: _noop,
            ),
            AttentionItem(
              label: 'open questions',
              count: 2,
              icon: Icons.mode_comment_outlined,
              tone: Severity.warning,
              caption: 'on 2 records',
              onTap: _noop,
            ),
            AttentionItem(
              label: 'failed imports',
              count: 1,
              icon: Icons.error_outline_rounded,
              tone: Severity.danger,
              caption: 'CSV · row 214',
              onTap: _noop,
            ),
            AttentionItem(
              label: 'invoices sent',
              count: 12,
              icon: Icons.outgoing_mail,
              tone: Severity.success,
              onTap: _noop,
            ),
          ],
        ),
        Gap(AdminSpacing.xxl),

        DemoSection('Empty — nothing needs attention'),
        AttentionGrid(items: []),
        Gap(AdminSpacing.xxl),

        DemoSection('Loading — tiles keep their height'),
        AttentionGrid(items: [], loading: true, placeholderCount: 2),
      ],
    );
  }
}
