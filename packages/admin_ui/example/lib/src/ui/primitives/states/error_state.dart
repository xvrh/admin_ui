import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../../demo_kit.dart';

class ErrorStateDemo extends StatelessWidget {
  @Preview(name: 'Error', wrapper: adminUiPreview)
  const ErrorStateDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 520,
      children: [
        const DemoSection('Default'),
        const Panel(child: ErrorState()),
        const Gap(AdminSpacing.xl),

        const DemoSection('With detail message'),
        const Panel(
          child: ErrorState(
            title: 'Couldn’t load products',
            message: 'The server returned a 500. Try again in a moment.',
          ),
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('With retry — the load → error → loading triad'),
        const Panel(child: _RetryFlow()),
      ],
    );
  }
}

enum _Phase { error, loading, loaded }

class _RetryFlow extends StatefulWidget {
  const _RetryFlow();

  @override
  State<_RetryFlow> createState() => _RetryFlowState();
}

class _RetryFlowState extends State<_RetryFlow> {
  _Phase _phase = _Phase.error;

  void _retry() {
    setState(() => _phase = _Phase.loading);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _phase = _Phase.loaded);
    });
  }

  @override
  Widget build(BuildContext context) {
    return switch (_phase) {
      _Phase.error => ErrorState(
        title: 'Couldn’t load products',
        message: 'Tap retry to simulate a successful reload.',
        onRetry: _retry,
      ),
      _Phase.loading => const LoadingPanel(message: 'Retrying…'),
      _Phase.loaded => EmptyState(
        icon: Icons.check_circle_outline_rounded,
        title: 'Loaded',
        message: 'The retry succeeded.',
        action: Button.ghost(
          'Reset',
          onPressed: () => setState(() => _phase = _Phase.error),
        ),
      ),
    };
  }
}
