import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../../demo_kit.dart';

/// The "today" every field here marks, so the page renders the same on any
/// day.
final _today = DateTime(2026, 6, 12);

/// The [DateBody] popover with its segmented cells swapped for a single masked
/// field (`editor: DateEditorStyle.masked`). Same trigger + calendar; open one
/// and type or paste into the field at the top of the popover. The side-by-side
/// section pairs it against the current segmented editor.
class MaskedDateFieldDemo extends StatelessWidget {
  @Preview(name: 'Date · masked (experimental)', wrapper: adminUiPreview)
  const MaskedDateFieldDemo({super.key});

  @override
  Widget build(BuildContext context) {
    // The locale rows read intl's date symbols; the bundled data loads
    // synchronously, so the returned future needs no waiting on.
    initializeDateFormatting();
    return DemoPage(
      maxWidth: 460,
      children: [
        DemoSection('Masked editor inside the popover'),
        DemoVariant(
          'Date · open, then type or paste "2026-06-18"',
          const _Live(label: 'Publish date'),
        ),
        DemoVariant(
          'Date & time',
          _Live(
            label: 'Goes live',
            granularity: DateGranularity.dateTime,
            initial: _instant,
          ),
        ),
        DemoVariant(
          'Time only',
          const _Live(label: 'Daily digest', granularity: DateGranularity.time),
        ),
        DemoSection('Inline mode — masked field + calendar button, no popover'),
        DemoVariant(
          'Date · type/paste directly; button opens the calendar',
          _Live(
            label: 'Publish date',
            editor: DateEditorStyle.inline,
            initial: _instant,
          ),
        ),
        DemoVariant(
          'Date & time · inline',
          _Live(
            label: 'Goes live',
            editor: DateEditorStyle.inline,
            granularity: DateGranularity.dateTime,
            initial: _instant,
          ),
        ),
        DemoSection('Same field, both editors — open each and compare paste'),
        const _Pair(),
        DemoSection('Locale order — the ghost shows the part order'),
        for (final (code, label) in _locales)
          DemoVariant(
            '$label · $code',
            _Live(label: 'Date', locale: code, initial: _instant),
          ),
      ],
    );
  }

  static final _instant = DateTime(2026, 6, 18, 14, 30);

  static const _locales = [
    ('en_US', 'English (US)'),
    ('en_GB', 'English (UK)'),
    ('fr', 'French'),
    ('ja', 'Japanese'),
  ];
}

class _Live extends StatefulWidget {
  final String label;
  final DateGranularity granularity;
  final DateTime? initial;
  final String? locale;
  final DateEditorStyle editor;

  const _Live({
    required this.label,
    this.granularity = DateGranularity.date,
    this.initial,
    this.locale,
    this.editor = DateEditorStyle.masked,
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
      child: DateBody(
        today: _today,
        value: _value,
        granularity: widget.granularity,
        locale: widget.locale,
        editor: widget.editor,
        onChanged: (v) => setState(() => _value = v),
      ),
    );
  }
}

/// One value behind two triggers — open each popover to compare the segmented
/// cells against the masked field.
class _Pair extends StatefulWidget {
  const _Pair();

  @override
  State<_Pair> createState() => _PairState();
}

class _PairState extends State<_Pair> {
  DateTime? _value = DateTime(2026, 6, 18);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FieldShell(
          label: 'Segmented editor',
          child: DateBody(
            today: _today,
            value: _value,
            onChanged: (v) => setState(() => _value = v),
          ),
        ),
        const Gap(AdminSpacing.lg),
        FieldShell(
          label: 'Masked editor',
          child: DateBody(
            today: _today,
            value: _value,
            editor: DateEditorStyle.masked,
            onChanged: (v) => setState(() => _value = v),
          ),
        ),
      ],
    );
  }
}
