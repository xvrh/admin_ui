import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

class SplitViewDemo extends StatelessWidget {
  @Preview(name: 'Split view (resizable)', wrapper: adminUiPreview)
  const SplitViewDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 900,
      children: [
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
