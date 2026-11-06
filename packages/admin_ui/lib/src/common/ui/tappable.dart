/// @docImport '../../comments/ui/mention_text.dart';
/// @docImport 'button.dart';
/// @docImport 'copy_button.dart';
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart' show DiagnosticsDebugCreator;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart'
    show
        PointerEnterEventListener,
        PointerExitEventListener,
        PointerHoverEventListener;
import 'package:material_ui/material_ui.dart';

import 'focus_ring.dart';

/// Ripple-free tap target — the house alternative to [InkWell]. Components paint
/// their own borders and fills for hover/selected state, so Material's ink would
/// only muddy them. A [GestureDetector] (opaque hit test) wrapped in a
/// [MouseRegion] that shows [cursor] (default the hand,
/// [SystemMouseCursors.click]) when [onTap] is set and [disabledCursor]
/// (default the arrow) otherwise.
///
/// **Cursor.** The hand says what is under the pointer, a control, not
/// whether this click changes anything: a selected option, the current page
/// and the current tab show it like their neighbours. It shows on every
/// platform, as the web does, so a development build on the desktop looks
/// like the shipped web app; Material's own buttons switch to the arrow off
/// the web (`WidgetStateMouseCursor.adaptiveClickable`), so an [InkWell] in
/// the kit passes `mouseCursor: WidgetStateMouseCursor.clickable`
/// (`test/selection_cursor_test.dart` checks every one). A link shows the
/// hand too; a disabled target the arrow; a target a double click or a long
/// press acts on, and a field's label, the arrow through [CursorRegion]; a
/// drag handle the open hand; a splitter the resize arrows; text input, and
/// text in a read-only place, the I-beam.
///
/// A tap target is no place to select text: under an ancestor [SelectionArea]
/// the label is left out of the selection and shows the tap cursor, not the
/// text I-beam (see [CursorRegion]). A value a user may want to copy out of
/// one gets a [CopyButton].
///
/// Use the default constructor for a static child. Use [Tappable.builder] when
/// the child depends on hover — the ubiquitous "tint a Container on hover" row —
/// so the `bool _hover` + `onEnter/onExit` scaffold lives here once instead of
/// in every caller. [onHover] also bubbles the flag out for a sibling that
/// reacts to it. Use [Tappable.states] when the child also paints pressed,
/// focused, disabled or selected.
///
/// **Keyboard.** While [onTap] is set (or [readOnly]) the target joins the
/// Tab order (unless [focusable] is false), Enter and Space activate it
/// (both [ActivateIntent] and [ButtonActivateIntent] invoke [onTap]), and
/// keyboard focus draws the theme's [FocusRing] around the child
/// ([showFocusRing], [focusRadius]). A Tappable that wraps another
/// focusable — a [Button], an [InkWell], a [TextField], a nested Tappable —
/// must pass `focusable: false`, or Tab stops on the same control twice. A
/// debug build reports that as a [FlutterError] after the first frame the
/// target can take focus, when a Tab stop inside it covers half of it or
/// more; a small control of its own inside the target (a chip's remove
/// button, a tab's menu caret) is a separate stop and is left alone.
/// `focusable: false` also refuses programmatic focus; for roving focus (one
/// Tab stop, arrows between items) pass a [focusNode] whose `skipTraversal`
/// is set instead. A row that is a Tab stop and holds its own actions keeps
/// both by putting the actions under a `Focus(parentNode:)` whose node wraps
/// the Tappable, so the focus tree has them beside the row, not inside it.
///
/// **Semantics.** A Tappable with an [onTap], or with any of the semantics
/// parameters set, is its own semantics node: a button (a link with [link],
/// no button role when [role], [checked], [mixed] or [toggled] says what it
/// is), enabled while [onTap] is set or [readOnly], carrying [semanticLabel]
/// ahead of the child's own text — or instead of it with [excludeSemantics].
/// One with neither stays silent, so a decorative hover target adds nothing.
/// A [role] must sit under its parent role (a `menuItem` inside a `menu`, a
/// `tab` inside a `tabBar`): the debug semantics checks assert on it.
class Tappable extends StatefulWidget {
  final VoidCallback? onTap;

