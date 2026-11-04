import 'package:admin_ui/src/fields/ui/history_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _versions = [
  FieldVersion(
    label: 'Editing now',
    author: 'You',
    initials: 'Yo',
    color: Color(0xFF5b5bd6),
    time: 'live',
    current: true,
  ),
  FieldVersion(
    label: 'Published v3',
    author: 'Marina',
    initials: 'MC',
    color: Color(0xFF9333a8),
    time: 'Yesterday',
  ),
];

Widget _host(HistoryButton button) => MaterialApp(
  home: Scaffold(body: Center(child: button)),
);

void main() {
  testWidgets('unmodified shows a quiet history icon, no "Edited"', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const HistoryButton(
          draft: 'same',
          baseline: 'same',
          versions: _versions,
        ),
      ),
    );

    expect(find.text('Edited'), findsNothing);
    expect(find.byIcon(Icons.history), findsOneWidget);
  });

  testWidgets('modified stands out, compares, and reverts', (tester) async {
    var reverted = false;
    await tester.pumpWidget(
      _host(
        HistoryButton(
          draft: 'new draft',
          baseline: 'old published',
          versions: _versions,
          onRevert: () => reverted = true,
        ),
      ),
    );

    expect(find.text('Edited'), findsOneWidget);

    await tester.tap(find.text('Edited'));
    await tester.pumpAndSettle();

    // Compare shows both values + the version list.
    expect(find.text('new draft'), findsOneWidget);
    expect(find.text('old published'), findsOneWidget);
    expect(find.text('Published v3'), findsOneWidget);

    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();
    expect(reverted, isTrue);
    // Popover closed (host would clear the modified state on its next build).
    expect(find.text('Restore'), findsNothing);
  });
}
