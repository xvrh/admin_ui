import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('selecting an option reports its value', (tester) async {
    String? picked;
    await tester.pumpWidget(
      _host(
        Choice<String>(
          value: 'a',
          onChanged: (v) => picked = v,
          options: const [
            ChoiceOption('a', 'Alpha'),
            ChoiceOption('b', 'Beta'),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Beta'));
    expect(picked, 'b');
  });

  testWidgets('the selected option does not re-fire', (tester) async {
    var fired = false;
    await tester.pumpWidget(
      _host(
        Choice<String>(
          value: 'a',
          onChanged: (_) => fired = true,
          options: const [ChoiceOption('a', 'Alpha')],
        ),
      ),
    );

    await tester.tap(find.text('Alpha'));
    expect(fired, isFalse);
  });

  testWidgets('disabled option and read-only group never fire', (tester) async {
    var fired = false;
    await tester.pumpWidget(
      _host(
        Choice<String>(
          value: 'a',
          onChanged: (_) => fired = true,
          options: const [
            ChoiceOption('a', 'Alpha'),
            ChoiceOption('b', 'Beta', enabled: false),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Beta'));
    expect(fired, isFalse);
  });

  testWidgets('card style shows the description', (tester) async {
    await tester.pumpWidget(
      _host(
        const Choice<String>(
          value: 'a',
          onChanged: null,
          style: ChoiceStyle.card,
          options: [
            ChoiceOption('a', 'Alpha', description: 'the first letter'),
          ],
        ),
      ),
    );

    expect(find.text('the first letter'), findsOneWidget);
  });

  testWidgets('a read-only group dims its selection; an enabled group keeps '
      'its value in colour even on a disabled option', (tester) async {
    final theme = buildAppTheme(defaultTokens);
    final colors = defaultTokens.palette;
    Color ring(String label) {
      final dot = tester.widget<Container>(
        find
            .descendant(
              of: find.ancestor(
                of: find.text(label),
                matching: find.byType(Row),
              ),
              matching: find.byWidgetPredicate(
                (w) =>
                    w is Container &&
                    w.decoration is BoxDecoration &&
                    (w.decoration! as BoxDecoration).shape == BoxShape.circle,
              ),
            )
            .first,
      );
      return ((dot.decoration! as BoxDecoration).border! as Border).top.color;
    }

    Future<void> pump(ValueChanged<String>? onChanged) => tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Choice<String>(
            value: 'a',
            onChanged: onChanged,
            options: const [
              ChoiceOption('a', 'Alpha', enabled: false),
              ChoiceOption('b', 'Beta'),
            ],
          ),
        ),
      ),
    );

    await pump(null);
    expect(ring('Alpha'), colors.foregroundSubtle);
    expect(ring('Beta'), colors.foregroundFaint);

    await pump((_) {});
    expect(ring('Alpha'), colors.primary);
  });
}
