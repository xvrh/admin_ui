import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart' show Bidi;
import 'package:material_ui/material_ui.dart';

import '../../common/ui/field_chrome.dart';
import '../../common/ui/icon_action.dart';
import '../../common/ui/input_decoration.dart';
import '../../common/ui/labeled_field.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'field_primitives.dart';

/// The bare key→value control — an ordered list of editable `key`/`value` rows
/// with add and remove, no label or capability chrome. Like the other bodies it
/// sits inside a [FieldShell] or one lane of a translatable field. The value is
/// an ordered `Map<String, String>` (think SEO meta, HTTP headers, env vars, a
/// loose settings blob).
///
/// Keys are typed left to right in any language, like the identifiers they
/// usually are; a value runs in the direction of its first letter, so a
/// token or a URL keeps its order in a right-to-left admin.
///
/// Rows are the editing surface, the map is the contract: a row with an empty
/// key is held while you type but never emitted, and when two rows share a key
/// the lower one wins — the colliding keys turn red and a message under the
/// rows says so, so it isn't silent.
///
/// A null [onChanged] renders the pairs read-only: full contrast, focusable
/// and selectable, no add or remove; with no pairs, the box shows
/// [emptyLabel]. [enabled] false, or a disabled [FieldStateScope], disables
/// it.
class KeyValueBody extends StatefulWidget {
  final Map<String, String> value;
  final ValueChanged<Map<String, String>>? onChanged;

  /// The key and value placeholders, and the add button's label; null reads
  /// "Key", "Value" and "Add row" in the app's language.
  final String? keyHint;
  final String? valueHint;
  final String? addLabel;

  /// Shown when read-only with no pairs; null reads "No entries".
  final String? emptyLabel;

  final bool enabled;

  const KeyValueBody({
    super.key,
    this.value = const {},
    this.onChanged,
    this.keyHint,
    this.valueHint,
    this.addLabel,
    this.emptyLabel,
    this.enabled = true,
  });

  @override
  State<KeyValueBody> createState() => _KeyValueBodyState();
}

class _Row {
  final TextEditingController key;
  final TextEditingController value;
  final FocusNode keyFocus;

  _Row(String k, String v)
    : key = TextEditingController(text: k),
      value = TextEditingController(text: v),
      keyFocus = FocusNode();

  void dispose() {
    key.dispose();
    value.dispose();
    keyFocus.dispose();
  }
}

class _KeyValueBodyState extends State<KeyValueBody> {
  late List<_Row> _rows = _seed();

  List<_Row> _seed() =>
      widget.value.entries.map((e) => _Row(e.key, e.value)).toList();

