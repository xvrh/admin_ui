import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

const _steps = [
  StepItem('Account', subtitle: 'Email & password'),
  StepItem('Workspace', subtitle: 'Name & domain'),
  StepItem('Team', subtitle: 'Invite people'),
  StepItem('Done'),
];

/// The indicator's states, an interactive wizard, and a completed step
/// holding keyboard focus: the keyboard highlight is forced on while this page
/// is up so the ring shows in a static render.
class StepsDemo extends StatefulWidget {
  @Preview(name: 'Steps / wizard', wrapper: adminUiPreview)
  const StepsDemo({super.key});

  @override
  State<StepsDemo> createState() => _StepsDemoState();
}

class _StepsDemoState extends State<StepsDemo> {
  final _focusScope = FocusScopeNode(debugLabel: 'Steps focus demo');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusScope.traversalDescendants.firstOrNull?.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusScope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardHighlight(
      child: DemoPage(
        maxWidth: 640,
        children: [
          const DemoSection('Horizontal'),
          const Steps(steps: _steps, current: 1),
          const Gap(AdminSpacing.xl),

          const DemoSection('With an error step'),
          const Steps(steps: _steps, current: 2, errorSteps: {1}),
          const Gap(AdminSpacing.xl),

          const DemoSection('Error on the current step'),
          const Steps(steps: _steps, current: 2, errorSteps: {2}),
          const Gap(AdminSpacing.xl),

          const DemoSection('Vertical'),
          const Steps(steps: _steps, current: 1, direction: Axis.vertical),
          const Gap(AdminSpacing.xl),

          const DemoSection('Keyboard focus on a completed step'),
          FocusScope(
            node: _focusScope,
            child: Steps(steps: _steps, current: 2, onChanged: (_) {}),
          ),
          const Gap(AdminSpacing.xl),

          const DemoSection('Interactive wizard (header + body + nav)'),
          const _Wizard(),
        ],
      ),
    );
  }
}

class _Wizard extends StatefulWidget {
  const _Wizard();

  @override
  State<_Wizard> createState() => _WizardState();
}

class _WizardState extends State<_Wizard> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    final last = _current == _steps.length - 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Steps(
          steps: _steps,
          current: _current,
          onChanged: (i) => setState(() => _current = i),
        ),
        const Gap(AdminSpacing.xxl),
        Container(
          height: 120,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.colors.background,
            borderRadius: BorderRadius.circular(context.radii.radius),
            border: Border.all(color: context.colors.border),
          ),
          child: Text(
            'Step ${_current + 1}: ${_steps[_current].title}',
            style: context.type.heading,
          ),
        ),
        const Gap(AdminSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Button(
              'Back',
              variant: ButtonVariant.secondary,
              onPressed: _current == 0
                  ? null
                  : () => setState(() => _current--),
            ),
            Button(
              last ? 'Finish' : 'Next',
              variant: ButtonVariant.primary,
              onPressed: last ? null : () => setState(() => _current++),
            ),
          ],
        ),
      ],
    );
  }
}
