import 'dart:async';

import 'package:admin_ui/fields.dart';
import 'package:admin_ui/forms.dart';
import 'package:admin_ui/shell.dart';
import 'package:admin_ui/theme.dart';
import 'package:admin_ui/widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../../api/shop_api.dart';
import '../../keys/catalogue_keys.dart';
import '../../l10n/ref_strings.dart';
import '../../routing/routes.dart';
import '../../services.dart';
import 'catalogue_widgets.dart';
import 'product_form.dart';

/// The new-product form's cells.
extension type DraftCells(FormScope _s) {
  ValueCell<String> get name => _s.text('name');
  ValueCell<String> get sku => _s.text('sku');
  ValueCell<String> get category => _s.text('category');
  ValueCell<double> get price => _s.decimal('price');
  ValueCell<int> get stock => _s.number('stock');
  ValueCell<ProductStatus> get status => _s.enumCell(
    'status',
    encode: (s) => s.name,
    decode: ProductStatus.values.byName,
    fallback: ProductStatus.draft,
  );

  ProductDraft read() => ProductDraft(
    sku: sku.value.trim(),
    name: {shopLanguages.first: name.value.trim()},
    categoryId: category.value,
    priceCents: (price.value * 100).round(),
    stock: stock.value,
    status: status.value,
  );

  void fill(ProductDraft draft) {
    name.set(draft.name[shopLanguages.first] ?? '');
    sku.set(draft.sku);
    category.set(draft.categoryId);
    price.set(draft.priceCents / 100);
    stock.set(draft.stock);
    status.set(draft.status);
  }
}

/// `/products/new`: the essentials of a product, then its editor.
class NewProductScreen extends StatefulWidget {
  const NewProductScreen({super.key});

  @override
  State<NewProductScreen> createState() => _NewProductScreenState();
}

class _NewProductScreenState extends State<NewProductScreen> {
  late final ShopApi _api = context.api;
  late CatalogueStrings _strings;
  CatalogueLookups _lookups = const CatalogueLookups();

  late final _form = ValueFormController<ProductDraft>(
    read: (scope) => DraftCells(scope).read(),
    write: (scope, draft) => DraftCells(scope).fill(draft),
    initial: const ProductDraft(
      sku: '',
      name: {},
      categoryId: '',
      priceCents: 0,
    ),
    // The blank form is itself worth submitting: Create shows what is
    // missing rather than staying disabled.
    requireChanges: false,
    rules: (scope) {
      final f = DraftCells(scope);
      return [
        FieldRules<String>(
          f.name,
          validators: [Validators.required(), Validators.maxLength(80)],
        ),
        FieldRules<String>(
          f.sku,
          validators: [Validators.required(), checkSkuFormat],
          asyncValidators: [
            (String sku) async =>
                await _api.skuAvailable(sku.trim()) ? null : _strings.skuTaken,
          ],
        ),
        FieldRules<String>(f.category, validators: [Validators.required()]),
        FieldRules<double>(
          f.price,
          validators: [Validators.required(), Validators.min(0.01)],
        ),
        FieldRules<int>(
          f.stock,
          validators: [Validators.required(), Validators.min(0)],
        ),
      ];
    },
    onSubmit: _create,
  );

  @override
  void initState() {
    super.initState();
    CatalogueLookups.load(_api).then((lookups) {
      if (mounted) setState(() => _lookups = lookups);
    }, onError: (Object _) {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _strings = context.strings.catalogue;
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _create(ProductDraft draft) async {
    final Product product;
    try {
      product = await _api.createProduct(draft);
    } on ValidationError catch (error) {
      if (!mounted) rethrow;
      throw FormSubmitException(
        fieldErrors: {
          for (final MapEntry(:key, :value) in error.fields.entries)
            key: value == ValidationCodes.taken
                ? _strings.skuTaken
                : context.strings.shell.errorValidation,
        },
      );
    }
    if (!mounted) return;
    showCatalogueToast(context, _strings.createdToast);
    // Saved, so there is nothing for the leave guard to ask about.
    unawaited(
      context.services.router.go(ProductDetail(product.id), confirm: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = _strings;
    final shell = context.strings.shell;
    final language = Localizations.localeOf(context).languageCode;
    final f = DraftCells(_form.scope);
    return UnsavedChangesGuard(
      controller: _form,
      child: ValueForm(
        controller: _form,
        child: PageScaffold(
          key: CatalogueKeys.newProductPage,
          title: strings.newProductTitle,
          subtitle: strings.newProductSubtitle,
          breadcrumb: Breadcrumbs([
            Crumb(
              shell.navProducts,
              onTap: () => unawaited(context.go(const Products())),
            ),
            Crumb(strings.newProductTitle),
          ]),
          maxWidth: 720,
          actions: [
            FormActions(controller: _form, commitLabel: strings.create),
          ],
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ValidationSummary(
                key: CatalogueKeys.summary,
                margin: EdgeInsets.only(bottom: AdminSpacing.lg),
              ),
              FieldGroup(
                boxed: true,
                columns: const FormColumns(medium: 2),
                children: [
                  FormGridItem(
                    fullWidth: true,
                    child: Field(
                      f.name,
                      key: CatalogueKeys.newName,
                      label: strings.fieldName,
                    ),
                  ),
                  Field(
                    f.sku,
                    key: CatalogueKeys.newSku,
                    label: strings.fieldSku,
                    hint: 'PS-0000',
                  ),
                  SelectField(
                    f.category,
                    key: CatalogueKeys.newCategory,
                    label: strings.fieldCategory,
                    options: [
                      for (final c in _lookups.categories.values)
                        SelectOption(
                          value: c.id,
                          label: inLanguage(c.name, language),
                        ),
                    ],
                  ),
                  DecimalField(
                    f.price,
                    key: CatalogueKeys.newPrice,
                    label: strings.fieldPrice,
                    prefix: '€',
                  ),
                  NumberField(
                    f.stock,
                    key: CatalogueKeys.newStock,
                    label: strings.fieldStock,
                  ),
                  EnumSelectField<ProductStatus>(
                    f.status,
                    key: CatalogueKeys.newStatus,
                    label: strings.fieldStatus,
                    values: ProductStatus.values,
                    labelOf: shell.productStatus,
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
