import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

class DescriptionListDemo extends StatelessWidget {
  @Preview(name: 'Description list', wrapper: adminUiPreview)
  const DescriptionListDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 620,
      children: [
        const DemoSection('Inline — record detail'),
        DescriptionList(
          items: [
            const DescriptionItem('Title', value: 'Spring campaign launch'),
            DescriptionItem(
              'Status',
              child: const Tag(
                'Published',
                severity: Severity.success,
                dot: true,
              ),
            ),
            DescriptionItem(
              'Author',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Avatar(initials: 'MC', size: 22),
                  const Gap(AdminSpacing.md),
                  Text('Maya Cohen', style: context.type.body),
                ],
              ),
            ),
            const DescriptionItem('Slug', value: 'spring-campaign-launch'),
            const DescriptionItem(
              'Published at',
              value: 'Jun 18, 2026 · 09:14',
            ),
            const DescriptionItem('Reviewer'), // empty → placeholder
          ],
        ),
        const Gap(AdminSpacing.xxxl),

        const DemoSection('Inline — two columns'),
        const DescriptionList(
          columns: 2,
          items: [
            DescriptionItem('First name', value: 'Maya'),
            DescriptionItem('Last name', value: 'Cohen'),
            DescriptionItem('Email', value: 'maya@example.com'),
            DescriptionItem('Phone', value: '+32 470 00 00 00'),
            DescriptionItem('Role', value: 'Editor'),
            DescriptionItem('Locale', value: 'en-GB'),
            DescriptionItem(
              'Bio',
              span: true,
              value:
                  'Long-form value spanning the full width of the list, so prose '
                  'and multi-line content keep a comfortable measure instead of '
                  'being crammed into a half-width column.',
            ),
          ],
        ),
        const Gap(AdminSpacing.xxxl),

        const DemoSection('Two columns in a 320px slot — drops to one'),
        const Align(
          alignment: AlignmentDirectional.centerStart,
          child: SizedBox(
            width: 320,
            child: DescriptionList(
              columns: 2,
              items: [
                DescriptionItem('First name', value: 'Maya'),
                DescriptionItem('Last name', value: 'Cohen'),
                DescriptionItem('Email', value: 'maya@example.com'),
                DescriptionItem('Phone', value: '+32 470 00 00 00'),
              ],
            ),
          ),
        ),
        const Gap(AdminSpacing.xxxl),

        const DemoSection('Stacked — grid of three'),
        DescriptionList(
          layout: DescriptionLayout.stacked,
          columns: 3,
          items: [
            const DescriptionItem('Views', value: '12,480'),
            const DescriptionItem('Conversion', value: '3.2%'),
            DescriptionItem(
              'Trend',
              child: const Tag('+8%', severity: Severity.success),
            ),
            const DescriptionItem('Bounce', value: '41%'),
            const DescriptionItem('Avg. time', value: '2m 14s'),
            const DescriptionItem('Sessions', value: '9,002'),
          ],
        ),
        const Gap(AdminSpacing.xxxl),

        const DemoSection('Widget values — hugging vs fill'),
        DescriptionList(
          items: [
            DescriptionItem(
              'Status',
              child: const Tag('Published', severity: Severity.success),
            ),
            const DescriptionItem(
              'Storage',
              child: ProgressBar(value: 0.62),
              fill: true,
            ),
          ],
        ),
        const Gap(AdminSpacing.xxxl),

        const DemoSection('Inline — undivided, narrow labels'),
        const DescriptionList(
          divided: false,
          labelWidth: 96,
          items: [
            DescriptionItem('ID', value: 'usr_8f21a0'),
            DescriptionItem('Plan', value: 'Pro'),
            DescriptionItem('Seats', value: '5 of 10'),
          ],
        ),
      ],
    );
  }
}
