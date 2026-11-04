/// @docImport '../asset_source.dart';
library;

import 'package:material_ui/material_ui.dart';

import '../../common/load_state_area.dart';
import '../../common/ui/delayed_loading.dart';
import '../../common/ui/empty_state.dart';
import '../../common/ui/error_state.dart';
import '../../common/ui/error_text.dart';
import '../../common/ui/search_field.dart';
import '../../common/ui/segmented.dart';
import '../../common/ui/severity.dart';
import '../../common/ui/spinner.dart';
import '../../common/ui/tabs.dart';
import '../../common/ui/toast.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../l10n/formats.dart';
import '../../l10n/sections/assets_messages.dart';
import '../../theme/breakpoints.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import '../asset_library_controller.dart';
import 'media_tile.dart';

/// Broad media class of an asset — drives the type filter and the fallback
/// glyph when no thumbnail is available.
enum AssetType { image, video, audio, document, other }

/// How the library reports taps: a read-only browser, a single-pick picker, or
/// a multi-select picker with a confirm footer.
enum AssetSelectionMode { none, single, multiple }

/// Grid of thumbnails vs. a detailed row list.
enum AssetView { grid, list }

/// One library asset. View-only: [thumbnail] is the real preview when present,
/// else [swatch] stands one in for demos. [usageCount] is how many entries
/// reference it (0 = orphan, safe to delete).
class Asset {
  final String id;
  final String name;
  final AssetType type;
  final int bytes;
  final ImageProvider? thumbnail;

  /// The raw (presigned) URL behind [thumbnail], when known — needed where a
  /// URL string is required rather than an [ImageProvider] (e.g. the block
  /// editor's image block).
  final String? url;
  final Color? swatch;
  final int? width;
  final int? height;
  final int usageCount;

  /// Library-level default alt text by language code; a usage's `AssetRef.alt`
  /// overrides it per reference.
  final Map<String, String> alt;

  const Asset({
    required this.id,
    required this.name,
    this.type = AssetType.image,
    this.bytes = 0,
    this.thumbnail,
    this.url,
    this.swatch,
    this.width,
    this.height,
    this.usageCount = 0,
    this.alt = const {},
  });

  /// [bytes] in [context]'s locale: '1.5 MB', '1,5 Mo'.
  String sizeOf(BuildContext context) => context.adminFormats.bytes(bytes);

  /// The pixel dimensions as [context]'s language writes them, "1920 ×
  /// 1080", or null when unknown.
  String? dimsOf(BuildContext context) {
    final (w, h) = (width, height);
    if (w == null || h == null) return null;
    return context.adminL10n.assets.pixelSize(w, h);
  }
}

IconData assetGlyph(AssetType type) => switch (type) {
  AssetType.image => Icons.image_outlined,
  AssetType.video => Icons.movie_outlined,
  AssetType.audio => Icons.audiotrack_outlined,
  AssetType.document => Icons.description_outlined,
  AssetType.other => Icons.insert_drive_file_outlined,
};

/// The recurring media-browsing surface: search + type filter + grid/list of
/// [assets], with optional multi-select and an embedded upload tab. The picker
/// every media field and the block editor's image insert reach for.
///
/// View-pure — it renders the [assets] it's handed and emits intent via
/// callbacks; the host owns filtering (so search/[filter] can map to a
/// server-side query) and selection state. [uploadTab], when supplied, turns
/// the header into Library/Upload tabs and is shown verbatim under the second.
///
/// Over an [AssetSource], [AssetLibrary.connected] takes its assets, search,
/// filters and paging from an [AssetLibraryController] instead.
///
/// Give it a bounded height: the grid scrolls, loading its next page through
/// [onLoadMore] as the end nears, and the tiles are one Tab stop the arrow
/// keys move between (see [MediaGrid]). Below 480px wide the toolbar puts
/// the search on a row of its own, and the filters wrap above the view
/// toggle when they outgrow theirs.
class AssetLibrary extends StatelessWidget {
  /// Already filtered to [query]/[filter] by the host; rendered as-is.
  final List<Asset> assets;

  final AssetView view;
  final ValueChanged<AssetView>? onViewChanged;

