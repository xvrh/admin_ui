import 'package:material_ui/material_ui.dart';

import '../../common/ui/input_decoration.dart';
import '../../l10n/formats.dart';
import '../../theme/sizes.dart';

/// One inline edit of a table cell: what `TableColumn.editBuilder` is handed
/// alongside the row.
///
/// The editor keeps a draft and tells the session how to save it through
/// [onCommit]; the table decides when. Enter, Tab and a tap outside the cell
/// [commit]; Escape [cancel]s, which closes the editor with nothing written.
/// An editor may call either itself too — a picker that commits on a pick.
///
/// A session ends once: after [commit] succeeds or [cancel] runs, both are
/// no-ops and [isActive] is false.
class EditSession {
  /// The column's label, for the editor's accessible name.
  final String label;

  final void Function(bool committed) _onEnd;

  /// Opens a session for the column [label]; `onEnd` runs once, with whether
  /// it committed. The table creates one per edit — build one directly only
  /// to host an editor elsewhere, such as a test.
  EditSession({required this.label, required this._onEnd});

  /// Saves the draft through the caller's closures. Returns false to keep
  /// the editor open — a draft that doesn't parse, say — and true once it is
  /// saved. Set by the editor, typically from `initState`; with none,
  /// [commit] just closes.
  bool Function()? onCommit;

  /// Undoes what the editor wrote before [commit] — only an editor that
  /// writes as the user types needs it. Runs on [cancel].
  VoidCallback? onCancel;

  bool _active = true;

  /// Whether the edit is still open.
  bool get isActive => _active;

  /// Saves and closes, unless [onCommit] refuses. Returns whether the edit
  /// closed.
  bool commit() {
    if (!_active) return false;
    if (onCommit?.call() == false) return false;
    _end(true);
    return true;
  }

  /// Closes without saving; [onCancel] runs first.
  void cancel() {
    if (!_active) return;
    onCancel?.call();
    _end(false);
  }

  void _end(bool committed) {
    _active = false;
    onCommit = null;
    onCancel = null;
    _onEnd(committed);
  }
}

/// The stock inline editor for a text or number cell: a small field in the
/// theme's field chrome that saves through [EditSession.onCommit], so Escape
/// leaves the value as it was.
///
/// The text starts selected, so typing replaces it. [TableTextEditor.number]
/// writes and reads the number in the app's notation ("12,5" in French),
/// parses on commit and keeps the editor open, marked invalid, while the
/// draft isn't a number; its figures are tabular and end-aligned like the
/// numeric column around it.
class TableTextEditor extends StatefulWidget {
  final EditSession session;

  /// Shown while the field is empty.
  final String? hint;

  /// The draft the editor opens with, in the notation of the formats it is
  /// given.
  final String Function(AdminFormats formats) _initialText;

  /// Saves the draft; false keeps the editor open, marked invalid.
  final bool Function(String text, AdminFormats formats) _save;

  final bool _numeric;

  /// Edits [value]; [onCommit] receives the text on commit.
  TableTextEditor({
    super.key,
    required this.session,
    required String value,
    required ValueChanged<String> onCommit,
    this.hint,
  }) : _initialText = ((_) => value),
       _numeric = false,
       _save = ((text, _) {
         onCommit(text);
         return true;
       });

  /// Edits the number [value], shown with [fractionDigits] decimals when
  /// set; [onCommit] receives the parsed number.
  TableTextEditor.number({
    super.key,
    required this.session,
    required num value,
    required ValueChanged<num> onCommit,
    int? fractionDigits,
    this.hint,
  }) : _initialText = ((formats) => fractionDigits == null
           ? formats.decimal(value, maxFractionDigits: 10)
           : formats.decimal(value, fractionDigits: fractionDigits)),
       _numeric = true,
       _save = ((text, formats) {
         final parsed = formats.parseDecimal(text);
         if (parsed == null) return false;
         onCommit(parsed);
         return true;
       });

  @override
  State<TableTextEditor> createState() => _TableTextEditorState();
}

class _TableTextEditorState extends State<TableTextEditor> {
  // First read by build, once [_formats] is set.
  late final _controller = () {
    final text = widget._initialText(_formats);
    return TextEditingController(text: text)
      ..selection = TextSelection(baseOffset: 0, extentOffset: text.length);
  }();
  bool _invalid = false;

  /// The app's notation, as of the last build: [_commit] can run from a
  /// key or a tap the table handles.
  late AdminFormats _formats;

  @override
  void initState() {
    super.initState();
    _bind();
  }

  @override
  void didUpdateWidget(TableTextEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) _bind();
  }

  void _bind() => widget.session.onCommit = _commit;

  bool _commit() {
    final saved = widget._save(_controller.text, _formats);
    if (!saved && mounted) setState(() => _invalid = true);
    return saved;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _formats = context.adminFormats;
    final numeric = widget._numeric;
    final style = fieldTextStyle(context);
    return MergeSemantics(
      child: Semantics(
        label: widget.session.label,
        child: TextField(
          controller: _controller,
          keyboardType: numeric
              ? const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                )
              : null,
          textAlign: numeric ? TextAlign.end : TextAlign.start,
          style: numeric
              ? style.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                )
              : style,
          decoration: fieldInputDecoration(
            context,
            hint: widget.hint,
            invalid: _invalid,
            size: ControlSize.small,
          ),
          onChanged: _invalid ? (_) => setState(() => _invalid = false) : null,
          onSubmitted: (_) => widget.session.commit(),
        ),
      ),
    );
  }
}
