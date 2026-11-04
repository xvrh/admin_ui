/// @docImport 'value_form_controller.dart';
library;

import 'package:flutter/foundation.dart' show internal, mapEquals;
import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

import '../assets/ui/asset_body.dart';
import '../assets/ui/asset_drop_target.dart' show AssetAccept;
import '../comments/comment_anchors.dart'
    show CommentAnnotationRegistry, CommentSelectionAnchor;
import '../comments/ui/comment_field_button.dart';
import '../common/ui/field_chrome.dart';
import '../common/ui/input_decoration.dart';
import '../fields/ui/boolean_body.dart';
import '../fields/ui/change_scope.dart';
import '../fields/ui/color_body.dart';
import '../fields/ui/date_body.dart';
import '../fields/ui/field_shell.dart';
import '../fields/ui/key_value_body.dart';
import '../fields/ui/lane_stack.dart';
import '../fields/ui/masked_body.dart';
import '../fields/ui/media_body.dart' show MediaKind;
import '../fields/ui/multi_select_body.dart';
import '../fields/ui/number_body.dart';
import '../fields/ui/reference_body.dart';
import '../fields/ui/repeater.dart';
import '../fields/ui/select_body.dart';
import '../fields/ui/tags_body.dart';
import '../fields/ui/text_body.dart';
import '../i18n/lang_scope.dart';
import '../i18n/locale_status.dart';
import '../l10n/admin_ui_localizations.dart';
import '../theme/tokens.dart';
import 'cell.dart';
import 'field_binder.dart';
import 'form_controller.dart';
import 'value_form.dart';

// ── L1 capability scopes: ambient, optional, keyed by capability id ─────────
/// Provides the comments capability to every field beneath it, sidebar-primary:
/// each field/lane shows a [CommentFieldButton] with its open-thread count, and
/// tapping it signals [onCommentField] (the host opens the sidebar with the
/// composer anchored there). Absent from the tree ⇒ no comment chrome anywhere.
///
/// `listenable` (typically the comments controller) rebuilds dependents when
/// counts change.
class CommentsScope extends InheritedNotifier<Listenable> {
  /// Unresolved thread count anchored at a field/lane id (locale-qualified
  /// sub-paths count toward their base field).
  final int Function(String id) openCountFor;
  final void Function(String id) onCommentField;

  /// Text-range intents for body editors; null disables selection comments.
  final void Function(CommentSelectionAnchor anchor)? onCommentSelection;

  /// Tap on a highlight's margin pin — open the range's thread.
  final void Function(String annotationId)? onOpenAnnotation;

  /// Annotation ids of unresolved text-range threads (the highlights to
  /// render). Read live so counts follow the feed.
  final Set<String> Function()? openAnnotationIds;

  /// The annotation of the selected thread — its highlight is emphasised.
  final String? activeAnnotationId;

  /// Mounted body editors register their annotation stores here so thread
  /// deletion can remove the backing annotation.
  final CommentAnnotationRegistry? annotations;

  const CommentsScope({
    super.key,
    Listenable? listenable,
    required this.openCountFor,
    required this.onCommentField,
    this.onCommentSelection,
    this.onOpenAnnotation,
    this.openAnnotationIds,
    this.activeAnnotationId,
    this.annotations,
    required super.child,
  }) : super(notifier: listenable);

  static CommentsScope? maybeOf(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<CommentsScope>();

  Widget buttonFor(String id) => CommentFieldButton(
    count: openCountFor(id),
    onTap: () => onCommentField(id),
  );
}

/// Validation messages for the fields beneath it, keyed by field id (a
/// [Cell.id]) — typically a [FormController]'s [FormController.errors]. Every
/// preset looks its cell's message up here through [bind]; a preset's own
/// `errorText` wins. The message shows under the field and turns its body red.
///
/// A screen wraps its form once, in a [FormErrorsScope] of its controller
/// (which rebuilds this as the errors change), so the fields show the
/// messages its `FormSaveBar` or `FormActions` counts.
///
/// Each field also registers under the same id with the ambient
/// `FormFieldScope`, so the save flow can move focus to the first invalid
/// one through its `FormFieldRegistry`. Only a field whose own message
/// changed rebuilds.
class FieldErrorsScope extends InheritedModel<String> {
  final Map<String, String?> errors;

  const FieldErrorsScope({
    super.key,
    required this.errors,
    required super.child,
  });

  /// The message for [fieldId] under the nearest scope, or null.
  static String? errorOf(BuildContext context, String fieldId) =>
      InheritedModel.inheritFrom<FieldErrorsScope>(
        context,
        aspect: fieldId,
      )?.errors[fieldId];

  @override
  bool updateShouldNotify(FieldErrorsScope old) =>
      !mapEquals(errors, old.errors);

  @override
  bool updateShouldNotifyDependent(
    FieldErrorsScope old,
    Set<String> dependencies,
  ) => dependencies.any((id) => errors[id] != old.errors[id]);
}

/// A [FieldErrorsScope] of [controller]'s [FormController.errors], kept
/// current as they change: what an editing screen puts around its form, so
/// a field the save status counts as invalid shows why.
class FormErrorsScope extends StatelessWidget {
  final FormController controller;
  final Widget child;

  const FormErrorsScope({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) =>
          FieldErrorsScope(errors: controller.errors, child: child!),
      child: child,
    );
  }
}

