import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'panel.dart';
import 'tappable.dart';

/// One collapsible section of an [Accordion].
class AccordionSection {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget child;

  const AccordionSection({
    required this.title,
    this.subtitle,
    this.icon,
    required this.child,
  });
}

/// A stack of collapsible [sections] in a bordered surface — the disclosure
/// pattern for settings groups, FAQs, or a long form split into parts.
///
/// Uncontrolled by default: the open set is internal UI state, seeded by
/// [initiallyOpen] (all collapsed unless given). Pass [open] to control it
/// instead — to expand a section from a validation error or a deep link —
/// and apply the sets [onOpenChanged] reports. Only one section is open at a
/// time unless [multiple].
///
/// Keyboard: every header is a Tab stop that Enter or Space toggles; Arrow
/// Up/Down move between headers (wrapping) and Home/End jump to the first and
/// last. Headers announce as buttons with their expanded state.
///
/// With animations disabled (reduced motion) a section opens and closes at
/// once.
class Accordion extends StatefulWidget {
  final List<AccordionSection> sections;
  final bool multiple;

  /// The sections open on first build, when uncontrolled.
  final Set<int> initiallyOpen;

  /// The open sections, when controlled; null leaves them to the accordion.
  final Set<int>? open;

  /// Reports the open set a header tap asks for. Required to change a
  /// controlled accordion; notified of an uncontrolled one's changes too.
  final ValueChanged<Set<int>>? onOpenChanged;

  const Accordion({
    super.key,
    required this.sections,
    this.multiple = false,
    this.initiallyOpen = const {},
    this.open,
    this.onOpenChanged,
  });

  @override
  State<Accordion> createState() => _AccordionState();
}

class _AccordionState extends State<Accordion> {
  late final Set<int> _uncontrolled = {...widget.initiallyOpen};
  final List<FocusNode> _headers = [];

  Set<int> get _open => widget.open ?? _uncontrolled;

  @override
  void initState() {
    super.initState();
    _syncHeaders();
  }

  @override
  void didUpdateWidget(Accordion oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncHeaders();
  }

  @override
  void dispose() {
    for (final node in _headers) {
      node.dispose();
    }
    super.dispose();
  }

  void _syncHeaders() {
    while (_headers.length > widget.sections.length) {
      // The header it served unmounts in the coming build, still holding it.
      final node = _headers.removeLast();
      WidgetsBinding.instance.addPostFrameCallback((_) => node.dispose());
    }
    while (_headers.length < widget.sections.length) {
      _headers.add(
        FocusNode(debugLabel: 'Accordion header ${_headers.length}'),
      );
    }
  }

  void _toggle(int i) {
    final next = {..._open};
    if (!next.remove(i)) {
      if (!widget.multiple) next.clear();
      next.add(i);
    }
    if (widget.open == null) {
      setState(() {
        _uncontrolled
          ..clear()
          ..addAll(next);
      });
    }
    widget.onOpenChanged?.call(next);
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final current = _headers.indexWhere((n) => n.hasPrimaryFocus);
    if (current < 0) return KeyEventResult.ignored;
    final count = _headers.length;
    final int? target = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowDown => (current + 1) % count,
      LogicalKeyboardKey.arrowUp => (current - 1 + count) % count,
      LogicalKeyboardKey.home => 0,
      LogicalKeyboardKey.end => count - 1,
      _ => null,
    };
    if (target == null) return KeyEventResult.ignored;
    _headers[target].requestFocus();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final open = _open;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _onKey,
      child: Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < widget.sections.length; i++) ...[
              if (i > 0)
                Divider(
                  height: context.stroke.hairline,
                  thickness: context.stroke.hairline,
                  color: context.colors.border,
                ),
              _Section(
                section: widget.sections[i],
                open: open.contains(i),
                focusNode: _headers[i],
                onTap: () => _toggle(i),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final AccordionSection section;
  final bool open;
  final FocusNode focusNode;
  final VoidCallback onTap;

  const _Section({
    required this.section,
    required this.open,
    required this.focusNode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = section;
    final colors = context.colors;
    final motion = context.motion;
    final icons = context.iconSizes;
    final body = open
        ? Padding(
            padding: const EdgeInsets.fromLTRB(
              AdminSpacing.xl,
              0,
              AdminSpacing.xl,
              AdminSpacing.xl,
            ),
            child: DefaultTextStyle.merge(
              style: context.type.body.copyWith(
                color: colors.foregroundSecondary,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: s.child,
              ),
            ),
          )
        : const SizedBox(width: double.infinity);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Tappable.states(
          onTap: onTap,
          focusNode: focusNode,
          expanded: open,
          // The panel clips a ring drawn outside the header, so it is drawn
          // just inside it instead.
          showFocusRing: false,
          builder: (context, states) => Stack(
            children: [
              Container(
                color: states.contains(WidgetState.pressed)
                    ? colors.pressedOverlay
                    : states.contains(WidgetState.hovered)
                    ? colors.hoverOverlay
                    : null,
                padding: const EdgeInsets.symmetric(
                  horizontal: AdminSpacing.xl,
                  vertical: AdminSpacing.lg,
                ),
                child: Row(
                  children: [
                    if (s.icon != null) ...[
                      Icon(
                        s.icon,
                        size: icons.md,
                        color: colors.foregroundMuted,
                      ),
                      const Gap(AdminSpacing.lg),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.title,
                            style: context.type.bodyStrong.copyWith(
                              color: colors.foreground,
                            ),
                          ),
                          if (s.subtitle != null) ...[
                            const Gap(AdminSpacing.xxs),
                            Text(
                              s.subtitle!,
                              style: context.type.caption.copyWith(
                                color: colors.foregroundMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Gap(AdminSpacing.md),
                    AnimatedRotation(
                      turns: open ? 0.5 : 0,
                      duration: motion.fast,
                      curve: motion.standard,
                      child: Icon(
                        Icons.expand_more_rounded,
                        size: icons.lg,
                        color: colors.foregroundMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (states.contains(WidgetState.focused))
                Positioned.fill(
                  child: IgnorePointer(
                    child: Padding(
                      padding: const EdgeInsets.all(AdminSpacing.xxs),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            context.radii.radiusSmall,
                          ),
                          border: Border.all(
                            color: colors.focusRing,
                            width: context.focus.width,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // An AnimatedSize cannot run at zero: under reduced motion the body
        // just appears.
        if (motion.medium == Duration.zero)
          body
        else
          AnimatedSize(
            duration: motion.medium,
            curve: motion.standard,
            alignment: Alignment.topCenter,
            child: body,
          ),
      ],
    );
  }
}
