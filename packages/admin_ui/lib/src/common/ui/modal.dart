import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../../l10n/admin_ui_localizations.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'alert.dart';
import 'button.dart';
import 'icon_action.dart';
import 'severity.dart';

/// Opens [builder] as a modal route — the scrim, focus trap, Escape-to-dismiss
/// and return value come from [showDialog]; the surface is a [Modal]. Returns
/// whatever the content pops. The scrim is the palette's `scrim` unless
/// [barrierColor] overrides it. It fades in over the theme's `motion.medium`
/// on `motion.enter` and out on `motion.exit`, and appears at once under
/// reduced motion.
///
/// The card is centred 24px inside the safe area and clear of the keyboard,
/// except a [ModalSize.fullscreen] one, which takes the whole screen and
/// keeps its content inside the safe area.
Future<T?> showModal<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
}) {
  final motion = context.motion;
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor ?? context.colors.scrim,
    animationStyle: AnimationStyle(
      duration: motion.medium,
      reverseDuration: motion.medium,
      curve: motion.enter,
      reverseCurve: motion.exit,
    ),
    // The frame keeps to the safe area itself, so a fullscreen modal can
    // reach the screen's edges.
    useSafeArea: false,
    builder: (context) => _ModalFrame(child: builder(context)),
  );
}

/// What [showModal] puts around its content: the keyboard's inset, the safe
/// area and a 24px margin, with the card centred in what is left. A
/// fullscreen [Modal] below drops the safe area and the margin through the
/// [_ModalFrameScope] it finds, and keeps its content inside the safe area
/// the scope hands it. Below the frame the safe area is taken out of the
/// [MediaQuery], as a dialog route's own `SafeArea` does.
class _ModalFrame extends StatefulWidget {
  final Widget child;

  const _ModalFrame({required this.child});

  @override
  State<_ModalFrame> createState() => _ModalFrameState();
}

class _ModalFrameState extends State<_ModalFrame> {
  final _fullscreen = ValueNotifier(false);

  @override
  void dispose() {
    _fullscreen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safeArea = MediaQuery.paddingOf(context);
    return _ModalFrameScope(
      fullscreen: _fullscreen,
      safeArea: safeArea,
      child: _ModalMargin(
        fullscreen: _fullscreen,
        insets: MediaQuery.viewInsetsOf(context),
        safeArea: safeArea,
        child: MediaQuery.removePadding(
          context: context,
          removeLeft: true,
          removeTop: true,
          removeRight: true,
          removeBottom: true,
          // The dialog can float over a web platform view (an embedded
          // iframe, say). Without an interceptor the view swallows pointer
          // events meant for the card; [PointerInterceptor] drops a DOM shim
          // above it so the card stays clickable. Wraps only the card (not
          // the full-screen padding) so a tap on the surrounding scrim still
          // reaches the barrier to dismiss.
          child: Center(child: PointerInterceptor(child: widget.child)),
        ),
      ),
    );
  }
}

/// Tells the [Modal] inside a [showModal] route where to say whether it is
/// fullscreen. The modal writes it as it builds, before the frame lays out,
/// so the margin never shows for a frame first. Each modal puts one without
/// a [fullscreen] over its own content, so a modal opened from inside it (a
/// `ModalAnchor` in its body) leaves the outer frame alone.
class _ModalFrameScope extends InheritedWidget {
  final ValueNotifier<bool>? fullscreen;

  /// The screen's safe area, which the frame takes out of the [MediaQuery].
  final EdgeInsets? safeArea;

  const _ModalFrameScope({
    this.fullscreen,
    this.safeArea,
    required super.child,
  });

  @override
  bool updateShouldNotify(_ModalFrameScope old) =>
      old.fullscreen != fullscreen || old.safeArea != safeArea;
}

class _ModalMargin extends SingleChildRenderObjectWidget {
  final ValueListenable<bool> fullscreen;
  final EdgeInsets insets;
  final EdgeInsets safeArea;

  const _ModalMargin({
    required this.fullscreen,
    required this.insets,
    required this.safeArea,
    required super.child,
  });