// ── The binder: one body, single or per-lane, decided by the cell ───────────
/// Renders [body] for [cell] — once for a scalar, or once per visible language
/// (with the language chrome) for a translated one — inside a [FieldShell]. The
/// single place the single/lane split + the shell live; every preset delegates
/// here, so translation is an orthogonal axis over any field type, never a
/// per-type widget. [body] is handed one lane's [ValueCell] at a time.
///
/// [required], [description], [enabled], [readOnly], [errorText] and
/// [warning] go to the [FieldShell], which carries the state to the body.
/// With no [errorText] the cell's message comes from the ambient
/// [FieldErrorsScope].
/// [mergeSemantics] is the shell's, for a scalar: say true for a body that
/// is one button-like control (a select trigger, a switch). Language lanes
/// always keep their controls apart.
///
/// An ambient [FieldBinder] ([FieldBinderScope]) is asked first, and may
/// render the cell its own way; otherwise it gives the language lanes their
/// status and re-translate action. A cell that is neither a [ValueCell] nor a
/// [TranslatedCell] needs a binder that takes it: `bind` throws on one no
/// binder rendered.
///
/// Under a [ValueForm] the form's rules have their say, read for this cell
/// alone so no other field rebuilds: a `Validators.required()` rule marks the
/// field [required] as the flag does, and while a `visibleWhen` hides it the
/// field folds away and leaves the tree, so it takes no focus and is no
/// longer in the form's registry.
Widget bind<V>(
  BuildContext context,
  Cell<V> cell, {
  required String label,
  Widget? help,
  bool required = false,
  String? description,
  bool enabled = true,
  bool readOnly = false,
  String? errorText,
  String? warning,
  bool mergeSemantics = false,
  required Widget Function(ValueCell<V> lane) body,
  Widget Function(ValueCell<V> lane, String lang)? laneBody,
}) {
  final binder = FieldBinderScope.maybeOf(context);
  final binding = FieldBinding<V>(
    label: label,
    help: help,
    required: required || ValueFormScope.isRequired(context, cell.id),
    description: description,
    enabled: enabled,
    readOnly: readOnly,
    errorText: errorText ?? FieldErrorsScope.errorOf(context, cell.id),
    warning: warning,
    mergeSemantics: mergeSemantics,
    body: body,
    laneBody: laneBody,
  );
  return _FieldVisibility.wrap(
    context,
    visible: ValueFormScope.isVisible(context, cell.id),
    child:
        binder?.bind<V>(context, cell, binding) ??
        _kitField(context, cell, binding, binder),
  );
}

/// The kit's own field for [cell], which no [binder] took.
Widget _kitField<V>(
  BuildContext context,
  Cell<V> cell,
  FieldBinding<V> b,
  FieldBinder? binder,
) {
  switch (cell) {
    case ValueCell<V>():
      return ValueListenableBuilder<V>(
        valueListenable: cell,
        builder: (context, value, _) => FieldShell(
          label: b.label,
          fieldId: cell.id,
          help: b.help,
          comments: CommentsScope.maybeOf(context)?.buttonFor(cell.id),
          modified: ChangeScope.summaryOf(context, cell.id).modified,
          required: b.required,
          description: b.description,
          enabled: b.enabled,
          readOnly: b.readOnly,
          errorText: b.errorText,
          warning: b.warning,
          mergeSemantics: b.mergeSemantics,
          child: b.body(cell),
        ),
      );
    case TranslatedCell<V>():
      final lang = LangScope.of(context);
      final comments = CommentsScope.maybeOf(context);
      final editable = b.enabled && !b.readOnly;
      final laneBody = b.laneBody;
      // Listen to every locale lane (not just the active one) so the per-lane
      // translation-status chrome tracks edits live. The modified marker itself
      // reads the ambient change index.
      final allLanes = [for (final l in lang.locales) cell.lane(l.code)];
      return ListenableBuilder(
        listenable: Listenable.merge(allLanes),
        builder: (context, _) {
          final lanes = [
            for (final l in lang.locales)
              if (lang.visibleLocales.contains(l.code))
                switch (binder?.laneStatus(context, cell, l.code)) {
                  final status? => l.copyWith(status: status),
                  null => l,
                },
          ];
          final retranslate = {
            if (editable && binder != null)
              for (final l in lanes)
                l.code: ?binder.retranslate(context, cell, l.code),
          };
          final summary = ChangeScope.summaryOf(context, cell.id);
          return FieldShell(
            label: b.label,
            fieldId: cell.id,
            help: b.help,
            comments: comments?.buttonFor(cell.id),
            modified: summary.modified,
            modifiedDetail: modifiedLocalesDetail(lang.locales, summary.lanes),
            required: b.required,
            description: b.description,
            enabled: b.enabled,
            readOnly: b.readOnly,
            errorText: b.errorText,
            warning: b.warning,
            child: LaneStack(
              lanes: lanes,
              activeLocale: lang.activeLocale,
              modifiedLanes: summary.lanes,
              laneBuilder: (l) => KeyedSubtree(
                key: ValueKey('lane-${l.code}'),
                child: laneBody != null
                    ? laneBody(cell.lane(l.code), l.code)
                    : b.body(cell.lane(l.code)),
              ),
              laneTrailing: (l) => comments?.buttonFor(cell.lane(l.code).id),
              retranslate: (l) => retranslate[l.code],
            ),
          );
        },
      );
    default:
      throw FlutterError(
        'bind() cannot render the cell "${cell.id}", a ${cell.runtimeType}.\n'
        'The kit renders a ValueCell or a TranslatedCell, and no FieldBinder '
        'above the field took this one.\n'
        'Make ${cell.runtimeType} implement ValueCell or TranslatedCell, or '
        'mount a FieldBinderScope whose FieldBinder renders it.',
      );
  }
}

/// Folds [child] away while the enclosing [ValueForm]'s rules hide
/// [fieldId], as [bind] does for the fields it renders: for a field that
/// builds its own [FieldShell]. Outside a form it returns [child].
@internal
Widget foldWhenHidden(BuildContext context, String fieldId, Widget child) =>
    _FieldVisibility.wrap(
      context,
      visible: ValueFormScope.isVisible(context, fieldId),
      child: child,
    );

