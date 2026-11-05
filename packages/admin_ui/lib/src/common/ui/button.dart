import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../theme/button_style.dart';
import '../../theme/palette.dart';
import '../../theme/sizes.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import '../text_metrics.dart';
import 'focus_ring.dart';
import 'menu.dart';
import 'popover.dart';
import 'severity.dart';
import 'spinner.dart';
import 'tip.dart';

/// Visual weight of a [Button]. Any of them can be destructive: see
/// [Button.danger].
enum ButtonVariant {
  /// Primary fill — the single primary action on a surface.
  primary,

  /// Surface fill with a token border — the default, secondary action. A
  /// theme may draw it filled instead (`AdminButtonStyle.filledSecondary`).
  secondary,

  /// No fill or border until hovered — tertiary / in-row actions.
  ghost,

  /// The primary text colour with no fill or border, underlined under the
  /// pointer: an action that reads as a link. Laid out as [ghost], with no
  /// minimum width.
  link,

  /// A soft, tonal fill (the palette's `softFill`, content in `onSoft`):
  /// weightier than [secondary], quieter than [primary], like M3's filled
  /// tonal button.
  soft,
}

/// The shared button for the admin UI.
///
/// Built on [Material] + [InkWell], without ink: filled variants (primary,
/// danger) hover and press by switching to the palette's hover / active fill,
/// and the others lay a hover / pressed wash over theirs. [danger] recolours
/// any variant as destructive. Keyboard focus draws the theme's focus ring.
/// [loading] blocks the tap and shows a spinner — in the glyph's slot when
/// there is an [icon], else centred over the hidden content — at exactly the
/// resting width, and adds "Loading" to what a screen reader hears. A null
/// [onPressed] renders the disabled look the theme's
/// [AdminButtonStyle.disabled] names.
///
/// Colours and type come from the theme tokens, the corner from
/// `AdminRadii.button`, and the height from the theme's control height at
/// [size]; the padding, label alignment, glyph placement, minimum width and
/// label weight from `context.buttonStyle`, which [style] overrides for one
/// button.
///
/// [Button.icon] is the icon-only form: a square of the control height.
class Button extends StatefulWidget {
  /// The visible label; for [Button.icon], its [semanticLabel].
  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ControlSize size;

  /// A destructive action, in the danger colours of its [variant]: a danger
  /// fill for [ButtonVariant.primary] ([Button.danger]), danger text in a
  /// danger outline for [ButtonVariant.secondary], danger text for
  /// [ButtonVariant.ghost] and [ButtonVariant.link], and the danger tint for
  /// [ButtonVariant.soft].
  final bool danger;

  /// The glyph beside the label (before it, or at the end edge where the
  /// theme places it there; a ghost or link button, which has no box to
  /// take the edge of, puts it just after the label); a spinner takes its
  /// place while [loading].
  final IconData? icon;

  /// Trailing glyph (e.g. a chevron on a menu trigger).
  final IconData? trailingIcon;

  /// The [icon]'s colour in place of the label's, for a glyph that reports
  /// a status: the check after a copy, a failure's warning. A disabled
  /// button keeps its own.
  final Color? iconColor;

  /// Shows a spinner and blocks the tap, at the button's resting width.
  final bool loading;

  /// Stretches to the full width of a bounded parent.
  final bool expand;

  /// Pulls a ghost or link button back by its start padding, so at rest its
  /// glyph (or its label) lines up with the content edge it sits under — an
  /// "Add row" under a field's rows, a copy action under a line of text. Its
  /// content starts there even when the button is wider than it ([expand]).
  /// Its hover fill and focus ring reach into the gutter before that edge;
  /// its layout box does not move.
  final bool flush;

  /// This button's anatomy in place of the theme's `context.buttonStyle`:
  /// its members win, and a null [AdminButtonStyle.padding],
  /// [AdminButtonStyle.minWidth] or [AdminButtonStyle.labelWeight] keeps the
  /// theme's. Start from `context.buttonStyle.copyWith(…)` to change one
  /// member.
  final AdminButtonStyle? style;

  /// Reports, and can seed, the button's interaction states (hovered,
  /// pressed, focused), like the Material buttons' `statesController` — e.g.
  /// to show a state in a catalog without a pointer or keyboard. The button
  /// keeps [WidgetState.disabled] in sync. Created internally when null.
  final WidgetStatesController? statesController;

  final FocusNode? focusNode;
  final bool autofocus;

