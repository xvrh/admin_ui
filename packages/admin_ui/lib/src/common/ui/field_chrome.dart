/// @docImport '../../theme/radii.dart';
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show internal;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../theme/field_style.dart';
import '../../theme/palette.dart';
import '../../theme/sizes.dart';
import '../../theme/stroke.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import 'icon_action.dart';
import 'popover.dart';
import 'tappable.dart';

/// Marks a subtree whose host already draws the field chrome (border, fill,
/// focus ring) around an embedded editor — e.g. the target lane of a
/// `SourceTargetPair`. Bodies consult it and drop their own box: [FieldChrome]
/// renders bare, `fieldInputDecoration` returns a border-less decoration.
/// Editors stay unaware; the choke points adapt.
class ChromelessFieldScope extends InheritedWidget {
  /// False under [ChromelessFieldScope.reset].
  final bool chromeless;

  const ChromelessFieldScope({super.key, required super.child})
    : chromeless = true;

  /// Gives the chrome back under an outer scope, to a field that is not the
  /// host's own — a popover's filter or hex box, which floats away from the
  /// host's box and so draws one of its own.
  const ChromelessFieldScope.reset({super.key, required super.child})
    : chromeless = false;

  static bool of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<ChromelessFieldScope>()
          ?.chromeless ??
      false;

  @override
  bool updateShouldNotify(ChromelessFieldScope old) =>
      chromeless != old.chromeless;
}

/// The state a field draws itself in — [enabled], [readOnly], [invalid] — and
/// the one set of colours every body resolves it to. Read the ambient state
/// with [FieldStateScope.of].
///
/// **Read-only and disabled** are different things, and every body follows
/// the same rule:
/// - A body with a null `onChanged` is READ-ONLY, as is one under a
///   read-only scope. It stays at full contrast, stays focusable and
///   selectable (its value can be read, copied and announced), and shows no
///   chevron, caret or hover. It opens nothing and edits nothing.
/// - DISABLED comes only from `FieldStateScope(enabled: false)` or an
///   explicit `enabled: false`: dimmed text on the disabled fill, a muted
///   outline, out of the Tab order.
///
/// [invalid] reddens the outline in either case.
@immutable
class FieldState {
  final bool enabled;
  final bool readOnly;
  final bool invalid;

  const FieldState({
    this.enabled = true,
    this.readOnly = false,
    this.invalid = false,
  });

  /// This state with a widget's own flags folded in: a false [enabled]
  /// disables, a true [readOnly] or [invalid] adds.
  FieldState merge({
    bool enabled = true,
    bool readOnly = false,
    bool invalid = false,
  }) {
    return FieldState(
      enabled: this.enabled && enabled,
      readOnly: this.readOnly || readOnly,
      invalid: this.invalid || invalid,
    );
  }

  /// The widget states the chrome resolves in: [WidgetState.disabled],
  /// [WidgetState.error], and [focused] and [hovered] where they apply — a
  /// disabled field takes neither, a read-only one no hover.
  Set<WidgetState> states({bool hovered = false, bool focused = false}) => {
    if (!enabled) WidgetState.disabled,
    if (invalid) WidgetState.error,
    if (focused && enabled) WidgetState.focused,
    if (hovered && enabled && !readOnly) WidgetState.hovered,
  };

  /// The value's colour: [AdminPalette.foreground],
  /// [AdminPalette.foregroundSubtle] when disabled. Read-only keeps full
  /// contrast.
  Color textColor(AdminPalette palette) =>
      enabled ? palette.foreground : palette.foregroundSubtle;

  /// A leading or trailing glyph's colour: [AdminPalette.foregroundMuted],
  /// [AdminPalette.foregroundSubtle] when disabled.
  Color iconColor(AdminPalette palette) =>
      enabled ? palette.foregroundMuted : palette.foregroundSubtle;

  /// The fill at rest: [AdminPalette.fieldFill], or the disabled fill (see
  /// [fieldFillColor]).
  Color fillColor(AdminPalette palette) => fieldFillColor(palette, states());

  /// The outline while [hovered] and [focused] (see [fieldBorderSide]), in
  /// the widths of [stroke] and the accents of [style]: pass
  /// `context.stroke` and `context.fieldStyle`. This is an outlined box's
  /// edge; a body draws its box in the theme's anatomy with
  /// `fieldDecoration` or `FieldBorder` over [states].
  BorderSide borderSide(
    AdminPalette palette, {
    bool hovered = false,
    bool focused = false,
    required AdminStroke stroke,
    AdminFieldStyle style = const AdminFieldStyle(),
  }) => fieldBorderSide(
    palette,
    states(hovered: hovered, focused: focused),
    stroke: stroke,
    style: style,
  );