/// Folds a field away while a [ValueForm]'s rules hide it: its height eases
/// to nothing over the theme's medium duration, clipped as it goes, and then
/// the field leaves the tree; shown again, it is built afresh and unfolds.
/// Under reduced motion it goes and comes at once. While folding it takes no
/// pointer, focus or semantics.
///
/// A field outside any [ValueForm] is always shown, and returned as it is.
class _FieldVisibility extends StatefulWidget {
  final bool visible;
  final Widget child;

  const _FieldVisibility({required this.visible, required this.child});

  static Widget wrap(
    BuildContext context, {
    required bool visible,
    required Widget child,
  }) {
    if (context.getInheritedWidgetOfExactType<ValueFormScope>() == null) {
      return child;
    }
    return _FieldVisibility(visible: visible, child: child);
  }

  @override
  State<_FieldVisibility> createState() => _FieldVisibilityState();
}

class _FieldVisibilityState extends State<_FieldVisibility>
    with SingleTickerProviderStateMixin {
  // Made on the first change of visibility: most fields never fold.
  AnimationController? _controller;

  double get _shown => _controller?.value ?? (widget.visible ? 1 : 0);

  @override
  void didUpdateWidget(_FieldVisibility old) {
    super.didUpdateWidget(old);
    if (widget.visible == old.visible) return;
    final target = widget.visible ? 1.0 : 0.0;
    final duration = context.motion.medium;
    if (duration == Duration.zero) {
      _controller?.value = target;
      return;
    }
    final controller = _controller ??= AnimationController(
      vsync: this,
      value: old.visible ? 1 : 0,
    )..addListener(() => setState(() {}));
    // Eased from wherever it is, so a field shown again mid-fold turns
    // back smoothly.
    controller
      ..duration = duration
      ..animateTo(target, curve: context.motion.standard);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shown;
    if (shown == 0) return const SizedBox.shrink();
    final hiding = !widget.visible;
    return _Fold(
      factor: shown,
      child: ExcludeFocus(
        excluding: hiding,
        child: IgnorePointer(
          ignoring: hiding,
          child: ExcludeSemantics(excluding: hiding, child: widget.child),
        ),
      ),
    );
  }
}

/// Lays its child out under its own constraints and takes [factor] of its
/// height, clipping the rest; at a factor of 1 it is the child.
class _Fold extends SingleChildRenderObjectWidget {
  final double factor;

  const _Fold({required this.factor, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderFold(factor);

  @override
  void updateRenderObject(BuildContext context, _RenderFold renderObject) {
    renderObject.factor = factor;
  }
}

class _RenderFold extends RenderProxyBox {
  _RenderFold(this._factor);

  double _factor;
  set factor(double value) {
    if (value == _factor) return;
    _factor = value;
    markNeedsLayout();
  }

  final _clip = LayerHandle<ClipRectLayer>();

  Size _fold(BoxConstraints constraints, Size child) =>
      constraints.constrain(Size(child.width, child.height * _factor));

  @override
  Size computeDryLayout(BoxConstraints constraints) => switch (child) {
    final child? => _fold(constraints, child.getDryLayout(constraints)),
    null => constraints.smallest,
  };

  @override
  double computeMinIntrinsicHeight(double width) =>
      super.computeMinIntrinsicHeight(width) * _factor;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      super.computeMaxIntrinsicHeight(width) * _factor;

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(constraints, parentUsesSize: true);
    size = _fold(constraints, child.size);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    if (_factor >= 1) {
      _clip.layer = null;
      context.paintChild(child, offset);
      return;
    }
    _clip.layer = context.pushClipRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      (context, offset) => context.paintChild(child, offset),
      oldLayer: _clip.layer,
    );
  }

  @override
  void dispose() {
    _clip.layer = null;
    super.dispose();
  }
}

// ── Presets: the everyday form surface. One per editor; each works scalar OR
//    translated for free, decided by the cell. Adding an editor is one Body +
//    one ~8-line preset here. Every preset also takes the field options
//    `required`, `description`, `enabled`, `readOnly`, `errorText` and
//    `warning`, forwarded through [bind] to the [FieldShell]. ─────────────────

/// A text field — the default. Single input, or one per language when [cell] is
/// translated. A [hint] shows as placeholder text in each empty lane (e.g. the
/// value the field falls back to when left blank).
///
/// [maxLines] above 1, or null, makes it a text area that grows with its
/// content from [minLines]; [maxLength] caps and counts the characters.
class Field extends StatelessWidget {
  final Cell<String> cell;
  final String label;
  final Widget? help;
  final String? hint;

  /// Per-language ghost text for a translated [cell] — the inherited value the
  /// lane falls back to when left blank (e.g. an asset's library default alt).
  /// Falls back to [hint] for languages without an entry.
  final Map<String, String>? laneHints;

  final int? minLines;
  final int? maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;

  /// Fixed text before and after the value — `https://`, `kg`.
  final String? prefix;
  final String? suffix;

  final bool required;
  final String? description;
  final bool enabled;
  final bool readOnly;
  final String? errorText;
  final String? warning;

  const Field(
    this.cell, {
    super.key,
    required this.label,
    this.help,
    this.hint,
    this.laneHints,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.autofillHints,
    this.prefix,
    this.suffix,
    this.required = false,
    this.description,
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.warning,
  });

  TextCellBody _body(ValueCell<String> lane, String? hint) => TextCellBody(
    lane,
    hint: hint,
    minLines: minLines,
    maxLines: maxLines,
    maxLength: maxLength,
    keyboardType: keyboardType,
    autofillHints: autofillHints,
    prefix: prefix,
    suffix: suffix,
  );

  @override
  Widget build(BuildContext context) => bind<String>(
    context,
    cell,
    label: label,
    help: help,
    required: required,
    description: description,
    enabled: enabled,
    readOnly: readOnly,
    errorText: errorText,
    warning: warning,
    body: (lane) => _body(lane, hint),
    laneBody: laneHints == null
        ? null
        : (lane, lang) => _body(lane, laneHints![lang] ?? hint),
  );
}

