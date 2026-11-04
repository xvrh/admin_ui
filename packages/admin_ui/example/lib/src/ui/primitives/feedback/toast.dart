import 'dart:math' as math;

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../../demo_kit.dart';

/// Wraps the demo in a [ToastScope] so the buttons can raise toasts into the
/// stack, at the position the Stacking section picks. The pinned stacks
/// below show toasts without a click.
class ToastDemo extends StatefulWidget {
  @Preview(name: 'Toast', wrapper: adminUiPreview)
  const ToastDemo({super.key});

  @override
  State<ToastDemo> createState() => _ToastDemoState();
}

class _ToastDemoState extends State<ToastDemo> {
  var _position = ToastPosition.topEnd;

  @override
  Widget build(BuildContext context) {
    return ToastScope(
      position: _position,
      child: _Body(
        position: _position,
        onPosition: (position) => setState(() => _position = position),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final ToastPosition position;
  final ValueChanged<ToastPosition> onPosition;

  const _Body({required this.position, required this.onPosition});

  @override
  Widget build(BuildContext context) {
    final toasts = ToastScope.of(context);
    void show(Toast toast) => toasts.show(toast);

    Future<void> publish({required bool fails}) async {
      try {
        await toasts.promise(
          Future<int>.delayed(const Duration(seconds: 2), () {
            if (fails) throw StateError('the server is unreachable');
            return 3;
          }),
          loading: const Toast.loading('Publishing “Pricing”…'),
          success: (count) => Toast(
            '“Pricing” and $count translations are live.',
            title: 'Page published',
            severity: Severity.success,
          ),
          error: (_) => Toast(
            'The server could not be reached.',
            title: 'Couldn’t publish “Pricing”',
            severity: Severity.danger,
            actionLabel: 'Retry',
            onAction: () {},
          ),
        );
      } on StateError {
        // Shown as the error toast.
      }
    }

    return DemoPage(
      maxWidth: 760,
      children: [
        const DemoSection('Severities'),
        Wrap(
          spacing: AdminSpacing.md,
          runSpacing: AdminSpacing.md,
          children: [
            Button('Info', onPressed: () => show(const Toast('Draft saved.'))),
            Button.primary(
              'Success',
              onPressed: () => show(
                const Toast('Page published.', severity: Severity.success),
              ),
            ),
            Button(
              'Warning',
              onPressed: () => show(
                const Toast(
                  'Connection is unstable.',
                  severity: Severity.warning,
                ),
              ),
            ),
            Button.danger(
              'Error',
              onPressed: () => show(
                const Toast('Upload failed.', severity: Severity.danger),
              ),
            ),
          ],
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('With action; loading, then the outcome'),
        Wrap(
          spacing: AdminSpacing.md,
          runSpacing: AdminSpacing.md,
          children: [
            Button(
              'Delete with undo',
              icon: Icons.delete_outline_rounded,
              onPressed: () => toasts.undoable(
                const Toast('Item deleted.'),
                commit: () async {},
                onUndo: () => show(
                  const Toast('Item restored.', severity: Severity.success),
                ),
              ),
            ),
            Button('Publish', onPressed: () => publish(fails: false)),
            Button('Publish, failing', onPressed: () => publish(fails: true)),
          ],
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('Long text'),
        Button(
          'Raise a long one',
          onPressed: () => show(
            const Toast(
              'Couldn’t publish “Pricing” — 3 of its translations are missing '
              'required fields, and the German variant references an asset that '
              'was deleted. Fix these and try again.',
              severity: Severity.danger,
            ),
          ),
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('Stacking'),
        Wrap(
          spacing: AdminSpacing.md,
          runSpacing: AdminSpacing.md,
          children: [
            Segmented<bool>(
              semanticLabel: 'Edge',
              size: ControlSize.small,
              value: _top(position),
              segments: const [
                SegmentOption(true, 'Top'),
                SegmentOption(false, 'Bottom'),
              ],
              onChanged: (top) => onPosition(_at(top, _side(position))),
            ),
            Segmented<_Side>(
              semanticLabel: 'Side',
              size: ControlSize.small,
              value: _side(position),
              segments: const [
                SegmentOption(_Side.start, 'Start'),
                SegmentOption(_Side.center, 'Center'),
                SegmentOption(_Side.end, 'End'),
              ],
              onChanged: (side) => onPosition(_at(_top(position), side)),
            ),
          ],
        ),
        const Gap(AdminSpacing.md),
        Wrap(
          spacing: AdminSpacing.md,
          runSpacing: AdminSpacing.md,
          children: [
            Button.primary(
              'Raise five',
              onPressed: () {
                show(const Toast('First.'));
                show(const Toast('Second.', severity: Severity.success));
                show(const Toast('Third.', severity: Severity.warning));
                show(const Toast('Fourth.'));
                show(const Toast('Fifth.', severity: Severity.success));
              },
            ),
            Button.ghost('Dismiss all', onPressed: toasts.dismissAll),
          ],
        ),
        const Gap(AdminSpacing.md),
        Text(
          'Three at a time, the newest nearest the edge; the rest wait. They '
          'leave after 4s (10s with an action or an error), pause while '
          'hovered, focused or held, and swipe off toward the side edge.',
          style: context.type.caption,
        ),
        const Gap(AdminSpacing.xl),

        Wrap(
          alignment: WrapAlignment.spaceBetween,
          runSpacing: AdminSpacing.xl,
          children: [
            _Pinned(
              'Pinned — a 320px-wide screen',
              PinnedToastStack(
                width: 320,
                toasts: [
                  const Toast('Draft saved.', duration: null),
                  Toast(
                    'Item deleted.',
                    actionLabel: 'Undo',
                    onAction: () {},
                    duration: null,
                  ),
                  const Toast(
                    'Upload failed: the file is larger than 20 MB.',
                    severity: Severity.danger,
                    duration: null,
                  ),
                ],
              ),
            ),
            _Pinned(
              'Success, warning, a long message',
              PinnedToastStack(
                width: 320,
                toasts: [
                  const Toast(
                    'Page published.',
                    severity: Severity.success,
                    duration: null,
                  ),
                  Toast(
                    'Connection is unstable.',
                    severity: Severity.warning,
                    actionLabel: 'Retry',
                    onAction: () {},
                    duration: null,
                  ),
                  const Toast(
                    'Couldn’t publish “Pricing”: 3 of its translations are '
                    'missing required fields, and the German variant '
                    'references a deleted asset.',
                    severity: Severity.danger,
                    duration: null,
                  ),
                ],
              ),
            ),
            _Pinned(
              'Titles; loading, and one updated',
              PinnedToastStack(
                width: 320,
                toasts: [
                  Toast(
                    '3 fields are missing.',
                    title: 'Publish failed',
                    severity: Severity.danger,
                    actionLabel: 'Retry',
                    onAction: () {},
                    duration: null,
                  ),
                  const Toast.loading('Publishing “Pricing”…'),
                  const Toast.loading('Publishing “Pricing”…'),
                ],
                // The middle one's work is done: the same card, now the
                // outcome.
                onShown: (handles) => handles[1].update(
                  const Toast(
                    '“Pricing” is live on the site.',
                    title: 'Page published',
                    severity: Severity.success,
                    duration: null,
                  ),
                ),
              ),
            ),
            const _Pinned(
              'Bottom start: the newest at the bottom',
              PinnedToastStack(
                width: 320,
                position: ToastPosition.bottomStart,
                toasts: [
                  Toast('Draft saved.', duration: null),
                  Toast(
                    'Page published.',
                    severity: Severity.success,
                    duration: null,
                  ),
                ],
              ),
            ),
          ],
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('Pinned — bottom center, on a wider screen'),
        const PinnedToastStack(
          width: double.infinity,
          position: ToastPosition.bottomCenter,
          toasts: [
            Toast('Draft saved.', duration: null),
            Toast(
              'Page published.',
              severity: Severity.success,
              duration: null,
            ),
          ],
        ),
      ],
    );
  }
}

/// A pinned stack under its section label, as wide as the stack.
class _Pinned extends StatelessWidget {
  final String title;
  final PinnedToastStack stack;

  const _Pinned(this.title, this.stack);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: stack.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [DemoSection(title), stack],
      ),
    );
  }
}

enum _Side { start, center, end }

bool _top(ToastPosition position) => switch (position) {
  ToastPosition.topStart ||
  ToastPosition.topCenter ||
  ToastPosition.topEnd => true,
  ToastPosition.bottomStart ||
  ToastPosition.bottomCenter ||
  ToastPosition.bottomEnd => false,
};

_Side _side(ToastPosition position) => switch (position) {
  ToastPosition.topStart || ToastPosition.bottomStart => _Side.start,
  ToastPosition.topCenter || ToastPosition.bottomCenter => _Side.center,
  ToastPosition.topEnd || ToastPosition.bottomEnd => _Side.end,
};

ToastPosition _at(bool top, _Side side) => switch ((top, side)) {
  (true, _Side.start) => ToastPosition.topStart,
  (true, _Side.center) => ToastPosition.topCenter,
  (true, _Side.end) => ToastPosition.topEnd,
  (false, _Side.start) => ToastPosition.bottomStart,
  (false, _Side.center) => ToastPosition.bottomCenter,
  (false, _Side.end) => ToastPosition.bottomEnd,
};

/// A [ToastScope] in a box of [width] (at most the page's) by [height],
/// stacking at [position] and raising [toasts] in order once mounted, so the
/// preview shows the stack as it lands on a narrow screen. [onShown] gets
/// their handles right after, to update or dismiss some before the first
/// frame shows them.
class PinnedToastStack extends StatefulWidget {
  final double width;

  /// The box's height; null fits it to the toasts once they have landed,
  /// in whatever the theme and the text size make of them.
  final double? height;
  final ToastPosition position;
  final List<Toast> toasts;
  final ValueChanged<List<ToastHandle>>? onShown;

  const PinnedToastStack({
    super.key,
    required this.width,
    this.height,
    this.position = ToastPosition.topEnd,
    required this.toasts,
    this.onShown,
  });

  @override
  State<PinnedToastStack> createState() => _PinnedToastStackState();
}

class _PinnedToastStackState extends State<PinnedToastStack> {
  final _scope = GlobalKey<ToastScopeState>();
  final _box = GlobalKey();

  /// The height the toasts take, once measured.
  double? _fit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final scope = _scope.currentState!;
      final handles = [for (final toast in widget.toasts) scope.show(toast)];
      widget.onShown?.call(handles);
      if (widget.height == null) _measure();
    });
  }

  /// Fits the box to its toasts after each frame, as they land.
  void _measure([Duration? _]) {
    if (!mounted) return;
    final fit = _toastsHeight();
    if (fit != null && fit != _fit) setState(() => _fit = fit);
    WidgetsBinding.instance.addPostFrameCallback(_measure);
  }

  /// From the box's anchored edge to the far edge of the farthest card, and
  /// the stack's gap and gutter past it; null before a card has laid out.
  /// The cards sit in the scope's overlay, which the element tree still
  /// holds below the box.
  double? _toastsHeight() {
    final box = _box.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    final top = _top(widget.position);
    double? reach;
    void visit(Element element) {
      if (element.widget is Material) {
        final card = element.renderObject;
        if (card is RenderBox && card.attached && card.hasSize) {
          final rect = MatrixUtils.transformRect(
            card.getTransformTo(box),
            Offset.zero & card.size,
          );
          final edge = top ? rect.bottom : box.size.height - rect.top;
          reach = math.max(reach ?? 0, edge);
        }
        return;
      }
      element.visitChildren(visit);
    }

    _box.currentContext!.visitChildElements(visit);
    return switch (reach) {
      final reach? =>
        (reach + AdminSpacing.md + AdminSpacing.xl).ceilToDouble(),
      null => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final corners = BorderRadius.circular(context.radii.radiusLarge);
    return Center(
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: corners,
          border: Border.all(color: colors.border),
        ),
        child: ClipRRect(
          borderRadius: corners,
          child: SizedBox(
            key: _box,
            width: widget.width,
            // Room to land in until measured.
            height: widget.height ?? _fit ?? 400,
            child: ToastScope(
              key: _scope,
              position: widget.position,
              child: ColoredBox(color: colors.background),
            ),
          ),
        ),
      ),
    );
  }
}
