import 'package:admin_ui/fields.dart' show SelectOption;
import 'package:admin_ui/forms.dart';
import 'package:admin_ui/l10n.dart';
import 'package:admin_ui/theme.dart';
import 'package:admin_ui/widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../../api/shop_api.dart';
import '../../keys/media_team_keys.dart';
import '../../l10n/ref_strings.dart';
import '../../services.dart';

/// The roles an invitation can give: every one but the shop's owner.
const invitableRoles = [Role.manager, Role.staff, Role.viewer];

/// Opens the invitation dialog; resolves to the teammate invited, or null
/// when it is closed first.
Future<StaffMember?> showInviteDialog(BuildContext context) =>
    showModal<StaffMember>(context, builder: (_) => const InviteDialog());

typedef InviteDraft = ({String email, Role role});

extension type InviteFields(FormScope _s) {
  ValueCell<String> get email => _s.text('email');
  ValueCell<String> get role => _s.text('role');

  InviteDraft read() => (
    email: email.value.trim(),
    role: Role.values.asNameMap()[role.value] ?? Role.staff,
  );

  void fill(InviteDraft draft) {
    email.set(draft.email);
    role.set(draft.role.name);
  }
}

/// An email address and a role, sent as an invitation. The address is
/// checked as it is typed; the shop refuses one already on the team, and
/// the refusal shows under the field.
class InviteDialog extends StatefulWidget {
  const InviteDialog({super.key});

  @override
  State<InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends State<InviteDialog> {
  late final _form = ValueFormController<InviteDraft>(
    read: (scope) => InviteFields(scope).read(),
    write: (scope, draft) => InviteFields(scope).fill(draft),
    initial: (email: '', role: Role.staff),
    rules: (scope) => [
      FieldRules(
        InviteFields(scope).email,
        validators: [Validators.required(), Validators.email()],
      ),
    ],
    onSubmit: _send,
    requireChanges: false,
  );

  Future<void> _send(InviteDraft draft) async {
    final strings = context.strings.mediaTeam;
    final l10n = context.adminL10n;
    try {
      final member = await context.api.invite(draft.email, draft.role);
      if (mounted) Navigator.of(context).pop(member);
    } on ValidationError catch (error) {
      // The key is the cell's name as `InviteFields` declares it.
      throw FormSubmitException(
        fieldErrors: {
          'email': error.fields['email'] == ValidationCodes.duplicate
              ? strings.alreadyOnTeam
              : l10n.fields.invalidEmail,
        },
      );
    } on ShopError catch (error) {
      if (!mounted) rethrow;
      throw FormSubmitException(
        message: ErrorTextScope.describe(context, error),
      );
    }
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings.mediaTeam;
    final shell = context.strings.shell;
    final fields = InviteFields(_form.scope);
    final compact = AdminBreakpoint.of(context).isCompact;
    return ValueForm(
      controller: _form,
      child: Modal(
        key: MediaTeamKeys.inviteDialog,
        title: strings.inviteTeammate,
        description: strings.inviteDescription,
        size: compact ? ModalSize.fullscreen : ModalSize.medium,
        onDismiss: () => Navigator.of(context).maybePop(),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Field(
              fields.email,
              key: MediaTeamKeys.inviteEmail,
              label: strings.email,
              hint: 'name@example.com',
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
            ),
            const Gap(AdminSpacing.lg),
            SelectField(
              fields.role,
              key: MediaTeamKeys.inviteRole,
              label: strings.role,
              options: [
                for (final role in invitableRoles)
                  SelectOption(
                    value: role.name,
                    label: shell.role(role),
                    description: strings.roleDescription(role),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          ListenableBuilder(
            listenable: _form,
            builder: (context, _) => FormActions(
              controller: _form,
              commitLabel: strings.sendInvitation,
              commitDisabledHint: context.adminL10n.shell.fieldsNeedAttention(
                _form.errorCount,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
