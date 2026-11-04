import 'dart:async';

import 'package:admin_ui/collection.dart';
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
import '../../widgets/money_text.dart';
import '../../widgets/page_width.dart';
import '../../widgets/status_meta.dart';
import 'catalogue_widgets.dart';

/// `/products`: the catalogue as a list, its saved views, filters, columns
/// and bulk status changes, with stock edited in place.
class ProductListScreen extends StatefulWidget {
  /// The saved view the route names, applied once the views are loaded.
  final String? savedView;

  const ProductListScreen({super.key, this.savedView});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late final ShopApi _api = context.api;
  late final _collection = CollectionController<Product>(
    fetcher: _api.listProducts,
    rowKey: (p) => p.id,
    initialQuery: const CollectionQuery(
      sortKey: ProductFields.name,
      pageSize: 25,
    ),
  );
  late final _views = SavedViewsController<Product>(
    store: _api.savedViews,
    collectionKey: CollectionKeys.products,
    collection: _collection,
    readColumns: () => _layout,
    writeColumns: (layout) => setState(() => _layout = layout ?? _defaults),
  );
  CatalogueLookups _lookups = const CatalogueLookups();

  static const _defaults = ColumnLayout(
    hidden: {ProductFields.updatedAt},
    order: [
      ProductFields.name,
      ProductFields.status,
      ProductFields.category,
      ProductFields.price,
      ProductFields.stock,
      _languagesColumn,
      ProductFields.updatedAt,
    ],
  );
  static const _languagesColumn = 'languages';
  ColumnLayout _layout = _defaults;

  @override
  void initState() {
    super.initState();
    CatalogueLookups.load(_api).then(
      (lookups) {
        if (mounted) setState(() => _lookups = lookups);
      },
      // Rows keep their placeholders; the list itself says what failed.
      onError: (Object _) {},
    );
    _views.addListener(_applyRouteView);
  }

  /// Selects the route's saved view once the views have loaded.
  void _applyRouteView() {
    final id = widget.savedView;
    if (_views.loading || _views.views.isEmpty) return;
    _views.removeListener(_applyRouteView);
    if (id == null || _views.activeId == id) return;
    if (_viewById(id) case final view?) _views.select(view);
  }

  SavedView? _viewById(String? id) =>
      _views.views.where((v) => v.id == id).firstOrNull;

  @override
  void didUpdateWidget(ProductListScreen old) {
    super.didUpdateWidget(old);
    final id = widget.savedView;
    if (id == old.savedView || id == _views.activeId) return;
    if (id == null) {
      _views.clearView();
    } else if (_viewById(id) case final view?) {
      _views.select(view);
    }
  }

  @override
  void dispose() {
    _views.removeListener(_applyRouteView);
    _views.dispose();
    _collection.dispose();
    super.dispose();
  }

  bool get _canEdit => context.services.session.can(Permission.editCatalogue);

  void _open(Product product) =>
      unawaited(context.go(ProductDetail(product.id)));

  void _selectView(SavedView? view) {
    if (view == null) {
      _views.clearView();
    } else {
      _views.select(view);
    }
    unawaited(
      context.services.router.go(Products(savedView: view?.id), confirm: false),
    );
  }

  /// Saves a stock count typed into the table. The row changes at once and
  /// goes back if the shop refuses.
  // FRICTION(F-302): TableTextEditor.number cannot refuse a fraction or a
  // negative, so a count the shop will refuse still closes the editor.
  void _commitStock(Product product, num typed) {
    if (typed != typed.truncate()) {
      _stockRefused(
        const ShopError.validation({'stock': ValidationCodes.invalid}),
      );
      return;
    }
    final stock = typed.toInt();
    if (stock == product.stock) return;
    unawaited(
      _collection
          .optimistic(
            update: (rows) => [
              for (final p in rows)
                p.id == product.id ? p.copyWith(stock: stock) : p,
            ],
            commit: () => _api.patchStock(product.id, stock),
          )
          .catchError((Object error) => _stockRefused(error)),
    );
  }

  void _stockRefused(Object error) {
    if (!mounted) return;
    final strings = context.strings.catalogue;
    showCatalogueToast(
      context,
      error is ValidationError
          ? strings.stockInvalid
          : ErrorTextScope.describe(context, error),
      title: strings.stockNotSaved,
      severity: Severity.danger,
    );
  }

