import 'dart:async';

import 'package:admin_ui/assets.dart';
import 'package:admin_ui/fields.dart';
import 'package:admin_ui/forms.dart';
import 'package:admin_ui/l10n.dart';
import 'package:admin_ui/shell.dart';
import 'package:admin_ui/theme.dart';
import 'package:admin_ui/widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../../api/shop_api.dart';
import '../../keys/catalogue_keys.dart';
import '../../l10n/money.dart';
import '../../l10n/ref_strings.dart';
import '../../routing/routes.dart';
import '../../services.dart';
import '../../widgets/page_width.dart';
import '../../widgets/status_meta.dart';
import 'catalogue_widgets.dart';
import 'product_diff.dart';
import 'product_form.dart';
import 'product_history.dart';

/// `/products/:id`: a product edited in three languages, and its history.
///
/// The page loads the product once and keeps its form across the two tabs,
/// so edits made on Details survive a look at History.
class ProductEditorScreen extends StatefulWidget {
  final String id;
  final ProductTab tab;

  const ProductEditorScreen({super.key, required this.id, required this.tab});

  @override
  State<ProductEditorScreen> createState() => _ProductEditorScreenState();
}

class _ProductEditorScreenState extends State<ProductEditorScreen> {
  late final ShopApi _api = context.api;
  late final _presence = _api.presence(widget.id);
  late CatalogueStrings _strings;

  /// The product as the shop last returned it: the form's baseline.
  Product? _product;
  Object? _error;
  CatalogueLookups _lookups = const CatalogueLookups();
  ValueFormController<Product>? _form;

  List<ProductRevision>? _revisions;
  Object? _revisionsError;