  final String query;

  /// Reports the search once typing has paused for [searchDebounce].
  final ValueChanged<String>? onQueryChanged;

  /// How long typing has to pause before [onQueryChanged] reports it, as the
  /// query usually goes to a server; submitting or clearing reports at once.
  /// [Duration.zero] reports every keystroke.
  final Duration searchDebounce;

  /// `null` = all types.
  final AssetType? filter;
  final ValueChanged<AssetType?>? onFilterChanged;

  final AssetSelectionMode selectionMode;
  final Set<String> selected;

  /// Toggle one asset's membership in the selection.
  final ValueChanged<String>? onToggle;

  /// Open an asset (browse mode / a detail peek). In picker modes a tap toggles
  /// selection instead.
  final ValueChanged<Asset>? onOpen;

  /// Loading with nothing to show yet fills the body with a spinner; loading
  /// over [assets] already shown (a new search) keeps them, under a progress
  /// bar.
  final bool loading;
  final Object? error;
  final VoidCallback? onRetry;

  /// Words [error] for the error state; [ErrorTextScope.describe] when null.
  final String Function(Object error)? errorText;

  /// How many assets match [query]/[filter] in all, when known: the bar
  /// under the grid counts them ("24 of 120 assets").
  final int? total;

  /// More assets match than [assets] holds: [onLoadMore] fetches the next
  /// page, called as the grid nears its end and from a "Load more" button.
  /// Not while [loading]: the next page of a new search follows its first.
  final bool hasMore;
  final VoidCallback? onLoadMore;

  /// The next page is on its way: a spinner shows under the grid, and
  /// [onLoadMore] is not called again until it lands.
  final bool loadingMore;

  /// When set, the header shows Library/Upload tabs and this is the Upload body.
  final Widget? uploadTab;

  /// Draws the library as its own bordered, rounded card. Off, it sits flush
  /// in a host that already frames it, such as a dialog pane under tabs.
  final bool framed;

  /// Picker footer. When [onConfirm] is set a selection bar pins to the bottom.
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;

  /// The confirm action's label; "Select" in the app's language by default.
  final String? confirmLabel;

  /// The app's own filters, beside the type filter: a [FilterMenuButton],
  /// say, whose choice the host passes to [AssetSource.browse] as `where`
  /// (see [AssetLibraryController.where]).
  final List<Widget> toolbarActions;

  /// The widest a grid column gets. Null gives two columns while the library
  /// is narrower than `context.breakpoints.medium`, a phone's two-up grid,
  /// and columns of at most 150 from there.
  final double? maxTileExtent;

  /// The controller a library made with [AssetLibrary.connected] reads, else
  /// null.
  final AssetLibraryController? controller;

  const AssetLibrary({
    super.key,
    required this.assets,
    this.view = AssetView.grid,
    this.onViewChanged,
    this.query = '',
    this.onQueryChanged,
    this.searchDebounce = const Duration(milliseconds: 300),
    this.filter,
    this.onFilterChanged,
    this.selectionMode = AssetSelectionMode.none,
    this.selected = const {},
    this.onToggle,
    this.onOpen,
    this.loading = false,
    this.error,
    this.onRetry,
    this.errorText,
    this.total,
    this.hasMore = false,
    this.onLoadMore,
    this.loadingMore = false,
    this.uploadTab,
    this.framed = true,
    this.onCancel,
    this.onConfirm,
    this.confirmLabel,
    this.toolbarActions = const [],
    this.maxTileExtent,
  }) : controller = null;

  /// A library over [controller]: the assets, the search, the type filter,
  /// the view and the paging are the controller's, and the toolbar sets
  /// them on it, which reloads. A next page that fails keeps the assets shown
  /// and says why in a toast (from a [ToastScope] above); "Load more" tries
  /// it again. The other parameters are [AssetLibrary]'s.
  const AssetLibrary.connected({
    super.key,
    required AssetLibraryController this.controller,
    this.searchDebounce = const Duration(milliseconds: 300),
    this.selectionMode = AssetSelectionMode.none,
    this.selected = const {},
    this.onToggle,
    this.onOpen,
    this.errorText,
    this.uploadTab,
    this.framed = true,
    this.onCancel,
    this.onConfirm,
    this.confirmLabel,
    this.toolbarActions = const [],
    this.maxTileExtent,
  }) : assets = const [],
       view = AssetView.grid,
       onViewChanged = null,
       query = '',
       onQueryChanged = null,
       filter = null,
       onFilterChanged = null,
       loading = false,
       error = null,
       onRetry = null,
       total = null,
       hasMore = false,
       onLoadMore = null,
       loadingMore = false;