  /// The outline's colour; see [borderSide].
  Color borderColor(
    AdminPalette palette, {
    bool hovered = false,
    bool focused = false,
    required AdminStroke stroke,
    AdminFieldStyle style = const AdminFieldStyle(),
  }) => borderSide(
    palette,
    hovered: hovered,
    focused: focused,
    stroke: stroke,
    style: style,
  ).color;

  /// The halo around the outline while [focused] (see [fieldFocusHalo]), in
  /// the widths of [stroke] and the accent of [style]: pass `context.stroke`
  /// and `context.fieldStyle`.
  BorderSide focusHalo(
    AdminPalette palette, {
    bool focused = false,
    required AdminStroke stroke,
    AdminFieldStyle style = const AdminFieldStyle(),
  }) => fieldFocusHalo(
    palette,
    states(focused: focused),
    stroke: stroke,
    style: style,
  );

  @override
  bool operator ==(Object other) =>
      other is FieldState &&
      other.enabled == enabled &&
      other.readOnly == readOnly &&
      other.invalid == invalid;

  @override
  int get hashCode => Object.hash(enabled, readOnly, invalid);

  @override
  String toString() =>
      'FieldState(enabled: $enabled, readOnly: $readOnly, invalid: $invalid)';
}

/// Carries a [FieldState] down to every field body under it — the one way a
/// field shell or a form turns its bodies red, disabled or read-only without
/// threading a flag through each of them. [FieldChrome], [FieldTrigger],
/// [FieldChevron], `fieldInputDecoration` and `fieldTextStyle` all read it;
/// a body that builds its own control reads [of].
///
/// A scope nested in another combines with it: [enabled] only while both
/// are, [readOnly] while either is, and [invalid] is the inner scope's own —
/// a validation error belongs to the field that owns it, not to the fields
/// nested inside it.
class FieldStateScope extends StatelessWidget {
  final bool enabled;
  final bool readOnly;
  final bool invalid;
  final Widget child;

  const FieldStateScope({
    super.key,
    this.enabled = true,
    this.readOnly = false,
    this.invalid = false,
    required this.child,
  });

  /// The nearest scope's state combined with the scopes above it, or the
  /// default (enabled, editable, valid) outside any.
  static FieldState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_FieldStateMarker>()?.state ??
      const FieldState();

  @override
  Widget build(BuildContext context) {
    final outer = of(context);
    return _FieldStateMarker(
      state: FieldState(
        enabled: enabled && outer.enabled,
        readOnly: readOnly || outer.readOnly,
        invalid: invalid,
      ),
      child: child,
    );
  }
}

class _FieldStateMarker extends InheritedWidget {
  final FieldState state;

  const _FieldStateMarker({required this.state, required super.child});

  @override
  bool updateShouldNotify(_FieldStateMarker old) => state != old.state;
}

/// The widest edge a field's box draws on each side over every state it
/// takes — at rest, hovered, focused, disabled, and in error focused or not
/// (see `resolveFieldChrome`). A body that lays its own content inside the
/// box keeps this much room, so no state's edge runs under the content.
@internal
EdgeInsets fieldEdgeRoom(AdminTokens tokens) {
  const all = <Set<WidgetState>>[
    {},
    {WidgetState.hovered},
    {WidgetState.focused},
    {WidgetState.disabled},
    {WidgetState.error},
    {WidgetState.error, WidgetState.focused},
  ];
  var room = EdgeInsets.zero;
  for (final states in all) {
    final edges = resolveFieldChrome(tokens, states).border;
    // Physical: as the chrome's edges, whose rule is at the bottom.
    room = EdgeInsets.fromLTRB(
      math.max(room.left, edges.left),
      math.max(room.top, edges.top),
      math.max(room.right, edges.right),
      math.max(room.bottom, edges.bottom),
    );
  }
  return room;
}