  /// The language the copy fields show.
  String _language = shopLanguages.first;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    if (widget.tab == ProductTab.history) unawaited(_loadRevisions());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _strings = context.strings.catalogue;
  }

  @override
  void didUpdateWidget(ProductEditorScreen old) {
    super.didUpdateWidget(old);
    if (widget.tab == ProductTab.history && _revisions == null) {
      unawaited(_loadRevisions());
    }
  }

  @override
  void dispose() {
    _form?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    final lookups = CatalogueLookups.load(_api)
        .catchError((Object _) => const CatalogueLookups());
    try {
      final product = await _api.product(widget.id);
      final loaded = await lookups;
      if (!mounted) return;
      _nameRecent(product);
      setState(() {
        _product = product;
        _lookups = loaded;
        _form ??= _controller(product);
      });
    } on ShopError catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _loadRevisions() async {
    setState(() => _revisionsError = null);
    try {
      final revisions = await _api.revisions(widget.id);
      if (mounted) setState(() => _revisions = revisions);
    } on ShopError catch (error) {
      if (mounted) setState(() => _revisionsError = error);
    }
  }

  void _nameRecent(Product product) =>
      context.services.recentTitles[ProductDetail(widget.id).uri.path] =
          product.name;

  ValueFormController<Product> _controller(Product product) =>
      ValueFormController<Product>(
        read: (scope) => ProductCells(scope).apply(_product!),
        write: (scope, value) => ProductCells(scope).fill(value),
        initial: product,
        rules: (scope) => productRules(
          ProductCells(scope),
          skuAvailable: (sku) => _api.skuAvailable(sku, exceptId: widget.id),
          strings: () => _strings,
        ),
        onSubmit: _save,
      );

  Future<void> _save(Product value) async {
    try {
      final saved = await _api.saveProduct(
        value,
        baseRevision: _product!.revision,
      );
      if (!mounted) return;
      _nameRecent(saved);
      setState(() {
        _product = saved;
        _revisions = null;
      });
    } on ValidationError catch (error) {
      // The shop names the fields as the form's cells are named; the sku is
      // the one it checks.
      final fields = ProductCells(_form!.scope);
      throw FormSubmitException(
        fieldErrors: {
          for (final MapEntry(:key, :value) in error.fields.entries)
            (key == 'sku' ? fields.sku.id : key): value == ValidationCodes.taken
                ? _strings.skuTaken
                : context.strings.shell.errorValidation,
        },
      );
    } on ConflictError {
      throw FormSubmitException(message: _strings.conflict);
    }
  }

  void _showTab(ProductTab tab) => unawaited(
    context.services.router.go(
      ProductDetail(widget.id, tab: tab),
      confirm: false,
    ),
  );

  Future<void> _restore(ProductRevision version) async {
    final n = context.adminFormats.integer(version.version);
    Product? restored;
    final confirmed = await showConfirmDialog(
      context,
      title: _strings.restoreTitle(n),
      message: _strings.restoreMessage(n),
      confirmLabel: _strings.restore,
      onConfirm: () async {
        restored = await _api.restoreRevision(widget.id, version.version);
      },
    );
    final product = restored;
    if (!confirmed || product == null || !mounted) return;
    setState(() {
      _product = product;
      _revisions = null;
    });
    _form!.seed(product);
    showCatalogueToast(context, _strings.restoredToast(n));
    _showTab(ProductTab.details);
  }

  void _restorePart(ProductRevision version, String key) {
    final form = _form!;
    ProductCells(form.scope)
        .fill(withFieldOf(form.value, version.snapshot, key));
    _showTab(ProductTab.details);
  }

  @override
  Widget build(BuildContext context) {
    final strings = _strings;
    final shell = context.strings.shell;
    final crumbs = [
      Crumb(
        shell.navProducts,
        onTap: () => unawaited(context.go(const Products())),
      ),
    ];
    if (_error case final error?) {
      return PageScaffold(
        key: CatalogueKeys.productPage,
        title: strings.notFoundTitle,
        breadcrumb: Breadcrumbs(crumbs),
        body: error is NotFoundError
            ? EmptyState(
                key: CatalogueKeys.notFound,
                icon: Icons.search_off_rounded,
                title: strings.notFoundTitle,
                message: strings.notFoundMessage,
              )
            : ErrorState(
                message: ErrorTextScope.describe(context, error),
                onRetry: _load,
              ),
      );
    }
    final form = _form;
    final product = _product;
    if (form == null || product == null) {
      return PageScaffold(
        key: CatalogueKeys.productPage,
        title: '',
        titleLoading: true,
        breadcrumb: Breadcrumbs(crumbs),
        maxWidth: pageMaxWidth,
        body: const _EditorSkeleton(),
      );
    }

    final language = Localizations.localeOf(context).languageCode;
    final readOnly = !context.services.session.can(Permission.editCatalogue);
    final details = widget.tab == ProductTab.details;
    final title = inLanguage(product.name, language);
    final page = PageScaffold(
      key: CatalogueKeys.productPage,
      title: title,
      titleTrailing: StatusPill(context.productStatusMeta(product.status)),
      subtitle: strings.updatedBy(
        formatDate(context, product.updatedAt),
        product.updatedBy,
      ),
      breadcrumb: Breadcrumbs([...crumbs, Crumb(title)]),
      actions: [_PresencePile(key: CatalogueKeys.presence, channel: _presence)],
      maxWidth: pageMaxWidth,
      tabs: Tabs(
        key: CatalogueKeys.tabs,
        tabs: [TabItem(strings.tabDetails), TabItem(strings.historyTitle)],
        selected: details ? 0 : 1,
        onChanged: (i) =>
            _showTab(i == 0 ? ProductTab.details : ProductTab.history),
      ),
      // History fills the page with a diff that scrolls on its own.
      scrollable: details,
      body: details
          ? _DetailsView(
              form: form,
              product: product,
              lookups: _lookups,
              language: _language,
              readOnly: readOnly,
              revisions: _revisions,
              onLanguage: (l) => setState(() => _language = l),
            )
          : ProductHistoryView(
              key: CatalogueKeys.history,
              revisions: _revisions,
              error: _revisionsError,
              onRetry: _loadRevisions,
              lookups: _lookups,
              onRestore: readOnly ? null : _restore,
              onRestorePart: readOnly ? null : _restorePart,
            ),
      // Nothing on History is edited, so it has no save bar; edits made on
      // Details wait there, and the leave guard still covers them.
      bottomBar: readOnly || !details
          ? null
          : FormSaveBar(
              key: CatalogueKeys.saveBar,
              controller: form,
              placement: SaveBarPlacement.bottom,
              commitLabel: strings.save,
              showDiscard: true,
            ),
    );

    final fields = ProductCells(form.scope);
    final lanes = [
      for (final l in shopLanguages) ...[
        fields.name.lane(l),
        fields.description.lane(l),
      ],
    ];
    return UnsavedChangesGuard(
      controller: form,
      enabled: !readOnly,
      child: ValueForm(
        controller: form,
        readOnly: readOnly,
        child: AssetSourceScope(
          source: _api.assets,
          child: ListenableBuilder(
            listenable: Listenable.merge(lanes),
            builder: (context, child) => LangScope(
              locales: productLocales(
                (l) =>
                    fields.name.lane(l).value.trim().isEmpty ||
                    fields.description.lane(l).value.trim().isEmpty,
              ),
              visibleLocales: {_language},
              sourceLocale: shopLanguages.first,
              activeLocale: _language,
              onVisibleLocalesChanged: (visible) {
                if (visible.isNotEmpty) {
                  setState(() => _language = visible.first);
                }
              },
              child: child!,
            ),
            child: FieldPresenceScope(
              channel: _presence,
              child: FormFieldCommands(child: page),
            ),
          ),
        ),
      ),
    );
  }
}

