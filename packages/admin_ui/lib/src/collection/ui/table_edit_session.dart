import 'dart:math' as math;
import 'dart:ui' show SemanticsValidationResult;

import 'package:material_ui/material_ui.dart';

import '../../common/ui/input_decoration.dart';
import '../../common/ui/labeled_field.dart';
import '../../common/ui/popover.dart';
import '../../common/ui/popover_menu.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../l10n/formats.dart';
import '../../theme/sizes.dart';
import '../../theme/spacing.dart';

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
/// writes and reads the number in the app's notation ("12,5" in French) and
/// parses it on commit; its figures are tabular and end-aligned like the
/// numeric column around it.
///
/// **Refusing a draft.** A number editor refuses text that is no number, and
/// what its `integer`, `min` and `max` rule out; either editor refuses what
/// its `validate` gives a message for. A draft refused is not saved: the
/// editor stays open, marked invalid, and says why on a card under the cell,
/// or over it where it does not fit below. The card takes no pointer and no
/// focus, follows the cell as the table scrolls, and goes once the draft is
/// edited. Escape still closes the editor with nothing written.
class TableTextEditor extends StatefulWidget {
  final EditSession session;

  /// Shown while the field is empty.
  final String? hint;

  /// The draft the editor opens with, in the notation of the formats it is
  /// given.
  final String Function(AdminFormats formats) _initialText;

  /// Saves the draft and answers null, or answers why it is refused: the
  /// editor then stays open, marked invalid, and shows the message.
  final String? Function(
    String text,
    AdminFormats formats,
    AdminLocalizations l10n,
  )
  _save;

  final bool _numeric;

  /// Whether a number's keyboard offers a decimal separator and a minus.
  final bool _decimal;
  final bool _signed;

  /// Edits [value]; [onCommit] receives the text on commit.
  ///
  /// [validate] is asked before the text is saved: a message refuses the
  /// draft and is shown under the cell, null lets it through. An empty
  /// message refuses it and shows none.
  TableTextEditor({
    super.key,
    required this.session,
    required String value,
    required ValueChanged<String> onCommit,
    String? Function(String value)? validate,
    this.hint,
  }) : _initialText = ((_) => value),
       _numeric = false,
       _decimal = false,
       _signed = false,
       _save = ((text, _, _) {
         final refused = validate?.call(text);
         if (refused != null) return refused;
         onCommit(text);
         return null;
       });

  /// Edits the number [value], shown with [fractionDigits] decimals when
  /// set; [onCommit] receives the parsed number.
  ///
  /// The draft is refused, each with a message in the app's language:
  ///
  /// - while it is no number in the app's notation;
  /// - with [integer], while it has a fraction: [onCommit] and [validate]
  ///   then receive an [int];
  /// - while it is below [min] or above [max];
  /// - while [validate] gives a message for it, which is the one shown. It
  ///   is asked last, and only about a number the rules above let through.
  ///   An empty message refuses the draft and shows none.
  TableTextEditor.number({
    super.key,
    required this.session,
    required num value,
    required ValueChanged<num> onCommit,
    int? fractionDigits,
    bool integer = false,
    num? min,
    num? max,
    String? Function(num value)? validate,
    this.hint,
  }) : assert(
         !integer || fractionDigits == null || fractionDigits == 0,
         'A whole number has no decimals to show',
       ),
       assert(
         min == null || max == null || min <= max,
         'No number is both $min or more and $max or less',
       ),
       _initialText = ((formats) => _shown(formats, value, fractionDigits)),
       _numeric = true,
       _decimal = !integer,
       _signed = min == null || min < 0,
       _save = ((text, formats, l10n) {
         final parsed = formats.parseDecimal(text);
         if (parsed == null ||
             !parsed.isFinite ||
             (integer && parsed != parsed.truncate())) {
           return l10n.fields.numberLike(
             integer
                 ? formats.decimal(1234, maxFractionDigits: 0)
                 : formats.decimal(1234.5, maxFractionDigits: 1),
           );
         }
         if ((min != null && parsed < min) || (max != null && parsed > max)) {
           String bound(num v) => _shown(formats, v, fractionDigits);
           return min != null && max != null
               ? l10n.fields.numberBetween(bound(min), bound(max))
               : min != null
               ? l10n.fields.numberAtLeast(bound(min))
               : l10n.fields.numberAtMost(bound(max!));
         }
         final number = integer ? parsed.toInt() : parsed;
         final refused = validate?.call(number);
         if (refused != null) return refused;
         onCommit(number);
         return null;
       });

  /// [value] as the editor writes a number: with [fractionDigits] decimals,
  /// or as many as it has.
  static String _shown(AdminFormats formats, num value, int? fractionDigits) =>
      fractionDigits == null
      ? formats.decimal(value, maxFractionDigits: 10)
      : formats.decimal(value, fractionDigits: fractionDigits);

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

