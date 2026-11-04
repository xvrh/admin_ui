import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _statuses = [
  SelectOption(value: 'draft', label: 'Draft'),
  SelectOption(value: 'review', label: 'In review'),
  SelectOption(value: 'published', label: 'Published'),
];

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  localizationsDelegates: AdminLocalizations.localizationsDelegates,
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 420, child: SingleChildScrollView(child: child)),
    ),
  ),
);

/// Whether the focused node sits inside a widget of type [T].
bool _focusIn<T extends Widget>() =>
    FocusManager.instance.primaryFocus?.context
        ?.findAncestorWidgetOfExactType<T>() !=
    null;

/// The node the [Tappable] around [label] reads as, looked up through its
/// gesture detector: the Tappable's own top render object sits above it.
SemanticsNode _rowNode(WidgetTester tester, Finder label) =>
    tester.getSemantics(
      find
          .descendant(
            of: find.ancestor(of: label, matching: find.byType(Tappable)).first,
            matching: find.byType(GestureDetector),
          )
          .first,
    );

/// The semantics node a [FieldTrigger] reads as — the field's merged node.
SemanticsNode _triggerNode(WidgetTester tester, Finder field) =>
    tester.getSemantics(
      find.descendant(
        of: field,
        matching: find.descendant(
          of: find.byType(FieldTrigger),
          matching: find.byType(GestureDetector),
        ),
      ),
    );