  @override
  _RenderModalMargin createRenderObject(BuildContext context) =>
      _RenderModalMargin(
        fullscreen: fullscreen,
        insets: insets,
        safeArea: safeArea,
      );

  @override
  void updateRenderObject(BuildContext context, _RenderModalMargin render) {
    render
      ..fullscreen = fullscreen
      ..insets = insets
      ..safeArea = safeArea;
  }
}

/// [insets] plus the [safeArea] and the 24px margin, both of which it drops
/// while [fullscreen] is true.
class _RenderModalMargin extends RenderPadding {
  _RenderModalMargin({
    required ValueListenable<bool> fullscreen,
    required EdgeInsets insets,
    required EdgeInsets safeArea,
  }) : _fullscreen = fullscreen,
       _insets = insets,
       _safeArea = safeArea,
       super(
         padding: _paddingFor(insets, safeArea, fullscreen: fullscreen.value),
       );

  static EdgeInsets _paddingFor(
    EdgeInsets insets,
    EdgeInsets safeArea, {
    required bool fullscreen,
  }) => fullscreen
      ? insets
      : insets + safeArea + const EdgeInsets.all(AdminSpacing.xxl);

  ValueListenable<bool> _fullscreen;
  set fullscreen(ValueListenable<bool> value) {
    if (value == _fullscreen) return;
    if (attached) _fullscreen.removeListener(_update);
    _fullscreen = value;
    if (attached) _fullscreen.addListener(_update);
    _update();
  }

  EdgeInsets _insets;
  set insets(EdgeInsets value) {
    if (value == _insets) return;
    _insets = value;
    _update();
  }

  EdgeInsets _safeArea;
  set safeArea(EdgeInsets value) {
    if (value == _safeArea) return;
    _safeArea = value;
    _update();
  }

  void _update() =>
      padding = _paddingFor(_insets, _safeArea, fullscreen: _fullscreen.value);

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _fullscreen.addListener(_update);
    _update();
  }

  @override
  void detach() {
    _fullscreen.removeListener(_update);
    super.detach();
  }
}

/// A confirm dialog. Resolves true if the user confirms, false if they cancel or
/// dismiss. [danger] makes the confirm button red for destructive actions, and
/// keeps a stray click on the scrim from answering; Escape still cancels.
/// [confirmLabel] and [cancelLabel] default to the localized "Confirm" and
/// "Cancel".
///
/// Cancel, the least destructive answer, takes the initial focus.
///
/// Pass [onConfirm] to run the action *inside* the dialog: the confirm button
/// shows a spinner and the dialog stays put while it runs (neither Escape nor
/// the scrim close it), dismissing on success and surfacing a thrown error
/// inline (so the user can retry) instead of closing on a failure. The inline
/// message is [errorText] applied to the error — a generic "try again" when
/// null, since a raw exception is rarely fit for the user. Without
/// [onConfirm] the dialog just resolves the boolean and the caller does the
/// work afterwards.
///
/// [confirmKey] and [cancelKey] are the keys of the two buttons, to find
/// them by in a test.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  String? cancelLabel,
  Key? confirmKey,
  Key? cancelKey,
  bool danger = false,
  Future<void> Function()? onConfirm,
  String Function(Object error)? errorText,
}) async {
  final result = await showModal<bool>(
    context,
    barrierDismissible: !danger,
    builder: (ctx) {
      final l10n = ctx.adminL10n;
      return _ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel ?? l10n.inputs.confirm,
        cancelLabel:
            cancelLabel ?? MaterialLocalizations.of(ctx).cancelButtonLabel,
        confirmKey: confirmKey,
        cancelKey: cancelKey,
        danger: danger,
        onConfirm: onConfirm,
        errorText: errorText ?? (_) => l10n.somethingWentWrongTryAgain,
      );
    },
  );
  return result ?? false;
}

