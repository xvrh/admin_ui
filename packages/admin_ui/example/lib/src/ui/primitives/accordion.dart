import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

/// The accordion's modes, plus a header holding keyboard focus: the
/// keyboard highlight is forced on while this page is up so the ring shows in
/// a static render.
class AccordionDemo extends StatefulWidget {
  @Preview(name: 'Accordion', wrapper: adminUiPreview)
  const AccordionDemo({super.key});

  @override
  State<AccordionDemo> createState() => _AccordionDemoState();
}

class _AccordionDemoState extends State<AccordionDemo> {
  final _focusScope = FocusScopeNode(debugLabel: 'Accordion focus demo');

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
        maxWidth: 560,
        children: [
          const DemoSection('Single open (default), first section opened'),
          Accordion(
            initiallyOpen: const {0},
            sections: [
              AccordionSection(
                title: 'General',
                subtitle: 'Name, description, visibility',
                icon: Icons.tune_rounded,
                child: const Text(
                  'Settings that apply across the whole workspace. Only one '
                  'section stays open at a time here.',
                ),
              ),
              AccordionSection(
                title: 'Members',
                subtitle: '12 people',
                icon: Icons.group_rounded,
                child: const Text('Invite, remove, and set roles for members.'),
              ),
              AccordionSection(
                title: 'Danger zone',
                icon: Icons.warning_amber_rounded,
                child: Button.danger(
                  'Delete workspace',
                  size: ControlSize.small,
                  onPressed: () {},
                ),
              ),
            ],
          ),
          const Gap(AdminSpacing.xxxl),

          const DemoSection('Multiple open'),
          const Accordion(
            multiple: true,
            initiallyOpen: {0, 1},
            sections: [
              AccordionSection(
                title: 'Shipping',
                child: Text('Ships in 2–4 business days.'),
              ),
              AccordionSection(
                title: 'Returns',
                child: Text('30-day returns on unused items.'),
              ),
              AccordionSection(
                title: 'Warranty',
                child: Text('One-year limited warranty.'),
              ),
            ],
          ),
          const Gap(AdminSpacing.xxxl),

          const DemoSection('Controlled — opened from outside'),
          const _Controlled(),
          const Gap(AdminSpacing.xxxl),

          const DemoSection('Keyboard focus on the first header'),
          FocusScope(
            node: _focusScope,
            child: const Accordion(
              sections: [
                AccordionSection(
                  title: 'Focused',
                  subtitle: 'Arrow keys move between headers',
                  child: Text('Enter or Space opens a section.'),
                ),
                AccordionSection(title: 'Next', child: Text('Next section.')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The host owns the open set, so a validation error (or a deep link) can
/// expand the section it points at.
class _Controlled extends StatefulWidget {
  const _Controlled();

  @override
  State<_Controlled> createState() => _ControlledState();
}

class _ControlledState extends State<_Controlled> {
  Set<int> _open = const {1};

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AdminSpacing.sm,
          runSpacing: AdminSpacing.sm,
          children: [
            Button(
              'Show the billing error',
              size: ControlSize.small,
              onPressed: () => setState(() => _open = const {2}),
            ),
            Button.ghost(
              'Collapse all',
              size: ControlSize.small,
              onPressed: () => setState(() => _open = const {}),
            ),
          ],
        ),
        const Gap(AdminSpacing.lg),
        Accordion(
          open: _open,
          onOpenChanged: (open) => setState(() => _open = open),
          sections: const [
            AccordionSection(
              title: 'Profile',
              subtitle: 'Name and avatar',
              child: Text('Display name and a square avatar.'),
            ),
            AccordionSection(
              title: 'Notifications',
              subtitle: 'Email and in-app',
              child: Text('Choose which events send an email.'),
            ),
            AccordionSection(
              title: 'Billing',
              subtitle: '1 problem',
              icon: Icons.error_outline_rounded,
              child: Text('The card on file expired last month.'),
            ),
          ],
        ),
      ],
    );
  }
}
