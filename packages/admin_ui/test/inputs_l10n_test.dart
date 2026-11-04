import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// [child] in an app in [locale], with the kit's delegates unless
/// [delegates] is false.
Widget _app(Widget child, {Locale? locale, bool delegates = true}) =>
    MaterialApp(
      theme: buildAppTheme(defaultTokens),
      locale: locale,
      supportedLocales: delegates
          ? AdminLocalizations.supportedLocales
          : const [Locale('en', 'US')],
      localizationsDelegates: delegates
          ? AdminLocalizations.localizationsDelegates
          : null,
      home: Scaffold(
        body: Center(child: SizedBox(width: 640, child: child)),
      ),
    );

const _fr = Locale('fr');

/// The accessible name and tooltip of the only [IconAction] under [of].
String? _actionLabel(WidgetTester tester, Finder of) => tester
    .widget<IconAction>(
      find.descendant(of: of, matching: find.byType(IconAction)),
    )
    .label;

/// Stubs the clipboard, which a test has no platform for.
void _stubClipboard(WidgetTester tester) {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async => null,
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
}

/// Opens [showConfirmDialog] from a button and settles it.
Widget _confirmOpener({String? confirmLabel, String? cancelLabel}) => Builder(
  builder: (context) => TextButton(
    onPressed: () => showConfirmDialog(
      context,
      title: 'Delete page?',
      message: 'This cannot be undone.',
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
    ),
    child: const Text('Ask'),
  ),
);

const _inbox = [
  NotificationItem(title: 'Mentioned you', unread: true),
  NotificationItem(title: 'Build passed', unread: true),
];