class _ConfirmDialog extends StatefulWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final Key? confirmKey;
  final Key? cancelKey;
  final bool danger;
  final Future<void> Function()? onConfirm;
  final String Function(Object error) errorText;

  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.confirmKey,
    required this.cancelKey,
    required this.danger,
    required this.onConfirm,
    required this.errorText,
  });

  @override
  State<_ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<_ConfirmDialog> {
  bool _busy = false;
  String? _error;

  /// Cancel's focus node: the safe choice takes focus when the dialog opens.
  final _cancel = FocusNode(debugLabel: 'Cancel');

  @override
  void initState() {
    super.initState();
    _focusCancel();
  }

  @override
  void dispose() {
    _cancel.dispose();
    super.dispose();
  }

  /// Focuses Cancel once it is laid out (and enabled again after a run).
  void _focusCancel() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _cancel.requestFocus();
    });
  }

  Future<void> _onConfirm() async {
    final run = widget.onConfirm;
    if (run == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await run();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = widget.errorText(e);
        });
        _focusCancel();
      }
    }
  }

  void _dismiss() {
    if (!_busy) Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final confirmButton = widget.danger
        ? Button.danger(
            widget.confirmLabel,
            key: widget.confirmKey,
            loading: _busy,
            onPressed: _onConfirm,
          )
        : Button.primary(
            widget.confirmLabel,
            key: widget.confirmKey,
            loading: _busy,
            onPressed: _onConfirm,
          );
    // The route only honours Escape while its barrier dismisses, so the
    // dialog answers it itself — a destructive confirm still cancels on
    // Escape. The PopScope holds the scrim and back while the action runs.
    return PopScope(
      canPop: !_busy,
      child: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) => _dismiss(),
          ),
        },
        child: Modal(
          title: widget.title,
          alert: true,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.message,
                style: context.type.body.copyWith(
                  color: context.colors.foregroundSecondary,
                ),
              ),
              if (_error != null) ...[
                const Gap(AdminSpacing.lg),
                Alert(_error!, severity: Severity.danger),
              ],
            ],
          ),
          actions: [
            Button.ghost(
              widget.cancelLabel,
              key: widget.cancelKey,
              onPressed: _busy ? null : _dismiss,
              focusNode: _cancel,
            ),
            confirmButton,
          ],
        ),
      ),
    );
  }
}

/// How wide a [Modal] is. Each width is a cap: under [showModal] a modal on
/// a narrow screen stops 24px short of its edges whatever its size.
enum ModalSize {
  /// 400px: a confirmation, or a field or two.
  small(400),

  /// 512px, the default: a short form or a message with its actions.
  medium(512),

  /// 720px: a longer form, or a preview beside its settings.
  large(720),

  /// The whole screen, edge to edge, with square corners and no border or
  /// shadow; the header, the footer and the scrolling content between them
  /// keep inside the safe area. It fills what its host gives it, which
  /// [showModal] and a `ModalAnchor` make the screen.
  fullscreen(null);

  const ModalSize(this.width);

  /// The card's width, or null for [fullscreen].
  final double? width;
}

/// The dialog surface — an elevated, rounded, hairline-bordered card with an
/// optional [title] and [description], a close affordance while [onDismiss]
/// is set, a [body] (or convenience [message]) and an end-aligned [actions]
/// footer. Render it via [showModal]; it's a plain widget so the catalog can
/// show it inline too.
///
/// It is [size] wide, or [maxWidth] when set. The card is never taller than
/// the screen less a 24px margin: the header and the footer stay pinned while
/// the content between them scrolls, with a hairline at whichever edge has
/// content beyond it. On a narrow screen the actions stack full width, the
/// last (primary) one on top.
///
/// Assistive technology announces it as a dialog named by [title] and
/// described by [description].
class Modal extends StatefulWidget {
  final String? title;

  /// A sentence under the title, in muted body text, saying what the dialog
  /// is for. It is read out with the dialog's name.
  final String? description;

  /// Arbitrary content. Ignored when null in favour of [message].
  final Widget? body;

  /// Convenience text body, used when [body] is null.
  final String? message;

  /// The footer actions, primary last.
  final List<Widget> actions;

  /// The width preset. [maxWidth], when set, wins over it.
  final ModalSize size;

  /// A width of the caller's own, instead of [size]'s.
  final double? maxWidth;

