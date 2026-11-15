import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

class ListRowDemo extends StatelessWidget {
  @Preview(name: 'List row', wrapper: adminUiPreview)
  const ListRowDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DemoPage(
      maxWidth: 900,
      children: [
        const DemoSection('Master list · split view (pick a row)'),
        const _MasterDetail(),
        const Gap(AdminSpacing.xxl),

        const DemoSection('Slots'),
        Panel(
          child: Column(
            children: [
              ListRow('Quarterly report.pdf', onTap: () {}),
              ListRow(
                'Quarterly report.pdf',
                subtitle: 'Finance · 2.4 MB',
                onTap: () {},
              ),
              ListRow(
                'Supplier contract.docx',
                subtitle: 'Legal · edited yesterday',
                leading: const Icon(Icons.description_outlined),
                trailing: const Text('3 versions'),
                onTap: () {},
              ),
              ListRow(
                'Order #10482',
                subtitle: 'Lena Ortiz · 3 items',
                leading: const Avatar(name: 'Lena Ortiz'),
                trailing: const Tag('Paid', severity: Severity.success),
                selected: true,
                onTap: () {},
              ),
              ListRow(
                'Order #10481',
                subtitle: 'Sam Patel · 1 item',
                leading: StatusDot(
                  color: colors.warning,
                  semanticLabel: 'Awaiting payment',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {},
              ),
            ],
          ),
        ),
        const Gap(AdminSpacing.xxl),

        const DemoSection('Rows that do not open (no onTap)'),
        Panel(
          child: Column(
            children: [
              const ListRow(
                'Invoice 2026-031.pdf',
                subtitle: 'Archived · read only',
                leading: Icon(Icons.inventory_2_outlined),
                trailing: Text('Mar 3'),
              ),
              ListRow(
                'Invoice 2026-032.pdf',
                subtitle: 'Uploading…',
                leading: const Icon(Icons.upload_file_outlined),
                trailing: StatusPill(_Status.queued.meta(context)),
              ),
            ],
          ),
        ),
        const Gap(AdminSpacing.xxl),

        const DemoSection('A long title in a narrow pane'),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: SizedBox(
            width: 300,
            child: Panel(
              child: ListRow(
                'deploy · release 4.2.0 to the production cluster, eu-west and '
                'us-east',
                subtitle:
                    'release/4.2 · 9c41e07 · started by the nightly schedule',
                leading: const Avatar(name: 'Nightly schedule'),
                trailing: StatusPill(_Status.running.meta(context)),
                selected: true,
                onTap: () {},
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum _Status {
  running,
  passed,
  failed,
  queued;

  StatusMeta meta(BuildContext context) {
    StatusMeta tone(Severity severity, String label) {
      final style = severityStyleOf(context, severity);
      return StatusMeta(label, style.accent, text: style.foreground);
    }

    return switch (this) {
      running => tone(Severity.info, 'Running'),
      passed => tone(Severity.success, 'Passed'),
      failed => tone(Severity.danger, 'Failed'),
      queued => StatusMeta(
        'Queued',
        context.colors.foregroundMuted,
        ring: true,
      ),
    };
  }
}

class _Job {
  final String name;
  final String branch;
  final String commit;
  final String started;
  final String duration;
  final String author;
  final _Status status;

  const _Job(
    this.name, {
    required this.branch,
    required this.commit,
    required this.started,
    required this.duration,
    required this.author,
    required this.status,
  });
}

const _jobs = [
  _Job(
    'web · release 4.2.0',
    branch: 'release/4.2',
    commit: '9c41e07',
    started: '2 min ago',
    duration: '1m 48s so far',
    author: 'Maya Cohen',
    status: _Status.running,
  ),
  _Job(
    'api · nightly',
    branch: 'main',
    commit: 'a1f9c3e',
    started: '6 h ago',
    duration: '12m 05s',
    author: 'Nightly schedule',
    status: _Status.failed,
  ),
  _Job(
    'web · pull request 1183',
    branch: 'fix/cart-totals',
    commit: '47be2d0',
    started: '8 h ago',
    duration: '6m 31s',
    author: 'Sam Patel',
    status: _Status.passed,
  ),
  _Job(
    'docs · publish',
    branch: 'main',
    commit: 'e02c118',
    started: 'queued',
    duration: '—',
    author: 'Lena Ortiz',
    status: _Status.queued,
  ),
  _Job(
    'mobile · beta',
    branch: 'release/4.2',
    commit: '9c41e07',
    started: 'yesterday',
    duration: '21m 40s',
    author: 'Maya Cohen',
    status: _Status.passed,
  ),
];

/// A master list of build jobs beside the picked job's detail.
class _MasterDetail extends StatefulWidget {
  const _MasterDetail();

  @override
  State<_MasterDetail> createState() => _MasterDetailState();
}

class _MasterDetailState extends State<_MasterDetail> {
  var _selected = 1;

  @override
  Widget build(BuildContext context) {
    final job = _jobs[_selected];
    return SizedBox(
      height: 340,
      child: Panel(
        child: SplitView.two(
          initialWeight: 0.45,
          minFirst: 240,
          minSecond: 240,
          first: ListView(
            padding: EdgeInsets.zero,
            children: [
              for (final (i, job) in _jobs.indexed)
                ListRow(
                  job.name,
                  subtitle: '${job.branch} · ${job.commit} · ${job.started}',
                  leading: Avatar(name: job.author),
                  trailing: StatusPill(job.status.meta(context)),
                  selected: i == _selected,
                  onTap: () => setState(() => _selected = i),
                ),
            ],
          ),
          second: ListView(
            padding: const EdgeInsets.all(AdminSpacing.xl),
            children: [
              Text(job.name, style: context.type.heading),
              const Gap(AdminSpacing.sm),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: StatusPill(job.status.meta(context)),
              ),
              const Gap(AdminSpacing.lg),
              DescriptionList(
                items: [
                  DescriptionItem('Branch', value: job.branch),
                  DescriptionItem('Commit', value: job.commit),
                  DescriptionItem('Started', value: job.started),
                  DescriptionItem('Duration', value: job.duration),
                  DescriptionItem('Triggered by', value: job.author),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
