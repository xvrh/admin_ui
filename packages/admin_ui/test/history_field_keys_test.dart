// A history view names a field by its label. The field's key, the app's own
// name for it, follows the label only when the view is asked to show it, and
// is what a restore names either way.

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _base = VersionRef(
  id: 'v1',
  label: 'Spring update',
  author: 'Ada Park',
  initials: 'AP',
  timestamp: '2 hours ago',
  status: VersionStatus.published,
);
const _draft = VersionRef(
  id: 'draft',
  label: 'Working draft',
  author: 'You',
  initials: 'YO',
  timestamp: 'just now',
  status: VersionStatus.draft,
);

/// A plain field, a translated one, and a list of records whose one record
/// has a field of its own.
final _diff = VersionDiff.of(
  base: _base,
  compare: _draft,
  fields: [
    FieldDiff.text('metaDescription', 'Meta description', 'Old', 'New'),
    FieldDiff.translated('title', 'Title', {'en': 'Build'}, {'en': 'Ship'}),
    FieldDiff(
      label: 'Sections',
      fieldKey: 'sections',
      kind: DiffFieldKind.recordList,
      locales: const [],
      records: [
        RecordChange(
          id: 's1',
          op: DiffOp.changed,
          label: 'Hero',
          fields: [FieldDiff.text('heading', 'Heading', 'Hello', 'Welcome')],
        ),
      ],
    ),
  ],
);

/// Each card's label and key, the record's own field last.
const _fields = [
  ('Meta description', 'metaDescription'),
  ('Title', 'title'),
  ('Sections', 'sections'),
  ('Heading', 'heading'),
];

Future<void> _pump(
  WidgetTester tester, {
  VersionDiff? diff,
  bool? showFieldKeys,
  Locale locale = const Locale('en'),
  void Function(RestoreTarget target)? onRestorePart,
}) async {
  tester.view.physicalSize = const Size(900, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(irisTheme.tokens),
      locale: locale,
      supportedLocales: AdminLocalizations.supportedLocales,
      localizationsDelegates: AdminLocalizations.localizationsDelegates,
      home: Scaffold(
        body: showFieldKeys == null
            ? DiffView(diff: diff ?? _diff, onRestorePart: onRestorePart)
            : DiffView(
                diff: diff ?? _diff,
                showFieldKeys: showFieldKeys,
                onRestorePart: onRestorePart,
              ),
      ),
    ),
  );
}

/// The one text that reads exactly [text], a card's header among them.
Finder _reads(String text) => find.text(text, findRichText: true);

void main() {
  testWidgets('a card names its field by its label alone', (tester) async {
    await _pump(tester);
    for (final (label, key) in _fields) {
      expect(_reads(label), findsOneWidget, reason: label);
      expect(
        find.textContaining(key, findRichText: true),
        findsNothing,
        reason: 'the key of $label',
      );
    }
  });

  testWidgets('a card is announced by its label, and by its key only when '
      'that is shown', (tester) async {
    final handle = tester.ensureSemantics();
    // A card is one announcement, a line for each of its texts.
    List<String> announced(String header) =>
        tester.getSemantics(_reads(header)).label.split('\n');

    await _pump(tester);
    for (final (label, key) in _fields) {
      final lines = announced(label);
      expect(lines, contains(label));
      expect(lines.where((line) => line.contains(key)), isEmpty, reason: label);
    }

    await _pump(tester, showFieldKeys: true);
    for (final (label, key) in _fields) {
      expect(announced('$label  $key'), contains('$label  $key'));
    }
    handle.dispose();
  });

  testWidgets('showFieldKeys names each key after its label, a record\'s '
      'field included', (tester) async {
    await _pump(tester, showFieldKeys: true);
    for (final (label, key) in _fields) {
      expect(_reads('$label  $key'), findsOneWidget, reason: label);
      expect(_reads(label), findsNothing, reason: label);
    }
  });

  testWidgets('the key is the smaller, muted text', (tester) async {
    await _pump(tester, showFieldKeys: true);
    final context = tester.element(find.byType(DiffView));
    final header = tester.widget<RichText>(_reads('Title  title'));
    final spans = <InlineSpan>[];
    header.text.visitChildren((span) {
      if (span is TextSpan && span.text != null) spans.add(span);
      return true;
    });
    final [label, gap, key] = spans.cast<TextSpan>();
    expect(label.text, 'Title');
    expect(gap.text, '  ');
    expect(key.text, 'title');
    expect(key.style!.fontSize, lessThan(label.style!.fontSize!));
    expect(key.style!.color, context.colors.foregroundMutedOnTint);
  });

  testWidgets('false is the default', (tester) async {
    await _pump(tester, showFieldKeys: false);
    for (final (label, key) in _fields) {
      expect(_reads(label), findsOneWidget, reason: label);
      expect(find.textContaining(key, findRichText: true), findsNothing);
    }
    expect(const DiffView(diff: _empty).showFieldKeys, isFalse);
  });

  testWidgets('a view told to show its keys shows them, and hides them '
      'again', (tester) async {
    await _pump(tester);
    expect(_reads('Title'), findsOneWidget);
    await _pump(tester, showFieldKeys: true);
    expect(_reads('Title  title'), findsOneWidget);
    await _pump(tester, showFieldKeys: false);
    expect(_reads('Title'), findsOneWidget);
  });

  for (final shown in [false, true]) {
    testWidgets('a restore names the field by its key, keys '
        '${shown ? 'shown' : 'hidden'}', (tester) async {
      final targets = <RestoreTarget>[];
      await _pump(tester, showFieldKeys: shown, onRestorePart: targets.add);
      await tester.tap(find.byTooltip('Restore this field').first);
      await tester.tap(find.byTooltip('Restore this item'));
      expect(
        [for (final t in targets) (t.fieldKey, t.recordId)],
        [('metaDescription', null), ('sections', 's1')],
      );
    });
  }

  testWidgets('in a right-to-left page a card reads its label alone', (
    tester,
  ) async {
    await _pump(
      tester,
      locale: const Locale('ar'),
      diff: VersionDiff.of(
        base: _base,
        compare: _draft,
        fields: [FieldDiff.scalar('price', 'السعر', 1200, 1400)],
      ),
    );
    expect(_reads('السعر'), findsOneWidget);
    expect(find.textContaining('price', findRichText: true), findsNothing);
  });
}

const _empty = VersionDiff(base: _base, compare: _draft, fields: []);
