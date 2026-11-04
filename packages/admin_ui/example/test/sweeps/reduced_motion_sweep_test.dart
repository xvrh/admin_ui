import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/entries.dart';
import '../support/harness/harness.dart';
import 'sweep.dart';

/// Entries this sweep does not pump, by id, each with the reason and the line
/// a fix starts from.
const _skipped = <String, String>{};

/// Entries that still schedule a frame after the fixed pumps with animations
/// off, by id, each with why. None of them animates: each is a demo
/// finishing what it set in motion, so each is given [_settleFrames] more
/// frames to go still.
const _stillExempt = <String, String>{
  'Preview / Interaction states':
      'pins its focused and edited cells by driving the table from a '
      'post-frame callback, one key per frame, and the last focus change '
      'lands after the fixed pumps: '
      'example/lib/src/ui/collection/table/data_table_interaction.dart:81; '
      'demo-states owns it',
  'Preview / Library — paginated':
      'its fake fetch completes on a demo timer during the last pump, and the '
      "grid's new extent is reported a frame later: "
      'example/lib/src/ui/assets/asset_browse_states.dart:272',
};

/// The frames an entry in [_stillExempt] gets after the fixed pumps.
const _settleFrames = 3;

/// Every demo with the platform asking for less motion: it must not throw,
/// and once the fixed pumps are over nothing may still schedule frames, so
/// no spinner, bar, pulse or transition is left running.
void main() {
  sweep(
    passes: (_) => {
      'reduced motion': RenderConfig.of(
        'Iris',
        ThemeMode.light,
      ).copyWith(disableAnimations: true),
    },
    skipped: _skipped,
    check: (tester, entry) async {
      if (_stillExempt.containsKey(entry.id)) {
        for (var i = 0; i < _settleFrames; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }
      expect(
        tester.binding.hasScheduledFrame,
        isFalse,
        reason:
            '${entry.id} still schedules frames with animations off: hold it '
            'still with motionDuration, spinnerValue or StillLinearProgress '
            '(lib/src/common/motion.dart)',
      );
    },
  );

  test('every still-exempt id names a demo this sweep pumps', () {
    final ids = {for (final entry in demoEntries()) entry.id};
    expect([
      for (final id in _stillExempt.keys)
        if (!ids.contains(id) || _skipped.containsKey(id)) id,
    ], isEmpty);
  });
}
