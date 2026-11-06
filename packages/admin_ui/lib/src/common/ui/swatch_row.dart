import 'package:material_ui/material_ui.dart';

import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'tappable.dart';
import 'tip.dart';

/// One choice in a [SwatchRow].
class SwatchOption<T> {
  final T value;
  final Color color;
  final String label;

  /// The key of the swatch built for this option, to find it by in a test.
  final Key? key;

  const SwatchOption(this.value, this.color, this.label, {this.key});
}

/// A row of color dots for enum props whose values *are* colors (a section's
/// background tint) — the swatch shows the value better than a label could.
class SwatchRow<T> extends StatelessWidget {
  final List<SwatchOption<T>> options;
  final T value;
  final ValueChanged<T>? onChanged;

  const SwatchRow({
    super.key,
    required this.options,
    required this.value,
    this.onChanged,
  });

  /// Each 18px dot sits in a 24px hit box; the gap is shaved by the 6px of
  /// padding so the dots keep their spacing.
  static const _box = 24.0;
  static const _dot = 18.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const Gap(AdminSpacing.sm - (_box - _dot)),
          _swatch(context, options[i]),
        ],
      ],
    );
  }

  Widget _swatch(BuildContext context, SwatchOption<T> option) {
    final colors = context.colors;
    final selected = option.value == value;
    return Tip(
      message: option.label,
      excludeFromSemantics: true,
      child: Tappable(
        key: option.key,
        onTap: onChanged == null
            ? null
            : () {
                if (!selected) onChanged!(option.value);
              },
        semanticLabel: option.label,
        excludeSemantics: true,
        selected: selected,
        focusRadius: _box / 2,
        child: SizedBox.square(
          dimension: _box,
          child: Center(
            child: Container(
              width: _dot,
              height: _dot,
              padding: const EdgeInsets.all(AdminSpacing.xxs),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? colors.primary : colors.border,
                  width: selected
                      ? context.stroke.indicator
                      : context.stroke.hairline,
                ),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: option.color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