  /// The accessible name. A labelled button is named by its [label] unless
  /// this replaces it, for a label that is ambiguous out of context; an
  /// icon-only one ([Button.icon]) always has one, and shows it as its
  /// tooltip.
  final String? semanticLabel;

  /// Shown on hover and keyboard focus. An icon-only button shows its
  /// [semanticLabel] when this is null.
  final String? tooltip;

  /// Why the button is disabled, as its tooltip while [onPressed] is null, in
  /// place of [tooltip].
  final String? disabledHint;

  final bool _iconOnly;

  /// Set on the two segments of a [SplitButton]: which side of the join this
  /// button is, which squares its inner corners and leaves the outline to
  /// the group.
  final _Join? _join;

  /// The disclosed menu's state, announced on a [SplitButton]'s caret.
  final bool? _expanded;

  const Button(
    this.label, {
    super.key,
    this.onPressed,
    this.variant = ButtonVariant.secondary,
    this.size = ControlSize.medium,
    this.danger = false,
    this.icon,
    this.trailingIcon,
    this.iconColor,
    this.loading = false,
    this.expand = false,
    this.style,
    this.tooltip,
    this.disabledHint,
    this.semanticLabel,
    this.statesController,
    this.focusNode,
    this.autofocus = false,
  }) : flush = false,
       _iconOnly = false,
       _join = null,
       _expanded = null;

  const Button.primary(
    this.label, {
    super.key,
    this.onPressed,
    this.size = ControlSize.medium,
    this.danger = false,
    this.icon,
    this.trailingIcon,
    this.iconColor,
    this.loading = false,
    this.expand = false,
    this.style,
    this.tooltip,
    this.disabledHint,
    this.semanticLabel,
    this.statesController,
    this.focusNode,
    this.autofocus = false,
  }) : variant = ButtonVariant.primary,
       flush = false,
       _iconOnly = false,
       _join = null,
       _expanded = null;

  const Button.ghost(
    this.label, {
    super.key,
    this.onPressed,
    this.size = ControlSize.medium,
    this.danger = false,
    this.icon,
    this.trailingIcon,
    this.iconColor,
    this.loading = false,
    this.expand = false,
    this.flush = false,
    this.style,
    this.tooltip,
    this.disabledHint,
    this.semanticLabel,
    this.statesController,
    this.focusNode,
    this.autofocus = false,
  }) : variant = ButtonVariant.ghost,
       _iconOnly = false,
       _join = null,
       _expanded = null;

  /// The destructive primary action: a [ButtonVariant.primary] button with
  /// [danger] set.
  const Button.danger(
    this.label, {
    super.key,
    this.onPressed,
    this.size = ControlSize.medium,
    this.icon,
    this.trailingIcon,
    this.iconColor,
    this.loading = false,
    this.expand = false,
    this.style,
    this.tooltip,
    this.disabledHint,
    this.semanticLabel,
    this.statesController,
    this.focusNode,
    this.autofocus = false,
  }) : variant = ButtonVariant.primary,
       danger = true,
       flush = false,
       _iconOnly = false,
       _join = null,
       _expanded = null;

  /// [ButtonVariant.link]: an action that reads as a link, laid out as a
  /// ghost button.
  const Button.link(
    this.label, {
    super.key,
    this.onPressed,
    this.size = ControlSize.medium,
    this.danger = false,
    this.icon,
    this.trailingIcon,
    this.iconColor,
    this.loading = false,
    this.expand = false,
    this.flush = false,
    this.style,
    this.tooltip,
    this.disabledHint,
    this.semanticLabel,
    this.statesController,
    this.focusNode,
    this.autofocus = false,
  }) : variant = ButtonVariant.link,
       _iconOnly = false,
       _join = null,
       _expanded = null;

  /// [ButtonVariant.soft]: the tonal button.
  const Button.soft(
    this.label, {
    super.key,
    this.onPressed,
    this.size = ControlSize.medium,
    this.danger = false,
    this.icon,
    this.trailingIcon,
    this.iconColor,
    this.loading = false,
    this.expand = false,
    this.style,
    this.tooltip,
    this.disabledHint,
    this.semanticLabel,
    this.statesController,
    this.focusNode,
    this.autofocus = false,
  }) : variant = ButtonVariant.soft,
       flush = false,
       _iconOnly = false,
       _join = null,
       _expanded = null;

