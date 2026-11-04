import 'dart:io';

import 'package:admin_ui/collection.dart' show CollectionTable, TableColumn;
import 'package:admin_ui/ui.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The cursor shown over a `Text('Label')` descendant of [child], while [child]
/// sits inside a [SelectionArea]. A selectable [Text] reads its cursor from the
/// ambient [DefaultSelectionStyle] (falling back to the I-beam), so this is how
/// we tell whether an interactive wrapper propagates its click cursor down to
/// its label the way Material's [InkWell] does.
Future<MouseCursor?> cursorOverLabel(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      home: SelectionArea(
        child: Material(child: Center(child: child)),
      ),
    ),
  );
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  addTearDown(gesture.removePointer);
  await gesture.addPointer();
  await gesture.moveTo(tester.getCenter(find.text('Label')));
  await tester.pumpAndSettle();
  return RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1);
}

/// A one-row table whose only cell reads `Label`.
Widget _table({void Function(int row)? onRowTap}) => SizedBox(
  width: 400,
  height: 200,
  child: CollectionTable<int>(
    rows: const [1],
    rowKey: (row) => row,
    onRowTap: onRowTap,
    columns: [
      TableColumn(id: 'name', label: 'Name', cell: (_) => const Text('Label')),
    ],
  ),
);

void main() {
  testWidgets('a bare cursor MouseRegion leaks the text I-beam', (
    tester,
  ) async {
    // What CursorRegion is for, and what the rule below refuses.
    final cursor = await cursorOverLabel(
      tester,
      const MouseRegion(cursor: SystemMouseCursors.click, child: Text('Label')),
    );
    expect(cursor, SystemMouseCursors.text);
  });

  testWidgets('InkWell propagates its cursor to the label (reference)', (
    tester,
  ) async {
    // Explicit cursor to sidestep `adaptiveClickable`, which defers on the
    // mobile target platform tests default to; the mechanism under test is that
    // InkWell hands its cursor to the label via DefaultSelectionStyle.
    final cursor = await cursorOverLabel(
      tester,
      InkWell(
        onTap: () {},
        mouseCursor: SystemMouseCursors.click,
        child: const Text('Label'),
      ),
    );
    expect(cursor, SystemMouseCursors.click);
  });

  testWidgets('Tappable matches InkWell — click cursor over its label', (
    tester,
  ) async {
    final cursor = await cursorOverLabel(
      tester,
      Tappable(onTap: () {}, child: const Text('Label')),
    );
    expect(cursor, SystemMouseCursors.click);
  });

  testWidgets('CursorRegion hands its cursor to the label', (tester) async {
    final cursor = await cursorOverLabel(
      tester,
      const CursorRegion(
        cursor: SystemMouseCursors.click,
        child: Text('Label'),
      ),
    );
    expect(cursor, SystemMouseCursors.click);
  });

  testWidgets('a deferring CursorRegion leaves the text its I-beam', (
    tester,
  ) async {
    final cursor = await cursorOverLabel(
      tester,
      const CursorRegion(cursor: MouseCursor.defer, child: Text('Label')),
    );
    expect(cursor, SystemMouseCursors.text);
  });

  testWidgets('a row that opens shows the click cursor over its text', (
    tester,
  ) async {
    final cursor = await cursorOverLabel(tester, _table(onRowTap: (_) {}));
    expect(cursor, SystemMouseCursors.click);
  });

  testWidgets('a row that does not open keeps the I-beam over its text', (
    tester,
  ) async {
    final cursor = await cursorOverLabel(tester, _table());
    expect(cursor, SystemMouseCursors.text);
  });

  test('a click cursor goes through CursorRegion across the kit', () {
    // A MouseRegion given the click cursor shows the text I-beam over its
    // label under a host's SelectionArea. This was fixed one widget at a time
    // before, and the table's cells came back with it. CursorRegion (or
    // Tappable, which uses it) carries the cursor to the text. The kit's lib
    // and its example's are scanned.
    final root = Directory.current.absolute.uri.normalizePath().toFilePath();
    final offenders = <String>[];
    for (final top in ['lib', 'example/lib']) {
      final dir = Directory('$root$top');
      if (!dir.existsSync()) continue;
      for (final entity in dir.listSync(recursive: true, followLinks: false)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final path = entity.path.replaceAll(r'\', '/').substring(root.length);
        if (path == 'lib/src/common/ui/tappable.dart') continue;
        final source = entity.readAsStringSync();
        if (!source.contains('MouseRegion')) continue;
        final unit = parseString(
          content: source,
          featureSet: FeatureSet.latestLanguageVersion(),
          throwIfDiagnostics: false,
        ).unit;
        final visitor = _ClickMouseRegions();
        unit.accept(visitor);
        for (final node in visitor.found) {
          final line = unit.lineInfo.getLocation(node.offset).lineNumber;
          offenders.add('$path:$line');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'A MouseRegion with the click cursor shows the text I-beam over '
          'its label under a SelectionArea. Use CursorRegion (a pointer-only '
          'target) or Tappable (a control of its own):\n  '
          '${offenders.join('\n  ')}',
    );
  });
}

/// Every `MouseRegion(...)` whose `cursor:` names the click cursor.
class _ClickMouseRegions extends RecursiveAstVisitor<void> {
  final found = <AstNode>[];

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.constructorName.type.toSource() == 'MouseRegion') {
      _check(node, node.argumentList);
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.target == null && node.methodName.name == 'MouseRegion') {
      _check(node, node.argumentList);
    }
    super.visitMethodInvocation(node);
  }

  void _check(AstNode node, ArgumentList arguments) {
    for (final argument in arguments.arguments.whereType<NamedArgument>()) {
      if (argument.name.lexeme == 'cursor' &&
          argument.argumentExpression.toSource().contains(
            'SystemMouseCursors.click',
          )) {
        found.add(node);
      }
    }
  }
}
