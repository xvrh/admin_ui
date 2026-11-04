import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lib/src lays out by start and end, not left and right', () {
    // Geometry written as left and right stays put when the app runs right to
    // left: a leading inset lands on the trailing side, a start-aligned label
    // on the end, a badge on the wrong corner. The directional forms resolve
    // against the ambient Directionality, and are the same in LTR.
    //
    // Geometry that really is physical (a code editor, image-crop pixel
    // space, a slide offset already mirrored) says so with a
    // `// Physical: <reason>` comment on its line or the line above.
    final offenders = <String, List<String>>{};
    for (final entity in Directory('lib/src').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      final source = entity.readAsStringSync();
      final unit = parseString(
        content: source,
        featureSet: FeatureSet.latestLanguageVersion(),
        throwIfDiagnostics: false,
      ).unit;
      final lines = source.split('\n');
      final visitor = _LtrOnly();
      unit.accept(visitor);
      for (final (node, message) in visitor.found) {
        final line = unit.lineInfo.getLocation(node.offset).lineNumber;
        if (_physical(lines, line)) continue;
        (offenders[path] ??= []).add('  $line: $message');
      }
    }

    final files = offenders.keys.toList()..sort();
    final count = offenders.values.fold(0, (n, l) => n + l.length);
    expect(
      offenders,
      isEmpty,
      reason:
          '$count LTR-only constructs in ${files.length} files. Use '
          'EdgeInsetsDirectional, AlignmentDirectional, PositionedDirectional, '
          'BorderDirectional, BorderRadiusDirectional, TextAlign.start/end, a '
          'mirroring icon and AlignmentDirectional gradient ends, or mark '
          'geometry that is physical on purpose with `// Physical: <reason>`.'
          '\n\n${[for (final f in files) '$f\n${offenders[f]!.join('\n')}'].join('\n\n')}',
    );
  });
}

/// Whether line [line] (1-based), or the one above it, carries the
/// `// Physical:` escape.
bool _physical(List<String> lines, int line) {
  bool marked(int i) =>
      i >= 1 && i <= lines.length && lines[i - 1].contains('// Physical:');
  return marked(line) || marked(line - 1);
}

class _LtrOnly extends RecursiveAstVisitor<void> {
  final found = <(AstNode, String)>[];

  static final _physicalAlignment = RegExp(
    r'^(top|center|bottom)(Left|Right)$',
  );
  static const _glyphs = ['▸', '◂', '→', '←'];

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _call(node, node.constructorName.toSource(), node.argumentList);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.target;
    final name = target == null
        ? node.methodName.name
        : '${target.toSource()}.${node.methodName.name}';
    _call(node, name, node.argumentList);
    super.visitMethodInvocation(node);
  }

  void _call(AstNode node, String callee, ArgumentList arguments) {
    final named = {
      for (final a in arguments.arguments.whereType<NamedArgument>())
        a.name.lexeme: a.argumentExpression.toSource(),
    };
    final positional = [
      for (final a in arguments.arguments)
        if (a is Expression) a.toSource(),
    ];
    switch (callee) {
      case 'EdgeInsets.only' when _sided(named, 'left', 'right'):
        found.add((
          node,
          'EdgeInsets.only(left:/right:) → EdgeInsetsDirectional.only(start:/end:)',
        ));
      case 'EdgeInsets.fromLTRB'
          when positional.length == 4 && positional[0] != positional[2]:
        found.add((
          node,
          'EdgeInsets.fromLTRB → EdgeInsetsDirectional.fromSTEB',
        ));
      case 'Positioned' || 'Positioned.fill' || 'AnimatedPositioned'
          when _sided(named, 'left', 'right'):
        found.add((
          node,
          '$callee(left:/right:) → ${callee.startsWith('Animated') ? 'AnimatedPositionedDirectional' : 'PositionedDirectional'}',
        ));
      case 'Border' when _sided(named, 'left', 'right'):
        found.add((node, 'Border(left:/right:) → BorderDirectional'));
      case 'BorderRadius.only'
          when _sided(named, 'topLeft', 'topRight') ||
              _sided(named, 'bottomLeft', 'bottomRight'):
        found.add((node, 'BorderRadius.only → BorderRadiusDirectional.only'));
      case 'BorderRadius.horizontal' when _sided(named, 'left', 'right'):
        found.add((
          node,
          'BorderRadius.horizontal → BorderRadiusDirectional.horizontal',
        ));
      case 'LinearGradient'
          when !named.containsKey('begin') || !named.containsKey('end'):
        found.add((
          node,
          'LinearGradient runs left to right by default → give it '
              'AlignmentDirectional begin: and end:',
        ));
    }
  }

  /// Whether the [left] and [right] arguments differ, so the geometry is
  /// lopsided: one given without the other, or both with different values.
  static bool _sided(Map<String, String> named, String left, String right) =>
      named[left] != named[right];

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _constant(node, node.prefix.name, node.identifier.name);
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.target case SimpleIdentifier(:final name)) {
      _constant(node, name, node.propertyName.name);
    }
    super.visitPropertyAccess(node);
  }

  void _constant(AstNode node, String type, String name) {
    switch (type) {
      case 'Alignment' when _physicalAlignment.hasMatch(name):
        found.add((
          node,
          'Alignment.$name → AlignmentDirectional.'
              '${name.replaceAll('Left', 'Start').replaceAll('Right', 'End')}',
        ));
      case 'TextAlign' when name == 'left' || name == 'right':
        found.add((
          node,
          'TextAlign.$name → TextAlign.${name == 'left' ? 'start' : 'end'}',
        ));
      case 'TextDirection' when name == 'ltr' && !_compared(node):
        found.add((node, 'TextDirection.ltr → Directionality.of(context)'));
      case 'Icons' when name.startsWith('east') || name.startsWith('west'):
        found.add((
          node,
          'Icons.$name does not mirror → Icons.arrow_forward/arrow_back',
        ));
    }
  }

  /// Whether [node] is only compared against: `dir == TextDirection.ltr`,
  /// or a case of a switch on a direction.
  static bool _compared(AstNode node) {
    final parent = node.parent;
    return parent is ConstantPattern ||
        parent is BinaryExpression &&
            (parent.operator.type == TokenType.EQ_EQ ||
                parent.operator.type == TokenType.BANG_EQ);
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    _text(node, node.value);
    super.visitSimpleStringLiteral(node);
  }

  @override
  void visitInterpolationString(InterpolationString node) {
    _text(node, node.value);
    super.visitInterpolationString(node);
  }

  void _text(AstNode node, String text) {
    for (final glyph in _glyphs) {
      if (text.contains(glyph)) {
        found.add((
          node,
          "'$glyph' in a string does not mirror → a directional icon",
        ));
        return;
      }
    }
  }
}