  /// Closes the dialog from a close (×) button in the header, which shows
  /// exactly when this is set. Usually
  /// `() => Navigator.of(context).maybePop()`: a `PopScope` or a form's
  /// leave guard around the content can then hold the dialog open.
  final VoidCallback? onDismiss;

  /// The key of the close button [onDismiss] shows, to find it by in a test.
  final Key? closeKey;

  /// Announces the surface as an alert dialog — a confirmation that
  /// interrupts the user — rather than a plain dialog.
  final bool alert;

  const Modal({
    super.key,
    this.title,
    this.description,
    this.body,
    this.message,
    this.actions = const [],
    this.size = ModalSize.medium,
    this.maxWidth,
    this.onDismiss,
    this.closeKey,
    this.alert = false,
  }) : assert(
         maxWidth == null || size != ModalSize.fullscreen,
         'A fullscreen modal takes no maxWidth',
       );

  @override
  State<Modal> createState() => _ModalState();
}

/// Line height of the title, as a multiple of its font size: fixed so the
/// close button can centre on the first line in every theme's font.
const _titleLineHeight = 1.5;

/// Room inside the scrolling region for a focus ring drawn around its first
/// or last control, which the region's clip would otherwise cut.
const _ringRoom = AdminSpacing.xs;

class _ModalState extends State<Modal> {
  final _scroll = ScrollController();
  final _metrics = _Ping();

