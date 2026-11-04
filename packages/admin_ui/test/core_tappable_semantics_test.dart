import 'dart:ui' show SemanticsRole;

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  home: Scaffold(body: Center(child: child)),
);

const _box = SizedBox(width: 50, height: 50);

/// The node the [Tappable] announces as: the one its tap target sits in.
SemanticsNode _node(WidgetTester tester) => tester.getSemantics(
  find.descendant(
    of: find.byType(Tappable),
    matching: find.byType(GestureDetector),
  ),
);

void main() {
  testWidgets('an enabled target is a focusable button carrying its label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(Tappable(onTap: () {}, child: const Text('Pages'))),
    );
    expect(
      _node(tester),
      matchesSemantics(
        label: 'Pages',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_node(tester), isSemantics(isFocused: true));
    handle.dispose();
  });

  testWidgets('semanticLabel with excludeSemantics is the whole name', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        Tappable(
          onTap: () {},
          semanticLabel: 'Next page',
          excludeSemantics: true,
          child: const Text('›'),
        ),
      ),
    );
    expect(_node(tester), isSemantics(label: 'Next page', isButton: true));
    handle.dispose();
  });

  testWidgets('a disabled target with a label is a disabled button', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(const Tappable(onTap: null, semanticLabel: 'Next', child: _box)),
    );
    expect(
      _node(tester),
      matchesSemantics(
        label: 'Next',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );
    handle.dispose();
  });

  testWidgets('a decorative target emits no node of its own', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        Semantics(
          container: true,
          label: 'Card',
          child: const Tappable(onTap: null, child: _box),
        ),
      ),
    );
    expect(_node(tester), matchesSemantics(label: 'Card'));
    handle.dispose();
  });

  testWidgets('focusable: false keeps the button but not the Tab stop', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(Tappable(onTap: () {}, focusable: false, child: const Text('Row'))),
    );
    expect(
      _node(tester),
      matchesSemantics(
        label: 'Row',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  group('state flags', () {
    Future<SemanticsNode> node(WidgetTester tester, Tappable tappable) async {
      await tester.pumpWidget(_host(tappable));
      return _node(tester);
    }

    testWidgets('selected and expanded', (tester) async {
      final handle = tester.ensureSemantics();
      expect(
        await node(
          tester,
          Tappable(
            onTap: () {},
            selected: true,
            expanded: false,
            child: const Text('Section'),
          ),
        ),
        isSemantics(
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          hasExpandedState: true,
          isExpanded: false,
        ),
      );
      handle.dispose();
    });

    testWidgets('checked, and mixed over checked', (tester) async {
      final handle = tester.ensureSemantics();
      expect(
        await node(
          tester,
          Tappable(onTap: () {}, checked: true, child: const Text('Notify')),
        ),
        isSemantics(isButton: false, hasCheckedState: true, isChecked: true),
      );
      expect(
        await node(
          tester,
          Tappable(
            onTap: () {},
            checked: true,
            mixed: true,
            child: const Text('All'),
          ),
        ),
        isSemantics(
          isButton: false,
          hasCheckedState: true,
          isChecked: false,
          isCheckStateMixed: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('toggled', (tester) async {
      final handle = tester.ensureSemantics();
      expect(
        await node(
          tester,
          Tappable(onTap: () {}, toggled: false, child: const Text('Comments')),
        ),
        isSemantics(isButton: false, hasToggledState: true, isToggled: false),
      );
      handle.dispose();
    });

    testWidgets('a radio in a mutually exclusive group', (tester) async {
      final handle = tester.ensureSemantics();
      expect(
        await node(
          tester,
          Tappable(
            onTap: () {},
            checked: false,
            inMutuallyExclusiveGroup: true,
            child: const Text('Draft'),
          ),
        ),
        isSemantics(
          isButton: false,
          hasCheckedState: true,
          isChecked: false,
          isInMutuallyExclusiveGroup: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('a link', (tester) async {
      final handle = tester.ensureSemantics();
      expect(
        await node(
          tester,
          Tappable(onTap: () {}, link: true, child: const Text('Forgot?')),
        ),
        isSemantics(isButton: false, isLink: true, label: 'Forgot?'),
      );
      handle.dispose();
    });

    testWidgets('a role replaces the button role', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Semantics(
            role: SemanticsRole.tabBar,
            container: true,
            child: Tappable(
              onTap: () {},
              role: SemanticsRole.tab,
              selected: true,
              child: const Text('General'),
            ),
          ),
        ),
      );
      final tab = _node(tester);
      expect(tab, isSemantics(isButton: false, isSelected: true));
      expect(tab.getSemanticsData().role, SemanticsRole.tab);
      handle.dispose();
    });
  });
}
