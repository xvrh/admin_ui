import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../../demo_fixtures.dart';
import '../../demo_kit.dart';

/// The "today" every field here marks and seeds from, so the page renders the
/// same on any day.
final _today = DateTime(2026, 6, 12);

final _published = DateTime(2026, 6, 20, 9, 0);

const _comments = [
  CommentEntry(
    author: 'Lena Fritz',
    initials: 'LF',
    color: Color(0xFFd97706),
    time: '3m',
    body: 'Can we push this to after the embargo lifts on the 22nd?',
  ),
];

final _versions = [
  FieldVersion(
    label: '18 Jun 2026 · 14:30',
    author: 'You',
    initials: 'Yo',
    color: const Color(0xFF5b5bd6),
    time: 'just now',
    current: true,
  ),
  FieldVersion(
    label: '20 Jun 2026 · 09:00',
    author: 'Diego Ruiz',
    initials: 'DR',
    color: const Color(0xFF0f9d8f),
    time: '4h ago',
  ),
];

/// The date / time field across granularities and states.
class DateFieldDemo extends StatelessWidget {
  @Preview(name: 'Date / time', wrapper: adminUiPreview)
  const DateFieldDemo({super.key});

  @override
  Widget build(BuildContext context) {
    // The locale rows read intl's date symbols for fr/de/ja/ar; the bundled
    // data loads synchronously, so the returned future needs no waiting on.
    initializeDateFormatting();
    return DemoPage(
      maxWidth: 460,
      children: [
        DemoSection('Date — press to open the editor + calendar'),
        DemoVariant(
          'Live — edit any cell, paste a full YYYY-MM-DD, or pick a day',
          _Live(label: 'Publish date', initial: DateTime(2026, 6, 18)),
        ),
        DemoVariant(
          'Empty — placeholder; the editor cells start blank',
          const _Live(label: 'Embargo until', hint: 'No embargo'),
        ),
        DemoSection('Date & time — calendar + time strip'),
        DemoVariant(
          'Live — pick day and time',
          _Live(
            label: 'Go live at',
            initial: DateTime(2026, 6, 18, 14, 30),
            granularity: DateGranularity.dateTime,
          ),
        ),
        DemoSection('Time only'),
        DemoVariant(
          'Live — hour : minute',
          _Live(
            label: 'Daily digest send',
            initial: DateTime(2026, 1, 1, 7, 0),
            granularity: DateGranularity.time,
          ),
        ),
        DemoSection('Range-constrained — days outside are disabled'),
        DemoVariant(
          'Bounded to this week',
          _Live(
            label: 'Event day',
            initial: DateTime(2026, 6, 12),
            min: DateTime(2026, 6, 8),
            max: DateTime(2026, 6, 14),
          ),
        ),
        DemoSection('Locale & format — same instant, localized everywhere'),
        _localeVariants(),
        DemoSection('Shared states'),
        DemoVariant(
          'Read-only — no onChanged: full contrast, no chevron, opens nothing',
          FieldShell(
            label: 'Created',
            child: DateBody(
              today: _today,
              value: DateTime(2026, 5, 2, 11, 18),
              granularity: DateGranularity.dateTime,
            ),
          ),
        ),
        DemoVariant(
          'Disabled — FieldStateScope(enabled: false)',
          FieldStateScope(
            enabled: false,
            child: _Live(
              label: 'Created',
              initial: DateTime(2026, 5, 2, 11, 18),
              granularity: DateGranularity.dateTime,
            ),
          ),
        ),
        DemoVariant(
          'Validation error — the outline turns red',
          _Live(
            label: 'Publish date',
            initial: DateTime(2026, 6, 1),
            error: 'Pick a day after the embargo.',
          ),
        ),
        DemoVariant(
          'Draft override — stands out (amber)',
          _Live(
            label: 'Publish date',
            initial: DateTime(2026, 6, 18),
            modified: true,
          ),
        ),
        DemoVariant(
          'Validation warning',
          _Live(
            label: 'Publish date',
            initial: DateTime(2026, 6, 1),
            warning: 'This date is in the past — it will publish on save.',
          ),
        ),
        DemoSection('Open — the editor above the calendar'),
        PinnedOpen(reserve: 420, child: const _Live(label: 'Embargo until')),
        DemoSection('All capabilities — help · comments · history'),
        DemoVariant(
          'Pick a time — it drives the draft and "Modified" tint',
          const _FullyLoaded(),
        ),
      ],
    );
  }

