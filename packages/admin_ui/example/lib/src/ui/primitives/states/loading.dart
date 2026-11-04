import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../../demo_kit.dart';

class LoadingDemo extends StatelessWidget {
  @Preview(name: 'Loading', wrapper: adminUiPreview)
  const LoadingDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 520,
      children: [
        const DemoSection('Spinner — sizes'),
        const Row(
          children: [
            Spinner(size: 16),
            Gap(AdminSpacing.xl),
            Spinner(),
            Gap(AdminSpacing.xl),
            Spinner(size: 28),
          ],
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('Loading panel'),
        const Panel(child: LoadingPanel()),
        const Gap(AdminSpacing.xl),

        const DemoSection('Loading panel — with message'),
        const Panel(child: LoadingPanel(message: 'Loading products…')),
        const Gap(AdminSpacing.xl),

        const DemoSection('Loading overlay — dims stale content on re-load'),
        const Panel(
          child: LoadingOverlay(
            loading: true,
            message: 'Refreshing…',
            child: _Rows(),
          ),
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('Loading overlay — live'),
        const _OverlayDemo(),
      ],
    );
  }
}

class _OverlayDemo extends StatefulWidget {
  const _OverlayDemo();

  @override
  State<_OverlayDemo> createState() => _OverlayDemoState();
}

class _OverlayDemoState extends State<_OverlayDemo> {
  bool _loading = false;

  void _reload() {
    setState(() => _loading = true);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Button(
            'Reload',
            icon: Icons.refresh_rounded,
            onPressed: _loading ? null : _reload,
          ),
        ),
        const Gap(AdminSpacing.lg),
        Panel(
          child: LoadingOverlay(
            loading: _loading,
            message: 'Refreshing…',
            child: const _Rows(),
          ),
        ),
      ],
    );
  }
}

/// The stale content the overlay dims.
class _Rows extends StatelessWidget {
  const _Rows();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in const ['Homepage', 'About us', 'Contact'])
          Padding(
            padding: const EdgeInsets.all(AdminSpacing.lg),
            child: Text(row, style: context.type.body),
          ),
      ],
    );
  }
}
