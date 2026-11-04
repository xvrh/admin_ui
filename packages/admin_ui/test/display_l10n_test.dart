import 'dart:async';

import 'package:admin_ui/admin_ui.dart';
import 'package:admin_ui/src/common/ui/upload.dart' show formatBytes;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// Hosts [child] in [locale], with the kit's delegates unless [delegates] is
/// false, when only Material's are registered.
Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Locale? locale,
  bool delegates = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(defaultTokens),
      locale: locale,
      supportedLocales: AdminLocalizations.supportedLocales,
      localizationsDelegates: delegates
          ? AdminLocalizations.localizationsDelegates
          : GlobalMaterialLocalizations.delegates,
      home: Scaffold(
        body: SingleChildScrollView(child: SizedBox(width: 640, child: child)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _base = VersionRef(
  id: 'a',
  label: 'A',
  author: 'Ann',
  initials: 'AN',
  timestamp: 'yesterday',
  status: VersionStatus.published,
);

const _compare = VersionRef(
  id: 'b',
  label: 'B',
  author: 'Bo',
  initials: 'BO',
  timestamp: 'now',
  status: VersionStatus.draft,
);

/// An object with [n] members.
Map<String, int> _keys(int n) => {for (var i = 0; i < n; i++) 'k$i': i};

void main() {
  group('JsonView counts in the plural rules of the language', () {
    testWidgets('French: 0 and 1 are singular, 3 plural', (tester) async {
      for (final (n, text) in [(0, '0 clé'), (1, '1 clé'), (3, '3 clés')]) {
        await _pump(
          tester,
          JsonView(data: _keys(n)),
          locale: const Locale('fr'),
        );
        expect(find.text('{ } $text'), findsOneWidget, reason: '$n');
      }
      await _pump(
        tester,
        const JsonView(data: [1, 2]),
        locale: const Locale('fr'),
      );
      expect(find.text('[ ] 2 éléments'), findsOneWidget);
    });

    testWidgets('Arabic: one, two, few, many and other', (tester) async {
      for (final (n, text) in [
        (1, 'مفتاح واحد'),
        (2, 'مفتاحان'),
        (3, '3 مفاتيح'),
        (11, '11 مفتاحًا'),
        (100, '100 مفتاح'),
      ]) {
        await _pump(
          tester,
          JsonView(data: _keys(n)),
          locale: const Locale('ar'),
        );
        expect(find.text('{ } $text'), findsOneWidget, reason: '$n');
      }
    });

    testWidgets('a folded row counts too, in its own direction', (
      tester,
    ) async {
      await _pump(
        tester,
        JsonView(
          data: {
            'items': [_keys(2)],
          },
        ),
        locale: const Locale('ar'),
      );
      // The nested object folds at depth 2, isolated inside the code line.
      expect(find.textContaining('\u2068مفتاحان\u2069'), findsOneWidget);
    });

    testWidgets('the toolbar is translated', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, JsonView(data: _keys(1)), locale: const Locale('fr'));
      expect(find.bySemanticsLabel('Tout développer'), findsOneWidget);
      expect(find.bySemanticsLabel('Tout réduire'), findsOneWidget);
      expect(find.bySemanticsLabel('Copier le JSON'), findsOneWidget);
      expect(find.text('Rechercher'), findsOneWidget);
      semantics.dispose();
    });
  });

  group('UploadZone', () {
    const done = UploadItem(
      id: 'a',
      name: 'a.png',
      bytes: 757760,
      status: UploadStatus.done,
    );

    testWidgets('Arabic says two uploads in the dual', (tester) async {
      await _pump(
        tester,
        const UploadZone(
          items: [
            done,
            UploadItem(id: 'b', name: 'b.png', status: UploadStatus.done),
          ],
        ),
        locale: const Locale('ar'),
      );
      expect(find.text('تم رفع الملفين'), findsOneWidget);
    });

    testWidgets('Arabic counts one failure in the singular', (tester) async {
      await _pump(
        tester,
        const UploadZone(
          items: [
            done,
            UploadItem(id: 'b', name: 'b.png', status: UploadStatus.error),
            UploadItem(id: 'c', name: 'c.png'),
          ],
        ),
        locale: const Locale('ar'),
      );
      expect(find.text('تم رفع 1 من 3 · تعذّر رفع ملف واحد'), findsOneWidget);
      expect(find.text('في الانتظار'), findsOneWidget);
    });

    testWidgets('a finished row shows its size in SI units', (tester) async {
      await _pump(tester, const UploadZone(items: [done]));
      expect(find.text('Upload complete'), findsOneWidget);
      expect(find.text('758 kB'), findsOneWidget);
    });

    testWidgets('French writes octets and a spaced percent', (tester) async {
      await _pump(
        tester,
        const UploadZone(
          items: [
            done,
            UploadItem(
              id: 'b',
              name: 'b.png',
              status: UploadStatus.uploading,
              progress: 0.42,
            ),
          ],
        ),
        locale: const Locale('fr'),
      );
      expect(find.text('758 ko'), findsOneWidget);
      expect(
        find.text(NumberFormat.percentPattern('fr').format(0.42)),
        findsOneWidget,
      );
    });

    test('formatBytes delegates to the locale formats', () {
      expect(formatBytes(null), '');
      expect(formatBytes(757760, locale: 'en'), '758 kB');
      expect(formatBytes(757760, locale: 'fr'), '758 ko');
    });
  });

  testWidgets('chart ticks are compact in the locale', (tester) async {
    await _pump(
      tester,
      const LineChart(
        series: [
          ChartSeries('Views', [0, 1200]),
        ],
        labels: ['Jan', 'Feb'],
      ),
      locale: const Locale('fr'),
    );
    // A 0–1,200 range takes steps of 500, up to 1,500.
    final fr = NumberFormat.compact(locale: 'fr');
    expect(fr.format(1500), '1,5 k');
    expect(find.text(fr.format(1500)), findsOneWidget);
    expect(find.text(fr.format(1000)), findsOneWidget);
  });

  testWidgets('a time axis names its ticks in the locale, from its week', (
    tester,
  ) async {
    // A French week starts on Monday: 2 March 2026.
    await _pump(
      tester,
      LineChart.time(
        series: [
          ChartTimeSeries('Score', [
            for (var d = 1; d <= 30; d++)
              (DateTime.utc(2026, 3, d), (d % 4).toDouble()),
          ]),
        ],
      ),
      locale: const Locale('fr'),
    );
    final day = DateFormat.MMMd('fr');
    expect(day.format(DateTime.utc(2026, 3, 2)), '2 mars');
    for (final d in [2, 9, 16, 23, 30]) {
      final tick = day.format(DateTime.utc(2026, 3, d));
      expect(find.text(tick), findsOneWidget, reason: tick);
    }
    expect(find.text(day.format(DateTime.utc(2026, 3))), findsNothing);
  });

  testWidgets('a progress bar shows its percent in the locale', (tester) async {
    await _pump(
      tester,
      const ProgressBar(value: 0.62, showPercent: true),
      locale: const Locale('fr'),
    );
    expect(find.text('62 %'), findsOneWidget);
  });

  group('without the delegate everything is English', () {
    testWidgets('defaults and counts', (tester) async {
      await _pump(
        tester,
        Column(
          children: [
            JsonView(data: _keys(3)),
            ErrorState(onRetry: () {}),
            const Steps(
              steps: [StepItem('Account'), StepItem('Profile')],
              current: 1,
            ),
            const SizedBox(
              height: 400,
              child: DiffView(
                diff: VersionDiff(base: _base, compare: _compare, fields: []),
              ),
            ),
          ],
        ),
        locale: const Locale('fr'),
        delegates: false,
      );
      expect(find.text('{ } 3 keys'), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('BEFORE'), findsOneWidget);
      expect(find.text('No changes'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('describeError', () {
    test('words the error in the given language', () {
      expect(
        describeError(TimeoutException('slow'), const AdminLocalizationsFr()),
        'Le serveur a mis trop de temps à répondre. Réessayez.',
      );
      expect(
        describeError(Exception('status 404'), const AdminLocalizationsAr()),
        'لم يُعثر عليه. ربما نُقل أو حُذف.',
      );
      expect(
        describeError(Exception('?'), const AdminLocalizationsFr()),
        'Une erreur s’est produite. Réessayez.',
      );
    });

    testWidgets('ErrorTextScope.describe uses the ambient language', (
      tester,
    ) async {
      late BuildContext context;
      await _pump(
        tester,
        Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
        locale: const Locale('fr'),
      );
      expect(
        ErrorTextScope.describe(context, Exception('status 403')),
        'Vous n’avez pas l’autorisation d’effectuer cette action.',
      );
    });
  });

  testWidgets('breadcrumbs name the collapsed crumbs in the plural', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      const Breadcrumbs([
        Crumb('Home'),
        Crumb('A'),
        Crumb('B'),
        Crumb('C'),
        Crumb('D'),
      ], maxItems: 3),
      locale: const Locale('ar'),
    );
    expect(find.bySemanticsLabel('إظهار 3 عناصر أخرى'), findsOneWidget);
    expect(find.bySemanticsLabel('D، الصفحة الحالية'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('a step announces itself in the language', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      Steps(
        steps: const [StepItem('Compte'), StepItem('Profil')],
        current: 1,
        onChanged: (_) {},
      ),
      locale: const Locale('fr'),
    );
    expect(
      find.bySemanticsLabel('Étape 1 sur 2 : Compte, terminée'),
      findsOneWidget,
    );
    semantics.dispose();
  });
}
