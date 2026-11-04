import 'package:admin_ui/fields.dart';
import 'package:admin_ui/forms.dart';
import 'package:admin_ui/theme.dart';
import 'package:admin_ui/widgets.dart' show FieldStateScope;
import 'package:material_ui/material_ui.dart';

import '../../api/shop_api.dart';
import '../../keys/access_keys.dart';
import '../../l10n/ref_strings.dart';

// The shop's settings as a form: the handles, the rules and the sections
// the first-run wizard and the shop settings page share.

/// The currencies the shop can price in.
const shopCurrencies = ['EUR', 'GBP', 'CHF'];

String currencySymbol(String code) => switch (code) {
  'EUR' => '€',
  'GBP' => '£',
  _ => code,
};

/// Typed handles over the form's cells, one per [ShopSettings] field.
extension type ShopFields(FormScope _s) {
  ValueCell<String> get name => _s.text('name');
  ValueCell<String> get supportEmail => _s.text('supportEmail');
  ValueCell<String> get currency => _s.text('currency');
  ValueCell<double> get taxRate => _s.decimal('taxRatePercent');
  ValueCell<List<String>> get languages => _s.list('languages');
  RecordListCell<ZoneFields> get zones =>
      _s.recordList('shippingZones', build: ZoneFields.new);

  /// [base] with the form's values: what is saved.
  ShopSettings read(ShopSettings base) => base.copyWith(
    name: name.value.trim(),
    supportEmail: supportEmail.value.trim(),
    currency: currency.value,
    taxRatePercent: taxRate.value,
    languages: [
      for (final code in shopLanguages)
        if (languages.value.contains(code)) code,
    ],
    shippingZones: [for (final zone in zones.elements) zone.read()],
  );

  void fill(ShopSettings shop) {
    name.set(shop.name);
    supportEmail.set(shop.supportEmail);
    currency.set(shop.currency);
    taxRate.set(shop.taxRatePercent);
    languages.set(shop.languages);
    final rows = zones;
    while (rows.elements.length > shop.shippingZones.length) {
      rows.removeAt(rows.elements.length - 1);
    }
    while (rows.elements.length < shop.shippingZones.length) {
      rows.add();
    }
    for (final (i, zone) in shop.shippingZones.indexed) {
      rows.elements[i].fill(zone);
    }
  }

  /// The row of [zone] in [zones], found by its cells: each read of
  /// `elements` hands out new handles.
  int indexOf(ZoneFields zone) =>
      zones.elements.indexWhere((z) => z.name.id == zone.name.id);
}

extension type ZoneFields(RecordScope _e) {
  ValueCell<String> get name => _e.text('name');
  ValueCell<List<String>> get countries => _e.list('countries');

  /// The flat rate, in the shop's currency (not cents).
  ValueCell<double> get rate => _e.decimal('rate');

  ShippingZone read() => ShippingZone(
    name: name.value.trim(),
    countries: [for (final c in countries.value) c.trim().toUpperCase()],
    rateCents: (rate.value * 100).round(),
  );

  void fill(ShippingZone zone) {
    name.set(zone.name);
    countries.set(zone.countries);
    rate.set(zone.rateCents / 100);
  }
}

/// What a valid shop is. [strings] is read when a rule runs, so its words
/// follow the app's language.
Iterable<ValidationRule> shopRules(
  ShopFields f,
  AccessStrings Function() strings,
) => [
  FieldRules<String>(
    f.name,
    validators: [Validators.required(), Validators.maxLength(60)],
  ),
  FieldRules<String>(
    f.supportEmail,
    validators: [Validators.required(), Validators.email()],
  ),
  FieldRules<double>(
    f.taxRate,
    validators: [Validators.min(0), Validators.max(30)],
  ),
  FieldRules<List<String>>(f.languages, validators: [Validators.required()]),
  ListRules(f.zones, message: strings().zonesRequired),
  for (final zone in f.zones.elements) ...[
    FieldRules<String>(zone.name, validators: [Validators.required()]),
    FieldRules<List<String>>(
      zone.countries,
      validators: [Validators.required()],
    ),
    FieldRules<double>(zone.rate, validators: [Validators.min(0)]),
  ],
];