/// The Details tab: the product's fields in six groups.
class _DetailsView extends StatelessWidget {
  final ValueFormController<Product> form;
  final Product product;
  final CatalogueLookups lookups;
  final String language;
  final bool readOnly;
  final List<ProductRevision>? revisions;
  final ValueChanged<String> onLanguage;

  const _DetailsView({
    required this.form,
    required this.product,
    required this.lookups,
    required this.language,
    required this.readOnly,
    required this.revisions,
    required this.onLanguage,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.strings.catalogue;
    final shell = context.strings.shell;
    final api = context.api;
    final f = ProductCells(form.scope);
    final appLanguage = Localizations.localeOf(context).languageCode;
    const grid = FormColumns(medium: 2);
    const gap = Gap(AdminSpacing.xl);
    final formats = context.adminFormats;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (readOnly) ...[
          Alert(strings.readOnlyNote, key: CatalogueKeys.readOnly),
          gap,
        ],
        const ValidationSummary(
          key: CatalogueKeys.summary,
          margin: EdgeInsets.only(bottom: AdminSpacing.lg),
        ),
        FieldGroup(
          title: strings.sectionCopy,
          description: strings.sectionCopyHelp,
          boxed: true,
          actions: [
            ListenableBuilder(
              listenable: f.description.lane(language),
              builder: (context, _) => HistoryButton(
                draft: f.description.lane(language).value,
                baseline: product.description[language] ?? '',
                versions: [
                  for (final (i, r) in (revisions ?? const []).indexed)
                    FieldVersion(
                      label: strings.versionLabel(formats.integer(r.version)),
                      author: r.by,
                      initials: presenceInitials(r.by),
                      color: presenceColorFor(r.version),
                      time: formatDate(context, r.at),
                      current: i == 0,
                    ),
                ],
                onRevert: readOnly
                    ? null
                    : () => f.description
                          .lane(language)
                          .set(product.description[language] ?? ''),
              ),
            ),
          ],
          children: [
            ListenableBuilder(
              listenable: Listenable.merge([
                for (final l in shopLanguages) ...[
                  f.name.lane(l),
                  f.description.lane(l),
                ],
              ]),
              builder: (context, _) {
                final locales = LangScope.of(context).locales;
                final active = locales.firstWhere((l) => l.code == language);
                return Row(
                  children: [
                    Expanded(
                      child: LocaleTabs(
                        key: CatalogueKeys.localeTabs,
                        lanes: locales,
                        activeLocale: language,
                        onActiveLocaleChanged: onLanguage,
                        modified: f.changedLanguages(product),
                      ),
                    ),
                    const Gap(AdminSpacing.md),
                    LocaleStatusPill(status: active.status),
                  ],
                );
              },
            ),
            Field(f.name, key: CatalogueKeys.name, label: strings.fieldName),
            Field(
              f.description,
              key: CatalogueKeys.description,
              label: strings.fieldDescription,
              minLines: 3,
              maxLines: 6,
            ),
          ],
        ),
        gap,
        FieldGroup(
          title: strings.sectionPricing,
          boxed: true,
          columns: grid,
          children: [
            DecimalField(
              f.price,
              key: CatalogueKeys.price,
              label: strings.fieldPrice,
              prefix: '€',
            ),
            OptionalDecimalField(
              f.compareAt,
              key: CatalogueKeys.compareAt,
              label: strings.fieldCompareAt,
              description: strings.fieldCompareAtHelp,
              prefix: '€',
            ),
            NumberField(
              f.stock,
              key: CatalogueKeys.stockField,
              label: strings.fieldStock,
            ),
            NumberField(
              f.lowStockAt,
              key: CatalogueKeys.lowStockAt,
              label: strings.fieldLowStockAt,
            ),
          ],
        ),
        gap,
        FieldGroup(
          title: strings.sectionOrganisation,
          boxed: true,
          columns: grid,
          children: [
            Field(
              f.sku,
              key: CatalogueKeys.sku,
              label: strings.fieldSku,
              hint: 'PS-0000',
            ),
            SelectField(
              f.category,
              key: CatalogueKeys.category,
              label: strings.fieldCategory,
              options: [
                for (final c in lookups.categories.values)
                  SelectOption(
                    value: c.id,
                    label: inLanguage(c.name, appLanguage),
                  ),
              ],
            ),
            EnumSelectField<ProductStatus>(
              f.status,
              key: CatalogueKeys.status,
              label: strings.fieldStatus,
              values: ProductStatus.values,
              labelOf: shell.productStatus,
            ),
            ReferenceField<Supplier, String>(
              f.supplier,
              key: CatalogueKeys.supplier,
              label: strings.fieldSupplier,
              addLabel: strings.linkSupplier,
              searchHint: strings.searchSuppliers,
              idOf: (s) => s.id,
              // FRICTION(F-304): the shop searches suppliers but resolves
              // none by id, so the field resolves through a search.
              resolve: (ids) async {
                final all = await api.searchSuppliers('');
                return [
                  for (final s in all)
                    if (ids.contains(s.id)) s,
                ];
              },
              search: (query, {cursor}) async =>
                  ReferencePage(await api.searchSuppliers(query)),
              tile: (context, s) => ReferenceTileCard(
                title: s.name,
                subtitle: strings.supplierTerms(
                  s.country,
                  formats.integer(s.terms),
                ),
                icon: Icons.local_shipping_outlined,
              ),
            ),
            TagsField(
              f.tags,
              key: CatalogueKeys.tags,
              label: strings.fieldTags,
            ),
            OptionalDateField(
              f.availableFrom,
              key: CatalogueKeys.availableFrom,
              label: strings.fieldAvailableFrom,
            ),
            ColorField(
              f.labelColor,
              key: CatalogueKeys.labelColor,
              label: strings.fieldLabelColor,
            ),
            BooleanField(
              f.featured,
              key: CatalogueKeys.featured,
              label: strings.fieldFeatured,
              description: strings.fieldFeaturedDescription,
            ),
          ],
        ),
        gap,
        FieldGroup(
          title: strings.sectionPhotos,
          boxed: true,
          children: [
            AssetListField<PhotoCells>(
              f.photos,
              key: CatalogueKeys.photos,
              label: strings.fieldPhotos,
              image: (p) => p.image,
              cover: true,
            ),
          ],
        ),
        gap,
        FieldGroup(
          title: strings.sectionVariants,
          boxed: true,
          children: [
            RecordListField<VariantCells>(
              f.variants,
              key: CatalogueKeys.variants,
              label: strings.fieldVariants,
              addLabel: strings.addVariant,
              itemLabel: (v, i) =>
                  v.size.value.isEmpty ? strings.variantSize : v.size.value,
              item: (v) => FormGrid(
                columns: const FormColumns(compact: 2, medium: 4),
                children: [
                  Field(v.size, label: strings.variantSize),
                  Field(v.skuSuffix, label: strings.variantSkuSuffix),
                  DecimalField(
                    v.priceDelta,
                    label: strings.variantPriceDelta,
                    prefix: '€',
                  ),
                  NumberField(v.stock, label: strings.variantStock),
                ],
              ),
            ),
          ],
        ),
        gap,
        FieldGroup(
          title: strings.sectionCare,
          boxed: true,
          children: [
            KeyValueField(
              f.care,
              key: CatalogueKeys.care,
              label: strings.fieldCare,
              keyHint: strings.careKeyHint,
              valueHint: strings.careValueHint,
              addLabel: strings.addCare,
            ),
          ],
        ),
        gap,
      ],
    );
  }
}

/// Who else has this product open, following the channel.
// FRICTION(F-305): PresenceAvatars takes a fixed list of peers; following
// the channel is the page's job.
class _PresencePile extends StatefulWidget {
  final PresenceChannel channel;

  const _PresencePile({super.key, required this.channel});

  @override
  State<_PresencePile> createState() => _PresencePileState();
}

class _PresencePileState extends State<_PresencePile> {
  late void Function() _unsubscribe;

  @override
  void initState() {
    super.initState();
    _unsubscribe = widget.channel.onChange(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      PresenceAvatars(peers: presentPeers(widget.channel));
}

/// The editor's shape while the product loads.
class _EditorSkeleton extends StatelessWidget {
  const _EditorSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget field() => const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Skeleton(width: 96),
        Gap(AdminSpacing.sm),
        Skeleton(height: 36),
      ],
    );
    return SkeletonGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Skeleton(width: 220, height: 32),
          const Gap(AdminSpacing.xl),
          field(),
          const Gap(AdminSpacing.lg),
          field(),
          const Gap(AdminSpacing.lg),
          Row(
            children: [
              Expanded(child: field()),
              const Gap(AdminSpacing.xl),
              Expanded(child: field()),
            ],
          ),
        ],
      ),
    );
  }
}
