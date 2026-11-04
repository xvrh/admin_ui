import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

enum Hue {
  red,
  green;

  String toJson() => name;
  static Hue fromJson(String s) => values.byName(s);
}

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('OptionalBooleanField reflects the nullable cell', (
    tester,
  ) async {
    final scope = LocalScope();
    final cell = scope.booleanOrNull('featured');
    await tester.pumpWidget(
      _host(OptionalBooleanField(cell, label: 'Featured')),
    );
    expect(cell.value, isNull);

    cell.set(true);
    await tester.pump();
    expect(tester.widget<BooleanBody>(find.byType(BooleanBody)).value, isTrue);
    scope.dispose();
  });

  testWidgets('OptionalDecimalField: empty input is null, not 0', (
    tester,
  ) async {
    final scope = LocalScope();
    final cell = scope.decimalOrNull('score');
    await tester.pumpWidget(_host(OptionalDecimalField(cell, label: 'Score')));

    await tester.enterText(find.byType(TextField), '4.5');
    await tester.pump();
    expect(cell.value, 4.5);

    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(cell.value, isNull);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
      reason: 'no "0" reseeded',
    );
    scope.dispose();
  });

  testWidgets('OptionalDateField binds a DateTime cell', (tester) async {
    final scope = LocalScope();
    final cell = scope.dateOrNull('publishedAt');
    await tester.pumpWidget(_host(OptionalDateField(cell, label: 'Published')));
    expect(tester.widget<DateBody>(find.byType(DateBody)).value, isNull);

    final when = DateTime.utc(2026, 6, 20);
    cell.set(when);
    await tester.pump();
    expect(tester.widget<DateBody>(find.byType(DateBody)).value, when);
    scope.dispose();
  });

  testWidgets('ColorField binds a hex string cell', (tester) async {
    final scope = LocalScope();
    final cell = scope.text('brand');
    await tester.pumpWidget(_host(ColorField(cell, label: 'Brand')));

    cell.set('#1A2B3C');
    await tester.pump();
    expect(tester.widget<ColorBody>(find.byType(ColorBody)).value, '#1A2B3C');
    scope.dispose();
  });

  testWidgets('MultiSelectField binds a string-list cell', (tester) async {
    final scope = LocalScope();
    final cell = scope.list('regions');
    await tester.pumpWidget(
      _host(
        MultiSelectField(
          cell,
          label: 'Regions',
          options: const [
            SelectOption(value: 'eu', label: 'EU'),
            SelectOption(value: 'us', label: 'US'),
          ],
        ),
      ),
    );
    cell.set(['eu']);
    await tester.pump();
    expect(tester.widget<MultiSelectBody>(find.byType(MultiSelectBody)).value, {
      'eu',
    });
    scope.dispose();
  });

  testWidgets('EnumSelectField binds a typed enum cell, persists the code', (
    tester,
  ) async {
    final scope = LocalScope();
    final cell = scope.enumCell<Hue>(
      'hue',
      encode: (e) => e.toJson(),
      decode: Hue.fromJson,
      fallback: Hue.red,
    );
    await tester.pumpWidget(
      _host(
        EnumSelectField(
          cell,
          label: 'Hue',
          values: Hue.values,
          labelOf: (h) => h.name,
        ),
      ),
    );
    expect(cell.value, Hue.red);
    final body = tester.widget<SelectBody>(find.byType(SelectBody));
    expect(body.options.length, 2);

    cell.set(Hue.green);
    await tester.pump();
    expect(cell.value, Hue.green);
    scope.dispose();
  });

  testWidgets('MaskedField builds over a string cell', (tester) async {
    final scope = LocalScope();
    await tester.pumpWidget(
      _host(
        MaskedField(
          scope.text('phone'),
          label: 'Phone',
          mask: '(###) ###-####',
        ),
      ),
    );
    expect(find.byType(MaskedBody), findsOneWidget);
    scope.dispose();
  });
}
