import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Pumps [child] in a window [width] × [height].
Future<void> _pumpWindow(
  WidgetTester tester,
  Widget child, {
  required double width,
  double height = 480,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(theme: buildAppTheme(defaultTokens), home: child),
  );
}

Widget _shell() => Shell(
  sidebar: Sidebar(
    entries: [
      const NavSection('Content'),
      NavItem(
        'Pages',
        icon: Icons.description_outlined,
        badge: '3',
        selected: true,
        onTap: () {},
      ),
      NavItem('Media', icon: Icons.photo_library_outlined, onTap: () {}),
    ],
  ),
  topBar: TopBar(
    leading: const Text('Acme Admin'),
    search: CommandTrigger(onTap: () {}),
    onSearch: () {},
    actions: [Button.primary('New', icon: Icons.add_rounded, onPressed: () {})],
  ),
  child: PageScaffold(
    title: 'Pages',
    subtitle: 'Manage your Pages',
    scrollable: false,
    actions: [
      Button('Preview', icon: Icons.visibility_outlined, onPressed: () {}),
      Button.primary('Publish', icon: Icons.send_rounded, onPressed: () {}),
    ],
    body: const SizedBox.expand(),
  ),
);

Rect _rect(WidgetTester tester, Finder finder) => tester.getRect(finder);

