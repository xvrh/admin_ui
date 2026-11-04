import 'dart:ui' show SemanticsRole;

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// A menu of two checkbox items the host keeps the values of, and a
/// disabled one.
class _Host extends StatefulWidget {
  final bool keepOpen;

  const _Host({this.keepOpen = false});

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  final changes = <(String, bool)>[];
  bool _title = true;
  bool _status = false;

  void _set(String label, bool value) {
    changes.add((label, value));
    setState(() => label == 'Title' ? _title = value : _status = value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Menu(
            entries: [
              MenuCheckboxItem(
                'Title',
                checked: _title,
                keepOpen: widget.keepOpen,
                onChanged: (value) => _set('Title', value),
              ),
              MenuCheckboxItem(
                'Status',
                checked: _status,
                shortcut: '⌘S',
                keepOpen: widget.keepOpen,
                onChanged: (value) => _set('Status', value),
              ),
              const MenuCheckboxItem('Author', checked: true, onChanged: null),
              MenuItem('Reset', onSelect: () {}),
            ],
            builder: (context, c) =>
                TextButton(onPressed: c.toggle, child: const Text('Columns')),
          ),
        ),
      ),
    );
  }
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Columns'));
  await tester.pumpAndSettle();
}

String? _focused() => FocusManager.instance.primaryFocus?.debugLabel;

void main() {
  testWidgets('a checkbox item is a menu item checkbox with its checked '
      'state; a null onChanged disables it', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const _Host());
    await _open(tester);

    SemanticsNode node(String text) => tester.getSemantics(find.text(text));
    expect(
      node('Title').getSemanticsData().role,
      SemanticsRole.menuItemCheckbox,
    );
    expect(
      node('Title'),
      isSemantics(
        label: 'Title',
        hasCheckedState: true,
        isChecked: true,
        isEnabled: true,
        hasTapAction: true,
        isInMutuallyExclusiveGroup: false,
      ),
    );
    expect(
      node('Status'),
      isSemantics(label: 'Status\n⌘S', hasCheckedState: true, isChecked: false),
    );
    expect(
      node('Author'),
      isSemantics(
        label: 'Author',
        hasCheckedState: true,
        isChecked: true,
        isEnabled: false,
      ),
    );
    expect(node('Reset').getSemanticsData().role, SemanticsRole.menuItem);
    semantics.dispose();
  });

  testWidgets('the check stands in the radio items\' column, level with its '
      'row', (tester) async {
    await tester.pumpWidget(const _Host());
    await _open(tester);
    final checks = find.byIcon(Icons.check_rounded);
    expect(checks, findsNWidgets(2), reason: 'Title and Author');
    expect(
      tester.getCenter(checks.first).dy,
      closeTo(tester.getCenter(find.text('Title')).dy, 1),
    );
    // Status keeps the column empty, so its shortcut lines up with the
    // others' ends.
    final surface = tester.getRect(find.byType(PopoverMenuSurface));
    expect(
      tester.getRect(checks.first).right,
      closeTo(surface.right - 4 - 8, 0.5),
    );
    expect(
      tester.getRect(find.text('⌘S')).right,
      lessThan(tester.getRect(checks.first).left),
    );
  });

  testWidgets('beside a row with an icon, the rows without one start their '
      'labels in its column', (tester) async {
    Widget host({required bool icons}) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: Menu(
            entries: [
              MenuItem(
                'Duplicate',
                icon: icons ? Icons.copy_rounded : null,
                onSelect: () {},
              ),
              MenuCheckboxItem('Drafts', checked: true, onChanged: (_) {}),
              const MenuSubmenu('Move to', entries: [MenuItem('Blog')]),
            ],
            builder: (context, c) =>
                TextButton(onPressed: c.toggle, child: const Text('Columns')),
          ),
        ),
      ),
    );

    await tester.pumpWidget(host(icons: true));
    await _open(tester);
    final labels = [
      for (final label in ['Duplicate', 'Drafts', 'Move to'])
        tester.getRect(find.text(label)).left,
    ];
    final surface = tester.getRect(find.byType(PopoverMenuSurface));
    // The row's 4 inset and 8 padding, then the 16 icon and its 8 gap.
    expect(labels, everyElement(closeTo(surface.left + 4 + 8 + 16 + 8, 0.5)));

    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();
    await tester.pumpWidget(host(icons: false));
    await _open(tester);
    final bare = tester.getRect(find.byType(PopoverMenuSurface));
    expect(
      tester.getRect(find.text('Drafts')).left,
      closeTo(bare.left + 4 + 8, 0.5),
      reason: 'no icon in the menu, no column to keep',
    );
  });

  testWidgets('choosing one closes the menu, then calls onChanged with the '
      'other value', (tester) async {
    await tester.pumpWidget(const _Host());
    await _open(tester);
    await tester.tap(find.text('Title'));
    await tester.pumpAndSettle();
    final host = tester.state<_HostState>(find.byType(_Host));
    expect(host.changes, [('Title', false)]);
    expect(find.text('Status'), findsNothing);

    // From the keyboard, too.
    await _open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(_focused(), 'Status');
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(host.changes, [('Title', false), ('Status', true)]);
    expect(find.text('Status'), findsNothing);
  });

  testWidgets('with keepOpen the menu stays open on it, showing the new '
      'value', (tester) async {
    await tester.pumpWidget(const _Host(keepOpen: true));
    await _open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(_focused(), 'Title');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Status'));
    await tester.pumpAndSettle();

    final host = tester.state<_HostState>(find.byType(_Host));
    expect(host.changes, [('Title', false), ('Status', true)]);
    expect(find.text('Title'), findsOneWidget, reason: 'still open');
    expect(find.byIcon(Icons.check_rounded), findsNWidgets(2));
    expect(
      tester.getCenter(find.byIcon(Icons.check_rounded).first).dy,
      closeTo(tester.getCenter(find.text('Status')).dy, 1),
    );
  });

  testWidgets('the arrows skip a disabled checkbox item, and tapping it does '
      'nothing', (tester) async {
    await tester.pumpWidget(const _Host());
    await _open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pumpAndSettle();
    expect(_focused(), 'Reset');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(_focused(), 'Status', reason: 'Author is disabled');

    await tester.tap(find.text('Author'));
    await tester.pumpAndSettle();
    expect(tester.state<_HostState>(find.byType(_Host)).changes, isEmpty);
    expect(find.text('Author'), findsOneWidget);
  });
}
