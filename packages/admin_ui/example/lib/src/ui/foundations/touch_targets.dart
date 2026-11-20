import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

/// Demo — a finger's near miss. Each small control is drawn at its own
/// size inside an outline of the area a finger can press it from: 48px,
/// under a [TouchTargetAdjustment]. Press inside an outline with a finger,
/// beside the control, and the control is pressed; a mouse has to be on it.
class TouchTargetsDemo extends StatefulWidget {
  @Preview(name: 'Touch targets', wrapper: adminUiPreview)
  const TouchTargetsDemo({super.key});

  @override
  State<TouchTargetsDemo> createState() => _TouchTargetsDemoState();
}

class _TouchTargetsDemoState extends State<TouchTargetsDemo> {
  String _last = 'nothing yet';
  bool _checked = false;

  void _pressed(String what) => setState(() => _last = what);

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 520,
      children: [
        const DemoSection(
          'A finger beside a small control presses it — nothing is laid '
          'out larger',
        ),
        TouchTargetAdjustment(
          child: Wrap(
            spacing: AdminSpacing.xl,
            runSpacing: AdminSpacing.xl,
            children: [
              _Reach(
                child: IconAction(
                  Icons.edit_outlined,
                  label: 'Edit',
                  size: IconActionSize.inline,
                  onPressed: () => _pressed('Edit'),
                ),
              ),
              _Reach(
                child: CircleButton(
                  icon: Icons.close,
                  label: 'Remove',
                  onTap: () => _pressed('Remove'),
                ),
              ),
              _Reach(
                child: Check(
                  value: _checked,
                  semanticLabel: 'Pick',
                  onChanged: (value) {
                    _checked = value;
                    _pressed('the checkbox');
                  },
                ),
              ),
              _Reach(
                child: IconAction(
                  Icons.more_horiz_rounded,
                  label: 'More',
                  onPressed: () => _pressed('More'),
                ),
              ),
            ],
          ),
        ),
        const Gap(AdminSpacing.lg),
        Text('Last pressed: $_last', style: context.type.bodyMuted),
        const Gap(AdminSpacing.xl),

        const DemoSection(
          'A tap target of the app\'s own joins with TouchTarget',
        ),
        TouchTargetAdjustment(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: _Reach(
              // Named for assistive technology, as a control of an app's
              // own has to be.
              child: Semantics(
                container: true,
                button: true,
                label: 'A control of the app\'s own',
                child: TouchTarget(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _pressed('the app\'s own'),
                    child: SizedBox.square(
                      dimension: 24,
                      child: ColoredBox(color: context.colors.primary),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('Off — a finger has to land on the control'),
        TouchTargetAdjustment(
          enabled: false,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: _Reach(
              child: CircleButton(
                icon: Icons.close,
                label: 'Remove',
                onTap: () => _pressed('Remove, with the adjustment off'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// [child] at its own size, centred in an outline of the area a finger can
/// press it from.
class _Reach extends StatelessWidget {
  final Widget child;

  const _Reach({required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: context.colors.borderSubtle),
        borderRadius: BorderRadius.circular(context.radii.radiusSmall),
      ),
      child: SizedBox.square(dimension: 48, child: Center(child: child)),
    );
  }
}