/// The box of a toolbar trigger that opens a filter or a choice (a filter
/// pill, a type menu), in [states] from its `Tappable`: the theme's field
/// anatomy, as a select beside it draws, hovered while hovered or pressed.
/// Once [active] (a filter is applied) it is tinted: `primarySubtle` under
/// the state's wash, its edges, whichever the anatomy draws, in `primary`.
@internal
FieldChromeSpec filterTriggerChrome(
  AdminTokens tokens,
  Set<WidgetState> states, {
  required bool active,
}) {
  final disabled = states.contains(WidgetState.disabled);
  final pressed = states.contains(WidgetState.pressed);
  final hovered = states.contains(WidgetState.hovered);
  if (!active || disabled) {
    return resolveFieldChrome(tokens, {
      if (disabled) WidgetState.disabled,
      if (hovered || pressed) WidgetState.hovered,
    });
  }
  final colors = tokens.palette;
  final rest = resolveFieldChrome(tokens, const {});
  final wash = pressed
      ? colors.pressedOverlay
      : hovered
      ? colors.hoverOverlay
      : null;
  BorderSide accent(BorderSide side) => side.style == BorderStyle.none
      ? side
      : side.copyWith(color: colors.primary);
  return rest.copyWith(
    fill: wash == null
        ? colors.primarySubtle
        : Color.alphaBlend(wash, colors.primarySubtle),
    outline: accent(rest.outline),
    rule: accent(rest.rule),
  );
}

/// The padding [FieldChrome] and [FieldTrigger] default to, inside a
/// control-wide edge ([AdminStroke.control]): the content starts
/// `fieldPaddingX` from the box's outer edge, where an input's text does,
/// and there is room above and below for one inline-slot row (a 24px chip or
/// action) in the control height, so a single line centres exactly and
/// taller content still breathes.
EdgeInsets _defaultPadding(BuildContext context, ControlSize size) {
  final sizes = context.sizes;
  final border = context.stroke.control;
  return EdgeInsets.symmetric(
    horizontal: sizes.fieldPaddingX - border,
    vertical: math.max(
      0,
      (sizes.height(size) - IconActionSize.inline.box) / 2 - border,
    ),
  );
}

/// The box every field trigger and input sits in — one place for the control
/// height, the theme's field anatomy (an outlined, filled or underlined box,
/// `context.fieldStyle`), its hover, active (open/focused), disabled,
/// read-only and error states, and the padding compensation that keeps the
/// content still when an edge thickens on activation. Every state is drawn
/// by `resolveFieldChrome`, as the theme's input is
/// (`buildInputDecorationTheme`), at [AdminRadii.radiusField].
///
/// The box is at least the [size]'s control height (`context.sizes`), with
/// the content centred vertically in it — unless [inline]. [enabled],
/// [readOnly] and [invalid] fold into the ambient [FieldStateScope], and the
/// content is built under the result, so a [FieldChevron] or
/// `fieldTextStyle` inside matches the box.
///
/// Pure chrome: it owns the decoration + padding only. For a trigger that
/// opens a popover use [FieldTrigger]; otherwise wrap it in a [Tappable] for
/// tap behaviour and put the trigger's content in [child].
class FieldChrome extends StatelessWidget {
  /// Open or focused — draws the theme's focus indicator (the whole edge, or
  /// the bottom rule of an underline-focused field) [AdminStroke.fieldFocus]
  /// wide, and the theme's [fieldFocusHalo] around it.
  final bool active;

  /// False draws the disabled fill and outline.
  final bool enabled;

  /// Drops the hover state; the box otherwise looks editable.
  final bool readOnly;

  /// Draws the danger edge, [AdminStroke.fieldError] wide (the wider of it
  /// and [AdminStroke.fieldFocus] while [active]).
  final bool invalid;

  /// Under the pointer — a step stronger edge (and a filled box's hover
  /// fill). Also pins the state in a catalog.
  final bool hovered;

  final ControlSize size;

  /// Resting padding inside a control-wide edge ([AdminStroke.control]),
  /// whichever edges the theme's anatomy draws; the compensation for a wider
  /// active or error edge is applied on top so the content never shifts.
  /// Defaults to content `context.sizes.fieldPaddingX` from the outer edge
  /// either side, and room for a 24px row above and below.
  final EdgeInsetsGeometry? padding;

  /// Corner radius; defaults to the token [AdminRadii.radiusField]. A filled
  /// box keeps its bottom corners square.
  final double? radius;

  /// A box drawn around inline content rather than as a control — an
  /// editable chip in a row of chips: as tall as its [padding] and content,
  /// with no control-height floor.
  final bool inline;

  final Widget child;

  const FieldChrome({
    super.key,
    required this.child,
    this.padding,
    this.active = false,
    this.enabled = true,
    this.readOnly = false,
    this.invalid = false,
    this.hovered = false,
    this.size = ControlSize.medium,
    this.radius,
    this.inline = false,
  });

