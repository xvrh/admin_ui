import 'package:material_ui/material_ui.dart';

import '../../common/ui/icon_action.dart';
import '../../common/ui/popover.dart';
import '../../common/ui/popover_menu.dart';
import '../../common/ui/tappable.dart';
import '../../common/ui/tip.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'field_shell.dart';

/// A self-contained help capability: a `(?)` dot that opens a popover with
/// inline help. Drops into a field's label row as a passed-in widget; it owns
/// its own overlay and needs nothing from the field. Inside a [FieldShell] it
/// is named after the field: "Help for Title".
class HelpButton extends StatelessWidget {
  final String text;

  const HelpButton({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final field = context.findAncestorWidgetOfExactType<FieldShell>()?.label;
    final messages = context.adminL10n.fields;
    final label = field == null ? messages.help : messages.helpFor(field);
    return Popover(
      // Read-only tip: keep the editor's focus/cursor.
      autofocus: false,
      anchor: (context, controller) => Tip(
        message: label,
        excludeFromSemantics: true,
        child: _Dot(
          label: label,
          on: controller.isOpen,
          onTap: controller.toggle,
        ),
      ),
      content: (context, controller) => _Card(text: text),
    );
  }
}

/// The `(?)` dot, 18px, centred in the inline 24px hit box.
class _Dot extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback onTap;

  const _Dot({required this.label, required this.on, required this.onTap});

  static const _dot = 18.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final box = IconActionSize.inline.box;
    return Tappable.states(
      onTap: onTap,
      semanticLabel: label,
      excludeSemantics: true,
      expanded: on,
      focusRadius: box / 2,
      builder: (context, states) {
        final active =
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.pressed);
        final ink = on
            ? colors.primaryText
            : (active ? colors.foregroundSecondary : colors.foregroundMuted);
        final fill = on
            ? colors.primaryFaint
            : states.contains(WidgetState.pressed)
            ? colors.pressedOverlay
            : (active ? colors.hoverOverlay : null);
        return SizedBox.square(
          dimension: box,
          child: Center(
            child: Container(
              width: _dot,
              height: _dot,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fill,
                border: Border.all(
                  color: ink,
                  width: context.stroke.controlStrong,
                ),
              ),
              alignment: Alignment.center,
              // A glyph drawn as the button's icon, which keeps its size
              // at any text scale as icons do. Its line is the glyph's own
              // size, so the ramp's taller micro line (20 in Ant) cannot
              // outgrow the ring.
              child: Text(
                '?',
                textScaler: TextScaler.noScaling,
                style: context.type.weighted(
                  context.type.micro.copyWith(color: ink, height: 1),
                  FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  final String text;

  const _Card({required this.text});

  @override
  Widget build(BuildContext context) {
    return PopoverMenuSurface(
      width: 250,
      maxHeight: double.infinity,
      child: Padding(
        padding: const EdgeInsets.all(AdminSpacing.lg),
        child: Text(
          text,
          style: context.type.bodySmall.copyWith(
            color: context.colors.foregroundSecondary,
          ),
        ),
      ),
    );
  }
}
