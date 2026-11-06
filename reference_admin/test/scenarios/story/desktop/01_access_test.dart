import 'package:flutter/widgets.dart';
import 'package:flutterware/flutter_test.dart';
import 'package:reference_admin/src/fake/seed_accounts.dart';
import 'package:reference_admin/src/keys/access_keys.dart';

import '../../../support/harness.dart';

// WP-A: getting in. Staff sign in; an invited teammate chooses a first
// password; an old invitation is turned away.

/// The text the input keyed [field] holds.
String _textOf(ScenarioTester s, Key field) => s.tester
    .widget<EditableText>(
      find.descendant(
        of: find.byKey(field),
        matching: find.byType(EditableText),
      ),
    )
    .controller
    .text;

void main() {
  scenario('Signing in', (s) async {
    final shop = await openShop(
      s,
      as: null,
      at: const SignIn(),
      shot: const Shot('Sign in', tags: ['tour']),
    );
    expect(shop.route, isA<SignIn>());
    final (email, _) = demoAccounts.first;

    await s.enterText(AccessKeys.signInEmail, email);
    await s.enterText(AccessKeys.signInPassword, 'not-the-password');
    await s.tap(
      AccessKeys.signInSubmit,
      shot: const Shot('Sign in · wrong password'),
    );
    expect(shop.route, isA<SignIn>());
    expect(shop.calls.failuresOf(Endpoint.signIn), 1);
    expect(find.text(s.strings.access.wrongPassword), findsOneWidget);
    expect(
      _textOf(s, AccessKeys.signInEmail),
      email,
      reason: 'the email is kept after the error',
    );

    await s.enterText(AccessKeys.signInPassword, demoPassword);
    await s.tap(
      AccessKeys.signInSubmit,
      shot: const Shot('Dashboard after sign-in'),
    );
    expect(shop.route, const Dashboard());
    final me = shop.api.currentStaff!;
    expect(find.text(s.strings.access.welcomeBack(me.name)), findsOneWidget);
    expect(shop.route.uri.path, '/');
    expect(shop.calls.paths.take(3), [
      'auth.signIn',
      'auth.signIn',
      'prefs.load',
    ]);
    expect(shop.calls.countOf(Endpoint.signIn), 2);
    expect(shop.calls.countOf(Endpoint.stats), 1);
    expect(
      shop.calls.paths.indexOf('dashboard.stats'),
      greaterThan(shop.calls.paths.indexOf('prefs.load')),
    );
    expect(find.byKey(AccessKeys.stats), findsOneWidget);
  });

  scenario('An invited teammate sets a password', (s) async {
    final shop = await openShop(
      s,
      as: null,
      at: const SetPassword('invite-7'),
      shot: const Shot('Set password'),
    );
    final invited = shop.db.staff.firstWhere(
      (m) => m.status == StaffStatus.invited && m.email.startsWith('priya'),
    );
    expect(shop.calls.countOf(Endpoint.inviteInfo), 1);

    // Typed twice alike, so the only thing wrong is the length.
    await s.enterText(AccessKeys.newPassword, 'fern');
    await s.enterText(AccessKeys.confirmPassword, 'fern');
    await s.tap(
      AccessKeys.setPasswordSubmit,
      shot: const Shot('Set password · too weak'),
    );
    expect(
      find.text(s.kit.shell.passwordTooShort(8)),
      findsOneWidget,
      reason: 'the length rule shows under the new password',
    );
    expect(find.text(s.kit.shell.passwordsDontMatch), findsNothing);

    await s.enterText(AccessKeys.newPassword, 'green-thumb-42');
    await s.enterText(
      AccessKeys.confirmPassword,
      'green-thumb-24',
      shot: const Shot('Set password · mismatch'),
    );
    expect(find.text(s.kit.shell.passwordsDontMatch), findsOneWidget);
    expect(shop.calls.countOf(Endpoint.setPassword), 0);

    await s.enterText(AccessKeys.confirmPassword, 'green-thumb-42');
    await s.tap(
      AccessKeys.setPasswordSubmit,
      shot: const Shot('Welcome, new teammate'),
    );
    expect(shop.calls.countOf(Endpoint.setPassword), 1);
    expect(shop.db.invites.where((i) => i.token == 'invite-7'), isEmpty);
    expect(
      shop.db.staff.firstWhere((m) => m.id == invited.id).status,
      StaffStatus.active,
    );
    expect(shop.api.currentStaff?.id, invited.id);
    expect(shop.route, const Dashboard());
  });

  scenario('An expired invitation', (s) async {
    final shop = await openShop(
      s,
      as: null,
      at: const SetPassword('invite-old'),
      shot: const Shot('Invitation expired'),
    );
    expect(find.byKey(AccessKeys.inviteProblem), findsOneWidget);
    expect(find.text(s.strings.access.inviteExpiredTitle), findsOneWidget);
    expect(shop.calls.countOf(Endpoint.inviteInfo), 1);
    expect(shop.calls.countOf(Endpoint.setPassword), 0);

    await s.tap(AccessKeys.backToSignIn);
    expect(shop.route, isA<SignIn>());
  });
}
