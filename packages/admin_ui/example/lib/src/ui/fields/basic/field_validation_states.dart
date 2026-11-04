import 'dart:async';

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../../preview_shell.dart';
import '../../demo_kit.dart';

/// A field in each validation state a form engine gives it, every form a
/// [ValueForm] over a [ValueFormController] seeded with fixed values.
///
/// The first row sets one field side by side, pristine and invalid: the
/// pristine one keeps the room of its message line, so the field after it
/// starts at the same height in both. The pinned states (the message
/// revealed, a check under way) are the controllers' own, set up as the
/// demo mounts.
class FieldValidationStatesDemo extends StatefulWidget {
  @Preview(name: 'Validation states', wrapper: adminUiPreview)
  const FieldValidationStatesDemo({super.key});

  @override
  State<FieldValidationStatesDemo> createState() =>
      _FieldValidationStatesDemoState();
}

extension type _Account(FormScope _s) {
  ValueCell<String> get company => _s.text('company');
  ValueCell<String> get email => _s.text('email');
  ValueCell<String> get handle => _s.text('handle');
  ValueCell<String> get customerId => _s.text('customerId');
  ValueCell<String> get plan => _s.text('plan');
  ValueCell<String> get nickname => _s.text('nickname');
}

typedef _Values = Map<String, String>;

const _fields = [
  'company',
  'email',
  'handle',
  'customerId',
  'plan',
  'nickname',
];

/// A username availability check that never answers: the field stays
/// "Checking…".
Future<String?> _neverAnswers(String _) => Completer<String?>().future;

ValueFormController<_Values> _account(_Values seed) =>
    ValueFormController<_Values>(
      read: (s) => {for (final name in _fields) name: s.text(name).value},
      write: (s, values) {
        for (final MapEntry(:key, :value) in values.entries) {
          s.text(key).set(value);
        }
      },
      initial: seed,
      rules: (s) {
        final f = _Account(s);
        return [
          FieldRules(f.company, validators: [Validators.required()]),
          FieldRules(
            f.email,
            validators: [Validators.required(), Validators.email()],
          ),
          FieldRules(
            f.handle,
            validators: [Validators.required(), Validators.minLength(3)],
            asyncValidators: [_neverAnswers],
          ),
          FieldRules(f.nickname, validators: [Validators.maxLength(40)]),
        ];
      },
    );

class _FieldValidationStatesDemoState extends State<FieldValidationStatesDemo> {
  final _pristine = _account(const {
    'company': 'Northwind Traders',
    'email': 'orders@northwind.test',
  });
  final _invalid = _account(const {
    'company': '',
    'email': 'orders@northwind.test',
  });
  final _states = _account(const {
    'handle': 'ada',
    'customerId': 'CUS-20417',
    'plan': 'Team',
  });

  @override
  void initState() {
    super.initState();
    unawaited(_invalid.validate(fields: [_Account(_invalid.scope).company.id]));
    final handle = _Account(_states.scope).handle;
    handle.set('ada.lovelace');
    unawaited(_states.validate(fields: [handle.id]));
  }

  @override
  void dispose() {
    _pristine.dispose();
    _invalid.dispose();
    _states.dispose();
    super.dispose();
  }

  Widget _contact(ValueFormController<_Values> controller) {
    final f = _Account(controller.scope);
    return ValueForm(
      controller: controller,
      child: FieldGroup(
        children: [
          Field(f.company, label: 'Company', required: true),
          Field(f.email, label: 'Billing email', required: true),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final f = _Account(_states.scope);
    return DemoPage(
      maxWidth: 720,
      children: [
        const DemoSection('Pristine and invalid: the next field stays put'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: DemoVariant('Pristine', _contact(_pristine))),
            const Gap(AdminSpacing.xl),
            Expanded(child: DemoVariant('Invalid', _contact(_invalid))),
          ],
        ),
        const DemoSection('Checking, read-only, disabled and optional'),
        ValueForm(
          controller: _states,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DemoVariant(
                'Checking: an async validator is under way',
                Field(f.handle, label: 'Username', required: true),
              ),
              DemoVariant(
                'Read-only',
                Field(
                  f.customerId,
                  label: 'Customer ID',
                  required: true,
                  readOnly: true,
                ),
              ),
              DemoVariant(
                'Disabled',
                Field(f.plan, label: 'Plan', required: true, enabled: false),
              ),
              DemoVariant(
                'Optional: a rule checks it but does not require it, so '
                'Carbon marks it; the other themes mark the required ones',
                Field(f.nickname, label: 'Nickname', hint: 'How we greet you'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
