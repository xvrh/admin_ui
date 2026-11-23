// The shop's refusal of its settings reaches the form's fields: the shop
// names a field by its path in the settings it was sent, a zone's by the
// zone's index, and the form finds the cell.

import 'package:admin_ui/forms.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reference_admin/src/api/shop_api.dart';
import 'package:reference_admin/src/l10n/ref_strings.dart';
import 'package:reference_admin/src/screens/setup/shop_form.dart';

final _shop = ShopSettings.blank.copyWith(
  name: 'Potting Shed',
  supportEmail: 'help@example.com',
  shippingZones: const [
    ShippingZone(name: 'Home', countries: ['BE'], rateCents: 500),
    ShippingZone(name: 'Abroad', countries: ['FR'], rateCents: 900),
  ],
);

/// The shop's form, as the settings page builds it, whose save the shop
/// refuses for [refused].
ValueFormController<ShopSettings> _form(Map<String, String> refused) {
  const strings = RefStringsEn();
  final form = ValueFormController<ShopSettings>(
    read: (s) => ShopFields(s).read(_shop),
    write: (s, shop) => ShopFields(s).fill(shop),
    initial: _shop,
    rules: (s) => shopRules(ShopFields(s), () => strings.access),
    onSubmit: (_) async =>
        throw shopSubmitError(ValidationError(refused), strings),
  );
  addTearDown(form.dispose);
  ShopFields(form.scope).name.set('Potting Shed 2');
  return form;
}

void main() {
  test('a refusal names a field, the zones, and the field of a zone by '
      'its index', () async {
    final form = _form(const {
      'name': 'invalid',
      'shippingZones': 'invalid',
      'shippingZones.1.name': 'invalid',
      'shippingZones.0.rateCents': 'invalid',
    });
    await form.submit();
    final f = ShopFields(form.scope);
    expect(
      form.errors.keys,
      unorderedEquals([
        f.name.id,
        f.zones.id,
        f.zones.elements[1].name.id,
        f.zones.elements[0].rate.id,
      ]),
    );
    expect(form.submitError, const RefStringsEn().shell.errorValidation);
  });

  test('a field the form has not does not keep it from saving again', () async {
    final form = _form(const {'vatNumber': 'invalid'});
    await form.submit();
    expect(form.errors.keys, ['vatNumber']);
    expect(form.canSubmit, isFalse);
    ShopFields(form.scope).name.set('Potting Shed 3');
    expect(form.errors, isEmpty);
    expect(form.canSubmit, isTrue);
  });
}
