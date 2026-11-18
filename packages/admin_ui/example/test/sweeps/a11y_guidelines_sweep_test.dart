import 'dart:developer';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/entries.dart';
import '../support/harness/harness.dart';
import 'sweep.dart';

/// WCAG 2.2 SC 2.5.8: a pointer target of at least 24 by 24 CSS pixels.
const _targetSize = MinimumTapTargetGuideline(
  size: Size(24, 24),
  link: 'https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum',
);

const _labelled = 'labelled targets';
const _sized = '24px targets';

/// The guidelines every demo is held to, by the name an exemption gives.
///
/// Flutter's `textContrastGuideline` is not one of them. It takes the two
/// commonest colours in a node's box for the text and what is behind it,
/// and in a box that holds a border, a stripe or a glyph or two that pair
/// is not the text's: run over every demo it failed 37 of 217, on pairs such
/// as a field's fill against its outline (Material's search field, 4.35:1)
/// and a cell's fill against its row rule (an em dash in a table, 1.15:1).
/// Text contrast is held by the kit's own tests: the palette's pairs in
/// every theme, mode and brand (`test/palettes_contrast_test.dart` and the
/// tests beside it), and that guideline over the exhibits it reads well
/// (`test/sweep_a11y_guidelines_test.dart`).
const _guidelines = <String, AccessibilityGuideline>{
  _labelled: labeledTapTargetGuideline,
  _sized: _targetSize,
};

/// Entries this sweep does not pump, by id, each with the reason and the line
/// a fix starts from.
const _skipped = <String, String>{};

const _bareCheck =
    'a Check with no label beside it is its box, 16 or 18px by the theme, '
    "and so are the row and select-all boxes of a table, each alone in its "
    'cell. Needs the target grown past the box: '
    'lib/src/common/ui/checkbox.dart:73';

const _bareToggle =
    'a Toggle with no label beside it is its track, 18 to 22px tall in '
    'every theme but Material and Carbon. Needs the target grown past the '
    'track: lib/src/common/ui/toggle.dart:65';

const _textLink =
    'a TextLink is as tall as its line of text, 16 to 18px. In a sentence '
    'WCAG 2.5.8 exempts it (a target in running text), and Flutter exempts a '
    'node flagged as a link, which one that runs an action is not. A column '
    'of them is no sentence: the rows of a ValidationSummary, a line apart, '
    'are short of the criterion. Needs a row 24px tall: '
    'lib/src/forms/validation_summary.dart, lib/src/common/ui/text_link.dart';

/// Targets a guideline is not held to wherever they are drawn, by the
/// guideline's name, then by what draws them: a widget of the kit's, or the
/// file a target is written in (relative to `packages/admin_ui`), found
/// among the three widgets nearest above the target that the package
/// creates. Each with the reason and the line a fix starts from. Growing a
/// target moves pixels, and is not this sweep's to do.
const _exemptTargets = <String, Map<String, String>>{
  _labelled: {
    'lib/src/common/ui/choice.dart':
        "the control-states page draws a radio with an empty label, to show "
        "the dot alone in each state, and a ChoiceOption has no name but its "
        'label. Needs a semantic label on the option: '
        'lib/src/common/ui/choice.dart:35',
  },
  _sized: {
    'Check': _bareCheck,
    'Toggle': _bareToggle,
    'TextLink': _textLink,
    'lib/src/shell/ui/save_cluster.dart':
        'the save status, "2 fields need attention", is a link as tall as '
        "its line, 16px, in the save bar's row of 32px controls. Needs the "
        'row height as its target: lib/src/shell/ui/save_cluster.dart:500',
    'lib/src/common/ui/segmented.dart':
        "Fluent's small segmented control is 24px tall with a 1px border, so "
        'a segment inside it is 22px. Needs the segment to take the '
        "control's height: lib/src/common/ui/segmented.dart:376",
    'lib/src/fields/ui/tags_body.dart':
        "a tags field's input is announced as its line of text, 18 to 20px, "
        "inside the field's box of 32px or more, which takes the pointer. "
        'Not checked: whether a switch-access user reaches the box. '
        'lib/src/fields/ui/tags_body.dart',
    'LaneLanguage':
        "a translation lane's text field is announced as its line of text, "
        '18 to 22px, inside a lane row that is taller. Not checked: whether '
        'the row takes the pointer around the line. '
        'lib/src/fields/ui/source_target_pair.dart',
    'example/lib/labs/lane_field_lab.dart':
        "a lab's own links, each as tall as its line of text (16px): a lab "
        'is a sketch, not a widget the kit ships',
  },
};