  /// An icon-only button: [icon] centred in a square of the control height,
  /// named by [semanticLabel] and tooltipped by [tooltip], or by
  /// [semanticLabel] when that is null. While [loading] the spinner takes the
  /// glyph's place, so the square never changes size.
  const Button.icon(
    IconData this.icon, {
    super.key,
    required String this.semanticLabel,
    this.onPressed,
    this.variant = ButtonVariant.secondary,
    this.size = ControlSize.medium,
    this.danger = false,
    this.iconColor,
    this.loading = false,
    this.style,
    this.tooltip,
    this.disabledHint,
    this.statesController,
    this.focusNode,
    this.autofocus = false,
  }) : label = semanticLabel,
       trailingIcon = null,
       expand = false,
       flush = false,
       _iconOnly = true,
       _join = null,
       _expanded = null;

  /// One side of a [SplitButton]: icon-only when it has a [semanticLabel].
  const Button._segment(
    this.label, {
    required _Join this._join,
    required this.onPressed,
    required this.variant,
    required this.size,
    required this.danger,
    required this.style,
    this.icon,
    this.loading = false,
    this.disabledHint,
    this.focusNode,
    this.semanticLabel,
    this._expanded,
  }) : trailingIcon = null,
       iconColor = null,
       expand = false,
       flush = false,
       tooltip = null,
       _iconOnly = semanticLabel != null,
       statesController = null,
       autofocus = false;

  @override
  State<Button> createState() => _ButtonState();
}

class _ButtonState extends State<Button> {
  WidgetStatesController? _own;

  WidgetStatesController get _states =>
      widget.statesController ?? (_own ??= WidgetStatesController());

  /// Tinted by its tone but not tappable while loading; greyed out when there's
  /// no callback at all.
  bool get _interactable => widget.onPressed != null && !widget.loading;

  @override
  void initState() {
    super.initState();
    _syncDisabled();
  }

