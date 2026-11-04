import 'package:admin_ui/src/common/ui/timeline.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: 400, child: child)),
  ),
);

void main() {
  testWidgets('renders an entry per item with title, subtitle and timestamp', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const Timeline(
          entries: [
            TimelineEntry(
              title: 'Published',
              subtitle: 'went live',
              timestamp: '2h ago',
            ),
            TimelineEntry(title: 'Created'),
          ],
        ),
      ),
    );

    expect(find.text('Published'), findsOneWidget);
    expect(find.text('went live'), findsOneWidget);
    expect(find.text('2h ago'), findsOneWidget);
    expect(find.text('Created'), findsOneWidget);
  });

  testWidgets('icon node and trailing widget render', (tester) async {
    await tester.pumpWidget(
      _host(
        const Timeline(
          entries: [
            TimelineEntry(
              title: 'Edited',
              icon: Icons.edit_rounded,
              trailing: Text('TAG'),
            ),
          ],
        ),
      ),
    );

    expect(find.byIcon(Icons.edit_rounded), findsOneWidget);
    expect(find.text('TAG'), findsOneWidget);
  });

  testWidgets('titleWidget overrides title', (tester) async {
    await tester.pumpWidget(
      _host(
        const Timeline(entries: [TimelineEntry(titleWidget: Text('RICH'))]),
      ),
    );

    expect(find.text('RICH'), findsOneWidget);
  });
}
