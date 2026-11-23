// A number field of a form shows what its number counts after it, as the
// bare input does: a unit drawn in the field, read with it, and no part of
// the value.

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The four number fields, each over a cell of its own in [scope].
typedef _Build = Widget Function(
  LocalScope scope, {
  String? prefix,
  String? unit,
});

final _fields = <(String, _Build, Object? Function(LocalScope))>[
  (
    'NumberField',
    (s, {prefix, unit}) =>
        NumberField(s.number('n'), label: 'Weight', prefix: prefix, unit: unit),
    (s) => s.number('n').value,
  ),
  (
    'OptionalNumberField',
    (s, {prefix, unit}) => OptionalNumberField(
      s.numberOrNull('n'),
      label: 'Weight',
      prefix: prefix,
      unit: unit,
    ),
    (s) => s.numberOrNull('n').value,
  ),
  (
    'DecimalField',
    (s, {prefix, unit}) => DecimalField(
      s.decimal('n'),
      label: 'Weight',
      prefix: prefix,
      unit: unit,
    ),
    (s) => s.decimal('n').value,
  ),
  (
    'OptionalDecimalField',
    (s, {prefix, unit}) => OptionalDecimalField(
      s.decimalOrNull('n'),
      label: 'Weight',
      prefix: prefix,
      unit: unit,
    ),
    (s) => s.decimalOrNull('n').value,
  ),
];

Future<LocalScope> _pump(
  WidgetTester tester,
  _Build build, {
  String? prefix,
  String? unit,
  bool readOnly = false,
}) async {
  final scope = LocalScope();
  addTearDown(scope.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(irisTheme.tokens),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 320,
            child: FieldStateScope(
              readOnly: readOnly,
              child: build(scope, prefix: prefix, unit: unit),
            ),
          ),
        ),
      ),
    ),
  );
  return scope;
}

void main() {
  for (final (name, build, value) in _fields) {
    group(name, () {
      testWidgets('shows its unit after the number, in the field', (
        tester,
      ) async {
        await _pump(tester, build, unit: 'kg');
        final field = tester.getRect(find.byType(TextField));
        final unit = tester.getRect(find.text('kg'));
        expect(field.contains(unit.center), isTrue);
        expect(unit.center.dx, greaterThan(field.center.dx));
        expect(tester.widget<NumberBody>(find.byType(NumberBody)).unit, 'kg');
      });

      testWidgets('the unit is no part of the value', (tester) async {
        final scope = await _pump(tester, build, unit: 'kg');
        await tester.enterText(find.byType(EditableText), '12');
        await tester.pump();
        expect(value(scope), 12);
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText))
              .controller
              .text,
          '12',
        );
      });

      testWidgets('is read with its unit', (tester) async {
        final handle = tester.ensureSemantics();
        await _pump(tester, build, prefix: '~', unit: 'kg');
        expect(
          tester.getSemantics(find.byType(EditableText)).hint,
          contains('~ kg'),
        );
        handle.dispose();
      });

      testWidgets('a prefix stays ahead of the number, the unit after it', (
        tester,
      ) async {
        await _pump(tester, build, prefix: '~', unit: 'kg');
        final field = tester.getRect(find.byType(TextField));
        expect(
          tester.getRect(find.text('~')).center.dx,
          lessThan(field.center.dx),
        );
        expect(
          tester.getRect(find.text('kg')).center.dx,
          greaterThan(field.center.dx),
        );
      });

      testWidgets('with no unit there is none', (tester) async {
        await _pump(tester, build, prefix: '~');
        expect(tester.widget<NumberBody>(find.byType(NumberBody)).unit, isNull);
        expect(find.text('~'), findsOneWidget);
        expect(find.text('kg'), findsNothing);
      });

      testWidgets('a read-only form keeps the unit', (tester) async {
        await _pump(tester, build, unit: 'kg', readOnly: true);
        expect(find.text('kg'), findsOneWidget);
        expect(
          tester.widget<TextField>(find.byType(TextField)).readOnly,
          isTrue,
        );
      });
    });
  }
}
