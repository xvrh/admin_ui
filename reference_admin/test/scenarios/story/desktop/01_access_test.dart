import 'package:flutter/widgets.dart';
import 'package:flutterware/flutter_test.dart';
import 'package:reference_admin/src/fake/seed_accounts.dart';
import 'package:reference_admin/src/keys/access_keys.dart';

import '../../../support/harness.dart';

// WP-A: getting in. Staff sign in; an invited teammate chooses a first
// password; an old invitation is turned away.

/// The editable fields of the form under [form], in order.
Finder _inputs(Key form) =>
    find.descendant(of: find.byKey(form), matching: find.byType(EditableText));

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
    final fields = _inputs(AccessKeys.signInForm);
    // FRICTION(F-008): SignInForm's fields and button take no keys.
    final submit = find.descendant(
      of: find.byKey(AccessKeys.signInForm),
      matching: find.text(s.kit.shell.signIn),
    );

    await s.enterText(fields.at(0), email);
    await s.enterText(fields.at(1), 'not-the-password');
    await s.tap(submit, shot: const Shot('Sign in · wrong password'));
    expect(shop.route, isA<SignIn>());
    expect(shop.calls.failuresOf(Endpoint.signIn), 1);
    expect(find.text(s.strings.access.wrongPassword), findsOneWidget);
    expect(
      s.tester.widget<EditableText>(fields.at(0)).controller.text,
      email,
      reason: 'the email is kept after the error',
    );

    await s.enterText(fields.at(1), demoPassword);
    await s.tap(submit, shot: const Shot('Dashboard after sign-in'));
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
    final fields = _inputs(AccessKeys.setPasswordForm);
    final join = find.text(s.strings.access.joinShop);

    // Typed twice alike, so the only thing wrong is the length.
    await s.enterText(fields.at(0), 'fern');
    await s.enterText(fields.at(1), 'fern');
    await s.tap(join, shot: const Shot('Set password · too weak'));
    expect(
      find.text(s.kit.shell.passwordTooShort(8)),
      findsOneWidget,
      reason: 'the length rule shows under the new password',
    );
    expect(find.text(s.kit.shell.passwordsDontMatch), findsNothing);

    await s.enterText(fields.at(0), 'green-thumb-42');
    await s.enterText(
      fields.at(1),
      'green-thumb-24',
      shot: const Shot('Set password · mismatch'),
    );
    expect(find.text(s.kit.shell.passwordsDontMatch), findsOneWidget);
    expect(shop.calls.countOf(Endpoint.setPassword), 0);

    await s.enterText(fields.at(1), 'green-thumb-42');
    await s.tap(join, shot: const Shot('Welcome, new teammate'));
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