  @override
  Widget build(BuildContext context) {
    final state = FieldStateScope.of(context)
        .merge(enabled: enabled, readOnly: readOnly, invalid: invalid);
    final content = _FieldStateMarker(state: state, child: child);
    if (ChromelessFieldScope.of(context)) return content;
    final tokens = context.adminTokens;
    final height = tokens.sizes.height(size);
    final pad = (padding ?? _defaultPadding(context, size)).resolve(
      Directionality.of(context),
    );
    final states = state.states(hovered: hovered, focused: active);
    final edges = resolveFieldChrome(tokens, states).border;
    final corners = BorderRadius.circular(radius ?? tokens.radii.radiusField);
    // The content sits [pad] inside a control-wide edge on every side, in
    // every anatomy and state. The decoration pads by the edges this state
    // draws, so they come off here: a thicker outline or rule moves nothing.
    final inset = pad + EdgeInsets.all(tokens.stroke.control);
    return Container(
      constraints: BoxConstraints(minHeight: inline ? 0 : height),
      padding: (inset - edges).clamp(
        EdgeInsets.zero,
        EdgeInsetsGeometry.infinity,
      ),
      decoration: fieldDecoration(tokens, states, corners),
      // Drawn outside the box, so it takes no room and moves nothing.
      foregroundDecoration: fieldForegroundDecoration(tokens, states, corners),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: 1,
        heightFactor: 1,
        child: content,
      ),
    );
  }
}

/// A field's popover trigger (a select, a date, a colour): a [FieldChrome]
/// that is one Tab stop, opens [controller] on Enter, Space, ArrowDown and
/// Alt+ArrowDown, and announces itself as a button with its expanded state.
/// The pointer draws the hover edge; focus draws the theme's field focus
/// indicator, as a focused input does, and no separate focus ring.
///
/// [chevron] draws the [FieldChevron] at the box's end. [trailing] is an
/// action of its own just before it — a clear button — laid over a 24px slot
/// kept free after [child] rather than nested in the trigger, so it is a
/// separate Tab stop and its hit box never grows the field. Both slots sit so
/// their 16px glyphs line up with `fieldPaddingX`, and [child]'s text ends
/// `fieldIconGap` before them.
///
/// Read-only (here or from the [FieldStateScope]) keeps the box at full
/// contrast and in the Tab order, announces its value as read-only, opens
/// nothing, and drops the chevron and [trailing]. Disabled takes no input.
class FieldTrigger extends StatefulWidget {
  final PopoverController controller;

  /// False renders the disabled chrome and takes no input.
  final bool enabled;

  /// Shows the value without opening; see [FieldTrigger].
  final bool readOnly;

  /// Draws the error border, as [FieldChrome.invalid].
  final bool invalid;

  final ControlSize size;

  /// Defaults as [FieldChrome.padding].
  final EdgeInsetsGeometry? padding;

  /// Draws the [FieldChevron] at the end of the box.
  final bool chevron;

  /// Announced ahead of [child]'s own text.
  final String? semanticLabel;

  /// Called the frame after a keyboard activation opens the popover, to move
  /// focus into it: the selected option, a filter box, the first cell.
  final VoidCallback? onKeyboardOpen;

  final Widget? trailing;

  /// Reports, and can seed, the hovered and focused states of an editable
  /// trigger, as [Tappable.statesController] does — e.g. to pin one in a
  /// catalog without a pointer or keyboard.
  final WidgetStatesController? statesController;

  final Widget child;

  const FieldTrigger({
    super.key,
    required this.controller,
    required this.child,
    this.padding,
    this.enabled = true,
    this.readOnly = false,
    this.invalid = false,
    this.size = ControlSize.medium,
    this.chevron = false,
    this.semanticLabel,
    this.onKeyboardOpen,
    this.trailing,
    this.statesController,
  });

  @override
  State<FieldTrigger> createState() => _FieldTriggerState();
}

class _FieldTriggerState extends State<FieldTrigger> {
  final _focusNode = FocusNode(debugLabel: 'FieldTrigger');

