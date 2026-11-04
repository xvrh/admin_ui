import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

class TabsDemo extends StatelessWidget {
  @Preview(name: 'Tabs', wrapper: adminUiPreview)
  const TabsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 560,
      children: [
        const DemoSection('Tabs switch content'),
        const _Tabbed(
          tabs: [TabItem('Details'), TabItem('Pricing'), TabItem('SEO')],
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('With icons'),
        const _Tabbed(
          tabs: [
            TabItem('General', icon: Icons.tune_rounded),
            TabItem('Members', icon: Icons.group_outlined),
            TabItem('Billing', icon: Icons.credit_card_outlined),
          ],
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('With a count + a disabled tab'),
        _Tabbed(
          tabs: [
            const TabItem('Open'),
            TabItem(
              'Comments',
              trailing: const Tag('3', variant: TagVariant.soft),
            ),
            const TabItem('Resolved', enabled: false),
          ],
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('Fill — justified across the width'),
        const _Tabbed(
          alignment: TabsAlignment.fill,
          tabs: [TabItem('Day'), TabItem('Week'), TabItem('Month')],
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('Overflow — scrolls horizontally'),
        const _Tabbed(tabs: _overflow),
        const Gap(AdminSpacing.xl),

        const DemoSection('Overflow — opened on the eighth tab'),
        const _Tabbed(tabs: _overflow, initial: 7),
        const Gap(AdminSpacing.xl),

        const DemoSection('Small — a compact 32px strip'),
        _Tabbed(
          size: ControlSize.small,
          tabs: [
            const TabItem('All'),
            TabItem(
              'Mine',
              trailing: const Tag('12', variant: TagVariant.soft),
            ),
            const TabItem('Shared'),
          ],
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('Long label truncates'),
        const _Tabbed(
          alignment: TabsAlignment.fill,
          tabs: [
            TabItem('Settings'),
            TabItem('A very long tab label that will not fit'),
            TabItem('Logs'),
          ],
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('Enclosed — folder tabs attached to a panel'),
        const _Enclosed(),
      ],
    );
  }
}

const _overflow = [
  TabItem('Overview'),
  TabItem('Content'),
  TabItem('Translations'),
  TabItem('Media'),
  TabItem('Pricing'),
  TabItem('Inventory'),
  TabItem('SEO'),
  TabItem('Audit log'),
  TabItem('Permissions'),
];

/// Enclosed tabs read as belonging to the panel directly beneath them, so the
/// demo shows that panel rather than floating content.
class _Enclosed extends StatefulWidget {
  const _Enclosed();

  @override
  State<_Enclosed> createState() => _EnclosedState();
}

class _EnclosedState extends State<_Enclosed> {
  static const _tabs = [
    TabItem('Content'),
    TabItem('Layout'),
    TabItem('Style'),
  ];
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Tabs(
          variant: TabsVariant.enclosed,
          tabs: _tabs,
          selected: _selected,
          onChanged: (i) => setState(() => _selected = i),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.surface,
            border: Border(
              left: BorderSide(color: context.colors.border),
              right: BorderSide(color: context.colors.border),
              bottom: BorderSide(color: context.colors.border),
            ),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(context.radii.radiusSmall),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AdminSpacing.xl),
            child: Text(
              '${_tabs[_selected].label} panel',
              style: context.type.body,
            ),
          ),
        ),
      ],
    );
  }
}

/// Holds the selected index and shows which tab is active — the routing a real
/// screen would do lives in the Screen, not here.
class _Tabbed extends StatefulWidget {
  final List<TabItem> tabs;
  final TabsAlignment alignment;
  final ControlSize size;

  /// The tab selected on first build — as a deep link would open it.
  final int initial;

  const _Tabbed({
    required this.tabs,
    this.alignment = TabsAlignment.start,
    this.size = ControlSize.medium,
    this.initial = 0,
  });

  @override
  State<_Tabbed> createState() => _TabbedState();
}

class _TabbedState extends State<_Tabbed> {
  late int _selected = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Tabs(
          tabs: widget.tabs,
          selected: _selected,
          alignment: widget.alignment,
          size: widget.size,
          onChanged: (i) => setState(() => _selected = i),
        ),
        Padding(
          padding: const EdgeInsets.all(AdminSpacing.xl),
          child: Text(
            '${widget.tabs[_selected].label} content',
            style: context.type.body,
          ),
        ),
      ],
    );
  }
}