/// Guidelines one demo is not held to, by its id then the guideline's name,
/// each with the reason: something the demo does, not a widget.
const _exemptEntries = <String, Map<String, String>>{
  'Foundations / Stock Material': {
    _labelled:
        "stock Material's Checkbox, Radio and Switch, bare beside the kit's "
        "to compare their look: not the kit's controls",
  },
  'Primitives / Feedback / Modal sizes': {
    _sized:
        'the page draws every modal size scaled down to fit them side by '
        'side, so a 32px button measures 24px or less',
  },
};

final _node = RegExp(r'SemanticsNode#(\d+)\(');

/// Every demo against Flutter's accessibility guidelines for targets, each
/// in its [homeCombo], so every theme and mode is checked: whatever takes a
/// tap or a long press has a name, and is at least 24 by 24.
///
/// The demo is pumped with its semantics on, so a node the framework
/// refuses fails it too: a role where it cannot go, a list item outside a
/// list, an alert that is a live region.
///
/// A target that fails is reported with what draws it. It is fixed, or
/// listed in [_exemptTargets] or [_exemptEntries] with its reason.
void main() {
  final checked = <String>{};
  final used = <(String, String)>{};

  sweep(
    semantics: true,
    passes: (entry) => {'${homeCombo(entry)} · guidelines': homeCombo(entry)},
    skipped: _skipped,
    check: (tester, entry) async {
      checked.add(entry.id);
      final problems = <String>[];
      for (final MapEntry(key: name, value: guideline) in _guidelines.entries) {
        final evaluation = await guideline.evaluate(tester);
        if (evaluation.passed) continue;
        if (_exemptEntries[entry.id]?.containsKey(name) ?? false) {
          used.add((entry.id, name));
          continue;
        }
        final exempt = _exemptTargets[name] ?? const {};
        for (final target in _targets(tester, evaluation.reason ?? '')) {
          final key = target.drawnBy.where(exempt.containsKey).firstOrNull;
          if (key != null) {
            used.add((name, key));
          } else {
            problems.add('$name: $target');
          }
        }
      }
      expect(
        problems,
        isEmpty,
        reason:
            '${entry.id} has targets short of a guideline. Fix them, or list '
            'what draws them in _exemptTargets with the reason',
      );
    },
  );

  // Only a full run sees every entry, so only a full run can tell that an
  // exemption no longer exempts anything.
  tearDownAll(() {
    final pumped = demoEntries().where((e) => !_skipped.containsKey(e.id));
    if (!pumped.every((entry) => checked.contains(entry.id))) return;
    expect(
      [
        for (final MapEntry(key: name, value: targets)
            in _exemptTargets.entries)
          for (final key in targets.keys)
            if (!used.contains((name, key))) '$name: $key',
        for (final MapEntry(key: id, value: guidelines)
            in _exemptEntries.entries)
          for (final name in guidelines.keys)
            if (!used.contains((id, name))) '$id: $name',
      ],
      isEmpty,
      reason: 'These exemptions exempt nothing now: drop them',
    );
  });

  test('every exempted entry names a demo', () {
    final ids = {for (final entry in demoEntries()) entry.id};
    expect(_exemptEntries.keys.where((id) => !ids.contains(id)), isEmpty);
  });
}

/// A target a guideline failed, and what draws it.
class _Target {
  final String label;
  final Size size;

  /// The widgets nearest above the target that `packages/admin_ui` creates,
  /// each as its type and as the file it is written in.
  final List<String> drawnBy;

  _Target(this.label, this.size, this.drawnBy);

  @override
  String toString() =>
      '"$label", ${size.width.toStringAsFixed(1)} by '
      '${size.height.toStringAsFixed(1)}, drawn by ${drawnBy.join(', ')}';
}

/// The targets [reason], a guideline's report, names by their semantics
/// node. The report is all a guideline gives, as one text.
List<_Target> _targets(WidgetTester tester, String reason) {
  final ids = {
    for (final match in _node.allMatches(reason)) int.parse(match.group(1)!),
  };
  final targets = <_Target>[];
  for (final element in tester.allElements) {
    if (element is! RenderObjectElement) continue;
    final node = element.renderObject.debugSemantics;
    // The outermost render object of a node is the widget that makes it.
    if (node == null || !ids.remove(node.id)) continue;
    final drawnBy = <String>[];
    var widgets = 0;
    element.visitAncestorElements((ancestor) {
      final file = CreationLocation.of(ancestor.widget)?.file;
      final type = '${ancestor.widget.runtimeType}'.split('<').first;
      if (file == null ||
          !file.contains('packages/admin_ui/') ||
          type.startsWith('_')) {
        return true;
      }
      drawnBy
        ..add(type)
        ..add(file.split('packages/admin_ui/').last);
      return ++widgets < 3;
    });
    targets.add(_Target(node.label, node.rect.size, drawnBy));
  }
  expect(ids, isEmpty, reason: 'No widget found for these semantics nodes');
  return targets;
}