  /// Static content, for the default constructor.
  final Widget? child;

  /// Hover-aware content, for [Tappable.builder].
  final Widget Function(BuildContext context, bool hovered)? builder;

  /// State-aware content, for [Tappable.states].
  final Widget Function(BuildContext context, Set<WidgetState> states)?
  statesBuilder;

  /// Notified as the pointer enters/leaves — for hover that drives a sibling.
  final ValueChanged<bool>? onHover;

  /// Overrides the enabled cursor (default [SystemMouseCursors.click]).
  final MouseCursor? cursor;

  /// Cursor while [onTap] is null.
  final MouseCursor disabledCursor;

  final HitTestBehavior behavior;

  /// Whether the target joins the Tab order. Only while [onTap] is set; false
  /// where the child is itself focusable.
  final bool focusable;

  final FocusNode? focusNode;
  final bool autofocus;

  /// Notified as keyboard or programmatic focus enters or leaves the target.
  final ValueChanged<bool>? onFocusChange;

  /// Draws the theme's [FocusRing] around the child while it holds keyboard
  /// focus. Off for a child that paints focus itself.
  final bool showFocusRing;

  /// Corner radius of the child's edge, which the focus ring follows.
  final double focusRadius;

  /// Reports, and can seed, the hovered, pressed and focused states — like
  /// [Button]'s, e.g. to pin a state in a catalog without a pointer or
  /// keyboard. Kept in sync with [WidgetState.disabled] (no [onTap]) and
  /// [WidgetState.selected] ([selected] true). Created internally when null.
  final WidgetStatesController? statesController;

  /// Announced ahead of the child's own text, or instead of it with
  /// [excludeSemantics].
  final String? semanticLabel;

  /// Selected state for assistive technology: a current page, a chosen segment.
  /// Also reported as [WidgetState.selected] when true.
  final bool? selected;

  /// Expanded state of a disclosure: an accordion header, a menu trigger.
  final bool? expanded;

  /// Checked state of a checkbox or radio; with it the node is no button.
  final bool? checked;

  /// The half-checked state of a tristate checkbox; announced instead of
  /// [checked] while true.
  final bool? mixed;

  /// On/off state of a switch; with it the node is no button.
  final bool? toggled;

  /// Marks a radio: one of a group of which only one can be checked.
  final bool inMutuallyExclusiveGroup;

  /// Announced as a link rather than a button.
  final bool link;

  /// An explicit role, e.g. [SemanticsRole.tab] or [SemanticsRole.menuItem];
  /// replaces the button role.
  final SemanticsRole? role;

  /// Further actions assistive technology offers on the node, by name — what
  /// a pointer reaches through a long press or a control it hides.
  final Map<CustomSemanticsAction, VoidCallback>? customSemanticsActions;

  /// Drops the child's own semantics, so [semanticLabel] is the whole
  /// announcement — e.g. an icon whose tooltip would otherwise repeat it.
  final bool excludeSemantics;

  /// Shows a value that can't change here — a read-only switch, checkbox or
  /// radio. With no [onTap] the target still joins the Tab order (unless
  /// [focusable] is false) and draws its focus ring, and is announced
  /// enabled and read-only with its state; it reports neither
  /// [WidgetState.disabled] nor [WidgetState.hovered], and the pointer keeps
  /// the [disabledCursor].
  final bool readOnly;

  const Tappable({
    super.key,
    required this.onTap,
    required Widget this.child,
    this.onHover,
    this.cursor,
    this.disabledCursor = SystemMouseCursors.basic,
    this.behavior = HitTestBehavior.opaque,
    this.focusable = true,
    this.focusNode,
    this.autofocus = false,
    this.onFocusChange,
    this.showFocusRing = true,
    this.focusRadius = 0,
    this.statesController,
    this.semanticLabel,
    this.selected,
    this.expanded,
    this.checked,
    this.mixed,
    this.toggled,
    this.inMutuallyExclusiveGroup = false,
    this.link = false,
    this.role,
    this.customSemanticsActions,
    this.excludeSemantics = false,
    this.readOnly = false,
  }) : builder = null,
       statesBuilder = null;