/// A chrome-less text input bound to a `ValueCell<String>`. A translated lane
/// carries a live collaborative [TextCell.controller] (cursor/IME over the
/// lane's shared text); a plain whole-value scalar has none, so this bridges
/// the cell to a controller with an echo guard. Use it directly for a bare
/// input (e.g. one cell of a record row); [Field] wraps it in the field shell.
///
/// It follows the ambient [FieldStateScope]: read-only there, it shows the
/// value without editing it; disabled, it takes no input.
class TextCellBody extends StatefulWidget {
  final ValueCell<String> cell;
  final String? hint;

  /// Line bounds: more than one line, or a null [maxLines], makes a text area
  /// that grows with its content.
  final int? minLines;
  final int? maxLines;

  /// A character limit, counted under the input.
  final int? maxLength;

  /// Defaults to a multi-line keyboard for a text area.
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;

  /// Fixed text before and after the value — `https://`, `kg`.
  final String? prefix;
  final String? suffix;

  const TextCellBody(
    this.cell, {
    super.key,
    this.hint,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.autofillHints,
    this.prefix,
    this.suffix,
  });

  @override
  State<TextCellBody> createState() => _TextCellBodyState();
}

class _TextCellBodyState extends State<TextCellBody> {
  TextEditingController? _owned;
  bool _applyingRemote = false;

  TextEditingController get _controller {
    final cell = widget.cell;
    if (cell is TextCell) return cell.controller;
    return _owned ??= (TextEditingController(text: cell.value)
      ..addListener(_onLocal));
  }

  void _onLocal() {
    if (_applyingRemote) return;
    if (widget.cell.value != _owned!.text) widget.cell.set(_owned!.text);
  }

  void _onRemote() {
    if (_owned == null) return;
    final v = widget.cell.value;
    if (_owned!.text == v) return;
    _applyingRemote = true;
    final sel = _owned!.selection;
    _owned!.text = v;
    if (sel.isValid && sel.baseOffset <= v.length) _owned!.selection = sel;
    _applyingRemote = false;
  }

  @override
  void initState() {
    super.initState();
    if (widget.cell is! TextCell) widget.cell.addListener(_onRemote);
  }

  /// A repeater keyed by position hands a row's body the next element's cell
  /// when an earlier row is removed: follow it, or the row keeps showing and
  /// editing the removed one.
  @override
  void didUpdateWidget(TextCellBody old) {
    super.didUpdateWidget(old);
    if (identical(widget.cell, old.cell)) return;
    if (old.cell is! TextCell) old.cell.removeListener(_onRemote);
    if (widget.cell is! TextCell) {
      widget.cell.addListener(_onRemote);
      _onRemote();
    }
  }

  @override
  void dispose() {
    if (widget.cell is! TextCell) widget.cell.removeListener(_onRemote);
    _owned?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      readOnly: FieldStateScope.of(context).readOnly,
      style: fieldTextStyle(context),
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      keyboardType: textKeyboardType(widget.keyboardType, widget.maxLines),
      autofillHints: widget.autofillHints,
      decoration: textInputDecoration(
        context,
        hint: widget.hint,
        prefix: widget.prefix,
        suffix: widget.suffix,
      ),
    );
  }
}

/// A numeric field. Emptying the input leaves the value as it was, so it can
/// be retyped; for a value that can be unset use [OptionalNumberField].
class NumberField extends StatelessWidget {
  final Cell<int> cell;
  final String label;
  final Widget? help;
  final num? step;
  final String? prefix;
  final bool required;
  final String? description;
  final bool enabled;
  final bool readOnly;
  final String? errorText;
  final String? warning;

  const NumberField(
    this.cell, {
    super.key,
    required this.label,
    this.help,
    this.step,
    this.prefix,
    this.required = false,
    this.description,
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.warning,
  });

  @override
  Widget build(BuildContext context) => bind<int>(
    context,
    cell,
    label: label,
    help: help,
    required: required,
    description: description,
    enabled: enabled,
    readOnly: readOnly,
    errorText: errorText,
    warning: warning,
    body: (lane) => ValueListenableBuilder<int>(
      valueListenable: lane,
      builder: (_, v, _) => NumberBody(
        value: v,
        onChanged: readOnly
            ? null
            : (n) {
                if (n != null) lane.set(n.round());
              },
        step: step ?? 1,
        prefix: prefix,
      ),
    ),
  );
}

/// A numeric field whose value is optional — an empty input is `null` (unset),
/// not `0`.
class OptionalNumberField extends StatelessWidget {
  final Cell<int?> cell;
  final String label;
  final Widget? help;
  final num? step;
  final String? prefix;
  final bool required;
  final String? description;
  final bool enabled;
  final bool readOnly;
  final String? errorText;
  final String? warning;

  const OptionalNumberField(
    this.cell, {
    super.key,
    required this.label,
    this.help,
    this.step,
    this.prefix,
    this.required = false,
    this.description,
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.warning,
  });

  @override
  Widget build(BuildContext context) => bind<int?>(
    context,
    cell,
    label: label,
    help: help,
    required: required,
    description: description,
    enabled: enabled,
    readOnly: readOnly,
    errorText: errorText,
    warning: warning,
    body: (lane) => ValueListenableBuilder<int?>(
      valueListenable: lane,
      builder: (_, v, _) => NumberBody(
        value: v,
        onChanged: readOnly ? null : (n) => lane.set(n?.round()),
        step: step ?? 1,
        prefix: prefix,
      ),
    ),
  );
}

/// An on/off field, not to be confused with `BoolFilterField`, the filter
/// bar's control. Its [description] sits beside the switch, where it says
/// what turning it on means.
class BooleanField extends StatelessWidget {
  final Cell<bool> cell;
  final String label;
  final Widget? help;
  final String? description;
  final bool required;
  final bool enabled;
  final bool readOnly;
  final String? errorText;
  final String? warning;