  @override
  void dispose() {
    _scroll.dispose();
    _metrics.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fullscreen = widget.size == ModalSize.fullscreen;
    final frame = context
        .dependOnInheritedWidgetOfExactType<_ModalFrameScope>();
    frame?.fullscreen?.value = fullscreen;
    final colors = context.colors;
    final title = widget.title;
    final description = widget.description;
    final content =
        widget.body ??
        (widget.message == null
            ? null
            : Text(
                widget.message!,
                style: context.type.body.copyWith(
                  color: colors.foregroundSecondary,
                ),
              ));
    final hasActions = widget.actions.isNotEmpty;
    final dismiss = widget.onDismiss;

    // The close button is taller than the title's line: it hangs [overhang]
    // above and below it, which the header takes back from its padding so
    // the title's line keeps its 24px and its 12px to the content. Under a
    // description the header ends with the description instead ([below]).
    const close = IconActionSize.small;
    final titleStyle = context.type.heading.copyWith(
      height: _titleLineHeight,
      leadingDistribution: TextLeadingDistribution.even,
    );
    final line =
        MediaQuery.textScalerOf(context).scale(titleStyle.fontSize!) *
        _titleLineHeight;
    final overhang = dismiss != null
        ? math.max(0.0, (close.box - line) / 2)
        : 0.0;
    final below = description == null ? overhang : 0.0;

    Widget? header;
    if (title != null || description != null || dismiss != null) {
      header = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: overhang, bottom: below),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Semantics(
                      header: true,
                      child: Text(title, style: titleStyle),
                    ),
                  if (title != null && description != null)
                    const Gap(AdminSpacing.md),
                  if (description != null)
                    // The dialog's hint reads it, after the title.
                    ExcludeSemantics(
                      child: Text(description, style: context.type.bodyMuted),
                    ),
                ],
              ),
            ),
          ),
          if (dismiss != null) ...[
            const Gap(AdminSpacing.md),
            Padding(
              padding: EdgeInsets.only(
                top: math.max(0, (line - close.box) / 2),
              ),
              child: IconAction.close(
                key: widget.closeKey,
                size: close,
                onPressed: dismiss,
              ),
            ),
          ],
        ],
      );
    }

    // Each gap is measured between what the eye sees: the header's last
    // line, the content (inside its focus-ring room) and the footer's
    // buttons.
    final surface = Column(
      mainAxisSize: fullscreen ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null)
          Padding(
            padding: EdgeInsetsDirectional.only(
              start: AdminSpacing.xxl,
              top: AdminSpacing.xxl - overhang,
              // The close glyph, not its hit box, lines up with the content.
              end: dismiss != null
                  ? AdminSpacing.xxl - (close.box - close.glyph) / 2
                  : AdminSpacing.xxl,
              bottom: content == null && !hasActions
                  ? AdminSpacing.xxl - below
                  : 0,
            ),
            child: header,
          ),
        if (content != null)
          Flexible(
            // Fullscreen, the content takes the height between the header and
            // the footer, which stays at the bottom.
            fit: fullscreen ? FlexFit.tight : FlexFit.loose,
            child: Padding(
              padding: EdgeInsets.only(
                top: math.max(
                  0,
                  (header == null
                          ? AdminSpacing.xxl
                          : AdminSpacing.lg - below) -
                      _ringRoom,
                ),
                bottom: hasActions ? 0 : AdminSpacing.xxl - _ringRoom,
              ),
              child: _ScrollingBody(
                controller: _scroll,
                metrics: _metrics,
                separator: colors.separator,
                child: content,
              ),
            ),
          )
        else if (fullscreen)
          const Spacer(),
        if (hasActions)
          Padding(
            padding: EdgeInsets.fromLTRB(
              AdminSpacing.xxl,
              content != null
                  ? AdminSpacing.xxl - _ringRoom
                  : AdminSpacing.xxl - below,
              AdminSpacing.xxl,
              AdminSpacing.xxl,
            ),
            child: _ActionBar(
              spacing: AdminSpacing.md,
              textDirection: Directionality.of(context),
              children: widget.actions,
            ),
          ),
      ],
    );

    final Widget card;
    if (fullscreen) {
      final safeArea = frame?.safeArea;
      card = SizedBox.expand(
        child: Material(
          color: colors.surface,
          child: safeArea == null
              ? SafeArea(child: surface)
              : Padding(padding: safeArea, child: surface),
        ),
      );
    } else {
      final corners = BorderRadius.circular(context.radii.radiusDialog);
      final maxHeight = math.max(
        0.0,
        MediaQuery.sizeOf(context).height -
            MediaQuery.viewInsetsOf(context).bottom -
            2 * AdminSpacing.xxl,
      );
      // Shadow on the outer box; the border rides on the Material's shape so
      // it paints over flush content and survives the clip.
      card = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: corners,
          boxShadow: context.elevation.lg,
        ),
        child: Material(
          color: colors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: corners,
            side: BorderSide(color: colors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: widget.maxWidth ?? widget.size.width!,
              maxHeight: maxHeight,
            ),
            child: surface,
          ),
        ),
      );
    }

    return Semantics(
      scopesRoute: true,
      namesRoute: title != null,
      explicitChildNodes: true,
      label: title,
      hint: description,
      role: widget.alert ? SemanticsRole.alertDialog : SemanticsRole.dialog,
      child: _ModalFrameScope(child: card),
    );
  }
}

class _Ping extends ChangeNotifier {
  void ping() => notifyListeners();
}

/// The modal's content region: scrolls when it outgrows the card and draws a
/// full-bleed separator along an edge while content lies beyond it.
class _ScrollingBody extends StatelessWidget {
  final ScrollController controller;

  /// Pinged when the content or viewport size changes without a scroll, so
  /// the hairlines repaint.
  final _Ping metrics;

  final Color separator;
  final Widget child;

