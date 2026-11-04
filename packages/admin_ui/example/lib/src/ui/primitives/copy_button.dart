import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

/// The copy affordance: icon-only and labelled, beside the kind of values it's
/// usually paired with (IDs, slugs, keys, URLs).
class CopyButtonDemo extends StatelessWidget {
  @Preview(name: 'Copy button', wrapper: adminUiPreview)
  const CopyButtonDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 460,
      children: [
        const DemoSection('Icon only'),
        DemoVariant(
          'beside a monospaced value',
          Panel(
            padding: const EdgeInsets.symmetric(
              horizontal: AdminSpacing.lg,
              vertical: AdminSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text('usr_8f2a1c9e0b', style: context.type.mono),
                ),
                const CopyButton('usr_8f2a1c9e0b'),
              ],
            ),
          ),
        ),
        const DemoSection('Labelled'),
        DemoVariant(
          'label flips to “Copied” on tap',
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: CopyButton(
              'https://admin.example.com/api/admin',
              label: 'Copy URL',
              flush: true,
            ),
          ),
        ),
        const DemoSection('Custom labels'),
        DemoVariant(
          'tooltip + confirmation text',
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: CopyButton(
              'sk_live_51H...',
              label: 'Copy secret',
              tooltip: 'Copy API secret',
              copiedLabel: 'Copied!',
              flush: true,
            ),
          ),
        ),
        const DemoSection('Reveal on hover (inline, no card)'),
        DemoVariant(
          'button fades in beside a plain line of text',
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: _InlineHoverCopy(
              copyText: 'abcd',
              child: Text('Here is your key: abcd'),
            ),
          ),
        ),
        DemoVariant(
          'inside a sentence — watch the trailing text for reserved space',
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Here is your key: '),
                _InlineHoverCopy(copyText: 'abcd', child: Text('abcd')),
                Flexible(
                  child: Text(
                    ' — keep it secret.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        const DemoSection('Reveal on hover (stacked, takes no room)'),
        DemoVariant(
          'button overlays the trailing edge — text never shifts',
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: _OverlayHoverCopy(
              copyText: 'abcd',
              child: Text('Here is your key: abcd'),
            ),
          ),
        ),
        const DemoSection('Reveal on hover (overlay card)'),
        DemoVariant(
          'the button fades in over the content on hover',
          _HoverCopy(
            copyText:
                'curl -X POST https://admin.example.com/api/admin/publish',
            child: Text(
              'curl -X POST https://admin.example.com/api/admin/publish',
              style: context.type.monoSmall,
            ),
          ),
        ),
      ],
    );
  }
}

