import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Ant, whose field labels keep their case.
final _theme = buildAppTheme(antTheme.tokens);

const _fr = Locale('fr');
const _ar = Locale('ar');

Widget _app(
  Widget child, {
  Locale? locale,
  List<LocalizationsDelegate<Object?>> delegates =
      AdminLocalizations.localizationsDelegates,
}) => MaterialApp(
  theme: _theme,
  locale: locale,
  supportedLocales: AdminLocalizations.supportedLocales,
  localizationsDelegates: delegates,
  home: Scaffold(body: child),
);

/// A full-width [SaveBar] in [locale].
Future<void> _pumpBar(
  WidgetTester tester,
  SaveBar bar, {
  Locale locale = _fr,
}) async {
  tester.view.physicalSize = const Size(1200, 400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(Column(children: [bar]), locale: locale));
}

class _Form extends FormController {
  _Form({this.status = FormStatus.clean});

  @override
  FormStatus status;

  @override
  Map<String, String?> errors = const {};

  void set(FormStatus value) {
    status = value;
    notifyListeners();
  }

  @override
  Future<void> submit() async {}

  @override
  void reset() {}
}

/// The tooltip of the [Tip] around the button reading [label].
String? _tipOn(WidgetTester tester, String label) => tester
    .widgetList<Tip>(
      find.ancestor(of: find.text(label), matching: find.byType(Tip)),
    )
    .firstOrNull
    ?.message;

/// The strength labels of a meter, as the German strings an app might load.
class _GermanShell extends ShellMessagesEn {
  const _GermanShell();

  @override
  String get strengthWeak => 'Schwach';

  @override
  String get strengthFair => 'Mittel';

  @override
  String get strengthGood => 'Gut';

  @override
  String get strengthStrong => 'Ausgezeichnet';
}

class _GermanL10n extends AdminLocalizationsEn {
  const _GermanL10n();

  @override
  ShellMessages get shell => const _GermanShell();
}

class _GermanDelegate extends LocalizationsDelegate<AdminLocalizations> {
  const _GermanDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AdminLocalizations> load(Locale locale) =>
      SynchronousFuture(const _GermanL10n());

  @override
  bool shouldReload(_GermanDelegate old) => false;
}

