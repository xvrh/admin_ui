import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

/// Every floating layer painted statically, in stacking order: the page
/// (`background`), a card on it (`surface`), a popover menu over the card, the
/// scrim over the right half, a dialog on the scrim, and a toast above it all.
/// Previews cannot open a route, so this is where the depth of each theme —
/// the dark ones especially — is checked at a glance.
class OverlaySurfacesDemo extends StatelessWidget {
  @Preview(name: 'Overlay surfaces', wrapper: adminUiPreview)
  const OverlaySurfacesDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final corners = BorderRadius.circular(context.radii.radiusLarge);
    final actions = LayerLink();
    return DemoPage(
      maxWidth: 940,
      children: [
        const DemoSection('Page · card · popover · scrim · dialog · toast'),
        Text(
          'The left half is the page as it rests; the right half is under the '
          'modal scrim, which must dim it in both modes.',
          style: context.type.bodyMuted,
        ),
        const Gap(AdminSpacing.lg),
        DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: corners,
            border: Border.all(color: colors.border),
          ),
          child: ClipRRect(
            borderRadius: corners,
            child: SizedBox(
              height: 440,
              child: ToastScope(
                child: _RaiseToast(
                  child: LayoutBuilder(
                    builder: (context, box) => Stack(
                      children: [
                        Positioned.fill(
                          child: ColoredBox(color: colors.background),
                        ),
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.all(AdminSpacing.xxl),
                            child: _Card(actions: actions),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          top: 0,
                          child: CompositedTransformFollower(
                            link: actions,
                            targetAnchor: Alignment.bottomLeft,
                            offset: const Offset(0, 6),
                            child: PopoverMenuSurface(
                              minWidth: 200,
                              maxWidth: 240,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Gap(AdminSpacing.xs),
                                  for (final entry in _menuEntries(context))
                                    Menu.entry(context, entry, _pinned),
                                  const Gap(AdminSpacing.xs),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: box.maxWidth / 2,
                          top: 0,
                          right: 0,
                          bottom: 0,
                          child: ColoredBox(
                            color: colors.scrim,
                            child: Center(
                              child: Modal(
                                title: 'Discard changes?',
                                maxWidth: 340,
                                message:
                                    'Your edits to “Pricing” will be lost. '
                                    'This cannot be undone.',
                                actions: [
                                  Button.ghost(
                                    'Keep editing',
                                    onPressed: () {},
                                  ),
                                  Button.danger('Discard', onPressed: () {}),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

List<MenuEntry> _menuEntries(BuildContext context) => [
  const MenuHeader('Page'),
  MenuItem(
    'Edit',
    icon: Icons.edit_outlined,
    shortcut: shortcutLabel(
      context,
      primaryModifierActivator(LogicalKeyboardKey.keyE),
    ),
    onSelect: _noop,
  ),
  const MenuItem('Duplicate', icon: Icons.copy_rounded, onSelect: _noop),
  const MenuItem('Archive', icon: Icons.archive_outlined),
  const MenuDivider(),
  const MenuItem(
    'Delete',
    icon: Icons.delete_outline_rounded,
    danger: true,
    onSelect: _noop,
  ),
];

void _noop() {}

final _pinned = _PinnedController();

/// A stand-in for an open popover's controller, so menu rows render without a
/// live anchor.
class _PinnedController implements PopoverController {
  @override
  bool get isOpen => true;

  @override
  double? get anchorWidth => null;

  @override
  void open() {}

  @override
  void close() {}

  @override
  void toggle() {}
}

/// The card the page layers sit on: a title, a line of body, the trigger the
/// popover hangs from and a few fields — enough texture to judge the scrim
/// over it.
class _Card extends StatelessWidget {
  final LayerLink actions;

  const _Card({required this.actions});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Panel(
      padding: const EdgeInsets.all(AdminSpacing.xl),
      // The stage is a fixed height; at a large text size the card scrolls
      // inside it rather than overflowing.
      child: SingleChildScrollView(child: _content(context, colors)),
    );
  }

  Widget _content(BuildContext context, AdminPalette colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Pricing', style: context.type.heading),
            const Gap(AdminSpacing.md),
            const Tag('Published', severity: Severity.success, dot: true),
          ],
        ),
        const Gap(AdminSpacing.xs),
        Text(
          'Card (surface) on the page (background). Plans, tiers and the '
          'comparison table shown on /pricing.',
          style: context.type.bodyMuted,
        ),
        const Gap(AdminSpacing.lg),
        CompositedTransformTarget(
          link: actions,
          child: Button(
            'Actions',
            trailingIcon: Icons.keyboard_arrow_down_rounded,
            onPressed: () {},
          ),
        ),
        const Gap(AdminSpacing.xl),
        for (final (label, value) in const [
          ('Title', 'Pricing'),
          ('Slug', '/pricing'),
          ('Updated', '2 hours ago'),
        ]) ...[
          Row(
            children: [
              SizedBox(
                width: 240,
                child: Text(label, style: context.type.caption),
              ),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 32),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AdminSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(context.radii.radius),
                    border: Border.all(color: colors.controlBorder),
                  ),
                  child: Text(value, style: context.type.body),
                ),
              ),
            ],
          ),
          const Gap(AdminSpacing.md),
        ],
      ],
    );
  }
}

/// Raises one long-lived toast once mounted, so the stack shows a toast
/// without a click.
class _RaiseToast extends StatefulWidget {
  final Widget child;

  const _RaiseToast({required this.child});

  @override
  State<_RaiseToast> createState() => _RaiseToastState();
}

class _RaiseToastState extends State<_RaiseToast> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ToastScope.of(context).show(
        const Toast(
          'Changes saved.',
          severity: Severity.success,
          duration: Duration(days: 1),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