  const BooleanField(
    this.cell, {
    super.key,
    required this.label,
    this.help,
    this.description,
    this.required = false,
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.warning,
  });

  @override
  Widget build(BuildContext context) => bind<bool>(
    context,
    cell,
    label: label,
    help: help,
    required: required,
    enabled: enabled,
    readOnly: readOnly,
    errorText: errorText,
    warning: warning,
    mergeSemantics: true,
    body: (lane) => ValueListenableBuilder<bool>(
      valueListenable: lane,
      builder: (_, v, _) => BooleanBody(
        value: v,
        onChanged: readOnly ? null : lane.set,
        description: description,
      ),
    ),
  );
}

/// An on/off field whose value is optional — unset is `null`, not `false`.
class OptionalBooleanField extends StatelessWidget {
  final Cell<bool?> cell;
  final String label;
  final Widget? help;
  final String? description;
  final bool required;
  final bool enabled;
  final bool readOnly;
  final String? errorText;
  final String? warning;

  const OptionalBooleanField(
    this.cell, {
    super.key,
    required this.label,
    this.help,
    this.description,
    this.required = false,
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.warning,
  });

  @override
  Widget build(BuildContext context) => bind<bool?>(
    context,
    cell,
    label: label,
    help: help,
    required: required,
    enabled: enabled,
    readOnly: readOnly,
    errorText: errorText,
    warning: warning,
    mergeSemantics: true,
    body: (lane) => ValueListenableBuilder<bool?>(
      valueListenable: lane,
      builder: (_, v, _) => BooleanBody(
        value: v ?? false,
        onChanged: readOnly ? null : lane.set,
        description: description,
      ),
    ),
  );
}

/// A decimal field. Emptying the input leaves the value as it was, so it can
/// be retyped; for a value that can be unset use [OptionalDecimalField].
class DecimalField extends StatelessWidget {
  final Cell<double> cell;
  final String label;
  final Widget? help;
  final int decimals;
  final num? step;
  final String? prefix;
  final bool required;
  final String? description;
  final bool enabled;
  final bool readOnly;
  final String? errorText;
  final String? warning;

  const DecimalField(
    this.cell, {
    super.key,
    required this.label,
    this.help,
    this.decimals = 2,
    this.step,
    this.prefix,
    this.required = false,
    this.description,
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.warning,
  });

  @override
  Widget build(BuildContext context) => bind<double>(
    context,
    cell,
    label: label,
    help: help,
    required: required,
    description: description,
    enabled: enabled,
    readOnly: readOnly,
    errorText: errorText,
    warning: warning,
    body: (lane) => ValueListenableBuilder<double>(
      valueListenable: lane,
      builder: (_, v, _) => NumberBody(
        value: v,
        decimals: decimals,
        onChanged: readOnly
            ? null
            : (n) {
                if (n != null) lane.set(n.toDouble());
              },
        step: step ?? 1,
        prefix: prefix,
      ),
    ),
  );
}

/// A decimal field whose value is optional — an empty input is `null` (unset),
/// not `0`.
class OptionalDecimalField extends StatelessWidget {
  final Cell<double?> cell;
  final String label;
  final Widget? help;
  final int decimals;
  final num? step;
  final String? prefix;
  final bool required;
  final String? description;
  final bool enabled;
  final bool readOnly;
  final String? errorText;
  final String? warning;

  const OptionalDecimalField(
    this.cell, {
    super.key,
    required this.label,
    this.help,
    this.decimals = 2,
    this.step,
    this.prefix,
    this.required = false,
    this.description,
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.warning,
  });

  @override
  Widget build(BuildContext context) => bind<double?>(
    context,
    cell,
    label: label,
    help: help,
    required: required,
    description: description,
    enabled: enabled,
    readOnly: readOnly,
    errorText: errorText,
    warning: warning,
    body: (lane) => ValueListenableBuilder<double?>(
      valueListenable: lane,
      builder: (_, v, _) => NumberBody(
        value: v,
        decimals: decimals,
        onChanged: readOnly ? null : (n) => lane.set(n?.toDouble()),
        step: step ?? 1,
        prefix: prefix,
      ),
    ),
  );
}

/// A text field whose value is optional — an empty input is `null` (unset), not
/// `''`. Unlike [Field] this is the plain scalar path (no collaborative
/// controller), so it suits last-writer-wins nullable columns.
///
/// It takes [Field]'s text options: [maxLines] above 1, or null, makes it a
/// text area that grows with its content from [minLines]; [maxLength] caps
/// and counts the characters.
class OptionalField extends StatelessWidget {
  final Cell<String?> cell;
  final String label;
  final Widget? help;
  final String? hint;
  final int? minLines;
  final int? maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;

  /// Fixed text before and after the value — `https://`, `kg`.
  final String? prefix;
  final String? suffix;

  final bool required;
  final String? description;
  final bool enabled;
  final bool readOnly;
  final String? errorText;
  final String? warning;

  const OptionalField(
    this.cell, {
    super.key,
    required this.label,
    this.help,
    this.hint,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.autofillHints,
    this.prefix,
    this.suffix,
    this.required = false,
    this.description,
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.warning,
  });

  @override
  Widget build(BuildContext context) => bind<String?>(
    context,
    cell,
    label: label,
    help: help,
    required: required,
    description: description,
    enabled: enabled,
    readOnly: readOnly,
    errorText: errorText,
    warning: warning,
    body: (lane) => ValueListenableBuilder<String?>(
      valueListenable: lane,
      builder: (_, v, _) => TextBody(
        value: v ?? '',
        onChanged: readOnly ? null : (s) => lane.set(s.isEmpty ? null : s),
        hint: hint,
        minLines: minLines,
        maxLines: maxLines,
        maxLength: maxLength,
        keyboardType: keyboardType,
        autofillHints: autofillHints,
        prefix: prefix,
        suffix: suffix,
      ),
    ),
  );
}