  const Tappable.builder({
    super.key,
    required this.onTap,
    required Widget Function(BuildContext, bool) this.builder,
    this.onHover,
    this.cursor,
    this.disabledCursor = SystemMouseCursors.basic,
    this.behavior = HitTestBehavior.opaque,
    this.focusable = true,
    this.focusNode,
    this.autofocus = false,
    this.onFocusChange,
    this.showFocusRing = true,
    this.focusRadius = 0,
    this.statesController,
    this.semanticLabel,
    this.selected,
    this.expanded,
    this.checked,
    this.mixed,
    this.toggled,
    this.inMutuallyExclusiveGroup = false,
    this.link = false,
    this.role,
    this.customSemanticsActions,
    this.excludeSemantics = false,
    this.readOnly = false,
  }) : child = null,
       statesBuilder = null;

  /// Content built from the live interaction states: [WidgetState.hovered],
  /// [WidgetState.pressed], [WidgetState.focused] (only while the keyboard
  /// highlight shows, so a click never lights it), [WidgetState.disabled]
  /// (no [onTap]) and [WidgetState.selected] ([selected] true).
  const Tappable.states({
    super.key,
    required this.onTap,
    required Widget Function(BuildContext, Set<WidgetState>) builder,
    this.onHover,
    this.cursor,
    this.disabledCursor = SystemMouseCursors.basic,
    this.behavior = HitTestBehavior.opaque,
    this.focusable = true,
    this.focusNode,
    this.autofocus = false,
    this.onFocusChange,
    this.showFocusRing = true,
    this.focusRadius = 0,
    this.statesController,
    this.semanticLabel,
    this.selected,
    this.expanded,
    this.checked,
    this.mixed,
    this.toggled,
    this.inMutuallyExclusiveGroup = false,
    this.link = false,
    this.role,
    this.customSemanticsActions,
    this.excludeSemantics = false,
    this.readOnly = false,
  }) : statesBuilder = builder,
       child = null,
       builder = null;

  @override
  State<Tappable> createState() => _TappableState();
}

class _TappableState extends State<Tappable> {
  WidgetStatesController? _ownStates;
  FocusNode? _ownFocusNode;

  /// Whether the pointer is over the target, whatever the controller holds.
  bool _pointerInside = false;

  /// Whether the keyboard focus highlight shows on the target.
  bool _showsFocus = false;

  /// Whether a check for a focusable inside the target is pending or done,
  /// in a debug build; cleared while the target cannot take focus.
  bool _debugNestedStopChecked = false;