  bool get _picker => selectionMode != AssetSelectionMode.none;

  /// This library's presentation over [controller]'s state.
  AssetLibrary _over(AssetLibraryController controller) => AssetLibrary(
    assets: controller.assets,
    view: controller.view,
    onViewChanged: (view) => controller.view = view,
    query: controller.query,
    onQueryChanged: (query) => controller.query = query,
    searchDebounce: searchDebounce,
    filter: controller.filter,
    onFilterChanged: (filter) => controller.filter = filter,
    selectionMode: selectionMode,
    selected: selected,
    onToggle: onToggle,
    onOpen: onOpen,
    loading: controller.loading,
    error: controller.error,
    onRetry: controller.retry,
    errorText: errorText,
    total: controller.total,
    hasMore: controller.hasMore,
    onLoadMore: controller.loadMore,
    loadingMore: controller.loadingMore,
    uploadTab: uploadTab,
    framed: framed,
    onCancel: onCancel,
    onConfirm: onConfirm,
    confirmLabel: confirmLabel,
    toolbarActions: toolbarActions,
    maxTileExtent: maxTileExtent,
  );

  @override
  Widget build(BuildContext context) {
    if (controller case final controller?) {
      return _Connected(library: this, controller: controller);
    }
    final pane = uploadTab != null ? _tabbed(context) : _libraryPane(context);
    if (!framed) return pane;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(context.radii.radiusLarge),
        border: Border.all(color: context.colors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.radii.radiusLarge),
        child: pane,
      ),
    );
  }

  Widget _tabbed(BuildContext context) {
    return _TabHost(library: _libraryPane(context), upload: uploadTab!);
  }

  Widget _libraryPane(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Toolbar(
          query: query,
          onQueryChanged: onQueryChanged,
          searchDebounce: searchDebounce,
          view: view,
          onViewChanged: onViewChanged,
          filter: filter,
          onFilterChanged: onFilterChanged,
          actions: toolbarActions,
        ),
        const Divider(height: 1),
        Flexible(child: _body(context)),
        if (_picker && onConfirm != null)
          SelectionFooter(
            status: context.adminL10n.selectedCount(selected.length),
            muted: selected.isEmpty,
            confirmLabel: confirmLabel ?? context.adminL10n.assets.select,
            onCancel: onCancel,
            onConfirm: selected.isEmpty ? null : onConfirm,
          ),
      ],
    );
  }

  Widget _body(BuildContext context) {
    final strings = context.adminL10n.assets;
    if (loading && assets.isEmpty) {
      return LoadStateArea(
        padding: const EdgeInsets.symmetric(vertical: AdminSpacing.xxxl),
        child: LoadingPanel(message: strings.loadingAssets, minHeight: 0),
      );
    }
    if (error case final error?) {
      return LoadStateArea(
        padding: const EdgeInsets.symmetric(vertical: AdminSpacing.xxl),
        child: ErrorState(
          minHeight: 0,
          title: strings.couldNotLoadAssets,
          message:
              errorText?.call(error) ?? ErrorTextScope.describe(context, error),
          onRetry: onRetry,
        ),
      );
    }
    if (assets.isEmpty) {
      var searching = query.isNotEmpty || filter != null;
      return LoadStateArea(
        padding: const EdgeInsets.symmetric(vertical: AdminSpacing.xxl),
        child: EmptyState(
          minHeight: 0,
          icon: searching
              ? Icons.search_off_rounded
              : Icons.photo_library_outlined,
          title: searching ? strings.noMatchingAssets : strings.noAssetsYet,
          message: searching
              ? strings.noMatchingAssetsHint
              : strings.noAssetsYetHint,
        ),
      );
    }
    final items = view == AssetView.grid ? _grid(context) : _list(context);
    return DelayedLoading(
      loading: loading,
      builder: (context, show) => Stack(
        children: [
          items,
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

  String? _status(BuildContext context) {
    final total = this.total;
    if (total == null) return null;
    final strings = context.adminL10n.assets;
    return assets.length < total
        ? strings.assetsShown(assets.length, total)
        : strings.assetCount(total);
  }

  MediaTileCheck get _check =>
      _picker ? MediaTileCheck.always : MediaTileCheck.none;

  Widget _grid(BuildContext context) {
    final extent = maxTileExtent;
    if (extent == null) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final compact = AdminBreakpoint.forWidth(
            width,
            context.breakpoints,
          ).isCompact;
          // Columns up to half the library wide: its padding leaves room
          // for two of them, never three.
          return _gridOf(context, compact ? width / 2 : _tileExtent);
        },
      );
    }
    return _gridOf(context, extent);
  }

  Widget _gridOf(BuildContext context, double maxTileExtent) {
    return MediaGrid(
      maxTileExtent: maxTileExtent,
      itemCount: assets.length,
      semanticLabel: context.adminL10n.assets.assets,
      status: _status(context),
      hasMore: hasMore && !loading,
      loadingMore: loadingMore,
      onLoadMore: onLoadMore,
      itemBuilder: (context, i, focusNode) {
        final asset = assets[i];
        return MediaTile(
          focusNode: focusNode,
          thumbnail: _thumb(asset),
          title: asset.name,
          subtitle: asset.dimsOf(context) ?? asset.sizeOf(context),
          selected: _picker ? selected.contains(asset.id) : null,
          check: _check,
          onTap: () => _onTap(asset),
          onConfirm: _confirmWith(asset),
        );
      },
    );
  }

  Widget _list(BuildContext context) {
    return MediaGrid.list(
      itemCount: assets.length,
      semanticLabel: context.adminL10n.assets.assets,
      status: _status(context),
      hasMore: hasMore && !loading,
      loadingMore: loadingMore,
      onLoadMore: onLoadMore,
      itemBuilder: (context, i, focusNode) {
        final asset = assets[i];
        return MediaListTile(
          focusNode: focusNode,
          thumbnail: _thumb(asset, iconSize: context.iconSizes.lg),
          title: asset.name,
          subtitle: [
            asset.sizeOf(context),
            ?asset.dimsOf(context),
          ].where((s) => s.isNotEmpty).join(' · '),
          selected: _picker ? selected.contains(asset.id) : null,
          check: _check,
          onTap: () => _onTap(asset),
          onConfirm: _confirmWith(asset),
        );
      },
    );
  }

  static Widget _thumb(Asset asset, {double? iconSize}) {
    final image = asset.type == AssetType.image;
    return MediaThumb(
      image: image ? asset.thumbnail : null,
      swatch: image ? asset.swatch : null,
      icon: image && asset.swatch != null
          ? Icons.image_outlined
          : assetGlyph(asset.type),
      iconSize: iconSize,
    );
  }

  void _onTap(Asset asset) {
    if (_picker) {
      onToggle?.call(asset.id);
    } else {
      onOpen?.call(asset);
    }
  }

  /// Enter on an asset in a picker with a confirm step: picks it, if it is not
  /// already, and confirms. Space and a click only toggle it.
  VoidCallback? _confirmWith(Asset asset) {
    final confirm = onConfirm;
    if (!_picker || confirm == null) return null;
    return () {
      if (!selected.contains(asset.id)) onToggle?.call(asset.id);
      confirm();
    };
  }
}