/// A date/time field. A non-null date is never cleared; for a clearable,
/// optional date use [OptionalDateField].
class DateField extends StatelessWidget {
  final Cell<DateTime> cell;
  final String label;
  final Widget? help;
  final DateGranularity granularity;
  final bool required;
  final String? description;
  final bool enabled;
  final bool readOnly;
  final String? errorText;
  final String? warning;

  const DateField(
    this.cell, {
    super.key,
    required this.label,
    this.help,
    this.granularity = DateGranularity.date,
    this.required = false,
    this.description,
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.warning,
  });

  @override
  Widget build(BuildContext context) => bind<DateTime>(
    context,
    cell,
    label: label,
    help: help,
    required: required,
    description: description,
    enabled: enabled,
    readOnly: readOnly,
    errorText: errorText,
    warning: warning,
    body: (lane) => ValueListenableBuilder<DateTime>(
      valueListenable: lane,
      builder: (_, v, _) => DateBody(
        value: v,
        granularity: granularity,
        clearable: false,
        onChanged: readOnly ? null : (d) => lane.set(d ?? v),
      ),
    ),
  );
}

/// A date/time field whose value is optional — clearing it sets `null` (unset).
class OptionalDateField extends StatelessWidget {
  final Cell<DateTime?> cell;
  final String label;
  final Widget? help;
  final DateGranularity granularity;
  final bool required;
  final String? description;
  final bool enabled;
  final bool readOnly;
  final String? errorText;
  final String? warning;

  const OptionalDateField(
    this.cell, {
    super.key,
    required this.label,
    this.help,
    this.granularity = DateGranularity.date,
    this.required = false,
    this.description,
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.warning,
  });

  @override
  Widget build(BuildContext context) => bind<DateTime?>(
    context,
    cell,
    label: label,
    help: help,
    required: required,
    description: description,
    enabled: enabled,
    readOnly: readOnly,
    errorText: errorText,
    warning: warning,
    body: (lane) => ValueListenableBuilder<DateTime?>(
      valueListenable: lane,
      builder: (_, v, _) => DateBody(
        value: v,
        granularity: granularity,
        // A day picked into an empty date & time lands at the start of the
        // working day rather than at midnight.
        defaultTime: const TimeOfDay(hour: 9, minute: 0),
        onChanged: readOnly ? null : lane.set,
      ),
    ),
  );
}

/// A single-choice field — a value constrained to [options] (e.g. an enum's
/// string codes).
class SelectField extends StatelessWidget {
  final Cell<String> cell;
  final String label;
  final Widget? help;
  final List<SelectOption> options;
  final bool required;
  final String? description;
  final bool enabled;
  final bool readOnly;
  final String? errorText;
  final String? warning;

  const SelectField(
    this.cell, {
    super.key,
    required this.label,
    this.help,
    required this.options,
    this.required = false,
    this.description,
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.warning,
  });

  @override
  Widget build(BuildContext context) => bind<String>(
    context,
    cell,
    label: label,
    help: help,
    required: required,
    description: description,
    enabled: enabled,
    readOnly: readOnly,
    errorText: errorText,
    warning: warning,
    mergeSemantics: true,
    body: (lane) => ValueListenableBuilder<String>(
      valueListenable: lane,
      builder: (_, v, _) => SelectBody(
        value: v,
        options: options,
        onChanged: readOnly ? null : lane.set,
      ),
    ),
  );
}

/// A single-choice field over a TYPED enum cell. The view supplies the enum's
/// [values] and a [labelOf] — an exhaustive `switch` is the natural choice, so a
/// newly-added enum value won't compile until it's given a label. The cell holds
/// `E`; persistence to the code string lives in the cell, not here.
class EnumSelectField<E> extends StatelessWidget {
  final Cell<E> cell;
  final String label;
  final Widget? help;
  final List<E> values;
  final String Function(E) labelOf;
  final bool required;
  final String? description;
  final bool enabled;
  final bool readOnly;
  final String? errorText;
  final String? warning;

  const EnumSelectField(
    this.cell, {
    super.key,
    required this.label,
    this.help,
    required this.values,
    required this.labelOf,
    this.required = false,
    this.description,
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.warning,
  });

  @override
  Widget build(BuildContext context) => bind<E>(
    context,
    cell,
    label: label,
    help: help,
    required: required,
    description: description,
    enabled: enabled,
    readOnly: readOnly,
    errorText: errorText,
    warning: warning,
    mergeSemantics: true,
    body: (lane) => ValueListenableBuilder<E>(
      valueListenable: lane,
      builder: (_, current, _) {
        // SelectBody is string-keyed; key options by index, map back to E.
        final options = [
          for (var i = 0; i < values.length; i++)
            SelectOption(value: '$i', label: labelOf(values[i])),
        ];
        final idx = values.indexOf(current);
        return SelectBody(
          value: idx < 0 ? '' : '$idx',
          options: options,
          onChanged: readOnly ? null : (k) => lane.set(values[int.parse(k)]),
        );
      },
    ),
  );
}

/// A primitive string list (e.g. tags) — chips with an add input.
class TagsField extends StatelessWidget {
  final Cell<List<String>> cell;
  final String label;
  final Widget? help;

  /// The add input's placeholder; "Add…" in the app's language when null.
  final String? addHint;

  final bool required;
  final String? description;
  final bool enabled;
  final bool readOnly;
  final String? errorText;
  final String? warning;

  const TagsField(
    this.cell, {
    super.key,
    required this.label,
    this.help,
    this.addHint,
    this.required = false,
    this.description,
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.warning,
  });