  @override
  void didUpdateWidget(Button oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.statesController != oldWidget.statesController) {
      // Carry the live hover / press / focus over, so swapping controllers
      // mid-interaction doesn't drop a state the pointer or keyboard still
      // holds; an internal controller an external one replaces is released.
      final carried =
          (oldWidget.statesController ?? _own)?.value ?? const <WidgetState>{};
      if (widget.statesController != null) {
        _own?.dispose();
        _own = null;
      }
      for (final state in carried) {
        if (state != WidgetState.disabled) _states.update(state, true);
      }
    }
    _syncDisabled();
  }

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  /// Synced here, ahead of the InkWell, so the InkWell never has to change the
  /// controller (and so rebuild this button) in the middle of a build.
  void _syncDisabled() {
    _states.update(WidgetState.disabled, !_interactable);
    if (!_interactable) _states.update(WidgetState.pressed, false);
  }

  @override
  Widget build(BuildContext context) {
    final style = _merged(context.buttonStyle, widget.style);
    final s = _SizeSpec.of(widget.size, context, style);
    final enabled = widget.onPressed != null;
    final faded = !enabled && style.disabled == ButtonDisabledStyle.faded;
    // Loading keeps the variant's tone (a primary button keeps its fill); only
    // a missing callback drops to the disabled look, which a faded style
    // draws as the enabled one at its opacity.
    final palette = _Palette.resolve(
      context,
      widget.variant,
      danger: widget.danger,
      enabled: enabled || faded,
      style: style,
      // A split button's caret takes its action's colours.
      iconOnly: widget._iconOnly && widget._join == null,
    );
    final join = widget._join;
    final radius = _Join.radius(join, s.radius);
    final leadingIcon =
        widget.icon != null &&
        !widget._iconOnly &&
        style.iconPlacement == ButtonIconPlacement.leading;
    final start = s.insets.startFor(leadingIcon: leadingIcon);
    // Taller by as much as the label grows at a large text size; a split
    // button's caret grows with its action.
    final height = s.height + textGrowthOf(context, s.text);
    // A segment leaves its outline to the group, which draws one around both.
    final outlined = join == null;

    // Named by the label's own text (or the semantic label that replaces it),
    // so it is read once; an icon-only button by its semantic label.
    Widget button = Semantics(
      button: true,
      enabled: _interactable,
      label: widget._iconOnly ? widget.semanticLabel : null,
      expanded: widget._expanded,
      child: ValueListenableBuilder<Set<WidgetState>>(
        valueListenable: _states,
        builder: (context, states, _) {
          final fg = palette.fgFor(states);
          final box = widget._iconOnly
              ? _iconBox(s, fg, height)
              : _labelled(
                  s,
                  style,
                  fg: fg,
                  start: start,
                  height: height,
                  underline: palette.underlineFor(states),
                );
          // The fill carries every state, so the InkWell paints no ink of its
          // own.
          final ink = InkWell(
            onTap: _interactable ? widget.onPressed : null,
            statesController: _states,
            focusNode: widget.focusNode,
            autofocus: widget.autofocus,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            splashFactory: NoSplash.splashFactory,
            // Material's own default is platform-adaptive: the hand on the
            // web, the arrow off it. The kit shows the hand on every platform,
            // so a development build on the desktop looks like the shipped web
            // app (see Tappable).
            mouseCursor: widget.loading
                ? SystemMouseCursors.progress
                : WidgetStateMouseCursor.clickable,
            // The InkWell leaves its label selectable under a SelectionArea;
            // a tap target is no place for that (see CursorRegion).
            child: SelectionContainer.disabled(child: box),
          );
          final border = outlined ? palette.borderFor(states) : null;
          final surface = Material(
            color: palette.fillFor(states),
            shape: RoundedRectangleBorder(
              borderRadius: radius,
              side: border == null
                  ? BorderSide.none
                  : BorderSide(color: border),
            ),
            clipBehavior: Clip.antiAlias,
            child: ink,
          );
          final focused = states.contains(WidgetState.focused);
          final ringed = FocusRing(
            focused: focused,
            borderRadius: radius,
            child: surface,
          );
          return faded
              ? Opacity(opacity: style.fadedOpacity, child: ringed)
              : ringed;
        },
      ),
    );
    final tooltip = widget.onPressed == null && widget.disabledHint != null
        ? widget.disabledHint
        : widget.tooltip ?? (widget._iconOnly ? widget.semanticLabel : null);
    if (tooltip != null) {
      button = Tip(
        message: tooltip,
        // Read once when it repeats the accessible name.
        excludeFromSemantics: tooltip == (widget.semanticLabel ?? widget.label),
        child: button,
      );
    }
    if (widget.flush) {
      final rtl = Directionality.of(context) == TextDirection.rtl;
      button = Transform.translate(
        offset: Offset(rtl ? start : -start, 0),
        child: button,
      );
    }
    return button;
  }

  /// The glyph's colour: [iconColor] while enabled, else the label's.
  Color _iconFg(Color fg) =>
      widget.onPressed == null ? fg : widget.iconColor ?? fg;

  Widget _glyph(_SizeSpec s, Color fg) => widget.loading
      ? Spinner(size: s.icon, color: fg)
      : Icon(widget.icon, size: s.icon, color: _iconFg(fg));

  Widget _iconBox(_SizeSpec s, Color fg, double height) => SizedBox(
    width: s.height,
    height: widget._join == null ? s.height : height,
    child: Center(child: _glyph(s, fg)),
  );

  /// Whether the button draws no box whose edge a glyph could take: a
  /// ghost or a link.
  bool get _textual =>
      widget.variant == ButtonVariant.ghost ||
      widget.variant == ButtonVariant.link;

  /// The label with its glyphs, padded [start] before and the style's end
  /// inset after. Where the style places the glyph at the end, it (or, with
  /// no [Button.icon], the trailing glyph) stands as far in from the end
  /// edge as the label does from the start, and the label keeps out of the
  /// end inset beside it. A ghost or link button has no edge for it: the
  /// glyph follows the label, and the end is padded as the start is.
  Widget _labelled(
    _SizeSpec s,
    AdminButtonStyle style, {
    required Color fg,
    required double start,
    required double height,
    required bool underline,
  }) {
    final icon = widget.icon == null ? null : _glyph(s, fg);
    final trailing = widget.trailingIcon == null
        ? null
        : Icon(widget.trailingIcon, size: s.icon, color: fg);
    final endPlaced = style.iconPlacement == ButtonIconPlacement.end;
    final ending = endPlaced && !_textual ? icon ?? trailing : null;
    // A ghost or link in an end-placing theme sets its glyph after the label.
    final after = endPlaced && _textual ? icon : null;
    final alignStart =
        widget.flush || style.labelAlignment == ButtonLabelAlignment.start;
    final mainAxisSize = widget.expand ? MainAxisSize.max : MainAxisSize.min;
    Widget content = Row(
      mainAxisSize: mainAxisSize,
      mainAxisAlignment: alignStart
          ? MainAxisAlignment.start
          : MainAxisAlignment.center,
      children: [
        if (icon != null && ending == null && after == null) ...[
          icon,
          Gap(s.gap),
        ],
        Flexible(
          child: Text(
            widget.label,
            semanticsLabel: widget.semanticLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: s.text.copyWith(
              color: fg,
              decoration: underline ? TextDecoration.underline : null,
              decorationColor: fg,
            ),
          ),
        ),
        if (after != null) ...[Gap(s.gap), after],
        if (trailing != null && !identical(trailing, ending)) ...[
          Gap(s.gap),
          trailing,
        ],
      ],
    );
    var end = endPlaced && _textual ? start : s.insets.end;
    if (ending != null) {
      content = Row(
        mainAxisSize: mainAxisSize,
        // Past a minimum width, the glyph still takes the end edge.
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (widget.expand)
            Expanded(
              child: Align(
                alignment: alignStart
                    ? AlignmentDirectional.centerStart
                    : Alignment.center,
                child: content,
              ),
            )
          else
            Flexible(child: content),
          Gap(math.max(s.gap, end - start - s.icon)),
          ending,
        ],
      );
      end = start;
    }
    content = Padding(
      padding: EdgeInsetsDirectional.only(start: start, end: end),
      child: content,
    );
    if (widget.loading && widget.icon == null) {
      // Hidden but still laid out and read, so the width holds and the
      // label is still announced; the spinner centred on the whole button,
      // however unequal its padding.
      content = Stack(
        alignment: Alignment.center,
        children: [
          Opacity(opacity: 0, alwaysIncludeSemantics: true, child: content),
          Spinner(size: s.icon, color: fg),
        ],
      );
    }
    Widget box = SizedBox(height: height, child: content);
    if (s.minWidth > 0 && widget.variant != ButtonVariant.link) {
      box = ConstrainedBox(
        constraints: BoxConstraints(minWidth: s.minWidth),
        child: box,
      );
    }
    return box;
  }
}

