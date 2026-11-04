import 'package:admin_ui/src/common/ui/button.dart';
import 'package:admin_ui/src/history/diff_model.dart';
import 'package:admin_ui/src/history/ui/diff_view.dart';
import 'package:admin_ui/src/history/ui/text_diff.dart';
import 'package:admin_ui/src/history/ui/version_timeline.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

const _base = VersionRef(
  id: 'v1',
  label: 'Trimmed intro, added a call to action',
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

LocaleDiff _lane(String locale) => LocaleDiff(
  locale: locale,
  op: DiffOp.added,
  before: '',
  after: 'Hi $locale',
);

/// The lane body [code] shows, found through its rich text.
Finder _laneText(String code) =>
    find.textContaining('Hi $code', findRichText: true);

VersionDiff _diff(List<String> locales) => VersionDiff(
  base: _base,
  compare: _draft,
  locales: locales,
  fields: [
    FieldDiff(
      label: 'Title',
      fieldKey: 'title',
      kind: DiffFieldKind.text,
      translatable: true,
      locales: [for (final code in locales) _lane(code)],
    ),
  ],
);

/// Whether any text the view lays out was cut short by its line limit.
bool _anyTruncated(WidgetTester tester) {
  for (final element in find.byType(RichText).evaluate()) {
    final paragraph = element.renderObject! as RenderParagraph;
    if (paragraph.didExceedMaxLines) return true;
  }
  return false;
}

void main() {
  group('locale resync', () {
    testWidgets('a locale new to the diff shows; a vanished one drops', (
      tester,
    ) async {
      final diff = ValueNotifier(_diff(['en', 'fr']));
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 900,
            height: 700,
            child: ValueListenableBuilder(
              valueListenable: diff,
              builder: (_, d, _) => DiffView(diff: d),
            ),
          ),
        ),
      );
      expect(_laneText('en'), findsOneWidget);
      expect(_laneText('fr'), findsOneWidget);

      // Hiding FR survives a new diff that still has it.
      await tester.tap(find.text('FR').first);
      await tester.pump();
      expect(_laneText('fr'), findsNothing);

      diff.value = _diff(['en', 'fr', 'nl']);
      await tester.pump();
      expect(_laneText('en'), findsOneWidget);
      expect(_laneText('fr'), findsNothing, reason: 'still hidden');
      expect(_laneText('nl'), findsOneWidget, reason: 'new, so shown');

      diff.value = _diff(['nl', 'de']);
      await tester.pump();
      expect(_laneText('nl'), findsOneWidget);
      expect(_laneText('de'), findsOneWidget);
    });

    testWidgets('a diff sharing no locale with the filter shows them all', (
      tester,
    ) async {
      final diff = ValueNotifier(_diff(['en', 'fr']));
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 900,
            height: 700,
            child: ValueListenableBuilder(
              valueListenable: diff,
              builder: (_, d, _) => DiffView(diff: d),
            ),
          ),
        ),
      );
      await tester.tap(find.text('FR').first);
      await tester.pump();

      diff.value = _diff(['fr', 'de']);
      await tester.pump();
      expect(_laneText('fr'), findsNothing, reason: 'the reader hid FR');
      expect(_laneText('de'), findsOneWidget);
    });
  });

  group('semantics', () {
    testWidgets('each deleted and inserted run is announced with its op', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const TextDiff(
            before: 'Build faster with Acme',
            after: 'Ship faster with Acme Cloud',
          ),
        ),
      );
      final label = tester.getSemantics(find.byType(RichText)).label;
      expect(label, contains('deleted: Build'));
      expect(label, contains('inserted: Ship'));
      expect(label, contains('inserted: Cloud'));
      expect(label, contains('faster with Acme'));
      handle.dispose();
    });

    testWidgets('split columns are named Before and After', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const TextDiff(
            before: 'old word',
            after: 'new word',
            layout: DiffLayout.split,
          ),
        ),
      );
      expect(
        find.bySemanticsLabel(RegExp(r'^Before\ndeleted: old')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'^After\ninserted: new')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('count chips read as one summary', (tester) async {
      final handle = tester.ensureSemantics();
      const diff = VersionDiff(
        base: _base,
        compare: _draft,
        fields: [
          FieldDiff(
            label: 'Sections',
            fieldKey: 'sections',
            kind: DiffFieldKind.recordList,
            locales: [],
            records: [
              RecordChange(id: 'a', op: DiffOp.added, label: 'A', fields: []),
              RecordChange(id: 'b', op: DiffOp.changed, label: 'B', fields: []),
              RecordChange(id: 'c', op: DiffOp.changed, label: 'C', fields: []),
            ],
          ),
        ],
      );
      await tester.pumpWidget(
        _host(
          const SizedBox(width: 900, height: 700, child: DiffView(diff: diff)),
        ),
      );
      expect(find.bySemanticsLabel('1 added, 2 changed'), findsOneWidget);
      handle.dispose();
    });
  });

  group('compact header', () {
    testWidgets(
      'at side-sheet width Restore is an icon and nothing truncates',
      (tester) async {
        var restored = false;
        await tester.pumpWidget(
          _host(
            Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 488,
                height: 700,
                child: DiffView(
                  diff: _diff(['en']),
                  onRestore: () => restored = true,
                ),
              ),
            ),
          ),
        );

        expect(find.text('Restore this version'), findsNothing);
        // material_ui's Tooltip is not the one flutter_test's byTooltip knows.
        final restore = find.byWidgetPredicate(
          (w) => w is Tooltip && w.message == 'Restore this version',
        );
        expect(restore, findsOneWidget);
        expect(
          find.widgetWithIcon(Button, Icons.history_rounded),
          findsOneWidget,
        );
        await tester.tap(restore);
        expect(restored, isTrue);

        expect(_anyTruncated(tester), isFalse);
        expect(find.textContaining(_base.label), findsOneWidget);
        // The long label wraps rather than ending in an ellipsis.
        final label = tester.renderObject<RenderParagraph>(
          find.text(_base.label),
        );
        expect(label.size.height, greaterThan(label.text.style!.fontSize! * 2));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('wide, Restore keeps its label', (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 1000,
            height: 700,
            child: DiffView(diff: _diff(['en']), onRestore: () {}),
          ),
        ),
      );
      expect(find.text('Restore this version'), findsOneWidget);
    });

    testWidgets('the controls wrap instead of overflowing at 360px', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 360,
              height: 700,
              child: DiffView(diff: _diff(['en', 'fr', 'nl', 'de'])),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('DE'), findsWidgets);
    });
  });

  group('own surface', () {
    testWidgets('with no Material above, DiffView and VersionTimeline paint '
        'the page and a body text style', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Row(
            children: [
              const SizedBox(
                width: 300,
                child: VersionTimeline(
                  versions: [_draft, _base],
                  baseId: 'v1',
                  compareId: 'draft',
                ),
              ),
              Expanded(child: DiffView(diff: _diff(['en']))),
            ],
          ),
        ),
      );

      for (final text in ['BEFORE', 'Working draft']) {
        final element = tester.element(find.text(text).first);
        expect(
          Material.maybeOf(element)?.color,
          isNotNull,
          reason: '$text sits on a painted surface',
        );
        expect(
          DefaultTextStyle.of(element).style.decoration,
          anyOf(isNull, TextDecoration.none),
          reason: 'no fallback underline under $text',
        );
      }
    });
  });
}
