import 'dart:async';

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

/// The [LogView] primitive: a job's output as lines of monospaced text. A
/// finished deploy opened on its last line, an empty log, and a live one to
/// try following by hand.
class LogViewDemo extends StatelessWidget {
  @Preview(name: 'Log view', wrapper: adminUiPreview)
  const LogViewDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 640,
      children: [
        Text(
          'The output of a job as it runs or after: a deploy, an import, a '
          'build. It opens on the last line and keeps it in view while lines '
          'arrive; scroll up to read and it stays put until you are back at '
          'the end. Lines wrap, prefixes line up, and a selection copies '
          'whole lines.',
          style: TextStyle(color: context.colors.foregroundMuted, height: 1.5),
        ),
        const Gap(AdminSpacing.xxl),
        const DemoVariant(
          'A finished deploy, opened on its last line: a warning, a failed '
          'check, and a line that wraps',
          SizedBox(height: 240, child: LogView(lines: _deploy)),
        ),
        const DemoVariant(
          'No lines yet',
          SizedBox(height: 96, child: LogView(lines: [])),
        ),
        const DemoVariant(
          'Live: add lines, scroll up and add more, then scroll back down',
          _LiveLog(),
        ),
      ],
    );
  }
}

const _deploy = [
  LogLine('Deploy web 4f2a9c1 to staging', prefix: '0.0 s'),
  LogLine('Fetching the release manifest', prefix: '0.2 s'),
  LogLine('Pulling registry.example.com/web:4f2a9c1', prefix: '0.4 s'),
  LogLine('Pulled 9 layers, 148 MB', prefix: '3.8 s'),
  LogLine('Starting 3 new instances', prefix: '4.1 s'),
  LogLine('Instance web-7d4f ready', prefix: '6.9 s'),
  LogLine('Instance web-91c0 ready', prefix: '7.2 s'),
  LogLine('Instance web-c3e8 ready', prefix: '7.4 s'),
  LogLine('Running migrations', prefix: '7.5 s'),
  LogLine('Applied 0042_add_order_notes', prefix: '8.9 s'),
  LogLine('Applied 0043_index_orders_by_date', prefix: '9.6 s'),
  LogLine(
    'Migration 0043 held a lock on orders for 640 ms',
    prefix: '9.6 s',
    severity: Severity.warning,
  ),
  LogLine('Uploading static assets', prefix: '9.8 s'),
  LogLine(
    'Uploaded 312 files, 18.4 MB, to https://cdn.example.com/web/4f2a9c1/ '
    'with a year of cache on hashed files and five minutes on the rest',
    prefix: '14.2 s',
  ),
  LogLine(
    'Health check https://staging.example.com/healthz failed: 503 Service '
    'Unavailable',
    prefix: '14.5 s',
    severity: Severity.danger,
  ),
  LogLine('Health check passed on the second try', prefix: '19.5 s'),
  LogLine('Switched traffic to 4f2a9c1', prefix: '19.7 s'),
  LogLine(
    'Deploy finished in 19.8 s',
    prefix: '19.8 s',
    severity: Severity.success,
  ),
];

/// What the live log's build prints, over and over.
const _steps = [
  'Resolving dependencies',
  'Compiling lib/src/orders/order_table.dart',
  'Compiling lib/src/orders/order_detail.dart',
  'Running 214 tests',
  'Bundling assets',
  'Writing build/web/main.dart.js',
];

/// A log that grows when asked: a line or a burst at a time, or one line
/// every few tenths of a second once started. Nothing runs until a button
/// is pressed, so a still preview stays still.
class _LiveLog extends StatefulWidget {
  const _LiveLog();

  @override
  State<_LiveLog> createState() => _LiveLogState();
}

class _LiveLogState extends State<_LiveLog> {
  final _lines = <LogLine>[];
  var _follow = true;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  LogLine _next() {
    final n = _lines.length;
    final prefix = '${(n * 0.7).toStringAsFixed(1)} s';
    if (n % 23 == 22) {
      return LogLine(
        'Test "exports a report" failed: expected 12 rows, found 11',
        prefix: prefix,
        severity: Severity.danger,
      );
    }
    if (n % 9 == 8) {
      return LogLine(
        'The --legacy-assets flag is deprecated',
        prefix: prefix,
        severity: Severity.warning,
      );
    }
    return LogLine(_steps[n % _steps.length], prefix: prefix);
  }

  void _add(int count) => setState(() {
    for (var i = 0; i < count; i++) {
      _lines.add(_next());
    }
  });

  void _run() {
    if (_timer != null) {
      _timer!.cancel();
      setState(() => _timer = null);
      return;
    }
    setState(() {
      _timer = Timer.periodic(
        const Duration(milliseconds: 400),
        (_) => _add(1),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AdminSpacing.md,
          runSpacing: AdminSpacing.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Button('Add a line', onPressed: () => _add(1)),
            Button('Add 200 lines', onPressed: () => _add(200)),
            Button(
              _timer == null ? 'Run' : 'Pause',
              icon: _timer == null
                  ? Icons.play_arrow_rounded
                  : Icons.pause_rounded,
              onPressed: _run,
            ),
            Toggle(
              value: _follow,
              label: 'Follow',
              onChanged: (v) => setState(() => _follow = v),
            ),
          ],
        ),
        const Gap(AdminSpacing.md),
        SizedBox(
          height: 240,
          child: LogView(
            lines: _lines,
            follow: _follow,
            emptyText: 'Press Run, or add a line',
          ),
        ),
      ],
    );
  }
}
