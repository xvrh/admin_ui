import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 600, child: child),
    ),
  ),
);

/// Whether keyboard focus sits on the control showing [text].
bool _focused(WidgetTester tester, Finder text) {
  final focus = FocusManager.instance.primaryFocus?.context;
  if (focus == null) return false;
  var found = false;
  tester.element(text).visitAncestorElements((e) {
    found = e == focus;
    return !found;
  });
  return found;
}

/// The node a [Tappable] around [text] announces as.
SemanticsNode _node(WidgetTester tester, Finder text) => tester.getSemantics(
  find.descendant(
    of: find.ancestor(of: text, matching: find.byType(Tappable)).first,
    matching: find.byType(GestureDetector),
  ),
);

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

void main() {
  group('Accordion', () {
    const sections = [
      AccordionSection(title: 'One', child: Text('body one')),
      AccordionSection(title: 'Two', child: Text('body two')),
      AccordionSection(title: 'Three', child: Text('body three')),
    ];

    testWidgets('Enter toggles a header, announced with its expanded state', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const Accordion(sections: sections)));
      expect(
        _node(tester, find.text('One')),
        isSemantics(
          label: 'One',
          isButton: true,
          isFocusable: true,
          hasExpandedState: true,
          isExpanded: false,
        ),
      );

      await _key(tester, LogicalKeyboardKey.tab);
      expect(_focused(tester, find.text('One')), isTrue);
      await _key(tester, LogicalKeyboardKey.enter);
      expect(find.text('body one'), findsOneWidget);
      expect(
        _node(tester, find.text('One')),
        isSemantics(hasExpandedState: true, isExpanded: true),
      );
      await _key(tester, LogicalKeyboardKey.space);
      expect(find.text('body one'), findsNothing);
      handle.dispose();
    });

    testWidgets('arrows, Home and End move between headers', (tester) async {
      await tester.pumpWidget(_host(const Accordion(sections: sections)));
      await _key(tester, LogicalKeyboardKey.tab);
      expect(_focused(tester, find.text('One')), isTrue);

      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_focused(tester, find.text('Two')), isTrue);
      await _key(tester, LogicalKeyboardKey.end);
      expect(_focused(tester, find.text('Three')), isTrue);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_focused(tester, find.text('One')), isTrue, reason: 'wraps');
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(_focused(tester, find.text('Three')), isTrue, reason: 'wraps');
      await _key(tester, LogicalKeyboardKey.home);
      expect(_focused(tester, find.text('One')), isTrue);
      // Moving focus opens nothing.
      expect(find.text('body one'), findsNothing);
    });

    testWidgets('each header is its own Tab stop', (tester) async {
      await tester.pumpWidget(_host(const Accordion(sections: sections)));
      await _key(tester, LogicalKeyboardKey.tab);
      await _key(tester, LogicalKeyboardKey.tab);
      expect(_focused(tester, find.text('Two')), isTrue);
    });

    testWidgets('the header hover fill is clipped to the rounded surface', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const Accordion(sections: sections)));
      final clip = find.ancestor(
        of: find.text('One'),
        matching: find.byType(ClipRRect),
      );
      expect(clip, findsOneWidget);
      expect(
        tester.widget<ClipRRect>(clip).borderRadius,
        BorderRadius.circular(defaultTokens.radii.radiusLarge),
      );
    });
  });

  group('Pagination', () {
    testWidgets('pages are labelled Tab stops, the current one selected', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final picked = <int>[];
      await tester.pumpWidget(
        _host(Pagination(page: 2, pageCount: 5, onChanged: picked.add)),
      );

      expect(
        _node(tester, find.text('2')),
        isSemantics(
          label: 'Page 2',
          isButton: true,
          isSelected: true,
          isFocusable: true,
        ),
      );
      expect(
        _node(tester, find.text('4')),
        isSemantics(label: 'Page 4', isSelected: false, isFocusable: true),
      );
      expect(find.bySemanticsLabel('Previous page'), findsOneWidget);
      expect(find.bySemanticsLabel('Next page'), findsOneWidget);

      await _key(tester, LogicalKeyboardKey.tab); // Previous page
      await _key(tester, LogicalKeyboardKey.tab);
      expect(_focused(tester, find.text('1')), isTrue);
      await _key(tester, LogicalKeyboardKey.tab);
      await _key(tester, LogicalKeyboardKey.tab);
      expect(_focused(tester, find.text('3')), isTrue);
      await _key(tester, LogicalKeyboardKey.enter);
      expect(picked, [3]);
      handle.dispose();
    });

    testWidgets('a disabled arrow is no Tab stop', (tester) async {
      await tester.pumpWidget(
        _host(Pagination(page: 1, pageCount: 3, onChanged: (_) {})),
      );
      await _key(tester, LogicalKeyboardKey.tab);
      expect(_focused(tester, find.text('1')), isTrue);
    });
  });

  group('Pager', () {
    testWidgets('arrows are labelled Tab stops', (tester) async {
      final handle = tester.ensureSemantics();
      var next = 0, prev = 0;
      await tester.pumpWidget(
        _host(
          Pager(
            from: 11,
            to: 20,
            total: 42,
            hasPrev: true,
            hasNext: true,
            onPrev: () => prev++,
            onNext: () => next++,
          ),
        ),
      );
      expect(find.bySemanticsLabel('Previous page'), findsOneWidget);
      expect(find.bySemanticsLabel('Next page'), findsOneWidget);

      await _key(tester, LogicalKeyboardKey.tab);
      await _key(tester, LogicalKeyboardKey.enter);
      await _key(tester, LogicalKeyboardKey.tab);
      await _key(tester, LogicalKeyboardKey.space);
      expect((prev, next), (1, 1));
      handle.dispose();
    });
  });

  group('Steps', () {
    const steps = [StepItem('One'), StepItem('Two'), StepItem('Three')];

    testWidgets('a reachable step is a labelled button; a later one is not', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final tapped = <int>[];
      await tester.pumpWidget(
        _host(Steps(steps: steps, current: 1, onChanged: tapped.add)),
      );
      expect(
        find.bySemanticsLabel('Step 1 of 3: One, completed'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Step 2 of 3: Two, current'),
        findsOneWidget,
      );

      await _key(tester, LogicalKeyboardKey.tab);
      expect(_focused(tester, find.text('One')), isTrue);
      await _key(tester, LogicalKeyboardKey.enter);
      expect(tapped, [0]);
      await _key(tester, LogicalKeyboardKey.tab);
      expect(_focused(tester, find.text('Two')), isTrue);
      await _key(tester, LogicalKeyboardKey.tab);
      expect(_focused(tester, find.text('Three')), isFalse);
      handle.dispose();
    });

    testWidgets('a static indicator has no Tab stops', (tester) async {
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              const Steps(steps: steps, current: 1),
              Button('After', onPressed: () {}),
            ],
          ),
        ),
      );
      await _key(tester, LogicalKeyboardKey.tab);
      expect(_focused(tester, find.text('After')), isTrue);
    });
  });

  group('JsonView', () {
    testWidgets('a fold row is a Tab stop announcing its expanded state', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const JsonView(
            showToolbar: false,
            data: {
              'user': {'name': 'Ada'},
            },
          ),
        ),
      );
      final user = find.textContaining('"user"');
      expect(
        _node(tester, user),
        isSemantics(hasExpandedState: true, isExpanded: true, isButton: true),
      );
      expect(find.textContaining('"Ada"'), findsOneWidget);

      await _key(tester, LogicalKeyboardKey.tab); // the root line
      await _key(tester, LogicalKeyboardKey.tab);
      expect(_focused(tester, user), isTrue);
      await _key(tester, LogicalKeyboardKey.enter);
      expect(find.textContaining('"Ada"'), findsNothing);
      expect(
        _node(tester, user),
        isSemantics(hasExpandedState: true, isExpanded: false),
      );

      // The root's closing brace folds by pointer only.
      await _key(tester, LogicalKeyboardKey.tab);
      expect(FocusManager.instance.primaryFocus?.context, isNot(isNull));
      expect(_focused(tester, find.text('}')), isFalse);
      handle.dispose();
    });

    testWidgets('Expand all and Collapse all are labelled actions', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const JsonView(
            data: {
              'a': {'b': 1},
            },
          ),
        ),
      );
      expect(find.bySemanticsLabel('Expand all'), findsOneWidget);
      expect(find.bySemanticsLabel('Collapse all'), findsOneWidget);
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is IconAction && w.label == 'Collapse all',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('"b"'), findsNothing);
      handle.dispose();
    });
  });

  group('UploadZone', () {
    testWidgets('row actions are named for what they do', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          UploadZone(
            items: const [
              UploadItem(id: 'a', name: 'a.jpg', status: UploadStatus.done),
              UploadItem(
                id: 'b',
                name: 'b.jpg',
                status: UploadStatus.uploading,
                progress: 0.4,
              ),
              UploadItem(id: 'c', name: 'c.jpg', status: UploadStatus.error),
            ],
            onCancel: (_) {},
            onRetry: (_) {},
            onRemove: (_) {},
          ),
        ),
      );
      expect(find.bySemanticsLabel('Remove file'), findsNWidgets(2));
      expect(find.bySemanticsLabel('Cancel upload'), findsOneWidget);
      expect(find.bySemanticsLabel('Retry upload'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('an action the host did not wire is not shown', (tester) async {
      await tester.pumpWidget(
        _host(
          UploadZone(
            items: const [
              UploadItem(
                id: 'b',
                name: 'b.jpg',
                status: UploadStatus.uploading,
                progress: 0.4,
              ),
              UploadItem(id: 'c', name: 'c.jpg', status: UploadStatus.error),
            ],
            onRemove: (_) {},
          ),
        ),
      );
      expect(find.byType(IconAction), findsOneWidget);
    });

    testWidgets('the drop target is a Tab stop that Enter browses from', (
      tester,
    ) async {
      var browsed = 0;
      await tester.pumpWidget(_host(UploadZone(onBrowse: () => browsed++)));
      await _key(tester, LogicalKeyboardKey.tab);
      expect(
        _focused(tester, find.byIcon(Icons.cloud_upload_outlined)),
        isTrue,
      );
      await _key(tester, LogicalKeyboardKey.enter);
      expect(browsed, 1);
    });
  });

  group('Attention tiles', () {
    testWidgets('attention tiles and stat cards take focus', (tester) async {
      final handle = tester.ensureSemantics();
      final hits = <String>[];
      await tester.pumpWidget(
        _host(
          SingleChildScrollView(
            child: Column(
              children: [
                AttentionGrid(
                  items: [
                    AttentionItem(
                      label: 'drafts to publish',
                      count: 7,
                      icon: Icons.edit_note_rounded,
                      caption: 'across pages',
                      onTap: () => hits.add('attention'),
                    ),
                  ],
                ),
                StatGrid(
                  children: [
                    StatCard(
                      label: 'Pages',
                      value: '48',
                      delta: const StatDelta('4%'),
                      onTap: () => hits.add('stat'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(
        find.bySemanticsLabel('7 drafts to publish, across pages'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Pages: 48, up 4%'), findsOneWidget);

      for (var i = 0; i < 2; i++) {
        await _key(tester, LogicalKeyboardKey.tab);
        await _key(tester, LogicalKeyboardKey.enter);
      }
      expect(hits, ['attention', 'stat']);
      handle.dispose();
    });
  });
}