  Future<void> _setStatus(ProductStatus status) async {
    final strings = context.strings.catalogue;
    final rows = _collection.selected.toList();
    final ids = {for (final p in rows) p.id};
    _collection.clearSelection();
    try {
      await _collection.optimistic(
        update: (items) => [
          for (final p in items)
            ids.contains(p.id) ? p.copyWith(status: status) : p,
        ],
        commit: () => Future.wait([
          for (final p in rows)
            _api.saveProduct(
              p.copyWith(status: status),
              baseRevision: p.revision,
            ),
        ]),
      );
      if (!mounted) return;
      showCatalogueToast(
        context,
        strings.bulkDone(
          rows.length,
          context.adminFormats.integer(rows.length),
        ),
      );
    } on ShopError catch (error) {
      if (!mounted) return;
      showCatalogueToast(
        context,
        ErrorTextScope.describe(context, error),
        severity: Severity.danger,
      );
    }
    unawaited(_collection.refresh());
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings.catalogue;
    final compact = AdminBreakpoint.of(context).isCompact;
    final canEdit = _canEdit;
    final columns = _columns(context, editable: canEdit && !compact);
    return PageScaffold(
      maxWidth: pageMaxWidth,
      key: CatalogueKeys.productsPage,
      title: context.strings.shell.navProducts,
      scrollable: false,
      actions: [
        if (canEdit)
          Button.primary(
            strings.newProduct,
            key: CatalogueKeys.newProduct,
            icon: Icons.add,
            onPressed: () => unawaited(context.go(const NewProduct())),
          ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListenableBuilder(
            listenable: _views,
            builder: (context, _) => SavedViewsBar(
              key: CatalogueKeys.savedViews,
              // FRICTION(F-201): a shared view's name is stored text, so the
              // seeded ones are renamed into the app's language here.
              views: [
                for (final v in _views.views)
                  v.copyWith(name: strings.savedViewName(v.id, v.name)),
              ],
              activeId: _views.activeId,
              dirty: _views.dirty,
              onSelect: _selectView,
              onSelectAll: () => _selectView(null),
              allLabel: strings.allProducts,
              onDiscardChanges: _views.discardChanges,
              error: _views.lastError,
              onRetry: _views.retry,
              onDismissError: _views.clearError,
            ),
          ),
          const Gap(AdminSpacing.md),
          ListenableBuilder(
            listenable: _collection,
            builder: (context, _) => CollectionHeader<Product>(
              controller: _collection,
              toolbar: _toolbar(context, columns),
              bulkActions: [
                if (canEdit) ...[
                  BulkAction(
                    strings.bulkActivate,
                    icon: Icons.check_circle_outline,
                    onPressed: () => _setStatus(ProductStatus.active),
                  ),
                  BulkAction(
                    strings.bulkDraft,
                    icon: Icons.edit_note_outlined,
                    onPressed: () => _setStatus(ProductStatus.draft),
                  ),
                  BulkAction(
                    strings.bulkArchive,
                    icon: Icons.archive_outlined,
                    onPressed: () => _setStatus(ProductStatus.archived),
                  ),
                ],
              ],
              selectedLabel: (n) =>
                  strings.productsSelected(n, context.adminFormats.integer(n)),
            ),
          ),
          const Gap(AdminSpacing.md),
          Expanded(
            child: Panel(
              child: Collection<Product>(
                key: CatalogueKeys.collection,
                controller: _collection,
                columns: _layout.apply(columns),
                columnWidths: _layout.widths,
                viewMode: compact
                    ? CollectionViewMode.cards
                    : CollectionViewMode.table,
                cardBuilder: _card,
                onRowTap: _open,
                editTrigger: TableEditTrigger.doubleTap,
                selectable: canEdit,
                density: context.services.appearance.density,
                empty: EmptyState(
                  icon: Icons.local_florist_outlined,
                  title: strings.emptyTitle,
                  message: strings.emptyMessage,
                ),
                onHideColumn: (key) =>
                    setState(() => _layout = _layout.withVisible(key, false)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolbar(BuildContext context, List<TableColumn<Product>> columns) {
    final strings = context.strings.catalogue;
    final shell = context.strings.shell;
    final language = Localizations.localeOf(context).languageCode;
    return CollectionToolbar(
      searchController: _collection.searchController,
      searchHint: strings.searchHint,
      filterBar: FilterBar(
        key: CatalogueKeys.filters,
        fields: [
          OptionsFilterField(ProductFields.status, strings.filterStatus, [
            for (final s in ProductStatus.values)
              FilterOption(s.name, shell.productStatus(s)),
          ]),
          OptionsFilterField(ProductFields.category, strings.filterCategory, [
            for (final c in _lookups.categories.values)
              FilterOption(c.id, inLanguage(c.name, language)),
          ]),
          BoolFilterField(ProductFields.lowStock, strings.filterLowStock),
          BoolFilterField(
            ProductFields.missingArabic,
            strings.filterMissingArabic,
          ),
        ],
        active: _collection.query.filters,
        onChanged: _collection.setFilters,
      ),
      trailing: [
        if (!AdminBreakpoint.of(context).isCompact)
          ColumnChooserButton(
            key: CatalogueKeys.columns,
            columns: ColumnChoice.fromColumns(columns),
            layout: _layout,
            onChanged: (layout) => setState(() => _layout = layout),
            onReset: () => setState(() => _layout = _defaults),
          ),
      ],
    );
  }

  List<TableColumn<Product>> _columns(
    BuildContext context, {
    required bool editable,
  }) {
    final strings = context.strings.catalogue;
    final language = Localizations.localeOf(context).languageCode;
    return [
      TableColumn(
        id: ProductFields.name,
        label: strings.colProduct,
        flex: 3,
        minWidth: 200,
        pinned: true,
        hideable: false,
        sortKey: ProductFields.name,
        cellBuilder: (context, p) => TableIdentity(
          key: CatalogueKeys.product(p.id),
          leading: ProductThumb(image: _lookups.coverOf(p)),
          title: inLanguage(p.name, language),
          subtitle: p.sku,
        ),
      ),
      TableColumn(
        id: ProductFields.status,
        label: strings.colStatus,
        fixed: 116,
        cellBuilder: (context, p) =>
            StatusPill(context.productStatusMeta(p.status)),
      ),
      TableColumn(
        id: ProductFields.category,
        label: strings.colCategory,
        flex: 1,
        minWidth: 110,
        cellBuilder: (context, p) =>
            Text(_lookups.categoryName(p.categoryId, language)),
      ),
      TableColumn(
        id: ProductFields.price,
        label: strings.colPrice,
        fixed: 110,
        numeric: true,
        sortKey: ProductFields.price,
        cell: (p) => MoneyText(p.priceCents),
      ),
      TableColumn(
        id: ProductFields.stock,
        label: strings.colStock,
        fixed: 120,
        numeric: true,
        sortKey: ProductFields.stock,
        cellBuilder: (context, p) =>
            _StockCell(key: CatalogueKeys.stock(p.id), product: p),
        editBuilder: editable
            ? (p, session) => TableTextEditor.number(
                key: CatalogueKeys.stockEditor,
                session: session,
                value: p.stock,
                fractionDigits: 0,
                onCommit: (value) => _commitStock(p, value),
              )
            : null,
      ),
      TableColumn(
        id: _languagesColumn,
        label: strings.colTranslations,
        fixed: 136,
        cell: (p) => LocaleRollup(locales: productLanguages(p)),
      ),
      TableColumn(
        id: ProductFields.updatedAt,
        label: strings.colUpdated,
        fixed: 136,
        sortKey: ProductFields.updatedAt,
        cellBuilder: (context, p) => Text(
          formatDate(context, p.updatedAt),
          style: tableMutedStyle(context),
        ),
      ),
    ];
  }

  Widget _card(BuildContext context, Product p) {
    final language = Localizations.localeOf(context).languageCode;
    final colors = context.colors;
    return Padding(
      key: CatalogueKeys.product(p.id),
      padding: const EdgeInsets.all(AdminSpacing.md),
      child: Row(
        children: [
          ProductThumb(image: _lookups.coverOf(p), size: 56),
          const Gap(AdminSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inLanguage(p.name, language),
                  style: context.type.bodyStrong,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(AdminSpacing.xxs),
                Text(
                  '${p.sku} · ${_lookups.categoryName(p.categoryId, language)}',
                  style: context.type.caption.copyWith(
                    color: colors.foregroundMutedOnTint,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(AdminSpacing.sm),
                StatusPill(context.productStatusMeta(p.status)),
              ],
            ),
          ),
          const Gap(AdminSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              MoneyText(p.priceCents, style: context.type.bodyStrong),
              const Gap(AdminSpacing.xs),
              _StockCell(product: p),
            ],
          ),
        ],
      ),
    );
  }
}

/// A stock count, flagged when it has reached the product's alert level.
class _StockCell extends StatelessWidget {
  final Product product;

  const _StockCell({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final count = Text(context.adminFormats.integer(product.stock));
    if (!product.isLowStock) return count;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tag(context.strings.catalogue.lowStock, severity: Severity.warning),
        const Gap(AdminSpacing.sm),
        count,
      ],
    );
  }
}
