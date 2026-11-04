import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../../demo_kit.dart';

class HelpDemo extends StatelessWidget {
  @Preview(name: 'Help', wrapper: adminUiPreview)
  const HelpDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      children: const [
        DemoVariant(
          'Open — the help card',
          PinnedOpen(
            makeRoom: true,
            child: FieldShell(
              label: 'Title',
              help: HelpButton(
                text:
                    'Renders as the page H1 and the browser tab. Keep it '
                    'under 60 characters so it isn’t truncated in search '
                    'results.',
              ),
              child: SizedBox.shrink(),
            ),
          ),
        ),
        DemoVariant(
          'Short help',
          FieldShell(
            label: 'Slug',
            help: HelpButton(text: 'The URL path for this page.'),
            child: TextBody(hint: 'about-us'),
          ),
        ),
        DemoVariant(
          'Long help (wraps in the popover)',
          FieldShell(
            label: 'Title',
            help: HelpButton(
              text:
                  'Renders as the page H1 and the browser tab. Keep '
                  'it under 60 characters so it isn’t truncated in search '
                  'engine results, and front-load the important words.',
            ),
            child: TextBody(),
          ),
        ),
        DemoVariant(
          'Help stays beside a long, truncated label',
          FieldShell(
            label:
                'A rather long field label that truncates beside its '
                'help affordance',
            help: HelpButton(text: 'Pinned next to the label.'),
            child: TextBody(hint: 'Type here…'),
          ),
        ),
      ],
    );
  }
}
