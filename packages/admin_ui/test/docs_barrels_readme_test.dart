// README.md against the code it describes. Each ```dart block is a file
// under readme/ (or part of one), or under the example's test/readme/ for a
// sample on a package only the example depends on, so the analyzer compiles
// it with the tests and the tests run it; the first test fails when the
// README and the files differ. The Libraries and Layer order tables are checked against
// api.txt, the barrels and layers_test.dart, so they follow a move.

import 'dart:io';

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'layers_test.dart' show allowed, layers;
import 'readme/branding.dart' as branding;
import 'readme/custom_theme.dart';
import 'readme/minimal_app.dart' show MyAdmin;
import 'readme/name_clash.dart' show price;
import 'readme/value_form.dart';

/// README blocks that are not compiled, with why: this one imports a package
/// the kit does not depend on.
const _uncompiled = {
  "import 'package:admin_ui/admin_ui.dart' hide Gap;\n"
      "import 'package:gap/gap.dart';\n",
};

/// The body of the README.md section headed [heading], up to the next
/// heading of the same or a higher level.
String _section(String heading) {
  final level = heading.indexOf(' ');
  final lines = File('README.md').readAsLinesSync();
  final start = lines.indexOf(heading);
  expect(start, isNot(-1), reason: 'README.md has no "$heading"');
  final end = lines.indexWhere(
    (l) => RegExp('^#{1,$level} ').hasMatch(l),
    start + 1,
  );
  return lines.sublist(start + 1, end == -1 ? null : end).join('\n');
}

/// The cells of each body row of the first table in [section].
List<List<String>> _rows(String section) => [
  for (final line
      in section
          .split('\n')
          .skipWhile((l) => !l.startsWith('|'))
          .takeWhile((l) => l.startsWith('|'))
          .skip(2)) // the header and its rule
    [for (final c in line.substring(1, line.length - 1).split('|')) c.trim()],
];

/// The code spans of [text] that name a Dart identifier, `()` dropped.
Iterable<String> _identifiers(String text) =>
    RegExp(r'`([A-Za-z_]\w*)(?:\(\))?`').allMatches(text).map((m) => m[1]!);

/// Symbols a Libraries row names although another barrel exports them, with
/// why.
const _namedElsewhere = {
  // The bodies are views over the cells of forms.dart.
  'fields.dart': {'Cell'},
};

/// api.txt as barrel -> the symbols (or, for an umbrella, the barrels) it
/// exports.
Map<String, Set<String>> _api() {
  final api = <String, Set<String>>{};
  for (final line in File('api.txt').readAsLinesSync()) {
    if (line.isEmpty || line.startsWith('#')) continue;
    final words = line.split(' ');
    final barrel = api.putIfAbsent(words.first, () => {});
    barrel.add(
      words.length == 3 ? words.last.replaceAll('.dart', '') : words[1],
    );
  }
  return api;
}

