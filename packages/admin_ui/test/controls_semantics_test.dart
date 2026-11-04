import 'dart:ui' show SemanticsRole;

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter/semantics.dart' show SemanticsBinding, SemanticsHandle;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  home: Scaffold(
    body: Center(child: SizedBox(width: 400, child: child)),
  ),
);

/// The node a control announces as: the one its tap target sits in.
SemanticsNode _node(WidgetTester tester, Finder control) => tester.getSemantics(
  find.descendant(of: control, matching: find.byType(GestureDetector)).first,
);

/// The node of the option or segment labelled [label].
SemanticsNode _nodeOf(WidgetTester tester, String label) =>
    tester.getSemantics(find.text(label));

void main() {
  late SemanticsHandle handle;
  setUp(() => handle = SemanticsBinding.instance.ensureSemantics());
  tearDown(() => handle.dispose());

  testWidgets('Toggle is a switch with its on/off state', (tester) async {
    await tester.pumpWidget(
      _host(Toggle(value: true, onChanged: (_) {}, label: 'Comments')),
    );
    expect(
      _node(tester, find.byType(Toggle)),
      isSemantics(
        label: 'Comments',
        isButton: false,
        hasToggledState: true,
        isToggled: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
      ),
    );
  });

  testWidgets('Check is a checkbox: checked, or mixed when indeterminate', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        Column(
          children: [
            Check(value: true, onChanged: (_) {}, label: 'On'),
            Check(value: false, onChanged: (_) {}, label: 'Off'),
            Check(
              value: false,
              indeterminate: true,
              onChanged: (_) {},
              label: 'Some',
            ),
          ],
        ),
      ),
    );
    expect(
      _nodeOf(tester, 'On'),
      isSemantics(
        isButton: false,
        hasCheckedState: true,
        isChecked: true,
        isFocusable: true,
      ),
    );
    expect(
      _nodeOf(tester, 'Off'),
      isSemantics(hasCheckedState: true, isChecked: false),
    );
    expect(
      _nodeOf(tester, 'Some'),
      isSemantics(
        hasCheckedState: true,
        isChecked: false,
        isCheckStateMixed: true,
      ),
    );
  });

  testWidgets('Toggle and Check without onChanged report disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const Column(
          children: [
            Toggle(value: true, label: 'Toggle'),
            Check(value: true, label: 'Check'),
          ],
        ),
      ),
    );
    for (final label in ['Toggle', 'Check']) {
      expect(
        _nodeOf(tester, label),
        isSemantics(
          hasEnabledState: true,
          isEnabled: false,
          isFocusable: false,
        ),
        reason: label,
      );
    }
  });

  testWidgets('read-only Toggle and Check are enabled, focusable Tab stops', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const Column(
          children: [
            Toggle(value: true, readOnly: true, label: 'Toggle'),
            Check(value: true, readOnly: true, label: 'Check'),
          ],
        ),
      ),
    );
    for (final label in ['Toggle', 'Check']) {
      expect(
        _nodeOf(tester, label),
        isSemantics(
          hasEnabledState: true,
          isEnabled: true,
          isReadOnly: true,
          isFocusable: true,
        ),
        reason: label,
      );
    }
  });

  testWidgets('a read-only Choice moves focus with the arrows, never the '
      'value', (tester) async {
    final picked = <String>[];
    await tester.pumpWidget(
      _host(
        Choice<String>(
          value: 'b',
          onChanged: picked.add,
          readOnly: true,
          semanticLabel: 'Status',
          options: const [
            ChoiceOption('a', 'Alpha'),
            ChoiceOption('b', 'Beta'),
          ],
        ),
      ),
    );
    expect(
      _nodeOf(tester, 'Beta'),
      isSemantics(isReadOnly: true, isChecked: true, isFocusable: true),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_nodeOf(tester, 'Beta'), isSemantics(isFocused: true));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(_nodeOf(tester, 'Alpha'), isSemantics(isFocused: true));
    expect(picked, isEmpty);
    await tester.tap(find.text('Alpha'));
    expect(picked, isEmpty);
  });

  testWidgets('Choice options are radios in a named group', (tester) async {
    await tester.pumpWidget(
      _host(
        Choice<String>(
          value: 'a',
          onChanged: (_) {},
          semanticLabel: 'Status',
          options: const [
            ChoiceOption('a', 'Alpha'),
            ChoiceOption('b', 'Beta'),
            ChoiceOption('c', 'Gamma', enabled: false),
          ],
        ),
      ),
    );
    expect(
      _nodeOf(tester, 'Alpha'),
      isSemantics(
        isButton: false,
        isInMutuallyExclusiveGroup: true,
        hasCheckedState: true,
        isChecked: true,
        isEnabled: true,
        isFocusable: true,
      ),
    );
    expect(
      _nodeOf(tester, 'Beta'),
      isSemantics(
        isInMutuallyExclusiveGroup: true,
        hasCheckedState: true,
        isChecked: false,
      ),
    );
    expect(
      _nodeOf(tester, 'Gamma'),
      isSemantics(isInMutuallyExclusiveGroup: true, isEnabled: false),
    );
    final group = tester.getSemantics(find.bySemanticsLabel('Status'));
    expect(group.role, SemanticsRole.radioGroup);
  });

  testWidgets('a read-only Choice reports its options disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const Choice<String>(
          value: 'a',
          onChanged: null,
          options: [ChoiceOption('a', 'Alpha'), ChoiceOption('b', 'Beta')],
        ),
      ),
    );
    expect(
      _nodeOf(tester, 'Alpha'),
      isSemantics(isChecked: true, isEnabled: false, isFocusable: false),
    );
  });

  testWidgets('segments are radios in a named radio group', (tester) async {
    await tester.pumpWidget(
      _host(
        Segmented<String>(
          value: 'a',
          onChanged: (_) {},
          semanticLabel: 'Layout',
          segments: const [
            SegmentOption('a', 'List'),
            SegmentOption('b', 'Grid'),
            SegmentOption(
              'c',
              'Board view',
              icon: Icons.view_column_rounded,
              showLabel: false,
            ),
          ],
        ),
      ),
    );
    final list = _nodeOf(tester, 'List');
    expect(
      list,
      isSemantics(
        label: 'List',
        isButton: false,
        hasCheckedState: true,
        isChecked: true,
        isInMutuallyExclusiveGroup: true,
        isFocusable: true,
      ),
    );
    expect(
      _nodeOf(tester, 'Grid'),
      isSemantics(hasCheckedState: true, isChecked: false),
    );
    var group = list.parent;
    while (group != null &&
        group.getSemanticsData().role != SemanticsRole.radioGroup) {
      group = group.parent;
    }
    expect(group, isNotNull, reason: 'the segments sit in a radio group');
    expect(group!.label, 'Layout');
    // The icon-only segment keeps its label as its name, and shows no text.
    expect(find.text('Board view'), findsNothing);
    expect(find.bySemanticsLabel('Board view'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Board view')),
      isSemantics(hasCheckedState: true, isChecked: false),
    );
  });

  testWidgets('BooleanBody is one switch named by its description', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        BooleanBody(
          value: false,
          onChanged: (_) {},
          description: 'Pin to the homepage',
        ),
      ),
    );
    expect(
      _node(tester, find.byType(BooleanBody)),
      isSemantics(
        label: 'Pin to the homepage',
        hasToggledState: true,
        isToggled: false,
        isFocusable: true,
      ),
    );

    await tester.pumpWidget(
      _host(
        BooleanBody(
          value: true,
          onChanged: (_) {},
          appearance: BooleanAppearance.checkbox,
          description: 'Pinned',
        ),
      ),
    );
    expect(
      _node(tester, find.byType(BooleanBody)),
      isSemantics(label: 'Pinned', hasCheckedState: true, isChecked: true),
    );
  });

  testWidgets('Button reads its label exactly once', (tester) async {
    await tester.pumpWidget(
      _host(const Button.primary('Save', onPressed: _noop)),
    );
    expect(
      tester.getSemantics(find.text('Save')),
      isSemantics(label: 'Save', isButton: true, isEnabled: true),
    );
  });

  testWidgets('a loading Button keeps its name and announces Loading', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const Button.primary('Save', loading: true, onPressed: _noop)),
    );
    expect(
      tester.getSemantics(find.text('Save')),
      isSemantics(label: 'Save', isButton: true, isEnabled: false),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Loading')),
      isSemantics(label: 'Loading', isLiveRegion: true),
    );
  });

  testWidgets('the Tag × is a 24px button named after the tag', (tester) async {
    await tester.pumpWidget(_host(Tag('design', onRemove: () {})));
    final remove = find.bySemanticsLabel('Remove design');
    expect(remove, findsOneWidget);
    expect(tester.getSemantics(remove), isSemantics(isButton: true));
    final action = tester.getSize(find.byType(IconAction));
    expect(action.width, greaterThanOrEqualTo(24));
    expect(action.height, greaterThanOrEqualTo(24));
  });

  testWidgets('Spinner and loading surfaces announce as a live region', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const Column(
          children: [
            Spinner(),
            LoadingPanel(message: 'Loading products…', minHeight: 40),
            Spinner(announce: false),
          ],
        ),
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Loading')),
      isSemantics(label: 'Loading', isLiveRegion: true),
    );
    expect(
      tester.getSemantics(find.text('Loading products…')),
      isSemantics(label: 'Loading products…', isLiveRegion: true),
    );
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
  });

  testWidgets('CountBadge reads its semanticLabel instead of the number', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const CountBadge(
          count: 3,
          semanticLabel: '3 unread',
          child: Icon(Icons.mail),
        ),
      ),
    );
    expect(find.bySemanticsLabel('3 unread'), findsOneWidget);
    expect(find.bySemanticsLabel('3'), findsNothing);
  });

  testWidgets('Avatar is named after its person, or silent', (tester) async {
    await tester.pumpWidget(
      _host(
        const Row(
          children: [
            Avatar(name: 'Lena Fritz'),
            Avatar(initials: 'XH'),
          ],
        ),
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Lena Fritz')),
      isSemantics(label: 'Lena Fritz', isImage: true),
    );
    expect(find.text('LF'), findsOneWidget);
    expect(find.bySemanticsLabel('XH'), findsNothing);
  });
}

void _noop() {}
