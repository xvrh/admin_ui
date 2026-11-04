import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The rendered text, and the parts drawn in the highlight colour.
(String, List<String>) _render(WidgetTester tester) {
  final rich = tester.widget<RichText>(
    find.descendant(
      of: find.byType(HighlightedText),
      matching: find.byType(RichText),
    ),
  );
  final highlighted = <String>[];
  final accent = defaultTokens.palette.primaryText;
  rich.text.visitChildren((span) {
    if (span is TextSpan && span.style?.color == accent && span.text != null) {
      highlighted.add(span.text!);
    }
    return true;
  });
  return (rich.text.toPlainText(), highlighted);
}

/// Renders [text] with [ranges], checks every character shows exactly once,
/// and returns the highlighted parts.
Future<List<String>> _pump(
  WidgetTester tester,
  String text,
  List<int> ranges,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(defaultTokens),
      home: Scaffold(body: HighlightedText(text, ranges: ranges)),
    ),
  );
  final (plain, highlighted) = _render(tester);
  expect(plain, text);
  return highlighted;
}

void main() {
  const text = 'hello world';

  testWidgets('highlights sorted, separate ranges', (tester) async {
    expect(await _pump(tester, text, [0, 5, 6, 11]), ['hello', 'world']);
  });

  testWidgets('merges overlapping ranges', (tester) async {
    expect(await _pump(tester, text, [0, 5, 2, 4]), ['hello']);
    expect(await _pump(tester, text, [0, 5, 3, 8]), ['hello wo']);
  });

  testWidgets('sorts ranges that arrive out of order', (tester) async {
    expect(await _pump(tester, text, [6, 11, 0, 5]), ['hello', 'world']);
  });

  testWidgets('merges touching ranges', (tester) async {
    expect(await _pump(tester, text, [0, 2, 2, 5]), ['hello']);
  });

  testWidgets('ignores a trailing odd offset', (tester) async {
    expect(await _pump(tester, text, [0, 5, 7]), ['hello']);
  });

  testWidgets('clamps out-of-bounds ranges to the text', (tester) async {
    expect(await _pump(tester, text, [-4, 2, 9, 40]), ['he', 'ld']);
    expect(await _pump(tester, text, [20, 30]), <String>[]);
  });

  testWidgets('ignores reversed and empty pairs', (tester) async {
    expect(await _pump(tester, text, [5, 0, 3, 3]), <String>[]);
  });

  testWidgets('no ranges renders the plain text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(defaultTokens),
        home: const Scaffold(body: HighlightedText(text)),
      ),
    );
    expect(find.text(text), findsOneWidget);
  });
}