  WidgetStatesController get _states =>
      widget.statesController ?? (_ownStates ??= WidgetStatesController());

  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode(debugLabel: 'Tappable'));

  bool get _enabled => widget.onTap != null;

  /// Read-only and inert: focusable and announced, but taking no input.
  bool get _readOnly => widget.readOnly && !_enabled;

  bool get _canFocus => widget.focusable && (_enabled || _readOnly);

  // Only watch the pointer when something consumes the flag, and only
  // rebuild for it when the child does.
  bool get _consumesHover =>
      widget.builder != null ||
      widget.statesBuilder != null ||
      widget.statesController != null;

  bool get _tracksHover => _consumesHover || widget.onHover != null;

  bool get _tracksPress =>
      _enabled &&
      (widget.statesBuilder != null || widget.statesController != null);

  /// Whether this target is a semantics node of its own; see [Tappable].
  bool get _announces =>
      _enabled ||
      _readOnly ||
      widget.semanticLabel != null ||
      widget.selected != null ||
      widget.expanded != null ||
      widget.checked != null ||
      widget.mixed != null ||
      widget.toggled != null ||
      widget.inMutuallyExclusiveGroup ||
      widget.link ||
      widget.role != null ||
      widget.customSemanticsActions != null;

  late final Map<Type, Action<Intent>> _actions = {
    ActivateIntent: CallbackAction<ActivateIntent>(
      onInvoke: (_) => _activate(),
    ),
    ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
      onInvoke: (_) => _activate(),
    ),
  };

  @override
  void initState() {
    super.initState();
    _syncStates();
    _states.addListener(_onStatesChanged);
    _focusNode.addListener(_onFocusNode);
    FocusManager.instance.addHighlightModeListener(_onHighlightMode);
  }

  @override
  void didUpdateWidget(Tappable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.statesController != oldWidget.statesController) {
      // Carry the live hover / press / focus over, so swapping controllers
      // mid-interaction doesn't drop a state the pointer or keyboard still
      // holds; an internal controller an external one replaces is released.
      final old = oldWidget.statesController ?? _ownStates;
      final carried = old?.value ?? const <WidgetState>{};
      old?.removeListener(_onStatesChanged);
      if (widget.statesController != null) {
        _ownStates?.dispose();
        _ownStates = null;
      }
      _states.addListener(_onStatesChanged);
      for (final state in carried) {
        if (state != WidgetState.disabled && state != WidgetState.selected) {
          _states.update(state, true);
        }
      }
    }
    if (widget.focusNode != oldWidget.focusNode) {
      (oldWidget.focusNode ?? _ownFocusNode)?.removeListener(_onFocusNode);
      final own = _ownFocusNode;
      if (widget.focusNode != null && own != null) {
        // Released once the coming build has handed its Focus the new node.
        _ownFocusNode = null;
        WidgetsBinding.instance.addPostFrameCallback((_) => own.dispose());
      }
      _focusNode.addListener(_onFocusNode);
    }
    _syncStates();
    _syncFocusHighlight();
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onHighlightMode);
    _focusNode.removeListener(_onFocusNode);
    _states.removeListener(_onStatesChanged);
    _ownStates?.dispose();
    _ownFocusNode?.dispose();
    super.dispose();
  }

  /// Synced here, ahead of the child, so nothing below has to change the
  /// controller (and so rebuild this target) in the middle of a build.
  void _syncStates() {
    _states.update(WidgetState.disabled, !_enabled && !_readOnly);
    if (_readOnly) _states.update(WidgetState.hovered, false);
    _states.update(WidgetState.selected, widget.selected ?? false);
    if (!_enabled) _states.update(WidgetState.pressed, false);
  }

  void _onStatesChanged() {
    if (mounted) setState(() {});
  }

  void _activate() => widget.onTap?.call();

  void _setHover(bool value) {
    if (_pointerInside == value) return;
    _pointerInside = value;
    if (_consumesHover && !_readOnly) {
      _states.update(WidgetState.hovered, value);
    }
    widget.onHover?.call(value);
  }

  void _setPressed(bool value) => _states.update(WidgetState.pressed, value);

  void _onFocusNode() {
    _syncFocusHighlight();
    // The node's own semantics carry the focused flag.
    if (_announces && mounted) setState(() {});
  }

  void _onHighlightMode(FocusHighlightMode _) => _syncFocusHighlight();

  /// Reports [WidgetState.focused] while the target itself holds focus — not
  /// a focusable inside it — and the keyboard highlight shows. Read from
  /// [FocusManager.highlightMode] on every change rather than cached: a
  /// connected mouse can switch the mode without notifying. Only a change is
  /// written, so a pinned focus stays.
  void _syncFocusHighlight() {
    final shows =
        _focusNode.hasPrimaryFocus &&
        _canFocus &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    if (shows == _showsFocus) return;
    _showsFocus = shows;
    _states.update(WidgetState.focused, shows);
  }

  /// Once the target can take focus, checks after the frame that no Tab stop
  /// inside it covers half of it or more, which Tab would reach as the same
  /// control again; see [Tappable].
  void _debugCheckNestedStop() {
    if (!_canFocus) {
      _debugNestedStopChecked = false;
      return;
    }
    if (_debugNestedStopChecked) return;
    _debugNestedStopChecked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final node = _focusNode;
      if (!_canFocus || !node.canRequestFocus || node.skipTraversal) return;
      final box = context.findRenderObject();
      if (box is! RenderBox || !box.hasSize || box.size.isEmpty) return;
      // Both rects are global, so a scale above the Tappable cancels out.
      final area = node.rect.width * node.rect.height;
      if (area <= 0) return;
      final inner = _tabStopsUnder(node).where((inner) {
        final innerBox = inner.context?.findRenderObject();
        if (innerBox is! RenderBox || !innerBox.hasSize) return false;
        final covered = node.rect.intersect(inner.rect);
        if (covered.width <= 0 || covered.height <= 0) return false;
        return covered.width * covered.height >= area / 2;
      }).firstOrNull;
      if (inner == null) return;
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: FlutterError.fromParts([
            // Not user-facing: a debug-build report for the developer.
            ErrorSummary('A Tappable wraps a Tab stop of its own.'),
            ErrorDescription(
              // Not user-facing: a debug-build report for the developer.
              'The Tappable joins the Tab order, and so does a focusable '
              'that covers most of it, so Tab stops on the same control '
              'twice.',
            ),
            DiagnosticsDebugCreator(DebugCreator(context as Element)),
            DiagnosticsProperty<FocusNode>('The focusable inside it', inner),
            if (inner.context case final inner?)
              inner.describeWidget('Its widget'),
            ErrorHint(
              // Not user-facing: a debug-build report for the developer.
              'Pass `focusable: false` to the Tappable when the child is the '
              'control (a Button, an InkWell, a TextField, a nested '
              'Tappable), or give the Tappable a focusNode whose '
              'skipTraversal is set for roving focus. A row that is its own '
              'Tab stop and holds its own actions keeps both by putting the '
              'actions under a Focus(parentNode:) whose node wraps the '
              'Tappable, so they are its siblings in the focus tree.',
            ),
          ]),
          library: 'admin_ui',
          context: ErrorDescription(
            'while checking a Tappable for a nested Tab stop',
          ),
        ),
      );
    });
  }

  /// The nodes under [node] that Tab stops on, walking only into nodes whose
  /// descendants can be traversed. A scope is walked into, not stopped on.
  static Iterable<FocusNode> _tabStopsUnder(FocusNode node) sync* {
    if (!node.descendantsAreFocusable || !node.descendantsAreTraversable) {
      return;
    }
    for (final child in node.children) {
      if (child is! FocusScopeNode &&
          child.canRequestFocus &&
          !child.skipTraversal) {
        yield child;
      }
      yield* _tabStopsUnder(child);
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(() {
      _debugCheckNestedStop();
      return true;
    }());
    final enabled = _enabled;
    final cursor = enabled
        ? (widget.cursor ?? SystemMouseCursors.click)
        : widget.disabledCursor;
    final states = _states.value;

    var child = widget.statesBuilder != null
        ? widget.statesBuilder!(context, states)
        : widget.builder != null
        ? widget.builder!(context, states.contains(WidgetState.hovered))
        : widget.child!;
    if (widget.showFocusRing) {
      child = FocusRing(
        focused: states.contains(WidgetState.focused),
        radius: widget.focusRadius,
        child: child,
      );
    }

    final tracksPress = _tracksPress;
    child = GestureDetector(
      behavior: widget.behavior,
      // The node's own semantics below carry the tap.
      excludeFromSemantics: true,
      onTap: widget.onTap,
      onTapDown: tracksPress ? (_) => _setPressed(true) : null,
      onTapUp: tracksPress ? (_) => _setPressed(false) : null,
      onTapCancel: tracksPress ? () => _setPressed(false) : null,
      child: child,
    );

    final tracksHover = _tracksHover;
    child = CursorRegion(
      cursor: cursor,
      onEnter: tracksHover ? (_) => _setHover(true) : null,
      onExit: tracksHover ? (_) => _setHover(false) : null,
      child: child,
    );

    return FocusableActionDetector(
      enabled: _canFocus,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      actions: _actions,
      includeFocusSemantics: false,
      onFocusChange: widget.onFocusChange,
      child: _semantics(child),
    );
  }

  /// Always present, so the child keeps its place in the tree as the target
  /// starts or stops announcing itself.
  Widget _semantics(Widget child) {
    if (!_announces) {
      return Semantics(excludeSemantics: widget.excludeSemantics, child: child);
    }
    final enabled = _enabled;
    final canFocus = _canFocus;
    final plain =
        !widget.link &&
        widget.role == null &&
        widget.checked == null &&
        widget.mixed == null &&
        widget.toggled == null;
    return Semantics(
      container: true,
      excludeSemantics: widget.excludeSemantics,
      button: plain ? true : null,
      link: widget.link ? true : null,
      role: widget.role,
      enabled: enabled || _readOnly,
      readOnly: _readOnly ? true : null,
      label: widget.semanticLabel,
      selected: widget.selected,
      expanded: widget.expanded,
      checked: widget.mixed == true ? false : widget.checked,
      mixed: widget.mixed,
      toggled: widget.toggled,
      inMutuallyExclusiveGroup: widget.inMutuallyExclusiveGroup ? true : null,
      focusable: canFocus,
      focused: canFocus ? _focusNode.hasPrimaryFocus : null,
      onFocus: canFocus && defaultTargetPlatform != TargetPlatform.iOS
          ? _focusNode.requestFocus
          : null,
      onTap: widget.onTap,
      customSemanticsActions: widget.customSemanticsActions,
      child: child,
    );
  }
}

