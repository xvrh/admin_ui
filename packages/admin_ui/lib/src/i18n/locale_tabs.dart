import 'package:material_ui/material_ui.dart';

import '../common/ui/tabs.dart';
import '../theme/sizes.dart';
import '../theme/tokens.dart';
import 'locale_status.dart';

/// A compact tab strip that picks the one locale in view, for an editor too
/// tall to show several lanes side by side (a full-height body, a fullscreen
/// dialog). A locale whose value differs from the baseline carries an amber
/// dot, so the strip still tells which languages were edited.
///
/// Collapses to nothing for a single locale: there is nothing to switch.
class LocaleTabs extends StatelessWidget {
  /// The selectable lanes, in display order.
  final List<LocaleInfo> lanes;

  /// The code of the locale in view.
  final String activeLocale;

  /// Called with the code of the locale the user picks.
  final ValueChanged<String> onActiveLocaleChanged;

  /// Codes of the locales whose value differs from the baseline.
  final Set<String> modified;

  const LocaleTabs({
    super.key,
    required this.lanes,
    required this.activeLocale,
    required this.onActiveLocaleChanged,
    this.modified = const {},
  });

  @override
  Widget build(BuildContext context) {
    if (lanes.length <= 1) return const SizedBox.shrink();
    var index = lanes.indexWhere((l) => l.code == activeLocale);
    if (index < 0) index = 0;
    return Tabs(
      size: ControlSize.small,
      baseline: false,
      tabs: [
        for (final l in lanes)
          TabItem(
            l.code.toUpperCase(),
            trailing: modified.contains(l.code) ? const _Dot() : null,
          ),
      ],
      selected: index,
      onChanged: (i) => onActiveLocaleChanged(lanes[i].code),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: context.colors.warning,
        shape: BoxShape.circle,
      ),
    );
  }
}