  @override
  void didUpdateWidget(covariant KeyValueBody old) {
    super.didUpdateWidget(old);
    // Reseed only when the value changes outside the field (revert, live-link).
    // Ordinary editing keeps [_emit] in sync, so this no-ops.
    if (!mapEquals(widget.value, _emit())) {
      for (final r in _rows) {
        r.dispose();
      }
      _rows = _seed();
    }
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  Map<String, String> _emit() {
    final out = <String, String>{};
    for (final r in _rows) {
      final k = r.key.text.trim();
      if (k.isEmpty) continue;
      out[k] = r.value.text;
    }
    return out;
  }

  void _notify() {
    widget.onChanged?.call(_emit());
    setState(() {}); // refresh duplicate-key flags
  }

  void _add() {
    setState(() => _rows.add(_Row('', '')));
    widget.onChanged?.call(_emit());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _rows.isNotEmpty) _rows.last.keyFocus.requestFocus();
    });
  }

  void _remove(int i) {
    setState(() => _rows.removeAt(i).dispose());
    widget.onChanged?.call(_emit());
  }

  Set<String> _duplicateKeys() {
    final seen = <String>{};
    final dups = <String>{};
    for (final r in _rows) {
      final k = r.key.text.trim();
      if (k.isEmpty) continue;
      if (!seen.add(k)) dups.add(k);
    }
    return dups;
  }

  @override
  Widget build(BuildContext context) {
    return FieldBodyScope(
      enabled: widget.enabled,
      readOnly: widget.onChanged == null,
      builder: _build,
    );
  }

  Widget _build(BuildContext context) {
    final state = FieldStateScope.of(context);
    final editable = state.enabled && !state.readOnly;
    final l10n = context.adminL10n;
    if (!editable && _rows.isEmpty) {
      return readOnlyEmpty(context, widget.emptyLabel ?? l10n.fields.noEntries);
    }

    final dups = _duplicateKeys();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _rows.length; i++) ...[
          if (i > 0) const Gap(AdminSpacing.sm),
          _RowEditor(
            row: _rows[i],
            keyHint: widget.keyHint ?? l10n.keyLabel,
            valueHint: widget.valueHint ?? l10n.valueLabel,
            duplicate: dups.contains(_rows[i].key.text.trim()),
            onChanged: _notify,
            onRemove: editable ? () => _remove(i) : null,
          ),
        ],
        if (dups.isNotEmpty) ...[
          const Gap(AdminSpacing.md),
          FieldMessage(
            error: dups.length == 1
                ? l10n.fields.duplicateKey(dups.single)
                : l10n.fields.duplicateKeys,
          ),
        ],
        if (editable) ...[
          if (_rows.isNotEmpty) const Gap(AdminSpacing.md),
          AddRowButton(label: widget.addLabel ?? l10n.addRow, onPressed: _add),
        ],
      ],
    );
  }
}

class _RowEditor extends StatelessWidget {
  final _Row row;
  final String keyHint;
  final String valueHint;
  final bool duplicate;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  const _RowEditor({
    required this.row,
    required this.keyHint,
    required this.valueHint,
    required this.duplicate,
    required this.onChanged,
    this.onRemove,
  });

  /// The direction of [text]'s first letter, or null (the ambient one)
  /// before it has any.
  static TextDirection? _directionOf(String text) => Bidi.startsWithRtl(text)
      ? TextDirection.rtl
      : Bidi.startsWithLtr(text)
      // Physical: the value's own direction.
      ? TextDirection.ltr
      : null;

  @override
  Widget build(BuildContext context) {
    final state = FieldStateScope.of(context);
    final style = fieldTextStyle(context);
    final valueDirection = _directionOf(row.value.text);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 5,
          child: TextField(
            controller: row.key,
            focusNode: row.keyFocus,
            readOnly: state.readOnly,
            onChanged: (_) => onChanged(),
            // Physical: a key is an identifier, read left to right.
            textDirection: TextDirection.ltr,
            style: style.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            decoration: fieldInputDecoration(
              context,
              hint: keyHint,
              invalid: duplicate,
              // Physical: the placeholder sits where the key starts.
            ).copyWith(hintTextDirection: TextDirection.ltr),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.sm),
          child: Icon(
            Icons.arrow_forward_rounded,
            size: context.iconSizes.sm,
            color: state.iconColor(context.colors),
          ),
        ),
        Expanded(
          flex: 7,
          child: TextField(
            controller: row.value,
            readOnly: state.readOnly,
            onChanged: (_) => onChanged(),
            textDirection: valueDirection,
            style: style,
            decoration: fieldInputDecoration(
              context,
              hint: valueHint,
            ).copyWith(hintTextDirection: valueDirection),
          ),
        ),
        if (onRemove != null) ...[
          const Gap(AdminSpacing.sm),
          IconAction(
            Icons.close_rounded,
            label: row.key.text.trim().isEmpty
                ? context.adminL10n.fields.removeRow
                : context.adminL10n.removeItem(row.key.text.trim()),
            size: IconActionSize.small,
            danger: true,
            onPressed: onRemove,
          ),
        ],
      ],
    );
  }
}
