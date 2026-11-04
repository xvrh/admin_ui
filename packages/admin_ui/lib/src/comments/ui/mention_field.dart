import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../common/text_metrics.dart';
import '../../common/ui/avatar.dart';
import '../../common/ui/field_chrome.dart';
import '../../common/ui/input_decoration.dart';
import '../../common/ui/labeled_field.dart';
import '../../common/ui/listbox.dart';
import '../../common/ui/popover.dart';
import '../../common/ui/popover_menu.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../theme/sizes.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import '../mentions.dart';

/// A text field that offers [candidates] to mention as soon as an `@` is
/// typed, for a comment or a note.
///
/// **Suggestions.** Typing `@` at the start of the text or after a space
/// opens a list of the candidates whose name holds what follows it
/// ([mentionQueryAt], [matchMentionCandidates]), or the localized "No
/// matches". It opens below the field with each suggestion's avatar under
/// the `@`, starting at its left edge, or at its right edge in a
/// right-to-left app; for an `@` that starts a line it lines up with the
/// field, as a dropdown does. Text that runs past a name nobody has, with a
/// space in it, is the note going on, and closes the list.
///
/// **Keyboard.** Focus stays in the field throughout: the list is announced
/// as a listbox whose highlighted option reads as focused, as on a
/// [Combobox]. ArrowDown and ArrowUp move the highlight, Enter or Tab
/// accepts it, and Escape closes the list until the caret leaves that
/// mention. Accepting, or tapping a suggestion, replaces the `@` and what
/// follows it up to the caret with `@Name` and a space. As the list opens
/// or its matches change, their number is announced.
///
/// **Sending.** [onSubmit] receives the body with each mention as its
/// durable token ([tokenizeMentions]), sent with Enter in a one-line field
/// and with Ctrl+Enter or ⌘+Enter in a multi-line one, never while the list
/// is open. A send button beside the field calls
/// `tokenizeMentions(controller.text.trim(), candidates)` itself.
///
/// It takes [label], [description] and [errorText] as an `InputField` does,
/// and is disabled or read-only by [enabled], [readOnly] or an enclosing
/// [FieldStateScope]; it then opens no list.
class MentionField extends StatefulWidget {
  /// The text, with mentions in their `@Name` form; the field keeps its own
  /// when null. The host clears it once a body it was sent has landed.
  final TextEditingController? controller;

  /// Who can be mentioned, in the order the list offers them.
  final List<MentionCandidate> candidates;

  /// Sends the body, mentions tokenized; see [MentionField]. The text stays.
  final ValueChanged<String>? onSubmit;

  /// Label above the field; null renders the bare field.
  final String? label;

  /// Muted line between the label and the field.
  final String? description;

  final String? hint;

  /// Validation message under the field; also turns its border red.
  final String? errorText;

  /// Shown in the list when no candidate matches; the localized "No matches"
  /// when null.
  final String? emptyText;

  final ControlSize size;

  /// 1 for a single line (the default); higher, or null to grow without
  /// bound, for a multi-line box.
  final int? maxLines;
  final int? minLines;

  final FocusNode? focusNode;
  final bool autofocus;
  final bool enabled;
  final bool readOnly;

  const MentionField({
    super.key,
    this.controller,
    required this.candidates,
    this.onSubmit,
    this.label,
    this.description,
    this.hint,
    this.errorText,
    this.emptyText,
    this.size = ControlSize.medium,
    this.maxLines = 1,
    this.minLines,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    this.readOnly = false,
  });

  @override
  State<MentionField> createState() => _MentionFieldState();
}

class _MentionFieldState extends State<MentionField> {
  /// Keeps the plain arrows moving the caret: the popover's anchor maps them
  /// to menu traversal.
  static const _caretShortcuts = <ShortcutActivator, Intent>{
    SingleActivator(
      LogicalKeyboardKey.arrowLeft,
    ): ExtendSelectionByCharacterIntent(
      forward: false,
      collapseSelection: true,
    ),
    SingleActivator(
      LogicalKeyboardKey.arrowRight,
    ): ExtendSelectionByCharacterIntent(
      forward: true,
      collapseSelection: true,
    ),
    SingleActivator(
      LogicalKeyboardKey.arrowUp,
    ): ExtendSelectionVerticallyToAdjacentLineIntent(
      forward: false,
      collapseSelection: true,
    ),
    SingleActivator(
      LogicalKeyboardKey.arrowDown,
    ): ExtendSelectionVerticallyToAdjacentLineIntent(
      forward: true,
      collapseSelection: true,
    ),
  };