/// [own] over [theme]: [own]'s members, with its unset padding, minimum
/// width and label weight taken from [theme].
AdminButtonStyle _merged(AdminButtonStyle theme, AdminButtonStyle? own) {
  if (own == null || own == theme) return theme;
  return AdminButtonStyle(
    labelAlignment: own.labelAlignment,
    iconPlacement: own.iconPlacement,
    padding: own.padding ?? theme.padding,
    minWidth: own.minWidth ?? theme.minWidth,
    labelWeight: own.labelWeight ?? theme.labelWeight,
    disabled: own.disabled,
    fadedOpacity: own.fadedOpacity,
    filledSecondary: own.filledSecondary,
    strongOutline: own.strongOutline,
    accentGhost: own.accentGhost,
    accentHover: own.accentHover,
  );
}

class _SizeSpec {
  final double height;
  final AdminButtonInsets insets;
  final double minWidth;
  final double icon;
  final double gap;
  final double radius;
  final TextStyle text;

  /// The height is the theme's control height at [size] and the corner
  /// `radii.button(size)`; the padding, minimum width and label weight are
  /// [style]'s at that size (by default `height / 2 - 4` either side: 10 at
  /// 28, 14 at 36, 16 at 40). A small button takes the small label and glyph
  /// (`type.buttonSmall`, `iconSizes.sm`).
  static _SizeSpec of(
    ControlSize size,
    BuildContext context,
    AdminButtonStyle style,
  ) {
    final type = context.type;
    final icons = context.iconSizes;
    final height = context.sizes.height(size);
    final text = switch (size) {
      ControlSize.small => type.buttonSmall,
      ControlSize.medium || ControlSize.large => type.button,
    };
    final weight = style.labelWeight;
    return _SizeSpec._(
      height: height,
      insets: style.paddingOf(size, height),
      minWidth: style.minWidthOf(size),
      icon: size == ControlSize.small ? icons.sm : icons.md,
      gap: size == ControlSize.small ? AdminSpacing.sm : AdminSpacing.md,
      radius: context.radii.button(size),
      text: weight == null ? text : type.weighted(text, weight),
    );
  }

  const _SizeSpec._({
    required this.height,
    required this.insets,
    required this.minWidth,
    required this.icon,
    required this.gap,
    required this.radius,
    required this.text,
  });
}

