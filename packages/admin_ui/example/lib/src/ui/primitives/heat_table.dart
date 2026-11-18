import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

/// Twelve weekly sign-up cohorts, oldest first: the week they signed up in,
/// how many signed up, and how many of them were active one, two, … weeks
/// later, as far as the weeks have come. The newest week has none yet.
const _cohorts = [
  ('Mar 2', 1204, [702, 566, 494, 447, 410, 386, 364, 349, 335, 323, 314]),
  ('Mar 9', 1138, [649, 521, 455, 410, 378, 353, 333, 318, 307, 297]),
  ('Mar 16', 1290, [761, 619, 542, 490, 452, 425, 400, 384, 369]),
  ('Mar 23', 1175, [682, 552, 482, 435, 400, 376, 357, 341]),
  ('Mar 30', 986, [552, 444, 385, 345, 316, 296, 281]),
  // A holiday week: few sign-ups, and a week when none of them came back.
  ('Apr 6', 12, [5, 3, 0, 2, 1, 1]),
  ('Apr 13', 1342, [805, 657, 577, 523, 483]),
  ('Apr 20', 1267, [748, 608, 532, 481]),
  ('Apr 27', 1219, [707, 573, 500]),
  ('May 4', 1311, [787, 642]),
  ('May 11', 1256, [741]),
  ('May 18', 1188, <int>[]),
];

/// The retention grid an activity dashboard shows: a [HeatTable] in a
/// [ChartCard], at the page's width and at a phone's, where the weeks scroll
/// under the cohort labels.
class HeatTableDemo extends StatelessWidget {
  @Preview(name: 'Heat table / retention', wrapper: adminUiPreview)
  const HeatTableDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const DemoPage(
      maxWidth: 960,
      children: [
        DemoSection('Weekly retention'),
        _RetentionCard(),
        Gap(AdminSpacing.xxxl),
        DemoSection('At a phone’s width: the weeks scroll, the cohorts stay'),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: SizedBox(width: 340, child: _RetentionCard()),
        ),
      ],
    );
  }
}

class _RetentionCard extends StatelessWidget {
  const _RetentionCard();

  @override
  Widget build(BuildContext context) {
    final formats = context.adminFormats;
    final weeks = _cohorts.first.$3.length;
    return ChartCard(
      title: 'Weekly retention',
      subtitle: 'Who came back, by the week they signed up in',
      chart: HeatTable(
        labels: const [
          HeatTableLabel('Week of'),
          HeatTableLabel('People', numeric: true),
        ],
        columns: [for (var w = 1; w <= weeks; w++) '+$w'],
        rows: [
          for (final (week, size, active) in _cohorts)
            HeatTableRow(
              [week, formats.integer(size)],
              [for (final n in active) HeatTableCell(n / size)],
            ),
        ],
      ),
    );
  }
}