void main() {
  test('every dart block in README.md is one of the samples', () {
    final readme = File('README.md').readAsStringSync();
    final fence = RegExp(r'```dart\n(.*?)```', dotAll: true);
    final blocks = [for (final m in fence.allMatches(readme)) m[1]!];
    // The example holds the samples on flutterware, which the kit does not
    // depend on.
    final samples = [
      for (final dir in ['test/readme', 'example/test/readme'])
        for (final f in Directory(dir).listSync())
          if (f is File && f.path.endsWith('.dart')) f.readAsStringSync(),
    ];
    expect(blocks, isNotEmpty);
    for (final block in blocks) {
      if (_uncompiled.contains(block)) continue;
      expect(
        samples.any((s) => s.contains(block)),
        isTrue,
        reason: 'README.md block not found under test/readme/:\n$block',
      );
    }
  });

  Future<BuildContext> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MyAdmin());
    await tester.pumpAndSettle();
    return tester.element(find.text('Welcome'));
  }

  testWidgets('the minimal app themes the kit and shows a toast', (
    tester,
  ) async {
    final context = await pumpApp(tester);
    expect(context.colors, irisPalette);
    expect(context.adminTokens, same(irisTheme.tokens));

    await tester.tap(find.text('Say hello'));
    await tester.pump();
    expect(find.text('Hello'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('the minimal app follows dark mode and the locale', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    final context = await pumpApp(tester);
    expect(context.colors, irisDarkPalette);
    expect(AdminLocalizations.of(context), isA<AdminLocalizationsFr>());
  });

  testWidgets("AdminScope mounts the scopes and keeps the app's ToastScope", (
    tester,
  ) async {
    final context = await pumpApp(tester);
    expect(CommandScope.maybeOf(context), isNotNull);
    expect(ModalAnchor.of(context), isNotNull);
    expect(find.byType(ToastScope), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byType(Navigator),
        matching: find.byType(ToastScope),
      ),
      findsOneWidget,
    );
  });

  testWidgets('hiding AdminTokensContext leaves adminTokens to read', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(irisTheme.tokens),
        home: const Builder(builder: price),
      ),
    );
    final style = tester.widget<Text>(find.text('42 €')).style!;
    expect(style.color, const Color(0xFF0D9488));
    expect(style.fontSize, irisTheme.tokens.typography.body.fontSize);
  });

  testWidgets('the contact form refuses an invalid email, then saves', (
    tester,
  ) async {
    final saved = <Contact>[];
    final form = contactForm((c) async => saved.add(c));
    addTearDown(form.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(irisTheme.tokens),
        localizationsDelegates: AdminLocalizations.localizationsDelegates,
        supportedLocales: AdminLocalizations.supportedLocales,
        home: Scaffold(body: ContactEditor(form: form)),
      ),
    );
    final name = find.byType(EditableText).first;
    final email = find.byType(EditableText).last;
    await tester.enterText(name, 'Ada');
    await tester.enterText(email, 'ada@');
    await tester.pump();
    expect(find.text('Enter a valid email address'), findsOneWidget);

    await form.submit();
    expect(saved, isEmpty);

    await tester.enterText(email, 'ada@example.com');
    await form.submit();
    await tester.pump();
    expect(saved, [(name: 'Ada', email: 'ada@example.com')]);
    expect(form.isDirty, isFalse);
  });

  test('branded swaps the accent only', () {
    final brand = branding.brand;
    expect(brand.name, 'Carbon (Acme)');
    expect(brand.palette.primary, isNot(carbonTheme.palette.primary));
    expect(brand.palette.surface, carbonTheme.palette.surface);
    expect(brand.darkPalette!.background, carbonTheme.darkPalette!.background);

    final tokens = branding.tokens;
    final shadcn = shadcnTheme.tokens;
    expect(tokens.palette.primary, isNot(shadcn.palette.primary));
    expect(tokens.palette.foreground, shadcn.palette.foreground);
    expect(tokens.radii, shadcn.radii);
  });

  test('a theme of your own takes its palette, shape and sizes', () {
    final theme = acmeTheme;
    final tokens = theme.tokens;
    expect(tokens.palette.primary, const Color(0xFF2563EB));
    expect(tokens.palette.surface, irisPalette.surface);
    expect(tokens.radii.radius, 6);
    expect(tokens.typography.spec.uppercaseLabels, isFalse);
    expect(tokens.sizes.height(ControlSize.large), 44);
    expect(tokens.table.rowHeight(TableDensity.compact), 36);

    final dark = theme.dark!;
    expect(dark.palette.brightness, Brightness.dark);
    expect(dark.sizes, tokens.sizes);
  });

  group('the Libraries table', () {
    test('has a row for every barrel, and only those', () {
      final barrels = {
        for (final f in Directory('lib').listSync())
          if (f is File && f.path.endsWith('.dart')) f.uri.pathSegments.last,
      };
      expect([
        for (final r in _rows(_section('## Libraries')))
          r.first.replaceAll('`', ''),
      ], unorderedEquals(barrels));
    });

    test('names only what each barrel exports', () {
      final api = _api();
      final wrong = [
        for (final [cell, contents, ...] in _rows(_section('## Libraries')))
          for (final name in _identifiers(contents))
            if (cell.replaceAll('`', '') case final barrel
                when !(api[barrel]?.contains(name) ?? false) &&
                    !(_namedElsewhere[barrel]?.contains(name) ?? false))
              '$barrel $name',
      ];
      expect(wrong, isEmpty, reason: 'api.txt has no such line');
    });

    test('lists every barrel an umbrella re-exports', () {
      for (final [cell, contents, ...] in _rows(_section('## Libraries'))) {
        final barrel = cell.replaceAll('`', '');
        final reexported = {
          for (final line in File('lib/$barrel').readAsLinesSync())
            if (RegExp(r"^export '(\w+)\.dart';$").firstMatch(line)
                case final m?)
              m[1]!,
        };
        if (reexported.isEmpty) continue;
        final named = RegExp(r'`(\w+)(?:\.dart)?`')
            .allMatches(contents)
            .map((m) => m[1]!)
            .toSet();
        expect(named, reexported, reason: '$barrel row');
      }
    });
  });

  group('the Theming tables are the shipped tokens', () {
    AdminTokens tokensOf(String theme) =>
        adminThemes.firstWhere((t) => t.name == theme).tokens;

    test('Type ramp: each role\'s size/line and tracking', () {
      final section = _section('### Type ramp');
      final header = section
          .split('\n')
          .firstWhere((l) => l.startsWith('|'))
          .split('|')
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty)
          .skip(1)
          .toList();
      expect(header, adminThemes.map((t) => t.name));
      String cell(AdminTypeStep step) {
        String n(double v) => v.abs() == v.abs().roundToDouble()
            ? v.abs().toStringAsFixed(0)
            : '${v.abs()}';
        final tracking = step.letterSpacing;
        return [
          '${n(step.size)}/${n(step.line)}',
          if (tracking > 0) '+${n(tracking)}',
          if (tracking < 0) '−${n(tracking)}',
        ].join(' ');
      }

      final rows = _rows(section);
      expect(rows, isNotEmpty);
      for (final [role, ...cells] in rows) {
        final name = role.replaceAll('`', '');
        for (final (i, theme) in header.indexed) {
          final step = tokensOf(theme).typography.spec.ramp.steps[name];
          expect(step, isNotNull, reason: 'no role $name');
          expect(cells[i], cell(step!), reason: '$theme $name');
        }
      }
    });

    test('Motion: each theme\'s durations', () {
      for (final [theme, durations, pulse, ...] in _rows(
        _section('### Motion'),
      )) {
        final motion = tokensOf(theme).motion;
        final ms = RegExp(r'\d+').allMatches(durations).take(3);
        expect(
          [for (final m in ms) int.parse(m[0]!)],
          [
            motion.fast.inMilliseconds,
            motion.medium.inMilliseconds,
            motion.slow.inMilliseconds,
          ],
          reason: theme,
        );
        expect(pulse, '${motion.pulse.inMilliseconds}ms', reason: theme);
      }
    });

    test('Stroke: each theme\'s field outlines', () {
      final rows = _rows(_section('### Stroke, icon sizes and state layers'));
      expect(rows.map((r) => r.first), adminThemes.map((t) => t.name));
      for (final [theme, focus, error, halo, ...] in rows) {
        final stroke = tokensOf(theme).stroke;
        expect(double.parse(focus), stroke.fieldFocus, reason: theme);
        expect(double.parse(error), stroke.fieldError, reason: theme);
        expect(double.parse(halo), stroke.fieldFocusHalo, reason: theme);
      }
    });

    test('Name clashes: every token shorthand', () {
      final section = _section('## Name clashes');
      for (final getter in [
        'colors',
        'type',
        'radii',
        'elevation',
        'focus',
        'sizes',
        'tableMetrics',
        'motion',
        'stroke',
        'iconSizes',
        'fieldStyle',
        'buttonStyle',
        'shellStyle',
        'overlayStyle',
        'breakpoints',
      ]) {
        expect(section, contains('`context.$getter`'), reason: getter);
      }
    });
  });

  test('the Layer order table is the one layers_test.dart enforces', () {
    final section = _section('## Layer order');
    final table = {
      for (final [layer, dirs, ...] in _rows(section))
        for (final dir in RegExp(r'`(\w+)`').allMatches(dirs))
          dir[1]!: int.parse(layer),
    };
    expect(table, layers);
    for (final edge in allowed.keys) {
      for (final path in edge.split(' -> ')) {
        expect(
          section,
          contains('`$path`'),
          reason: 'README.md does not name the allowed import $edge',
        );
      }
    }
  });
}
