import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  home: Scaffold(body: Center(child: child)),
);

/// What one activation of a [Check] reports, by [activate].
Future<bool?> _report(
  WidgetTester tester, {
  required bool value,
  required bool indeterminate,
  required Future<void> Function() activate,
  String? label,
}) async {
  bool? reported;
  await tester.pumpWidget(
    _host(
      Check(
        value: value,
        indeterminate: indeterminate,
        label: label,
        semanticLabel: 'Select all',
        onChanged: (v) => reported = v,
      ),
    ),
  );
  await activate();
  await tester.pump();
  return reported;
}

void main() {
  // Radix and Material: a mixed box checks on activation, so a select-all
  // header goes from some to all, then to none.
  for (final (name, activate)
      in <(String, Future<void> Function(WidgetTester))>[
        ('a tap', (tester) => tester.tap(find.byType(Check))),
        (
          'Space',
          (tester) async {
            await tester.sendKeyEvent(LogicalKeyboardKey.tab);
            await tester.sendKeyEvent(LogicalKeyboardKey.space);
          },
        ),
      ]) {
    testWidgets('$name on an indeterminate Check reports true', (tester) async {
      for (final value in [false, true]) {
        expect(
          await _report(
            tester,
            value: value,
            indeterminate: true,
            activate: () => activate(tester),
          ),
          isTrue,
          reason: 'value: $value',
        );
      }
    });

    testWidgets('$name on a determinate Check flips it', (tester) async {
      for (final value in [false, true]) {
        expect(
          await _report(
            tester,
            value: value,
            indeterminate: false,
            activate: () => activate(tester),
          ),
          !value,
        );
      }
    });
  }

  testWidgets('a tap on the label of an indeterminate Check reports true', (
    tester,
  ) async {
    expect(
      await _report(
        tester,
        value: false,
        indeterminate: true,
        label: 'Select all',
        activate: () => tester.tap(find.text('Select all')),
      ),
      isTrue,
    );
  });
}
