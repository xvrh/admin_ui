import 'package:admin_ui/admin_ui.dart';
import 'package:admin_ui/l10n/de.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

const _kitLanguages = AdminLanguages([adminEn, adminFr, adminAr, adminDe]);

// The time a DateBody displays is on its locale's own clock: 12-hour with
// its day period where the locale writes one, as a chart's time axis is.
// The editor under it keeps a 24-hour clock in every locale.

final _afternoon = DateTime(2026, 6, 18, 14, 30);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(irisTheme.tokens),
      locale: locale,
      supportedLocales: [
        ..._kitLanguages.locales,
        const Locale('en', 'GB'),
        const Locale('de'),
      ],
      localizationsDelegates: _kitLanguages.delegates,
      home: Scaffold(
        body: Align(
          alignment: AlignmentDirectional.topStart,
          child: SizedBox(width: 360, child: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Widget _field(
  DateTime? value, {
  DateGranularity granularity = DateGranularity.dateTime,
  String? locale,
  bool readOnly = false,
}) => DateBody(
  value: value,
  granularity: granularity,
  locale: locale,
  onChanged: readOnly ? null : (_) {},
);

/// What the closed field shows.
String _shown(WidgetTester tester) => tester
    .widget<Text>(
      find.descendant(of: find.byType(DateBody), matching: find.byType(Text)),
    )
    .data!;

/// The editor cell showing [token] as its hint.
Finder _cell(String token) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == token,
);

/// A [DateBody] that keeps its value, as a form's field does.
class _Live extends StatefulWidget {
  const _Live();

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  DateTime? _value = _afternoon;

  @override
  Widget build(BuildContext context) => DateBody(
    value: _value,
    granularity: DateGranularity.dateTime,
    onChanged: (v) => setState(() => _value = v),
  );
}

void main() {
  setUpAll(initializeDateFormatting);

  group('a 12-hour locale', () {
    testWidgets('a date and time ends in the hour with its day period', (
      tester,
    ) async {
      await _pump(tester, _field(_afternoon));
      final shown = _shown(tester);
      expect(shown, startsWith('Jun 18, 2026 2:30'));
      expect(shown, endsWith('PM'));
      expect(shown, isNot(contains('14')));
      // What intl writes for the locale, date then time.
      expect(shown, DateFormat.yMMMd('en').add_jm().format(_afternoon));
    });

    testWidgets('a time alone is the locale\'s time of day', (tester) async {
      Future<String> at(int hour, int minute) async {
        await _pump(
          tester,
          _field(
            DateTime(2026, 1, 1, hour, minute),
            granularity: DateGranularity.time,
          ),
        );
        return _shown(tester);
      }

      final morning = await at(7, 0);
      expect(morning, startsWith('7:00'));
      expect(morning, endsWith('AM'));

      // Midnight and noon are both twelve.
      final midnight = await at(0, 5);
      expect(midnight, startsWith('12:05'));
      expect(midnight, endsWith('AM'));
      final noon = await at(12, 0);
      expect(noon, startsWith('12:00'));
      expect(noon, endsWith('PM'));

      final evening = await at(23, 59);
      expect(evening, startsWith('11:59'));
      expect(evening, endsWith('PM'));
    });

    testWidgets('a read-only field writes it the same way', (tester) async {
      await _pump(tester, _field(_afternoon, readOnly: true));
      expect(
        _shown(tester),
        DateFormat.yMMMd('en').add_jm().format(_afternoon),
      );
    });

    testWidgets('Arabic writes its own day period, in the kit\'s digits', (
      tester,
    ) async {
      await _pump(tester, _field(_afternoon), locale: const Locale('ar'));
      final shown = _shown(tester);
      expect(shown, contains('2:30'));
      expect(shown, endsWith('م'));
      expect(shown, isNot(contains('14')));
      // A count beside it is in Latin digits, so the date is too.
      expect(shown, contains('2026'));
    });
  });

  group('a 24-hour locale is as it was', () {
    for (final (locale, text) in const [
      (Locale('en', 'GB'), '18 Jun 2026 14:30'),
      (Locale('fr'), '18 juin 2026 14:30'),
      (Locale('de'), '18. Juni 2026 14:30'),
    ]) {
      testWidgets('$locale', (tester) async {
        await _pump(tester, _field(_afternoon), locale: locale);
        expect(_shown(tester), text);
      });
    }

    testWidgets('a time alone', (tester) async {
      await _pump(
        tester,
        _field(DateTime(2026, 1, 1, 7, 5), granularity: DateGranularity.time),
        locale: const Locale('fr'),
      );
      expect(_shown(tester), '07:05');
    });
  });

  group('the locale given to the field decides, not the app\'s', () {
    testWidgets('en_GB in an English app is 24-hour', (tester) async {
      await _pump(tester, _field(_afternoon, locale: 'en_GB'));
      expect(_shown(tester), '18 Jun 2026 14:30');
    });

    testWidgets('en_US in a French app is 12-hour', (tester) async {
      await _pump(
        tester,
        _field(_afternoon, locale: 'en_US'),
        locale: const Locale('fr'),
      );
      final shown = _shown(tester);
      expect(shown, startsWith('Jun 18, 2026 2:30'));
      expect(shown, endsWith('PM'));
    });
  });

  testWidgets('a date alone shows no time', (tester) async {
    await _pump(tester, _field(_afternoon, granularity: DateGranularity.date));
    expect(_shown(tester), 'Jun 18, 2026');
  });

  group('the editor keeps a 24-hour clock', () {
    testWidgets('its hour cell reads 14 under a field that reads 2:30 PM', (
      tester,
    ) async {
      await _pump(tester, const _Live());
      await tester.tap(find.byType(DateBody));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(_cell('HH')).controller!.text, '14');
      expect(find.text('MM / DD / YYYY · HH : MM'), findsOneWidget);
    });

    testWidgets('an hour typed there is read on that clock', (tester) async {
      await _pump(tester, const _Live());
      await tester.tap(find.byType(DateBody));
      await tester.pumpAndSettle();

      Future<String> type(String hour) async {
        await tester.enterText(_cell('HH'), hour);
        await tester.pump();
        return tester.widget<Text>(find.textContaining('Jun 18, 2026')).data!;
      }

      final morning = await type('9');
      expect(morning, startsWith('Jun 18, 2026 9:30'));
      expect(morning, endsWith('AM'));

      final evening = await type('21');
      expect(evening, startsWith('Jun 18, 2026 9:30'));
      expect(evening, endsWith('PM'));
    });
  });
}