  /// Whether a read-only trigger shows the keyboard focus highlight.
  bool _readOnlyFocus = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _toggle() {
    final controller = widget.controller;
    if (controller.isOpen) {
      controller.close();
      return;
    }
    // A pointer tap never focuses the trigger, so holding focus here means
    // the keyboard opened it.
    final fromKeyboard = _focusNode.hasPrimaryFocus;
    controller.open();
    if (fromKeyboard && widget.onKeyboardOpen != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && controller.isOpen) widget.onKeyboardOpen!();
      });
    }
  }

  void _open() {
    if (!widget.controller.isOpen) _toggle();
  }

  @override
  Widget build(BuildContext context) {
    final state = FieldStateScope.of(context).merge(
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      invalid: widget.invalid,
    );
    final sizes = context.sizes;
    final padding = (widget.padding ?? _defaultPadding(context, widget.size))
        .resolve(Directionality.of(context));
    final editable = state.enabled && !state.readOnly;
    final trailing = editable ? widget.trailing : null;
    final chevron = widget.chevron && !state.readOnly;

    final slot = IconActionSize.inline.box;
    final glyphInset = (slot - sizes.fieldIcon) / 2;
    final slots = (trailing == null ? 0 : 1) + (chevron ? 1 : 0);
    final content = slots == 0
        ? widget.child
        : Row(
            children: [
              Expanded(child: widget.child),
              SizedBox(
                width: slots * slot + sizes.fieldIconGap - 2 * glyphInset,
              ),
            ],
          );

    FieldChrome chrome({required bool active, bool hovered = false}) =>
        FieldChrome(
          active: active,
          hovered: hovered,
          enabled: state.enabled,
          readOnly: state.readOnly,
          invalid: state.invalid,
          size: widget.size,
          padding: padding,
          child: content,
        );

    Widget trigger;
    if (state.readOnly && state.enabled) {
      trigger = FocusableActionDetector(
        focusNode: _focusNode,
        // Rebuilt for the node's focused flag.
        onFocusChange: (_) => setState(() {}),
        onShowFocusHighlight: (shown) {
          if (shown != _readOnlyFocus) setState(() => _readOnlyFocus = shown);
        },
        child: Semantics(
          container: true,
          readOnly: true,
          focusable: true,
          focused: _focusNode.hasFocus,
          label: widget.semanticLabel,
          child: chrome(active: _readOnlyFocus),
        ),
      );
    } else {
      trigger = Tappable.states(
        onTap: editable ? _toggle : null,
        focusNode: _focusNode,
        // The chrome's own focus indicator shows keyboard focus, as an
        // input's does, so the trigger draws no second ring.
        showFocusRing: false,
        statesController: widget.statesController,
        semanticLabel: widget.semanticLabel,
        expanded: widget.controller.isOpen,
        builder: (context, states) => chrome(
          active:
              widget.controller.isOpen || states.contains(WidgetState.focused),
          hovered: states.contains(WidgetState.hovered),
        ),
      );
    }
    if (editable) {
      trigger = CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowDown): _open,
          const SingleActivator(LogicalKeyboardKey.arrowDown, alt: true): _open,
        },
        child: trigger,
      );
    }
    if (slots == 0) return trigger;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Stack(
      children: [
        trigger,
        PositionedDirectional(
          top: 0,
          bottom: 0,
          // The padding sits inside the resting border.
          end:
              (rtl ? padding.left : padding.right) +
              context.stroke.control -
              glyphInset,
          child: _FieldStateMarker(
            state: state,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (trailing != null)
                  SizedBox.square(
                    dimension: slot,
                    child: Center(child: trailing),
                  ),
                // Drawn over the trigger, so the pointer passes through it.
                if (chevron) const IgnorePointer(child: FieldChevron()),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The one chevron every field trigger shows — combobox, select, multi-select,
/// date, date range and colour: a 16px [Icons.keyboard_arrow_down_rounded]
/// centred in the 24px inline slot, in [AdminPalette.foregroundMuted]
/// ([AdminPalette.foregroundSubtle] when disabled). A read-only field shows
/// none: this renders nothing. Decorative — the trigger announces its own
/// expanded state.
///
/// [FieldTrigger] places it with `chevron: true`; an input takes it as
/// `fieldInputDecoration(suffix: const FieldChevron())`. Both slots line its
/// glyph up with `fieldPaddingX`.
class FieldChevron extends StatelessWidget {
  final bool enabled;
  final bool readOnly;

  const FieldChevron({super.key, this.enabled = true, this.readOnly = false});

  @override
  Widget build(BuildContext context) {
    final state = FieldStateScope.of(context)
        .merge(enabled: enabled, readOnly: readOnly);
    if (state.readOnly) return const SizedBox.shrink();
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: IconActionSize.inline.box,
        child: Center(
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: context.sizes.fieldIcon,
            color: state.iconColor(context.colors),
          ),
        ),
      ),
    );
  }
}