  /// Why the draft was refused, while it stands as it was refused.
  String? _refused;

  /// The card that says [_refused], and what ties it to the field.
  final _card = OverlayPortalController();
  final _link = LayerLink();

  /// The app's notation and language, as of the last build: [_commit] can
  /// run from a key or a tap the table handles.
  late AdminFormats _formats;
  late AdminLocalizations _l10n;

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
    final refused = widget._save(_controller.text, _formats, _l10n);
    if (refused == null) return true;
    if (mounted) {
      setState(() => _refused = refused);
      refused.isEmpty ? _card.hide() : _card.show();
    }
    return false;
  }

  /// The draft is no longer the one refused.
  void _edited(String _) {
    _card.hide();
    setState(() => _refused = null);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _formats = context.adminFormats;
    _l10n = context.adminL10n;
    final numeric = widget._numeric;
    final refused = _refused;
    final style = fieldTextStyle(context);
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _card,
        overlayChildBuilder: (_) => _Refusal(
          link: _link,
          field: context,
          message: refused ?? '',
          numeric: numeric,
        ),
        child: MergeSemantics(
          child: Semantics(
            label: widget.session.label,
            hint: refused == null || refused.isEmpty ? null : refused,
            validationResult: refused == null
                ? SemanticsValidationResult.none
                : SemanticsValidationResult.invalid,
            child: TextField(
              controller: _controller,
              keyboardType: numeric
                  ? TextInputType.numberWithOptions(
                      decimal: widget._decimal,
                      signed: widget._signed,
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
                invalid: refused != null,
                size: ControlSize.small,
              ),
              onChanged: refused != null ? _edited : null,
              onSubmitted: (_) => widget.session.commit(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Why a cell's draft was refused, on a card beside the cell's editor.
///
/// The card is placed as a popover is: under the editor, or over it where
/// it does not fit below and there is more room above; lined up with the
/// edge the cell's content ends on for a number and starts on for text; and
/// kept inside the window. It is tied to the editor's layer, so it moves
/// with the cell as the table scrolls. It takes no pointer: a tap on it
/// lands on what is under it, as a tap outside the editor.
class _Refusal extends StatelessWidget {
  final LayerLink link;

  /// The editor: where the card stands is read from its box.
  final BuildContext field;
  final String message;
  final bool numeric;

  const _Refusal({
    required this.link,
    required this.field,
    required this.message,
    required this.numeric,
  });

  /// The widest a card gets; a longer message wraps.
  static const _maxWidth = 280.0;

  @override
  Widget build(BuildContext context) {
    final overlay = Overlay.of(context).context.findRenderObject();
    final box = field.findRenderObject();
    if (overlay is! RenderBox || box is! RenderBox || !box.hasSize) {
      return const SizedBox.shrink();
    }
    // Read as a tooltip reads its target: the editor was laid out in an
    // earlier frame, since a draft is refused in an editor that is open.
    final cell = box.localToGlobal(Offset.zero, ancestor: overlay) & box.size;
    // The follower is the overlay's size, its corner on the editor's: the
    // card is placed in the overlay, and again when the window is resized,
    // then moves as the editor does.
    return CompositedTransformFollower(
      link: link,
      showWhenUnlinked: false,
      child: IgnorePointer(
        child: CustomSingleChildLayout(
          delegate: _BesideCell(
            cell: cell,
            numeric: numeric,
            textDirection: Directionality.of(context),
          ),
          child: PopoverMenuSurface(
            maxWidth: _maxWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AdminSpacing.lg,
                vertical: AdminSpacing.md,
              ),
              child: FieldMessage(error: message),
            ),
          ),
        ),
      ),
    );
  }
}

/// Places a refusal's card beside [cell], the editor's box in the overlay,
/// and answers where that is from the editor's corner.
class _BesideCell extends SingleChildLayoutDelegate {
  final Rect cell;
  final bool numeric;
  final TextDirection textDirection;

  const _BesideCell({
    required this.cell,
    required this.numeric,
    required this.textDirection,
  });

  /// Between the editor and the card.
  static const _gap = AdminSpacing.xs;

  /// What the card keeps from the window's edges.
  static const _margin = AdminSpacing.md;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(
        maxWidth: math.max(constraints.maxWidth - _margin * 2, 0),
        maxHeight: constraints.maxHeight,
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) =>
      placePopover(
        anchor: cell,
        child: childSize,
        viewport: size,
        side: PopoverSide.bottom,
        align: numeric ? PopoverAlign.end : PopoverAlign.start,
        gap: _gap,
        textDirection: textDirection,
        margin: _margin,
      ).offset -
      cell.topLeft;

  @override
  bool shouldRelayout(_BesideCell old) =>
      old.cell != cell ||
      old.numeric != numeric ||
      old.textDirection != textDirection;
}
