import 'dart:io';

import 'package:admin_ui/collection.dart' show CollectionTable, TableColumn;
import 'package:admin_ui/comments.dart' show MentionText;
import 'package:admin_ui/ui.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// A tap target is no place to select text. Under a host's [SelectionArea]
/// every [Text] is selectable and shows the I-beam, and Flutter ties the two
/// together (`Text.build`), so the kit takes a target's text out of the
/// selection ([CursorRegion], and the `InkWell` sites) rather than hand the
/// click cursor down and leave the text selectable, as [InkWell] does. What a
/// drag selects is the measure; the cursor follows from it. The cursor over a
/// control is the hand on every platform, which Material's own buttons give
/// up off the web; the kit's `InkWell` sites are held to it here too.

/// Pumps [child] centred in a [SelectionArea].
Future<void> _pumpInArea(
  WidgetTester tester,
  Widget child, {
  ValueChanged<SelectedContent?>? onSelectionChanged,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: SelectionArea(
        onSelectionChanged: onSelectionChanged,
        child: Material(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(child: child),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<TestGesture> _mouse(WidgetTester tester) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  addTearDown(gesture.removePointer);
  await gesture.addPointer();
  return gesture;
}

/// The cursor shown over a `Text('Label')` descendant of [child], while [child]
/// sits inside a [SelectionArea]. A selectable [Text] puts up the I-beam; one
/// a target took out of the selection shows the target's cursor.
Future<MouseCursor?> cursorOverLabel(WidgetTester tester, Widget child) async {
  await _pumpInArea(tester, child);
  final gesture = await _mouse(tester);
  await gesture.moveTo(tester.getCenter(find.text('Label')));
  await tester.pumpAndSettle();
  return RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1);
}

/// What a mouse drag across the `Text('Label')` descendant of [child] selects,
/// while [child] sits inside a [SelectionArea]: the text, or '' for nothing.
Future<String> dragSelects(WidgetTester tester, Widget child) async {
  String? selected;
  await _pumpInArea(
    tester,
    child,
    onSelectionChanged: (content) => selected = content?.plainText,
  );
  final gesture = await _mouse(tester);
  final rect = tester.getRect(find.text('Label'));
  final from = Offset(rect.left - 4, rect.center.dy);
  final to = Offset(rect.right + 4, rect.center.dy);
  await gesture.moveTo(from);
  await tester.pump();
  await gesture.down(from);
  await tester.pump();
  await gesture.moveTo(Offset.lerp(from, to, 0.5)!);
  await tester.pump();
  await gesture.moveTo(to);
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
  return selected ?? '';
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
  group('what a drag selects', () {
    testWidgets('text outside a target selects', (tester) async {
      expect(await dragSelects(tester, const Text('Label')), 'Label');
    });

    testWidgets('text outside a target shows the I-beam', (tester) async {
      expect(
        await cursorOverLabel(tester, const Text('Label')),
        SystemMouseCursors.text,
      );
    });

    testWidgets('a Tappable leaves its label out, and still opens', (
      tester,
    ) async {
      var taps = 0;
      final target = Tappable(onTap: () => taps++, child: const Text('Label'));
      expect(await dragSelects(tester, target), '');
      await tester.tap(find.text('Label'));
      expect(taps, 1);
    });

    testWidgets('a disabled Tappable leaves its label out', (tester) async {
      const target = Tappable(onTap: null, child: Text('Label'));
      expect(await dragSelects(tester, target), '');
    });

    testWidgets('a Button leaves its label out', (tester) async {
      // Built on InkWell, which hands its cursor down and leaves the label
      // selectable; the Button takes the label out itself.
      expect(await dragSelects(tester, Button('Label', onPressed: () {})), '');
    });

    testWidgets('a row that opens leaves its cells out, and still opens', (
      tester,
    ) async {
      var taps = 0;
      expect(await dragSelects(tester, _table(onRowTap: (_) => taps++)), '');
      await tester.tap(find.text('Label'));
      expect(taps, 1);
    });

    testWidgets('a row that does not open selects', (tester) async {
      expect(await dragSelects(tester, _table()), 'Label');
    });

    testWidgets('a MentionText in a Tappable stays plain', (tester) async {
      // MentionText opens a selection area of its own where none is above.
      // Under a target it must not: that would select its text, show the
      // I-beam, and put a second Tab stop inside the target.
      final target = Tappable(
        onTap: () {},
        child: MentionText('Label', nameOf: (id) => id),
      );
      expect(await dragSelects(tester, target), '');
      expect(find.byType(SelectionArea), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('the cursor over a label', () {
    testWidgets('a bare cursor MouseRegion leaks the text I-beam', (
      tester,
    ) async {
      // What CursorRegion is for, and what the rule below refuses.
      final cursor = await cursorOverLabel(
        tester,
        const MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Text('Label'),
        ),
      );
      expect(cursor, SystemMouseCursors.text);
    });

    testWidgets('InkWell shows the click cursor (reference)', (tester) async {
      // Explicit cursor: InkWell's own default is platform-adaptive, the arrow
      // off the web (the rule below has every InkWell in the kit name one).
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

    testWidgets('InkWell keeps its label selectable, which the kit does not', (
      tester,
    ) async {
      // Material's choice: the cursor handed down through
      // DefaultSelectionStyle, the text still in the selection. See
      // CursorRegion for the kit's.
      final selected = await dragSelects(
        tester,
        InkWell(onTap: () {}, child: const Text('Label')),
      );
      expect(selected, 'Label');
    });

    testWidgets('Tappable shows the click cursor over its label', (
      tester,
    ) async {
      final cursor = await cursorOverLabel(
        tester,
        Tappable(onTap: () {}, child: const Text('Label')),
      );
      expect(cursor, SystemMouseCursors.click);
    });

    testWidgets('CursorRegion shows its cursor over the label', (tester) async {
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
  });

  group('the cursor over a control', () {
    // The hand on every platform, so a development build on the desktop
    // looks like the shipped web app. Material's buttons switch to the arrow
    // off the web; the kit's InkWell sites override that (see Tappable).
    testWidgets('Button shows the hand', (tester) async {
      final cursor = await cursorOverLabel(
        tester,
        Button('Label', onPressed: () {}),
      );
      expect(cursor, SystemMouseCursors.click);
    });

    testWidgets('a disabled Button shows the arrow', (tester) async {
      final cursor = await cursorOverLabel(tester, const Button('Label'));
      expect(cursor, SystemMouseCursors.basic);
    });

    testWidgets('a disabled Tappable shows the arrow', (tester) async {
      final cursor = await cursorOverLabel(
        tester,
        const Tappable(onTap: null, child: Text('Label')),
      );
      expect(cursor, SystemMouseCursors.basic);
    });
  });

  test('a click cursor goes through CursorRegion across the kit', () {
    // A MouseRegion given the click cursor leaves its label selectable, with
    // the text I-beam, under a host's SelectionArea. This was fixed one
    // widget at a time before, and the table's cells came back with it.
    // CursorRegion (or Tappable, which uses it) takes the text out of the
    // selection.
    final offenders = _scan(
      () => _Constructions(
        const ['MouseRegion'],
        (arguments) => arguments.any(
          (a) =>
              a.name.lexeme == 'cursor' &&
              a.argumentExpression.toSource().contains(
                'SystemMouseCursors.click',
              ),
        ),
      ),
      skip: const {'lib/src/common/ui/tappable.dart'},
    );

    expect(
      offenders,
      isEmpty,
      reason:
          'A MouseRegion with the click cursor leaves its label selectable, '
          'with the text I-beam, under a SelectionArea. Use CursorRegion (a '
          'pointer-only target) or Tappable (a control of its own):\n  '
          '${offenders.join('\n  ')}',
    );
  });

  test('an InkWell names its cursor across the kit', () {
    // InkWell's default cursor is platform-adaptive: the hand on the web, the
    // arrow off it. Left to it, a Button showed the arrow in a desktop build
    // while the Tappable beside it showed the hand. The kit's hand is the
    // same on every platform (see Tappable).
    final offenders = _scan(
      () => _Constructions(const [
        'InkWell',
        'InkResponse',
      ], (arguments) => !arguments.any((a) => a.name.lexeme == 'mouseCursor')),
    );

    expect(
      offenders,
      isEmpty,
      reason:
          'An InkWell left to its default cursor shows the arrow off the web '
          'and the hand on it. Pass mouseCursor: '
          'WidgetStateMouseCursor.clickable, or use Tappable:\n  '
          '${offenders.join('\n  ')}',
    );
  });
}

/// `path:line` of every construction in the kit's lib, and its example's,
/// that a fresh [visitor] flags; files in [skip] are left out.
List<String> _scan(
  _Constructions Function() visitor, {
  Set<String> skip = const {},
}) {
  final root = Directory.current.absolute.uri.normalizePath().toFilePath();
  final offenders = <String>[];
  for (final top in ['lib', 'example/lib']) {
    final dir = Directory('$root$top');
    if (!dir.existsSync()) continue;
    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/').substring(root.length);
      if (skip.contains(path)) continue;
      final source = entity.readAsStringSync();
      final constructions = visitor();
      if (!constructions.names.any(source.contains)) continue;
      final unit = parseString(
        content: source,
        featureSet: FeatureSet.latestLanguageVersion(),
        throwIfDiagnostics: false,
      ).unit;
      unit.accept(constructions);
      for (final node in constructions.found) {
        final line = unit.lineInfo.getLocation(node.offset).lineNumber;
        offenders.add('$path:$line');
      }
    }
  }
  return offenders;
}

/// Every construction of a widget in [names] whose named arguments [flag]
/// accepts.
class _Constructions extends RecursiveAstVisitor<void> {
  final List<String> names;
  final bool Function(Iterable<NamedArgument> arguments) flag;
  final found = <AstNode>[];

  _Constructions(this.names, this.flag);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (names.contains(node.constructorName.type.toSource())) {
      _check(node, node.argumentList);
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.target == null && names.contains(node.methodName.name)) {
      _check(node, node.argumentList);
    }
    super.visitMethodInvocation(node);
  }

  void _check(AstNode node, ArgumentList arguments) {
    if (flag(arguments.arguments.whereType<NamedArgument>())) found.add(node);
  }
}
