import 'package:admin_ui/collection.dart';
import 'package:admin_ui/l10n.dart';
import 'package:admin_ui/shell.dart';
import 'package:admin_ui/theme.dart';
import 'package:admin_ui/widgets.dart';
import 'package:clock/clock.dart';
import 'package:material_ui/material_ui.dart';

import '../../api/shop_api.dart';
import '../../keys/media_team_keys.dart';
import '../../l10n/money.dart';
import '../../l10n/ref_strings.dart';
import '../../services.dart';
import '../../widgets/page_width.dart';
import '../../widgets/status_meta.dart';
import 'invite_dialog.dart';

/// The shop's staff: who is on the team, their role and whether they can
/// sign in. The owner invites teammates, changes their roles and
/// deactivates them; nobody changes their own row.
class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  late final _controller = CollectionController<StaffMember>(
    fetcher: _fetch,
    rowKey: (member) => member.id,
  );

  /// Everyone the last load returned, for the counts in the header.
  List<StaffMember> _staff = const [];

  Future<CollectionPage<StaffMember>> _fetch(CollectionQuery query) async {
    final staff = await context.api.staff();
    if (mounted) setState(() => _staff = staff);
    final ordered = [...staff]..sort(_teamOrder);
    return LocalCollectionSource<StaffMember>(
      ordered,
      fields: {
        'name': (m) => m.name,
        'email': (m) => m.email,
        'role': (m) => m.role.index,
        'status': (m) => m.status.index,
        'lastActive': (m) => m.lastActiveAt,
      },
      searchFields: const {'name', 'email'},
    ).fetch(query);
  }

  /// Who can sign in first, then pending invitations, then the
  /// deactivated; within each, by role and then by name.
  static int _teamOrder(StaffMember a, StaffMember b) {
    final byStatus = a.status.index.compareTo(b.status.index);
    if (byStatus != 0) return byStatus;
    final byRole = a.role.index.compareTo(b.role.index);
    if (byRole != 0) return byRole;
    return a.name.compareTo(b.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toast(String message, Severity severity) =>
      ToastScope.of(context).show(Toast(message, severity: severity));

  void _patch(StaffMember updated) {
    _controller.patchLocal((_) => updated, where: (m) => m.id == updated.id);
    setState(() {
      _staff = [for (final m in _staff) m.id == updated.id ? updated : m];
    });
  }

  Future<void> _invite() async {
    final member = await showInviteDialog(context);
    if (member == null || !mounted) return;
    _toast(
      context.strings.mediaTeam.invitationSent(bidiIsolate(member.email)),
      Severity.success,
    );
    await _controller.refresh();
  }

  Future<void> _setRole(StaffMember member, Role role) async {
    if (member.role == role) return;
    final strings = context.strings;
    try {
      final updated = await context.api.setRole(member.id, role);
      if (!mounted) return;
      _patch(updated);
      _toast(
        strings.mediaTeam.roleChanged(
          bidiIsolate(member.name),
          strings.shell.role(role),
        ),
        Severity.success,
      );
    } on ShopError catch (error) {
      if (mounted) {
        _toast(ErrorTextScope.describe(context, error), Severity.danger);
      }
    }
  }

  Future<void> _deactivate(StaffMember member) async {
    final strings = context.strings.mediaTeam;
    final name = bidiIsolate(member.name);
    StaffMember? updated;
    final confirmed = await showConfirmDialog(
      context,
      title: strings.deactivateTitle(name),
      message: strings.deactivateMessage(name),
      confirmLabel: strings.deactivate,
      danger: true,
      onConfirm: () async => updated = await context.api.deactivate(member.id),
    );
    final done = updated;
    if (!confirmed || done == null || !mounted) return;
    _patch(done);
    _toast(strings.deactivated(name), Severity.success);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings.mediaTeam;
    final services = context.services;
    final canManage = services.session.can(Permission.manageTeam);
    final me = services.session.user?.id;
    final formats = context.adminFormats;
    final active = _staff.where((m) => m.status == StaffStatus.active).length;
    final invited = _staff.where((m) => m.status == StaffStatus.invited).length;
    final compact = AdminBreakpoint.of(context).isCompact;

    Widget? actionsFor(StaffMember member) =>
        canManage && member.id != me && member.status != StaffStatus.deactivated
        ? _MemberMenu(
            member: member,
            onRole: (role) => _setRole(member, role),
            onDeactivate: () => _deactivate(member),
          )
        : null;

    return PageScaffold(
      maxWidth: pageMaxWidth,
      title: strings.teamTitle,
      subtitle: _staff.isEmpty
          ? null
          : strings.teamSubtitle(
              invited,
              formats.integer(active),
              formats.integer(invited),
            ),
      scrollable: false,
      actions: [
        if (canManage)
          Button.primary(
            strings.inviteTeammate,
            key: MediaTeamKeys.invite,
            icon: Icons.person_add_alt_1_outlined,
            onPressed: _invite,
          ),
      ],
      body: ListenableBuilder(
        listenable: services.appearance,
        builder: (context, _) => Collection<StaffMember>(
          key: MediaTeamKeys.staffList,
          controller: _controller,
          density: services.appearance.density,
          // FRICTION(F-011): the screen picks cards below the compact width.
          viewMode: compact
              ? CollectionViewMode.cards
              : CollectionViewMode.table,
          cardBuilder: (context, member) => _MemberCard(
            member: member,
            isMe: member.id == me,
            actions: actionsFor(member),
          ),
          empty: EmptyState(
            icon: Icons.group_outlined,
            title: strings.noTeamTitle,
            message: strings.noTeamMessage,
          ),
          columns: [
            TableColumn<StaffMember>(
              id: 'member',
              label: strings.columnMember,
              flex: 3,
              minWidth: 220,
              sortKey: 'name',
              cellBuilder: (context, member) =>
                  _MemberIdentity(member: member, isMe: member.id == me),
            ),
            TableColumn<StaffMember>(
              id: 'role',
              label: strings.columnRole,
              flex: 1,
              minWidth: 120,
              sortKey: 'role',
              cellBuilder: (context, member) => Align(
                alignment: AlignmentDirectional.centerStart,
                child: Tag(context.strings.shell.role(member.role)),
              ),
            ),
            TableColumn<StaffMember>(
              id: 'status',
              label: strings.columnStatus,
              flex: 1,
              minWidth: 120,
              sortKey: 'status',
              cellBuilder: (context, member) => Align(
                alignment: AlignmentDirectional.centerStart,
                child: StatusPill(context.staffStatusMeta(member.status)),
              ),
            ),
            TableColumn<StaffMember>(
              id: 'lastActive',
              label: strings.columnLastActive,
              flex: 1,
              minWidth: 110,
              sortKey: 'lastActive',
              cellBuilder: (context, member) => Text(
                _lastActive(context, member),
                style: tableMutedStyle(context, context.type.body),
              ),
            ),
            TableColumn<StaffMember>(
              id: 'actions',
              label: '',
              fixed: 56,
              align: AlignmentDirectional.centerEnd,
              hideable: false,
              cellBuilder: (context, member) =>
                  actionsFor(member) ?? const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

String _lastActive(BuildContext context, StaffMember member) {
  final at = member.lastActiveAt;
  if (at == null) return context.strings.mediaTeam.notYet;
  return formatAgo(context, at, clock.now());
}

/// A member's avatar, name and email, with "You" on the signed-in row.
class _MemberIdentity extends StatelessWidget {
  final StaffMember member;
  final bool isMe;

  const _MemberIdentity({required this.member, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: TableIdentity(
            leading: Avatar(name: member.name, size: 32),
            title: member.name,
            subtitle: member.email,
          ),
        ),
        if (isMe) ...[
          const Gap(AdminSpacing.sm),
          Tag(context.strings.mediaTeam.you, variant: TagVariant.outline),
        ],
      ],
    );
  }
}

/// A member as a card, on a phone: identity, role and status, and the
/// actions menu in the corner.
class _MemberCard extends StatelessWidget {
  final StaffMember member;
  final bool isMe;
  final Widget? actions;

  const _MemberCard({required this.member, required this.isMe, this.actions});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Avatar(name: member.name, size: 40),
        const Gap(AdminSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                member.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.type.bodyStrong,
              ),
              Text(
                member.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.type.caption.copyWith(
                  color: context.colors.foregroundMuted,
                ),
              ),
              const Gap(AdminSpacing.md),
              Wrap(
                spacing: AdminSpacing.sm,
                runSpacing: AdminSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Tag(strings.shell.role(member.role)),
                  StatusPill(context.staffStatusMeta(member.status)),
                  if (isMe)
                    Tag(strings.mediaTeam.you, variant: TagVariant.outline),
                ],
              ),
            ],
          ),
        ),
        ?actions,
      ],
    );
  }
}

/// The actions on a teammate: their role, in a submenu, and deactivating
/// them.
class _MemberMenu extends StatelessWidget {
  final StaffMember member;
  final ValueChanged<Role> onRole;
  final VoidCallback onDeactivate;

  const _MemberMenu({
    required this.member,
    required this.onRole,
    required this.onDeactivate,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return MenuButton(
      key: MediaTeamKeys.memberMenu(member.id),
      icon: Icons.more_horiz_rounded,
      tooltip: strings.mediaTeam.memberActions(bidiIsolate(member.name)),
      entries: [
        MenuSubmenu(
          strings.mediaTeam.changeRole,
          icon: Icons.badge_outlined,
          entries: [
            for (final role in invitableRoles)
              MenuItem(
                strings.shell.role(role),
                description: strings.mediaTeam.roleDescription(role),
                checked: member.role == role,
                onSelect: () => onRole(role),
              ),
          ],
        ),
        const MenuDivider(),
        MenuItem(
          strings.mediaTeam.deactivate,
          icon: Icons.person_off_outlined,
          danger: true,
          onSelect: onDeactivate,
        ),
      ],
    );
  }
}
