import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

/// A [ValidationSummary] over a form with fields to fix, pinned after a
/// refused save: each message links to its field, and the summary goes as
/// the fields are fixed, its margin with it.
class ValidationSummaryDemo extends StatefulWidget {
  @Preview(name: 'Validation summary', wrapper: adminUiPreview)
  const ValidationSummaryDemo({super.key});

  @override
  State<ValidationSummaryDemo> createState() => _ValidationSummaryDemoState();
}

typedef _Venue = ({String name, String email, String website, int seats});

extension type _VenueFields(FormScope _s) {
  ValueCell<String> get name => _s.text('name');
  ValueCell<String> get email => _s.text('email');
  ValueCell<String> get website => _s.text('website');
  ValueCell<int> get seats => _s.number('seats');
}

class _ValidationSummaryDemoState extends State<ValidationSummaryDemo> {
  late final _form = ValueFormController<_Venue>(
    read: (s) {
      final f = _VenueFields(s);
      return (
        name: f.name.value,
        email: f.email.value,
        website: f.website.value,
        seats: f.seats.value,
      );
    },
    write: (s, value) {
      final f = _VenueFields(s);
      f.name.set(value.name);
      f.email.set(value.email);
      f.website.set(value.website);
      f.seats.set(value.seats);
    },
    initial: (name: '', email: 'events@', website: 'harbour-hall', seats: 0),
    rules: (s) {
      final f = _VenueFields(s);
      return [
        FieldRules(f.name, validators: [Validators.required()]),
        FieldRules(
          f.email,
          validators: [Validators.required(), Validators.email()],
        ),
        FieldRules(f.website, validators: [Validators.url()]),
        FieldRules(f.seats, validators: [Validators.min(1)]),
      ];
    },
    requireChanges: false,
    onSubmit: (_) => Future<void>.delayed(const Duration(milliseconds: 600)),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _form.requestSubmit();
    });
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = _VenueFields(_form.scope);
    return DemoPage(
      maxWidth: 560,
      children: [
        ValueForm(
          controller: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('New venue', style: context.type.heading),
              const Gap(AdminSpacing.xl),
              const ValidationSummary(
                margin: EdgeInsets.only(bottom: AdminSpacing.xl),
              ),
              Field(f.name, label: 'Name'),
              const Gap(AdminSpacing.lg),
              Field(
                f.email,
                label: 'Booking email',
                keyboardType: TextInputType.emailAddress,
              ),
              const Gap(AdminSpacing.lg),
              Field(
                f.website,
                label: 'Website',
                keyboardType: TextInputType.url,
              ),
              const Gap(AdminSpacing.lg),
              NumberField(f.seats, label: 'Seats'),
              const Gap(AdminSpacing.xl),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: ListenableBuilder(
                  listenable: _form,
                  builder: (context, _) => Button.primary(
                    MaterialLocalizations.of(context).saveButtonLabel,
                    loading: _form.status == FormStatus.submitting,
                    onPressed: _form.requestSubmit,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
