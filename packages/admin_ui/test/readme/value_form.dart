// The form sample under "Forms" in README.md, verbatim below the imports.
// docs_barrels_readme_test.dart fails when the two differ.

import 'package:admin_ui/admin_ui.dart';
import 'package:material_ui/material_ui.dart';

typedef Contact = ({String name, String email});

extension type ContactFields(FormScope _s) {
  ValueCell<String> get name => _s.text('name');
  ValueCell<String> get email => _s.text('email');
}

ValueFormController<Contact> contactForm(Future<void> Function(Contact) save) =>
    ValueFormController<Contact>(
      read: (s) {
        final f = ContactFields(s);
        return (name: f.name.value, email: f.email.value);
      },
      write: (s, contact) => ContactFields(s)
        ..name.set(contact.name)
        ..email.set(contact.email),
      onSubmit: save,
      rules: (s) {
        final f = ContactFields(s);
        return [
          FieldRules(
            f.name,
            validators: [Validators.required(), Validators.maxLength(80)],
          ),
          FieldRules(
            f.email,
            validators: [Validators.required(), Validators.email()],
          ),
        ];
      },
    );

class ContactEditor extends StatelessWidget {
  final ValueFormController<Contact> form;

  const ContactEditor({super.key, required this.form});

  @override
  Widget build(BuildContext context) {
    final f = ContactFields(form.scope);
    return ValueForm(
      controller: form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FormGrid(
            children: [
              Field(f.name, label: 'Name'),
              Field(f.email, label: 'Email'),
            ],
          ),
          FormActions(controller: form),
        ],
      ),
    );
  }
}
