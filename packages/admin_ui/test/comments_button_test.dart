import 'package:admin_ui/src/common/ui/focus_ring.dart';
import 'package:admin_ui/src/fields/ui/comments_button.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _messages = [
  CommentEntry(
    author: 'Lena',
    initials: 'LF',
    color: Color(0xFFd97706),
    time: '14m',
    body: 'Love this headline.',
  ),
  CommentEntry(
    author: 'Diego',
    initials: 'DR',
    color: Color(0xFF0f9d8f),
    time: '6m',
    body: 'Agreed.',
  ),
];

void main() {
  testWidgets('opens the thread and emits a reply', (tester) async {
    String? replied;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CommentsButton(
              count: _messages.length,
              messages: _messages,
              anchor: 'keeps its own time',
              onReply: (text) => replied = text,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Love this headline.'), findsNothing);

    await tester.tap(find.byIcon(Icons.mode_comment_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Love this headline.'), findsOneWidget);
    expect(find.text('Agreed.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Looks good');
    await tester.tap(find.byIcon(Icons.arrow_upward));
    await tester.pump();
    expect(replied, 'Looks good');
  });

  testWidgets('Resolve is a kit target at least 24px tall, with no ink', (
    tester,
  ) async {
    var resolved = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CommentsButton(
              count: _messages.length,
              messages: _messages,
              onResolve: () => resolved++,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.mode_comment_outlined));
    await tester.pumpAndSettle();

    final resolve = find.text('Resolve');
    final target = find
        .ancestor(of: resolve, matching: find.byType(GestureDetector))
        .first;
    final box = tester.getSize(target);
    expect(box.height, greaterThanOrEqualTo(24));
    expect(box.width, greaterThanOrEqualTo(24));
    expect(
      find.ancestor(of: resolve, matching: find.byType(InkWell)),
      findsNothing,
    );
    await expectLater(
      tester,
      meetsGuideline(
        const MinimumTapTargetGuideline(
          size: Size(24, 24),
          link:
              'https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum',
        ),
      ),
    );

    await tester.tap(resolve);
    expect(resolved, 1);

    // Reached from the keyboard, it shows the kit's focus ring and resolves
    // on Enter.
    Focus.of(tester.element(resolve)).requestFocus();
    await tester.pump();
    expect(
      find.ancestor(of: resolve, matching: find.byType(FocusRing)),
      findsOneWidget,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(resolved, 2);
  });
}