  @override
  Widget build(BuildContext context) => bind<List<String>>(
    context,
    cell,
    label: label,
    help: help,
    required: required,
    description: description,
    enabled: enabled,
    readOnly: readOnly,
    errorText: errorText,
    warning: warning,
    body: (lane) => ValueListenableBuilder<List<String>>(
      valueListenable: lane,
      builder: (_, values, _) => TagsBody(
        value: values,
        onChanged: readOnly ? null : lane.set,
        hint: addHint ?? context.adminL10n.shell.addTagHint,
      ),
    ),
  );
}

/// A free key→value map (SEO meta, headers, env, a loose settings blob). The
/// value is an ordered `Map<String, String>`; rows add/remove inline. Bind
/// it to a [FormScope.map] cell, which a [ValueFormController] tracks,
/// discards and saves like any other.
class KeyValueField extends StatelessWidget {
  final Cell<Map<String, String>> cell;
  final String label;
  final Widget? help;

  /// The key column's placeholder; "Key" in the app's language when null.
  final String? keyHint;

  /// The value column's placeholder; "Value" in the app's language when null.
  final String? valueHint;

  /// The add button's label; "Add row" in the app's language when null.
  final String? addLabel;

  final bool required;
  final String? description;
  final bool enabled;
  final bool readOnly;
  final String? errorText;
  final String? warning;

  const KeyValueField(
    this.cell, {
    super.key,
    required this.label,
    this.help,
    this.keyHint,
    this.valueHint,
    this.addLabel,
    this.required = false,
    this.description,
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.warning,
  });

  @override
  Widget build(BuildContext context) => bind<Map<String, String>>(
    context,
    cell,
    label: label,
    help: help,
    required: required,
    description: description,
    enabled: enabled,
    readOnly: readOnly,
    errorText: errorText,
    warning: warning,
    body: (lane) => ValueListenableBuilder<Map<String, String>>(
      valueListenable: lane,
      builder: (_, map, _) => KeyValueBody(
        value: map,
        onChanged: readOnly ? null : lane.set,
        keyHint: keyHint ?? context.adminL10n.keyLabel,
        valueHint: valueHint ?? context.adminL10n.valueLabel,
        addLabel: addLabel ?? context.adminL10n.addRow,
      ),
    ),
  );
}

/// A masked text input (phone, card, code…). [mask] follows [MaskFormatter].
class MaskedField extends StatelessWidget {
  final Cell<String> cell;
  final String label;
  final Widget? help;
  final String mask;
  final String? hint;
  final bool required;
  final String? description;
  final bool enabled;
  final bool readOnly;
  final String? errorText;
  final String? warning;

  const MaskedField(
    this.cell, {
    super.key,
    required this.label,
    this.help,
    required this.mask,
    this.hint,
    this.required = false,
    this.description,
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.warning,
  });

  @override
  Widget build(BuildContext context) => bind<String>(
    context,
    cell,
    label: label,
    help: help,
    required: required,
    description: description,
    enabled: enabled,
    readOnly: readOnly,
    errorText: errorText,
    warning: warning,
    body: (lane) => ValueListenableBuilder<String>(
      valueListenable: lane,
      builder: (_, v, _) => MaskedBody(
        mask: mask,
        value: v,
        onChanged: readOnly ? null : lane.set,
        hint: hint,
      ),
    ),
  );
}

/// A colour, stored as a hex string (e.g. `#1A2B3C`).
class ColorField extends StatelessWidget {
  final Cell<String> cell;
  final String label;
  final Widget? help;
  final bool required;
  final String? description;
  final bool enabled;
  final bool readOnly;
  final String? errorText;
  final String? warning;

  const ColorField(
    this.cell, {
    super.key,
    required this.label,
    this.help,
    this.required = false,
    this.description,
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.warning,
  });

  @override
  Widget build(BuildContext context) => bind<String>(
    context,
    cell,
    label: label,
    help: help,
    required: required,
    description: description,
    enabled: enabled,
    readOnly: readOnly,
    errorText: errorText,
    warning: warning,
    mergeSemantics: true,
    body: (lane) => ValueListenableBuilder<String>(
      valueListenable: lane,
      builder: (_, v, _) => ColorBody(
        value: v.isEmpty ? null : v,
        onChanged: readOnly ? null : lane.set,
      ),
    ),
  );
}

/// A single attached asset (image/file) held as an integer foreign key — the
/// shape a generated `numberOrNull` cell has (null = unset). The field
/// previews it through the ambient [AssetSourceScope] and opens the shared
/// media picker to choose/replace, through the bare [AssetBody], which speaks
/// the kit's string asset ids: the key is shown as its decimal string, and a
/// picked id that is not an integer cannot be stored — it is refused with an
/// assert and never written. [accept] is what the picker takes.
class AssetField extends StatelessWidget {
  final Cell<int?> cell;
  final String label;
  final Widget? help;
  final MediaKind kind;
  final AssetAccept? accept;
  final bool required;
  final String? description;
  final bool enabled;
  final bool readOnly;
  final String? errorText;
  final String? warning;

  const AssetField(
    this.cell, {
    super.key,
    required this.label,
    this.help,
    this.kind = MediaKind.image,
    this.accept,
    this.required = false,
    this.description,
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.warning,
  });

  @override
  Widget build(BuildContext context) => bind<int?>(
    context,
    cell,
    label: label,
    help: help,
    required: required,
    description: description,
    enabled: enabled,
    readOnly: readOnly,
    errorText: errorText,
    warning: warning,
    body: (lane) => ValueListenableBuilder<int?>(
      valueListenable: lane,
      builder: (_, v, _) => AssetBody(
        value: v?.toString(),
        onChanged: readOnly ? null : (id) => _write(lane, id),
        kind: kind,
        accept: accept,
      ),
    ),
  );

  static void _write(ValueCell<int?> lane, String? id) {
    if (id == null) return lane.set(null);
    final key = int.tryParse(id);
    assert(key != null, 'AssetField stores integer ids; got "$id"');
    if (key != null) lane.set(key);
  }
}

