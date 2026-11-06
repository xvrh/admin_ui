import 'package:admin_ui/ui.dart' show CursorRegion, Tappable;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/harness/harness.dart';
import 'sweep.dart';

/// Entries this sweep does not pump, by id, each with the reason and the line
/// a fix starts from.
const _skipped = <String, String>{
  'Foundations / Stock Material':
      "Flutter's own buttons, tabs and list tiles, which the kit styles but "
      'does not build: under a SelectionArea their labels stay selectable, '
      "as in any Flutter app, and no theme setting changes that. The kit's "
      'own targets opt out through CursorRegion '
      '(lib/src/common/ui/tappable.dart).',
};

/// Every demo under a `SelectionArea`, as a page an app lets its users select
/// text on: no [Text] under a tap target may take part in the selection. A
/// selectable Text drags into the selection and shows the I-beam, and a tap
/// target (a [Tappable], a [CursorRegion], an [InkWell], a [GestureDetector]
/// that takes taps) is no place for either: it takes its text out with
/// [SelectionContainer.disabled], as [CursorRegion] does.
void main() {
  sweep(
    passes: (entry) {
      final config = homeCombo(entry).copyWith(selectable: true);
      return {'$config': config};
    },
    skipped: _skipped,
    check: (tester, entry) async {
      final offenders = <String>[];
      for (final element in tester.allElements) {
        final widget = element.widget;
        if (widget is! Text) continue;
        final scope = element
            .getInheritedWidgetOfExactType<SelectionRegistrarScope>();
        if (scope?.registrar == null) continue;
        final target = _targetAbove(element);
        if (target == null) continue;
        offenders.add('${siteOf(element)} "${_textOf(widget)}" under $target');
      }
      expect(
        offenders,
        isEmpty,
        reason:
            '${entry.id} lets text under a tap target be selected. Route the '
            'target through Tappable or CursorRegion, or wrap its content in '
            'SelectionContainer.disabled (see CursorRegion):\n  '
            '${offenders.join('\n  ')}',
      );
    },
  );
}

/// The nearest tap target above [element], by type, or null.
String? _targetAbove(Element element) {
  String? found;
  element.visitAncestorElements((ancestor) {
    final widget = ancestor.widget;
    final isTarget = switch (widget) {
      Tappable() => true,
      CursorRegion(:final cursor) => cursor != MouseCursor.defer,
      InkResponse() => true,
      GestureDetector(:final onTap, :final onDoubleTap, :final onLongPress) =>
        onTap != null || onDoubleTap != null || onLongPress != null,
      _ => false,
    };
    if (isTarget) found = '${widget.runtimeType}';
    return !isTarget;
  });
  return found;
}

String _textOf(Text text) {
  final plain = text.data ?? text.textSpan?.toPlainText() ?? '';
  return plain.length > 40 ? '${plain.substring(0, 39)}…' : plain;
}
