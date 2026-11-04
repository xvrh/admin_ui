import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';
import 'customer_form.dart';

/// A create-record dialog on a [ValueFormController], opened over the page
/// that launches it: "New contact", with the customer form's handles and
/// rules.
///
/// A new record starts blank and a blank record is worth submitting, so the
/// controller does not require changes: Create is live from the start, and
/// pressed on empty required fields it refuses, shows each message in place
/// and takes focus to the first. [invalid] pins that moment.
class RecordDialogDemo extends StatefulWidget {
  /// Opens after a refused submit, its messages shown.
  final bool invalid;

  @Preview(name: 'Record dialog', wrapper: adminUiPreview)
  const RecordDialogDemo({super.key}) : invalid = false;

  @Preview(name: 'Record dialog (invalid)', wrapper: adminUiPreview)
  const RecordDialogDemo.invalid({super.key}) : invalid = true;

  @override
  State<RecordDialogDemo> createState() => _RecordDialogDemoState();
}

class _RecordDialogDemoState extends State<RecordDialogDemo> {
  final _api = FakeContactApi();
  String? _created;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _open(submitAtOnce: widget.invalid);
    });
  }

  Future<void> _open({bool submitAtOnce = false}) async {
    final created = await showNewContactDialog(
      context,
      api: _api,
      submitAtOnce: submitAtOnce,
    );
    if (created != null && mounted) setState(() => _created = created.name);
  }

  @override
  Widget build(BuildContext context) {
    final created = _created;
    return DemoPage(
      children: [
        Text('Contacts', style: context.type.heading),
        const Gap(AdminSpacing.lg),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Button.primary(
            'New contact',
            icon: Icons.add,
            onPressed: _open,
          ),
        ),
        if (created != null) ...[
          const Gap(AdminSpacing.lg),
          Text('Created $created', style: context.type.bodyMuted),
        ],
      ],
    );
  }
}

/// Opens the "New contact" dialog over [api]; resolves to the contact
/// created, or null when it is closed first. [submitAtOnce] presses Create
/// as the dialog opens.
Future<ContactDto?> showNewContactDialog(
  BuildContext context, {
  required FakeContactApi api,
  bool submitAtOnce = false,
}) => showModal<ContactDto>(
  context,
  builder: (_) => NewContactDialog(api: api, submitAtOnce: submitAtOnce),
);

/// The "New contact" dialog: a [ValueForm] around a [Modal], whose footer is
/// the form's [FormActions]. It closes with the contact once [api] has
/// created it; a failed create keeps it open, the reason beside Create.
class NewContactDialog extends StatefulWidget {
  final FakeContactApi api;

  /// Presses Create after the first frame.
  final bool submitAtOnce;

  const NewContactDialog({
    super.key,
    required this.api,
    this.submitAtOnce = false,
  });

  @override
  State<NewContactDialog> createState() => _NewContactDialogState();
}

class _NewContactDialogState extends State<NewContactDialog> {
  late final _form = ValueFormController<ContactDto>(
    read: (scope) => ContactFields(scope).toDto(),
    write: (scope, dto) => ContactFields(scope).fill(dto),
    rules: (scope) => contactRules(ContactFields(scope), widget.api),
    onSubmit: _create,
    requireChanges: false,
  );

  @override
  void initState() {
    super.initState();
    if (!widget.submitAtOnce) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _form.requestSubmit();
    });
  }

  Future<void> _create(ContactDto contact) async {
    await widget.api.create(contact);
    if (mounted) Navigator.of(context).pop(contact);
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fields = ContactFields(_form.scope);
    return ValueForm(
      controller: _form,
      child: Modal(
        title: 'New contact',
        onDismiss: () => Navigator.of(context).maybePop(),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Field(fields.name, label: 'Name'),
            const Gap(AdminSpacing.lg),
            Field(
              fields.email,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
            ),
            const Gap(AdminSpacing.lg),
            BooleanField(
              fields.vip,
              label: 'VIP',
              description: 'Priority support and invoicing',
            ),
          ],
        ),
        actions: [
          // Changes are not required, so Create is disabled only while
          // messages show, which the status of a form still clean does not
          // count: its hint says so rather than "No changes".
          ListenableBuilder(
            listenable: _form,
            builder: (context, _) => FormActions(
              controller: _form,
              commitLabel: 'Create',
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
