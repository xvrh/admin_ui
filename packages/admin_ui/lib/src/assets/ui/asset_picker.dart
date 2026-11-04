import 'package:file_picker/file_picker.dart';
import 'package:flutter/semantics.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mime/mime.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../../common/ui/dashed_border.dart';
import '../../common/ui/error_text.dart';
import '../../common/ui/icon_action.dart';
import '../../common/ui/modal_anchor.dart';
import '../../common/ui/severity.dart';
import '../../common/ui/tabs.dart';
import '../../common/ui/toast.dart';
import '../../common/ui/upload.dart';
import '../../fields/ui/media_body.dart' show MediaStatus;
import '../../l10n/admin_ui_localizations.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import '../asset_library_controller.dart';
import '../asset_source.dart';
import '../asset_upload_controller.dart';
import '../external_provider.dart';
import 'asset_drop_target.dart';
import 'asset_library.dart';
import 'provider_browser.dart';
import 'provider_import_sheet.dart';

/// Opens the shared media picker over [source] and returns the chosen asset id,
/// or null if dismissed. Single-selection: the picker browses the library
/// (search + type filter) and confirms one asset.
///
/// New files enter two ways, both uploading through [source]: the library's
/// Upload tab (browse or drop), and dropping a file anywhere on the dialog.
/// A single dropped/browsed file is the replace gesture — the picker pops with
/// the new asset id as soon as the upload lands (unless it was cancelled
/// first). [accept] governs what may be dropped and what the file browser
/// offers alike; a file it turns away is named in a toast.
///
/// Shows on [modals] when given, else on the nearest [ModalAnchor] — pass a
/// dedicated anchor when the picker opens over another modal (the asset
/// editor does this; the outer anchor is busy showing the editor).
///
/// When external [providers] are available (passed explicitly, else read from
/// the ambient [ExternalProviderScope]) the picker grows a tab per provider;
/// confirming a provider pick licenses + imports it and returns the new local
/// asset id, so the result is always an ordinary asset id.
Future<String?> showAssetPicker(
  BuildContext context, {
  required AssetSource source,
  AssetType? initialFilter,
  AssetAccept accept = AssetAccept.any,
  List<ExternalAssetProvider>? providers,
  ModalAnchorController? modals,
}) {
  final resolved = providers ?? ExternalProviderScope.of(context);
  final anchor = modals ?? ModalAnchor.of(context);
  return anchor.show<String>(
    builder: (_) => _AssetPickerDialog(
      source: source,
      initialFilter: initialFilter,
      accept: accept,
      providers: resolved,
      modals: anchor,
    ),
  );
}

class _AssetPickerDialog extends StatefulWidget {
  final AssetSource source;
  final AssetType? initialFilter;
  final AssetAccept accept;
  final List<ExternalAssetProvider> providers;

  /// The anchor this dialog is shown on — its close handle.
  final ModalAnchorController modals;

  const _AssetPickerDialog({
    required this.source,
    this.initialFilter,
    this.accept = AssetAccept.any,
    this.providers = const [],
    required this.modals,
  });

  @override
  State<_AssetPickerDialog> createState() => _AssetPickerDialogState();
}

class _AssetPickerDialogState extends State<_AssetPickerDialog> {
  int _tab = 0;
  final _uploads = AssetUploadController();
  late final _library = AssetLibraryController(
    source: widget.source,
    initialFilter: widget.initialFilter,
  );

  /// Holds focus for the dialog when the pane that had it is hidden.
  final _surface = FocusNode(debugLabel: 'Media picker', skipTraversal: true);

  @override
  void dispose() {
    _uploads.dispose();
    _library.dispose();
    _surface.dispose();
    super.dispose();
  }

  void _close([String? id]) => widget.modals.close(id);

