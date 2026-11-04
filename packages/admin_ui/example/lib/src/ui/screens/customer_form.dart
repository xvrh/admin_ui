import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';

/// The reference shape for a customer detail screen: load a DTO over RPC,
/// edit it through typed handles, and save the whole value back — no CRDT,
/// no draft, and no controller of the screen's own.
///
/// A [ValueFormController] does the bookkeeping. Its `read` and `write` map
/// the DTO onto the handles, which are exactly what codegen would emit;
/// [ValueFormController.seed] makes the loaded value the baseline, so the
/// form knows when it is dirty and what Discard goes back to; its rules say
/// what a valid contact is, down to an email address the server checks as
/// the user types; and its submit posts the value and maps the server's
/// refusal. The fields declare none of this: they are bound to the cells.
///
/// A [ValueForm] around the save bar and the fields shows it: each message
/// in the line under its field, kept free so nothing moves when one
/// appears; the required marks the rules imply; "Checking…" while the email
/// is checked; and after a refused save (the save bar's "1 field needs
/// attention", or Cmd+S / Ctrl+S) the focus on the first invalid field. The
/// save bar and the unsaved-changes guard read the same controller.
class CustomerFormDemo extends StatefulWidget {
  /// Opens with the name cleared: unsaved, and invalid.
  final bool invalid;

  @Preview(name: 'Customer form (RPC + LocalScope)', wrapper: adminUiPreview)
  const CustomerFormDemo({super.key}) : invalid = false;

  @Preview(name: 'Customer form (invalid edit)', wrapper: adminUiPreview)
  const CustomerFormDemo.invalid({super.key}) : invalid = true;

  @override
  State<CustomerFormDemo> createState() => _CustomerFormDemoState();
}

// ── The wire DTO + a fake RPC endpoint ───────────────────────────────────────

class ContactDto {
  final String name;
  final String email;
  final bool vip;
  final List<PhoneDto> phones;
  const ContactDto({
    required this.name,
    required this.email,
    required this.vip,
    required this.phones,
  });
}

class PhoneDto {
  final String label;
  final String number;
  const PhoneDto(this.label, this.number);
}

/// Stands in for the generated RPC client, each call taking [latency].
///
/// [failNextSave] makes the next save or create fail as a busy server would,
/// so the save bar's error and retry can be exercised; [takenEmail] is the
/// address another contact already has.
class FakeContactApi {
  FakeContactApi({this.latency = const Duration(milliseconds: 400)});

  final Duration latency;
  bool failNextSave = false;

  /// The contact [load] returns.
  static const stored = ContactDto(
    name: 'Ada Lovelace',
    email: 'ada@example.com',
    vip: true,
    phones: [PhoneDto('Office', '+32 2 555 01 23')],
  );

  /// The address [emailInUse] says another contact has.
  static const takenEmail = 'grace@example.com';

  /// Why a save fails while [failNextSave] is set.
  static const busyMessage = 'The server is busy. Try again.';

  Future<ContactDto> load() async {
    await _wait();
    return stored;
  }

  Future<void> save(ContactDto dto) async {
    await _wait();
    if (failNextSave) {
      failNextSave = false;
      throw const FormSubmitException(message: busyMessage);
    }
  }

  Future<void> create(ContactDto dto) => save(dto);

  /// Whether another contact has [email].
  Future<bool> emailInUse(String email) async {
    await _wait();
    return email.trim().toLowerCase() == takenEmail;
  }

  Future<void> _wait() async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
  }
}

// ── Typed handles, exactly as codegen would emit them ────────────────────────

extension type ContactFields(FormScope _s) {
  ValueCell<String> get name => _s.text('name');
  ValueCell<String> get email => _s.text('email');
  ValueCell<bool> get vip => _s.boolean('vip');
  RecordListCell<PhoneFields> get phones =>
      _s.recordList('phones', build: PhoneFields.new);

  ContactDto toDto() => ContactDto(
    name: name.value,
    email: email.value,
    vip: vip.value,
    phones: [for (final phone in phones.elements) phone.toDto()],
  );

  void fill(ContactDto dto) {
    name.set(dto.name);
    email.set(dto.email);
    vip.set(dto.vip);
    final rows = phones;
    while (rows.elements.length > dto.phones.length) {
      rows.removeAt(rows.elements.length - 1);
    }
    while (rows.elements.length < dto.phones.length) {
      rows.add();
    }
    for (final (i, phone) in dto.phones.indexed) {
      rows.elements[i].fill(phone);
    }
  }
}