  static final _space = RegExp(r'\s');

  final _listbox = ListboxController();
  final _anchorKey = GlobalKey();
  TextEditingController? _ownController;
  FocusNode? _ownFocus;
  PopoverController? _popover;

  /// The `@` query at the caret, while it is one the list answers.
  ({int start, String query})? _query;
  List<MentionCandidate> _matches = const [];

  /// The `@` whose list was accepted from or dismissed: it stays closed
  /// until the caret leaves that mention.
  int? _settledAt;

  bool _open = false;
  bool _closing = false;
  bool _editable = true;

  /// Where the list lines up: from the field's start edge to the `@`, less
  /// the inset a suggestion's content keeps.
  double _offset = 0;
  bool _placing = false;
  int? _announced;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());

  FocusNode get _focus =>
      widget.focusNode ?? (_ownFocus ??= FocusNode(debugLabel: 'MentionField'));

  bool get _multiline => widget.maxLines != 1;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChange);
    _focus.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(MentionField old) {
    super.didUpdateWidget(old);
    final oldController = old.controller ?? _ownController;
    if (!identical(oldController, _controller)) {
      oldController?.removeListener(_onChange);
      _controller.addListener(_onChange);
    }
    final oldFocus = old.focusNode ?? _ownFocus;
    if (!identical(oldFocus, _focus)) {
      oldFocus?.removeListener(_onFocus);
      _focus.addListener(_onFocus);
    }
    if (!identical(widget.candidates, old.candidates)) {
      // The open list is in the overlay, which cannot rebuild from here.
      SchedulerBinding.instance.addPostFrameCallback((_) => _onChange());
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    _focus.removeListener(_onFocus);
    _ownController?.dispose();
    _ownFocus?.dispose();
    _listbox.dispose();
    super.dispose();
  }

  /// Works out the query at the caret and opens, updates or closes the list.
  void _onChange() {
    if (!mounted) return;
    final value = _controller.value;
    final selection = value.selection;
    var query = selection.isValid && selection.isCollapsed
        ? mentionQueryAt(value.text, selection.baseOffset)
        : null;
    var matches = const <MentionCandidate>[];
    if (query != null) {
      matches = matchMentionCandidates(widget.candidates, query.query);
      // A space right after the `@` opens nothing, and text with a space in
      // it that names nobody is the note going on past a mention.
      if (query.query.startsWith(_space) ||
          (matches.isEmpty && query.query.contains(_space))) {
        query = null;
        matches = const [];
      }
    }
    if (query?.start != _settledAt) _settledAt = null;
    final previous = _query;
    final changed =
        previous?.start != query?.start || previous?.query != query?.query;
    if (changed || !_same(matches, _matches)) {
      setState(() {
        _query = query;
        _matches = matches;
      });
      if (query != null) {
        _listbox.reset(matches.length, labelOf: (i) => matches[i].name);
      }
    }
    if (!_shows) {
      _close();
      return;
    }
    if (!_open || previous?.start != query?.start) _schedulePlace();
    if (_open) _announce();
  }

  static bool _same(List<MentionCandidate> a, List<MentionCandidate> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id || a[i].name != b[i].name) return false;
    }
    return true;
  }

  /// Whether the list belongs open: a live query, not settled, in a focused
  /// field that takes input.
  bool get _shows =>
      _query != null && _settledAt == null && _editable && _focus.hasFocus;

  void _onFocus() {
    if (_focus.hasFocus) {
      _onChange();
    } else {
      _close();
    }
  }

  /// Lines the list up with the `@` once the field has laid its text out,
  /// then opens it.
  void _schedulePlace() {
    if (_placing) return;
    _placing = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _placing = false;
      final query = _query;
      if (!mounted || query == null || !_shows) return;
      final offset = _offsetOf(query.start);
      if (offset != _offset) setState(() => _offset = offset);
      if (!_open) _popover?.open();
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  /// The distance from the field's start edge to the start of the `@` at
  /// [index], less a suggestion's inset, so the avatar of each suggestion
  /// sits under it; none for an `@` that starts its line.
  double _offsetOf(int index) {
    final anchor = _anchorKey.currentContext?.findRenderObject();
    if (anchor is! RenderBox || !anchor.hasSize) return 0;
    RenderEditable? editable;
    void find(RenderObject child) {
      if (editable != null) return;
      if (child is RenderEditable) {
        editable = child;
      } else {
        child.visitChildren(find);
      }
    }

    anchor.visitChildren(find);
    final text = editable;
    if (text == null || !text.hasSize || index >= text.plainText.length) {
      return 0;
    }
    if (index == 0 || text.plainText[index - 1] == '\n') return 0;
    final boxes = text.getBoxesForSelection(
      TextSelection(baseOffset: index, extentOffset: index + 1),
    );
    if (boxes.isEmpty) return 0;
    final box = boxes.first;
    final ltr = Directionality.of(context) == TextDirection.ltr;
    final edge = anchor
        .globalToLocal(
          text.localToGlobal(Offset(ltr ? box.left : box.right, box.top)),
        )
        .dx;
    final fromStart = ltr ? edge : anchor.size.width - edge;
    final inset = AdminSpacing.xs + ListboxOption.contentInset(context);
    return (fromStart - inset).clamp(0.0, anchor.size.width).roundToDouble();
  }

  void _close() {
    if (!_open) return;
    _closing = true;
    _popover?.close();
  }

  void _onOpenChanged(bool open) {
    if (!mounted) return;
    if (open) {
      setState(() => _open = true);
      _announced = null;
      _announce();
      return;
    }
    // Escape, or a tap outside: this mention's list stays closed.
    if (!_closing && _query != null) _settledAt = _query!.start;
    _closing = false;
    _announced = null;
    setState(() => _open = false);
  }

  void _announce() {
    final count = _matches.length;
    if (count == _announced || !SemanticsBinding.instance.semanticsEnabled) {
      return;
    }
    _announced = count;
    final l10n = context.adminL10n;
    SemanticsService.sendAnnouncement(
      View.of(context),
      count == 0 ? l10n.noMatches : l10n.display.mentionMatches(count),
      Directionality.of(context),
    );
  }

  void _accept(MentionCandidate candidate) {
    final query = _query;
    if (query == null) return;
    final value = _controller.value;
    final caret = value.selection.baseOffset.clamp(
      query.start,
      value.text.length,
    );
    // A space already there is stepped over rather than doubled.
    final spaced = value.text.startsWith(' ', caret);
    final mention = '@${candidate.name}${spaced ? '' : ' '}';
    _settledAt = query.start;
    _controller.value = TextEditingValue(
      text: value.text.replaceRange(query.start, caret, mention),
      selection: TextSelection.collapsed(
        offset: query.start + mention.length + (spaced ? 1 : 0),
      ),
    );
    _close();
    if (!_focus.hasFocus) _focus.requestFocus();
  }

  bool _acceptHighlighted() {
    final at = _listbox.highlighted;
    if (!_open || at == null || at >= _matches.length) return false;
    _accept(_matches[at]);
    return true;
  }

  void _submit() {
    final onSubmit = widget.onSubmit;
    if (onSubmit == null || !_editable) return;
    final body = tokenizeMentions(_controller.text.trim(), widget.candidates);
    if (body.isNotEmpty) onSubmit(body);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!_editable || (event is! KeyDownEvent && event is! KeyRepeatEvent)) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final keyboard = HardwareKeyboard.instance;
    final enter =
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter;
    if (!_open) {
      if (enter &&
          _multiline &&
          (keyboard.isControlPressed || keyboard.isMetaPressed)) {
        if (event is KeyDownEvent) _submit();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    if (keyboard.isControlPressed ||
        keyboard.isMetaPressed ||
        keyboard.isAltPressed) {
      return KeyEventResult.ignored;
    }
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowUp) {
      _listbox.moveBy(key == LogicalKeyboardKey.arrowDown ? 1 : -1);
      return KeyEventResult.handled;
    }
    final tab = key == LogicalKeyboardKey.tab && !keyboard.isShiftPressed;
    if (enter || tab) {
      if (_matches.isEmpty) {
        // Nothing to accept: the key does what it would have.
        _close();
        return KeyEventResult.ignored;
      }
      if (event is KeyDownEvent) _acceptHighlighted();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final field = Popover(
      autofocus: false,
      alignOffset: _offset,
      onOpenChanged: _onOpenChanged,
      anchor: (context, controller) {
        _popover = controller;
        return KeyedSubtree(key: _anchorKey, child: _field(context));
      },
      content: _panel,
    );
    final label = widget.label;
    if (label != null) {
      return LabeledField(
        label: label,
        description: widget.description,
        errorText: widget.errorText,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        child: field,
      );
    }
    final error = widget.errorText;
    final invalid = error != null || FieldStateScope.of(context).invalid;
    return FieldStateScope(
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      invalid: invalid,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            hint: error,
            validationResult: invalid
                ? SemanticsValidationResult.invalid
                : SemanticsValidationResult.none,
            child: field,
          ),
          if (error != null) FieldErrorText(error),
        ],
      ),
    );
  }

  Widget _field(BuildContext context) {
    final state = FieldStateScope.of(context);
    final editable = state.enabled && !state.readOnly;
    if (editable != _editable) {
      _editable = editable;
      if (!editable) {
        SchedulerBinding.instance.addPostFrameCallback((_) => _close());
      }
    }
    final Widget field = TextField(
      controller: _controller,
      focusNode: _focus,
      autofocus: widget.autofocus,
      enabled: state.enabled,
      readOnly: state.readOnly,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      keyboardType: _multiline ? TextInputType.multiline : TextInputType.text,
      textInputAction: _multiline
          ? TextInputAction.newline
          : TextInputAction.send,
      // A one-line field sends on its keyboard's action and keeps focus for
      // the next one; the list, while open, takes the action for a pick.
      onSubmitted: _multiline
          ? null
          : (_) {
              if (!_acceptHighlighted()) _submit();
            },
      onEditingComplete: _multiline ? null : () {},
      style: fieldTextStyle(context),
      decoration: fieldInputDecoration(
        context,
        hint: widget.hint,
        size: widget.size,
      ),
    );
    return Semantics(
      expanded: editable ? _open : null,
      child: Shortcuts(
        shortcuts: _caretShortcuts,
        includeSemantics: false,
        child: Focus(
          canRequestFocus: false,
          skipTraversal: true,
          includeSemantics: false,
          onKeyEvent: _onKey,
          child: field,
        ),
      ),
    );
  }

  Widget _panel(BuildContext context, PopoverController controller) {
    final l10n = context.adminL10n;
    final matches = _matches;
    final avatar = math.max(
      _avatarSize,
      lineHeightOf(context, context.type.fieldText),
    );
    final Widget body = matches.isEmpty
        ? _NoMatch(widget.emptyText ?? l10n.noMatches)
        : Listbox(
            controller: _listbox,
            itemCount: matches.length,
            semanticLabel: l10n.display.mentionSuggestions,
            itemBuilder: (context, i) => ListboxOption(
              controller: _listbox,
              index: i,
              label: matches[i].name,
              leading: Avatar(name: matches[i].name, size: avatar),
              onTap: () => _accept(matches[i]),
            ),
          );
    // Taps in the list count as inside the field, which keeps its focus;
    // nothing in it takes focus from the field.
    return TextFieldTapRegion(
      child: ExcludeFocus(
        child: PopoverMenuSurface(
          width: _listWidth,
          maxHeight: _listMaxHeight,
          fitAvailableHeight: true,
          child: body,
        ),
      ),
    );
  }
}

/// Room for a name beside its avatar. A surface sized to its content would
/// measure the lazy list by its intrinsic width, which it cannot report.
const _listWidth = 280.0;

/// About seven suggestions, so the field keeps its place in view.
const _listMaxHeight = 280.0;

/// A suggestion's avatar, at least: room for two initials, as the 24px
/// avatars of shadcn's command list and Ant's mentions give them. It grows
/// with the name's line at a larger text size.
const _avatarSize = 24.0;

class _NoMatch extends StatelessWidget {
  final String text;

  const _NoMatch(this.text);

  @override
  Widget build(BuildContext context) {
    final sizes = context.sizes;
    return Container(
      constraints: BoxConstraints(
        minHeight: sizes.medium + 2 * AdminSpacing.xs,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: sizes.fieldPaddingX,
        vertical: AdminSpacing.xs,
      ),
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        text,
        style: context.type.fieldText.copyWith(
          color: context.colors.foregroundMuted,
        ),
      ),
    );
  }
}