/// The shop's refusal as the form shows it: each field the shop named under
/// its cell, and the reason in the save status.
FormSubmitException shopSubmitError(
  ShopError error,
  ShopFields f,
  RefStrings strings,
) {
  if (error is! ValidationError) {
    return FormSubmitException(message: strings.shell.error(error));
  }
  // FRICTION(F-103): a row's cell ids are opaque, so a server path such
  // as `shippingZones.1.name` is mapped by walking the handles.
  String? cellId(String path) {
    final parts = path.split('.');
    switch (parts) {
      case ['name']:
        return f.name.id;
      case ['supportEmail']:
        return f.supportEmail.id;
      case ['currency']:
        return f.currency.id;
      case ['taxRatePercent']:
        return f.taxRate.id;
      case ['languages']:
        return f.languages.id;
      case ['shippingZones']:
        return f.zones.id;
      case ['shippingZones', final index, final field]:
        final rows = f.zones.elements;
        final i = int.tryParse(index);
        if (i == null || i < 0 || i >= rows.length) return f.zones.id;
        return switch (field) {
          'name' => rows[i].name.id,
          'countries' => rows[i].countries.id,
          _ => rows[i].rate.id,
        };
    }
    return null;
  }

  return FormSubmitException(
    message: strings.shell.errorValidation,
    fieldErrors: {
      for (final path in error.fields.keys)
        ?cellId(path): strings.shell.errorValidation,
    },
  );
}

/// Name, contact, currency, VAT and languages, on a grid of two columns
/// that stacks on a phone.
class ShopDetailsFields extends StatelessWidget {
  final ShopFields fields;

  const ShopDetailsFields({super.key, required this.fields});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final f = fields;
    return FormGrid(
      children: [
        Field(
          f.name,
          key: AccessKeys.shopName,
          label: strings.access.shopName,
          description: strings.access.shopNameDescription,
          autofillHints: const [AutofillHints.organizationName],
        ),
        Field(
          f.supportEmail,
          key: AccessKeys.supportEmail,
          label: strings.access.supportEmail,
          description: strings.access.supportEmailDescription,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
        ),
        SelectField(
          f.currency,
          key: AccessKeys.currency,
          label: strings.access.currency,
          description: strings.access.currencyDescription,
          options: [
            for (final code in shopCurrencies)
              SelectOption(
                value: code,
                label: strings.access.currencyName(code),
              ),
          ],
        ),
        PercentField(
          f.taxRate,
          key: AccessKeys.taxRate,
          label: strings.access.taxRate,
          description: strings.access.taxRateDescription,
        ),
        FormGridItem(
          fullWidth: true,
          child: MultiSelectField(
            f.languages,
            key: AccessKeys.languages,
            label: strings.access.languages,
            description: strings.access.languagesDescription,
            options: [
              for (final code in shopLanguages)
                SelectOption(
                  value: code,
                  label: strings.shell.languageName(code),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The shipping zones, one row each: a name, its countries and its flat
/// rate in the shop's currency.
class ShippingZonesField extends StatelessWidget {
  final ShopFields fields;

  const ShippingZonesField({super.key, required this.fields});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings.access;
    final f = fields;
    return RecordListField<ZoneFields>(
      f.zones,
      key: AccessKeys.zones,
      label: strings.zones,
      description: strings.zonesDescription,
      addLabel: strings.addZone,
      required: true,
      itemLabel: (zone, index) => strings.zoneItem(zone.name.value, index),
      item: (zone) {
        final index = f.indexOf(zone);
        return FormGrid(
          columns: const FormColumns(compact: 1, medium: 3),
          columnGap: AdminSpacing.lg,
          children: [
            Field(
              zone.name,
              key: AccessKeys.zoneName(index),
              label: strings.zoneName,
            ),
            TagsField(
              zone.countries,
              key: AccessKeys.zoneCountries(index),
              label: strings.zoneCountries,
              addHint: strings.zoneCountriesHint,
            ),
            ListenableBuilder(
              listenable: f.currency,
              builder: (context, _) => DecimalField(
                zone.rate,
                key: AccessKeys.zoneRate(index),
                label: strings.zoneRate,
                prefix: currencySymbol(f.currency.value),
                step: 0.5,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A percentage with its sign after the number, bound like the kit's
/// presets.
// FRICTION(F-104): DecimalField takes a prefix but no unit, though its
// NumberBody has one; the field is bound by hand to reach it.
class PercentField extends StatelessWidget {
  final ValueCell<double> cell;
  final String label;
  final String? description;

  const PercentField(
    this.cell, {
    super.key,
    required this.label,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final state = FieldStateScope.of(context);
    final editable = state.enabled && !state.readOnly;
    return bind<double>(
      context,
      cell,
      label: label,
      description: description,
      body: (lane) => ValueListenableBuilder<double>(
        valueListenable: lane,
        builder: (context, value, _) => NumberBody(
          value: value,
          decimals: 1,
          step: 0.5,
          unit: '%',
          onChanged: editable
              ? (n) {
                  if (n != null) lane.set(n.toDouble());
                }
              : null,
        ),
      ),
    );
  }
}
