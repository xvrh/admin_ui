import 'dart:async';

import 'package:admin_ui/forms.dart' show AssetDetailView;
import 'package:admin_ui/l10n.dart' show bidiIsolate;
import 'package:admin_ui/shell.dart' show Sidebar;
import 'package:admin_ui/widgets.dart' show Tip;
import 'package:flutter/widgets.dart';
import 'package:flutterware/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show Icons;
import 'package:reference_admin/src/frame/navigation.dart';
import 'package:reference_admin/src/keys/media_team_keys.dart';

import '../../../support/harness.dart';

void main() {
  scenario('The media library', (s) async {
    final shop = await openShop(
      s,
      at: const Media(),
      shot: const Shot('Media library', tags: ['tour']),
    );
    expect(find.byKey(MediaTeamKeys.library), findsOneWidget);
    // A page at a time: the first 24, and the next as soon as a tall
    // window shows the end of the grid.
    final pages = [
      for (final call in shop.calls.all)
        if (call.endpoint == Endpoint.browseAssets) call.args['index'],
    ];
    expect(pages.first, 0);
    expect(pages, anyOf(equals([0]), equals([0, 24])));

    final library = find.byKey(MediaTeamKeys.library);
    // FRICTION(F-008): the library's view switch takes no key.
    await s.tap(
      find.descendant(
        of: library,
        matching: find.byIcon(Icons.view_list_rounded),
      ),
      shot: const Shot('Media · list'),
    );
    await s.tap(
      find.descendant(
        of: library,
        matching: find.byIcon(Icons.grid_view_rounded),
      ),
    );

    // The usage filter sits in the library's toolbar, and the shop answers
    // it: one page, not the whole library read and filtered here.
    await s.tap(MediaTeamKeys.usageFilter);
    shop.calls.clear();
    await s.tap(
      find.text(s.strings.mediaTeam.usageUnused),
      shot: const Shot('Media · unused'),
    );
    final browsed = [
      for (final call in shop.calls.all)
        if (call.endpoint == Endpoint.browseAssets) call.args,
    ];
    expect(browsed, hasLength(1));
    expect(browsed.single['index'], 0);
    expect(browsed.single['size'], 24);
    expect(browsed.single['where'], isNotEmpty);
    final unused = shop.db.assets.where((a) => a.usageCount == 0).toList();
    expect(unused, hasLength(6));
    for (final asset in unused) {
      expect(find.text(asset.name), findsOneWidget);
    }

    final asset = shop.db.assets.firstWhere((a) => a.id == 'm-35');
    expect(asset.alt.containsKey('ar'), isFalse);
    await s.tap(find.text(asset.name), shot: const Shot('Media · details'));
    final sheet = find.byType(AssetDetailView);
    expect(sheet, findsOneWidget);

    // The alt text's lanes follow the shop's languages: en, fr, ar.
    // FRICTION(F-008): a lane takes no key, so it is found by its place.
    const arabicAlt = 'قفازات، رسم ٣';
    await s.enterText(
      find.descendant(of: sheet, matching: find.byType(EditableText)).at(2),
      arabicAlt,
    );
    shop.calls.clear();
    await s.keyboard.dismiss();
    await s.tap(
      find.descendant(of: sheet, matching: find.text(s.kit.assets.saveAltText)),
      shot: const Shot('Media · alt text saved'),
    );
    expect(shop.calls.paths, ['media.updateAlt']);
    final saved = shop.db.assets.firstWhere((a) => a.id == asset.id);
    expect(saved.alt['ar'], arabicAlt);
    expect(saved.alt['en'], asset.alt['en']);
    expect(saved.alt['fr'], asset.alt['fr']);

    await s.tap(MediaTeamKeys.crop, shot: const Shot('Media · crop'));
    expect(find.text(s.kit.assets.cropAndFocalPoint), findsOneWidget);
    await s.tap(find.text(s.kit.apply));
    expect(find.text(s.kit.assets.cropAndFocalPoint), findsNothing);
    expect(shop.calls.paths, ['media.updateAlt']);
  });

  scenario('Inviting a teammate', (s) async {
    final shop = await openShop(
      s,
      at: const Team(),
      shot: const Shot('Team', tags: ['tour']),
    );
    final strings = s.strings.mediaTeam;
    final before = shop.db.staff.length;
    expect(find.byKey(MediaTeamKeys.staffList), findsOneWidget);

    await s.tap(MediaTeamKeys.invite, shot: const Shot('Invite teammate'));
    expect(find.byKey(MediaTeamKeys.inviteDialog), findsOneWidget);

    await s.enterText(
      MediaTeamKeys.inviteEmail,
      'robin.example.com',
      shot: const Shot('Invite · invalid email'),
    );
    expect(find.text(s.kit.fields.invalidEmail), findsOneWidget);

    final taken = shop.db.staff.firstWhere((m) => m.role == Role.staff).email;
    await s.enterText(MediaTeamKeys.inviteEmail, taken);
    await s.tap(
      find.text(strings.sendInvitation),
      shot: const Shot('Invite · already on the team'),
    );
    expect(find.text(strings.alreadyOnTeam), findsOneWidget);
    expect(shop.calls.countOf(Endpoint.invite), 1);
    expect(shop.db.staff, hasLength(before));

    const email = 'robin.gardener@example.com';
    await s.enterText(MediaTeamKeys.inviteEmail, email);
    await s.tap(MediaTeamKeys.inviteRole);
    await s.tap(find.text(strings.roleDescription(Role.viewer)));
    await s.tap(
      find.text(strings.sendInvitation),
      shot: const Shot('Team · invitation sent'),
    );
    expect(find.byKey(MediaTeamKeys.inviteDialog), findsNothing);
    expect(shop.calls.countOf(Endpoint.invite), 2);
    expect(shop.db.staff, hasLength(before + 1));
    final invited = shop.db.staff.last;
    expect(invited.email, email);
    expect(invited.role, Role.viewer);
    expect(invited.status, StaffStatus.invited);
    expect(shop.db.invites.where((i) => i.email == email), hasLength(1));
    expect(shop.calls.countOf(Endpoint.staff), 2);
    if (!s.breakpoint.isCompact) expect(find.text(email), findsOneWidget);
  });

  scenario('Changing a role, deactivating', (s) async {
    final shop = await openShop(s, at: const Team());
    final strings = s.strings.mediaTeam;
    final owner = shop.api.currentStaff!;
    final member = shop.db.staff.firstWhere(
      (m) => m.role == Role.staff && m.status == StaffStatus.active,
    );

    // Nobody changes their own row: the owner's has no menu, and the shop
    // refuses a forced change.
    expect(find.byKey(MediaTeamKeys.memberMenu(owner.id)), findsNothing);

    await s.tap(MediaTeamKeys.memberMenu(member.id));
    await s.tap(
      find.text(strings.changeRole),
      shot: const Shot('Team · role menu'),
    );
    expect(shop.calls.countOf(Endpoint.setRole), 0);

    await s.tap(
      find.text(strings.roleDescription(Role.manager)),
      shot: const Shot('Team · role changed'),
    );
    expect(shop.calls.countOf(Endpoint.setRole), 1);
    expect(shop.db.staffById(member.id).role, Role.manager);
    // The role toast times out (a frameless timer) before the next action,
    // so the dialog is photographed alone.
    await s.wait(const Duration(seconds: 5));
    expect(
      find.text(
        strings.roleChanged(
          bidiIsolate(member.name),
          s.strings.shell.role(Role.manager),
        ),
      ),
      findsNothing,
    );

    await s.tap(MediaTeamKeys.memberMenu(member.id));
    await s.tap(
      find.text(strings.deactivate),
      shot: const Shot('Team · deactivate?'),
    );
    expect(shop.calls.countOf(Endpoint.deactivate), 0);
    await s.tap(
      find.text(strings.deactivate),
      shot: const Shot('Team · deactivated'),
    );
    expect(shop.calls.countOf(Endpoint.deactivate), 1);
    expect(shop.db.staffById(member.id).status, StaffStatus.deactivated);
    expect(find.byKey(MediaTeamKeys.memberMenu(member.id)), findsNothing);

    Object? refused;
    unawaited(
      shop.api
          .setRole(owner.id, Role.viewer)
          .then<void>((_) {}, onError: (Object error) => refused = error),
    );
    await s.wait(const Duration(seconds: 1));
    expect(refused, isA<ForbiddenError>());
    expect(shop.db.staffById(owner.id).role, Role.owner);
  });

  scenario('Staff cannot manage the team', (s) async {
    final shop = await openShop(
      s,
      as: Role.staff,
      at: const Team(),
      shot: const Shot('Team · not allowed'),
    );
    expect(shop.route, isA<Forbidden>());
    expect(find.byKey(MediaTeamKeys.teamPage), findsNothing);
    final label = navLabel(s.strings.shell, Nav.team);
    expect(
      find.descendant(
        of: find.byType(Sidebar),
        matching: find.byWidgetPredicate(
          (w) =>
              (w is Text && w.data == label) ||
              (w is Tip && w.message == label),
        ),
      ),
      findsNothing,
    );

    const email = 'robin.gardener@example.com';
    Object? refused;
    unawaited(
      shop.api
          .invite(email, Role.viewer)
          .then<void>((_) {}, onError: (Object error) => refused = error),
    );
    await s.wait(const Duration(seconds: 1));
    expect(refused, isA<ForbiddenError>());
    expect(shop.db.staff.where((m) => m.email == email), isEmpty);
  });
}