  static final _localeInstant = DateTime(2026, 6, 18, 14, 30);

  // (code, label, isRTL)
  static const _locales = [
    ('en_US', 'English (US)', false),
    ('en_GB', 'English (UK)', false),
    ('fr', 'French', false),
    ('de', 'German', false),
    ('es', 'Spanish', false),
    ('ja', 'Japanese', false),
    ('ar', 'Arabic (RTL)', true),
  ];

  Widget _localeVariants() {
    return Column(
      children: [
        for (var (code, label, rtl) in _locales)
          DemoVariant('$label · $code', _localeField(code, rtl)),
      ],
    );
  }

  Widget _localeField(String code, bool rtl) {
    var field = _Live(
      label: 'Published',
      initial: _localeInstant,
      granularity: DateGranularity.dateTime,
      locale: code,
    );
    return rtl
        ? Directionality(textDirection: TextDirection.rtl, child: field)
        : field;
  }
}

/// The date & time editor pinned open, so its cells, legend and calendar
/// can be checked in each direction and locale.
class DateFieldOpenDemo extends StatelessWidget {
  @Preview(name: 'Date / time · open', wrapper: adminUiPreview)
  const DateFieldOpenDemo({super.key});

  @override
  Widget build(BuildContext context) {
    initializeDateFormatting();
    return DemoPage(
      maxWidth: 460,
      children: [
        DemoSection('Date & time — the editor above the calendar'),
        PinnedOpen(
          reserve: 480,
          child: _Live(
            label: 'Go live at',
            initial: DateTime(2026, 6, 18, 14, 30),
            granularity: DateGranularity.dateTime,
          ),
        ),
      ],
    );
  }
}

class _Live extends StatefulWidget {
  final String label;
  final DateTime? initial;
  final DateGranularity granularity;
  final DateTime? min;
  final DateTime? max;
  final String? locale;
  final String? hint;
  final bool modified;
  final String? warning;
  final String? error;

  const _Live({
    required this.label,
    this.initial,
    this.granularity = DateGranularity.date,
    this.min,
    this.max,
    this.locale,
    this.hint,
    this.modified = false,
    this.warning,
    this.error,
  });

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  late DateTime? _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return FieldShell(
      label: widget.label,
      modified: widget.modified,
      warning: widget.warning,
      errorText: widget.error,
      child: DateBody(
        today: _today,
        value: _value,
        granularity: widget.granularity,
        min: widget.min,
        max: widget.max,
        locale: widget.locale,
        hint: widget.hint,
        onChanged: (v) => setState(() => _value = v),
      ),
    );
  }
}

/// One field wired with every capability slot. Picking a time updates the
/// draft, flipping the history chip to "Modified" and tinting the field until
/// reverted.
class _FullyLoaded extends StatefulWidget {
  const _FullyLoaded();

  @override
  State<_FullyLoaded> createState() => _FullyLoadedState();
}

class _FullyLoadedState extends State<_FullyLoaded> {
  DateTime? _value = DateTime(2026, 6, 18, 14, 30);
  final List<CommentEntry> _messages = [..._comments];

  final _fmt = DateFormat('d MMM y · HH:mm');

  @override
  Widget build(BuildContext context) {
    var modified = _value != _published;
    return FieldShell(
      label: 'Go live at',
      modified: modified,
      help: const HelpButton(
        text:
            'Scheduling a future time queues the entry; it publishes '
            'automatically when the moment arrives.',
      ),
      comments: CommentsButton(
        count: _messages.length,
        messages: _messages,
        onReply: (text) => setState(() => _messages.add(youReply(text))),
        onResolve: () => setState(_messages.clear),
      ),
      history: HistoryButton(
        draft: _value == null ? '—' : _fmt.format(_value!),
        baseline: _fmt.format(_published),
        versions: _versions,
        onRevert: () => setState(() => _value = _published),
      ),
      child: DateBody(
        today: _today,
        value: _value,
        granularity: DateGranularity.dateTime,
        clearable: false,
        onChanged: (v) => setState(() => _value = v),
      ),
    );
  }
}