// ── toolbar ───────────────────────────────────────────────────────────────

class _Toolbar extends StatelessWidget {
  final String query;
  final ValueChanged<String>? onQueryChanged;
  final Duration searchDebounce;
  final AssetView view;
  final ValueChanged<AssetView>? onViewChanged;
  final AssetType? filter;
  final ValueChanged<AssetType?>? onFilterChanged;
  final List<Widget> actions;

  const _Toolbar({
    required this.query,
    required this.onQueryChanged,
    required this.searchDebounce,
    required this.view,
    required this.onViewChanged,
    required this.filter,
    required this.onFilterChanged,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.adminL10n.assets;
    final search = SearchField(
      value: query,
      onChanged: onQueryChanged,
      debounce: searchDebounce > Duration.zero ? searchDebounce : null,
      hint: strings.searchAssets,
    );
    final type = FilterMenuButton<AssetType?>(
      value: filter,
      tooltip: strings.filterByType,
      onChanged: onFilterChanged,
      options: [
        FilterMenuOption(null, strings.allTypes),
        for (final t in AssetType.values)
          FilterMenuOption(t, _typeLabel(strings, t), icon: assetGlyph(t)),
      ],
    );
    final views = Segmented<AssetView>(
      value: view,
      onChanged: onViewChanged,
      semanticLabel: strings.view,
      segments: [
        SegmentOption(
          AssetView.grid,
          strings.gridView,
          icon: Icons.grid_view_rounded,
          showLabel: false,
        ),
        SegmentOption(
          AssetView.list,
          strings.listView,
          icon: Icons.view_list_rounded,
          showLabel: false,
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.all(AdminSpacing.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth + 2 * AdminSpacing.lg >= _wideToolbar) {
            return Row(
              children: [
                Expanded(child: search),
                for (final control in [type, ...actions]) ...[
                  const Gap(AdminSpacing.lg),
                  control,
                ],
                const Gap(AdminSpacing.lg),
                views,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const Gap(AdminSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: AdminSpacing.md,
                      runSpacing: AdminSpacing.md,
                      children: [type, ...actions],
                    ),
                  ),
                  const Gap(AdminSpacing.lg),
                  views,
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The narrowest browser that keeps its search and filters on one row.
const _wideToolbar = 480.0;

/// The widest a grid column gets from the medium breakpoint up.
const _tileExtent = 150.0;

/// [AssetLibrary.connected]: rebuilds [library] over [controller]'s state,
/// and says why a next page failed.
class _Connected extends StatefulWidget {
  final AssetLibrary library;
  final AssetLibraryController controller;

  const _Connected({required this.library, required this.controller});

  @override
  State<_Connected> createState() => _ConnectedState();
}

class _ConnectedState extends State<_Connected> {
  /// The failure last reported, so a rebuild does not report it again.
  Object? _reported;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(_Connected old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    final failed = widget.controller.loadMoreError;
    if (failed != null && !identical(failed, _reported)) {
      _reported = failed;
      ToastScope.maybeOf(context)?.show(
        Toast(
          context.adminL10n.assets.couldNotLoadMore(
            widget.library.errorText?.call(failed) ??
                ErrorTextScope.describe(context, failed),
          ),
          severity: Severity.danger,
        ),
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => widget.library._over(widget.controller);
}

String _typeLabel(AssetsMessages strings, AssetType t) => switch (t) {
  AssetType.image => strings.typeImages,
  AssetType.video => strings.typeVideos,
  AssetType.audio => strings.typeAudio,
  AssetType.document => strings.typeDocuments,
  AssetType.other => strings.typeOther,
};

class _TabHost extends StatefulWidget {
  final Widget library;
  final Widget upload;

  const _TabHost({required this.library, required this.upload});

  @override
  State<_TabHost> createState() => _TabHostState();
}

class _TabHostState extends State<_TabHost> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AdminSpacing.lg,
            AdminSpacing.md,
            AdminSpacing.lg,
            0,
          ),
          child: Tabs(
            selected: _tab,
            onChanged: (i) => setState(() => _tab = i),
            tabs: [
              TabItem(
                context.adminL10n.assets.libraryTab,
                icon: Icons.photo_library_outlined,
              ),
              TabItem(
                context.adminL10n.assets.uploadTab,
                icon: Icons.cloud_upload_outlined,
              ),
            ],
          ),
        ),
        Flexible(
          child: _tab == 0
              ? widget.library
              : Padding(
                  padding: const EdgeInsets.all(AdminSpacing.xl),
                  child: SingleChildScrollView(child: widget.upload),
                ),
        ),
      ],
    );
  }
}