/// The copy button's states a static preview cannot reach by itself: the
/// hover fill on a panel, the confirmation, and the failure when the
/// clipboard refuses the copy.
class CopyButtonStatesDemo extends StatelessWidget {
  @Preview(name: 'Copy button — copied and error', wrapper: adminUiPreview)
  const CopyButtonStatesDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      maxWidth: 460,
      children: [
        const DemoSection('Hovered, on a panel'),
        DemoVariant(
          'the ghost hover overlay shows on the panel fill',
          Panel(
            padding: const EdgeInsets.symmetric(
              horizontal: AdminSpacing.lg,
              vertical: AdminSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text('usr_8f2a1c9e0b', style: context.type.mono),
                ),
                const _Pinned(
                  hovered: true,
                  child: CopyButton('usr_8f2a1c9e0b', label: 'Copy ID'),
                ),
              ],
            ),
          ),
        ),
        const DemoSection('Copied'),
        DemoVariant(
          'a check and the confirmation, at the resting width',
          Row(
            children: [
              _Pinned(
                tapped: true,
                child: CopyButton(
                  'abcd',
                  label: 'Copy URL',
                  revertAfter: _held,
                  write: (_) async {},
                ),
              ),
              const Gap(AdminSpacing.lg),
              _Pinned(
                tapped: true,
                child: CopyButton(
                  'abcd',
                  revertAfter: _held,
                  write: (_) async {},
                ),
              ),
            ],
          ),
        ),
        const DemoSection('The clipboard refused the copy'),
        DemoVariant(
          'a danger glyph and the failure, announced; onCopied is not called',
          Row(
            children: [
              _Pinned(
                tapped: true,
                child: CopyButton(
                  'abcd',
                  label: 'Copy URL',
                  revertAfter: _held,
                  write: _refuse,
                ),
              ),
              const Gap(AdminSpacing.lg),
              _Pinned(
                tapped: true,
                child: CopyButton('abcd', revertAfter: _held, write: _refuse),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Long enough that a pinned outcome never reverts while the preview shows.
const _held = Duration(days: 1);

/// A clipboard that refuses, as a browser does outside a secure context.
Future<void> _refuse(String _) =>
    Future.error(PlatformException(code: 'NotAllowedError'));

/// Pins [child]'s [CopyButton] hovered, or taps it once mounted, so a static
/// preview shows the state.
class _Pinned extends StatefulWidget {
  final bool hovered;
  final bool tapped;
  final Widget child;

  const _Pinned({
    this.hovered = false,
    this.tapped = false,
    required this.child,
  });

  @override
  State<_Pinned> createState() => _PinnedState();
}

class _PinnedState extends State<_Pinned> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      void visit(Element element) {
        switch (element.widget) {
          case InkWell(:final statesController?) when widget.hovered:
            statesController.update(WidgetState.hovered, true);
          case Button(:final onPressed?) when widget.tapped:
            onPressed();
          case IconAction(:final onPressed?) when widget.tapped:
            onPressed();
        }
        element.visitChildren(visit);
      }

      context.visitChildElements(visit);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// A line of text with a [CopyButton] stacked over its trailing edge, fading in
/// on hover. The button is [Positioned], so it takes no layout room of its own —
/// the text never shifts and nothing reserves space.
class _OverlayHoverCopy extends StatefulWidget {
  final Widget child;
  final String copyText;

  const _OverlayHoverCopy({required this.child, required this.copyText});

  @override
  State<_OverlayHoverCopy> createState() => _OverlayHoverCopyState();
}

class _OverlayHoverCopyState extends State<_OverlayHoverCopy> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Stack(
        children: [
          widget.child,
          PositionedDirectional(
            end: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: AnimatedOpacity(
                opacity: _hover ? 1 : 0,
                duration: const Duration(milliseconds: 150),
                child: IgnorePointer(
                  ignoring: !_hover,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(
                        context.radii.radiusSmall,
                      ),
                      border: Border.all(color: context.colors.border),
                    ),
                    child: CopyButton(widget.copyText),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A plain line of text with a [CopyButton] that fades in beside it on hover —
/// no card. The button's space is always reserved so the text doesn't shift.
class _InlineHoverCopy extends StatefulWidget {
  final Widget child;
  final String copyText;

  const _InlineHoverCopy({required this.child, required this.copyText});

  @override
  State<_InlineHoverCopy> createState() => _InlineHoverCopyState();
}

class _InlineHoverCopyState extends State<_InlineHoverCopy> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          widget.child,
          const Gap(AdminSpacing.xs),
          AnimatedOpacity(
            opacity: _hover ? 1 : 0,
            duration: const Duration(milliseconds: 120),
            child: IgnorePointer(
              ignoring: !_hover,
              child: CopyButton(widget.copyText),
            ),
          ),
        ],
      ),
    );
  }
}

/// Wraps [child] in a panel that reveals a corner [CopyButton] on hover — the
/// pattern for code blocks and read-only values.
class _HoverCopy extends StatefulWidget {
  final Widget child;
  final String copyText;

  const _HoverCopy({required this.child, required this.copyText});

  @override
  State<_HoverCopy> createState() => _HoverCopyState();
}

class _HoverCopyState extends State<_HoverCopy> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Panel(
        padding: const EdgeInsets.all(AdminSpacing.lg),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AdminSpacing.xxl),
              child: widget.child,
            ),
            PositionedDirectional(
              top: -AdminSpacing.xs,
              end: -AdminSpacing.xs,
              child: AnimatedOpacity(
                opacity: _hover ? 1 : 0,
                duration: const Duration(milliseconds: 120),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(
                      context.radii.radiusSmall,
                    ),
                    border: Border.all(color: context.colors.border),
                  ),
                  child: CopyButton(widget.copyText),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
