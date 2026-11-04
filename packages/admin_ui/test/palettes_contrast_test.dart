import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'shipped_palettes.dart';

/// The client accents the catalog's Brand control offers.
const _brands = <String, Color?>{
  'Default': null,
  'Crimson': Color(0xFFE11D48),
  'Violet': Color(0xFF7C3AED),
  'Teal': Color(0xFF0D9488),
  'Amber': Color(0xFFD97706),
};

/// Every shipped palette, in both modes and under every demo brand, against
/// the WCAG pairs the components rely on and the surface ordering they assume.
/// The sidebar and top-bar palettes a theme's shell carries meet the same
/// pairs; they draw one strip of the frame, not a page, so the ordering of
/// a page's surfaces is not theirs to keep (Carbon's header is one flat
/// #161616).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final theme in adminThemes) {
    for (final (mode, palette, read) in [
      ('Light', theme.palette, () => theme.tokens),
      ('Dark', theme.darkPalette!, () => theme.dark!),
    ]) {
      for (final MapEntry(key: brand, value: seed) in _brands.entries) {
        final p = seed == null ? palette : palette.branded(seed);
        group('${theme.name} $mode, brand $brand', () {
          test('meets its contrast pairs', () {
            final style = read().field;
            expect(_contrastFailures(p, style), isEmpty);
          });

          test('orders its surfaces', () {
            expect(_orderingFailures(p), isEmpty);
          });
        });
      }
    }
  }

  for (final MapEntry(key: name, value: palette)
      in shippedChromePalettes.entries) {
    for (final MapEntry(key: brand, value: seed) in _brands.entries) {
      final p = seed == null ? palette : palette.branded(seed);
      test('$name, brand $brand meets its contrast pairs', () {
        expect(_contrastFailures(p, const AdminFieldStyle()), isEmpty);
      });
    }
  }
}

List<String> _contrastFailures(AdminPalette p, AdminFieldStyle field) {
  final failures = <String>[];
  void atLeast(double min, String name, Color fg, Map<String, Color> on) {
    for (final MapEntry(key: surface, value: bg) in on.entries) {
      final ratio = contrastRatio(fg, bg);
      if (ratio < min) {
        failures.add('$name on $surface: ${ratio.toStringAsFixed(2)} < $min');
      }
    }
  }

  final page = {'surface': p.surface, 'background': p.background};
  atLeast(4.5, 'foreground', p.foreground, {
    ...page,
    'primarySubtle': p.primarySubtle,
    'primaryFaint': p.primaryFaint,
  });
  atLeast(4.5, 'foregroundMuted', p.foregroundMuted, page);
  atLeast(4.5, 'placeholder', p.placeholder, {'surface': p.surface});
  atLeast(4.5, 'onPrimary', p.onPrimary, {'primary': p.primary});
  atLeast(4.5, 'onDanger', p.onDanger, {'danger': p.danger});
  atLeast(4.5, 'onSuccess', p.onSuccess, {'success': p.success});
  atLeast(4.5, 'onWarning', p.onWarning, {'warning': p.warning});
  atLeast(4.5, 'onInfo', p.onInfo, {'info': p.info});
  for (final (name, text, accent) in [
    ('dangerText', p.dangerText, p.danger),
    ('successText', p.successText, p.success),
    ('warningText', p.warningText, p.warning),
    ('infoText', p.infoText, p.info),
  ]) {
    atLeast(4.5, name, text, {
      'surface': p.surface,
      'its fill': p.statusFill(accent),
    });
  }
  atLeast(4.5, 'primaryText', p.primaryText, {'surface': p.surface});
  atLeast(3, 'focusRing', p.focusRing, page);
  atLeast(3, 'controlBorder', p.controlBorder, page);
  atLeast(3, 'controlAccent', p.controlAccent, page);
  atLeast(3, 'onControlAccent', p.onControlAccent, {
    'controlAccent': p.controlAccent,
    'controlAccentHover': p.controlAccentHover,
  });
  atLeast(4.5, 'foregroundMutedOnTint', p.foregroundMutedOnTint, {
    ...page,
    'surfaceMuted': p.surfaceMuted,
    'primarySubtle': p.primarySubtle,
    'primaryFaint': p.primaryFaint,
    'listHighlight': p.listHighlight,
    'tableRowSelected': p.tableRowSelected,
    'tableRowSelectedHover': p.tableRowSelectedHover,
    'hoverOverlay on surface': Color.alphaBlend(p.hoverOverlay, p.surface),
  });
  // A filled or underlined field is found by its bottom rule (WCAG 1.4.11).
  atLeast(3, 'fieldRule', p.fieldRule, {'fieldFill': p.fieldFill, ...page});
  if (field.accentFocus) {
    atLeast(3, 'controlAccent', p.controlAccent, {'fieldFill': p.fieldFill});
  }
  atLeast(3, 'focusRing', p.focusRing, {'fieldFill': p.fieldFill});
  atLeast(4.5, 'onSoft', p.onSoft, {'softFill': p.softFill});
  atLeast(4.5, 'onNeutralFill', p.onNeutralFill, {
    'neutralFill': p.neutralFill,
    'neutralFillHover': p.neutralFillHover,
    'neutralFillActive': p.neutralFillActive,
  });
  if (p.chart.length < 8) failures.add('chart has ${p.chart.length} colours');
  for (final (i, color) in p.chart.indexed) {
    atLeast(3, 'chart[$i]', color, page);
  }
  return failures;
}

List<String> _orderingFailures(AdminPalette p) {
  final failures = <String>[];
  double lum(Color c) => relativeLuminance(c);
  double fromSurface(Color c) => contrastRatio(c, p.surface);

  if (lum(p.surface) <= lum(p.background)) {
    failures.add('surface is not lighter than the background page');
  }
  if (lum(p.surfaceMuted) >= lum(p.surface)) {
    failures.add('surfaceMuted is not below surface');
  }
  if (p.brightness == Brightness.dark &&
      lum(p.surfaceMuted) <= lum(p.background)) {
    failures.add('surfaceMuted is not above the background page');
  }
  if (p.primarySubtle == p.background) {
    failures.add('primarySubtle equals background');
  }
  if (fromSurface(p.primaryFaint) >= fromSurface(p.primarySubtle)) {
    failures.add('primaryFaint is not subtler than primarySubtle');
  }
  if (fromSurface(p.borderSubtle) >= fromSurface(p.border)) {
    failures.add('borderSubtle is not subtler than border');
  }
  if (p.info == p.primary) failures.add('info equals primary');
  return failures;
}
