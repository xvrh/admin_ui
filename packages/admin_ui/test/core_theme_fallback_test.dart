// Alone in its file: the warning is printed once per isolate, so a test
// before this one reading tokens under a bare Theme would already have used it.

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// [child] with no material_ui Theme above it, as under a MaterialApp from
/// package:flutter/material.dart, whose Theme the kit cannot see.
Widget _bare(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

void main() {
  group('no material_ui Theme above', () {
    testWidgets('reading the tokens throws in debug, naming the fix', (
      tester,
    ) async {
      await tester.pumpWidget(
        _bare(
          Builder(
            builder: (context) {
              context.adminTokens;
              return const SizedBox();
            },
          ),
        ),
      );
      final error = tester.takeException();
      expect(error, isA<FlutterError>());
      expect('$error', contains('No material_ui Theme above Builder'));
      expect('$error', contains('buildAppTheme(tokens)'));
      expect('$error', contains('is not supported'));
      expect('$error', contains('package:flutter/material.dart'));
    });

    testWidgets('so does a kit widget, and every token getter', (tester) async {
      await tester.pumpWidget(_bare(const Button('Save')));
      expect(tester.takeException(), isA<FlutterError>());

      late BuildContext context;
      await tester.pumpWidget(
        _bare(
          Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      );
      for (final read in <Object Function()>[
        () => context.colors,
        () => context.type,
        () => context.radii,
        () => context.elevation,
        () => context.focus,
        () => context.sizes,
        () => context.tableMetrics,
      ]) {
        expect(read, throwsFlutterError);
      }
    });

    testWidgets('AdminScope(tokens:) supplies them', (tester) async {
      final tokens = AdminTokens.from(palette: irisDarkPalette);
      late BuildContext context;
      await tester.pumpWidget(
        _bare(
          AdminScope(
            tokens: tokens,
            child: Builder(
              builder: (c) {
                context = c;
                return const Button('Save');
              },
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(context.adminTokens, same(tokens));
    });
  });

  testWidgets('a Theme without AdminTokens falls back to Iris and warns once', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      ),
    );

    final printed = <String?>[];
    final original = debugPrint;
    debugPrint = (message, {wrapWidth}) => printed.add(message);
    try {
      expect(context.adminTokens, same(defaultTokens));
      expect(context.colors, same(defaultTokens.palette));
      expect(context.adminTokens, same(defaultTokens));
    } finally {
      debugPrint = original;
    }
    expect(printed, hasLength(1));
    expect(printed.single, contains('no AdminTokens'));
    expect(printed.single, contains('buildAppTheme'));
    expect(printed.single, contains('AdminScope'));
  });

  testWidgets('a theme built by buildAppTheme carries its tokens', (
    tester,
  ) async {
    final tokens = AdminTokens.from(palette: irisDarkPalette);
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(tokens),
        home: Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(context.adminTokens, same(tokens));
    expect(context.colors, same(tokens.palette));
  });
}
