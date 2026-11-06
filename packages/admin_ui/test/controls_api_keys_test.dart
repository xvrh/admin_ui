import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  home: ToastScope(
    child: Scaffold(
      body: Align(alignment: Alignment.topLeft, child: child),
    ),
  ),
);

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(_host(child));
  await tester.pumpAndSettle();
}

/// [bar] across a window [width] wide, so the bar's width picks its tier.
Future<void> _pumpBar(
  WidgetTester tester,
  Widget bar, {
  required double width,
}) async {
  tester.view.physicalSize = Size(width, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(defaultTokens),
      home: Scaffold(body: Column(children: [bar])),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Taps the only widget keyed [key], first checking it is the only one.
Future<void> _tapKey(WidgetTester tester, Key key) async {
  expect(find.byKey(key), findsOneWidget);
  await _tap(tester, find.byKey(key));
}

Widget _menu(List<MenuEntry> entries) => Menu(
  entries: entries,
  builder: (context, c) => Button('Actions', onPressed: c.toggle),
);

Future<void> _openMenu(WidgetTester tester) =>
    _tap(tester, find.text('Actions'));

final _more = find.byIcon(Icons.more_horiz);

class _Form extends FormController {
  var submits = 0;
  var resets = 0;

  @override
  FormStatus get status => FormStatus.dirty;

  @override
  Map<String, String?> get errors => const {};

  @override
  Future<void> submit() async => submits++;

  @override
  void reset() => resets++;
}

/// Walks a three-step wizard forward, back and through its finish by [back]
/// and [next] alone.
Future<void> _wizardByKeys(
  WidgetTester tester, {
  required Key back,
  required Key next,
}) async {
  var submits = 0;
  final form = ValueFormController<int>(
    read: (_) => 0,
    write: (_, _) {},
    onSubmit: (_) async => submits++,
    requireChanges: false,
  );
  addTearDown(form.dispose);
  final steps = <int>[];
  await _pump(
    tester,
    SizedBox(
      width: 800,
      child: FormWizard(
        controller: form,
        steps: [
          for (final title in ['Account', 'Profile', 'Review'])
            FormWizardStep(
              title: title,
              fields: const [],
              builder: (_) => Text('$title body'),
            ),
        ],
        onStepChanged: steps.add,
        finishLabel: 'Create',
        backKey: back,
        nextKey: next,
      ),
    ),
  );
  expect(find.byKey(back), findsNothing);
  await _tapKey(tester, next);
  await _tapKey(tester, back);
  await _tapKey(tester, next);
  await _tapKey(tester, next);
  expect(steps, [1, 0, 1, 2]);
  expect(find.widgetWithText(Button, 'Create'), findsOneWidget);
  await _tapKey(tester, next);
  expect(submits, 1);
}

const _options = [
  SelectOption(value: 'draft', label: 'Draft'),
  SelectOption(key: Key('published'), value: 'published', label: 'Published'),
];

void main() {
  group('items', () {
    testWidgets('a sidebar row is found and opened by its key, in the '
        'collapsed rail too', (tester) async {
      const media = Key('media');
      final opened = <String>[];
      for (final collapsed in [false, true]) {
        await _pump(
          tester,
          Row(
            children: [
              Sidebar(
                collapsed: collapsed,
                entries: [
                  NavItem(
                    'Pages',
                    icon: Icons.description_outlined,
                    onTap: () => opened.add('Pages'),
                  ),
                  NavItem(
                    'Media',
                    key: media,
                    icon: Icons.photo_library_outlined,
                    onTap: () => opened.add('Media'),
                  ),
                ],
              ),
            ],
          ),
        );
        expect(find.text('Media'), collapsed ? findsNothing : findsOneWidget);
        await _tapKey(tester, media);
      }
      expect(opened, ['Media', 'Media']);
    });

    testWidgets('a menu row is found and chosen by its key', (tester) async {
      const rename = Key('rename');
      final chosen = <String>[];
      await _pump(
        tester,
        _menu([
          MenuItem('Duplicate', onSelect: () => chosen.add('Duplicate')),
          MenuItem('Rename', key: rename, onSelect: () => chosen.add('Rename')),
        ]),
      );
      expect(find.byKey(rename), findsNothing);
      await _openMenu(tester);
      await _tapKey(tester, rename);
      expect(chosen, ['Rename']);
      expect(find.text('Duplicate'), findsNothing);
    });

    testWidgets('a menu checkbox row is found and toggled by its key', (
      tester,
    ) async {
      const pinned = Key('pinned');
      final changes = <bool>[];
      await _pump(
        tester,
        _menu([
          MenuCheckboxItem('Archived', checked: false, onChanged: (_) {}),
          MenuCheckboxItem(
            'Pinned',
            key: pinned,
            checked: false,
            onChanged: changes.add,
          ),
        ]),
      );
      await _openMenu(tester);
      await _tapKey(tester, pinned);
      expect(changes, [true]);
    });

    testWidgets('a submenu row is found and opened by its key', (tester) async {
      const moveTo = Key('move to');
      const blog = Key('blog');
      final chosen = <String>[];
      await _pump(
        tester,
        _menu([
          MenuItem('Rename', onSelect: () => chosen.add('Rename')),
          MenuSubmenu(
            'Move to',
            key: moveTo,
            entries: [
              MenuItem('Docs', onSelect: () => chosen.add('Docs')),
              MenuItem('Blog', key: blog, onSelect: () => chosen.add('Blog')),
            ],
          ),
        ]),
      );
      await _openMenu(tester);
      expect(find.byKey(blog), findsNothing);
      await _tapKey(tester, moveTo);
      await _tapKey(tester, blog);
      expect(chosen, ['Blog']);
    });

    testWidgets('a tab is found and selected by its key', (tester) async {
      const pricing = Key('pricing');
      final picked = <int>[];
      await _pump(
        tester,
        SizedBox(
          width: 600,
          child: Tabs(
            tabs: const [
              TabItem('Details'),
              TabItem('Pricing', key: pricing),
              TabItem('SEO'),
            ],
            selected: 0,
            onChanged: picked.add,
          ),
        ),
      );
      await _tapKey(tester, pricing);
      expect(picked, [1]);
    });

    testWidgets('a segment is found and selected by its key', (tester) async {
      const beta = Key('beta');
      final picked = <String>[];
      await _pump(
        tester,
        Segmented<String>(
          segments: const [
            SegmentOption('a', 'Alpha'),
            SegmentOption('b', 'Beta', key: beta),
          ],
          value: 'a',
          onChanged: picked.add,
        ),
      );
      await _tapKey(tester, beta);
      expect(picked, ['b']);
    });

    testWidgets('a choice option is found and selected by its key', (
      tester,
    ) async {
      const beta = Key('beta');
      final picked = <String>[];
      await _pump(
        tester,
        Choice<String>(
          options: const [
            ChoiceOption('a', 'Alpha'),
            ChoiceOption('b', 'Beta', key: beta),
          ],
          value: 'a',
          onChanged: picked.add,
        ),
      );
      await _tapKey(tester, beta);
      expect(picked, ['b']);
    });

    testWidgets('a swatch is found and picked by its key', (tester) async {
      const blue = Key('blue');
      final picked = <String>[];
      await _pump(
        tester,
        SwatchRow<String>(
          options: const [
            SwatchOption('red', Colors.red, 'Red'),
            SwatchOption('blue', Colors.blue, 'Blue', key: blue),
          ],
          value: 'red',
          onChanged: picked.add,
        ),
      );
      await _tapKey(tester, blue);
      expect(picked, ['blue']);
    });

    testWidgets('an accordion header is found and toggled by its key', (
      tester,
    ) async {
      const two = Key('two');
      await _pump(
        tester,
        const SizedBox(
          width: 500,
          child: Accordion(
            sections: [
              AccordionSection(title: 'One', child: Text('body one')),
              AccordionSection(key: two, title: 'Two', child: Text('body two')),
            ],
          ),
        ),
      );
      await _tapKey(tester, two);
      expect(find.text('body two'), findsOneWidget);
      await _tapKey(tester, two);
      expect(find.text('body two'), findsNothing);
    });

    testWidgets('a step is found by its key, and jumped to when it is past', (
      tester,
    ) async {
      const one = Key('one');
      const three = Key('three');
      for (final direction in Axis.values) {
        final picked = <int>[];
        await _pump(
          tester,
          SizedBox(
            width: 500,
            child: Steps(
              steps: const [
                StepItem('One', key: one),
                StepItem('Two'),
                StepItem('Three', key: three),
              ],
              current: 1,
              direction: direction,
              onChanged: picked.add,
            ),
          ),
        );
        await _tapKey(tester, one);
        expect(find.byKey(three), findsOneWidget);
        await tester.tap(find.byKey(three), warnIfMissed: false);
        expect(picked, [0], reason: '$direction');
      }
    });

    testWidgets('a crumb is found and followed by its key, in the menu of a '
        'collapsed trail too', (tester) async {
      const home = Key('home');
      const marketing = Key('marketing');
      final followed = <String>[];
      Crumb crumb(String label, {Key? key}) =>
          Crumb(label, key: key, onTap: () => followed.add(label));
      await _pump(
        tester,
        SizedBox(
          width: 640,
          child: Breadcrumbs([
            crumb('Home', key: home),
            crumb('Workspace'),
            crumb('Marketing', key: marketing),
            crumb('Campaigns'),
            const Crumb('Landing page'),
          ]),
        ),
      );
      await _tapKey(tester, home);
      expect(find.byKey(marketing), findsNothing);
      await _tap(
        tester,
        find.widgetWithIcon(IconAction, Icons.more_horiz_rounded),
      );
      await _tapKey(tester, marketing);
      expect(followed, ['Home', 'Marketing']);
    });

    testWidgets('a bulk action is found and run by its key, folded into the '
        'menu too', (tester) async {
      const keys = [Key('export'), Key('archive'), Key('delete')];
      final ran = <String>[];
      Widget bar(double width) => SizedBox(
        width: width,
        child: BulkActionBar(
          count: 3,
          onClear: () {},
          actions: [
            BulkAction('Export', key: keys[0], onPressed: () => ran.add('0')),
            BulkAction(
              'Archive',
              key: keys[1],
              primary: true,
              onPressed: () => ran.add('1'),
            ),
            BulkAction(
              'Delete',
              key: keys[2],
              danger: true,
              onPressed: () => ran.add('2'),
            ),
          ],
        ),
      );
      await _pump(tester, bar(800));
      for (final key in keys) {
        await _tapKey(tester, key);
      }
      await _pump(tester, bar(240));
      expect(find.text('Export'), findsNothing);
      for (final key in keys) {
        await _tap(tester, _more);
        await _tapKey(tester, key);
      }
      expect(ran, ['0', '1', '2', '0', '1', '2']);
    });

    testWidgets('a save bar action is found and run by its key, in the ⋯ '
        'menu and under the commit', (tester) async {
      const duplicate = Key('duplicate');
      const schedule = Key('schedule');
      final ran = <String>[];
      final bar = SaveBar(
        state: SaveState.unsaved,
        onSave: () {},
        onCommit: () {},
        overflowActions: [
          SaveBarAction(
            key: duplicate,
            label: 'Duplicate',
            onPressed: () => ran.add('duplicate'),
          ),
        ],
        commitMenu: [
          SaveBarAction(
            key: schedule,
            label: 'Schedule…',
            onPressed: () => ran.add('schedule'),
          ),
        ],
      );
      await _pumpBar(tester, bar, width: 900);
      await _tap(tester, _more);
      await _tapKey(tester, duplicate);
      await _tap(tester, find.byIcon(Icons.keyboard_arrow_down_rounded));
      await _tapKey(tester, schedule);
      await _pumpBar(tester, bar, width: 360);
      await _tap(tester, _more);
      await _tapKey(tester, schedule);
      expect(ran, ['duplicate', 'schedule', 'schedule']);
    });

    testWidgets('a combobox option is found and picked by its key', (
      tester,
    ) async {
      const cherry = Key('cherry');
      final picked = <String?>[];
      await _pump(
        tester,
        SizedBox(
          width: 300,
          child: Combobox<String>(
            value: null,
            onChanged: picked.add,
            options: const [
              ComboboxOption('a', 'Apple'),
              ComboboxOption('c', 'Cherry', key: cherry),
            ],
          ),
        ),
      );
      expect(find.byKey(cherry), findsNothing);
      await _tap(tester, find.byType(TextField));
      await _tapKey(tester, cherry);
      expect(picked, ['c']);
    });

    testWidgets('a select option is found and picked by its key, in every '
        'appearance', (tester) async {
      for (final appearance in SelectAppearance.values) {
        final picked = <String>[];
        await _pump(
          tester,
          SizedBox(
            width: 320,
            child: SelectBody(
              options: _options,
              value: 'draft',
              appearance: appearance,
              onChanged: picked.add,
            ),
          ),
        );
        if (appearance == SelectAppearance.dropdown) {
          await _tap(tester, find.byType(FieldTrigger));
        }
        await _tapKey(tester, _options[1].key!);
        expect(picked, ['published'], reason: '$appearance');
      }
    });

    testWidgets('a multi-select option is found and toggled by its key, in '
        'every appearance', (tester) async {
      for (final appearance in MultiSelectAppearance.values) {
        final changes = <Set<String>>[];
        await _pump(
          tester,
          SizedBox(
            width: 320,
            child: MultiSelectBody(
              options: _options,
              value: const {'draft'},
              appearance: appearance,
              onChanged: changes.add,
            ),
          ),
        );
        if (appearance == MultiSelectAppearance.tokens) {
          await _tap(tester, find.byType(FieldTrigger));
        }
        await _tapKey(tester, _options[1].key!);
        expect(changes, [
          {'draft', 'published'},
        ], reason: '$appearance');
      }
    });

    testWidgets('a filter option is found and checked by its key', (
      tester,
    ) async {
      const south = Key('south');
      List<FilterCondition> active = const [];
      await _pump(
        tester,
        StatefulBuilder(
          builder: (context, setState) => FilterBar(
            fields: const [
              OptionsFilterField('zone', 'Zone', [
                FilterOption('north', 'North'),
                FilterOption('south', 'South', key: south),
              ]),
            ],
            active: active,
            onChanged: (next) => setState(() => active = next),
          ),
        ),
      );
      await _tap(tester, find.text('Zone'));
      await _tapKey(tester, south);
      expect(active, [
        isA<OptionsFilter>().having((f) => f.selected, 'selected', {'south'}),
      ]);
    });
  });

  group('own controls', () {
    testWidgets('a confirm dialog resolves by the keys of its buttons', (
      tester,
    ) async {
      const confirm = Key('confirm');
      const cancel = Key('cancel');
      for (final danger in [false, true]) {
        final answers = <bool>[];
        await _pump(
          tester,
          Builder(
            builder: (context) => Button(
              'Open',
              onPressed: () async => answers.add(
                await showConfirmDialog(
                  context,
                  title: 'Delete?',
                  message: 'Gone for good.',
                  danger: danger,
                  confirmKey: confirm,
                  cancelKey: cancel,
                ),
              ),
            ),
          ),
        );
        await _tap(tester, find.text('Open'));
        await _tapKey(tester, cancel);
        await _tap(tester, find.text('Open'));
        await _tapKey(tester, confirm);
        expect(answers, [false, true], reason: 'danger: $danger');
      }
    });

    testWidgets('an error state retries by the key of its button', (
      tester,
    ) async {
      const retry = Key('retry');
      var retries = 0;
      await _pump(
        tester,
        SizedBox(
          width: 400,
          child: ErrorState(
            title: 'Could not load',
            onRetry: () => retries++,
            retryKey: retry,
          ),
        ),
      );
      await _tapKey(tester, retry);
      expect(retries, 1);
    });

    testWidgets('a modal is dismissed by the key of its close button', (
      tester,
    ) async {
      const close = Key('close');
      var dismissed = 0;
      await _pump(
        tester,
        Modal(
          title: 'Rename',
          message: 'x',
          onDismiss: () => dismissed++,
          closeKey: close,
        ),
      );
      await _tapKey(tester, close);
      expect(dismissed, 1);
    });

    testWidgets('a side sheet is closed by the key of its close button', (
      tester,
    ) async {
      const close = Key('close');
      await _pump(
        tester,
        Builder(
          builder: (context) => Button(
            'Open',
            onPressed: () => showSideSheet(
              context,
              builder: (_) => const SideSheet(
                title: 'Sheet',
                closeKey: close,
                child: Text('sheet-body'),
              ),
            ),
          ),
        ),
      );
      await _tap(tester, find.text('Open'));
      await _tapKey(tester, close);
      expect(find.text('sheet-body'), findsNothing);
    });

    testWidgets('a save cluster\'s buttons are found and pressed by their '
        'keys, Discard folded into ⋯ too', (tester) async {
      const save = Key('save');
      const commit = Key('commit');
      const discard = Key('discard');
      final pressed = <String>[];
      Widget cluster({bool compact = false, bool split = false}) => SaveCluster(
        state: SaveState.unsaved,
        onSave: () => pressed.add('save'),
        onCommit: () => pressed.add('commit'),
        onDiscard: () => pressed.add('discard'),
        commitMenu: [
          if (split) const SaveBarAction(label: 'Schedule…', onPressed: _noop),
        ],
        compact: compact,
        saveKey: save,
        commitKey: commit,
        discardKey: discard,
      );
      await _pump(tester, cluster());
      for (final key in [save, commit, discard]) {
        await _tapKey(tester, key);
      }
      await _pump(tester, cluster(split: true));
      expect(tester.widget(find.byKey(commit)), isA<SplitButton>());
      await _tapKey(tester, commit);
      await _pump(tester, cluster(compact: true));
      expect(find.byKey(discard), findsNothing);
      await _tap(tester, _more);
      await _tapKey(tester, discard);
      expect(pressed, ['save', 'commit', 'discard', 'commit', 'discard']);
    });

    testWidgets('a save bar\'s buttons are found and pressed by their keys, '
        'Discard folded into ⋯ too', (tester) async {
      const save = Key('save');
      const commit = Key('commit');
      const discard = Key('discard');
      final pressed = <String>[];
      final bar = SaveBar(
        state: SaveState.unsaved,
        onSave: () => pressed.add('save'),
        onCommit: () => pressed.add('commit'),
        onDiscard: () => pressed.add('discard'),
        saveKey: save,
        commitKey: commit,
        discardKey: discard,
      );
      await _pumpBar(tester, bar, width: 900);
      for (final key in [save, commit, discard]) {
        await _tapKey(tester, key);
      }
      await _pumpBar(tester, bar, width: 608);
      expect(find.byKey(discard), findsNothing);
      await _tap(tester, _more);
      await _tapKey(tester, discard);
      expect(pressed, ['save', 'commit', 'discard', 'discard']);
    });

    testWidgets('a form save bar submits and discards by its keys, Discard '
        'folded into ⋯ too', (tester) async {
      const commit = Key('commit');
      const discard = Key('discard');
      final form = _Form();
      addTearDown(form.dispose);
      final bar = FormSaveBar(
        controller: form,
        showDiscard: true,
        commitKey: commit,
        discardKey: discard,
      );
      await _pumpBar(tester, bar, width: 900);
      await _tapKey(tester, commit);
      await _tapKey(tester, discard);
      await _pumpBar(tester, bar, width: 608);
      await _tap(tester, _more);
      await _tapKey(tester, discard);
      expect((form.submits, form.resets), (1, 2));
    });

    testWidgets('form actions submit and discard by their keys', (
      tester,
    ) async {
      const commit = Key('commit');
      const discard = Key('discard');
      final form = _Form();
      addTearDown(form.dispose);
      await _pump(
        tester,
        FormActions(
          controller: form,
          showDiscard: true,
          commitKey: commit,
          discardKey: discard,
        ),
      );
      await _tapKey(tester, commit);
      await _tapKey(tester, discard);
      expect((form.submits, form.resets), (1, 1));
    });

    testWidgets('a wizard moves and finishes by the keys of Back and Next, '
        'named as an app would name them', (tester) async {
      await _wizardByKeys(
        tester,
        back: const Key('back'),
        next: const Key('next'),
      );
    });

    testWidgets('pagination pages by the keys of its arrows', (tester) async {
      const previous = Key('previous');
      const next = Key('next');
      final picked = <int>[];
      await _pump(
        tester,
        Pagination(
          page: 2,
          pageCount: 5,
          onChanged: picked.add,
          previousKey: previous,
          nextKey: next,
        ),
      );
      await _tapKey(tester, next);
      await _tapKey(tester, previous);
      expect(picked, [3, 1]);
    });

    testWidgets('a pager pages by the keys of its arrows, numbered, narrowed '
        'to the arrows or arrows alone', (tester) async {
      const previous = Key('previous');
      const next = Key('next');
      final paged = <String>[];
      for (final (numbered, width) in [
        (true, 900.0),
        (true, 200.0),
        (false, 900.0),
      ]) {
        await _pump(
          tester,
          SizedBox(
            width: width,
            child: Pager(
              from: 11,
              to: 20,
              total: 50,
              hasPrev: true,
              hasNext: true,
              page: numbered ? 2 : null,
              pageSize: 10,
              onPage: numbered ? (p) => paged.add('$p') : null,
              onPrev: () => paged.add('prev'),
              onNext: () => paged.add('next'),
              previousKey: previous,
              nextKey: next,
            ),
          ),
        );
        expect(
          find.text('3'),
          numbered && width > 200 ? findsOneWidget : findsNothing,
        );
        await _tapKey(tester, next);
        await _tapKey(tester, previous);
      }
      expect(paged, ['3', '1', '3', '1', 'next', 'prev']);
    });

    testWidgets('a collection pages by the keys of its pager\'s arrows', (
      tester,
    ) async {
      const previous = Key('previous');
      const next = Key('next');
      final c = CollectionController<int>(
        rowKey: (r) => r,
        searchDebounce: Duration.zero,
        initialQuery: const CollectionQuery(pageSize: 10),
        fetcher: (q) async => CollectionPage(
          items: [for (var i = 0; i < 10; i++) q.pageIndex * 10 + i],
          total: 30,
        ),
      );
      addTearDown(c.dispose);
      await _pump(
        tester,
        SizedBox(
          width: 900,
          height: 600,
          child: Collection<int>(
            controller: c,
            columns: [TableColumn<int>(label: 'Row', cell: (r) => Text('$r'))],
            previousPageKey: previous,
            nextPageKey: next,
          ),
        ),
      );
      await _tapKey(tester, next);
      expect(c.pageIndex, 1);
      await _tapKey(tester, previous);
      expect(c.pageIndex, 0);
    });

    testWidgets('a toast\'s action is found and run by its key', (
      tester,
    ) async {
      const undo = Key('undo');
      var undone = 0;
      await _pump(
        tester,
        Builder(
          builder: (context) => Button(
            'Delete',
            onPressed: () => ToastScope.of(context).show(
              Toast(
                'Deleted.',
                actionLabel: 'Undo',
                onAction: () => undone++,
                actionKey: undo,
              ),
            ),
          ),
        ),
      );
      await _tap(tester, find.text('Delete'));
      await _tapKey(tester, undo);
      expect(undone, 1);
      expect(find.text('Deleted.'), findsNothing);
    });

    Future<void> clearBulkByKey(WidgetTester tester, double width) async {
      const clear = Key('clear');
      var cleared = 0;
      await _pump(
        tester,
        SizedBox(
          width: width,
          child: BulkActionBar(
            count: 3,
            onClear: () => cleared++,
            actions: const [],
            clearKey: clear,
          ),
        ),
      );
      await _tapKey(tester, clear);
      expect(cleared, 1);
    }

    testWidgets('a narrow bulk action bar clears by the key of its icon', (
      tester,
    ) async {
      await clearBulkByKey(tester, 240);
      expect(find.text('Clear'), findsNothing);
    });

    testWidgets('a full-width bulk action bar clears by the key of its Clear '
        'button', (tester) async {
      await clearBulkByKey(tester, 800);
      expect(find.text('Clear'), findsOneWidget);
    });

    testWidgets('a search field clears by the key of its clear button', (
      tester,
    ) async {
      const clear = Key('clear');
      final changes = <String>[];
      await _pump(
        tester,
        SearchField(width: 240, onChanged: changes.add, clearKey: clear),
      );
      expect(find.byKey(clear), findsNothing);
      await tester.enterText(find.byType(TextField), 'lamp');
      await tester.pump();
      await _tapKey(tester, clear);
      expect(changes.last, '');
      expect(find.byKey(clear), findsNothing);
    });

    testWidgets('a sign-in form is filled and submitted by its keys, and its '
        'forgot link followed', (tester) async {
      const email = Key('email');
      const password = Key('password');
      const submit = Key('submit');
      const forgot = Key('forgot');
      final signIns = <(String, String)>[];
      var forgotten = 0;
      await _pump(
        tester,
        SizedBox(
          width: 360,
          child: SignInForm(
            onSignIn: (e, p) => signIns.add((e, p)),
            onForgotPassword: () => forgotten++,
            emailKey: email,
            passwordKey: password,
            submitKey: submit,
            forgotKey: forgot,
          ),
        ),
      );
      await tester.enterText(find.byKey(email), 'me@acme.com');
      await tester.enterText(find.byKey(password), 'hunter2');
      await _tapKey(tester, submit);
      await _tapKey(tester, forgot);
      expect(signIns, [('me@acme.com', 'hunter2')]);
      expect(forgotten, 1);
    });

    testWidgets('a set-password form is filled and submitted by its keys', (
      tester,
    ) async {
      const newKey = Key('new');
      const confirm = Key('confirm');
      const submit = Key('submit');
      final submitted = <String>[];
      await _pump(
        tester,
        SizedBox(
          width: 360,
          child: SetPasswordForm(
            onSubmit: submitted.add,
            newKey: newKey,
            confirmKey: confirm,
            submitKey: submit,
          ),
        ),
      );
      await tester.enterText(find.byKey(newKey), 'longenough1');
      await tester.enterText(find.byKey(confirm), 'longenough1');
      await _tapKey(tester, submit);
      expect(submitted, ['longenough1']);
    });

    testWidgets('a change-password form is filled and submitted by its keys', (
      tester,
    ) async {
      const current = Key('current');
      const newKey = Key('new');
      const confirm = Key('confirm');
      const submit = Key('submit');
      final submitted = <(String, String)>[];
      await _pump(
        tester,
        SizedBox(
          width: 360,
          child: ChangePasswordForm(
            onSubmit: (c, n) => submitted.add((c, n)),
            currentKey: current,
            newKey: newKey,
            confirmKey: confirm,
            submitKey: submit,
          ),
        ),
      );
      await tester.enterText(find.byKey(current), 'oldpass00');
      await tester.enterText(find.byKey(newKey), 'newpass11');
      await tester.enterText(find.byKey(confirm), 'newpass11');
      await _tapKey(tester, submit);
      expect(submitted, [('oldpass00', 'newpass11')]);
    });

    testWidgets('new-password fields are filled by their keys', (tester) async {
      const newKey = Key('new');
      const confirm = Key('confirm');
      final values = <String?>[];
      await _pump(
        tester,
        SizedBox(
          width: 360,
          child: NewPasswordFields(
            onChanged: values.add,
            newKey: newKey,
            confirmKey: confirm,
          ),
        ),
      );
      await tester.enterText(find.byKey(newKey), 'longenough1');
      expect(values.last, isNull);
      await tester.enterText(find.byKey(confirm), 'longenough1');
      expect(values.last, 'longenough1');
    });
  });
}

void _noop() {}
