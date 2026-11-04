import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

/// Files whose literals are names, not prose: the theme files name their
/// themes. Paths are relative to lib/src; one ending in '/' covers the
/// directory.
const _names = {'theme/themes/'};

void main() {
  test('lib/src shows no English literal a user reads', () {
    // A literal in a label, a tooltip or a default is English for every
    // user, and only a fork can change it. Each string resolves through a
    // label parameter, then MaterialLocalizations, then
    // context.adminL10n (lib/src/l10n), where it has French and Arabic too.
    //
    // A string no one reads (text measured for its metrics, say) says so
    // with a `// Not user-facing: <reason>` comment on its line or the line
    // above.
    final offenders = <String, List<String>>{};
    for (final entity in Directory('lib/src').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      final relative = path.substring('lib/src/'.length);
      if (relative.startsWith('l10n/')) continue;
      if (_names.any(
        (p) => p.endsWith('/') ? relative.startsWith(p) : relative == p,
      )) {
        continue;
      }
      final source = entity.readAsStringSync();
      final unit = parseString(
        content: source,
        featureSet: FeatureSet.latestLanguageVersion(),
        throwIfDiagnostics: false,
      ).unit;
      final lines = source.split('\n');
      final visitor = _UserFacingLiterals();
      unit.accept(visitor);
      for (final (node, where) in visitor.found) {
        final line = unit.lineInfo.getLocation(node.offset).lineNumber;
        if (_notShown(lines, line)) continue;
        (offenders[path] ??= []).add('  $line: $where ${node.toSource()}');
      }
    }

    final files = offenders.keys.toList()..sort();
    final count = offenders.values.fold(0, (n, l) => n + l.length);
    expect(
      offenders,
      isEmpty,
      reason:
          '$count English literals in ${files.length} files. Take the text '
          'from a label parameter, MaterialLocalizations or '
          'context.adminL10n (add it to your section in lib/src/l10n, with '
          'French and Arabic).'
          '\n\n${[for (final f in files) '$f\n${offenders[f]!.join('\n')}'].join('\n\n')}',
    );
  });
}

/// Whether line [line] (1-based), or the one above it, carries the
/// `// Not user-facing:` escape.
bool _notShown(List<String> lines, int line) {
  bool marked(int i) =>
      i >= 1 &&
      i <= lines.length &&
      lines[i - 1].contains('// Not user-facing:');
  return marked(line) || marked(line - 1);
}

/// The literals in the places a user reads them: an argument to a widget or
/// value class (`Text('Save')`, `Button('Retry')`, `MenuItem('Rename')`), a
/// label-like named argument (`tooltip:`, `semanticLabel:`, `hintText:`,
/// `text:`...), and a parameter's default (`this.hint = 'Search'`).
class _UserFacingLiterals extends RecursiveAstVisitor<void> {
  final found = <(StringLiteral, String)>[];

  static const _labels = {
    'tooltip',
    'label',
    'semanticLabel',
    'message',
    'hintText',
    'barrierLabel',
    'title',
    'text',
    'hint',
    'status',
    'error',
    'placeholder',
    'name',
  };

  /// Named arguments ending so carry text too: `semanticsLabel:`,
  /// `overflowMenuLabel:`, `filterHint:`.
  static final _labelLike = RegExp(r'(Label|Hint|Text|Message|Title|Tooltip)$');

  /// Classes whose string arguments no user reads: debug names, errors,
  /// keys, patterns and formats.
  static final _notUserFacing = RegExp(
    r'^(Expando|RegExp|Uri|Locale|Logger|Intl|FocusNode|FocusScopeNode|'
    r'\w*(Error|Exception|Key|Format|Property))$',
  );

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _call(node.constructorName.toSource(), node.argumentList);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.target;
    _call(
      target == null
          ? node.methodName.name
          : '${target.toSource()}.${node.methodName.name}',
      node.argumentList,
    );
    super.visitMethodInvocation(node);
  }

  /// A call to a class (a constructor, or a static method such as
  /// `SemanticsService.sendAnnouncement`): its positional strings.
  void _call(String callee, ArgumentList arguments) {
    final type = callee.split('.').first;
    if (!RegExp('^[A-Z]').hasMatch(type) || _notUserFacing.hasMatch(type)) {
      return;
    }
    for (final argument in arguments.arguments) {
      if (argument is Expression) _check(argument, '$callee(…)');
    }
  }

  @override
  void visitNamedArgument(NamedArgument node) {
    final name = node.name.lexeme;
    if (name != 'debugLabel' &&
        (_labels.contains(name) || _labelLike.hasMatch(name))) {
      _check(node.argumentExpression, '$name:');
    }
    super.visitNamedArgument(node);
  }

  @override
  void visitFormalParameterDefaultClause(FormalParameterDefaultClause node) {
    _check(node.value, 'default');
    super.visitFormalParameterDefaultClause(node);
  }

  /// Records the English literals [expression] evaluates to, looking through
  /// the conditionals and fallbacks that choose between them.
  void _check(Expression expression, String where) {
    switch (expression) {
      case StringLiteral() when _english(expression):
        found.add((expression, where));
      case ConditionalExpression(:final thenExpression, :final elseExpression):
        _check(thenExpression, where);
        _check(elseExpression, where);
      case BinaryExpression(:final leftOperand, :final rightOperand):
        _check(leftOperand, where);
        _check(rightOperand, where);
      case ParenthesizedExpression(:final expression):
        _check(expression, where);
      case SwitchExpression(:final cases):
        for (final c in cases) {
          _check(c.expression, where);
        }
      default:
    }
  }

  /// Whether [literal] starts with a capital letter and holds a word: 'Save',
  /// 'No results for $query', but not 'px', a lone 'A' or '$count'.
  static bool _english(StringLiteral literal) {
    final text = switch (literal) {
      SimpleStringLiteral(:final value) => value,
      StringInterpolation(:final elements) => [
        for (final e in elements)
          if (e is InterpolationString) e.value else '\u0000',
      ].join(),
      AdjacentStrings(:final strings) => [
        for (final s in strings)
          if (s is SimpleStringLiteral) s.value else '\u0000',
      ].join(),
    };
    return RegExp(r'^[A-Z]').hasMatch(text) &&
        RegExp('[A-Za-z]{2,}').hasMatch(text);
  }
}