Future<void> _tab(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  Widget form({ValueChanged<String>? onStatus}) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FieldShell(
        label: 'Status',
        mergeSemantics: true,
        child: SelectBody(
          options: _statuses,
          value: 'draft',
          onChanged: onStatus ?? (_) {},
        ),
      ),
      const SizedBox(height: 24),
      FieldShell(
        label: 'Publish date',
        child: DateBody(value: DateTime(2026, 6, 18), onChanged: (_) {}),
      ),
      const SizedBox(height: 24),
      FieldShell(
        label: 'Accent',
        mergeSemantics: true,
        child: ColorBody(value: '#5B5BD6', onChanged: (_) {}),
      ),
      const SizedBox(height: 24),
      FieldShell(
        label: 'Featured',
        mergeSemantics: true,
        child: BooleanBody(value: false, onChanged: (_) {}),
      ),
    ],
  );

  testWidgets('Tab walks the select, date, colour and boolean fields', (
    tester,
  ) async {
    await tester.pumpWidget(_host(form()));

    await _tab(tester);
    expect(_focusIn<SelectBody>(), isTrue, reason: 'select trigger');
    await _tab(tester);
    expect(_focusIn<DateBody>(), isTrue, reason: 'date trigger');
    // The date's clear button is its own stop, beside the trigger.
    await _tab(tester);
    expect(_focusIn<ClearButton>(), isTrue, reason: 'date clear');
    await _tab(tester);
    expect(_focusIn<ColorBody>(), isTrue, reason: 'colour trigger');
    await _tab(tester);
    expect(_focusIn<BooleanBody>(), isTrue, reason: 'boolean control');
  });

  testWidgets('the focused trigger draws the active border', (tester) async {
    await tester.pumpWidget(_host(form()));
    FieldChrome chrome() => tester.widget<FieldChrome>(
      find.descendant(
        of: find.byType(SelectBody),
        matching: find.byType(FieldChrome),
      ),
    );
    expect(chrome().active, isFalse);
    await _tab(tester);
    expect(chrome().active, isTrue);
  });

  testWidgets('Enter opens the select onto its selected option', (
    tester,
  ) async {
    String? picked;
    await tester.pumpWidget(_host(form(onStatus: (v) => picked = v)));
    await _tab(tester);
    expect(find.text('In review'), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('In review'), findsOneWidget);
    // Focus moved into the menu, with the selected option highlighted.
    expect(_focusIn<ListboxMenu>(), isTrue);
    final draft = tester.widget<ListboxOption>(
      find.widgetWithText(ListboxOption, 'Draft'),
    );
    expect(draft.controller.highlighted, draft.index);

    // The arrows walk the options; Enter picks.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(picked, 'review');
    expect(find.text('Published'), findsNothing);
  });

  testWidgets('Space, ArrowDown and Alt+ArrowDown open the select too', (
    tester,
  ) async {
    await tester.pumpWidget(_host(form()));
    await _tab(tester);

    for (final open in [
      () => tester.sendKeyEvent(LogicalKeyboardKey.space),
      () => tester.sendKeyEvent(LogicalKeyboardKey.arrowDown),
      () async {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      },
    ]) {
      await open();
      await tester.pumpAndSettle();
      expect(find.text('Published'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Published'), findsNothing);
      // Closing hands focus back to the trigger.
      expect(_focusIn<SelectBody>(), isTrue);
    }
  });

  testWidgets('Enter opens the date picker onto its first cell', (
    tester,
  ) async {
    await tester.pumpWidget(_host(form()));
    await _tab(tester);
    await _tab(tester);
    expect(_focusIn<DateBody>(), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(Calendar), findsOneWidget);
    expect(_focusIn<Calendar>(), isTrue, reason: "on the calendar's day");
  });

  testWidgets('Enter opens the colour picker onto the selected swatch', (
    tester,
  ) async {
    await tester.pumpWidget(_host(form()));
    for (var i = 0; i < 4; i++) {
      await _tab(tester);
    }
    expect(_focusIn<ColorBody>(), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    final handle = tester.ensureSemantics();
    final focused = FocusManager.instance.primaryFocus!.context!;
    expect(
      tester.getSemantics(find.byElementPredicate((e) => e == focused).first),
      isSemantics(label: '#5B5BD6', isSelected: true, isButton: true),
    );
    handle.dispose();
  });

  testWidgets('triggers read the field label, the value and expanded', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(form()));
    final status = find.widgetWithText(FieldShell, 'STATUS');
    expect(
      _triggerNode(tester, status),
      isSemantics(
        label: 'Status\nDraft',
        isButton: true,
        isFocusable: true,
        hasExpandedState: true,
        isExpanded: false,
        hasTapAction: true,
      ),
    );

    await tester.tap(find.text('Draft'));
    await tester.pumpAndSettle();
    expect(
      _triggerNode(tester, status),
      isSemantics(hasExpandedState: true, isExpanded: true),
    );
    handle.dispose();
  });

  testWidgets('a read-only select still names its value', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        const FieldShell(
          label: 'Status',
          mergeSemantics: true,
          child: SelectBody(options: _statuses, value: 'published'),
        ),
      ),
    );
    // Read-only is not disabled: a focusable node that reads its value.
    expect(
      tester.getSemantics(find.text('Published')),
      isSemantics(
        label: 'Status\nPublished',
        isReadOnly: true,
        isFocusable: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('the tokens trigger is one stop and opens onto its options', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        Column(
          children: [
            MultiSelectBody(
              options: _statuses,
              value: const {'draft', 'review'},
              onChanged: (_) {},
            ),
            const _After(),
          ],
        ),
      ),
    );
    await _tab(tester);
    expect(_focusIn<MultiSelectBody>(), isTrue);
    // The tokens' remove buttons are no stops of their own.
    await _tab(tester);
    expect(_focusIn<_After>(), isTrue);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
    expect(_focusIn<MultiSelectBody>(), isTrue, reason: 'back on the trigger');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Published'), findsOneWidget);
    expect(_focusIn<ListboxMenu>(), isTrue);
  });

  testWidgets('the reference add trigger opens onto its search box', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        ReferenceBody<String, String>(
          value: const [],
          onChanged: (_) {},
          idOf: (s) => s,
          resolve: (ids) async => ids.toList(),
          search: (query, {cursor}) async => const ReferencePage(['Alpha']),
          tile: (context, s) => ReferenceTileCard(title: s),
          addLabel: 'Link a page',
        ),
      ),
    );
    await _tab(tester);
    expect(_focusIn<ReferenceBody<String, String>>(), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(find.text('Alpha'), findsOneWidget);
    expect(_focusIn<EditableText>(), isTrue);
  });

  group('option rows', () {
    testWidgets('radio rows are one Tab stop the arrows move and check', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var value = 'draft';
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              StatefulBuilder(
                builder: (context, setState) => SelectBody(
                  options: _statuses,
                  value: value,
                  appearance: SelectAppearance.radio,
                  onChanged: (v) => setState(() => value = v),
                ),
              ),
              const _After(),
            ],
          ),
        ),
      );
      SemanticsNode row(String label) => _rowNode(tester, find.text(label));
      expect(
        row('Draft'),
        isSemantics(
          hasCheckedState: true,
          isChecked: true,
          isInMutuallyExclusiveGroup: true,
        ),
      );
      expect(row('In review'), isSemantics(isChecked: false));

      await _tab(tester);
      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<SelectBody>(),
        isNotNull,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(value, 'review');
      expect(row('In review'), isSemantics(isChecked: true, isFocused: true));

      // Tab leaves the group rather than visiting every radio.
      await _tab(tester);
      expect(_focusIn<_After>(), isTrue);
      handle.dispose();
    });

    testWidgets('checklist rows are checkboxes; segment pills are selected', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              MultiSelectBody(
                options: _statuses,
                value: const {'review'},
                appearance: MultiSelectAppearance.checklist,
                onChanged: (_) {},
              ),
              SelectBody(
                options: _statuses,
                value: 'published',
                appearance: SelectAppearance.segmented,
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      );
      SemanticsNode row(Finder scope, String label) => _rowNode(
        tester,
        find.descendant(of: scope, matching: find.text(label)),
      );
      final checklist = find.byType(MultiSelectBody);
      expect(
        row(checklist, 'In review'),
        isSemantics(hasCheckedState: true, isChecked: true),
      );
      expect(
        row(checklist, 'Draft'),
        isSemantics(hasCheckedState: true, isChecked: false),
      );
      final pills = find.byType(SelectBody);
      expect(
        row(pills, 'Published'),
        isSemantics(hasSelectedState: true, isSelected: true, isButton: true),
      );
      expect(row(pills, 'Draft'), isSemantics(isSelected: false));
      handle.dispose();
    });
  });

  group('capability buttons', () {
    Widget field() => FieldShell(
      label: 'Title',
      help: const HelpButton(text: 'The page heading.'),
      comments: const CommentsButton(count: 3),
      history: const HistoryButton(draft: 'a', baseline: 'a'),
      child: TextBody(onChanged: (_) {}),
    );

    testWidgets('are named nodes of their own, not merged into the field', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(field()));
      expect(
        find.bySemanticsLabel('Help for Title'),
        findsOneWidget,
        reason: 'help',
      );
      expect(find.bySemanticsLabel('3 comments'), findsOneWidget);
      expect(find.bySemanticsLabel('Version history'), findsOneWidget);
      final help = tester.getSemantics(find.bySemanticsLabel('Help for Title'));
      expect(help.isMergedIntoParent, isFalse);
      expect(help, isSemantics(isButton: true, hasExpandedState: true));
      handle.dispose();
    });

    testWidgets('are Tab stops with hit boxes of 24px or more', (tester) async {
      await tester.pumpWidget(_host(field()));
      for (final type in [HelpButton, CommentsButton, HistoryButton]) {
        final box = tester.getSize(
          find
              .descendant(
                of: find.byType(type),
                matching: find.byType(Tappable),
              )
              .first,
        );
        expect(box.width, greaterThanOrEqualTo(24), reason: '$type');
        expect(box.height, greaterThanOrEqualTo(24), reason: '$type');
      }
      await _tab(tester);
      expect(_focusIn<HelpButton>(), isTrue);
    });
  });

  testWidgets('tag and repeater removes are labelled, 24px or more', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        Column(
          children: [
            TagsBody(value: const ['news', 'sport'], onChanged: (_) {}),
            Repeater(
              itemCount: 2,
              itemBuilder: (_, i) => Text('row-$i'),
              onRemove: (_) {},
            ),
            KeyValueBody(value: const {'color': 'red'}, onChanged: (_) {}),
          ],
        ),
      ),
    );
    expect(find.bySemanticsLabel('Remove news'), findsOneWidget);
    expect(find.bySemanticsLabel('Remove sport'), findsOneWidget);
    expect(find.bySemanticsLabel('Remove item 1'), findsOneWidget);
    expect(find.bySemanticsLabel('Remove item 2'), findsOneWidget);
    expect(find.bySemanticsLabel('Remove color'), findsOneWidget);
    for (final element in find.byType(IconAction).evaluate()) {
      final action = element.widget as IconAction;
      expect(action.size.boxOf(element), greaterThanOrEqualTo(24));
    }
    final add = tester.getSize(
      find.ancestor(of: find.text('Add row'), matching: find.byType(Button)),
    );
    expect(add.height, greaterThanOrEqualTo(24));
    handle.dispose();
  });

  testWidgets('the number steppers are no Tab stops; the arrows step', (
    tester,
  ) async {
    num? value = 4;
    await tester.pumpWidget(
      _host(
        Column(
          children: [
            StatefulBuilder(
              builder: (context, setState) => NumberBody(
                value: value,
                appearance: NumberAppearance.stepper,
                onChanged: (v) => setState(() => value = v),
              ),
            ),
            const _After(),
          ],
        ),
      ),
    );
    await _tab(tester);
    expect(_focusIn<EditableText>(), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(value, 5);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(value, 3);
    // Tab leaves the field: the + square is not a stop.
    await _tab(tester);
    expect(_focusIn<_After>(), isTrue);
  });

  testWidgets('a number field reads its unit with its value, as one node', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        FieldShell(
          label: 'Hero height',
          child: NumberBody(value: 480, unit: 'px', onChanged: (_) {}),
        ),
      ),
    );
    expect(find.text('px'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(EditableText)),
      isSemantics(
        label: 'Hero height',
        value: '480',
        hint: 'px',
        isTextField: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('the label focuses a trigger body, as it does a text input', (
    tester,
  ) async {
    await tester.pumpWidget(_host(form()));
    await tester.tap(find.text('PUBLISH DATE'));
    await tester.pump();
    expect(_focusIn<DateBody>(), isTrue);
  });
}

/// A focusable after the widget under test, where Tab lands on leaving it.
class _After extends StatelessWidget {
  const _After();

  @override
  Widget build(BuildContext context) =>
      TextButton(onPressed: () {}, child: const Text('after'));
}