  /// Shows tab [index]. The pane it hides drops the focus it held — a
  /// search typed into — so focus stays in the dialog, where Escape still
  /// closes it.
  void _showTab(int index) {
    setState(() => _tab = index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_surface.hasFocus) _surface.requestFocus();
    });
  }

  /// Files upload immediately. Exactly one file (and nothing else in flight) is
  /// the replace gesture: the picker pops with the new asset id when it lands.
  /// More than one just feeds the library — ambiguous which one was meant.
  void _onFiles(List<DroppedAsset> files) {
    if (files.isEmpty || !mounted) return;
    // Land on the Upload tab so in-flight progress (and any failure) is seen.
    _showTab(1);
    final autoReturn = files.length == 1 && _uploads.isEmpty;
    _uploads.enqueue(
      files,
      widget.source,
      onUploaded: (id) {
        if (autoReturn && mounted) {
          _close(id);
        } else {
          _library.load();
        }
      },
    );
  }

  void _retry(String localId) {
    final autoReturn = _uploads.length == 1;
    _uploads.retry(localId, widget.source, (id) {
      if (autoReturn && mounted) {
        _close(id);
      } else {
        _library.load();
      }
    });
  }

  /// The file browser offers what `accept` takes where the platform dialog
  /// can say so; anything it still lets through is checked here, like a drop.
  /// A file refused by its name, or by a size the platform reported, is
  /// never read.
  Future<void> _browse() async {
    final accept = widget.accept;
    final (type, extensions) = _browseFilter(accept);
    final picked = await FilePicker.pickFiles(
      type: type,
      allowedExtensions: extensions,
    );
    if (picked.isEmpty || !mounted) return;
    final files = <DroppedAsset>[];
    final refused = <AssetRefusal>[];
    for (final f in picked) {
      final mime = lookupMimeType(f.name);
      final early = accept.refusalFor(
        f.name,
        mime: mime,
        bytes: f.lengthSync(),
      );
      if (early != null) {
        refused.add(AssetRefusal(f.name, early));
        continue;
      }
      final bytes = await f.readAsBytes();
      final reason = accept.refusalFor(f.name, mime: mime, bytes: bytes.length);
      if (reason != null) {
        refused.add(AssetRefusal(f.name, reason));
        continue;
      }
      files.add(
        DroppedAsset(
          name: f.name,
          mime: mime ?? 'application/octet-stream',
          bytes: bytes,
        ),
      );
    }
    if (!mounted) return;
    _onFiles(files);
    showAssetRefusals(context, accept, refused);
  }

  Widget _uploadZone() {
    return ListenableBuilder(
      listenable: _uploads,
      builder: (context, _) => UploadZone(
        items: [
          for (final m in _uploads.busyItems(context))
            UploadItem(
              id: m.id,
              name: m.name,
              bytes: m.bytes,
              status: switch (m.status) {
                MediaStatus.error => UploadStatus.error,
                MediaStatus.queued => UploadStatus.queued,
                MediaStatus.uploading ||
                MediaStatus.processing => UploadStatus.uploading,
                MediaStatus.ready => UploadStatus.done,
              },
              progress: m.progress,
              errorText: m.errorText,
            ),
        ],
        accept: widget.accept.hintOf(context),
        onBrowse: _browse,
        onCancel: _uploads.remove,
        onRetry: _retry,
        onRemove: _uploads.remove,
      ),
    );
  }

  /// The Upload pane, flush with the dialog like a provider pane.
  Widget _uploadPane() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AdminSpacing.xl),
      child: _uploadZone(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final library = _LibraryPane(
      controller: _library,
      onCancel: _close,
      onSelect: _close,
    );

    // A titled header with a close that every tab shares, over one flat
    // strip: Library | Upload | one tab per provider. The library's own
    // embedded upload tab stays unused here so the picker never nests two
    // tab bars. The surface is a Modal's: the dialog radius, a hairline and
    // the large shadow.
    final strings = context.adminL10n.assets;
    final corners = BorderRadius.circular(context.radii.radiusDialog);
    const close = IconActionSize.small;
    final Widget content = DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: corners,
        boxShadow: context.elevation.lg,
      ),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: corners,
          border: Border.all(color: context.colors.border),
        ),
        child: ClipRRect(
          borderRadius: corners,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                // The close glyph, not its hit box, keeps the title's inset
                // from the end edge, as the grid's tiles do.
                padding: EdgeInsetsDirectional.only(
                  start: AdminSpacing.xl,
                  top: AdminSpacing.md,
                  end: AdminSpacing.xl - (close.box - close.glyph) / 2,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          strings.pickerTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.type.heading,
                        ),
                      ),
                    ),
                    const Gap(AdminSpacing.md),
                    IconAction.close(size: close, onPressed: _close),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AdminSpacing.lg,
                ),
                child: Tabs(
                  selected: _tab,
                  onChanged: _showTab,
                  baseline: false,
                  tabs: [
                    TabItem(
                      strings.libraryTab,
                      icon: Icons.photo_library_outlined,
                    ),
                    TabItem(
                      strings.uploadTab,
                      icon: Icons.cloud_upload_outlined,
                    ),
                    for (final p in widget.providers)
                      TabItem(p.label, icon: p.icon),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: IndexedStack(
                  index: _tab,
                  sizing: StackFit.passthrough,
                  children: [
                    library,
                    _uploadPane(),
                    for (final p in widget.providers)
                      _ProviderPane(
                        provider: p,
                        onCancel: _close,
                        onSelect: _close,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AdminSpacing.xxl),
      // The dialog node is the surface's own, below, which names it.
      semanticsRole: SemanticsRole.none,
      // Stay clickable over a web platform view (an embedded iframe, say).
      child: PointerInterceptor(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860, maxHeight: 620),
          child: Semantics(
            scopesRoute: true,
            namesRoute: true,
            explicitChildNodes: true,
            label: strings.pickerTitle,
            role: SemanticsRole.dialog,
            child: Focus(
              focusNode: _surface,
              includeSemantics: false,
              child: AssetDropTarget(
                accept: widget.accept,
                onFiles: _onFiles,
                builder: (context, dragOver) => Stack(
                  children: [
                    content,
                    if (dragOver) const Positioned.fill(child: _DropOverlay()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DropOverlay extends StatelessWidget {
  const _DropOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          // token-literal: the veil a drop target lays over the library
          color: context.colors.surface.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(context.radii.radiusDialog),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AdminSpacing.lg),
          child: DashedBorder(
            color: context.colors.primary,
            radius: context.radii.radiusLarge,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 40,
                    color: context.colors.primaryText,
                  ),
                  const Gap(AdminSpacing.md),
                  Text(
                    context.adminL10n.assets.dropToUpload,
                    style: context.type.bodyStrong.copyWith(
                      color: context.colors.primaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Reports a page that failed to add to results already shown: they stay,
/// and the toast says why ("Load more" tries again).
void _reportMoreFailed(BuildContext context, Object error) {
  final toasts = context.findAncestorStateOfType<ToastScopeState>();
  toasts?.show(
    Toast(
      context.adminL10n.assets.couldNotLoadMore(
        ErrorTextScope.describe(context, error),
      ),
      severity: Severity.danger,
    ),
  );
}

/// The local-library tab: search + type filter + single-select grid/list,
/// over the dialog's [AssetLibraryController]. [AssetLibrary] debounces the
/// search; the grid pulls the next page of the library as it nears its end.
class _LibraryPane extends StatefulWidget {
  final AssetLibraryController controller;
  final VoidCallback onCancel;
  final ValueChanged<String?> onSelect;

  const _LibraryPane({
    required this.controller,
    required this.onCancel,
    required this.onSelect,
  });

  @override
  State<_LibraryPane> createState() => _LibraryPaneState();
}

class _LibraryPaneState extends State<_LibraryPane> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    return AssetLibrary.connected(
      controller: widget.controller,
      framed: false,
      selectionMode: AssetSelectionMode.single,
      selected: {?_selected},
      onToggle: (id) => setState(() => _selected = _selected == id ? null : id),
      onCancel: widget.onCancel,
      onConfirm: () => widget.onSelect(_selected),
    );
  }
}

/// A provider tab: search → [ProviderBrowser] (which debounces it), a page at
/// a time; confirming opens the license/import sheet and pops the new local
/// asset id.
class _ProviderPane extends StatefulWidget {
  final ExternalAssetProvider provider;
  final VoidCallback onCancel;
  final ValueChanged<String?> onSelect;

  const _ProviderPane({
    required this.provider,
    required this.onCancel,
    required this.onSelect,
  });

  @override
  State<_ProviderPane> createState() => _ProviderPaneState();
}

class _ProviderPaneState extends State<_ProviderPane> {
  String _query = '';
  ProviderFilters _filters = const ProviderFilters();
  String? _selectedId;
  List<ProviderItem> _items = const [];
  int _total = 0;
  int _page = 1;
  bool _loading = true;
  bool _loadingMore = false;
  Object? _error;

  int _reqId = 0;

  @override
  void initState() {
    super.initState();
    _search();
  }

  bool get _hasMore => _items.length < _total;

  Future<void> _search() async {
    final req = ++_reqId;
    setState(() {
      _loading = true;
      _loadingMore = false;
      _error = null;
    });
    try {
      final result = await widget.provider.search(
        query: _query,
        filters: _filters,
      );
      if (!mounted || req != _reqId) return;
      setState(() {
        _items = result.items;
        _total = result.total;
        _page = 1;
        _selectedId = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || req != _reqId) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    final req = _reqId;
    setState(() => _loadingMore = true);
    try {
      final result = await widget.provider.search(
        query: _query,
        page: _page + 1,
        filters: _filters,
      );
      if (!mounted || req != _reqId) return;
      setState(() {
        _items = [..._items, ...result.items];
        _total = result.items.isEmpty ? _items.length : result.total;
        _page++;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted || req != _reqId) return;
      setState(() => _loadingMore = false);
      _reportMoreFailed(context, e);
    }
  }

  ProviderItem? get _selected {
    for (final it in _items) {
      if (it.id == _selectedId) return it;
    }
    return null;
  }

  Future<void> _confirm() async {
    final item = _selected;
    if (item == null) return;
    final id = await showProviderImport(
      context,
      item: item,
      providerLabel: widget.provider.label,
      choosesSize: widget.provider.choosesSize,
      loadSizes: () => widget.provider.sizesFor(item),
      onImport: (size) => widget.provider.import(item, size: size),
    );
    if (id != null && mounted) widget.onSelect(id);
  }

  @override
  Widget build(BuildContext context) {
    return ProviderBrowser(
      providerLabel: widget.provider.label,
      items: _items,
      loading: _loading,
      error: _error,
      onRetry: _search,
      query: _query,
      onQueryChanged: (q) {
        setState(() => _query = q);
        _search();
      },
      filters: _filters,
      onFiltersChanged: (f) {
        setState(() => _filters = f);
        _search();
      },
      total: _total,
      hasMore: _hasMore && !_loading,
      loadingMore: _loadingMore,
      onLoadMore: _loadMore,
      selectedId: _selectedId,
      onSelect: (item) =>
          setState(() => _selectedId = _selectedId == item.id ? null : item.id),
      onCancel: widget.onCancel,
      onConfirm: _confirm,
    );
  }
}

/// The platform file dialog's filter for [accept]: a family it names (images,
/// video, audio), or the extensions alone when only extensions are given.
/// Anything else browses all files and is checked once picked.
(FileType, List<String>?) _browseFilter(AssetAccept accept) {
  if (accept.anyType) return (FileType.any, null);
  if (accept.mimeTypes.isEmpty) {
    return (
      FileType.custom,
      [for (final e in accept.extensions) e.toLowerCase()],
    );
  }
  if (accept.extensions.isEmpty && accept.mimeTypes.length == 1) {
    switch (accept.mimeTypes.single.toLowerCase()) {
      case 'image/*':
        return (FileType.image, null);
      case 'video/*':
        return (FileType.video, null);
      case 'audio/*':
        return (FileType.audio, null);
    }
  }
  return (FileType.any, null);
}
