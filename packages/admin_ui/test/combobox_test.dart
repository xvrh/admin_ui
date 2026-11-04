import 'package:admin_ui/src/common/ui/clear_button.dart';
import 'package:admin_ui/src/common/ui/combobox.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _opts = [
  ComboboxOption('a', 'Apple'),
  ComboboxOption('b', 'Banana'),
  ComboboxOption('c', 'Cherry'),
];

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: 300, child: child)),
  ),
);

void main() {
  testWidgets('opens on tap and filters as you type', (tester) async {
    String? picked;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => Combobox<String>(
            value: picked,
            onChanged: (v) => setState(() => picked = v),
            options: _opts,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(find.text('Banana'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ch');
    await tester.pumpAndSettle();
    expect(find.text('Cherry'), findsOneWidget);
    expect(find.text('Apple'), findsNothing);

    await tester.tap(find.text('Cherry'));
    await tester.pumpAndSettle();
    expect(picked, 'c');
  });

  testWidgets('keyboard arrows + enter select a value', (tester) async {
    String? picked;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => Combobox<String>(
            value: picked,
            onChanged: (v) => setState(() => picked = v),
            options: _opts,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // -> Banana
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(picked, 'b');
  });

  testWidgets('clearable resets to null', (tester) async {
    String? picked = 'a';
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => Combobox<String>(
            value: picked,
            onChanged: (v) => setState(() => picked = v),
            options: _opts,
            clearable: true,
          ),
        ),
      ),
    );

    final clear = find.byType(ClearButton);
    expect(tester.widget<ClearButton>(clear).label, 'Clear selection');
    await tester.tap(clear);
    await tester.pumpAndSettle();
    expect(picked, isNull);
  });
}
