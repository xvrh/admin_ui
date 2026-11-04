import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

/// A [FormWizard] that signs a user up in three steps over one
/// [ValueFormController]: Account, whose username a fake server checks as
/// it is typed and whose password is confirmed by a rule across two fields;
/// Profile; and Review, which reads the values back and creates the account.
///
/// Next checks only the step's own fields; a step whose fields fail stays,
/// in error in the indicator, with its messages in place and listed in the
/// summary between the indicator and the step.
class FormWizardDemo extends StatefulWidget {
  /// Opens on a step whose fields need fixing, Next refused.
  final bool blocked;

  @Preview(name: 'Form wizard', wrapper: adminUiPreview)
  const FormWizardDemo({super.key}) : blocked = false;

  @Preview(name: 'Form wizard (blocked step)', wrapper: adminUiPreview)
  const FormWizardDemo.blocked({super.key}) : blocked = true;

  @override
  State<FormWizardDemo> createState() => _FormWizardDemoState();
}

typedef _SignUp = ({
  String username,
  String password,
  String name,
  String email,
  String team,
  bool welcome,
});

extension type _SignUpFields(FormScope _s) {
  ValueCell<String> get username => _s.text('username');
  ValueCell<String> get password => _s.text('password');
  ValueCell<String> get confirm => _s.text('confirm');
  ValueCell<String> get name => _s.text('name');
  ValueCell<String> get email => _s.text('email');
  ValueCell<String> get team => _s.text('team');
  ValueCell<bool> get welcome => _s.boolean('welcome');

  _SignUp read() => (
    username: username.value,
    password: password.value,
    name: name.value,
    email: email.value,
    team: team.value,
    welcome: welcome.value,
  );

  void write(_SignUp value) {
    username.set(value.username);
    password.set(value.password);
    confirm.set(value.password);
    name.set(value.name);
    email.set(value.email);
    team.set(value.team);
    welcome.set(value.welcome);
  }
}

/// The usernames the fake server says are taken.
const _taken = {'admin', 'root'};

Future<String?> _usernameAvailable(String username) async {
  await Future<void>.delayed(const Duration(milliseconds: 600));
  return _taken.contains(username) ? 'That username is taken' : null;
}

Iterable<ValidationRule> _rules(_SignUpFields f) => [
  FieldRules(
    f.username,
    validators: [
      Validators.required(),
      Validators.minLength(3),
      Validators.pattern(
        RegExp(r'^[a-z0-9_]+$'),
        message: 'Use lowercase letters, digits and _',
      ),
    ],
    asyncValidators: [_usernameAvailable],
  ),
  FieldRules(
    f.password,
    validators: [Validators.required(), Validators.minLength(8)],
  ),
  FieldRules(f.confirm, validators: [Validators.required()]),
  FormRule(
    watch: [f.password, f.confirm],
    target: f.confirm,
    check: (_) => f.confirm.value == f.password.value
        ? null
        : 'The passwords do not match',
  ),
  FieldRules(f.name, validators: [Validators.required()]),
  FieldRules(f.email, validators: [Validators.required(), Validators.email()]),
];

class _FormWizardDemoState extends State<FormWizardDemo> {
  late final _form = ValueFormController<_SignUp>(
    read: (s) => _SignUpFields(s).read(),
    write: (s, value) => _SignUpFields(s).write(value),
    initial: (
      username: '',
      password: '',
      name: '',
      email: '',
      team: '',
      welcome: true,
    ),
    rules: (s) => _rules(_SignUpFields(s)),
    onSubmit: (_) => Future<void>.delayed(const Duration(milliseconds: 800)),
  );

  _SignUpFields get _fields => _SignUpFields(_form.scope);

  @override
  void initState() {
    super.initState();
    if (widget.blocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _pressNext();
      });
    }
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  /// Presses the wizard's Next, as a user with the fields still empty would.
  void _pressNext() {
    final next = context.adminL10n.fields.wizardNext;
    var pressed = false;
    void visit(Element element) {
      if (pressed) return;
      final widget = element.widget;
      if (widget is Button && widget.label == next) {
        pressed = true;
        widget.onPressed?.call();
        return;
      }
      element.visitChildren(visit);
    }

    context.visitChildElements(visit);
  }

  @override
  Widget build(BuildContext context) {
    final f = _fields;
    return DemoPage(
      maxWidth: 720,
      children: [
        Text('Create an account', style: context.type.heading),
        const Gap(AdminSpacing.xxl),
        FormWizard(
          controller: _form,
          finishLabel: 'Create account',
          summary: const ValidationSummary(),
          steps: [
            FormWizardStep(
              title: 'Account',
              subtitle: 'Sign-in details',
              fields: [f.username, f.password, f.confirm],
              builder: (context) => _Fields([
                Field(
                  f.username,
                  label: 'Username',
                  description: 'Lowercase letters, digits and _',
                  autofillHints: const [AutofillHints.newUsername],
                ),
                _PasswordField(f.password, label: 'Password'),
                _PasswordField(f.confirm, label: 'Confirm password'),
              ]),
            ),
            FormWizardStep(
              title: 'Profile',
              subtitle: 'How others see you',
              fields: [f.name, f.email, f.team],
              builder: (context) => _Fields([
                Field(
                  f.name,
                  label: 'Full name',
                  autofillHints: const [AutofillHints.name],
                ),
                Field(
                  f.email,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                ),
                Field(f.team, label: 'Team'),
              ]),
            ),
            FormWizardStep(
              title: 'Review',
              subtitle: 'Check and create',
              fields: const [],
              builder: (context) => _Review(f),
            ),
          ],
        ),
        const Gap(AdminSpacing.xxl),
        Text(
          'Demo: ${_taken.join(' and ')} are taken usernames.',
          style: context.type.caption.copyWith(
            color: context.colors.foregroundMuted,
          ),
        ),
      ],
    );
  }
}

/// A step's fields, one under the other.
class _Fields extends StatelessWidget {
  final List<Widget> children;

  const _Fields(this.children);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, child) in children.indexed) ...[
          if (i > 0) const Gap(AdminSpacing.lg),
          child,
        ],
      ],
    );
  }
}

/// A new password bound to [cell], hidden until revealed.
class _PasswordField extends StatelessWidget {
  final ValueCell<String> cell;
  final String label;

  const _PasswordField(this.cell, {required this.label});

  @override
  Widget build(BuildContext context) => bind<String>(
    context,
    cell,
    label: label,
    body: (lane) => ValueListenableBuilder<String>(
      valueListenable: lane,
      builder: (context, value, _) => PasswordField(
        value: value,
        onChanged: lane.set,
        icon: null,
        autofillHints: const [AutofillHints.newPassword],
      ),
    ),
  );
}

/// The values entered, to check before creating the account.
class _Review extends StatelessWidget {
  final _SignUpFields f;

  const _Review(this.f);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListenableBuilder(
          listenable: Listenable.merge([f.username, f.name, f.email, f.team]),
          builder: (context, _) => DescriptionList(
            items: [
              DescriptionItem('Username', value: f.username.value),
              DescriptionItem('Full name', value: f.name.value),
              DescriptionItem('Email', value: f.email.value),
              DescriptionItem('Team', value: f.team.value),
            ],
          ),
        ),
        const Gap(AdminSpacing.xl),
        BooleanField(
          f.welcome,
          label: 'Welcome email',
          description: 'Send the new user a link to sign in',
        ),
      ],
    );
  }
}