void main() {
  group('SaveBar', () {
    testWidgets('French: buttons and every status', (tester) async {
      await _pumpBar(
        tester,
        SaveBar(
          state: SaveState.unsaved,
          onDiscard: () {},
          onSave: () {},
          onCommit: () {},
        ),
      );
      expect(find.text('Modifications non enregistrées'), findsOneWidget);
      expect(find.text('Abandonner'), findsOneWidget);
      // Save is Material's own word.
      expect(find.text('Enregistrer'), findsOneWidget);
      expect(find.text('Publier'), findsOneWidget);

      const states = {
        SaveState.saving: 'Enregistrement…',
        SaveState.saved: 'Enregistré · il y a 2 min',
        SaveState.error: 'Enregistrement impossible',
      };
      for (final MapEntry(key: state, value: text) in states.entries) {
        await _pumpBar(
          tester,
          SaveBar(state: state, savedLabel: 'il y a 2 min', onSave: () {}),
        );
        expect(find.text(text), findsOneWidget, reason: '$state');
      }
    });

    testWidgets(
      'French: a document under SaveFlow.publish edits and publishes',
      (tester) async {
        const states = {
          SaveState.unsaved: 'Modifié',
          SaveState.saving: 'Publication…',
          SaveState.saved: 'Publié',
          SaveState.error: 'Publication impossible',
        };
        for (final MapEntry(key: state, value: text) in states.entries) {
          await _pumpBar(
            tester,
            SaveBar(state: state, flow: SaveFlow.publish, onCommit: () {}),
          );
          expect(find.text(text), findsOneWidget, reason: '$state');
        }
      },
    );

    testWidgets('French: the invalid count is a plural', (tester) async {
      for (final (count, text) in const [
        (1, '1 champ à vérifier'),
        (2, '2 champs à vérifier'),
      ]) {
        await _pumpBar(
          tester,
          SaveBar(state: SaveState.unsaved, invalidCount: count, onSave: () {}),
        );
        expect(find.text(text), findsOneWidget);
        // The disabled Save gives the same reason.
        expect(_tipOn(tester, 'Enregistrer'), text);
      }
    });

    testWidgets('French: the menus are named', (tester) async {
      await _pumpBar(
        tester,
        SaveBar(
          state: SaveState.unsaved,
          onCommit: () {},
          overflowActions: const [SaveBarAction(label: 'Dupliquer')],
          commitMenu: const [SaveBarAction(label: 'Planifier…')],
        ),
      );
      expect(find.bySemanticsLabel('Plus d’actions'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Plus d’options de publication'),
        findsOneWidget,
      );
    });

    testWidgets('Arabic: buttons, status and all six plural forms', (
      tester,
    ) async {
      await _pumpBar(
        tester,
        SaveBar(
          state: SaveState.unsaved,
          onDiscard: () {},
          onSave: () {},
          onCommit: () {},
        ),
        locale: _ar,
      );
      expect(find.text('تغييرات غير محفوظة'), findsOneWidget);
      expect(find.text('تجاهل'), findsOneWidget);
      expect(find.text('الحفظ'), findsOneWidget);
      expect(find.text('نشر'), findsOneWidget);

      const shell = ShellMessagesAr();
      for (final (count, noun) in const [
        (1, 'حقل واحد'),
        (2, 'حقلان'),
        (3, 'حقول'),
        (11, 'حقلًا'),
        (100, 'حقل يحتاج'),
      ]) {
        expect(shell.fieldsNeedAttention(count), contains(noun));
      }
      await _pumpBar(
        tester,
        SaveBar(state: SaveState.unsaved, invalidCount: 3, onSave: () {}),
        locale: _ar,
      );
      expect(find.text(shell.fieldsNeedAttention(3)), findsOneWidget);
    });

    testWidgets('a label passed in wins over the locale', (tester) async {
      await _pumpBar(
        tester,
        SaveBar(
          state: SaveState.error,
          errorLabel: 'Le slug est déjà pris',
          onDiscard: () {},
          discardLabel: 'Rétablir',
          onCommit: () {},
          commitLabel: 'Mettre en ligne',
        ),
      );
      expect(find.text('Le slug est déjà pris'), findsOneWidget);
      expect(find.text('Rétablir'), findsOneWidget);
      expect(find.text('Mettre en ligne'), findsOneWidget);
    });
  });

  group('FormActions', () {
    testWidgets('French: shares the save bar’s strings', (tester) async {
      final form = _Form(status: FormStatus.dirty);
      addTearDown(form.dispose);
      await tester.pumpWidget(
        _app(
          Center(child: FormActions(controller: form, showDiscard: true)),
          locale: _fr,
        ),
      );
      expect(find.text('Modifications non enregistrées'), findsOneWidget);
      expect(find.text('Abandonner'), findsOneWidget);
      expect(find.text('Enregistrer'), findsOneWidget);

      form.set(FormStatus.submitting);
      await tester.pump();
      expect(find.text('Enregistrement…'), findsOneWidget);
    });

    testWidgets('French: nothing to publish, in French word order', (
      tester,
    ) async {
      final form = _Form();
      addTearDown(form.dispose);
      await tester.pumpWidget(
        _app(
          Center(
            child: FormActions(controller: form, flow: SaveFlow.publish),
          ),
          locale: _fr,
        ),
      );
      // Not "Aucune modification à Publier", nor a lowercased label.
      expect(_tipOn(tester, 'Publier'), 'Aucune modification à publier');
    });

    testWidgets('English: nothing to publish, and a caller’s own label', (
      tester,
    ) async {
      final form = _Form();
      addTearDown(form.dispose);
      await tester.pumpWidget(
        _app(
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FormActions(
                  controller: form,
                  flow: SaveFlow.publish,
                  saveShortcut: false,
                ),
                FormActions(
                  controller: form,
                  commitLabel: 'Go live',
                  saveShortcut: false,
                ),
              ],
            ),
          ),
        ),
      );
      expect(_tipOn(tester, 'Publish'), 'No changes to publish');
      expect(_tipOn(tester, 'Go live'), 'No changes');
    });

    testWidgets('FormSaveBar forwards discard and error labels', (
      tester,
    ) async {
      final form = _Form(status: FormStatus.error);
      addTearDown(form.dispose);
      await tester.pumpWidget(
        _app(
          FormSaveBar(
            controller: form,
            showDiscard: true,
            discardLabel: 'Rétablir',
            errorLabel: 'Réseau indisponible',
          ),
          locale: _fr,
        ),
      );
      expect(find.text('Rétablir'), findsOneWidget);
      expect(find.text('Réseau indisponible'), findsOneWidget);
    });
  });

  group('UnsavedChangesGuard', () {
    for (final (saving, title, confirm) in const [
      (false, 'Abandonner les modifications ?', 'Abandonner'),
      (true, 'Enregistrement en cours — quitter quand même ?', 'Quitter'),
    ]) {
      testWidgets('French prompt${saving ? ' mid-save' : ''}', (tester) async {
        final form = _Form(
          status: saving ? FormStatus.submitting : FormStatus.dirty,
        );
        addTearDown(form.dispose);
        await tester.pumpWidget(
          MaterialApp(
            theme: _theme,
            locale: _fr,
            supportedLocales: AdminLocalizations.supportedLocales,
            localizationsDelegates: AdminLocalizations.localizationsDelegates,
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => UnsavedChangesGuard(
                      controller: form,
                      child: const Scaffold(body: Text('page')),
                    ),
                  ),
                ),
                child: const Text('go'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('go'));
        await tester.pumpAndSettle();

        await tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
        await tester.pumpAndSettle();

        expect(find.text(title), findsOneWidget);
        expect(find.text(confirm), findsOneWidget);
        // The cancel is Material's.
        expect(find.text('Annuler'), findsOneWidget);
      });
    }
  });

  group('auth forms', () {
    testWidgets('SignInForm in French: labels, hint and required marks', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SignInForm(
            onSignIn: (_, _) {},
            onForgotPassword: () {},
            providerButtons: [Button('Google', onPressed: () {})],
          ),
          locale: _fr,
        ),
      );
      expect(find.text('E-mail'), findsOneWidget);
      expect(find.text('Mot de passe'), findsOneWidget);
      expect(find.text('Mot de passe oublié ?'), findsOneWidget);
      expect(find.text('vous@example.com'), findsOneWidget);
      expect(find.text('ou'), findsOneWidget);

      await tester.tap(find.text('Se connecter'));
      await tester.pump();
      expect(find.text('Le champ « E-mail » est obligatoire'), findsOneWidget);
      expect(
        find.text('Le champ « Mot de passe » est obligatoire'),
        findsOneWidget,
      );
    });

    testWidgets('SetPasswordForm in French: labels and validation', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(SetPasswordForm(onSubmit: (_) {}), locale: _fr),
      );
      expect(find.text('Nouveau mot de passe'), findsOneWidget);
      expect(find.text('Confirmer le mot de passe'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'abc');
      await tester.enterText(find.byType(TextField).last, 'abd');
      await tester.tap(find.text('Définir le mot de passe'));
      await tester.pump();
      expect(find.text('Utilisez au moins 8 caractères.'), findsOneWidget);
      expect(
        find.text('Les mots de passe ne correspondent pas.'),
        findsOneWidget,
      );
    });

    testWidgets('the length rule counts in the plural', (tester) async {
      await tester.pumpWidget(
        _app(SetPasswordForm(onSubmit: (_) {}, minLength: 1)),
      );
      await tester.tap(find.text('Set password'));
      await tester.pump();
      expect(find.text('Use at least 1 character.'), findsOneWidget);
    });

    testWidgets('ChangePasswordForm in Arabic', (tester) async {
      await tester.pumpWidget(
        _app(ChangePasswordForm(onSubmit: (_, _) {}), locale: _ar),
      );
      expect(find.text('كلمة المرور الحالية'), findsOneWidget);
      expect(find.text('كلمة المرور الجديدة'), findsOneWidget);
      expect(find.text('تأكيد كلمة المرور الجديدة'), findsOneWidget);

      await tester.tap(find.text('تغيير كلمة المرور'));
      await tester.pump();
      expect(find.text('حقل ”كلمة المرور الحالية“ مطلوب'), findsOneWidget);
    });

    for (final (name, locale, delegates) in [
      ('Arabic', _ar, AdminLocalizations.localizationsDelegates),
      (
        'a longer German override',
        const Locale('de'),
        <LocalizationsDelegate<Object?>>[
          const _GermanDelegate(),
          ...AdminLocalizations.localizationsDelegates,
        ],
      ),
    ]) {
      testWidgets('the strength label is never cut short: $name', (
        tester,
      ) async {
        for (final password in const [
          'abcdefgh',
          'abcdEfgh',
          'abcdEf12',
          r'abcdEf12!xyz',
        ]) {
          await tester.pumpWidget(
            _app(
              Center(
                child: SizedBox(
                  width: 240,
                  child: PasswordStrengthMeter(password: password),
                ),
              ),
              locale: locale,
              delegates: delegates,
            ),
          );
          final shown = find.descendant(
            of: find.byType(PasswordStrengthMeter),
            matching: find.byWidgetPredicate(
              (w) => w is Visibility && w.visible,
            ),
          );
          final paragraph = tester.renderObject<RenderParagraph>(
            find.descendant(of: shown, matching: find.byType(RichText)),
          );
          expect(
            paragraph.size.width,
            greaterThanOrEqualTo(
              paragraph.getMaxIntrinsicWidth(double.infinity),
            ),
            reason: paragraph.text.toPlainText(),
          );
          expect(paragraph.didExceedMaxLines, isFalse);
          expect(paragraph.size.height, lessThan(24), reason: 'one line');
        }
      });
    }
  });

  group('the save shortcut label', () {
    for (final (platform, label) in const [
      (TargetPlatform.linux, 'Ctrl+S'),
      (TargetPlatform.windows, 'Ctrl+S'),
      (TargetPlatform.macOS, '⌘S'),
    ]) {
      testWidgets('${platform.name}: $label', (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        late BuildContext context;
        await tester.pumpWidget(
          _app(
            Builder(
              builder: (c) {
                context = c;
                return const SizedBox();
              },
            ),
            locale: _fr,
          ),
        );
        final activator = primaryModifierActivator(LogicalKeyboardKey.keyS);
        expect(shortcutLabel(context, activator), label);
        debugDefaultTargetPlatformOverride = null;
      });
    }
  });

  group('shell chrome', () {
    testWidgets('Sidebar and TopBar name themselves in Arabic', (tester) async {
      tester.view.physicalSize = const Size(500, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              TopBar(search: const SizedBox(), onSearch: () {}),
              Expanded(
                child: Row(
                  children: [
                    Sidebar(
                      entries: [
                        NavItem(
                          'Pages',
                          icon: Icons.description_outlined,
                          badge: '3',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          locale: _ar,
        ),
      );
      expect(find.bySemanticsLabel('التنقل'), findsOneWidget);
      expect(find.bySemanticsLabel('Pages، 3'), findsOneWidget);
      // The narrow bar's search icon is named by Material.
      expect(find.bySemanticsLabel('بحث'), findsOneWidget);
    });
  });
}
