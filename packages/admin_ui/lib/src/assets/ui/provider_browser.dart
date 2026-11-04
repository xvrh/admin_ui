import 'package:material_ui/material_ui.dart';

import '../../common/load_state_area.dart';
import '../../common/ui/delayed_loading.dart';
import '../../common/ui/empty_state.dart';
import '../../common/ui/error_state.dart';
import '../../common/ui/error_text.dart';
import '../../common/ui/search_field.dart';
import '../../common/ui/spinner.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../theme/spacing.dart';
import '../external_provider.dart';
import 'asset_library.dart' show AssetLibrary;
import 'media_tile.dart';

/// Browses a single [ExternalAssetProvider]: a search box + facet filters over a
/// grid of watermarked [items], single-select, with a footer that confirms the
/// pick (which the host turns into a license + import).
///
/// View-pure — it renders the [items] it's handed and emits intent via
/// callbacks; the host owns the query, filters and the search round-trip.
/// Give it a bounded height: the grid scrolls and pages like
/// [AssetLibrary]'s (see [MediaGrid]).
class ProviderBrowser extends StatelessWidget {
  final String providerLabel;

  /// Already filtered/searched by the host; rendered as-is.
  final List<ProviderItem> items;

  final String query;

  /// Reports the search once typing has paused for [searchDebounce].
  final ValueChanged<String>? onQueryChanged;

  /// How long typing has to pause before [onQueryChanged] reports it;
  /// submitting or clearing reports at once. [Duration.zero] reports every
  /// keystroke.
  final Duration searchDebounce;

  final ProviderFilters filters;
  final ValueChanged<ProviderFilters>? onFiltersChanged;

  final String? selectedId;
  final ValueChanged<ProviderItem>? onSelect;

  /// Loading with nothing to show yet fills the body with a spinner; loading
  /// over [items] already shown keeps them, under a progress bar.
  final bool loading;
  final Object? error;
  final VoidCallback? onRetry;

  /// Words [error] for the error state; [ErrorTextScope.describe] when null.
  final String Function(Object error)? errorText;

  /// How many results the provider has for the search, when known.
  final int? total;

  /// The provider has more results than [items]: [onLoadMore] fetches the
  /// next page, called as the grid nears its end and from a "Load more"
  /// button.
  final bool hasMore;
  final VoidCallback? onLoadMore;

  /// The next page is on its way; [onLoadMore] waits for it.
  final bool loadingMore;

  final VoidCallback? onCancel;

  /// Enabled only when an item is selected; the host runs the license/import.
  final VoidCallback? onConfirm;

  /// The confirm action's label; "Use image" in the app's language by
  /// default.
  final String? confirmLabel;

