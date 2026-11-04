import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';

/// A site's settings page on the form engine: a `ValueFormController` over
/// the settings record, a `ValueForm` around the page, and a `FormSaveBar`
/// docked under it. The general settings sit in a boxed group of two
/// columns, which stack in a phone-sized window, with the description
/// across both; the digest's frequency shows only while the digest is on.
///
/// [SettingsFormDemo.invalid] opens with the loaded contact email edited to
/// a malformed one: its message shows in place, the fields beside and below
/// it keep their positions, and the save bar says a field needs attention.
class SettingsFormDemo extends StatefulWidget {
  /// Opens with invalid edits, their messages shown.
  final bool invalid;

  @Preview(name: 'Settings form', wrapper: adminUiPreview)
  const SettingsFormDemo({super.key}) : invalid = false;

  @Preview(name: 'Settings form (invalid)', wrapper: adminUiPreview)
  const SettingsFormDemo.invalid({super.key}) : invalid = true;

  @override
  State<SettingsFormDemo> createState() => _SettingsFormDemoState();
}

/// The settings record, as loaded from and saved to the server.
typedef _Settings = ({
  String siteName,
  String contactEmail,
  String timezone,
  String language,
  String description,
  bool digest,
  String digestFrequency,
});

/// Typed handles on the settings' cells.
extension type _SettingsFields(FormScope _s) {
  ValueCell<String> get siteName => _s.text('siteName');
  ValueCell<String> get contactEmail => _s.text('contactEmail');
  ValueCell<String> get timezone => _s.text('timezone');
  ValueCell<String> get language => _s.text('language');
  ValueCell<String> get description => _s.text('description');
  ValueCell<bool> get digest => _s.boolean('digest');
  ValueCell<String> get digestFrequency => _s.text('digestFrequency');

  _Settings read() => (
    siteName: siteName.value,
    contactEmail: contactEmail.value,
    timezone: timezone.value,
    language: language.value,
    description: description.value,
    digest: digest.value,
    digestFrequency: digestFrequency.value,
  );

  void write(_Settings settings) {
    siteName.set(settings.siteName);
    contactEmail.set(settings.contactEmail);
    timezone.set(settings.timezone);
    language.set(settings.language);
    description.set(settings.description);
    digest.set(settings.digest);
    digestFrequency.set(settings.digestFrequency);
  }

  List<ValidationRule> rules() => [
    FieldRules(
      siteName,
      validators: [Validators.required(), Validators.maxLength(60)],
    ),
    FieldRules(
      contactEmail,
      validators: [Validators.required(), Validators.email()],
    ),
    FieldRules(description, validators: [Validators.maxLength(280)]),
    FieldRules(
      digestFrequency,
      validators: [Validators.required()],
      visibleWhen: () => digest.value,
      dependsOn: [digest],
    ),
  ];
}

class _SettingsFormDemoState extends State<SettingsFormDemo> {
  static const _loaded = (
    siteName: 'Harbor Notes',
    contactEmail: 'editors@example.com',
    timezone: 'Europe/Paris',
    language: 'en',
    description:
        'A weekly journal of small harbours, their boats and the people '
        'who keep them.',
    digest: true,
    digestFrequency: 'weekly',
  );

  static const _timezones = [
    SelectOption(value: 'America/New_York', label: 'New York (UTC−5)'),
    SelectOption(value: 'UTC', label: 'UTC'),
    SelectOption(value: 'Europe/Paris', label: 'Paris (UTC+1)'),
    SelectOption(value: 'Asia/Tokyo', label: 'Tokyo (UTC+9)'),
  ];

  static const _languages = [
    SelectOption(value: 'en', label: 'English'),
    SelectOption(value: 'fr', label: 'Français'),
    SelectOption(value: 'ar', label: 'العربية'),
  ];

  static const _frequencies = [
    SelectOption(value: 'daily', label: 'Daily'),
    SelectOption(value: 'weekly', label: 'Weekly'),
    SelectOption(value: 'monthly', label: 'Monthly'),
  ];

  final _form = ValueFormController<_Settings>(
    read: (s) => _SettingsFields(s).read(),
    write: (s, settings) => _SettingsFields(s).write(settings),
    rules: (s) => _SettingsFields(s).rules(),
    onSubmit: (_) => Future.delayed(const Duration(milliseconds: 600)),
  );

  @override
  void initState() {
    super.initState();
    _form.seed(_loaded);
    if (widget.invalid) {
      _SettingsFields(_form.scope).contactEmail.set('editors@example');
    }
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = _SettingsFields(_form.scope);
    const columns = FormColumns(compact: 1, medium: 2);
    return Scaffold(
      backgroundColor: context.colors.background,
      body: ValueForm(
        controller: _form,
        child: PageScaffold(
          title: 'Site settings',
          subtitle: 'How the site presents itself, and what it emails you.',
          maxWidth: 860,
          bottomBar: FormSaveBar(
            controller: _form,
            placement: SaveBarPlacement.bottom,
            showDiscard: true,
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FieldGroup(
                title: 'General',
                boxed: true,
                columns: columns,
                children: [
                  Field(f.siteName, label: 'Site name'),
                  Field(
                    f.contactEmail,
                    label: 'Contact email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SelectField(
                    f.timezone,
                    label: 'Timezone',
                    options: _timezones,
                  ),
                  SelectField(
                    f.language,
                    label: 'Language',
                    options: _languages,
                  ),
                  FormGridItem(
                    fullWidth: true,
                    child: Field(
                      f.description,
                      label: 'Description',
                      description:
                          'Shown under the site name in search '
                          'results and link previews.',
                      minLines: 3,
                      maxLines: 6,
                      maxLength: 280,
                    ),
                  ),
                ],
              ),
              const Gap(AdminSpacing.xl),
              FieldGroup(
                title: 'Notifications',
                boxed: true,
                columns: columns,
                children: [
                  BooleanField(
                    f.digest,
                    label: 'Email digest',
                    description: 'New comments, in one email.',
                  ),
                  SelectField(
                    f.digestFrequency,
                    label: 'Frequency',
                    options: _frequencies,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
