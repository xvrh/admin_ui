import 'package:admin_ui/src/forms/insert_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _entries = [
  InsertPickerEntry(
    id: 'hero',
    label: 'Hero',
    description: 'Big banner',
    icon: Icons.image,
    category: 'Marketing',
    keywords: ['banner'],
  ),
  InsertPickerEntry(
    id: 'cta',
    label: 'CTA band',
    description: 'Strip with a button',
    icon: Icons.campaign,
    category: 'Marketing',
  ),
  InsertPickerEntry(
    id: 'prose',
    label: 'Prose',
    description: 'Rich text',
    icon: Icons.notes,
    category: 'Content',
  ),
];

Widget _host({
  required ValueChanged<InsertPickerEntry> onSelect,
  VoidCallback? onDismiss,
  List<InsertPickerEntry> entries = _entries,
}) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: InsertPicker(
        entries: entries,
        onSelect: onSelect,
        onDismiss: onDismiss,
      ),
    ),
  ),
);

final _withPreview = [
  InsertPickerEntry(
    id: 'hero',
    label: 'Hero',
    icon: Icons.image,
    category: 'Marketing',
    preview: (_) => const Text('LIVE-HERO'),
  ),
  const InsertPickerEntry(
    id: 'prose',
    label: 'Prose',
    icon: Icons.notes,
    category: 'Content',
  ),
];

void main() {
  testWidgets('groups entries under uppercased category headers', (
    tester,
  ) async {
    await tester.pumpWidget(_host(onSelect: (_) {}));
    await tester.pump();

    expect(find.text('MARKETING'), findsOneWidget);
    expect(find.text('CONTENT'), findsOneWidget);
    expect(find.text('Hero'), findsOneWidget);
    expect(find.text('CTA band'), findsOneWidget);
    expect(find.text('Prose'), findsOneWidget);
  });

  testWidgets('typing fuzzy-filters and drops the section headers', (
    tester,
  ) async {
    await tester.pumpWidget(_host(onSelect: (_) {}));
    await tester.enterText(find.byType(TextField), 'prose');
    await tester.pump();

    expect(find.text('Prose'), findsOneWidget);
    expect(find.text('Hero'), findsNothing);
    expect(find.text('CTA band'), findsNothing);
    expect(find.text('MARKETING'), findsNothing);
    expect(find.text('CONTENT'), findsNothing);
  });

  testWidgets('a keyword match surfaces its entry', (tester) async {
    await tester.pumpWidget(_host(onSelect: (_) {}));
    await tester.enterText(find.byType(TextField), 'banner');
    await tester.pump();

    // "banner" is only a keyword of Hero.
    expect(find.text('Hero'), findsOneWidget);
    expect(find.text('Prose'), findsNothing);
  });

  testWidgets('tapping an entry fires onSelect with it', (tester) async {
    InsertPickerEntry? picked;
    await tester.pumpWidget(_host(onSelect: (e) => picked = e));
    await tester.pump();

    await tester.tap(find.text('CTA band'));
    expect(picked?.id, 'cta');
  });

  testWidgets('arrow-down then enter commits the second visible entry', (
    tester,
  ) async {
    InsertPickerEntry? picked;
    await tester.pumpWidget(_host(onSelect: (e) => picked = e));
    await tester.pump(); // let autofocus land on the search field

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);

    // Visible order (empty query) is [hero, cta, prose]; down → index 1.
    expect(picked?.id, 'cta');
  });

  testWidgets(
    'an entry with a preview renders the pane and shows it selected',
    (tester) async {
      await tester.pumpWidget(_host(onSelect: (_) {}, entries: _withPreview));
      await tester.pump();

      // Hero is first → selected → its live preview + PREVIEW header show.
      expect(find.text('LIVE-HERO'), findsOneWidget);
      expect(find.text('PREVIEW'), findsOneWidget);
      // Its row carries the eye affordance somewhere in the tree.
      expect(find.byIcon(Icons.visibility_outlined), findsWidgets);
    },
  );

  testWidgets('selecting a no-preview entry shows the inline-insert hint', (
    tester,
  ) async {
    await tester.pumpWidget(_host(onSelect: (_) {}, entries: _withPreview));
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // → Prose
    await tester.pump();

    expect(find.text('NO PREVIEW'), findsOneWidget);
    expect(find.textContaining('Inserts inline'), findsOneWidget);
    expect(find.text('LIVE-HERO'), findsNothing);
  });

  testWidgets('escape invokes onDismiss', (tester) async {
    var dismissed = false;
    await tester.pumpWidget(
      _host(onSelect: (_) {}, onDismiss: () => dismissed = true),
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(dismissed, isTrue);
  });
}
