import 'dart:async';

import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import 'customer_form.dart';

enum _SaveMoment { validating, submitting, failed }

/// The customer form pinned in each moment of a save, on the screen's own
/// controller and fake API: the server checking the email just typed, the
/// save in flight, and a save the server refused, its reason in the save
/// bar.
class CustomerFormStatesDemo extends StatefulWidget {
  final _SaveMoment _moment;

  @Preview(name: 'Customer form (checking email)', wrapper: adminUiPreview)
  const CustomerFormStatesDemo.validating({super.key})
    : _moment = _SaveMoment.validating;

  @Preview(name: 'Customer form (saving)', wrapper: adminUiPreview)
  const CustomerFormStatesDemo.submitting({super.key})
    : _moment = _SaveMoment.submitting;

  @Preview(name: 'Customer form (save failed)', wrapper: adminUiPreview)
  const CustomerFormStatesDemo.failed({super.key})
    : _moment = _SaveMoment.failed;

  @override
  State<CustomerFormStatesDemo> createState() => _CustomerFormStatesDemoState();
}

class _CustomerFormStatesDemoState extends State<CustomerFormStatesDemo> {
  late final _api = switch (widget._moment) {
    _SaveMoment.failed => FakeContactApi(
      latency: Duration.zero,
    )..failNextSave = true,
    _ => _HeldContactApi(),
  };
  late final _form = contactFormController(
    _api,
    initial: FakeContactApi.stored,
  );

  @override
  void initState() {
    super.initState();
    final fields = ContactFields(_form.scope);
    switch (widget._moment) {
      case _SaveMoment.validating:
        fields.email.set(FakeContactApi.takenEmail);
        // Past the debounce, as the check would be a moment after typing.
        unawaited(_form.validate(fields: [fields.email.id]));
      case _SaveMoment.submitting:
      case _SaveMoment.failed:
        fields.name.set('Ada King');
        _form.requestSubmit();
    }
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ContactFormScreen(controller: _form);
}

/// Never answers: the email check stays pending, and the save in flight.
class _HeldContactApi extends FakeContactApi {
  _HeldContactApi() : super(latency: Duration.zero);

  @override
  Future<bool> emailInUse(String email) => Completer<bool>().future;

  @override
  Future<void> save(ContactDto dto) => Completer<void>().future;
}