extension type PhoneFields(RecordScope _e) {
  ValueCell<String> get label => _e.text('label');
  ValueCell<String> get number => _e.text('number');

  PhoneDto toDto() => PhoneDto(label.value, number.value);

  void fill(PhoneDto dto) {
    label.set(dto.label);
    number.set(dto.number);
  }
}

// ── The form: DTO ⇄ cells, the rules, RPC at submit ─────────────────────────

/// What a valid contact is: a name of at most 80 characters, and an email
/// address no other contact has, which [api] checks as the user types.
Iterable<ValidationRule> contactRules(
  ContactFields fields,
  FakeContactApi api,
) => [
  FieldRules(
    fields.name,
    validators: [Validators.required(), Validators.maxLength(80)],
  ),
  FieldRules(
    fields.email,
    validators: [Validators.required(), Validators.email()],
    asyncValidators: [
      (String email) async => await api.emailInUse(email)
          ? 'Already used by another contact'
          : null,
    ],
  ),
];

/// The customer form's controller: the contact read from and written to
/// the cells through [ContactFields], checked by [contactRules] and saved
/// through [api]. It starts from [initial], or blank until it is seeded
/// with the loaded contact.
ValueFormController<ContactDto> contactFormController(
  FakeContactApi api, {
  ContactDto? initial,
}) => ValueFormController(
  read: (scope) => ContactFields(scope).toDto(),
  write: (scope, dto) => ContactFields(scope).fill(dto),
  initial: initial,
  rules: (scope) => contactRules(ContactFields(scope), api),
  onSubmit: api.save,
);

// ── The screen ───────────────────────────────────────────────────────────────

/// The customer screen over [controller]: the save bar above the fields,
/// both in the [ValueForm], behind the unsaved-changes guard. [below] goes
/// under the fields.
class ContactFormScreen extends StatelessWidget {
  final ValueFormController<ContactDto> controller;
  final Widget? below;

  const ContactFormScreen({super.key, required this.controller, this.below});

  @override
  Widget build(BuildContext context) {
    return UnsavedChangesGuard(
      controller: controller,
      child: Scaffold(
        backgroundColor: context.colors.surface,
        body: ValueForm(
          controller: controller,
          child: Column(
            children: [
              FormSaveBar(
                controller: controller,
                leading: Text('Edit contact', style: context.type.heading),
                showDiscard: true,
              ),
              Expanded(child: _fields(ContactFields(controller.scope))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fields(ContactFields fields) {
    final below = this.below;
    return ListView(
      padding: const EdgeInsets.all(AdminSpacing.xl),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                const Gap(AdminSpacing.lg),
                RecordListField(
                  fields.phones,
                  label: 'Phone numbers',
                  addLabel: 'Add phone',
                  item: (PhoneFields p) => Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Field(p.label, label: 'Label')),
                      const Gap(AdminSpacing.md),
                      Expanded(
                        flex: 2,
                        child: Field(
                          p.number,
                          label: 'Number',
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                    ],
                  ),
                ),
                if (below != null) ...[const Gap(AdminSpacing.xxxl), below],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CustomerFormDemoState extends State<CustomerFormDemo> {
  final _api = FakeContactApi();
  late final _form = contactFormController(_api);
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    _api.load().then((dto) {
      if (!mounted) return;
      _form.seed(dto);
      if (widget.invalid) ContactFields(_form.scope).name.set('');
      setState(() => _loaded = true);
    });
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Center(child: Spinner());
    return ContactFormScreen(controller: _form, below: _demoChrome(context));
  }

  /// Demo-only controls, not part of the pattern.
  Widget _demoChrome(BuildContext context) {
    final save = shortcutLabel(
      context,
      primaryModifierActivator(LogicalKeyboardKey.keyS),
    );
    return Panel(
      padding: const EdgeInsets.all(AdminSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Demo: clear the name or enter ${FakeContactApi.takenEmail} to '
              'see the checks. $save saves; the switch fails the next save.',
              style: context.type.caption.copyWith(
                color: context.colors.foregroundMuted,
              ),
            ),
          ),
          const Gap(AdminSpacing.lg),
          // A failed save turns it back off.
          ListenableBuilder(
            listenable: _form,
            builder: (context, _) => Toggle(
              value: _api.failNextSave,
              label: 'Fail next save',
              onChanged: (v) => setState(() => _api.failNextSave = v),
            ),
          ),
        ],
      ),
    );
  }
}
