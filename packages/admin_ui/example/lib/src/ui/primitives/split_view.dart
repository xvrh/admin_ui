import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

/// [SplitView]: weighted and sized panes, side by side and stacked. A
/// divider drags, and never needs to: it is a Tab stop that the arrow keys
/// move, Home and End take to its limits and Enter collapses, and a
/// right-click or a long press on it opens a menu of the same moves.
class SplitViewDemo extends StatelessWidget {
  final bool _focused;

  @Preview(name: 'Split view (resizable)', wrapper: adminUiPreview)
  const SplitViewDemo({super.key}) : _focused = false;

  /// A divider as Tab leaves it: lit, and ringed inside the view.
  @Preview(name: 'Split view · a focused divider', wrapper: adminUiPreview)
  const SplitViewDemo.focused({super.key}) : _focused = true;

  @override
  Widget build(BuildContext context) {
    if (_focused) {
      return DemoPage(
        maxWidth: 900,
        children: [
          DemoVariant(
            'Tab stops on the divider: lit and ringed, it takes ← →, Home, '
            'End and Enter',
            KeyboardHighlight(
              child: PinnedFocus(
                child: _Frame(
                  height: 220,
                  child: SplitView.two(
                    initialWeight: 0.35,
                    first: const _Pane('List', tone: 0),
                    second: const _Pane('Detail', tone: 1),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return DemoPage(
      maxWidth: 900,
      children: [
        Text(
          'Drag a divider, or Tab to it: ← → (↑ ↓ between stacked panes) '
          'move it, Home and End take its pane to its smallest and its '
          'largest, Enter collapses the pane and restores it. A right-click '
          'or a long press on a divider opens a menu of the same moves.',
          style: context.type.bodyMuted,
        ),
        const Gap(AdminSpacing.xxl),
        const DemoSection('Two panes · horizontal (master / detail)'),
        _Frame(
          height: 280,
          child: SplitView.two(
            initialWeight: 0.35,
            minFirst: 140,
            minSecond: 220,
            first: const _Pane('List', tone: 0),
            second: const _Pane('Detail', tone: 1),
          ),
        ),
        const Gap(AdminSpacing.xxl),

        const DemoSection('A divider\'s menu, in place of a drag'),
        DemoVariant(
          'A right-click or a long press on a divider: a step either way, '
          'and collapse or expand, each beside its key',
          PinnedOpen(
            reserve: 130,
            child: _Frame(
              height: 120,
              child: SplitView.two(
                initialWeight: 0.35,
                first: const _Pane('List', tone: 0),
                second: const _Pane('Detail', tone: 1),
              ),
            ),
          ),
        ),
        const Gap(AdminSpacing.xxl),

        const DemoSection('Two panes · vertical (stacked)'),
        _Frame(
          height: 320,
          child: SplitView.two(
            axis: SplitAxis.vertical,
            initialWeight: 0.4,
            first: const _Pane('Editor', tone: 0),
            second: const _Pane('Preview', tone: 1),
          ),
        ),
        const Gap(AdminSpacing.xxl),

        const DemoSection('Three panes · nav │ list │ detail (min sizes)'),
        _Frame(
          height: 320,
          child: SplitView(
            initialWeights: const [0.2, 0.3, 0.5],
            minSizes: const [120, 160, 240],
            children: const [
              _Pane('Nav', tone: 0),
              _Pane('List', tone: 1),
              _Pane('Detail', tone: 2),
            ],
          ),
        ),
        const Gap(AdminSpacing.xxl),

        const DemoSection(
          'Sized side panes · list │ content │ inspector (only the content '
          'follows the width; Enter on a divider collapses its side pane)',
        ),
        _Frame(
          height: 320,
          child: SplitView(
            initialSizes: const [200, null, 240],
            minSizes: const [160, 240, 200],
            children: const [
              _Pane('List · 200', tone: 0),
              _Pane('Content', tone: 1),
              _Pane('Inspector · 240', tone: 2),
            ],
          ),
        ),
        const Gap(AdminSpacing.xxl),

        const DemoSection('Persisted weights (onWeightsChanged)'),
        const _PersistedDemo(),
      ],
    );
  }
}

class _PersistedDemo extends StatefulWidget {
  const _PersistedDemo();

  @override
  State<_PersistedDemo> createState() => _PersistedDemoState();
}

class _PersistedDemoState extends State<_PersistedDemo> {
  List<double> _weights = const [0.5, 0.5];

  @override
  Widget build(BuildContext context) {
    final readout = _weights.map((w) => w.toStringAsFixed(2)).join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Frame(
          height: 220,
          child: SplitView.two(
            first: const _Pane('A', tone: 0),
            second: const _Pane('B', tone: 1),
            onWeightsChanged: (w) => setState(() => _weights = w),
          ),
        ),
        const Gap(AdminSpacing.md),
        Text('weights: $readout', style: context.type.bodyMuted),
      ],
    );
  }
}

class _Frame extends StatelessWidget {
  final double height;
  final Widget child;

  const _Frame({required this.height, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Panel(child: child),
    );
  }
}

class _Pane extends StatelessWidget {
  final String label;
  final int tone;

  const _Pane(this.label, {this.tone = 0});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fill = switch (tone % 3) {
      0 => colors.surface,
      1 => colors.background,
      _ => colors.surfaceMuted,
    };
    return Container(
      color: fill,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AdminSpacing.lg),
      child: Text(label, style: context.type.bodyStrong),
    );
  }
}