/// The least contrast a neutral disabled button's label keeps on its fill:
/// short of text's 4.5:1, which a disabled control is exempt from, but well
/// clear of the 1.3:1 a grey label on a grey fill can fall to.
const _disabledLabelContrast = 2.5;

class _Palette {
  final Color fill;

  /// The fill while hovered / pressed: a shade of [fill] for the filled
  /// variants, [fill] under a wash for the others.
  final Color hoverFill;
  final Color pressedFill;
  final Color fg;
  final Color hoverFg;
  final Color pressedFg;
  final Color? border;
  final Color? hoverBorder;
  final Color? pressedBorder;

  /// Underlines the label under the pointer and while pressed: a link.
  final bool underline;

  _Palette({
    required this.fill,
    required this.fg,
    Color? hoverFill,
    Color? pressedFill,
    Color? hoverFg,
    Color? pressedFg,
    this.border,
    Color? hoverBorder,
    Color? pressedBorder,
    this.underline = false,
  }) : hoverFill = hoverFill ?? fill,
       pressedFill = pressedFill ?? fill,
       hoverFg = hoverFg ?? fg,
       pressedFg = pressedFg ?? fg,
       hoverBorder = hoverBorder ?? border,
       pressedBorder = pressedBorder ?? border;

  T _for<T>(Set<WidgetState> states, T rest, T hovered, T pressed) {
    if (states.contains(WidgetState.disabled)) return rest;
    if (states.contains(WidgetState.pressed)) return pressed;
    if (states.contains(WidgetState.hovered)) return hovered;
    return rest;
  }

  Color fillFor(Set<WidgetState> states) =>
      _for(states, fill, hoverFill, pressedFill);

  Color fgFor(Set<WidgetState> states) => _for(states, fg, hoverFg, pressedFg);

  Color? borderFor(Set<WidgetState> states) =>
      _for(states, border, hoverBorder, pressedBorder);

  bool underlineFor(Set<WidgetState> states) =>
      underline && _for(states, false, true, true);

  /// The colours of [variant] in each state. An [iconOnly] ghost keeps the
  /// neutral glyph where `AdminButtonStyle.accentGhost` sets a labelled
  /// ghost in the accent, as Carbon's icon button is `$icon-primary`.
  static _Palette resolve(
    BuildContext context,
    ButtonVariant variant, {
    required bool danger,
    required bool enabled,
    required AdminButtonStyle style,
    bool iconOnly = false,
  }) {
    final colors = context.colors;
    final destructive = danger;
    final kind = variant;
    if (!enabled) return _disabled(kind, colors, style, destructive);

    final layer = colors.stateLayer;
    // [fill] under [wash] as it lands on the page, a card or the background.
    List<Color> landed(Color fill, Color wash) => [
      for (final page in [colors.surface, colors.background])
        Color.alphaBlend(wash, Color.alphaBlend(fill, page)),
    ];
    // A [fill] that hovers and presses by laying [hover] / [pressed] over it,
    // its [text] kept at 4.5:1 on each of the three.
    _Palette washed({
      required Color fill,
      required Color text,
      required Color hover,
      required Color pressed,
      Color? border,
    }) => _Palette(
      fill: fill,
      hoverFill: Color.alphaBlend(hover, fill),
      pressedFill: Color.alphaBlend(pressed, fill),
      fg: colors.readableOn(text, surfaces: landed(fill, Colors.transparent)),
      hoverFg: colors.readableOn(text, surfaces: landed(fill, hover)),
      pressedFg: colors.readableOn(text, surfaces: landed(fill, pressed)),
      border: border,
    );
    // The hover and pressed washes of a destructive outline or ghost: the
    // danger at the state layer's tint opacities, as a destructive menu row.
    final dangerWash = colors.danger.withValues(alpha: layer.tintHover);
    final dangerPressedWash = colors.danger.withValues(
      alpha: layer.tintPressed,
    );

    switch (kind) {
      case ButtonVariant.primary:
        return destructive
            ? _Palette(
                fill: colors.danger,
                hoverFill: colors.dangerHover,
                pressedFill: colors.dangerActive,
                fg: colors.onDanger,
              )
            : _Palette(
                fill: colors.primary,
                hoverFill: colors.primaryHover,
                pressedFill: colors.primaryActive,
                fg: colors.onPrimary,
              );

      case ButtonVariant.secondary when style.filledSecondary && !destructive:
        return _Palette(
          fill: colors.neutralFill,
          hoverFill: colors.neutralFillHover,
          pressedFill: colors.neutralFillActive,
          fg: colors.onNeutralFill,
        );

      case ButtonVariant.secondary when style.accentHover:
        // The outline and label turn to the accent's hover and pressed
        // colours on a fill that stays put, as Ant's default button does.
        final (hover, pressed) = destructive
            ? (colors.dangerHover, colors.dangerActive)
            : (colors.primaryHover, colors.primaryActive);
        return _Palette(
          fill: colors.surface,
          fg: destructive ? colors.dangerText : colors.foreground,
          border: destructive
              ? colors.danger
              : style.strongOutline
              ? colors.controlBorder
              : colors.border,
          hoverFg: colors.readableOn(hover),
          pressedFg: colors.readableOn(pressed),
          hoverBorder: hover,
          pressedBorder: pressed,
        );

      case ButtonVariant.secondary:
        return destructive
            ? washed(
                fill: colors.surface,
                text: colors.dangerText,
                hover: dangerWash,
                pressed: dangerPressedWash,
                border: colors.danger,
              )
            : washed(
                fill: colors.surface,
                text: colors.foreground,
                hover: colors.hoverOverlay,
                pressed: colors.pressedOverlay,
                border: style.strongOutline
                    ? colors.controlBorder
                    : colors.border,
              );

      case ButtonVariant.ghost:
        return washed(
          fill: Colors.transparent,
          text: destructive
              ? colors.dangerText
              : style.accentGhost && !iconOnly
              ? colors.primaryText
              : colors.foregroundSecondary,
          hover: destructive ? dangerWash : colors.hoverOverlay,
          pressed: destructive ? dangerPressedWash : colors.pressedOverlay,
        );

      case ButtonVariant.link:
        return _Palette(
          fill: Colors.transparent,
          fg: destructive ? colors.dangerText : colors.primaryText,
          underline: true,
        );

      case ButtonVariant.soft:
        return washed(
          fill: destructive
              ? severityStyleOf(context, Severity.danger).surface
              : colors.softFill,
          text: destructive ? colors.dangerText : colors.onSoft,
          hover: colors.hoverOverlay,
          pressed: colors.pressedOverlay,
        );
    }
  }

