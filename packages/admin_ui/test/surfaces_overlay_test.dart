import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'shipped_palettes.dart';

/// A canvas colour no palette uses, so a surface that falls back to
/// `canvasColor` instead of naming its own shows up.
const _stray = Color(0xFFFF00FF);

Widget _host(AdminPalette palette, Widget child) {
  final theme = buildAppTheme(AdminTokens.from(palette: palette));
  return MaterialApp(
    theme: theme.copyWith(canvasColor: _stray),
    home: Scaffold(
      body: Center(child: SizedBox(width: 640, height: 480, child: child)),
    ),
  );
}

/// The outermost [Material] under [surface]: the one that paints its fill and
/// border.
Material _surfaceMaterial(WidgetTester tester, Finder surface) => tester
    .widgetList<Material>(
      find.descendant(of: surface, matching: find.byType(Material)),
    )
    .first;

void _expectFloating(Material material, AdminPalette palette) {
  expect(material.color, palette.surface);
  final side = switch (material.shape) {
    RoundedRectangleBorder(:final side) => side,
    Border(:final left, :final right) => left.width > 0 ? left : right,
    final other => fail('unexpected surface shape $other'),
  };
  expect(side.color, palette.border);
  expect(side.width, 1);
}

void main() {
  for (final MapEntry(key: name, value: palette) in shippedPalettes.entries) {
    group(name, () {
      testWidgets('PopoverMenuSurface paints surface with a border', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(palette, const PopoverMenuSurface(child: Text('menu'))),
        );
        _expectFloating(
          _surfaceMaterial(tester, find.byType(PopoverMenuSurface)),
          palette,
        );
      });

      testWidgets('Modal, CommandPalette and SideSheet are bordered surfaces', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(palette, const Modal(title: 'Title', message: 'Body')),
        );
        _expectFloating(_surfaceMaterial(tester, find.byType(Modal)), palette);

        await tester.pumpWidget(
          _host(palette, const CommandPalette(items: [])),
        );
        _expectFloating(
          _surfaceMaterial(tester, find.byType(CommandPalette)),
          palette,
        );

        for (final side in SideSheetSide.values) {
          await tester.pumpWidget(
            _host(palette, SideSheet(side: side, child: const SizedBox())),
          );
          final material = _surfaceMaterial(tester, find.byType(SideSheet));
          _expectFloating(material, palette);
          // The hairline runs along the edge that faces the page.
          final border = material.shape! as Border;
          final inner = side == SideSheetSide.end ? border.left : border.right;
          final outer = side == SideSheetSide.end ? border.right : border.left;
          expect(inner.color, palette.border);
          expect(outer, BorderSide.none);
        }
      });

      testWidgets('a toast is a bordered surface card', (tester) async {
        await tester.pumpWidget(
          _host(
            palette,
            ToastScope(
              child: Builder(
                builder: (context) => TextButton(
                  onPressed: () =>
                      ToastScope.of(context).show(const Toast('Saved.')),
                  child: const Text('go'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('go'));
        await tester.pumpAndSettle();
        final card = find.ancestor(
          of: find.text('Saved.'),
          matching: find.byType(Material),
        );
        _expectFloating(tester.widgetList<Material>(card).first, palette);
      });

      testWidgets('the command palette field shows no border when focused', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(palette, const CommandPalette(items: [])),
        );
        await tester.pump(); // autofocus lands

        final decorator = tester.widget<InputDecorator>(
          find.descendant(
            of: find.byType(CommandPalette),
            matching: find.byType(InputDecorator),
          ),
        );
        expect(decorator.isFocused, isTrue);
        final decoration = decorator.decoration;
        expect(decoration.filled, isFalse);
        for (final border in [
          decoration.border,
          decoration.enabledBorder,
          decoration.focusedBorder,
          decoration.disabledBorder,
          decoration.errorBorder,
          decoration.focusedErrorBorder,
        ]) {
          expect(border, InputBorder.none);
        }
        expect(decoration.hintStyle?.color, palette.placeholder);
      });
    });
  }

  testWidgets(
    'a theme-level focused border does not reach the command palette field',
    (tester) async {
      final theme = buildAppTheme(AdminTokens.from(palette: irisPalette));
      await tester.pumpWidget(
        MaterialApp(
          theme: theme.copyWith(
            inputDecorationTheme: theme.inputDecorationTheme.copyWith(
              filled: true,
              enabledBorder: const OutlineInputBorder(),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(width: 2),
              ),
            ),
          ),
          home: const Scaffold(body: CommandPalette(items: [])),
        ),
      );
      await tester.pump();

      final decoration = tester
          .widget<InputDecorator>(find.byType(InputDecorator))
          .decoration;
      expect(decoration.focusedBorder, InputBorder.none);
      expect(decoration.enabledBorder, InputBorder.none);
      expect(decoration.filled, isFalse);
    },
  );

  testWidgets('menu rows: danger reads as text, hover takes listHighlight', (
    tester,
  ) async {
    for (final palette in [antPalette, carbonDarkPalette]) {
      await tester.pumpWidget(
        _host(
          palette,
          Align(
            alignment: Alignment.topLeft,
            child: Menu(
              builder: (context, c) =>
                  TextButton(onPressed: c.toggle, child: const Text('open')),
              entries: [
                MenuItem('Delete', danger: true, onSelect: () {}),
                MenuItem('Edit', onSelect: () {}),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final delete = tester.widget<Text>(find.text('Delete'));
      expect(delete.style!.color, palette.dangerText);
      expect(
        contrastRatio(palette.dangerText, palette.surface),
        greaterThanOrEqualTo(4.5),
      );

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.text('Edit')));
      await tester.pumpAndSettle();
      final row = tester.widget<DecoratedBox>(
        find
            .ancestor(
              of: find.text('Edit'),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect((row.decoration as BoxDecoration).color, palette.listHighlight);
      await mouse.removePointer();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }
  });
}