  const ProviderBrowser({
    super.key,
    required this.providerLabel,
    required this.items,
    this.query = '',
    this.onQueryChanged,
    this.searchDebounce = const Duration(milliseconds: 300),
    this.filters = const ProviderFilters(),
    this.onFiltersChanged,
    this.selectedId,
    this.onSelect,
    this.loading = false,
    this.error,
    this.onRetry,
    this.errorText,
    this.total,
    this.hasMore = false,
    this.onLoadMore,
    this.loadingMore = false,
    this.onCancel,
    this.onConfirm,
    this.confirmLabel,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.adminL10n.assets;
    final picked = selectedId != null && items.any((it) => it.id == selectedId);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Toolbar(
          query: query,
          onQueryChanged: onQueryChanged,
          searchDebounce: searchDebounce,
          filters: filters,
          onFiltersChanged: onFiltersChanged,
          providerLabel: providerLabel,
        ),
        const Divider(height: 1),
        Flexible(child: _body(context)),
        SelectionFooter(
          icon: Icons.workspace_premium_outlined,
          status: picked
              ? strings.licenseNotice(1)
              : strings.selectImageToLicense,
          muted: true,
          confirmLabel: confirmLabel ?? strings.useImage,
          onCancel: onCancel,
          onConfirm: selectedId == null ? null : onConfirm,
        ),
      ],
    );
  }

  Widget _body(BuildContext context) {
    final strings = context.adminL10n.assets;
    if (loading && items.isEmpty) {
      return LoadStateArea(
        padding: const EdgeInsets.symmetric(vertical: AdminSpacing.xxxl),
        child: LoadingPanel(message: context.adminL10n.searching, minHeight: 0),
      );
    }
    if (error case final error?) {
      return LoadStateArea(
        padding: const EdgeInsets.symmetric(vertical: AdminSpacing.xxl),
        child: ErrorState(
          minHeight: 0,
          title: context.adminL10n.searchFailed,
          message:
              errorText?.call(error) ?? ErrorTextScope.describe(context, error),
          onRetry: onRetry,
        ),
      );
    }
    if (items.isEmpty) {
      final searching = query.isNotEmpty || !filters.isEmpty;
      return LoadStateArea(
        padding: const EdgeInsets.symmetric(vertical: AdminSpacing.xxl),
        child: EmptyState(
          minHeight: 0,
          icon: searching ? Icons.search_off_rounded : Icons.search_rounded,
          title: searching
              ? context.adminL10n.noResults
              : strings.findStockImages,
          message: searching
              ? strings.noResultsHint
              : strings.stockSearchPrompt(providerLabel),
        ),
      );
    }
    final total = this.total;
    final grid = MediaGrid(
      itemCount: items.length,
      maxTileExtent: 180,
      semanticLabel: strings.providerResults(providerLabel),
      status: total == null
          ? null
          : items.length < total
          ? strings.resultsShown(items.length, total)
          : strings.resultCount(total),
      hasMore: hasMore,
      loadingMore: loadingMore,
      onLoadMore: onLoadMore,
      itemBuilder: (context, i, focusNode) {
        final item = items[i];
        return MediaTile(
          focusNode: focusNode,
          thumbnail: MediaThumb(
            image: item.preview,
            swatch: item.preview == null ? item.swatch : null,
          ),
          title: item.title ?? item.id,
          subtitle: [
            item.contributor,
            if ((item.width, item.height) case (final w?, final h?))
              strings.pixelSize(w, h),
          ].whereType<String>().join(' · '),
          selected: item.id == selectedId,
          check: MediaTileCheck.selected,
          onTap: () => onSelect?.call(item),
          // Enter picks the item, if it is not already — a second select
          // would toggle it off — and confirms.
          onConfirm: onConfirm == null
              ? null
              : () {
                  if (item.id != selectedId) onSelect?.call(item);
                  onConfirm!();
                },
        );
      },
    );
    return DelayedLoading(
      loading: loading,
      builder: (context, show) => Stack(
        children: [
          grid,
          if (show)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: TopProgressBar(),
            ),
        ],
      ),
    );
  }
}

// ── toolbar ───────────────────────────────────────────────────────────────

class _Toolbar extends StatelessWidget {
  final String query;
  final ValueChanged<String>? onQueryChanged;
  final Duration searchDebounce;
  final ProviderFilters filters;
  final ValueChanged<ProviderFilters>? onFiltersChanged;
  final String providerLabel;

  const _Toolbar({
    required this.query,
    required this.onQueryChanged,
    required this.searchDebounce,
    required this.filters,
    required this.onFiltersChanged,
    required this.providerLabel,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.adminL10n.assets;
    final change = onFiltersChanged;
    final search = SearchField(
      value: query,
      onChanged: onQueryChanged,
      debounce: searchDebounce > Duration.zero ? searchDebounce : null,
      hint: strings.searchProvider(providerLabel),
    );
    final orientation = FilterMenuButton<ProviderOrientation?>(
      value: filters.orientation,
      tooltip: strings.orientation,
      icon: Icons.crop_rounded,
      onChanged: change == null
          ? null
          : (v) => change(filters.copyWith(orientation: () => v)),
      options: [
        FilterMenuOption(null, strings.anyOrientation),
        FilterMenuOption(ProviderOrientation.horizontal, strings.horizontal),
        FilterMenuOption(ProviderOrientation.vertical, strings.vertical),
        FilterMenuOption(ProviderOrientation.square, strings.square),
      ],
    );
    final imageType = FilterMenuButton<ProviderImageType?>(
      value: filters.imageType,
      tooltip: strings.imageType,
      icon: Icons.category_outlined,
      onChanged: change == null
          ? null
          : (v) => change(filters.copyWith(imageType: () => v)),
      options: [
        FilterMenuOption(null, strings.anyType),
        FilterMenuOption(ProviderImageType.photo, strings.photos),
        FilterMenuOption(ProviderImageType.illustration, strings.illustrations),
        FilterMenuOption(ProviderImageType.vector, strings.vectors),
      ],
    );
    return Padding(
      padding: const EdgeInsets.all(AdminSpacing.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth + 2 * AdminSpacing.lg >= 560) {
            return Row(
              children: [
                Expanded(child: search),
                const Gap(AdminSpacing.lg),
                orientation,
                const Gap(AdminSpacing.md),
                imageType,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const Gap(AdminSpacing.md),
              Wrap(
                spacing: AdminSpacing.md,
                runSpacing: AdminSpacing.md,
                children: [orientation, imageType],
              ),
            ],
          );
        },
      ),
    );
  }
}