  /// The neutral disabled look, one grey for every filled variant whatever
  /// its tone: the state layer's pressed wash of the foreground over the
  /// surface (an outline keeps the quiet border, a ghost or link no fill),
  /// and the label the foreground at the disabled-content opacity, darkened
  /// or lightened as far as it takes to keep [_disabledLabelContrast]. A
  /// [ButtonDisabledStyle.faded] theme never gets here: its disabled button
  /// is the enabled one at the faded opacity.
  static _Palette _disabled(
    ButtonVariant kind,
    AdminPalette colors,
    AdminButtonStyle style,
    bool destructive,
  ) {
    final layer = colors.stateLayer;
    Color label(List<Color> on) => colors.readableOn(
      Color.alphaBlend(
        colors.foreground.withValues(alpha: layer.disabledContent),
        on.first,
      ),
      surfaces: on,
      minContrast: _disabledLabelContrast,
    );
    final filled = switch (kind) {
      ButtonVariant.primary || ButtonVariant.soft => true,
      ButtonVariant.secondary => style.filledSecondary && !destructive,
      ButtonVariant.ghost || ButtonVariant.link => false,
    };
    if (filled) {
      final wash = Color.alphaBlend(colors.pressedOverlay, colors.surface);
      return _Palette(fill: wash, fg: label([wash]));
    }
    return switch (kind) {
      // The quiet border whatever the enabled one: a disabled button never
      // reads as more defined than a live one.
      ButtonVariant.secondary => _Palette(
        fill: colors.surface,
        fg: label([colors.surface]),
        border: colors.border,
      ),
      _ => _Palette(
        fill: Colors.transparent,
        fg: label([colors.surface, colors.background]),
      ),
    };
  }
}

/// Which side of a [SplitButton] a [Button] segment is.
enum _Join {
  start,
  end;

  /// A standalone button's corners are all [radius]; a segment's inner ones
  /// are square.
  static BorderRadiusDirectional radius(_Join? join, double radius) {
    final r = Radius.circular(radius);
    return switch (join) {
      null => BorderRadiusDirectional.all(r),
      _Join.start => BorderRadiusDirectional.horizontal(start: r),
      _Join.end => BorderRadiusDirectional.horizontal(end: r),
    };
  }
}

