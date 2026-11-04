import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';

/// A product page whose last field the server refuses on save: the form
/// reveals it whole, its message a gutter above the save bar docked under
/// the page, not only its input with the message cut off by the bar.
///
/// The page saves as it opens, and opens again in each theme, since a
/// theme's field heights move the field the reveal scrolled to.
class FormsRevealDemo extends StatelessWidget {
  @Preview(name: 'Revealed field (bottom save bar)', wrapper: adminUiPreview)
  const FormsRevealDemo({super.key});

  @override
  Widget build(BuildContext context) =>
      _RevealedPage(key: ValueKey(context.adminTokens));
}

class _RevealedPage extends StatefulWidget {
  const _RevealedPage({super.key});

  @override
  State<_RevealedPage> createState() => _RevealedPageState();
}

typedef _Product = ({
  String name,
  String description,
  double price,
  int stock,
  String category,
  String sku,
});

extension type _ProductFields(FormScope _s) {
  ValueCell<String> get name => _s.text('name');
  ValueCell<String> get description => _s.text('description');
  ValueCell<double> get price => _s.decimal('price');
  ValueCell<int> get stock => _s.number('stock');
  ValueCell<String> get category => _s.text('category');
  ValueCell<String> get sku => _s.text('sku');

  _Product read() => (
    name: name.value,
    description: description.value,
    price: price.value,
    stock: stock.value,
    category: category.value,
    sku: sku.value,
  );

  void write(_Product product) {
    name.set(product.name);
    description.set(product.description);
    price.set(product.price);
    stock.set(product.stock);
    category.set(product.category);
    sku.set(product.sku);
  }
}

class _RevealedPageState extends State<_RevealedPage> {
  late final ValueFormController<_Product> _form = ValueFormController(
    read: (s) => _ProductFields(s).read(),
    write: (s, product) => _ProductFields(s).write(product),
    initial: (
      name: 'Desk lamp',
      description: 'An adjustable lamp with a weighted base and a warm LED.',
      price: 49,
      stock: 12,
      category: 'lighting',
      sku: 'DL-0100',
    ),
    rules: (s) => [
      FieldRules(_ProductFields(s).name, validators: [Validators.required()]),
      FieldRules(_ProductFields(s).sku, validators: [Validators.required()]),
    ],
    requireChanges: false,
    onSubmit: (_) async => throw FormSubmitException(
      fieldErrors: {
        _ProductFields(_form.scope).sku.id:
            'Another product already uses this SKU',
      },
    ),
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
    final f = _ProductFields(_form.scope);
    const columns = FormColumns(compact: 1, medium: 2);
    return Scaffold(
      backgroundColor: context.colors.background,
      body: ValueForm(
        controller: _form,
        child: PageScaffold(
          title: 'Desk lamp',
          maxWidth: 760,
          bottomBar: FormSaveBar(
            controller: _form,
            placement: SaveBarPlacement.bottom,
            showDiscard: true,
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FieldGroup(
                title: 'Copy',
                boxed: true,
                children: [
                  Field(f.name, label: 'Name'),
                  Field(
                    f.description,
                    label: 'Description',
                    minLines: 4,
                    maxLines: 6,
                  ),
                ],
              ),
              const Gap(AdminSpacing.xl),
              FieldGroup(
                title: 'Pricing',
                boxed: true,
                columns: columns,
                children: [
                  DecimalField(f.price, label: 'Price', prefix: '€'),
                  NumberField(f.stock, label: 'Stock'),
                ],
              ),
              const Gap(AdminSpacing.xl),
              FieldGroup(
                title: 'Organisation',
                boxed: true,
                columns: columns,
                children: [
                  SelectField(
                    f.category,
                    label: 'Category',
                    options: const [
                      SelectOption(value: 'lighting', label: 'Lighting'),
                      SelectOption(value: 'desks', label: 'Desks'),
                    ],
                  ),
                  Field(f.sku, label: 'SKU', hint: 'DL-0000'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
