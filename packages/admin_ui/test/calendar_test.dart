import 'package:admin_ui/src/common/ui/calendar.dart';
import 'package:admin_ui/src/theme/theme.dart';
import 'package:admin_ui/src/theme/themes/shadcn.dart';
import 'package:admin_ui/src/theme/tokens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: 300, child: child)),
  ),
);

final _today = DateTime(2026, 6, 12);

void main() {
  testWidgets('single mode reports the tapped day', (tester) async {
    DateTime? picked;
    await tester.pumpWidget(
      _host(
        Calendar(
          today: _today,
          value: DateTime(2026, 6, 12),
          onChanged: (d) => picked = d,
        ),
      ),
    );
    await tester.tap(find.text('18'));
    expect(picked, DateTime(2026, 6, 18));
  });

  testWidgets('range mode: two taps emit an ordered DateTimeRange', (
    tester,
  ) async {
    DateTimeRange? range;
    await tester.pumpWidget(
      _host(
        Calendar(
          mode: CalendarMode.range,
          today: _today,
          onRangeChanged: (r) => range = r,
        ),
      ),
    );

    // Tap the later day first to prove the result is ordered. Days 12–30 are
    // unique in this grid (it runs from Sunday May 31 to Saturday July 11).
    await tester.tap(find.text('21'));
    await tester.pump();
    expect(range, isNull); // not emitted until the second tap
    await tester.tap(find.text('14'));
    await tester.pump();

    expect(range!.start, DateTime(2026, 6, 14));
    expect(range!.end, DateTime(2026, 6, 21));
  });

  testWidgets('bounds disable days outside [min, max]', (tester) async {
    DateTime? picked;
    await tester.pumpWidget(
      _host(
        Calendar(
          today: _today,
          min: DateTime(2026, 6, 10),
          max: DateTime(2026, 6, 24),
          onChanged: (d) => picked = d,
        ),
      ),
    );

    await tester.tap(find.text('28')); // after max — disabled
    expect(picked, isNull);
    await tester.tap(find.text('16')); // in range
    expect(picked, DateTime(2026, 6, 16));
  });

  testWidgets(
    'range mode paints a visible band in the soft primary',
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
    (tester) async {
      await tester.pumpWidget(
        _host(
          Calendar(
            mode: CalendarMode.range,
            today: _today,
            range: DateTimeRange(
              start: DateTime(2026, 6, 10),
              end: DateTime(2026, 6, 21),
            ),
            onRangeChanged: (_) {},
          ),
        ),
      );
      final soft = tester.element(find.byType(Calendar)).colors.primarySubtle;
      final bands = find.byWidgetPredicate(
        (w) =>
            w is DecoratedBox &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).color == soft,
      );
      expect(bands, findsWidgets);
      expect(tester.getSize(bands.first).height, 32);
    },
  );

  testWidgets('header shows the month of the seeded value', (tester) async {
    await tester.pumpWidget(
      _host(
        Calendar(
          today: _today,
          value: DateTime(2026, 6, 18),
          onChanged: (_) {},
        ),
      ),
    );
    expect(find.text('June 2026'), findsOneWidget);
  });

  testWidgets('day colours come from the palette roles', (tester) async {
    const palette = shadcnDarkPalette;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(AdminTokens.from(palette: palette)),
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: Calendar(
              today: _today,
              value: DateTime(2026, 6, 18),
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    Color color(String text) =>
        tester.widget<Text>(find.text(text).first).style!.color!;

    expect(color('18'), palette.onControlAccent, reason: 'selected day');
    expect(color('12'), palette.primaryText, reason: 'today');
    expect(color('M'), palette.foregroundMuted, reason: 'weekday header');
    expect(color('11'), palette.foregroundSecondary, reason: 'another day');
    expect(
      color('31'),
      palette.foregroundMutedOnTint,
      reason: 'a day of the month before',
    );
  });
}