void main() {
  group('Shell', () {
    for (final width in [500.0, 560.0]) {
      testWidgets('lays out at $width with the search folded to an icon', (
        tester,
      ) async {
        await _pumpWindow(tester, _shell(), width: width);
        expect(tester.takeException(), isNull);
        expect(find.byType(CommandTrigger), findsNothing);
        final search = find.widgetWithIcon(IconAction, Icons.search_rounded);
        expect(search, findsOneWidget);
        expect(tester.getSize(search).height, 36);

        // The header actions wrap under the title rather than squeezing it.
        // At 560 the compact shell gives the page the whole width, where
        // they fit beside it.
        if (width == 500) {
          final title = _rect(tester, find.text('Pages').last);
          final publish = _rect(tester, find.widgetWithText(Button, 'Publish'));
          expect(publish.top, greaterThan(title.bottom));
          expect(title.height, lessThan(40), reason: 'one line of title');
        }
      });
    }

    testWidgets('a wide window keeps the search field and the side gutter', (
      tester,
    ) async {
      await _pumpWindow(tester, _shell(), width: 1100);
      expect(tester.takeException(), isNull);
      final field = _rect(tester, find.byType(CommandTrigger));
      expect(field.width, TopBar.searchMaxWidth);
      final title = _rect(tester, find.text('Pages').last);
      final publish = _rect(tester, find.widgetWithText(Button, 'Publish'));
      expect(publish.top, lessThan(title.bottom), reason: 'one row');
      final content = _rect(tester, find.byType(PageScaffold));
      expect(title.left - content.left, 24);
    });

    testWidgets('the search narrows before it folds', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(defaultTokens),
          home: Center(
            child: SizedBox(
              width: 640,
              child: TopBar(
                leading: const SizedBox(width: 300),
                search: CommandTrigger(onTap: () {}),
                onSearch: () {},
                actions: [Button.primary('New', onPressed: () {})],
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final field = _rect(tester, find.byType(CommandTrigger)).width;
      expect(field, lessThan(TopBar.searchMaxWidth));
      expect(field, greaterThanOrEqualTo(TopBar.searchMinWidth));
    });
  });

  group('PageHeader', () {
    Widget page() => Scaffold(
      body: PageScaffold(
        title: 'Aurora Lamp',
        breadcrumb: const Breadcrumbs([
          Crumb('Products'),
          Crumb('Aurora Lamp'),
        ]),
        actions: [
          IconAction(
            Icons.visibility_outlined,
            label: 'Preview',
            onPressed: () {},
          ),
          Button.ghost('Discard', onPressed: () {}),
          Button.primary('Save', onPressed: () {}),
        ],
        body: const SizedBox(height: 200),
      ),
    );

    testWidgets('at 420 wraps its actions under a whole-word title', (
      tester,
    ) async {
      await _pumpWindow(tester, page(), width: 420, height: 600);
      expect(tester.takeException(), isNull);
      final title = find.text('Aurora Lamp').last;
      final paragraph = tester.renderObject<RenderParagraph>(title);
      expect(
        paragraph.getMaxIntrinsicWidth(double.infinity),
        lessThanOrEqualTo(paragraph.size.width),
        reason: 'the title fits on one line',
      );
      final save = _rect(tester, find.widgetWithText(Button, 'Save'));
      expect(save.top, greaterThan(_rect(tester, title).bottom));
      // The compact gutter; the leading icon action's glyph, not its box,
      // lines up with the title.
      expect(_rect(tester, title).left, 16);
      final preview = find.byType(IconAction);
      expect(
        _rect(
          tester,
          find.descendant(of: preview, matching: find.byType(Icon)),
        ).left,
        16,
      );
      expect(_rect(tester, preview).left, 16 - (36 - 18) / 2);
    });

    testWidgets('the pulled-back action keeps all of its target', (
      tester,
    ) async {
      var previewed = false;
      await _pumpWindow(
        tester,
        Scaffold(
          body: PageHeader(
            'Aurora Lamp',
            actions: [
              IconAction(
                Icons.visibility_outlined,
                label: 'Preview',
                onPressed: () => previewed = true,
              ),
              Button.ghost('Discard', onPressed: () {}),
              Button.primary('Save', onPressed: () {}),
            ],
          ),
        ),
        width: 420,
      );
      final box = _rect(tester, find.byType(IconAction));
      await tester.tapAt(Offset(box.left + 2, box.center.dy));
      expect(previewed, isTrue);
    });

    testWidgets('actions wrapped over several lines all start at the edge', (
      tester,
    ) async {
      await _pumpWindow(
        tester,
        Scaffold(
          body: PageHeader(
            'Aurora Lamp',
            actions: [
              IconAction(
                Icons.visibility_outlined,
                label: 'Preview',
                onPressed: () {},
              ),
              Button('Duplicate', onPressed: () {}),
              Button.ghost('Discard', onPressed: () {}),
              Button.primary('Save', onPressed: () {}),
            ],
          ),
        ),
        width: 260,
      );
      expect(tester.takeException(), isNull);
      final preview = _rect(tester, find.byType(IconAction));
      final save = _rect(tester, find.widgetWithText(Button, 'Save'));
      expect(save.top, greaterThan(preview.top), reason: 'several lines');
      expect(preview.left, 16);
    });

    testWidgets('keeps a long title to two lines beside roomy actions', (
      tester,
    ) async {
      await _pumpWindow(
        tester,
        Scaffold(
          body: PageHeader(
            'A remarkably long page title that would otherwise run on and on '
            'across several lines of the header',
            actions: [Button.primary('Publish', onPressed: () {})],
          ),
        ),
        width: 900,
      );
      expect(tester.takeException(), isNull);
      final title = tester.widget<Text>(find.byType(Text).first);
      expect(title.maxLines, 2);
      expect(title.overflow, TextOverflow.ellipsis);
    });

    testWidgets('mirrors under RTL', (tester) async {
      await _pumpWindow(
        tester,
        Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: PageHeader(
              'Pages',
              actions: [Button.primary('Publish', onPressed: () {})],
            ),
          ),
        ),
        width: 900,
      );
      final title = _rect(tester, find.text('Pages'));
      final publish = _rect(tester, find.widgetWithText(Button, 'Publish'));
      expect(title.right, 900 - 24);
      expect(publish.left, 24);
    });
  });

  group('SaveBar', () {
    Widget bar({List<SaveBarAction> overflow = const []}) => Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SaveBar(
          state: SaveState.unsaved,
          leading: const Text('A long document title for a narrow bar'),
          status: const Tag('Draft'),
          actions: [
            IconAction(
              Icons.history,
              label: 'Version history',
              onPressed: () {},
            ),
          ],
          overflowActions: overflow,
          onDiscard: () {},
          onSave: () {},
          onCommit: () {},
          commitMenu: [SaveBarAction(label: 'Schedule…', onPressed: () {})],
        ),
      ),
    );

    testWidgets('at 480 folds Discard into ⋯ and ellipsises the title', (
      tester,
    ) async {
      var discarded = false;
      await _pumpWindow(
        tester,
        Scaffold(
          body: SaveBar(
            state: SaveState.unsaved,
            leading: const Text('A long document title for a narrow bar'),
            status: const Tag('Draft'),
            actions: [
              IconAction(
                Icons.history,
                label: 'Version history',
                onPressed: () {},
              ),
            ],
            onDiscard: () => discarded = true,
            onSave: () {},
            onCommit: () {},
            commitMenu: [SaveBarAction(label: 'Schedule…', onPressed: () {})],
          ),
        ),
        width: 480,
      );
      expect(tester.takeException(), isNull);
      expect(find.widgetWithText(Button, 'Discard'), findsNothing);
      final title = tester.renderObject<RenderParagraph>(
        find.text('A long document title for a narrow bar'),
      );
      expect(title.didExceedMaxLines, isTrue, reason: 'ellipsised');

      final more = find.widgetWithIcon(IconAction, Icons.more_horiz);
      expect(tester.getSize(more), const Size.square(36));
      await tester.tap(more);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(discarded, isTrue);
    });

    testWidgets('squeezed, the status tag ellipsises inside its pill', (
      tester,
    ) async {
      await _pumpWindow(
        tester,
        Scaffold(
          body: SaveBar(
            state: SaveState.unsaved,
            leading: const Text('Edit page'),
            status: const Tag('Changed'),
            actions: [
              IconAction(
                Icons.history,
                label: 'Version history',
                onPressed: () {},
              ),
            ],
            overflowActions: [
              SaveBarAction(label: 'Duplicate', onPressed: () {}),
            ],
            onCommit: () {},
            commitMenu: [SaveBarAction(label: 'Schedule…', onPressed: () {})],
          ),
        ),
        width: 540,
      );
      expect(tester.takeException(), isNull);
      expect(
        tester
            .renderObject<RenderParagraph>(find.text('Edit page'))
            .didExceedMaxLines,
        isFalse,
        reason: 'the title is whole',
      );
      final label = tester.renderObject<RenderParagraph>(find.text('Changed'));
      expect(label.didExceedMaxLines, isTrue, reason: 'ellipsised');
      final pill = _rect(tester, find.byType(Tag));
      final text = _rect(tester, find.text('Changed'));
      expect(text.right, lessThanOrEqualTo(pill.right - 8));
      expect(find.byType(UnconstrainedBox), findsNothing);
    });

    testWidgets('the status tag gives way before a short title does', (
      tester,
    ) async {
      await _pumpWindow(
        tester,
        Scaffold(
          body: SaveBar(
            state: SaveState.unsaved,
            leading: const Text('Edit page'),
            status: const Tag('Draft'),
            actions: [
              IconAction(
                Icons.history,
                label: 'Version history',
                onPressed: () {},
              ),
            ],
            overflowActions: [
              SaveBarAction(label: 'Duplicate', onPressed: () {}),
            ],
            onCommit: () {},
            commitMenu: [SaveBarAction(label: 'Schedule…', onPressed: () {})],
          ),
        ),
        width: 400,
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(Tag), findsNothing);
      expect(
        tester
            .renderObject<RenderParagraph>(find.text('Edit page'))
            .didExceedMaxLines,
        isFalse,
      );
    });

    testWidgets('too squeezed for a glyph, the status tag steps aside', (
      tester,
    ) async {
      await _pumpWindow(
        tester,
        Scaffold(
          body: SaveBar(
            state: SaveState.unsaved,
            leading: const Text('Edit page'),
            status: const Tag('Draft'),
            overflowActions: [
              SaveBarAction(label: 'Duplicate', onPressed: () {}),
            ],
            onCommit: () {},
          ),
        ),
        width: 320,
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(Tag), findsNothing);
      expect(find.text('Edit page'), findsOneWidget);
    });

    testWidgets('wide, Discard stays a button and the status reads in full', (
      tester,
    ) async {
      await _pumpWindow(tester, bar(), width: 1000);
      expect(tester.takeException(), isNull);
      expect(find.widgetWithText(Button, 'Discard'), findsOneWidget);
      expect(find.widgetWithIcon(IconAction, Icons.more_horiz), findsNothing);
      expect(find.text('Unsaved changes'), findsOneWidget);
    });

    testWidgets('the overflow trigger is a 36px labelled icon action', (
      tester,
    ) async {
      await _pumpWindow(
        tester,
        bar(
          overflow: [SaveBarAction(label: 'Duplicate', onPressed: () {})],
        ),
        width: 1000,
      );
      final more = find.widgetWithIcon(IconAction, Icons.more_horiz);
      expect(tester.getSize(more), const Size.square(36));
      expect(tester.widget<IconAction>(more).label, 'More actions');
      expect(tester.widget<IconAction>(more).expanded, isFalse);
      await tester.tap(more);
      await tester.pumpAndSettle();
      expect(tester.widget<IconAction>(more).expanded, isTrue);
    });
  });

  testWidgets('FormActions overflow is a 36px icon action in a 36px row', (
    tester,
  ) async {
    final form = _Form();
    addTearDown(form.dispose);
    await _pumpWindow(
      tester,
      Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: FormActions(
            controller: form,
            overflowActions: [
              SaveBarAction(label: 'Duplicate', onPressed: () {}),
            ],
          ),
        ),
      ),
      width: 800,
    );
    final more = find.widgetWithIcon(IconAction, Icons.more_horiz);
    expect(tester.getSize(more), const Size.square(36));
    expect(tester.getSize(find.byType(FormActions)).height, 36);
  });
}

class _Form extends FormController {
  @override
  FormStatus get status => FormStatus.dirty;

  @override
  Map<String, String?> get errors => const {};

  @override
  Future<void> submit() async {}

  @override
  void reset() {}
}