void main() {
  group('French, under the delegate', () {
    testWidgets('the password reveal toggle', (tester) async {
      await tester.pumpWidget(_app(const PasswordField(), locale: _fr));
      expect(
        _actionLabel(tester, find.byType(PasswordField)),
        'Afficher le mot de passe',
      );
      await tester.tap(find.byType(IconAction));
      await tester.pump();
      expect(
        _actionLabel(tester, find.byType(PasswordField)),
        'Masquer le mot de passe',
      );
    });

    testWidgets('the search field: Material\'s placeholder, our clear', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const SearchField(), locale: _fr));
      expect(find.text('Rechercher'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'prix');
      await tester.pump();
      expect(
        _actionLabel(tester, find.byType(SearchField)),
        'Effacer la recherche',
      );
    });

    testWidgets('the combobox placeholder, empty list and clear', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Combobox<String>(
            options: const [ComboboxOption('be', 'Belgique')],
            value: null,
            onChanged: (_) {},
          ),
          locale: _fr,
        ),
      );
      expect(find.text('Sélectionner…'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('Aucune correspondance'), findsOneWidget);
    });

    testWidgets('an async combobox says the search found nothing', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Combobox<String>(
            value: null,
            onChanged: (_) {},
            onSearch: (_) async => const [],
          ),
          locale: _fr,
        ),
      );
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('Aucun résultat'), findsOneWidget);
    });

    testWidgets('the date-range picker and its presets', (tester) async {
      await tester.pumpWidget(
        _app(
          DateRangePicker(onChanged: (_) {}, today: DateTime(2026, 6, 12)),
          locale: _fr,
        ),
      );
      expect(find.text('Sélectionner une plage'), findsOneWidget);
      await tester.tap(find.byType(DateRangePicker));
      await tester.pumpAndSettle();
      for (final preset in [
        "Aujourd'hui",
        '7 derniers jours',
        '30 derniers jours',
        'Ce mois-ci',
        'Le mois dernier',
        'Année en cours',
      ]) {
        expect(find.text(preset), findsOneWidget, reason: preset);
      }
      await tester.tap(find.text('7 derniers jours'));
      await tester.pumpAndSettle();
    });

    testWidgets('the calendar follows the app: month, week start, names', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 300,
            child: Calendar(today: DateTime(2026, 6, 12), onChanged: (_) {}),
          ),
          locale: _fr,
        ),
      );
      expect(find.text('juin 2026'), findsOneWidget);
      final weekdays = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(Calendar),
              matching: find.byType(Text),
            ),
          )
          .skip(1)
          .take(7)
          .map((t) => t.data);
      expect(weekdays, ['L', 'M', 'M', 'J', 'V', 'S', 'D']);
    });

    testWidgets('a chosen span reads as one message', (tester) async {
      await tester.pumpWidget(
        _app(
          DateRangePicker(
            value: DateTimeRange(
              start: DateTime(2026, 6, 1),
              end: DateTime(2026, 6, 15),
            ),
            onChanged: (_) {},
          ),
          locale: _fr,
        ),
      );
      expect(find.text('1 juin – 15 juin'), findsOneWidget);
      expect(
        _actionLabel(tester, find.byType(DateRangePicker)),
        'Effacer les dates',
      );
    });

    testWidgets('confirm: Confirmer and Material\'s Annuler', (tester) async {
      await tester.pumpWidget(_app(_confirmOpener(), locale: _fr));
      await tester.tap(find.text('Ask'));
      await tester.pumpAndSettle();
      expect(find.text('Confirmer'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);
    });

    testWidgets('the copy button: Material\'s Copier, then Copié, announced', (
      tester,
    ) async {
      _stubClipboard(tester);
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_app(const CopyButton('usr_42'), locale: _fr));
      expect(tester.widget<Tooltip>(find.byType(Tooltip)).message, 'Copier');
      await tester.tap(find.byType(CopyButton));
      await tester.pump();
      expect(tester.widget<Tooltip>(find.byType(Tooltip)).message, 'Copié');
      final announced = tester.takeAnnouncements();
      expect(announced.map((a) => a.message), ['Copié']);
      expect(announced.single.textDirection, TextDirection.ltr);
      await tester.pump(const Duration(seconds: 2));
      semantics.dispose();
    });

    testWidgets('the notification center', (tester) async {
      await tester.pumpWidget(
        _app(
          NotificationCenter(items: _inbox, onMarkAllRead: () {}),
          locale: _fr,
        ),
      );
      expect(
        _actionLabel(tester, find.byType(NotificationCenter)),
        'Notifications, 2 non lues',
      );
      await tester.tap(find.byType(IconAction));
      await tester.pumpAndSettle();
      expect(find.text('Tout marquer comme lu'), findsOneWidget);
    });

    testWidgets('an empty inbox', (tester) async {
      await tester.pumpWidget(
        _app(const NotificationCenter(items: []), locale: _fr),
      );
      await tester.tap(find.byType(IconAction));
      await tester.pumpAndSettle();
      expect(find.text('Vous êtes à jour'), findsOneWidget);
    });

    testWidgets('the command palette', (tester) async {
      await tester.pumpWidget(
        _app(
          SizedBox(
            height: 480,
            child: CommandPalette(
              items: [
                PaletteItem(
                  id: 'p',
                  title: 'Tarifs',
                  icon: Icons.description_outlined,
                  group: 'Pages',
                  onSelect: () {},
                ),
              ],
              recent: [
                PaletteItem(
                  id: 'r',
                  title: 'Accueil',
                  icon: Icons.description_outlined,
                  group: 'Pages',
                  onSelect: () {},
                ),
              ],
              onDismiss: () {},
            ),
          ),
          locale: _fr,
        ),
      );
      expect(find.text('Rechercher ou aller à…'), findsOneWidget);
      expect(find.text('RÉCENTS'), findsOneWidget);
      for (final hint in ['naviguer', 'sélectionner', 'fermer']) {
        expect(find.text(hint), findsOneWidget, reason: hint);
      }
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('Aucun résultat pour « zzz »'), findsOneWidget);
    });

    testWidgets('the palette announces its count with French plurals', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          SizedBox(
            height: 480,
            child: CommandPalette(
              items: [
                for (final title in ['Tarifs', 'Tableau'])
                  PaletteItem(
                    id: title,
                    title: title,
                    icon: Icons.description_outlined,
                    group: 'Pages',
                    onSelect: () {},
                  ),
              ],
              onDismiss: () {},
            ),
          ),
          locale: _fr,
        ),
      );
      await tester.enterText(find.byType(TextField), 'ta');
      await tester.pump(const Duration(seconds: 1));
      expect(
        tester.takeAnnouncements().map((a) => a.message),
        contains('2 résultats'),
      );
      await tester.enterText(find.byType(TextField), 'tar');
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeAnnouncements().map((a) => a.message), ['1 résultat']);
      semantics.dispose();
    });

    testWidgets('the palette trigger', (tester) async {
      await tester.pumpWidget(_app(CommandTrigger(onTap: () {}), locale: _fr));
      expect(find.text('Rechercher…'), findsOneWidget);
    });

    testWidgets('the side sheet scrim is Material\'s', (tester) async {
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showSideSheet(
                context,
                builder: (_) => const SideSheet(child: SizedBox()),
              ),
              child: const Text('Open'),
            ),
          ),
          locale: _fr,
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<ModalBarrier>(find.byType(ModalBarrier))
            .map((b) => b.semanticsLabel),
        contains('Ignorer'),
      );
    });
  });

  group('Arabic', () {
    testWidgets('strings come from the Arabic section', (tester) async {
      await tester.pumpWidget(
        _app(const PasswordField(), locale: const Locale('ar')),
      );
      expect(
        _actionLabel(tester, find.byType(PasswordField)),
        'إظهار كلمة المرور',
      );
    });

    test('counts use all six plural forms', () {
      const ar = InputsMessagesAr();
      expect(
        [
          for (final n in [0, 1, 2, 3, 11, 100]) ar.resultCount(n),
        ],
        [
          'لا توجد نتائج',
          'نتيجة واحدة',
          'نتيجتان',
          '3 نتائج',
          '11 نتيجة',
          '100 نتيجة',
        ],
      );
      expect(
        [
          for (final n in [1, 2, 7, 30]) ar.lastDays(n),
        ],
        ['آخر يوم', 'آخر يومين', 'آخر 7 أيام', 'آخر 30 يومًا'],
      );
    });

    test('English and French plurals', () {
      const en = InputsMessagesEn();
      const fr = InputsMessagesFr();
      expect(en.lastDays(7), 'Last 7 days');
      expect(en.lastDays(1), 'Last day');
      expect(en.resultCount(0), 'No results');
      expect(en.resultCount(1), '1 result');
      expect(en.resultCount(1200), '1,200 results');
      expect(fr.resultCount(0), 'Aucun résultat');
      expect(fr.resultCount(1200), '1 200 résultats');
      expect(fr.unreadCount('Notifications', 1), 'Notifications, 1 non lue');
    });
  });

  group('an explicit label wins over the localized default', () {
    testWidgets('on inputs and pickers', (tester) async {
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              const SearchField(hint: 'Find people'),
              Combobox<String>(
                value: null,
                onChanged: (_) {},
                hint: 'Pick a country',
              ),
              DateRangePicker(onChanged: (_) {}, hint: 'Any time'),
              CommandTrigger(onTap: () {}, hint: 'Jump', shortcut: 'F1'),
            ],
          ),
          locale: _fr,
        ),
      );
      for (final text in [
        'Find people',
        'Pick a country',
        'Any time',
        'Jump',
        'F1',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
    });

    testWidgets('on confirm', (tester) async {
      await tester.pumpWidget(
        _app(
          _confirmOpener(confirmLabel: 'Delete', cancelLabel: 'Keep'),
          locale: _fr,
        ),
      );
      await tester.tap(find.text('Ask'));
      await tester.pumpAndSettle();
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Keep'), findsOneWidget);
    });

    testWidgets('on the copy button', (tester) async {
      _stubClipboard(tester);
      await tester.pumpWidget(
        _app(
          const CopyButton('x', tooltip: 'Copy id', copiedLabel: 'Got it'),
          locale: _fr,
        ),
      );
      expect(tester.widget<Tooltip>(find.byType(Tooltip)).message, 'Copy id');
      await tester.tap(find.byType(CopyButton));
      await tester.pump();
      expect(tester.widget<Tooltip>(find.byType(Tooltip)).message, 'Got it');
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('on the notification center', (tester) async {
      await tester.pumpWidget(
        _app(
          const NotificationCenter(items: _inbox, title: 'Inbox'),
          locale: _fr,
        ),
      );
      expect(
        _actionLabel(tester, find.byType(NotificationCenter)),
        'Inbox, 2 non lues',
      );
    });

    testWidgets('on the date presets', (tester) async {
      await tester.pumpWidget(
        _app(
          DateRangePicker(
            onChanged: (_) {},
            presets: [
              DateRangePreset('Q3', (t) => DateTimeRange(start: t, end: t)),
            ],
          ),
          locale: _fr,
        ),
      );
      await tester.tap(find.byType(DateRangePicker));
      await tester.pumpAndSettle();
      expect(find.text('Q3'), findsOneWidget);
      expect(find.text('7 derniers jours'), findsNothing);
    });
  });

  group('English without the delegate', () {
    testWidgets('inputs and pickers', (tester) async {
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              const PasswordField(),
              const SearchField(),
              Combobox<String>(value: null, onChanged: (_) {}),
              DateRangePicker(onChanged: (_) {}),
              CommandTrigger(onTap: () {}),
            ],
          ),
          delegates: false,
        ),
      );
      expect(_actionLabel(tester, find.byType(PasswordField)), 'Show password');
      for (final text in ['Search', 'Select…', 'Select range', 'Search…']) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      await tester.tap(find.byType(DateRangePicker));
      await tester.pumpAndSettle();
      for (final preset in [
        'Today',
        'Last 7 days',
        'Last 30 days',
        'This month',
        'Last month',
        'Year to date',
      ]) {
        expect(find.text(preset), findsOneWidget, reason: preset);
      }
    });

    testWidgets('confirm and the notification center', (tester) async {
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              _confirmOpener(),
              NotificationCenter(items: _inbox, onMarkAllRead: () {}),
            ],
          ),
          delegates: false,
        ),
      );
      expect(
        _actionLabel(tester, find.byType(NotificationCenter)),
        'Notifications, 2 unread',
      );
      await tester.tap(find.byType(IconAction));
      await tester.pumpAndSettle();
      expect(find.text('Mark all read'), findsOneWidget);
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ask'));
      await tester.pumpAndSettle();
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('the command palette', (tester) async {
      await tester.pumpWidget(
        _app(
          SizedBox(
            height: 480,
            child: CommandPalette(items: const [], onDismiss: () {}),
          ),
          delegates: false,
        ),
      );
      expect(find.text('Search or jump to…'), findsOneWidget);
      expect(find.text('Type to search'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('No results for “zzz”'), findsOneWidget);
    });
  });

  group('the palette trigger shortcut follows the platform', () {
    for (final (platform, label) in [
      (TargetPlatform.macOS, '⌘K'),
      (TargetPlatform.iOS, '⌘K'),
      (TargetPlatform.windows, 'Ctrl+K'),
      (TargetPlatform.linux, 'Ctrl+K'),
      (TargetPlatform.android, 'Ctrl+K'),
    ]) {
      testWidgets('${platform.name}: $label', (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        try {
          await tester.pumpWidget(_app(CommandTrigger(onTap: () {})));
          expect(find.text(label), findsOneWidget);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });
    }

    testWidgets('in French on Windows, with Material\'s key names', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        await tester.pumpWidget(
          _app(CommandTrigger(onTap: () {}), locale: _fr),
        );
        expect(find.text('Ctrl+K'), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });

  testWidgets('the kit\'s palette groups keep their key and show localized', (
    tester,
  ) async {
    final commands = CommandRegistry();
    addTearDown(commands.dispose);
    final fields = FormFieldRegistry();
    await tester.pumpWidget(
      _app(
        CommandScope(
          registry: commands,
          child: FormFieldScope(
            registry: fields,
            child: const FormFieldCommands(child: SizedBox()),
          ),
        ),
        locale: _fr,
      ),
    );
    await tester.pump();
    fields.register(FormFieldEntry(id: 'title', label: 'Titre', focus: () {}));
    final items = commands.active();
    // The key an app lists in groupOrder is the same in every language.
    expect(items.map((i) => i.group), [FormFieldCommands.defaultGroup]);

    await tester.pumpWidget(
      _app(
        SizedBox(
          height: 480,
          child: CommandPalette(
            items: items,
            recent: items,
            preview: true,
            onDismiss: () {},
          ),
        ),
        locale: _fr,
      ),
    );
    expect(find.text('RÉCENTS'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'titre');
    await tester.pumpAndSettle();
    expect(find.text('CHAMPS'), findsNWidgets(2), reason: 'list and preview');
  });
}
