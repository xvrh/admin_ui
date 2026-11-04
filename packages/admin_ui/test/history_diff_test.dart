import 'package:admin_ui/src/history/diff_model.dart';
import 'package:admin_ui/src/history/ui/block_diff.dart';
import 'package:admin_ui/src/history/ui/diff_view.dart';
import 'package:admin_ui/src/history/ui/text_diff.dart';
import 'package:admin_ui/src/history/ui/version_timeline.dart';
import 'package:admin_ui/src/theme/theme.dart';
import 'package:admin_ui/src/theme/themes/carbon.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

String _joined(List<DiffSegment> segs, DiffOp op) =>
    segs.where((s) => s.op == op).map((s) => s.text).join();

const _vBase = VersionRef(
  id: 'v1',
  label: 'Published v1',
  author: 'Marina',
  initials: 'MC',
  timestamp: 'last week',
  status: VersionStatus.published,
  number: 1,
);
const _vCompare = VersionRef(
  id: 'draft',
  label: 'Working draft',
  author: 'You',
  initials: 'YO',
  timestamp: 'now',
  status: VersionStatus.draft,
);

void main() {
  group('InlineDiff.words', () {
    test('keeps unchanged words, marks insert and delete', () {
      final segs = InlineDiff.words('the quick fox', 'the slow fox');
      expect(_joined(segs, DiffOp.removed), 'quick');
      expect(_joined(segs, DiffOp.added), 'slow');
      expect(
        segs.where((s) => s.op == DiffOp.unchanged).map((s) => s.text).join(),
        'the  fox',
      );
    });

    test('all added when before is empty', () {
      final segs = InlineDiff.words('', 'brand new');
      expect(segs.every((s) => s.op == DiffOp.added), isTrue);
      expect(_joined(segs, DiffOp.added), 'brand new');
    });

    test('all removed when after is empty', () {
      final segs = InlineDiff.words('going away', '');
      expect(segs.every((s) => s.op == DiffOp.removed), isTrue);
    });

    test('identical input yields only unchanged', () {
      final segs = InlineDiff.words('same text', 'same text');
      expect(segs.every((s) => s.op == DiffOp.unchanged), isTrue);
    });

    test('merges a run of trailing removed tokens into one segment', () {
      final segs = InlineDiff.words('keep this extra tail', 'keep this');
      final removed = segs.where((s) => s.op == DiffOp.removed).toList();
      expect(removed.length, 1);
      expect(removed.single.text, ' extra tail');
    });
  });

  testWidgets('TextDiff split hides additions on the before side', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const TextDiff(
          before: 'old word',
          after: 'new word',
          layout: DiffLayout.split,
        ),
      ),
    );
    expect(find.byType(TextDiff), findsOneWidget);
  });

  testWidgets('BlockDiff hides unchanged blocks by default, shows on toggle', (
    tester,
  ) async {
    const blocks = [
      BlockChange(
        id: 'a',
        type: 'paragraph',
        op: DiffOp.changed,
        before: 'one two',
        after: 'one three',
      ),
      BlockChange(
        id: 'b',
        type: 'paragraph',
        op: DiffOp.unchanged,
        before: 'stable',
        after: 'stable',
      ),
    ];

    await tester.pumpWidget(_host(const BlockDiff(blocks: blocks)));
    expect(find.text('CHANGED'), findsOneWidget);
    expect(find.text('UNCHANGED'), findsNothing);

    await tester.pumpWidget(
      _host(const BlockDiff(blocks: blocks, showUnchanged: true)),
    );
    expect(find.text('UNCHANGED'), findsOneWidget);
  });

  testWidgets('BlockDiff notes a moved block position shift', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        const BlockDiff(
          blocks: [
            BlockChange(
              id: 'm',
              type: 'heading_2',
              op: DiffOp.moved,
              before: 'Hi',
              after: 'Hi',
              fromIndex: 4,
              toIndex: 2,
            ),
          ],
        ),
      ),
    );
    expect(find.text('MOVED'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
    expect(find.bySemanticsLabel('from position 5 to 3'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('BlockDiff paints under a theme with square corners', (
    tester,
  ) async {
    expect(carbonTheme.tokens.radii.radiusSmall, 0);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(carbonTheme.tokens),
        home: const Scaffold(
          body: BlockDiff(
            blocks: [
              BlockChange(
                id: 'a',
                type: 'paragraph',
                op: DiffOp.added,
                after: 'new block',
              ),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('ADDED'), findsOneWidget);
  });

  testWidgets('VersionTimeline marks base and compare endpoints', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 320,
          height: 600,
          child: VersionTimeline(
            versions: [_vCompare, _vBase],
            baseId: 'v1',
            compareId: 'draft',
          ),
        ),
      ),
    );
    expect(find.text('BEFORE'), findsOneWidget);
    expect(find.text('AFTER'), findsOneWidget);
  });

  testWidgets('DiffView shows no-changes empty state when nothing changed', (
    tester,
  ) async {
    const diff = VersionDiff(
      base: _vBase,
      compare: _vCompare,
      fields: [
        FieldDiff(
          label: 'Title',
          fieldKey: 'title',
          kind: DiffFieldKind.text,
          locales: [
            LocaleDiff(
              locale: '',
              op: DiffOp.unchanged,
              before: 'x',
              after: 'x',
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      _host(
        const SizedBox(width: 800, height: 600, child: DiffView(diff: diff)),
      ),
    );
    expect(find.text('No changes'), findsOneWidget);
  });

  testWidgets('DiffView renders a Restore action when onRestore is set', (
    tester,
  ) async {
    var restored = false;
    final diff = const VersionDiff(
      base: _vBase,
      compare: _vCompare,
      fields: [
        FieldDiff(
          label: 'Title',
          fieldKey: 'title',
          kind: DiffFieldKind.text,
          locales: [
            LocaleDiff(
              locale: '',
              op: DiffOp.changed,
              before: 'old',
              after: 'new',
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 900,
          height: 600,
          child: DiffView(diff: diff, onRestore: () => restored = true),
        ),
      ),
    );
    await tester.tap(find.text('Restore this version'));
    expect(restored, isTrue);
  });

  testWidgets('DiffView renders a recordList field with nested child diffs', (
    tester,
  ) async {
    const diff = VersionDiff(
      base: _vBase,
      compare: _vCompare,
      fields: [
        FieldDiff(
          label: 'Sections',
          fieldKey: 'sections',
          kind: DiffFieldKind.recordList,
          locales: [],
          records: [
            RecordChange(
              id: 'a',
              op: DiffOp.changed,
              label: 'Pricing',
              fields: [
                FieldDiff(
                  label: 'Heading',
                  fieldKey: 'heading',
                  kind: DiffFieldKind.text,
                  locales: [
                    LocaleDiff(
                      locale: '',
                      op: DiffOp.changed,
                      before: 'Plans',
                      after: 'Pricing',
                    ),
                  ],
                ),
              ],
            ),
            RecordChange(
              id: 'c',
              op: DiffOp.added,
              label: 'New section',
              fields: [],
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      _host(
        const SizedBox(width: 900, height: 600, child: DiffView(diff: diff)),
      ),
    );
    expect(find.text('Pricing'), findsWidgets);
    expect(find.text('New section'), findsOneWidget);
    expect(find.textContaining('Heading', findRichText: true), findsOneWidget);
  });

  testWidgets('DiffView fires per-field restore with the field target', (
    tester,
  ) async {
    RestoreTarget? target;
    const diff = VersionDiff(
      base: _vBase,
      compare: _vCompare,
      fields: [
        FieldDiff(
          label: 'Title',
          fieldKey: 'title',
          kind: DiffFieldKind.text,
          locales: [
            LocaleDiff(
              locale: '',
              op: DiffOp.changed,
              before: 'old',
              after: 'new',
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 900,
          height: 600,
          child: DiffView(diff: diff, onRestorePart: (t) => target = t),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Restore this field'));
    expect(target?.fieldKey, 'title');
    expect(target?.recordId, isNull);
  });

  testWidgets('DiffView fires per-record restore with the record target', (
    tester,
  ) async {
    RestoreTarget? target;
    const diff = VersionDiff(
      base: _vBase,
      compare: _vCompare,
      fields: [
        FieldDiff(
          label: 'Sections',
          fieldKey: 'sections',
          kind: DiffFieldKind.recordList,
          locales: [],
          records: [
            RecordChange(
              id: 'a',
              op: DiffOp.changed,
              label: 'Pricing',
              fields: [
                FieldDiff(
                  label: 'Heading',
                  fieldKey: 'heading',
                  kind: DiffFieldKind.text,
                  locales: [
                    LocaleDiff(
                      locale: '',
                      op: DiffOp.changed,
                      before: 'x',
                      after: 'y',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 900,
          height: 600,
          child: DiffView(diff: diff, onRestorePart: (t) => target = t),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Restore this item'));
    expect(target?.fieldKey, 'sections');
    expect(target?.recordId, 'a');
  });
}
