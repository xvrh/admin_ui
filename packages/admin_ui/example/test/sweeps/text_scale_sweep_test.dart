import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/entries.dart';
import '../support/harness/harness.dart';
import 'clipped_text.dart';
import 'sweep.dart';

/// Entries this sweep does not pump, by id, each with the reason and the line
/// a fix starts from.
const _skipped = <String, String>{
  'Labs / Lane field':
      'a lane row gives its workflow hint its natural width beside an '
      'Expanded value, and at twice the size "Source changed since this was '
      'translated · Re-translate" alone is wider than the row; the lane code '
      'also wraps in its fixed 26px box. Needs the hint under the row when it '
      'does not fit: example/lib/labs/lane_field_lab.dart:646 and :602',
  'Preview / Shell (phone width)':
      "on a 360px phone the demo's brand and its New action leave the top "
      "bar's middle 6px, and the search icon (32px) overflows it. Needs a "
      'rule for which gives way (the brand folding to its mark, or search '
      'moving into a menu): lib/src/shell/ui/top_bar.dart:193',
  'Preview / Shell (phone, drawer open)':
      'the phone-width frame above under its open drawer: the same top bar, '
      'which overflows the same way',
};

/// Text known to clip at twice the size, by the file it is written in
/// (relative to `packages/admin_ui`), each with the reason. Any other text
/// whose glyphs a box cuts off fails the entry it is in.
const _clipped = <String, String>{};

/// Every demo at twice the platform's text size: a row or a control of fixed
/// height clips its label there first, and a label with no room to wrap or
/// ellipsize overflows. Besides exceptions, the check fails on text a box
/// clips without reporting it (see [clippedText]).
///
/// Two passes: Iris, and Ant, whose ramp has the tallest lines (14/22) in
/// the smallest controls (24).
void main() {
  final checked = <String>{};
  final hit = <String>{};

  sweep(
    passes: (_) => {
      'text x2': RenderConfig.of(
        'Iris',
        ThemeMode.light,
      ).copyWith(textScale: 2),
      'text x2 · Ant': RenderConfig.of(
        'Ant',
        ThemeMode.light,
      ).copyWith(textScale: 2),
    },
    skipped: _skipped,
    check: (tester, entry) async {
      checked.add(entry.id);
      final unexpected = <ClippedText>[];
      for (final clip in clippedText(tester)) {
        final file = clip.site.split(':').first;
        if (_clipped.containsKey(file)) {
          hit.add(file);
        } else {
          unexpected.add(clip);
        }
      }
      expect(
        unexpected,
        isEmpty,
        reason:
            '${entry.id} clips text at twice the size. Grow the box with its '
            'text (textGrowthOf in lib/src/common/text_metrics.dart), or list '
            'the file in _clipped with the reason',
      );
    },
  );

  // Only a full run sees every entry, so only a full run can tell that a
  // listed file no longer clips.
  tearDownAll(() {
    final pumped = demoEntries().where((e) => !_skipped.containsKey(e.id));
    if (!pumped.every((entry) => checked.contains(entry.id))) return;
    expect(
      _clipped.keys.where((file) => !hit.contains(file)),
      isEmpty,
      reason: 'These no longer clip: drop them from _clipped',
    );
  });
}