  const _ScrollingBody({
    required this.controller,
    required this.metrics,
    required this.separator,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (notification) {
        if (notification.depth == 0) metrics.ping();
        return false;
      },
      child: CustomPaint(
        foregroundPainter: _EdgeHairlines(
          controller: controller,
          color: separator,
          repaint: Listenable.merge([controller, metrics]),
        ),
        child: SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.symmetric(
            horizontal: AdminSpacing.xxl,
            vertical: _ringRoom,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _EdgeHairlines extends CustomPainter {
  final ScrollController controller;
  final Color color;

  _EdgeHairlines({
    required this.controller,
    required this.color,
    required Listenable repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    if (!controller.hasClients) return;
    final position = controller.position;
    if (!position.hasContentDimensions || !position.hasPixels) return;
    final paint = Paint()..color = color;
    if (position.pixels > position.minScrollExtent) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 1), paint);
    }
    if (position.pixels < position.maxScrollExtent) {
      canvas.drawRect(Rect.fromLTWH(0, size.height - 1, size.width, 1), paint);
    }
  }

  @override
  bool shouldRepaint(_EdgeHairlines old) =>
      old.color != color || old.controller != controller;
}

/// The footer's actions: a row at the end while they fit on one line;
/// otherwise a stack, each stretched to the full width and the last (the
/// primary) on top, so the stack reads as one block.
class _ActionBar extends MultiChildRenderObjectWidget {
  final double spacing;
  final TextDirection textDirection;

  const _ActionBar({
    required this.spacing,
    required this.textDirection,
    required super.children,
  });

  @override
  _RenderActionBar createRenderObject(BuildContext context) =>
      _RenderActionBar(spacing: spacing, textDirection: textDirection);

  @override
  void updateRenderObject(BuildContext context, _RenderActionBar renderObject) {
    renderObject
      ..spacing = spacing
      ..textDirection = textDirection;
  }
}

class _ActionBarParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderActionBar extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ActionBarParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ActionBarParentData> {
  _RenderActionBar({required this._spacing, required this._textDirection});

  double _spacing;
  set spacing(double value) {
    if (value == _spacing) return;
    _spacing = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ActionBarParentData) {
      child.parentData = _ActionBarParentData();
    }
  }

  List<RenderBox> get _children => getChildrenAsList();

  double _rowWidth(double Function(RenderBox child) width) {
    final children = _children;
    if (children.isEmpty) return 0;
    return children.map(width).reduce((a, b) => a + b) +
        _spacing * (children.length - 1);
  }

  @override
  double computeMinIntrinsicWidth(double height) => _children.fold(
    0,
    (widest, child) => math.max(widest, child.getMinIntrinsicWidth(height)),
  );

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _rowWidth((child) => child.getMaxIntrinsicWidth(height));

  @override
  double computeMinIntrinsicHeight(double width) => _plan(
    BoxConstraints(maxWidth: width),
    ChildLayoutHelper.dryLayoutChild,
  ).size.height;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      _plan(constraints, ChildLayoutHelper.dryLayoutChild).size;

  @override
  void performLayout() {
    final plan = _plan(constraints, ChildLayoutHelper.layoutChild);
    size = plan.size;
    for (final (child, offset) in plan.offsets) {
      (child.parentData! as BoxParentData).offset = offset;
    }
  }

  ({Size size, List<(RenderBox, Offset)> offsets}) _plan(
    BoxConstraints constraints,
    ChildLayouter layoutChild,
  ) {
    final children = _children;
    final width = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : computeMaxIntrinsicWidth(double.infinity);
    final loose = BoxConstraints(maxWidth: width);
    final sizes = [for (final child in children) layoutChild(child, loose)];
    final rowWidth = sizes.isEmpty
        ? 0.0
        : sizes.map((s) => s.width).reduce((a, b) => a + b) +
              _spacing * (sizes.length - 1);
    final offsets = <(RenderBox, Offset)>[];

    if (rowWidth <= width) {
      final height = sizes.fold(0.0, (h, s) => math.max(h, s.height));
      final rtl = _textDirection == TextDirection.rtl;
      var x = rtl ? rowWidth : width - rowWidth;
      for (var i = 0; i < children.length; i++) {
        final size = sizes[i];
        offsets.add((
          children[i],
          Offset(rtl ? x - size.width : x, (height - size.height) / 2),
        ));
        x += rtl ? -(size.width + _spacing) : size.width + _spacing;
      }
      return (
        size: constraints.constrain(Size(width, height)),
        offsets: offsets,
      );
    }

    final tight = BoxConstraints.tightFor(width: width);
    var y = 0.0;
    for (final child in children.reversed) {
      final size = layoutChild(child, tight);
      offsets.add((child, Offset(0, y)));
      y += size.height + _spacing;
    }
    return (
      size: constraints.constrain(Size(width, math.max(0, y - _spacing))),
      offsets: offsets,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