/// A primary action with a menu of alternatives beside it — "Publish" with
/// "Schedule…" and "Publish to…" under a caret.
///
/// Two segments of one [Button]: [label] runs [onPressed], and a caret — a
/// square of the control height, named [menuSemanticLabel] ("More publish
/// options") — opens a [Menu] of [entries]. They share the outer corners of
/// one button (`AdminRadii.button`, so a stadium where the theme's buttons
/// are full-round), with square inner corners and a 1px divider in the
/// variant's foreground at 25% between them; an outlined variant draws one
/// outline around both. Each segment is its own Tab stop with its own focus
/// ring, and the caret opens its menu on Enter, Space or ↓ like any menu
/// button. [danger] and [style] apply to both segments, as on a [Button].
///
/// A null [onPressed] disables the action but not the menu, and shows
/// [disabledHint] as its tooltip when set. While [loading] the action shows
/// its spinner at its resting width. The caret takes the disabled look, and
/// no input, while the action loads or when no entry is enabled, so a split
/// button with nothing to offer reads as one disabled control. Given less
/// than its width, the action's label ellipsises.
class SplitButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final List<MenuEntry> entries;

  /// The caret's accessible name and tooltip.
  final String menuSemanticLabel;

  final ButtonVariant variant;
  final ControlSize size;

  /// Both segments in the danger colours of [variant]; see [Button.danger].
  final bool danger;

  /// Leading glyph of the action; the spinner takes its place while
  /// [loading].
  final IconData? icon;

  final bool loading;

  /// Why the action is disabled, as its tooltip while [onPressed] is null.
  final String? disabledHint;

  /// Both segments' anatomy in place of the theme's; see [Button.style].
  final AdminButtonStyle? style;

  /// The action segment's focus node.
  final FocusNode? focusNode;

  const SplitButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.entries,
    required this.menuSemanticLabel,
    this.variant = ButtonVariant.primary,
    this.size = ControlSize.medium,
    this.danger = false,
    this.icon,
    this.loading = false,
    this.disabledHint,
    this.style,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final style = _merged(context.buttonStyle, this.style);
    final s = _SizeSpec.of(size, context, style);
    final menuLive = !loading && entries.any(_enabled);
    // Between two live segments, the divider is drawn in their tone; beside
    // a disabled one, in the disabled tone, which a faded style draws as the
    // live one at its opacity.
    final live = onPressed != null && menuLive;
    final faded = !live && style.disabled == ButtonDisabledStyle.faded;
    final palette = _Palette.resolve(
      context,
      variant,
      danger: danger,
      enabled: live || faded,
      style: style,
    );
    Color fade(Color c) =>
        faded ? c.withValues(alpha: c.a * style.fadedOpacity) : c;

    final action = Button._segment(
      label,
      join: _Join.start,
      onPressed: onPressed,
      variant: variant,
      size: size,
      danger: danger,
      style: this.style,
      icon: icon,
      loading: loading,
      disabledHint: disabledHint,
      focusNode: focusNode,
    );
    final caret = Menu(
      entries: entries,
      align: PopoverAlign.end,
      builder: (context, c) => Button._segment(
        menuSemanticLabel,
        join: _Join.end,
        onPressed: menuLive ? c.toggle : null,
        variant: variant,
        size: size,
        danger: danger,
        style: this.style,
        icon: Icons.keyboard_arrow_down_rounded,
        semanticLabel: menuSemanticLabel,
        expanded: c.isOpen,
      ),
    );
    final divider = Color.alphaBlend(
      // token-literal: the split's divider, the label colour at a quarter
      palette.fg.withValues(alpha: 0.25),
      palette.fill,
    );
    final border = palette.border;
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(s.radius),
        border: border == null ? null : Border.all(color: fade(border)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: action),
          SizedBox(
            width: 1,
            height: s.height + textGrowthOf(context, s.text),
            child: ColoredBox(color: fade(divider)),
          ),
          caret,
        ],
      ),
    );
  }

  static bool _enabled(MenuEntry entry) => switch (entry) {
    MenuItem(:final onSelect, :final uri) => onSelect != null || uri != null,
    MenuCheckboxItem(:final onChanged) => onChanged != null,
    MenuSubmenu(:final enabled, :final entries) =>
      enabled && entries.isNotEmpty,
    MenuDivider() || MenuHeader() => false,
  };
}