/// A [MouseRegion] that marks a pointer target, where no text is selected.
///
/// Under an ancestor [SelectionArea] every [Text] is selectable and puts up a
/// mouse region of its own, with the text I-beam, which sits inside this one
/// and so wins: a bare MouseRegion with the click cursor shows the I-beam
/// over its label, and a drag across the label selects it. Flutter ties the
/// two together (see `Text.build`), so this takes the text out of the
/// selection with [SelectionContainer.disabled], and the I-beam goes with
/// it: [cursor] shows over the whole region. [InkWell] instead hands its
/// cursor down through [DefaultSelectionStyle] and leaves its label
/// selectable, which a tap target must not be. [MouseCursor.defer] marks no
/// target, so text in such a region keeps its I-beam and selects.
///
/// The container is put up whether or not a [SelectionArea] is above, so a
/// widget that opens a selection area of its own where none is above it
/// ([MentionText]) can see it is under a target and stay plain.
///
/// The pointer half of a tap target whose keyboard and assistive-technology
/// path is elsewhere (a table cell, a listbox option, a popover's anchor):
/// wrap its [GestureDetector] in this. A target that is a control of its own
/// is a [Tappable], which uses this. `test/selection_cursor_test.dart` refuses
/// a MouseRegion given the click cursor anywhere else in the repo, and checks
/// what a drag selects; the example's selection sweep checks every demo.
class CursorRegion extends StatelessWidget {
  final MouseCursor cursor;
  final PointerEnterEventListener? onEnter;
  final PointerExitEventListener? onExit;
  final PointerHoverEventListener? onHover;

  /// As [MouseRegion.opaque].
  final bool opaque;
  final Widget child;

  const CursorRegion({
    super.key,
    required this.cursor,
    this.onEnter,
    this.onExit,
    this.onHover,
    this.opaque = true,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: cursor,
    onEnter: onEnter,
    onExit: onExit,
    onHover: onHover,
    opaque: opaque,
    child: cursor == MouseCursor.defer
        ? child
        : SelectionContainer.disabled(child: child),
  );
}
