import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

final _iris = AdminTokens.from(palette: irisPalette);

Widget _host(Widget child, {AdminTokens? tokens}) => MaterialApp(
  theme: buildAppTheme(tokens ?? _iris),
  home: Scaffold(
    body: SingleChildScrollView(
      child: Center(
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              child,
              TextButton(onPressed: () {}, child: const Text('Elsewhere')),
            ],
          ),
        ),
      ),
    ),
  ),
);

/// The [EditableText] of the field labelled [label].
Finder _field(String label) => find.descendant(
  of: find.byWidgetPredicate((w) => w is LabeledField && w.label == label),
  matching: find.byType(EditableText),
);

bool _focused(WidgetTester tester, String label) =>
    tester.widget<EditableText>(_field(label)).focusNode.hasPrimaryFocus;

/// Moves focus off every field.
Future<void> _blur(WidgetTester tester) async {
  Focus.of(tester.element(find.text('Elsewhere'))).requestFocus();
  await tester.pump();
}

void main() {
  group('SignInForm', () {
    testWidgets('an empty submit marks each empty field and focuses the '
        'first', (tester) async {
      var fired = 0;
      await tester.pumpWidget(_host(SignInForm(onSignIn: (_, _) => fired++)));
      await _blur(tester);

      await tester.tap(find.text('Sign in'));
      await tester.pump();
      expect(fired, 0);
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      expect(_focused(tester, 'Email'), isTrue);

      // Filling one in clears its mark; the next submit lands on the other.
      await tester.enterText(_field('Email'), 'me@example.com');
      await tester.pump();
      expect(find.text('Email is required'), findsNothing);
      await _blur(tester);
      await tester.tap(find.text('Sign in'));
      await tester.pump();
      expect(fired, 0);
      expect(find.text('Password is required'), findsOneWidget);
      expect(_focused(tester, 'Password'), isTrue);

      await tester.enterText(_field('Password'), 'hunter2');
      await tester.pump();
      expect(find.text('Password is required'), findsNothing);
      await tester.tap(find.text('Sign in'));
      expect(fired, 1);
    });

    testWidgets('both fields are the same input: a leading glyph and one '
        'height, the button\'s', (tester) async {
      await tester.pumpWidget(
        _host(SignInForm(onSignIn: (_, _) {}, onForgotPassword: () {})),
      );
      final decorators = find.byType(InputDecorator);
      expect(decorators, findsNWidgets(2));
      final height = _iris.sizes.medium;
      for (final e in decorators.evaluate()) {
        expect((e.renderObject! as RenderBox).size.height, height);
      }
      expect(find.byIcon(Icons.mail_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
      expect(
        tester
            .getSize(
              find.ancestor(
                of: find.text('Sign in'),
                matching: find.byType(Button),
              ),
            )
            .height,
        height,
      );
      // No placeholder repeats the password label.
      final password = tester.widget<InputDecorator>(decorators.last);
      expect(password.decoration.hintText, isNull);
    });

    for (final theme in adminThemes) {
      for (final dark in [false, true]) {
        final source = dark ? theme.dark! : theme.tokens;
        final tokens = AdminTokens.from(
          palette: source.palette,
          radii: source.radii,
          sizes: source.sizes,
        );
        final height = tokens.sizes.medium;
        testWidgets('${theme.name} ${dark ? 'Dark' : 'Light'}: email, '
            'password and Sign in are all $height', (tester) async {
          await tester.pumpWidget(
            _host(SignInForm(onSignIn: (_, _) {}), tokens: tokens),
          );
          for (final e in find.byType(InputDecorator).evaluate()) {
            expect((e.renderObject! as RenderBox).size.height, height);
          }
          expect(
            tester
                .getSize(
                  find.ancestor(
                    of: find.text('Sign in'),
                    matching: find.byType(Button),
                  ),
                )
                .height,
            height,
          );
        });
      }
    }

    testWidgets('the server error is announced', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          SignInForm(
            onSignIn: (_, _) {},
            errorText: 'Invalid email or password.',
          ),
        ),
      );
      expect(
        tester.getSemantics(find.text('Invalid email or password.')),
        isSemantics(isLiveRegion: true),
      );
      handle.dispose();
    });
  });

  group('NewPasswordFields', () {
    Widget form({ValueChanged<String>? onSubmit}) =>
        SetPasswordForm(onSubmit: onSubmit ?? (_) {});

    testWidgets('the length rule waits for the field to be left', (
      tester,
    ) async {
      await tester.pumpWidget(_host(form()));
      await tester.enterText(_field('New password'), 'a');
      await tester.pump();
      expect(find.text('Use at least 8 characters.'), findsNothing);

      await _blur(tester);
      expect(find.text('Use at least 8 characters.'), findsOneWidget);

      // Once shown, it follows the typing and clears when met.
      await tester.enterText(_field('New password'), 'abcdefgh');
      await tester.pump();
      expect(find.text('Use at least 8 characters.'), findsNothing);
    });

    testWidgets('leaving an empty field shows nothing', (tester) async {
      await tester.pumpWidget(_host(form()));
      await tester.showKeyboard(_field('New password'));
      await _blur(tester);
      expect(find.text('Use at least 8 characters.'), findsNothing);
    });

    testWidgets('a mismatch shows once the confirmation is left', (
      tester,
    ) async {
      await tester.pumpWidget(_host(form()));
      await tester.enterText(_field('New password'), 'correct-horse-1');
      await tester.enterText(_field('Confirm password'), 'correct');
      await tester.pump();
      expect(find.text("Passwords don't match."), findsNothing);

      await _blur(tester);
      expect(find.text("Passwords don't match."), findsOneWidget);

      await tester.enterText(_field('Confirm password'), 'correct-horse-1');
      await tester.pump();
      expect(find.text("Passwords don't match."), findsNothing);
    });

    testWidgets('a mismatch shows once the confirmation is as long', (
      tester,
    ) async {
      await tester.pumpWidget(_host(form()));
      await tester.enterText(_field('New password'), 'correct-horse-1');
      await tester.enterText(_field('Confirm password'), 'correct-horse-');
      await tester.pump();
      expect(find.text("Passwords don't match."), findsNothing);
      await tester.enterText(_field('Confirm password'), 'correct-horse-2');
      await tester.pump();
      expect(find.text("Passwords don't match."), findsOneWidget);
      expect(_focused(tester, 'Confirm password'), isTrue);
    });

    testWidgets('submit stays enabled, and focuses the first failing field', (
      tester,
    ) async {
      final submitted = <String>[];
      await tester.pumpWidget(_host(form(onSubmit: submitted.add)));
      final button = find.ancestor(
        of: find.text('Set password'),
        matching: find.byType(Button),
      );
      expect(tester.widget<Button>(button).onPressed, isNotNull);

      await tester.tap(button);
      await tester.pump();
      expect(submitted, isEmpty);
      expect(find.text('Use at least 8 characters.'), findsOneWidget);
      expect(_focused(tester, 'New password'), isTrue);

      await tester.enterText(_field('New password'), 'longenough1');
      await tester.pump();
      await tester.tap(button);
      await tester.pump();
      expect(submitted, isEmpty);
      expect(find.text("Passwords don't match."), findsOneWidget);
      expect(_focused(tester, 'Confirm password'), isTrue);

      await tester.enterText(_field('Confirm password'), 'longenough1');
      await tester.pump();
      await tester.tap(button);
      expect(submitted, ['longenough1']);
    });

    testWidgets('Enter in the new password moves to the confirmation', (
      tester,
    ) async {
      await tester.pumpWidget(_host(form()));
      await tester.showKeyboard(_field('New password'));
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      expect(_focused(tester, 'Confirm password'), isTrue);
    });
  });

  group('ChangePasswordForm', () {
    testWidgets('an empty current password is marked and focused first', (
      tester,
    ) async {
      final calls = <(String, String)>[];
      await tester.pumpWidget(
        _host(ChangePasswordForm(onSubmit: (c, n) => calls.add((c, n)))),
      );
      final button = find.ancestor(
        of: find.text('Change password'),
        matching: find.byType(Button),
      );
      await tester.tap(button);
      await tester.pump();
      expect(calls, isEmpty);
      expect(find.text('Current password is required'), findsOneWidget);
      // The new password's rules show too, without taking the focus.
      expect(find.text('Use at least 8 characters.'), findsOneWidget);
      expect(_focused(tester, 'Current password'), isTrue);

      await tester.enterText(_field('Current password'), 'oldpass00');
      await tester.pump();
      expect(find.text('Current password is required'), findsNothing);
      await tester.tap(button);
      await tester.pump();
      expect(_focused(tester, 'New password'), isTrue);

      await tester.enterText(_field('New password'), 'newpass11');
      await tester.enterText(_field('Confirm new password'), 'newpass11');
      await tester.pump();
      await tester.tap(button);
      expect(calls, [('oldpass00', 'newpass11')]);
    });

    testWidgets('Enter in the current password moves to the new one', (
      tester,
    ) async {
      await tester.pumpWidget(_host(ChangePasswordForm(onSubmit: (_, _) {})));
      await tester.showKeyboard(_field('Current password'));
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      expect(_focused(tester, 'New password'), isTrue);
    });
  });

  group('PasswordStrengthMeter', () {
    /// The four segments' colours and the label, for [password].
    Future<(List<Color>, String)> read(
      WidgetTester tester,
      AdminTokens tokens,
      String password,
    ) async {
      await tester.pumpWidget(
        _host(PasswordStrengthMeter(password: password), tokens: tokens),
      );
      final segments = [
        for (final c in tester.widgetList<Container>(
          find.descendant(
            of: find.byType(PasswordStrengthMeter),
            matching: find.byWidgetPredicate(
              (w) => w is Container && w.constraints?.maxHeight == 4,
            ),
          ),
        ))
          (c.decoration! as BoxDecoration).color!,
      ];
      final label = tester
          .widgetList<Visibility>(find.byType(Visibility))
          .firstWhere((v) => v.visible)
          .child;
      return (segments, (label as Text).data!);
    }

    const passwords = {
      'Weak': 'abcdefgh',
      'Fair': 'abcdEfgh',
      'Good': 'abcdEf12',
      'Strong': r'abcdEf12!xyz',
    };

    /// The accent of each step, from Weak to Strong.
    Future<List<Color>> ramp(WidgetTester tester, AdminTokens tokens) async {
      final accents = <Color>[];
      for (final MapEntry(key: name, value: password) in passwords.entries) {
        final (segments, label) = await read(tester, tokens, password);
        expect(label, name);
        accents.add(segments.first);
      }
      return accents;
    }

    testWidgets('the ramp is the same under any brand', (tester) async {
      final base = await ramp(tester, _iris);
      final p = _iris.palette;
      expect(base, [
        p.danger,
        p.warning,
        Color.alphaBlend(p.success.withValues(alpha: 0.55), p.surface),
        p.success,
      ]);
      expect(base.toSet(), hasLength(4));

      for (final seed in const [Color(0xFFE11D48), Color(0xFFD97706)]) {
        final branded = _iris.branded(seed);
        expect(await ramp(tester, branded), base);
        expect(base, isNot(contains(branded.palette.primary)));
      }

      // shadcn's near-black primary never shows up in the ramp either.
      final shadcn = AdminTokens.from(palette: shadcnPalette);
      final steps = await ramp(tester, shadcn);
      expect(steps, isNot(contains(shadcn.palette.primary)));
      expect(steps.toSet(), hasLength(4));
    });

    testWidgets('the label takes the widest one\'s width, so the bar holds '
        'still', (tester) async {
      double barWidth() => tester
          .getSize(
            find
                .descendant(
                  of: find.byType(PasswordStrengthMeter),
                  matching: find.byType(Expanded),
                )
                .first,
          )
          .width;
      final widths = <double>{};
      for (final password in passwords.values) {
        await read(tester, _iris, password);
        widths.add(barWidth());
      }
      expect(widths, hasLength(1));
      expect(tester.takeException(), isNull);
    });
  });

  group('AuthScaffold', () {
    Widget scaffold({CrossAxisAlignment? align}) => MaterialApp(
      theme: buildAppTheme(_iris),
      home: align == null
          ? const AuthScaffold(
              logo: SizedBox.square(key: Key('logo'), dimension: 40),
              title: 'Sign in',
              subtitle: 'Use your admin account.',
              child: SizedBox(height: 40),
            )
          : AuthScaffold(
              logo: const SizedBox.square(key: Key('logo'), dimension: 40),
              title: 'Sign in',
              subtitle: 'Use your admin account.',
              align: align,
              child: const SizedBox(height: 40),
            ),
    );

    testWidgets('the title is a heading', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(scaffold());
      expect(
        tester.getSemantics(find.text('Sign in')),
        isSemantics(label: 'Sign in', isHeader: true),
      );
      handle.dispose();
    });

    testWidgets('logo, title and subtitle share one alignment', (tester) async {
      TextAlign alignOf(String text) =>
          tester.widget<Text>(find.text(text)).textAlign!;

      await tester.pumpWidget(scaffold());
      final card = tester.getRect(
        find
            .ancestor(of: find.text('Sign in'), matching: find.byType(Column))
            .first,
      );
      expect(
        tester.getCenter(find.byKey(const Key('logo'))).dx,
        card.center.dx,
      );
      expect(alignOf('Sign in'), TextAlign.center);
      expect(alignOf('Use your admin account.'), TextAlign.center);

      await tester.pumpWidget(scaffold(align: CrossAxisAlignment.start));
      expect(tester.getTopLeft(find.byKey(const Key('logo'))).dx, card.left);
      expect(alignOf('Sign in'), TextAlign.start);
      expect(alignOf('Use your admin account.'), TextAlign.start);
    });
  });

  testWidgets('a danger Alert is a live region', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(const Alert('Could not sign in.', severity: Severity.danger)),
    );
    expect(
      tester.getSemantics(find.text('Could not sign in.')),
      isSemantics(isLiveRegion: true),
    );
    handle.dispose();
  });
}