/// A multi-choice field over a string list constrained to [options].
class MultiSelectField extends StatelessWidget {
  final Cell<List<String>> cell;
  final String label;
  final Widget? help;
  final List<SelectOption> options;
  final bool required;
  final String? description;
  final bool enabled;
  final bool readOnly;
  final String? errorText;
  final String? warning;

  const MultiSelectField(
    this.cell, {
    super.key,
    required this.label,
    this.help,
    required this.options,
    this.required = false,
    this.description,
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.warning,
  });

  @override
  Widget build(BuildContext context) => bind<List<String>>(
    context,
    cell,
    label: label,
    help: help,
    required: required,
    description: description,
    enabled: enabled,
    readOnly: readOnly,
    errorText: errorText,
    warning: warning,
    body: (lane) => ValueListenableBuilder<List<String>>(
      valueListenable: lane,
      builder: (_, values, _) => MultiSelectBody(
        options: options,
        value: values.toSet(),
        onChanged: readOnly ? null : (s) => lane.set(s.toList()),
      ),
    ),
  );
}

/// A reference relation — a set of related ids picked through the shared
/// reference picker. Generic over the related domain type [T] and its id
/// type [K]: an integer primary key, a UUID or a slug.
class ReferenceField<T, K extends Object> extends StatelessWidget {
  final Cell<List<K>> cell;
  final String label;
  final Widget? help;
  final K Function(T) idOf;
  final ReferenceResolver<T, K> resolve;
  final ReferenceSearch<T> search;
  final ReferenceTile<T> tile;

  /// The add button's label; "Link…" in the app's language when null.
  final String? addLabel;

  /// The search input's placeholder; "Search…" in the app's language when
  /// null.
  final String? searchHint;

  final bool required;
  final String? description;
  final bool enabled;
  final bool readOnly;
  final String? errorText;
  final String? warning;

  const ReferenceField(
    this.cell, {
    super.key,
    required this.label,
    this.help,
    required this.idOf,
    required this.resolve,
    required this.search,
    required this.tile,
    this.addLabel,
    this.searchHint,
    this.required = false,
    this.description,
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.warning,
  });

  @override
  Widget build(BuildContext context) => bind<List<K>>(
    context,
    cell,
    label: label,
    help: help,
    required: required,
    description: description,
    enabled: enabled,
    readOnly: readOnly,
    errorText: errorText,
    warning: warning,
    body: (lane) => ValueListenableBuilder<List<K>>(
      valueListenable: lane,
      builder: (_, ids, _) => ReferenceBody<T, K>(
        value: ids,
        onChanged: readOnly ? null : lane.set,
        idOf: idOf,
        resolve: resolve,
        search: search,
        tile: tile,
        addLabel: addLabel ?? context.adminL10n.linkPlaceholder,
        searchHint: searchHint ?? context.adminL10n.searchPlaceholder,
      ),
    ),
  );
}

/// An owned record list (e.g. specs, variants) — a repeater of typed sub-handles
/// [H]. [item] renders one element's editors (the sub-handle exposes a
/// controller per field + `remove()`); add/remove are wired to the cell, and
/// drop out while the field is read-only or disabled, by its own flags or an
/// enclosing [FieldStateScope] (a read-only [ValueForm]). [itemLabel] names an
/// element in its remove action ("Remove Lens hood"), which otherwise says its
/// position. Like a bound field, it follows a [ValueForm]'s rules for its id:
/// required, or folded away while hidden. A `ListRules` over [cell] counts
/// its rows: "Add at least 1 item" shows under the list, and its link in a
/// `ValidationSummary` takes focus to the add button of an empty list.
class RecordListField<H> extends StatelessWidget {
  final RecordListCell<H> cell;
  final String label;
  final Widget? help;
  final Widget Function(H element) item;

  /// The add button's label; "Add item" in the app's language when null.
  final String? addLabel;

  final String Function(H element, int index)? itemLabel;
  final bool required;
  final String? description;
  final bool enabled;
  final bool readOnly;
  final String? errorText;
  final String? warning;

  const RecordListField(
    this.cell, {
    super.key,
    required this.label,
    this.help,
    required this.item,
    this.addLabel,
    this.itemLabel,
    this.required = false,
    this.description,
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.warning,
  });

  @override
  Widget build(BuildContext context) {
    final message = errorText ?? FieldErrorsScope.errorOf(context, cell.id);
    final required =
        this.required || ValueFormScope.isRequired(context, cell.id);
    final state = FieldStateScope.of(context);
    final editable = enabled && !readOnly && state.enabled && !state.readOnly;
    final field = ListenableBuilder(
      listenable: cell,
      builder: (context, _) {
        final elements = cell.elements;
        final summary = ChangeScope.summaryOf(context, cell.id);
        final lang = LangScope.maybeOf(context);
        final name = itemLabel;
        return FieldShell(
          label: label,
          fieldId: cell.id,
          help: help,
          comments: CommentsScope.maybeOf(context)?.buttonFor(cell.id),
          modified: summary.modified,
          modifiedDetail: lang == null
              ? null
              : modifiedLocalesDetail(lang.locales, summary.lanes),
          required: required,
          description: description,
          enabled: enabled,
          readOnly: readOnly,
          errorText: message,
          warning: warning,
          child: Repeater(
            itemCount: elements.length,
            itemBuilder: (_, i) => item(elements[i]),
            onAdd: editable ? cell.add : null,
            onRemove: editable ? cell.removeAt : null,
            removeLabel: name == null
                ? null
                : (i) => context.adminL10n.removeItem(name(elements[i], i)),
            addLabel: addLabel ?? context.adminL10n.addItem,
          ),
        );
      },
    );
    return _FieldVisibility.wrap(
      context,
      visible: ValueFormScope.isVisible(context, cell.id),
      child: field,
    );
  }
}
