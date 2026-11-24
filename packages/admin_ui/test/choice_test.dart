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

  group('cards side by side', () {
    const a = Key('a');
    const b = Key('b');
    const cards = Choice<String>(
      value: 'a',
      onChanged: null,
      style: ChoiceStyle.card,
      direction: Axis.horizontal,
      options: [
        ChoiceOption(
          'a',
          'Monthly',
          key: a,
          description: 'Billed on the first day of each month.',
        ),
        ChoiceOption(
          'b',
          'Yearly',
          key: b,
          description:
              'Billed once a year, on the day the plan started, with two '
              'months free and a reminder a week before it renews.',
        ),
      ],
    );

    Future<void> pump(
      WidgetTester tester,
      Widget child, {
      TextDirection? dir,
    }) => tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: dir ?? TextDirection.ltr,
          child: Scaffold(
            body: Align(alignment: Alignment.topLeft, child: child),
          ),
        ),
      ),
    );

    testWidgets('share a bounded width evenly, at the tallest one\'s height', (
      tester,
    ) async {
      await pump(tester, const SizedBox(width: 416, child: cards));

      expect(tester.takeException(), isNull);
      final first = tester.getRect(find.byKey(a));
      final second = tester.getRect(find.byKey(b));
      expect(first.width, 200);
      expect(second.width, 200);
      expect(first.left, 0);
      expect(second.left, 216);
      expect(first.height, second.height);
      expect(first.top, second.top);
      // The longer description wraps, and the shorter card grows to match.
      expect(
        first.height,
        greaterThan(tester.getSize(find.text('Monthly')).height * 3),
      );
    });

    testWidgets('line up again when a card\'s content grows', (tester) async {
      Widget choice(String description) => SizedBox(
        width: 416,
        child: Choice<String>(
          value: 'a',
          onChanged: null,
          style: ChoiceStyle.card,
          direction: Axis.horizontal,
          options: [
            ChoiceOption('a', 'Monthly', key: a, description: description),
            const ChoiceOption(
              'b',
              'Yearly',
              key: b,
              description: 'Two months free.',
            ),
          ],
        ),
      );
      await pump(tester, choice('Each month.'));
      final before = tester.getSize(find.byKey(b)).height;

      await pump(
        tester,
        choice(
          'Billed on the first day of each month, with a receipt by email '
          'and a reminder a week before.',
        ),
      );

      expect(tester.takeException(), isNull);
      final first = tester.getSize(find.byKey(a)).height;
      expect(first, greaterThan(before));
      expect(tester.getSize(find.byKey(b)).height, first);
    });

    testWidgets('read in the page\'s direction', (tester) async {
      await pump(
        tester,
        const SizedBox(width: 416, child: cards),
        dir: TextDirection.rtl,
      );

      expect(tester.takeException(), isNull);
      expect(tester.getRect(find.byKey(a)).left, 216);
      expect(tester.getRect(find.byKey(b)).left, 0);
    });

    testWidgets('with no width to share, each is as wide as the widest needs', (
      tester,
    ) async {
      await pump(
        tester,
        const SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: cards,
        ),
      );

      expect(tester.takeException(), isNull);
      final first = tester.getRect(find.byKey(a));
      final second = tester.getRect(find.byKey(b));
      expect(first.size, second.size);
      expect(second.left, first.right + AdminSpacing.xl);
      // The long description stands on one line.
      expect(
        tester.getSize(find.textContaining('Billed once')).height,
        tester.getSize(find.textContaining('Billed on the')).height,
      );
    });

    testWidgets('asked how wide they would be, say what they take with none', (
      tester,
    ) async {
      const short = Choice<String>(
        value: 'a',
        onChanged: null,
        style: ChoiceStyle.card,
        direction: Axis.horizontal,
        options: [
          ChoiceOption('a', 'Monthly', key: a, description: 'Each month.'),
          ChoiceOption('b', 'Yearly', key: b, description: 'Two months free.'),
        ],
      );
      await pump(
        tester,
        const SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: short,
        ),
      );
      final natural = tester.getRect(find.byKey(b)).right;

      await pump(tester, const IntrinsicWidth(child: short));

      expect(tester.takeException(), isNull);
      expect(tester.getRect(find.byKey(b)).right, natural);
      expect(tester.getSize(find.byKey(a)), tester.getSize(find.byKey(b)));
    });

    testWidgets('a plain row still hugs its labels', (tester) async {
      await pump(
        tester,
        const SizedBox(
          width: 416,
          child: Choice<String>(
            value: 'a',
            onChanged: null,
            direction: Axis.horizontal,
            options: [
              ChoiceOption('a', 'One', key: a),
              ChoiceOption('b', 'Two', key: b),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final first = tester.getRect(find.byKey(a));
      final second = tester.getRect(find.byKey(b));
      expect(first.width, lessThan(100));
      expect(second.left, first.right + AdminSpacing.xl);
    });
  });
}
